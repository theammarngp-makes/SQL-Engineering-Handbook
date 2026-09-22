# Optimizer Myths

> **Module 16 · Query Optimization · Reference Library**
> [Home](./README.md) · [Interview Guide](./INTERVIEW_GUIDE.md) · [Performance Smells](./PERFORMANCE_SMELLS.md) · [Cheatsheet](./CHEATSHEET.md)

Query optimizers are widely used and widely misunderstood at the same
time. This doc corrects the myths that come up most often across this
module's lessons, with the mechanism, not just the correction.

## Myth: "Adding an index always makes queries faster"
**Reality:** an index speeds up reads that use it and slows down every
write to that table, since the index must be maintained on every
INSERT/UPDATE/DELETE. An index the optimizer doesn't choose provides zero
read benefit while paying the full write cost (Lesson 03).

## Myth: "The optimizer will always pick the fastest plan"
**Reality:** it picks the plan with the lowest *estimated* cost, based on
statistics that can be stale and cardinality estimates that degrade under
correlated columns or skew. "Fastest" and "lowest-estimated-cost" are the
same only when estimates are accurate (Lesson 08).

## Myth: "More indexes on a column are always better"
**Reality:** the leftmost-prefix rule means a composite index on (a,b,c)
already serves queries filtering on a, or a+b, or a+b+c -- a separate
single-column index on a alone is usually redundant, paying the write
cost with no additional read benefit (Lesson 03).

## Myth: "JOIN order in my SQL determines execution order"
**Reality:** SQL is declarative. The optimizer reorders joins based on
cost estimates for anything beyond a small number of tables (Lesson 04).

## Myth: "A fast query is a cheap/efficient query"
**Reality:** latency and resource cost (I/O, bytes scanned, cloud
billing) are correlated, not identical. A query can return in
milliseconds from cache or a small dev table while scanning enormous data
at production volume (Lesson 10).

## Myth: "EXPLAIN tells you what the query will actually do"
**Reality:** plain EXPLAIN shows the optimizer's *estimate* without
running the query. Only EXPLAIN ANALYZE executes it and reports actual
numbers -- a large estimate-vs-actual gap is itself a diagnostic signal
(Lesson 02).

## Myth: "NOT IN and NOT EXISTS are interchangeable"
**Reality:** NOT IN against a subquery returning even one NULL silently
returns zero rows for the entire outer query (three-valued logic). NOT
EXISTS has no such trap -- a correctness bug hiding behind what looks
like a performance choice (Lesson 05).

## Myth: "A CTE is always computed once and reused, like a temp table"
**Reality:** engine- and version-dependent. Postgres pre-12 always
materialized CTEs; 12+ inlines them unless marked MATERIALIZED. SQL
Server/MySQL generally inline CTEs, re-evaluating wherever referenced
(Lesson 05).

## Myth: "OFFSET pagination scales fine with an index on the sort column"
**Reality:** the index avoids a separate sort step, not the linear cost
of skipping OFFSET rows -- the engine still walks past every skipped row.
Keyset pagination is the actual fix (Lesson 06).

## Myth: "An optimizer hint is always a sign of a poorly-written query"
**Reality:** a hint applied *after* understanding why the optimizer chose
a suboptimal plan -- narrowly-scoped, documented, revisitable -- is a
legitimate tool. The anti-pattern is reaching for a hint as a first
response without understanding the underlying misestimate (Lesson 08).

## Myth: "If an AI assistant says a rewrite returns the same results,
that's good enough to merge"
**Reality:** a model's confidence carries no information about
correctness -- it sounds equally certain whether verified or fabricated.
Result-set equivalence needs a real diff against real data, independent
of how the claim was phrased (Lesson 12).

## Myth: "A performance regression will show up in code review if the
reviewer is careful enough"
**Reality:** the highest-risk regressions are caused by *unrelated* PRs --
a migration silently dropping a covering index. No reviewer of a PR about
feature X will notice it broke a query in feature Y they don't know
depends on the schema being touched. This is why Lesson 11 treats
performance testing as automated and CI-enforced, not a review
responsibility.

---

## Related

- [`INTERVIEW_GUIDE.md`](./INTERVIEW_GUIDE.md) -- several myths map directly to interview questions
- [`PERFORMANCE_SMELLS.md`](./PERFORMANCE_SMELLS.md) -- the pattern-level catalog these myths lead into
- [`COST_SMELLS.md`](./COST_SMELLS.md) -- the cost-specific companion catalog
