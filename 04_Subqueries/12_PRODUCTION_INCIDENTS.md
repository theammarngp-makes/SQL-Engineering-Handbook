# Production Playbooks & Incident Post-Mortems: Subquery Outages

This document details 5 real-world production outages and performance incidents caused by subquery antipatterns in high-concurrency relational database systems. Each incident report follows standard Site Reliability Engineering (SRE) post-mortem structure: **Symptoms**, **Diagnosis**, **Execution Plan Breakdown**, **Root Cause**, **Fix Procedure**, **Verification**, **Regression Test**, and **Lessons Learned**.

---

## Playbook Incident 1: Executive Dashboard Timeout Outage (SEV-1)

- **System Context**: SaaS Financial Analytics Platform
- **Outage Duration**: 45 Minutes during Monday morning executive login window.
- **Affected Services**: Main Executive Dashboard & Revenue API microservices.

### Symptoms
- 100% of executive dashboard queries failed with `504 Gateway Timeout` (30s statement timeout).
- Database CPU utilization spiked to 100% across all 32 core reader replicas.
- Active connection pool depleted (`FATAL: remaining connection slots are reserved for non-replication superuser connections`).

### Diagnosis
DBA team inspected `pg_stat_activity` and identified 450 concurrent instances of the financial view query blocked in `active` state:
```sql
SELECT query, state, age(clock_timestamp(), query_start) 
FROM pg_stat_activity 
WHERE state != 'idle';
```

### Execution Plan Breakdown
```text
Seq Scan on transactions t  (cost=0.00..850420.00 rows=500000 width=48) (actual time=0.080..32100.450 rows=500000 loops=1)
  SubPlan 1
    ->  Aggregate  (cost=1.70..1.71 rows=1 width=8) (actual time=0.060..0.060 rows=1 loops=5000000)
          ->  Index Scan using idx_tx_account on transactions sub (loops=5000000)
```

### Root Cause
The production reporting view contained a projected scalar subquery (`(SELECT COUNT(*) FROM transactions sub WHERE sub.account_id = t.account_id)`). Because the inner subquery was correlated on `account_id`, the database parser generated a `SubPlan` node that executed **5,000,000 index scans per dashboard request**, scaling to over $2,250,000,000$ index operations per minute under concurrent traffic.

### Fix Procedure & Refactored SQL
Refactored the view projection to use a SQL Window Function (`COUNT(*) OVER (PARTITION BY account_id)`):

```sql
-- ✅ PRODUCTION REVISED QUERY (Execution Time: 110ms)
CREATE OR REPLACE VIEW v_executive_dashboard AS
SELECT 
    t.transaction_id,
    t.account_id,
    t.amount,
    t.created_at,
    COUNT(*) OVER (PARTITION BY t.account_id) AS total_account_txs
FROM transactions t
WHERE t.created_at >= CURRENT_DATE - INTERVAL '7 days';
```

### Verification & Regression Test
- Execution time dropped from $> 30,000\text{ ms}$ to $110\text{ ms}$.
- Shared buffer page reads reduced by $99.8\%$.
- Added CI/CD static lint check using `pg_query` AST parser to reject any SQL view PR containing `SubLink` nodes inside projection target lists.

### Lessons Learned
- **Prohibit Correlated Projections**: Prohibit projected scalar subqueries inside database views.
- **Mandate Window Functions**: Enforce Window Functions for windowed aggregate projections.

---

## Playbook Incident 2: Silent Data Loss in Marketing Automation (SEV-2)

- **System Context**: E-Commerce Customer Re-Engagement Engine
- **Outage Duration**: 3 Days (Undetected silent logic failure).

### Symptoms
- Zero marketing emails sent to 450,000 inactive customers during quarterly win-back campaign.
- No error logs emitted by application servers; HTTP 200 returned by batch cron jobs.

### Diagnosis
Inspecting the batch campaign query revealed it returned **0 rows**:

```sql
-- ❌ SEV-2 BUG: Returns 0 rows because inner target column contains NULLs
SELECT email 
FROM users 
WHERE user_id NOT IN (
    SELECT customer_id 
    FROM active_subscriptions -- Contains 1 NULL row!
);
```

### Root Cause
Under ANSI SQL 3-valued logic, `user_id NOT IN (1, 2, NULL)` expands to `(user_id <> 1) AND (user_id <> 2) AND (user_id <> NULL)`. Because any comparison against `NULL` yields `UNKNOWN`, the entire `WHERE` clause evaluated to `UNKNOWN`, silently discarding all 450,000 valid customer target records without throwing a syntax or runtime error.

### Fix Procedure & Refactored SQL
Refactored the query to use `NOT EXISTS` (2-valued Anti-Join logic):

```sql
-- ✅ SAFE FIX: Refactored to NOT EXISTS Anti-Join
SELECT u.email 
FROM users u
WHERE NOT EXISTS (
    SELECT 1 
    FROM active_subscriptions s 
    WHERE s.customer_id = u.user_id
);
```

### Lessons Learned
- **Banned `NOT IN`**: Mandated complete elimination of `NOT IN` subqueries targeting nullable columns in favor of `NOT EXISTS`.

---

## Playbook Incident 3: Credit Card Fraud Engine Locking Outage (SEV-1)

- **System Context**: Real-Time Card Authorization Fraud-Scoring Service
- **Outage Duration**: 22 minutes during a Black Friday traffic peak.
- **Affected Services**: Card authorization API (synchronous, in the customer checkout path).

### Symptoms
- Card authorization P99 latency rose from a baseline of ~25ms to over 12,000ms.
- Downstream payment gateway began issuing timeout declines on otherwise valid transactions.
- On-call paged after authorization success rate dropped below the 99.5% SLO threshold.

### Diagnosis
`pg_stat_activity` showed dozens of authorization queries stuck in `active` state well past their expected sub-50ms runtime, all executing against the same `transactions` table:

```sql
SELECT pid, state, wait_event_type, query_start
FROM pg_stat_activity
WHERE query ILIKE '%fraud_score%' AND state = 'active';
```

### Execution Plan Breakdown
```text
Seq Scan on transactions t  (cost=0.00..1920840.00 rows=1 width=24) (actual time=45.200..11890.310 rows=1 loops=1)
  Filter: (card_id = $1)
  SubPlan 1
    ->  Aggregate  (cost=3.20..3.21 rows=1 width=8) (actual time=118.400..118.400 rows=1 loops=1)
          ->  Seq Scan on transactions sub  (cost=0.00..1920820.00 rows=50000000 width=0) (actual time=0.020..115.900 rows=1240 loops=1)
                Filter: (card_id = t.card_id AND created_at >= (now() - '01:00:00'::interval))
```

### Root Cause
The fraud-scoring query's correlated subquery — counting a card's transactions in the trailing hour — had no supporting index on `(card_id, created_at)`. Under normal traffic this full scan of the 50M-row `transactions` table was slow but tolerable; under Black Friday's 8x transaction volume, concurrent full scans exhausted shared buffer cache, forcing physical disk reads that serialized behind I/O contention and cascaded into the observed latency spike.

### Fix Procedure & Refactored SQL
Added a composite covering index and rewrote the correlated count as an unnestable, indexable predicate:

```sql
-- ✅ Composite index supporting the correlation + time-window filter
CREATE INDEX CONCURRENTLY idx_tx_card_recent
    ON transactions (card_id, created_at);

-- ✅ PRODUCTION REVISED QUERY (P99: 8ms, down from 12,000ms)
SELECT
    t.transaction_id,
    t.card_id,
    (SELECT COUNT(*)
     FROM transactions sub
     WHERE sub.card_id = t.card_id
       AND sub.created_at >= now() - INTERVAL '1 hour') AS recent_tx_count
FROM transactions t
WHERE t.card_id = $1;
```

### Verification & Regression Test
- P99 authorization latency returned to 8ms under a re-run of Black Friday traffic replay.
- `EXPLAIN (ANALYZE, BUFFERS)` confirmed the subquery now resolves via `Index Only Scan` on `idx_tx_card_recent` instead of `Seq Scan`.
- Added a synthetic load test to the pre-release pipeline that replays peak-traffic query volume against a 50M-row staging table before any fraud-engine deploy.

### Lessons Learned
- **Index Correlation Keys Proactively**: Any correlated subquery filtering on a time window must have a composite index covering both the correlation key and the time predicate — not just the correlation key alone.
- **Load-Test at Peak Multiplier, Not Baseline**: The query was "acceptable" at baseline volume; the incident only manifested at 8x peak load, which pre-release testing hadn't simulated.

---

## Playbook Incident 4: Monthly Payroll Processing Timeout (SEV-2)

- **System Context**: HR/Payroll Batch Processing Pipeline
- **Outage Duration**: Payroll run failed and had to be manually re-triggered; 90-minute delay to end-of-month disbursement.
- **Affected Services**: Overnight payroll batch job (not customer-facing, but business-critical deadline).

### Symptoms
- Batch job failed with `ERROR: canceling statement due to statement timeout` after 15 minutes.
- Job had completed successfully in under 4 minutes every prior month.
- No application code had changed since the last successful run.

### Diagnosis
Comparing row counts against the prior month revealed the `employes` table had grown from 8,000 to roughly 50,000 rows following a company acquisition — the query's cost had scaled with headcount, not with a code change.

### Execution Plan Breakdown
```text
HashAggregate  (cost=1850200.00..1850200.05 rows=1 width=40) (actual time=901200.100..901200.110 rows=1 loops=1)
  Filter: (SubPlan 1 > 100000.00)
  ->  Seq Scan on departments d  (cost=0.00..1850150.00 rows=50 width=40) (actual time=18.000..900980.500 rows=50 loops=1)
        SubPlan 1
          ->  Aggregate  (cost=37000.00..37000.01 rows=1 width=8) (actual time=18019.610..18019.610 rows=1 loops=50)
                ->  Seq Scan on employes e  (cost=0.00..36990.00 rows=1000000 width=8) (actual time=0.030..17980.200 rows=50000 loops=50)
                      Filter: (dept_id = d.dept_id)
```

### Root Cause
An un-indexed correlated subquery inside a `HAVING` clause (summing salaries per department to flag departments over a budget threshold) re-scanned the full, now-6x-larger `employes` table once per department — 50 departments × ~1M row scan each ≈ 50,000,000 row evaluations, versus roughly 8M the prior month. The query had no functional bug; it simply crossed a scale threshold where an already-inefficient plan became untenable.

### Fix Procedure & Refactored SQL
Replaced the correlated `HAVING` subquery with a pre-aggregated derived table joined once, backed by an index on the join key:

```sql
CREATE INDEX CONCURRENTLY idx_employes_dept ON employes (dept_id);

-- ✅ PRODUCTION REVISED QUERY (Execution Time: 640ms, down from >900,000ms)
SELECT d.dept_id, d.dept_name, dept_totals.total_salary
FROM departments d
JOIN (
    SELECT dept_id, SUM(salary) AS total_salary
    FROM employes
    GROUP BY dept_id
) dept_totals ON dept_totals.dept_id = d.dept_id
WHERE dept_totals.total_salary > 100000.00;
```

### Verification & Regression Test
- Re-run against the full 50,000-row post-acquisition dataset completed in 640ms.
- Added a data-volume regression test that re-runs this batch query against a synthetic dataset 10x current headcount, so the next acquisition-scale growth event is caught before it reaches production.

### Lessons Learned
- **Scale Is a Silent Trigger**: A query with no code changes can still cause a SEV without any deploy — data growth alone can cross a performance cliff. Batch jobs on business-critical deadlines need periodic re-validation against current data volume, not just at initial release.
- **HAVING Subqueries Deserve the Same Scrutiny as WHERE Subqueries**: Correlated subqueries inside `HAVING` are just as susceptible to the per-row re-execution problem as those in `WHERE`, but are audited less often in practice.

---

## Playbook Incident 5: Supply Chain Warehouse Fulfillment Over-Allocation (SEV-1)

- **System Context**: Multi-Warehouse Inventory Allocation Engine
- **Outage Duration**: Not a downtime outage — a 6-hour window of silently incorrect order allocation before detection.
- **Affected Services**: Order fulfillment allocation job; downstream warehouse picking systems.

### Symptoms
- Warehouse operations reported 1,200 orders allocated against inventory that had already been reserved for other orders, causing duplicate picking instructions.
- No errors or failed jobs — the allocation query ran successfully and "fast."

### Diagnosis
A recent PR, intended to "optimize" a slow `EXISTS` filter, had replaced it with an `INNER JOIN` against the same inner table without adding a `DISTINCT` or `GROUP BY`. Reviewing the diff:

```sql
-- ❌ SEV-1 BUG: JOIN duplicates outer rows when warehouse_inventory has multiple matching rows per item
SELECT o.order_id, o.item_id, o.qty_requested
FROM orders o
JOIN warehouse_inventory wi ON wi.item_id = o.item_id AND wi.qty_available > 0;
```

### Execution Plan Breakdown
```text
Hash Join  (cost=1200.00..8400.00 rows=15400 width=24) (actual time=2.100..44.900 rows=15400 loops=1)
  Hash Cond: (o.item_id = wi.item_id)
  -> Seq Scan on orders o (rows=8200 loops=1)
  -> Hash (rows=15400 loops=1)
       -> Seq Scan on warehouse_inventory wi (rows=15400 loops=1)
             Filter: (qty_available > 0)
```
The plan itself is fast and "correct" relative to the SQL as written — the row multiplication happened at the semantic level (each order joined against every warehouse holding stock of that item), not from any execution inefficiency, which is exactly why no error or alert fired.

### Root Cause
The original `EXISTS` query correctly expressed "does *any* warehouse have this item in stock" — a Semi-Join, returning at most one row per order regardless of how many warehouses matched. The `INNER JOIN` rewrite instead returned **one row per matching warehouse**, so an item stocked in 3 warehouses caused its order to be processed 3 times by the downstream allocation logic, each time deducting inventory as if it were a distinct order.

### Fix Procedure & Refactored SQL
Reverted to the `EXISTS` Semi-Join, and added an explicit code comment documenting why:

```sql
-- ✅ RESTORED: EXISTS preserves one-row-per-order Semi-Join semantics
SELECT o.order_id, o.item_id, o.qty_requested
FROM orders o
WHERE EXISTS (
    SELECT 1 FROM warehouse_inventory wi
    WHERE wi.item_id = o.item_id AND wi.qty_available > 0
);
-- NOTE: Do not replace with INNER JOIN — warehouse_inventory has a
-- many-to-one relationship with items, and a JOIN will duplicate orders
-- once per matching warehouse row. See Incident 5 postmortem.
```

### Verification & Regression Test
- Re-ran the allocation job against a copy of the incident-window dataset; order counts matched the pre-incident baseline exactly (8,200 orders, zero duplicates).
- Added a row-count invariant test asserting the allocation query's output row count never exceeds the input `orders` row count for the same date range — a cheap, general-purpose guard against future cardinality-changing rewrites.

### Lessons Learned
- **"Optimizing" a Semi-Join Into a Join Is a Correctness Change, Not Just a Performance One**: Any PR converting `EXISTS`/`IN` to `JOIN` must be reviewed for the inner table's cardinality relative to the join key, not just benchmarked for speed.
- **Silent Correctness Bugs Need Invariant Tests, Not Just Alerts**: This incident produced no errors, timeouts, or anomalous metrics — only a row-count invariant check would have caught it automatically.

---

## Related Modules

- [Module 10 — Execution Plans](./10_EXECUTION_PLANS.md)
- [Module 13 — Troubleshooting Guide](./13_TROUBLESHOOTING_GUIDE.md)
