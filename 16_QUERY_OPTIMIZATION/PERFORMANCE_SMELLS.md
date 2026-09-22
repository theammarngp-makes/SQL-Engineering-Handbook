# Performance Smells — 50+ Query Optimization Code Smells

> **Module 16 · Query Optimization · Reference Library**
> [Home](./README.md) · [Checklist](./PERFORMANCE_CHECKLIST.md) · [Anti-Patterns Lesson](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) · [Rewrite Cookbook](./REWRITE_COOKBOOK.md)

A catalog of SQL patterns that *look* reasonable but predictably degrade at production scale. Use during code review, incident post-mortems, and interview preparation.

Each smell includes: **Smell → Why It's Expensive → Fix → Reference**.

---

## Category 1: Predicate & Index Smells (1–12)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 1 | `SELECT *` | Pulls all columns; defeats covering indexes | Explicit column list | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 2 | `WHERE YEAR(col) = 2023` | Function on column → non-SARGable | Range predicate on bare column | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 3 | `WHERE UPPER(col) = 'X'` | Function on column → full scan (Seq Scan/type ALL) | CI collation or functional index | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 4 | `WHERE col LIKE '%text'` | Leading wildcard → index unusable | Full-text/trigram index or prefix search | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 5 | `WHERE int_col = '4'` | Implicit type conversion on column | Match literal type to column type | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 6 | `WHERE col + 0 = 5` | Arithmetic on column → non-SARGable | `WHERE col = 5` | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 7 | `WHERE CAST(col AS VARCHAR) = 'x'` | Explicit cast on column | Compare without cast | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 8 | `WHERE col IS NOT NULL` on nullable index | Often can't use index efficiently | Partial index: `WHERE col IS NOT NULL` | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 9 | `WHERE col != value` | Inequality → low selectivity, often a full scan (Seq Scan/type ALL) | Evaluate if filter is selective enough to index | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 10 | `WHERE col BETWEEN a AND b` on low-cardinality col | Scans most of table anyway | Evaluate selectivity; may not need index | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 11 | Filter on trailing composite index column only | Leftmost prefix rule violated | Reorder index or add separate index | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 12 | `OR` across unrelated indexed columns | Single index can't serve both branches | Split into `UNION ALL` | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |

---

## Category 2: Join Smells (13–20)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 13 | Comma join without ON condition | Cartesian product | Explicit `JOIN ... ON` | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 14 | Join on expression: `ON UPPER(a.col) = UPPER(b.col)` | Non-SARGable join key | Join on bare columns | [04](./04_JOIN_OPTIMIZATION.md) |
| 15 | Joining tables not needed in result | Unnecessary join work | Remove unused joins | [04](./04_JOIN_OPTIMIZATION.md) |
| 16 | Large × large join, neither side indexed | Full hash join on both sides | Index join columns | [04](./04_JOIN_OPTIMIZATION.md) |
| 17 | Nested Loop on large outer without inner index | O(N×M) row comparisons | Index inner join column | [04](./04_JOIN_OPTIMIZATION.md) |
| 18 | 8+ table join with no filter early | Join order explosion | Push filters down; reduce join width | [04](./04_JOIN_OPTIMIZATION.md) |
| 19 | Cross-database join in application | Network round-trips per join | Denormalize or use federated query engine | [04](./04_JOIN_OPTIMIZATION.md) |
| 20 | Join on calculated/derived column without index | Expression not indexed | Persist computed column + index it | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |

---

## Category 3: Subquery & CTE Smells (21–30)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 21 | `NOT IN` with nullable subquery column | Returns zero rows (3VL bug) | `NOT EXISTS` | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 22 | Correlated subquery in SELECT list | Re-executes per outer row | Window function or join | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 23 | Correlated subquery for per-group MAX/MIN | O(N×M) per-row evaluation | `MAX() OVER (PARTITION BY ...)` | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 24 | `IN (SELECT ...)` for existence check | Materializes full subquery set | `EXISTS` | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 25 | CTE assumed materialized (PG < 12) | Optimization fence blocked pushdown | Inline or upgrade PG | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 26 | CTE referenced 3×, inlined 3× | Recomputes expensive CTE each time | `MATERIALIZED` keyword | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 27 | Deeply nested CTEs (5+ levels) | Planner can't optimize across boundaries | Flatten to fewer levels | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 28 | Scalar subquery returning multiple rows | Runtime error or wrong result | Aggregate subquery or LIMIT 1 | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 29 | Subquery in WHERE that could be JOIN | Misses join optimization | Rewrite to JOIN | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |
| 30 | Recursive CTE without cycle guard | Infinite loop until resource limit | Depth limit or cycle detection | [05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md) |

---

## Category 4: Aggregation & Sort Smells (31–38)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 31 | `DISTINCT` masking join fan-out | Sort/hash dedup on inflated set | Fix join or use EXISTS | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 32 | `GROUP BY` on unindexed expression | Sort entire result set | Index expression or pre-compute | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 33 | `ORDER BY RAND()` (MySQL) / `ORDER BY RANDOM()` (PostgreSQL) | Full scan + sort every call | Pre-computed random key | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 34 | `ORDER BY` column not in index | Explicit Sort node in plan | Index matching ORDER BY | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 35 | `HAVING` when `WHERE` would suffice | Filters after aggregation | Move filter to WHERE | [01](./01_QUERY_EXECUTION_LIFECYCLE.md) |
| 36 | Aggregating then joining (wrong order) | Aggregates more rows than needed | Filter/aggregate before join | [04](./04_JOIN_OPTIMIZATION.md) |
| 37 | `COUNT(*)` on large table without filter | Full scan | Add WHERE or use approximate count | [02](./02_EXPLAIN_AND_EXECUTION_PLANS.md) |
| 38 | `SELECT DISTINCT` + `ORDER BY` unindexed col | Two expensive sort passes | Composite index or rewrite | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |

---

## Category 5: Pagination & Result Set Smells (39–44)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 39 | `LIMIT 20 OFFSET 100000` | Generates and discards 100K rows | Keyset pagination | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 40 | Unbounded result set to application | Memory/network exhaustion | Always use LIMIT or cursor | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 41 | Fetching all rows to count them in app | Transfers entire table | `SELECT COUNT(*)` in SQL | [02](./02_EXPLAIN_AND_EXECUTION_PLANS.md) |
| 42 | Keyset pagination on non-unique sort col | Duplicate/missing rows across pages | Add tiebreaker column to sort key | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 43 | Page number pagination on sorted view | View prevents index pushdown | Query base table with keyset | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 44 | `TOP 100 PERCENT` (SQL Server) | No optimization benefit; adds sort | Remove it | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |

---

## Category 6: Application & Architecture Smells (45–50)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 45 | N+1 queries in application loop | N round-trips × parse/plan overhead | Single batched query or JOIN | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 46 | Literal values instead of bind params | Plan cache miss every call | Parameterized queries | [01](./01_QUERY_EXECUTION_LIFECYCLE.md) |
| 47 | Over-indexing (index per WHERE column) | Write amplification on every DML | Audit index usage; remove unused | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 48 | Under-indexing (no index on 5M-row filter col) | Full table scan on every query | Add targeted index | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 49 | Stale statistics after bulk load | Optimizer picks wrong plan | `ANALYZE` (MySQL/PostgreSQL) / `UPDATE STATISTICS` (SQL Server) after bulk operations | [01](./01_QUERY_EXECUTION_LIFECYCLE.md) |
| 50 | Parameter sniffing (plan cached for atypical value) | Wrong plan for majority of calls | SQL Server: `OPTION (RECOMPILE)` or "optimize for unknown"; PostgreSQL prepared statements have a related but distinct custom/generic-plan mechanism; verify which mechanism applies on your engine before reaching for a fix | [01](./01_QUERY_EXECUTION_LIFECYCLE.md) |

---

## Category 7: Advanced Smells (51–55)

| # | Smell | Why Expensive | Fix | Ref |
|---|---|---|---|---|
| 51 | Nested views (view of view of view) | Blocks predicate pushdown | Flatten to base tables | [06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) |
| 52 | User-defined scalar function in WHERE | Executes per row; not inlined | Inline logic or persist computed column | [03](./03_SARGABILITY_AND_INDEX_USAGE.md) |
| 53 | Trigger firing per row in bulk INSERT | Row-by-row trigger overhead | Statement-level trigger or batch | [07](./07_QUERY_TUNING_WORKFLOW.md) |
| 54 | Query on unpartitioned time-series table | Scans all historical data | Partition by date + partition pruning | [CROSS_DATABASE](./CROSS_DATABASE_ENGINEERING.md) |
| 55 | Hint abuse (`FORCE INDEX`, `USE HASH`) | Locks plan regardless of data changes | Remove hint; fix underlying issue | [07](./07_QUERY_TUNING_WORKFLOW.md) |

---

## Smell Detection Workflow

```mermaid
flowchart LR
    A[Code Review / PR] --> B[Scan for Category 1 smells]
    B --> C[Scan for Category 3 smells]
    C --> D[Run EXPLAIN ANALYZE]
    D --> E{Plan acceptable?}
    E -->|No| F[Match to smell catalog]
    F --> G[Apply rewrite from REWRITE_COOKBOOK]
    E -->|Yes| H[Approve]
```

---

## Related Documents

- [REWRITE_COOKBOOK.md](./REWRITE_COOKBOOK.md) — fixes for each smell
- [06 — Anti-Patterns](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md) — detailed lesson
- [PERFORMANCE_CHECKLIST.md](./PERFORMANCE_CHECKLIST.md) — pre-merge checklist
- [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md) — incident diagnostics

[← Back to Module Home](./README.md)
