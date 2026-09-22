# Real-World Casebook — Query Optimization

End-to-end case studies connecting business problems to optimization solutions. Each case maps to lessons and engineering documents in this module.

> **Illustrative material.** Company contexts, scale figures, benchmark results, timings, and business impacts in this document are illustrative unless an external source is explicitly cited. They are composites built to teach a diagnostic pattern, not verified production incidents from named companies. For sourced, real incident write-ups, see [PRODUCTION_INCIDENTS.md](./PRODUCTION_INCIDENTS.md), which cites its sources directly.
>
> **Engine labels.** Every case below is labeled with the database engine its query and diagnosis assume (`MySQL`, `PostgreSQL`, `SQL Server`, `Oracle`, or `Cross-engine` where the pattern applies broadly). Vendor-specific syntax and plan terminology (e.g. `pg_trgm`, `OPTION (RECOMPILE)`, `Seq Scan`) is **not** portable SQL — it is called out explicitly so it is never mistaken for standard behavior on another engine. This module's labs target MySQL 8.x; cases labeled for other engines are included for pattern-recognition value only and are not runnable against this module's MySQL schema.

---

## Case 1: HR Compliance Reporting at Scale

**Engine: Cross-engine (MySQL / PostgreSQL / SQL Server — illustrative)**

**Company context** *(illustrative)*: Global enterprise, 180,000 employees across 40 countries.

**Business problem**: "Employees hired in 2023" compliance report times out during quarterly audit window.

**Query**:
```sql
SELECT emp_name, hire_date, dept_id
FROM employes
WHERE YEAR(hire_date) = 2023;
```

**Diagnosis**: `YEAR(hire_date)` wraps the indexed column, making the predicate non-SARGable, so the optimizer falls back to a full table scan of 180K rows instead of an index range scan. (`YEAR()` is valid in MySQL and SQL Server; PostgreSQL's equivalent is `EXTRACT(YEAR FROM hire_date)`. "Full table scan" is used here as the engine-neutral term — PostgreSQL's `EXPLAIN` labels this `Seq Scan`; MySQL's labels it `type: ALL`.)

**Solution**: SARGable range rewrite (`hire_date >= '2023-01-01' AND hire_date < '2024-01-01'`) + existing index on `hire_date`.

**Result** *(illustrative)*: 45 seconds → 120ms.

**Lessons**: [03 — SARGability](./03_SARGABILITY_AND_INDEX_USAGE.md), [REWRITE_COOKBOOK #1](./REWRITE_COOKBOOK.md)

---

## Case 2: E-Commerce Product Search

**Engine: PostgreSQL**

**Company context** *(illustrative)*: Online retailer, 2M products, peak traffic during sales events.

**Business problem**: Product search by name takes 8+ seconds during Black Friday.

**Query**:
```sql
SELECT product_id, product_name, price
FROM products
WHERE UPPER(product_name) LIKE '%' || UPPER(@search_term) || '%'
ORDER BY price
LIMIT 50;
```

**Diagnosis**: Leading wildcard (`LIKE '%...%'`) plus a function wrapped around the column defeats a standard B-tree index, forcing a full table scan and sort on every search.

**Solution (PostgreSQL-specific)**: A `pg_trgm` trigram GIN/GIST index — a PostgreSQL extension, not standard SQL and not available in MySQL, SQL Server, or Oracle without an equivalent vendor-specific feature (e.g. MySQL's `FULLTEXT` index, SQL Server's Full-Text Search) — plus prefix search where the business allows it; full-text search for substring requirements.

**Result** *(illustrative)*: 8,000ms → 25ms (prefix) / 180ms (trigram substring).

**Lessons**: [03 — SARGability](./03_SARGABILITY_AND_INDEX_USAGE.md), [PERFORMANCE_SMELLS #3, #4](./PERFORMANCE_SMELLS.md)

---

## Case 3: SaaS Multi-Tenant Dashboard

**Engine: SQL Server**

**Company context** *(illustrative)*: B2B SaaS platform, 50,000 tenants, shared database.

**Business problem**: Tenant dashboard query fast for small tenants, 30+ seconds for enterprise tenants with 500K records.

**Query**:
```sql
SELECT event_type, COUNT(*) AS event_count
FROM events
WHERE tenant_id = @tenant_id
  AND created_at >= @start_date
GROUP BY event_type;
```

**Diagnosis**: Composite index on `(tenant_id, created_at)` exists, but parameter sniffing cached a plan optimized for a small tenant (the first execution had 50 rows), and that plan was reused for enterprise tenants with much larger row counts. Parameter sniffing and plan caching behave differently across engines — this specific mechanism and fix are SQL Server's.

**Solution (SQL Server-specific)**: `OPTION (RECOMPILE)` for tenant-specific queries — a SQL Server query hint with no direct equivalent in MySQL or PostgreSQL — plus separate query paths for tenant size tiers.

**Result** *(illustrative)*: Enterprise tenant query: 30,000ms → 450ms.

**Lessons**: [01 — Plan Cache / Parameter Sniffing](./01_QUERY_EXECUTION_LIFECYCLE.md), [OPTIMIZATION_PLAYBOOK #3](./OPTIMIZATION_PLAYBOOK.md)

---

## Case 4: Financial Reconciliation Batch

**Engine: Cross-engine (pattern applies to MySQL, PostgreSQL, SQL Server, Oracle)**

**Company context** *(illustrative)*: Payment processor, 500M transactions/month.

**Business problem**: Nightly reconciliation job exceeded 6-hour window after transaction volume doubled.

**Query**:
```sql
SELECT t.account_id,
    (SELECT SUM(amount) FROM transactions t2
     WHERE t2.account_id = t.account_id
       AND t2.status = 'pending') AS pending_total
FROM accounts t
WHERE t.last_activity >= CURRENT_DATE - 30;
```

**Diagnosis**: Correlated scalar subquery in the `SELECT` list — the subquery re-executes once per outer row (roughly 2M active accounts), which every major engine plans as some form of nested-loop re-evaluation, though the exact plan node name differs (e.g. PostgreSQL's `SubPlan`).

**Solution**: Window function rewrite with a pre-filtered CTE — standard SQL (window functions and CTEs), supported by MySQL 8+, PostgreSQL, SQL Server, and Oracle.

**Result** *(illustrative)*: 6.5 hours → 18 minutes.

**Lessons**: [05 — Subquery Optimization](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md), [PRODUCTION_INCIDENTS #3 (Uber)](./PRODUCTION_INCIDENTS.md)

---

## Case 5: Logistics Inventory Pagination

**Engine: MySQL / PostgreSQL** (`LIMIT ... OFFSET` syntax; SQL Server and Oracle use `OFFSET ... FETCH NEXT` instead)

**Company context** *(illustrative)*: Warehouse management system, 800M SKU-location records.

**Business problem**: Inventory listing page 100+ unusable; warehouse staff resorting to CSV exports.

**Query**:
```sql
SELECT sku, location, quantity
FROM inventory
WHERE warehouse_id = @wh_id
ORDER BY sku
LIMIT 50 OFFSET @page * 50;
```

**Diagnosis**: `OFFSET`-based pagination requires the engine to generate and discard the preceding rows on every page — page 100 at 50 rows/page means scanning and discarding roughly 5,000 rows before returning results, and the cost grows with page depth.

**Solution**: Keyset (seek) pagination on `(warehouse_id, sku)`, replacing `OFFSET` with a `WHERE (warehouse_id, sku) > (last_seen_warehouse, last_seen_sku)` predicate. This pattern applies across MySQL, PostgreSQL, SQL Server, and Oracle, though the exact tuple-comparison syntax varies by engine.

**Result** *(illustrative)*: Page 100: 12,000ms → 8ms (flat across all pages).

**Lessons**: [06 — Anti-Patterns #9](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md), [PRODUCTION_INCIDENTS #4 (GitHub)](./PRODUCTION_INCIDENTS.md)

---

## Case 6: Healthcare Claims Analytics

**Engine: Cross-engine** (partitioning and statistics maintenance exist in MySQL, PostgreSQL, SQL Server, and Oracle, but with different syntax and defaults)

**Company context** *(illustrative)*: Insurance provider, 2B claims records, strict HIPAA audit windows.

**Business problem**: Monthly claims summary report must complete within 2-hour audit window; recently taking 4+ hours.

**Query**:
```sql
SELECT provider_id, claim_type, SUM(paid_amount)
FROM claims
WHERE service_date >= '2025-01-01'
  AND service_date < '2026-01-01'
  AND status IN ('paid', 'partially_paid')
GROUP BY provider_id, claim_type;
```

**Diagnosis**: No partition pruning — the optimizer scans all historical partitions despite the date filter, because statistics went stale after a year-end bulk import and the planner could no longer estimate partition selectivity correctly.

**Solution**: Partition by `service_date` (monthly) — MySQL `PARTITION BY RANGE`, PostgreSQL declarative partitioning, or the equivalent in SQL Server/Oracle — refresh statistics post-import (`ANALYZE TABLE` in MySQL, `ANALYZE` in PostgreSQL, `UPDATE STATISTICS` in SQL Server), and add a composite index on `(service_date, status, provider_id)`.

**Result** *(illustrative)*: 4.2 hours → 35 minutes.

**Lessons**: [CROSS_DATABASE — Partitioning](./CROSS_DATABASE_ENGINEERING.md), [01 — Statistics](./01_QUERY_EXECUTION_LIFECYCLE.md)

---

## Related Documents

- [PRODUCTION_INCIDENTS.md](./PRODUCTION_INCIDENTS.md) — detailed post-mortems
- [REWRITE_COOKBOOK.md](./REWRITE_COOKBOOK.md) — canonical fixes
- [Performance_lab/](./Performance_lab/) — hands-on benchmarks
