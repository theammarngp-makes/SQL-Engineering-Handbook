# Senior & Staff Database Engineer Subquery Interview Guide

This guide contains 20 senior and staff-level database engineering interview questions and technical answers focused on subqueries, relational algebra, optimizer internals, 3-valued logic, and query refactoring.

---

## Senior/Staff Technical Interview Questions

### Question 1: InitPlan vs SubPlan Execution Mechanics
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  An **`InitPlan`** represents an uncorrelated subquery evaluated **once** before main query execution starts. Its output scalar is cached in process memory as a parameter (e.g. `$0`) and substituted as a literal constant during outer scanning ($\mathcal{O}(1)$ subquery evaluations).  
  A **`SubPlan`** represents a subquery that the optimizer failed to decorrelate. It re-executes **once for every candidate outer tuple** ($\mathcal{O}(N)$ subquery evaluations), creating severe row-by-row CPU thread bottlenecks.
- **Reasoning**: Evaluates candidate's understanding of PostgreSQL execution plan AST nodes and algorithmic complexity.
- **Common Wrong Answers**: "InitPlan is used for initial joins; SubPlan is used for nested subqueries."
- **Follow-up Questions**: How do non-deterministic functions like `RANDOM()` impact `SubPlan` generation?

---

### Question 2: The 3-Valued Logic NOT IN NULL Trap
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  SQL uses 3-valued logic (`TRUE`, `FALSE`, `UNKNOWN`). `v NOT IN (1, 2, NULL)` expands to `(v <> 1) AND (v <> 2) AND (v <> NULL)`. Because any scalar comparison against `NULL` yields `UNKNOWN`, the expression simplifies to `TRUE AND TRUE AND UNKNOWN` $\equiv$ `UNKNOWN`. In SQL, `WHERE` clauses require conditions to evaluate strictly to `TRUE` to emit a row; `UNKNOWN` is treated as false. Consequently, zero rows are returned.
- **Reasoning**: Tests candidate's mastery of formal ANSI SQL boolean truth table logic and production safety.
- **Common Wrong Answers**: "It throws a NULL pointer exception at runtime."
- **Follow-up Questions**: Why is `NOT EXISTS` immune to this behavior?

---

### Question 3: Relational Algebra Semi-Join (⋉) Transformation
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  The parser converts `EXISTS` or `IN` subqueries into a **Semi-Join** ($\ltimes$). A Semi-Join scans the outer table $R$ and probes the inner table $S$, halting evaluation on the **first matching tuple** (short-circuit execution). Unlike a standard `INNER JOIN`, a Semi-Join never duplicates outer rows regardless of how many matching records exist in $S$.
- **Reasoning**: Tests knowledge of relational operators and duplicate elimination mechanics.
- **Common Wrong Answers**: "Semi-joins return half of the dataset."
- **Follow-up Questions**: How does a Hash Semi-Join handle in-memory hashing under `work_mem` constraints?

---

### Question 4: Projected Scalar Subquery Caching
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  PostgreSQL and Oracle maintain a session **Scalar Subquery Cache** (an in-memory hash table mapping correlation key parameters to computed scalar results). If the correlation key has low cardinality (e.g. 5 department IDs across 1,000,000 employees), cache hits exceed $99.9\%$, avoiding re-execution. If the correlation key is unique (high cardinality), caching fails, forcing 1,000,000 subquery evaluations ($\mathcal{O}(N \times M)$).
- **Reasoning**: Tests deep knowledge of execution engine memory caching mechanisms.
- **Common Wrong Answers**: "Scalar subqueries in SELECT lists are always rewritten to joins by the parser."
- **Follow-up Questions**: What SQL construct should replace projected scalar subqueries on high-cardinality keys? (Answer: Window Functions).

---

### Question 5: Subquery Unnesting Blockers
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  Optimizers fail to unnest subqueries into flat join trees when:
  1. The subquery contains non-deterministic/volatile functions (`RANDOM()`, `CLOCK_TIMESTAMP()`).
  2. A `NOT IN` subquery target column is nullable.
  3. Correlation predicates use non-equi join conditions (`BETWEEN`).
  4. The subquery contains un-ordered `LIMIT` / `OFFSET` clauses.
- **Reasoning**: Tests practical troubleshooting skills when reading execution plans.
- **Common Wrong Answers**: "Subqueries are never unnested automatically; you must manually write joins."
- **Follow-up Questions**: How do GUC flags like `enable_hashjoin` affect unnesting decisions?

---

### Question 6: ANY / ALL vs IN — Are They Interchangeable?
- **Difficulty**: Mid-to-Senior Engineer
- **Expected Answer**:  
  `x = ANY (subquery)` is semantically identical to `x IN (subquery)` — both are TRUE if `x` matches at least one row. They diverge with other comparison operators: `x > ALL (subquery)` requires `x` to exceed **every** value returned (equivalent to `x > (SELECT MAX(...))` for a single column), while `x > ANY (subquery)` requires `x` to exceed **at least one** value (equivalent to `x > (SELECT MIN(...))`). `IN` has no `ALL` counterpart — it is fixed to the "matches at least one" semantics of `= ANY`.
- **Reasoning**: Tests whether the candidate actually understands quantified comparison semantics rather than treating `ANY`/`ALL`/`IN` as syntactic synonyms.
- **Common Wrong Answers**: "`ALL` and `ANY` are just older syntax for `IN`, functionally identical in every case."
- **Follow-up Questions**: What does `x > ALL (subquery)` evaluate to if the subquery returns zero rows? (Answer: `TRUE` — vacuously true over an empty set, a common source of surprising bugs.)

---

### Question 7: Why Prefer NOT EXISTS Over NOT IN in Production Code?
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  Three reasons, in order of severity: (1) **Correctness** — `NOT IN` silently returns zero rows if the subquery's target column contains any `NULL`, due to 3-valued logic (see Question 2); `NOT EXISTS` has no such trap because it tests row existence, not value equality against a NULL-containing list. (2) **Optimizer friendliness** — `NOT EXISTS` unnests cleanly into an Anti-Join in every major engine; `NOT IN` sometimes cannot be rewritten as cleanly when nullability can't be statically ruled out, forcing a slower plan. (3) **Intent clarity** — `NOT EXISTS` reads as "no matching row," which is usually the actual business question, versus `NOT IN`'s "not a member of this value list."
- **Reasoning**: Tests whether the candidate can justify a production coding standard with engineering reasoning, not just repeat "NOT IN is bad."
- **Common Wrong Answers**: "`NOT IN` is always slower than `NOT EXISTS`" (not universally true — on a guaranteed-NOT-NULL column with a small subquery result, performance is often comparable).
- **Follow-up Questions**: If the target column is defined `NOT NULL` at the schema level, does the correctness argument against `NOT IN` still apply?

---

### Question 8: Predicate Pushdown Into Derived Tables
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  When a query joins against a derived table (a subquery in the `FROM` clause), the optimizer can often "push" an outer `WHERE` predicate on the derived table's output column down into the derived table's own query, so filtering happens before aggregation/joining inside the subquery rather than after. This shrinks the intermediate row count the derived table has to materialize. Pushdown is blocked when the derived table contains `LIMIT`, `OFFSET`, window functions, or non-deterministic functions, because pushing a filter earlier would change which rows those operations see.
- **Reasoning**: Tests understanding of a specific, high-value optimizer transformation and its failure conditions.
- **Common Wrong Answers**: "The database always executes the derived table's subquery first as a temporary table, then filters it afterward — this behavior never changes."
- **Follow-up Questions**: Would wrapping a derived table in `SELECT * FROM (...) LIMIT 10` change whether pushdown can occur for a predicate applied outside it?

---

### Question 9: Materialization vs Inlining for CTEs
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  A CTE can be executed two ways: **materialized** (computed once into a temporary result set, then referenced) or **inlined/streamed** (treated like a derived table and folded into the surrounding query plan, potentially re-evaluated per reference). Materialization is a performance win when the CTE is referenced multiple times or is expensive to compute once; it's a performance loss when the CTE is referenced once and materializing it blocks predicate pushdown into it. Modern PostgreSQL (12+) inlines single-reference CTEs by default unless `MATERIALIZED` is explicitly specified; older versions always materialized.
- **Reasoning**: Tests awareness that CTE behavior is version- and engine-dependent, not a fixed rule of thumb.
- **Common Wrong Answers**: "CTEs are always an optimization fence that force materialization in every database."
- **Follow-up Questions**: When would you explicitly force `MATERIALIZED` even in a version that defaults to inlining?

---

### Question 10: Diagnosing a Hash Semi-Join Disk Spill
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  A Hash Semi-Join builds an in-memory hash table from the smaller (inner) side of the join. If that hash table's estimated size exceeds the query's working memory budget (`work_mem` in PostgreSQL), the engine splits the join into multiple batches and spills intermediate data to temporary disk files — visible in `EXPLAIN (ANALYZE, BUFFERS)` as `Batches: N` where `N > 1`, plus nonzero `temp_bytes`/`temp_written` in system stats. Fixes are: raise `work_mem` for the session/query, reduce the inner-side row count before the join (filter earlier), or ensure statistics are current so the planner's row estimate — and therefore its batch-count decision — is accurate.
- **Reasoning**: Tests whether the candidate can read a specific EXPLAIN artifact and connect it to a memory-configuration root cause and a concrete remediation.
- **Common Wrong Answers**: "Disk spills only happen with `ORDER BY` sorts, never with joins."
- **Follow-up Questions**: Why can raising `work_mem` globally be risky on a high-concurrency production instance?

---

### Question 11: Indexing Strategy for Correlated Subquery Join Keys
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  The column used in the correlation predicate (e.g., `sub.dept_id = e.dept_id`) on the **inner** table should carry a B-Tree index, since a naive `SubPlan` re-probes that table once per outer row — without an index, each probe is a full sequential scan, turning the whole query into `O(N × M)` disk I/O instead of `O(N × log M)`. If the optimizer instead unnests into a Hash Join, an index is less critical for that specific join (hashing doesn't need one), but is still valuable if the same column is filtered or joined elsewhere in the query.
- **Reasoning**: Tests the candidate's ability to connect a specific execution strategy (SubPlan vs Hash Join) to a differentiated indexing recommendation, rather than a blanket "always index it."
- **Common Wrong Answers**: "Subqueries can't use indexes at all, so indexing doesn't matter here."
- **Follow-up Questions**: Would a covering index (including the selected columns) provide additional benefit for this correlated pattern?

---

### Question 12: Cross-Engine Semi-Join Strategy Differences
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  MySQL 8.0's optimizer chooses among several distinct named semi-join strategies — `FirstMatch` (short-circuit, similar to nested-loop semi-join), `LooseScan` (exploits an index to skip duplicate outer-key groups), `Materialization` (builds a temp table of the subquery once), and `DuplicateWeedout` — visible in `EXPLAIN FORMAT=JSON`. PostgreSQL, by contrast, doesn't name strategies explicitly; it simply picks between `Hash Semi Join`, `Nested Loop Semi Join`, or a `SubPlan`, and exposes the choice only through the generic plan node type. A candidate should know that "semi-join" is a relational algebra concept implemented differently — and diagnosed differently — per engine.
- **Reasoning**: Tests whether the candidate's optimizer knowledge is engine-specific and current, versus a single mental model wrongly generalized across all SQL databases.
- **Common Wrong Answers**: "All major databases implement semi-joins identically since it's part of the SQL standard."
- **Follow-up Questions**: How would you determine which semi-join strategy MySQL chose for a given query in production?

---

### Question 13: Anti-Join NULL Handling — Why NOT EXISTS Is Safe
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  `NOT EXISTS (SELECT 1 FROM inner_table WHERE inner_table.key = outer.key)` evaluates a **row-existence test**, not a value comparison against a NULL-containing set. Even if `inner_table.key` contains `NULL` rows, those rows simply never satisfy the correlation predicate (since `NULL = anything` is `UNKNOWN`, never `TRUE`) and are correctly excluded from the "exists" check — they don't poison the outer `NOT EXISTS` result the way a `NULL` in a `NOT IN` list does, because `NOT EXISTS` never has to evaluate `NOT (UNKNOWN)` across the whole set — it only asks "did any row satisfy the predicate," which resolves cleanly to `FALSE`/no match.
- **Reasoning**: Tests precise understanding of *why* the anti-join pattern sidesteps 3-valued logic, not just that it does.
- **Common Wrong Answers**: "NOT EXISTS avoids the NULL trap because it automatically filters out NULL rows before comparison" (implies special-casing that doesn't exist — it's a consequence of existence semantics, not a NULL filter).
- **Follow-up Questions**: Does `LEFT JOIN ... WHERE inner.key IS NULL` (the anti-join-via-outer-join pattern) share the same NULL-safety, and why or why not?

---

### Question 14: Replacing a Correlated Running-Total Subquery With a Window Function
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  A correlated subquery computing a running total (`SELECT SUM(amount) FROM t sub WHERE sub.date <= t.date`) re-scans and re-aggregates the table once per outer row — `O(N²)` in the worst case. `SUM(amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)` computes the same result in a single pass over data sorted once, typically `O(N log N)` for the sort plus `O(N)` for the window pass — a fundamentally different execution strategy, not just a syntax preference.
- **Reasoning**: Tests the ability to recognize when a correlated-subquery pattern has a strictly better window-function equivalent, a very common real-world refactor.
- **Common Wrong Answers**: "Window functions and correlated subqueries always produce different result sets, so they aren't interchangeable here."
- **Follow-up Questions**: What changes if the running total needs to be reset per group (e.g., per customer) rather than globally?

---

### Question 15: How LIMIT Inside a Subquery Blocks Unnesting
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  A subquery containing `LIMIT`/`OFFSET` (or `FETCH FIRST`) cannot generally be flattened into a plain join, because a join would evaluate the predicate against every matching row, while `LIMIT` semantically restricts the subquery to a fixed number of rows *before* that predicate is applied outside it — flattening would change which rows are considered, and therefore the result. The optimizer must preserve the subquery as a distinct, separately-executed plan node (often materialized), which forecloses several rewrite optimizations available to unlimited subqueries.
- **Reasoning**: Tests whether the candidate understands that some rewrite blockers are semantic necessities, not optimizer limitations to work around.
- **Common Wrong Answers**: "This is just a current limitation of query optimizers that will eventually be fixed with smarter planners."
- **Follow-up Questions**: How would you rewrite a "top-N per group" correlated-subquery-with-LIMIT pattern to avoid this entirely? (Answer: a ranking window function such as `ROW_NUMBER() OVER (PARTITION BY ...)` filtered in an outer query.)

---

### Question 16: How Stale Statistics Break Subquery Plan Choice
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  The cost-based optimizer chooses between a Nested Loop, Hash, or Merge strategy for an unnested subquery based on estimated row counts and selectivity from table statistics (histograms, distinct-value counts). If statistics are stale — e.g., after a large bulk load that hasn't been followed by `ANALYZE` — the planner may badly underestimate the inner table's row count, choosing a Nested Loop (cheap only for a small inner set) when a Hash Join would actually be far cheaper at the true row count, causing a severe production regression that has nothing to do with the SQL itself.
- **Reasoning**: Tests whether the candidate looks beyond the query text itself when diagnosing a sudden performance regression — a very common real-world root cause.
- **Common Wrong Answers**: "If the query worked fine yesterday and the SQL hasn't changed, the query itself cannot be the cause of a slowdown today" (true in a narrow sense, but the candidate should immediately connect this to statistics/data-volume drift as the actual culprit, not dismiss investigation).
- **Follow-up Questions**: What autovacuum/auto-analyze configuration would you check first in this scenario?

---

### Question 17: Parallel Query Execution and Correlated Subqueries
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  Parallel workers can scan and join independent chunks of the outer table concurrently, but a correlated `SubPlan` re-executed per outer row introduces a serialization dependency that limits how effectively that portion of the plan parallelizes — each worker still pays the per-row subquery cost independently, so parallelism reduces wall-clock time roughly proportionally to worker count, but does **not** reduce the underlying `O(N × M)` algorithmic cost the way decorrelation does. Throwing more parallel workers at an undecorrelated query is a way to make a bad plan finish faster, not a substitute for fixing the plan.
- **Reasoning**: Tests whether the candidate understands parallelism as a multiplier on existing algorithmic cost, not a fix for it — a distinction junior engineers often miss when told to "just enable parallel query."
- **Common Wrong Answers**: "Enabling parallel workers turns an O(N×M) correlated subquery into an O(N+M) operation."
- **Follow-up Questions**: Would increasing `max_parallel_workers_per_gather` help more, or would fixing the decorrelation help more, for a query already timing out at 10M rows?

---

### Question 18: Correlated Subqueries in the SELECT List vs the WHERE Clause
- **Difficulty**: Mid-to-Senior Engineer
- **Expected Answer**:  
  A correlated subquery in a `WHERE` clause filters rows and can often be rewritten as a Semi/Anti-Join. A correlated subquery in the `SELECT` list (a scalar projection) must return exactly one value per outer row and is evaluated as part of row construction, not filtering — it cannot become a Semi-Join, since the goal is to *retrieve* a value, not to test membership. The correct rewrite target for a projected correlated subquery is usually a `LEFT JOIN` to a pre-aggregated derived table, or a window function, not a Semi-Join transformation.
- **Reasoning**: Tests whether the candidate distinguishes rewrite strategies by subquery *position* (filter vs. projection), a distinction many engineers conflate.
- **Common Wrong Answers**: "Any correlated subquery, wherever it appears in the query, can be converted into a Semi-Join."
- **Follow-up Questions**: What happens if the projected scalar subquery returns more than one row at runtime? (Answer: a runtime error — "more than one row returned by a subquery used as an expression.")

---

### Question 19: Safely Migrating Legacy NOT IN Code to NOT EXISTS
- **Difficulty**: Senior Engineer
- **Expected Answer**:  
  A safe migration requires: (1) confirming via schema constraints or a data audit whether the subquery's target column can actually contain `NULL` — if it's `NOT NULL`-constrained, the rewrite is behavior-preserving; if nullable, the *current* `NOT IN` behavior (silently returning zero rows on any NULL) may already be a latent bug worth fixing, not preserving. (2) Rewriting `NOT IN (subquery)` to `NOT EXISTS (SELECT 1 FROM inner WHERE inner.key = outer.key)`, being careful the correlation predicate matches the original `IN` column exactly. (3) Validating row counts match on a staging dataset before and after, specifically testing rows where the old query silently returned nothing.
- **Reasoning**: Tests migration discipline — treating a "safe" refactor as still requiring verification, since the old and new queries can have *different* correct behavior when NULLs are involved, not identical behavior via different mechanisms.
- **Common Wrong Answers**: "NOT IN and NOT EXISTS are always interchangeable, so the rewrite is a pure performance optimization with zero behavior risk."
- **Follow-up Questions**: How would you write a regression test that specifically catches the case where the two forms diverge?

---

### Question 20: Diagnosing a Subquery-Driven Outage From Monitoring Alone
- **Difficulty**: Staff Engineer
- **Expected Answer**:  
  Without query text in hand, the signals pointing at a correlated-subquery regression specifically (versus a generic slow query) are: a spike in CPU-bound (not I/O-wait) time on the database host, a rise in active connection/thread count without a matching rise in overall query throughput (queries holding connections open longer while looping), and — if available — `pg_stat_statements` (or engine equivalent) showing a query with disproportionately high `calls`-to-`rows`-returned ratio at the *plan node* level, or a small number of statements accounting for a large share of total execution time despite low individual row counts. The next step is pulling `EXPLAIN (ANALYZE, BUFFERS)` for the suspect query and looking specifically for `SubPlan` nodes with a high `loops` count, as covered in Question 1.
- **Reasoning**: Tests staff-level operational reasoning — connecting infrastructure-level monitoring signals to a specific, diagnosable SQL root cause, rather than only knowing the SQL-level fix in isolation.
- **Common Wrong Answers**: "You'd need to check the slow query log first, since monitoring dashboards can't tell you anything about subquery-specific problems."
- **Follow-up Questions**: What's the difference in monitoring signature between a SubPlan-driven CPU bottleneck and a lock-contention-driven outage?

---

## Related Modules

- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
- [Module 10 — Execution Plans](./10_EXECUTION_PLANS.md)
