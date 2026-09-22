# Engineering Glossary — Query Optimization

Definitions for terms used throughout Module 16. Cross-referenced to the lesson where each term is taught in depth.

---

## A

**Access Method** — The physical strategy the engine uses to retrieve rows from a table: sequential scan, index scan, index-only scan, or bitmap scan. Visible in EXPLAIN output. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

**Anti-Join (⋉)** — A join that returns rows from the outer table that have *no* match in the inner table. Implemented via `NOT EXISTS` or `LEFT JOIN ... WHERE inner IS NULL`. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

**ANALYZE** — Command to refresh table statistics (row counts, value distributions) used by the optimizer. Stale statistics cause wrong plan choices. → [Lesson 01](./01_QUERY_EXECUTION_LIFECYCLE.md)

## B

**Bitmap Index Scan** — Access method that builds a bitmap of matching row locations from an index, then fetches rows from the heap. Common for medium-selectivity filters in PostgreSQL. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

**Buffer Cache / Buffer Pool** — In-memory cache of recently accessed data pages. Warm cache = fast reads; cold cache = disk I/O. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

## C

**Cardinality** — The number of rows an operation produces or processes. Optimizer estimates cardinality at each plan node; wrong estimates cause wrong plan choices. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

**Cost-Based Optimization (CBO)** — Optimizer strategy that assigns estimated cost to each possible plan and picks the cheapest. Used by PostgreSQL, MySQL 8+, SQL Server, Oracle. → [Lesson 01](./01_QUERY_EXECUTION_LIFECYCLE.md)

**Covering Index** — An index that contains all columns a query needs, enabling an index-only scan without table lookup. → [Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md)

**CTE (Common Table Expression)** — Named subquery defined with `WITH`. May be inlined or materialized depending on engine and version. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

## D

**Decorrelation** — Optimizer transformation that converts a correlated subquery into an equivalent join-based plan. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

## E

**Execution Plan** — The tree of physical operations the optimizer chooses to execute a query. Read with EXPLAIN. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

**EXPLAIN / EXPLAIN ANALYZE** — Commands to display estimated (EXPLAIN) or actual (EXPLAIN ANALYZE) execution plans. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

## H

**Hash Join** — Join algorithm that builds an in-memory hash table from the smaller input, then probes it with each row of the larger input. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

**Hash Spill** — When a hash join's build side exceeds available memory (`work_mem`), the engine spills to disk. Visible as `Batches > 1` in PostgreSQL. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

## I

**Index-Only Scan** — Access method that answers a query entirely from the index without visiting the table heap. Requires a covering index. → [Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md)

**Index Selectivity** — Fraction of rows a predicate eliminates. High selectivity = few matching rows = index is useful. → [Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md)

## J

**Join Elimination** — Optimizer optimization that removes unnecessary joins when a foreign key guarantees the join can't filter or change row count. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

**Join Order** — The sequence in which the optimizer joins tables. Not determined by SQL text order. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

## K

**Keyset Pagination** — Pagination using a cursor value (`WHERE id > last_seen_id`) instead of OFFSET. Cost stays flat regardless of page number. → [Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md)

## L

**Leftmost Prefix Rule** — Composite index on `(a, b, c)` can serve queries filtering on `a`, or `a AND b`, or `a AND b AND c` — but not `b` alone or `c` alone. → [Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md)

**Logical Processing Order** — `FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT`. Defines result equivalence, not physical execution. → [Lesson 01](./01_QUERY_EXECUTION_LIFECYCLE.md)

## M

**Merge Join** — Join algorithm that walks two pre-sorted inputs together. Efficient when both sides are already sorted on the join key. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

## N

**Nested Loop Join** — Join algorithm that iterates outer rows and looks up matches in the inner table (ideally via index). → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

**N+1 Query Pattern** — Application anti-pattern issuing one query per row in a loop instead of a single set-based query. → [Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md)

## P

**Parameter Sniffing** — When the optimizer caches a plan optimized for the first parameter value seen, which may be suboptimal for subsequent values. → [Lesson 01](./01_QUERY_EXECUTION_LIFECYCLE.md)

**Partial Index** — Index defined with a WHERE clause, indexing only rows matching a condition. → [Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md)

**Plan Cache** — Engine cache of parsed/optimized query plans. Parameterized queries benefit; literal-heavy queries miss. → [Lesson 01](./01_QUERY_EXECUTION_LIFECYCLE.md)

**Predicate Pushdown** — Optimizer optimization that applies a WHERE filter before a join instead of after, reducing join input size. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

## R

**RBAR (Row-By-Agonizing-Row)** — Anti-pattern of processing one row at a time in application code instead of set-based SQL. → [Lesson 06](./06_COMMON_PERFORMANCE_ANTI_PATTERNS.md)

## S

**SARGable (Search ARGument-able)** — A predicate written so the optimizer can use an index: the indexed column appears bare on one side of the comparison. → [Lesson 03](./03_SARGABILITY_AND_INDEX_USAGE.md)

**Selectivity** — See Index Selectivity.

**Semi-Join (⋉)** — A join that returns rows from the outer table that have *at least one* match in the inner table, without duplicating outer rows. Implemented via `EXISTS` or `IN`. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

**Seq Scan (Sequential Scan)** — PostgreSQL's `EXPLAIN` term for an access method that reads every row in the table (MySQL shows this as `type: ALL` in `EXPLAIN`, or "Table scan" in `EXPLAIN FORMAT=TREE`). Expensive on large tables but correct when no useful index exists or table is small. → [Lesson 02](./02_EXPLAIN_AND_EXECUTION_PLANS.md)

**Statistics** — Metadata about table data (row counts, distinct values, null fraction, histograms) used by the optimizer for cost estimation. → [Lesson 01](./01_QUERY_EXECUTION_LIFECYCLE.md)

**SubPlan** — EXPLAIN node indicating a correlated subquery executed per outer row. High `loops` count = performance problem. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

## T

**Three-Valued Logic (3VL)** — SQL's logic system where comparisons involving NULL evaluate to UNKNOWN (not TRUE or FALSE). Causes `NOT IN` with NULLs to return zero rows. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

## W

**Window Function** — Function computed over a defined window of rows (`OVER (PARTITION BY ... ORDER BY ...)`). Preferred rewrite for correlated subqueries computing ranks, running totals, or per-group aggregates. → [Lesson 05](./05_SUBQUERY_AND_CTE_OPTIMIZATION.md)

**work_mem** — PostgreSQL setting controlling memory available per sort/hash operation. Exceeding it causes disk spill. → [Lesson 04](./04_JOIN_OPTIMIZATION.md)

---

## Related Documents

- [ENGINEERING_GUIDE.md](./ENGINEERING_GUIDE.md)
- [CHEATSHEET.md](./CHEATSHEET.md)
- [CROSS_DATABASE_ENGINEERING.md](./CROSS_DATABASE_ENGINEERING.md)
