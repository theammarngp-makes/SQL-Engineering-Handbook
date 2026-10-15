[← Level 4](../05_DATABASE_ENGINEERING/QUESTION_BANK.md) · [Module Home](../README.md) · Level 5 (of 0–9)

# Level 5 — Real-World SQL

Pilot set: 8 of ~70 target questions, spanning multiple industries. Each
question defines a small inline schema for its domain, per this module's
dataset policy in `README.md`.

---

## Q032 — E-commerce: Customer Lifetime Value Ranking

**Difficulty:** 🟠 Advanced
**Category:** E-commerce, Window Functions
**Type:** A — Write SQL

### Scenario
A marketplace wants to rank customers by lifetime revenue, excluding
refunded orders, for a loyalty-tier assignment.

### Schema
`orders(order_id, customer_id, order_total, order_status, order_date)`
— `order_status` in `('completed', 'refunded', 'cancelled')`

### Problem
Rank customers by total revenue from completed orders only, and assign a
loyalty tier: top 10% = 'Gold', next 20% = 'Silver', rest = 'Standard'.

### Expected SQL
```sql
WITH customer_revenue AS (
    SELECT customer_id, SUM(order_total) AS lifetime_revenue
    FROM orders
    WHERE order_status = 'completed'
    GROUP BY customer_id
),
ranked AS (
    SELECT customer_id, lifetime_revenue,
        PERCENT_RANK() OVER (ORDER BY lifetime_revenue DESC) AS pct_rank
    FROM customer_revenue
)
SELECT customer_id, lifetime_revenue,
    CASE
        WHEN pct_rank <= 0.10 THEN 'Gold'
        WHEN pct_rank <= 0.30 THEN 'Silver'
        ELSE 'Standard'
    END AS loyalty_tier
FROM ranked;
```

### Explanation
`PERCENT_RANK()` gives each row's relative standing as a fraction
(0 = top), which maps naturally onto percentile-based tier cutoffs — far
more direct than manually computing count-based thresholds with
`NTILE()` or manual row-counting.

### Common Mistake
Filtering `order_status = 'completed'` in a `WHERE` clause applied
*after* an unfiltered `SUM` — silently including refunded revenue in the
total if the filter is placed incorrectly relative to the aggregation.

### Interviewer Follow-Up
"How would this change if 'lifetime revenue' should account for partial
refunds (a completed order later partially refunded), not just fully
refunded orders?"

### Senior-Level Extension
"The business now wants tiers recalculated monthly, with a customer's
tier only allowed to move DOWN one level per month even if their
percentile would justify a bigger drop (to avoid loyalty-program churn).
How would you design this — is it even a single-query problem?"

---

## Q033 — Fintech: Detecting Potential Duplicate Transactions

**Difficulty:** 🔴 Expert
**Category:** Fintech, Fraud Detection
**Type:** A — Write SQL

### Scenario
A payment processor wants to flag potentially duplicate transactions —
same account, same amount, within a 60-second window — for manual review.

### Schema
`transactions(txn_id, account_id, amount, txn_timestamp)`

### Problem
Find every pair of transactions from the same account, same amount,
where the timestamps are within 60 seconds of each other.

### Expected SQL
```sql
SELECT t1.txn_id AS txn_a, t2.txn_id AS txn_b,
    t1.account_id, t1.amount,
    t1.txn_timestamp AS time_a, t2.txn_timestamp AS time_b
FROM transactions t1
JOIN transactions t2
    ON t1.account_id = t2.account_id
   AND t1.amount = t2.amount
   AND t1.txn_id < t2.txn_id  -- avoid self-match and duplicate pairs
   AND ABS(TIMESTAMPDIFF(SECOND, t1.txn_timestamp, t2.txn_timestamp)) <= 60;
```
*(MySQL: `TIMESTAMPDIFF(SECOND, ...)`. PostgreSQL equivalent:
`EXTRACT(EPOCH FROM (t2.txn_timestamp - t1.txn_timestamp))`.)*

### Explanation
The self-join on matching `account_id`/`amount` finds candidate pairs;
`t1.txn_id < t2.txn_id` prevents comparing a transaction to itself and
avoids reporting each pair twice (A-B and B-A); the timestamp difference
check enforces the 60-second window in both directions via `ABS()`.

### Common Mistake
Omitting the `t1.txn_id < t2.txn_id` guard — every transaction would
match itself (0-second difference, same amount, same account), flooding
the results with meaningless self-pairs.

### Performance Consideration
This self-join on `(account_id, amount)` needs a supporting composite
index on those columns at production transaction volume, or it degrades
to comparing every transaction against every other transaction for the
same account — see Module 16's join optimization lesson for the general
mechanism.

### Interviewer Follow-Up
"This flags legitimate rapid repeated purchases too (e.g., buying two
identical items back to back). How would you reduce false positives
without missing real duplicates?"

---

## Q034 — SaaS: Monthly Recurring Revenue (MRR) Waterfall

**Difficulty:** 🔴 Expert
**Category:** SaaS, Subscription Analytics
**Type:** A — Write SQL

### Scenario
A subscription business needs a monthly MRR waterfall: new MRR, expansion
MRR (upgrades), contraction MRR (downgrades), and churned MRR.

### Schema
`subscription_events(customer_id, event_month, event_type, mrr_delta)`
— `event_type` in `('new', 'expansion', 'contraction', 'churn')`,
`mrr_delta` is signed (positive for new/expansion, negative for
contraction/churn)

### Problem
Produce one row per month with each MRR movement type summed separately,
plus a running total of net MRR.

### Expected SQL
```sql
SELECT
    event_month,
    SUM(CASE WHEN event_type = 'new' THEN mrr_delta ELSE 0 END) AS new_mrr,
    SUM(CASE WHEN event_type = 'expansion' THEN mrr_delta ELSE 0 END) AS expansion_mrr,
    SUM(CASE WHEN event_type = 'contraction' THEN mrr_delta ELSE 0 END) AS contraction_mrr,
    SUM(CASE WHEN event_type = 'churn' THEN mrr_delta ELSE 0 END) AS churned_mrr,
    SUM(SUM(mrr_delta)) OVER (ORDER BY event_month) AS cumulative_mrr
FROM subscription_events
GROUP BY event_month
ORDER BY event_month;
```

### Explanation
Conditional aggregation (Q010, Q029's pattern) isolates each movement
type into its own column; the nested `SUM(SUM(mrr_delta)) OVER (ORDER BY
event_month)` is a window function applied to an already-aggregated
value — the inner `SUM` produces one net-change value per month, the
outer windowed `SUM` turns that into a running cumulative total across
months.

### Interviewer Follow-Up
"Why does the window function wrap SUM(mrr_delta) rather than one of the
individual conditional columns? What would change if you windowed
new_mrr alone instead?"

### Senior-Level Extension
"The business also wants 'reactivation MRR' (a churned customer coming
back) tracked separately from 'new.' How would you need to change the
underlying event data model, not just the query, to support this
distinction correctly?" (Tests schema-design judgment, not just query
skill — the query can't fix an underlying data model that conflates two
genuinely different business events.)

---

## Q035 — Healthcare: Readmission Rate Within 30 Days

**Difficulty:** 🟠 Advanced
**Category:** Healthcare, Temporal Analysis
**Type:** A — Write SQL

### Scenario
A hospital system tracks patient admissions and needs to compute the
30-day readmission rate — a standard healthcare quality metric.

### Schema
`admissions(admission_id, patient_id, admit_date, discharge_date)`

### Problem
For each discharge, determine whether the same patient was readmitted
within 30 days of that discharge.

### Expected SQL
```sql
SELECT a1.admission_id, a1.patient_id, a1.discharge_date,
    CASE WHEN EXISTS (
        SELECT 1 FROM admissions a2
        WHERE a2.patient_id = a1.patient_id
          AND a2.admit_date > a1.discharge_date
          AND a2.admit_date <= DATE_ADD(a1.discharge_date, INTERVAL 30 DAY)
    ) THEN TRUE ELSE FALSE END AS readmitted_within_30_days
FROM admissions a1;
```
*(MySQL: `DATE_ADD(date, INTERVAL 30 DAY)`. PostgreSQL equivalent:
`date + INTERVAL '30 days'`.)*

### Explanation
The correlated `EXISTS` check looks for any OTHER admission by the same
patient with an admit date strictly after this discharge but within the
30-day window — `a2.admit_date > a1.discharge_date` correctly excludes
the same admission record from matching itself, which a naive
`>= a1.discharge_date` could accidentally include depending on same-day
edge cases.

### Interviewer Follow-Up
"What if a patient has more than one admission within the 30-day window
— does this query correctly count the readmission rate, or could it
double count?" (Tests whether the candidate recognizes this query
correctly answers "was there at least one readmission" per discharge,
which is the standard metric definition — not "how many.")

### Senior-Level Extension
"Compute the overall 30-day readmission RATE (percentage) across the
whole hospital for a given month, using this per-discharge flag as a
building block."

---

## Q036 — Logistics: Identifying Delayed Shipments with SLA Breach

**Difficulty:** 🟡 Intermediate
**Category:** Logistics
**Type:** A — Write SQL

### Scenario
A logistics company promises delivery within an SLA that varies by
shipping tier, and needs a report of every shipment that breached its
SLA.

### Schema
`shipments(shipment_id, tier, ship_date, delivered_date)`,
`sla_by_tier(tier, sla_days)`

### Problem
List every shipment where the actual delivery time exceeded its tier's
SLA.

### Expected SQL
```sql
SELECT s.shipment_id, s.tier, s.ship_date, s.delivered_date,
    s.delivered_date - s.ship_date AS actual_days,
    sla.sla_days
FROM shipments s
JOIN sla_by_tier sla ON sla.tier = s.tier
WHERE s.delivered_date - s.ship_date > sla.sla_days;
```

### Common Mistake
Hardcoding SLA thresholds per tier directly in the query (`WHEN tier =
'express' THEN 2` etc.) instead of joining to a proper reference table —
this silently goes stale the moment business rules change the SLA for a
tier, requiring a code deploy instead of a data update.

### Interviewer Follow-Up
"What about shipments that haven't been delivered yet (delivered_date IS
NULL) but have already exceeded their SLA based on days elapsed so far?
How would you include those?"

---

## Q070 — Fintech: Reconciliation Deduplication

**Difficulty:** 🟠 Advanced
**Category:** Fintech, Deduplication
**Type:** A — Write SQL

### Scenario
A payments reconciliation job occasionally double-inserts the same
settled transaction (retry logic upstream doesn't guarantee
idempotency). Before totals are reported, duplicates must be removed —
keeping only the earliest-inserted copy of each true transaction.

### Schema
`settlements(settlement_id, external_txn_id, amount, inserted_at)` —
`external_txn_id` should be unique per real transaction but isn't
enforced at the database level.

### Problem
Identify and remove duplicate rows for the same `external_txn_id`,
keeping the earliest `inserted_at` row for each.

### Expected SQL
```sql
WITH ranked AS (
    SELECT settlement_id,
        ROW_NUMBER() OVER (
            PARTITION BY external_txn_id ORDER BY inserted_at ASC
        ) AS rn
    FROM settlements
)
DELETE FROM settlements
WHERE settlement_id IN (SELECT settlement_id FROM ranked WHERE rn > 1);
```

### Explanation
`ROW_NUMBER()` partitioned by the natural key assigns `1` to the
earliest-inserted row per `external_txn_id` and `2+` to every later
duplicate; deleting everything with `rn > 1` keeps exactly one row per
real transaction. The real fix is a unique constraint on
`external_txn_id` going forward — this query only remediates existing
damage.

### Interviewer Follow-Up
"Why should this cleanup query run inside a transaction, and what would
you check before committing it in production?"

---

## Q071 — SaaS: Monthly Cohort Retention

**Difficulty:** 🟠 Advanced
**Category:** SaaS, Cohort Analysis
**Type:** A — Write SQL

### Scenario
A SaaS product wants to know, for each signup month cohort, what
percentage of users were still active exactly 1 month later.

### Schema
`users(user_id, signup_date)`,
`activity_events(event_id, user_id, event_date)`

### Problem
For each signup month, compute the percentage of that cohort with at
least one activity event in their second calendar month after signup.

### Expected SQL
```sql
WITH cohorts AS (
    SELECT user_id, DATE_FORMAT(signup_date, '%Y-%m-01') AS cohort_month
    FROM users
),
month_1_active AS (
    SELECT DISTINCT c.user_id, c.cohort_month
    FROM cohorts c
    JOIN activity_events a ON a.user_id = c.user_id
    WHERE a.event_date >= DATE_ADD(c.cohort_month, INTERVAL 1 MONTH)
      AND a.event_date < DATE_ADD(c.cohort_month, INTERVAL 2 MONTH)
)
```
*(MySQL: `DATE_FORMAT(date, '%Y-%m-01')` truncates to month start;
`DATE_ADD(date, INTERVAL 1 MONTH)`. PostgreSQL equivalent:
`DATE_TRUNC('month', date)`; `date + INTERVAL '1 month'`.)*
```sql
SELECT c.cohort_month,
    COUNT(DISTINCT c.user_id) AS cohort_size,
    COUNT(DISTINCT m.user_id) AS retained,
    ROUND(100.0 * COUNT(DISTINCT m.user_id) / COUNT(DISTINCT c.user_id), 1) AS retention_pct
FROM cohorts c
LEFT JOIN month_1_active m ON m.user_id = c.user_id AND m.cohort_month = c.cohort_month
GROUP BY c.cohort_month
ORDER BY c.cohort_month;
```

### Explanation
The cohort is fixed by signup month; retention is computed against a
strictly-defined follow-up window (the second calendar month, not "30
days" — the two aren't the same and interviewers watch for that
conflation). `LEFT JOIN` plus `COUNT(DISTINCT m.user_id)` correctly
counts zero-retention cohorts instead of dropping them.

### Interviewer Follow-Up
"How would the query change to produce a full retention curve —
month 1, 2, 3... — instead of just month 1?"

---

## Q072 — Logistics: Late Delivery Root-Cause Segmentation

**Difficulty:** 🟠 Advanced
**Category:** Logistics, Segmentation
**Type:** A — Write SQL

### Scenario
A logistics company wants to know which combination of carrier and
origin warehouse has the worst on-time delivery rate, but only among
routes with enough volume to be statistically meaningful.

### Schema
`shipments(shipment_id, carrier, origin_warehouse, promised_date,
delivered_date)`

### Problem
For carrier/warehouse pairs with at least 30 shipments, report the
late-delivery rate, worst first.

### Expected SQL
```sql
SELECT carrier, origin_warehouse,
    COUNT(*) AS shipment_count,
    ROUND(100.0 * SUM(CASE WHEN delivered_date > promised_date THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS late_pct
FROM shipments
GROUP BY carrier, origin_warehouse
HAVING COUNT(*) >= 30
ORDER BY late_pct DESC;
```

### Explanation
The `HAVING COUNT(*) >= 30` volume floor exists specifically to prevent
a carrier/warehouse pair with 2 shipments (one late = 50%) from
outranking a pair with 500 shipments and a genuinely worse absolute
problem — a classic small-sample-size trap in "worst performer"
reporting that interviewers expect a candidate to catch unprompted.

### Interviewer Follow-Up
"A stakeholder wants the volume floor removed entirely. What's the risk
in doing that, and how would you push back or compromise?"

---

[← Level 4](../05_DATABASE_ENGINEERING/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 6 — Production Debugging](../07_PRODUCTION_DEBUGGING/QUESTION_BANK.md)
