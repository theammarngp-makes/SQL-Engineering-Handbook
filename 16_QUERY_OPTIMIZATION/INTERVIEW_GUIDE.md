# Interview Guide — Query Optimization

> **Module 16 · Query Optimization · Reference Library**
> [Home](./README.md) · [Cheatsheet](./CHEATSHEET.md) · [Performance Smells](./PERFORMANCE_SMELLS.md) · [Optimizer Myths](./OPTIMIZER_MYTHS.md)

Every lesson in this module ends with its own "Interview Questions"
section. This guide collects them with model answers, organized by
lesson, for interview prep on either side of the table. Don't memorize the
answers verbatim -- read the linked lesson first; a good interviewer who
probes one level deeper will expose a memorized answer immediately.

---

## Lesson 02 -- EXPLAIN & Execution Plans

**Q: What's the difference between EXPLAIN and EXPLAIN ANALYZE?**
`EXPLAIN` shows the planner's *estimated* plan without running the query;
`EXPLAIN ANALYZE` executes it and reports real row counts and timing. A
large estimate-vs-actual gap means stale statistics or an
unestimable predicate -- and because join order and algorithm choice are
both driven by these estimates, a bad estimate early in the plan cascades
throughout.

## Lesson 03 -- SARGability & Index Usage

**Q: What does SARGable mean?**
A predicate is written so the engine can use an index seek instead of
evaluating a function against every row. `WHERE YEAR(order_date) = 2025`
is non-SARGable; `WHERE order_date >= '2025-01-01' AND order_date <
'2026-01-01'` is, and lets an index on `order_date` be used directly.

**Q: Does a composite index on (a, b) help a query filtering only on b?**
No -- the leftmost-prefix rule means a composite index can only be used
efficiently for lookups including the leading column(s).

## Lesson 04 -- Join Optimization

**Q: Hash join vs. merge join -- when does each apply?**
Hash join builds an in-memory hash table on the smaller input, efficient
for large unsorted inputs with equality predicates. Merge join requires
both inputs pre-sorted on the join key and avoids the hash table's memory
cost. **Why doesn't JOIN order in SQL determine execution order?** SQL is
declarative -- the optimizer reorders joins based on cost estimates.

## Lesson 05 -- Subquery & CTE Optimization

**Q: When is EXISTS preferred over IN?**
`NOT IN` against a subquery containing even one `NULL` silently returns
zero rows for the entire query (three-valued logic: `x NOT IN (1, NULL)`
evaluates to `UNKNOWN`). `NOT EXISTS` has no such trap.

**Q: Is a CTE always computed once and cached?**
No -- Postgres before v12 always materialized CTEs; v12+ inlines them
like subqueries unless marked `MATERIALIZED`. SQL Server/MySQL generally
inline CTEs, re-evaluating them wherever referenced.

## Lesson 06 -- Common Performance Anti-Patterns

**Q: Why does OFFSET get slower as it grows, even with an index?**
The index lets rows be read in order, but the engine must still walk past
every skipped row before returning results. Keyset pagination
(`WHERE id > last_seen_id`) turns an O(offset) scan into an O(page size) seek.

## Lesson 07 -- Query Tuning Workflow

**Q: A report "used to be fast" with no code changes. Your approach?**
Rule out a code change, check data-volume growth, check statistics
staleness, check for a dropped index or silent migration. Compare current
`EXPLAIN ANALYZE` against the last known-good plan if available -- the
plan shape change usually reveals which of the three happened.

## Lesson 08 -- Cost-Based Optimizer

**Q: Cardinality estimation vs. selectivity?**
Selectivity is the *fraction* of rows a predicate matches; cardinality
estimation is the *absolute row count* a plan node is predicted to
produce, derived from selectivity applied to input size.

**Q: What's parameter sniffing?**
The optimizer caches a plan compiled for the first parameter value a
prepared statement runs with, and reuses it for later executions --
efficient when value distributions are similar, a problem when skewed.

## Lesson 09 -- Query Rewrite Patterns

**Q: Explain the OR-to-UNION-ALL rewrite.**
`WHERE a = 1 OR b = 2` across separately-indexed columns often can't use
either index efficiently. `SELECT ... WHERE a=1 UNION ALL SELECT ...
WHERE b=2` lets each branch use its own index independently.

## Lesson 10 -- Cloud Cost Optimization & Resource Governance

**Q: A query is fast but the cloud bill went up. How do you investigate?**
Check the bytes-scanned/I/O-cost signal directly -- `total_bytes_billed`
on BigQuery, `WAREHOUSE_METERING_HISTORY` on Snowflake, `shared read`
counts via `EXPLAIN (ANALYZE, BUFFERS)` on Postgres/RDS. Latency and cost
are correlated, not identical, on any consumption-billed engine.

**Q: Why doesn't LIMIT reduce cost on BigQuery?**
The engine must still read the data needed to compute the result before
truncating output -- LIMIT reduces what's *returned*, not what's *scanned*.

## Lesson 11 -- Automated Performance Testing & CI/CD Integration

**Q: How do you design a CI gate without producing false positives?**
Assert on `EXPLAIN` plan-node shape (deterministic) over raw latency
(noisy on shared runners), size seed data to reproduce the production
plan shape, and scope the gate to only run when query-relevant files changed.

**Q: Your decision process for automate vs. manual review?**
Three questions in order: does it run on a hot path; will its plan shape
be affected by changes outside this PR; can the regression pattern be
expressed as a concrete, versioned threshold a CI job can evaluate
without human judgment. Automate only when all three are true.

## Lesson 12 -- AI-Assisted Query Tuning Workflow

**Q: How do you validate an AI-suggested index before production?**
Never create it directly. Check column order against the leftmost-prefix
rule, verify no existing index already covers it, ask explicitly for the
write-side cost, and confirm via a real `EXPLAIN` run that the planner
actually chooses to use it.

**Q: A rewrite passes EXPLAIN review but changes the result set. How
would your process catch this?**
Plan-shape improvement says nothing about correctness. The mandatory step
is a direct result-set diff against real data, run independently of
whatever equivalence argument the model gave, before the plan-shape
improvement is considered relevant at all.

---

## Related

- [`PERFORMANCE_SMELLS.md`](./PERFORMANCE_SMELLS.md) -- catalog several answers reference
- [`OPTIMIZER_MYTHS.md`](./OPTIMIZER_MYTHS.md) -- common wrong answers to these questions
- [`COST_SMELLS.md`](./COST_SMELLS.md) -- Lesson 10's companion catalog
