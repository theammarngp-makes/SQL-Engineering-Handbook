# 07 — View Performance

**Module:** 14 — Views
**Previous:** [06 — View Limitations](06_VIEW_LIMITATIONS.md) · **Next:** [08 — Real-World Case Studies](08_REAL_WORLD_CASE_STUDIES.md)

---

## Learning Objectives

- Explain `ALGORITHM = MERGE` vs `ALGORITHM = TEMPTABLE` and what disqualifies merge
- Read `EXPLAIN` output to determine which algorithm a query used
- Diagnose the nested-View performance trap
- Know when a View is the wrong tool and a physical table (or Module 15's indexing) is the right one

## Concept Overview

This is the file that turns "I know View syntax" into "I can be trusted with View design in production." The performance characteristics of a View are entirely determined by which of MySQL's two processing algorithms the optimizer chooses — and that choice is driven by the View's SQL shape, not by anything you configure at query time.

## Why This Exists

Teams that nest Views casually — a View built on a View built on a View — routinely discover, only under production load, that a query which looked fine in testing degrades badly at scale because each aggregating layer forces materialization into an unindexed temporary table.

## Business Context

A `vw_customer_lifetime_summary` View built on top of `vw_monthly_revenue_growth` (Module 05) built on top of `vw_monthly_revenue_trend` (Module 05) works fine against a 500-row test dataset. In production, against millions of order rows, the same query takes 40 seconds instead of 400 milliseconds, because each layer's `GROUP BY`/window function forces `TEMPTABLE` materialization, and none of those intermediate temp tables carry the indexes the base tables have.

## Where Companies Use It — Where Performance Matters

- **Dashboard backends** querying reporting Views on a schedule can tolerate `TEMPTABLE` cost; a **checkout flow** or **API endpoint** querying a View in the request path generally cannot.
- **Data platform teams** use `EXPLAIN` on every View before promoting it from "internal analyst tool" to "production-facing dashboard source."

## Real Business Example

```sql
EXPLAIN SELECT * FROM vw_completed_order_revenue WHERE region = 'APAC';
-- Look for "Using temporary" in Extra — its presence indicates TEMPTABLE
-- materialization occurred for this View invocation.
```

## Syntax

```sql
CREATE ALGORITHM = MERGE VIEW view_name AS ...;      -- hint, not a guarantee
CREATE ALGORITHM = TEMPTABLE VIEW view_name AS ...;  -- forces materialization
CREATE ALGORITHM = UNDEFINED VIEW view_name AS ...;  -- default: optimizer decides

EXPLAIN SELECT ... FROM view_name WHERE ...;
```

## Visual Explanation

```
MERGE (fast — folds into outer query, uses base-table indexes):
  SELECT col1, col2 FROM base_table WHERE simple_condition

TEMPTABLE (slower — materializes into an unindexed temp table first):
  SELECT ..., aggregate_fn(...) FROM base_table GROUP BY ...
  SELECT DISTINCT ...
  SELECT ... FROM base_table1 UNION SELECT ... FROM base_table2
  Any View containing a subquery in the SELECT list
  Any View using window functions (varies by exact query shape)
```

## Step-by-Step Walkthrough — Diagnosing a Slow View

1. Run `EXPLAIN` on the exact query pattern your application/dashboard sends against the View.
2. Check `Extra` for `Using temporary` — this is your `TEMPTABLE` signal.
3. If nested Views are involved, run `EXPLAIN` at each layer independently to find where materialization is introduced.
4. If a `TEMPTABLE` View is on a hot path (not a scheduled dashboard refresh), consider: flattening the nested Views into one query, moving the aggregation to a physical summary table refreshed on a schedule, or proceeding to Module 15 to index the base tables the View reads from more effectively (indexing doesn't eliminate `TEMPTABLE`, but it speeds up the base-table scan feeding it).

## Engineering Notes

`ALGORITHM = MERGE` requires, among other conditions: no aggregate functions, no `GROUP BY`/`HAVING`, no `DISTINCT`, no `UNION`, no subquery in the select list, and (in most cases) no window functions — essentially, a query the optimizer can textually splice into the caller. The moment any of Modules 1–13's more powerful features (aggregation, window functions, set operators) appear in a View, expect `TEMPTABLE`.

## Production Considerations

Never assume a View's performance characteristics from its logical simplicity — a one-line `GROUP BY` View can be far more expensive than a five-table `JOIN` View with no aggregation, purely because of which algorithm each triggers.

## Performance Notes

`TEMPTABLE` cost scales with the size of the intermediate result set the optimizer must materialize before applying any outer `WHERE` — meaning a filter applied *outside* a `TEMPTABLE`-algorithm View (`SELECT * FROM vw_x WHERE region = 'APAC'`) often cannot be "pushed down" into the View's own query, so the full unfiltered aggregation runs first, and the filter is applied after. This is the single most important performance fact in this file.

## Edge Cases

- A `MERGE`-eligible View nested inside a `TEMPTABLE`-algorithm View still gets folded correctly at the merge layer, but the outer `TEMPTABLE` layer's cost dominates regardless.
- Adding a seemingly harmless `DISTINCT` to "deduplicate just in case" silently converts a fast `MERGE` View into a `TEMPTABLE` View.

## Best Practices

- Run `EXPLAIN` on every View before it goes into a BI tool or application code path.
- Avoid nesting more than 2 levels of aggregating Views in a hot path — flatten into one query or a physical summary table instead.
- Prefer filtering columns that exist in the base table's `WHERE` clause of the View itself, not only at the outer query, when the filter is always applied by every consumer.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| Assuming an outer `WHERE` gets pushed into a `TEMPTABLE` View | Full unfiltered aggregation runs every time regardless of the filter |
| Nesting 3+ aggregating Views | Compounding `TEMPTABLE` materialization cost |
| Never running `EXPLAIN` before production rollout | Performance issue discovered only under real load |

## Interview Questions

1. "What's the difference between `MERGE` and `TEMPTABLE` View algorithms?" — whether the View's SQL is folded into the outer query or materialized into a temp table first.
2. "Does filtering a View from the outside always get pushed down into the View's query?" — no, particularly not for `TEMPTABLE`-eligible Views (those with `GROUP BY`, `DISTINCT`, etc.).
3. "Would you use a heavily nested, aggregating View inside a checkout API's hot path?" — no; flatten it or move to a scheduled physical summary table.

## Summary

A View's runtime cost is governed by whether MySQL can merge it into the outer query or must materialize it first — and that choice is made by the query's structural features (aggregation, `DISTINCT`, `UNION`, subqueries), not by anything you tune at query time. `EXPLAIN` is the only reliable way to know which happened.

## Practice Challenges

1. Run `EXPLAIN` on `vw_completed_order_revenue` (Module 01) and `vw_pending_orders` (Module 03); identify which uses `MERGE` and which uses `TEMPTABLE`, and justify why from the query shape alone before checking.
2. Propose a redesign of the 3-layer nested View chain from Module 05 (`vw_monthly_revenue_trend` → `vw_monthly_revenue_growth`) that would perform better on a hot application path, without losing the reusability benefit for dashboard use.

## Further Reading

- MySQL 8.0 Reference Manual — [View Processing Algorithms](https://dev.mysql.com/doc/refman/8.0/en/view-algorithms.html)
- MySQL 8.0 Reference Manual — [EXPLAIN Output Format](https://dev.mysql.com/doc/refman/8.0/en/explain-output.html)
