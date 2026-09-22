# Performance Lab — SARGability Benchmark

Hands-on benchmark exercise demonstrating the impact of SARGable vs. non-SARGable predicates.

---

## Objective

Measure the performance difference between a function-wrapped column predicate and its SARGable range rewrite on the `employes` table.

## Prerequisites

- **MySQL 8.0.18+** (required for `EXPLAIN ANALYZE` support)
- `employes` table from `00_Schema.sql` (~5,000 rows in seed data)
- Index on `hire_date`: `CREATE INDEX idx_employes_hire_date ON employes (hire_date);`

> **Environment Note:** Performance differences are more dramatic with larger datasets. The 5,000-row seed data demonstrates the plan-shape changes; for timing benchmarks, consider generating additional test data. Results vary by hardware, OS, buffer pool size, and cold/warm cache state.

## Dataset Setup

```sql
-- Verify row count
SELECT COUNT(*) FROM employes;

-- Verify index exists (MySQL)
SHOW INDEX FROM employes;
```

---

## Baseline Query (Version 0)

Non-SARGable: function on indexed column.

```sql
EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE EXTRACT(YEAR FROM hire_date) = 2023;
```

**Expected plan (MySQL)**: `Table scan on employes` — the function prevents index usage.

Record: actual time, rows examined, and plan shape.

---

## Version 1: SARGable Range Rewrite

```sql
EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE hire_date >= '2023-01-01'
  AND hire_date < '2024-01-01';
```

**Expected plan (MySQL)**: `Index range scan` on `idx_employes_hire_date`

---

## Version 2: Covering Index

```sql
-- MySQL InnoDB does not support INCLUDE — use a composite index instead.
-- The composite index contains all columns needed by the query, so no
-- table lookup is required (equivalent to an "Index Only Scan" in PostgreSQL).
-- CREATE INDEX idx_employes_hire_covering
--     ON employes (hire_date, emp_name);

EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE hire_date >= '2023-01-01'
  AND hire_date < '2024-01-01';
```

**Expected plan (MySQL)**: `Index range scan` with `Using index` (covering index — no table lookup)

> **PostgreSQL note:** PostgreSQL supports `CREATE INDEX ... INCLUDE (emp_name)` for covering indexes, which adds non-key columns to leaf pages without affecting the index sort order.

---

## Version 3: Expression Index (MySQL 8.0.13+)

MySQL 8.0.13+ supports functional/expression indexes. This version creates an index on the exact expression used in Version 0.

```sql
-- CREATE INDEX idx_employes_hire_year
--     ON employes ((YEAR(hire_date)));

EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE YEAR(hire_date) = 2023;
```

> **Note:** MySQL does not support partial indexes (PostgreSQL `WHERE` clause on `CREATE INDEX`). Use expression indexes or composite indexes as alternatives.

---

## Benchmark Results Template

Run each version 5 times (after one warmup run). Record the median. With only 5,000 rows, timing differences may be small; focus on plan-shape changes (access type, rows examined).

| Version | Plan Node (MySQL) | Median (ms) | Rows Examined | Access Type |
|---|---|---|---|---|
| v0: EXTRACT(YEAR) | Table scan | | | ALL |
| v1: Range rewrite | Index range scan | | | range |
| v2: Covering index | Index range scan (Using index) | | | range |
| v3: Expression index | Index ref/range | | | ref or range |

### Before vs. After

| Metric | v0 (baseline) | Best version | Change |
|---|---|---|---|
| Access type | ALL (table scan) | range (index) | ✓ |
| Rows examined | | | |
| Median time | | | |

---

## Cold Cache vs. Warm Cache

```sql
-- MySQL: flush query cache and buffer pool (requires SUPER privilege)
-- RESET QUERY CACHE;  -- removed in MySQL 8.0
-- FLUSH TABLES;       -- closes and reopens all tables

-- For a true cold cache test, restart the MySQL server.
-- InnoDB buffer pool state persists across FLUSH TABLES.
-- On Linux: sync && echo 3 > /proc/sys/vm/drop_caches (requires root)
```

> **Note:** Neither `FLUSH TABLES` nor closing client connections flushes InnoDB's buffer pool or the OS page cache — both persist across those commands. A true cold-cache test requires restarting the MySQL server and clearing the OS page cache (see above).

| Cache State | v0 (ms) | v1 (ms) |
|---|---|---|
| Cold | | |
| Warm | | |

---

## Lessons Learned

1. Wrapping an indexed column in a function typically makes the predicate non-SARGable, so the optimizer usually falls back to a full table scan on a plain B-tree index — unless a matching functional/expression index exists for that exact expression. Confirm with EXPLAIN rather than assuming.
2. SARGable rewrite → index range scan (improvement varies by dataset size and selectivity; measure in your environment)
3. Covering index → eliminates table lookup (further improvement depends on row width and I/O pattern)
4. Cold cache amplifies I/O-bound differences — observed effect size depends on hardware and OS cache behavior

---

## Related

- [Lesson 03 — SARGability](./../03_SARGABILITY_AND_INDEX_USAGE.md)
- [BENCHMARK_GUIDE.md](./../BENCHMARK_GUIDE.md)
- [REWRITE_COOKBOOK #1](./../REWRITE_COOKBOOK.md)
