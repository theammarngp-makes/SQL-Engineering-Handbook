# Best Practices — Query Optimization

> **Module 16 · Query Optimization · Reference Library**
> [Home](./README.md) · [Checklist](./PERFORMANCE_CHECKLIST.md) · [Common Mistakes](./COMMON_MISTAKES.md) · [Lesson 07](./07_QUERY_TUNING_WORKFLOW.md)

Engineering standards for writing, reviewing, and deploying SQL at production scale.

---

## Writing SQL for Performance

1. **Select only needed columns.** Never `SELECT *` in production queries. Explicit projection enables covering indexes and reduces network transfer.

2. **Keep indexed columns bare in predicates.** No functions, casts, or arithmetic on the column side of comparisons. Transform the constant instead.

3. **Use explicit JOIN syntax.** Always `JOIN ... ON`. Comma joins without ON conditions create cartesian products silently.

4. **Prefer NOT EXISTS over NOT IN.** NULL-safe, typically compiles to anti-join, no three-valued logic traps.

5. **Prefer EXISTS over IN for existence checks.** Short-circuits on first match; clearer intent.

6. **Use window functions for per-group calculations.** Replace correlated subqueries computing ranks, running totals, or group aggregates.

7. **Use keyset pagination.** Replace `OFFSET n` with `WHERE cursor_col > last_value ORDER BY cursor_col LIMIT n`.

8. **Parameterize queries.** Use bind parameters (`$1`, `?`, `@param`) to benefit from plan cache reuse.

9. **State production data volume.** Every performance claim in documentation and PRs should specify assumed row counts.

10. **One change at a time during tuning.** Add one index OR rewrite one predicate OR refresh statistics — never all three simultaneously.

---

## Index Design

1. **Index for your actual query patterns**, not hypothetical future queries.
2. **Composite index column order**: equality columns first, then range/ORDER BY columns.
3. **Covering indexes** for high-frequency queries selecting few columns from large tables.
4. **Partial indexes** for queries targeting a subset of rows (e.g., `WHERE status = 'active'`).
5. **Audit existing indexes** before adding new ones — remove unused indexes identified via engine statistics.
6. **Create indexes online** in production: `CONCURRENTLY` (PG), `ONLINE = ON` (SQL Server).
7. **Monitor index bloat** on high-write tables, especially before peak traffic events.

---

## Execution Plan Review

1. **Prefer EXPLAIN ANALYZE over plan-only EXPLAIN** for slow query diagnosis, since it reports actual row counts and timings alongside the estimates. Exception: EXPLAIN ANALYZE executes the query (including any writes), so for expensive or mutating statements, review the plan-only EXPLAIN first or run ANALYZE inside a transaction you intend to roll back.
2. **Read plans bottom-up** — innermost nodes execute first.
3. **Compare estimated vs. actual row counts** — gap > 10× means stale statistics.
4. **Identify the single most expensive node** before proposing any fix.
5. **Check for SubPlan with loops > 1** — correlated subquery not rewritten.
6. **Check for hash spill** (Batches > 1) — work_mem exhaustion.
7. **Review on production-representative data** — dev datasets hide performance problems.

---

## Statistics & Maintenance

1. **Run ANALYZE after bulk loads**, schema changes, or major DELETE operations.
2. **Configure auto-analyze** with appropriate thresholds for high-churn tables.
3. **Monitor plan regressions** via Query Store (SQL Server) or pg_stat_statements (PostgreSQL).
4. **Schedule regular index bloat checks** on high-write tables.

---

## Application Layer

1. **Eliminate N+1 queries** — batch related lookups into single set-based queries.
2. **Set statement timeouts** — prevent runaway queries from exhausting connection pools.
3. **Use connection pooling** — PgBouncer, RDS Proxy, or engine-native pooler.
4. **Bound result sets** — always LIMIT or cursor; never unbounded SELECT to application.
5. **Cache expensive read queries** at the application layer when appropriate (Redis, materialized views).

---

## Code Review Standards

1. Every query touching tables > 100K rows must include EXPLAIN ANALYZE in the PR.
2. No `NOT IN` against nullable columns — reject in review.
3. No `SELECT *` in production code paths.
4. No large OFFSET without documented keyset alternative.
5. Assumed production data volume stated in PR description.

---

## Related Documents

- [PERFORMANCE_CHECKLIST.md](./PERFORMANCE_CHECKLIST.md)
- [PERFORMANCE_SMELLS.md](./PERFORMANCE_SMELLS.md)
- [07 — Query Tuning Workflow](./07_QUERY_TUNING_WORKFLOW.md)
- [COMMON_MISTAKES.md](./COMMON_MISTAKES.md)

[← Back to Module Home](./README.md)
