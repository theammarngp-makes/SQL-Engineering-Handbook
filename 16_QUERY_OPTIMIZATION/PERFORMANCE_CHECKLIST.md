# Performance Checklist — Module 16

> **Module 16 · Query Optimization · Reference Library**
> [Home](./README.md) · [Smells](./PERFORMANCE_SMELLS.md) · [Best Practices](./BEST_PRACTICES.md) · [Troubleshooting](./TROUBLESHOOTING_GUIDE.md) · [Lesson 07](./07_QUERY_TUNING_WORKFLOW.md)

Use this checklist during code review, pre-deployment verification, and quarterly query audits. Each item maps to a specific lesson or reference document.

![Optimization Checklist](./assets/diagrams/optimization-checklist.svg)

---

## Query Shape Checklist

- [ ] **Projection**: Query selects only columns needed — no `SELECT *` ([Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md))
- [ ] **SARGability**: No functions, casts, or arithmetic on indexed columns in WHERE or JOIN ([Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md))
- [ ] **LIKE patterns**: No leading wildcard `%text` unless full-text/trigram index exists ([Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md))
- [ ] **Join syntax**: Explicit `JOIN ... ON` — no comma joins without join condition ([Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md))
- [ ] **NOT IN safety**: No `NOT IN` against nullable subquery columns — use `NOT EXISTS` ([Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md))
- [ ] **DISTINCT necessity**: `DISTINCT` is not masking a join fan-out — fix the join instead ([Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md))
- [ ] **Pagination**: No large `OFFSET` — keyset/cursor pagination used ([Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md))
- [ ] **OR conditions**: OR across unrelated columns split into `UNION ALL` where needed ([Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md))
- [ ] **Subquery form**: Correlated subqueries rewritten to window functions or joins where applicable ([Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md))
- [ ] **CTE behavior**: CTE materialization verified for engine/version — not assumed ([Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md))

---

## Index Checklist

- [ ] **Index exists** for every column used in WHERE equality/range filters on tables > 100K rows
- [ ] **Composite index column order** matches query filter pattern (equality columns first, range/ORDER BY second)
- [ ] **Leftmost prefix** rule respected — no query filtering only on trailing composite columns without alternative index
- [ ] **Covering index** considered for high-frequency queries that select few columns
- [ ] **No over-indexing** — each index justified by read query frequency vs. write overhead
- [ ] **Partial/filtered index** considered for queries targeting a subset of rows (e.g., `WHERE status = 'active'`)
- [ ] **Index usage verified** in `EXPLAIN` output — index exists but plan shows a full table scan (`Seq Scan` in PostgreSQL, `type: ALL` in MySQL) is a red flag

---

## Execution Plan Checklist

- [ ] **`EXPLAIN ANALYZE` run** against production-representative data volume
- [ ] **Most expensive node identified** (read plan bottom-up)
- [ ] **Estimated vs. actual row counts** compared — gap > 10x triggers statistics review
- [ ] **Join algorithm appropriate** for table sizes (nested loop for small outer + indexed inner; hash for large unindexed)
- [ ] **No unexpected Sort** before LIMIT that an index could eliminate
- [ ] **No SubPlan with loops > 1** on large outer tables
- [ ] **No hash spill to disk** (`Batches > 1` in PostgreSQL hash nodes)
- [ ] **Buffer/cache stats reviewed** — query I/O-bound vs. CPU-bound understood

---

## Statistics & Maintenance Checklist

- [ ] **Statistics current** — `ANALYZE` / `UPDATE STATISTICS` run after bulk loads or major data changes
- [ ] **Auto-analyze configured** with appropriate thresholds for high-churn tables
- [ ] **Plan cache monitored** — no silent plan regressions (Query Store / `pg_stat_statements`)
- [ ] **Index bloat monitored** on high-write tables
- [ ] **Table bloat / vacuum** healthy (PostgreSQL: `pg_stat_user_tables.n_dead_tup`)

---

## Application Layer Checklist

- [ ] **No N+1 pattern** — application not issuing one query per row in a loop
- [ ] **Parameterized queries** used — plan cache benefits from bind parameters
- [ ] **Connection pooling** configured — not opening new connections per query
- [ ] **Result set size bounded** — no unbounded `SELECT` returning millions of rows to application
- [ ] **Timeout configured** — `statement_timeout` / query timeout prevents runaway queries

---

## Monitoring Checklist

- [ ] **Slow query log enabled** with appropriate threshold (e.g., > 1 second)
- [ ] **`pg_stat_statements` / Query Store** capturing top queries by total time
- [ ] **Alert on plan change** for critical queries
- [ ] **Baseline metrics recorded** before and after any optimization change
- [ ] **Dashboard for p95 query latency** on critical endpoints

---

## Deployment Checklist

- [ ] **One change at a time** — index OR rewrite OR statistics, not all three
- [ ] **Index created online** — `CREATE INDEX CONCURRENTLY` (PG) / `WITH (ONLINE = ON)` (SQL Server)
- [ ] **Rollback documented** — how to revert index or query change
- [ ] **Tested on replica** before applying to primary
- [ ] **Write impact assessed** — new index impact on INSERT/UPDATE throughput measured

---

## Scoring Guide

| Score | Meaning | Action |
|---|---|---|
| 90–100% | Production-ready | Ship with confidence |
| 70–89% | Minor gaps | Address flagged items before merge |
| 50–69% | Significant risk | Block merge until plan reviewed |
| < 50% | Not production-ready | Rework query shape before any index work |

---

## Related Documents

- [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md) — active incident diagnostics
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) — engineering standards
- [PERFORMANCE_SMELLS.md](./PERFORMANCE_SMELLS.md) — 50+ code smell catalog
- [07 — Query Tuning Workflow](./07_QUERY_TUNING_WORKFLOW.md) — the five-step process
- [OPTIMIZATION_PLAYBOOK.md](./OPTIMIZATION_PLAYBOOK.md) — scenario-specific tuning sequences

[← Back to Module Home](./README.md)
