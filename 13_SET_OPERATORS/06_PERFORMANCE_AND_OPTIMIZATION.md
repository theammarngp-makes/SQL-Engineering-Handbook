# 06 — Performance and Optimization

## Introduction

Every prior topic in this module deferred a performance question to this file. Topic 01 promised that the cost of duplicate detection would be "expanded fully" here. Topics 02, 03, and 05 all noted that native set operators sometimes lose to a rewritten `JOIN`, `EXISTS`, or `NOT EXISTS` — without proving it. This topic collects every one of those threads and gives you the mental model, the rewrite patterns, and the diagnostic habits to make the call yourself, on your own data, instead of trusting a rule of thumb.

## Concept Overview

Every set operator except `UNION ALL` has to answer one expensive question: *"have I seen this row before?"* Answering that question is what costs money. This topic is organized around that single idea, applied to four recurring engineering decisions:

| Decision | What's really being compared |
|---|---|
| `UNION` vs `UNION ALL` | Paying for de-duplication vs. not |
| `UNION` vs `JOIN` | Stacking rows vs. combining columns — a correctness question disguised as a performance one |
| `INTERSECT` vs `EXISTS` | Set-comparison vs. row-by-row existence check |
| `EXCEPT` vs `NOT EXISTS` / `LEFT JOIN ... IS NULL` | Set-difference vs. anti-join |

A fifth pattern — recursive `UNION ALL` — is covered separately because it solves a different problem entirely: traversing hierarchical data, not comparing two datasets.

## Why This Exists

The `SELECT` statements in Topics 01–05 all ran instantly, because the datasets were small enough to fit in a teaching example. Production tables aren't. At ten rows, a sort-based de-duplication step and a hash-based one are indistinguishable. At ten million rows, the choice between them — and the choice of whether to de-duplicate at all — is the difference between a query that returns in milliseconds and one that spills to disk. Optimization isn't a separate skill from writing correct set-operator SQL; it's the second half of the same skill.

## Business Context

A nightly ETL job that reconciles two 50-million-row tables using `EXCEPT` and finishes in eight minutes is invisible. The same job, written slightly differently, that takes ninety minutes and blocks the warehouse refresh downstream is an incident. The SQL text can look almost identical. The difference is whether the engineer understood what the engine actually has to *do* to answer the question.

## Real Company Examples

- A ride-sharing company rewrote a driver/rider `EXCEPT`-based reconciliation job as a `NOT EXISTS` anti-join after it began missing its SLA window as ride volume grew, cutting runtime from over an hour to under ten minutes.
- A subscription analytics team replaced a recursive `UNION ALL` traversal of an org/account hierarchy with an indexed closure table once traversal depth made the recursive query too slow for an interactive dashboard — recursion is powerful, not free.
- A data platform team materialized a frequently-queried `UNION ALL` integration view (see Topic 04) into a nightly-refreshed table after discovering every dashboard load was recomputing the same three-way union from scratch.

## Production Use Cases

- Deciding whether a reconciliation job (Topic 05) should use native `EXCEPT` or an anti-join, based on table size and index availability.
- Diagnosing why a `UNION`-based report is slow and determining whether the fix is `UNION ALL`, better indexing, or a rewrite.
- Traversing hierarchical business data — org charts, category trees, bill-of-materials structures — with recursive `UNION ALL`.
- Reusing a set-operator query multiple times within one statement via a CTE, instead of duplicating the logic (and its cost) twice.

## Visual Explanation

```
 UNION ALL:  [branch A] ──concat──► [branch B] ──► done
             (no sort, no comparison, cheapest possible plan)

 UNION:      [branch A] ─┐
                          ├─► [combine] ─► [SORT or HASH] ─► [de-dup] ─► done
             [branch B] ─┘         ↑
                          this step is the entire extra cost

 EXCEPT (native):  [sort/hash A] ──┐
                                    ├─► [set difference] ─► done
                   [sort/hash B] ──┘
             (must materialize and order/hash BOTH full sets)

 NOT EXISTS (anti-join):  for each row in A:
                             [index seek into B] ─► keep if no match
             (no full materialization of B required, if B is indexed)
```

## Syntax

```sql
-- Recursive UNION ALL (ANSI SQL / PostgreSQL / SQL Server / MySQL 8.0+)
WITH RECURSIVE org_chart AS (
    -- Anchor member: the starting row(s), evaluated once
    SELECT emp_id, emp_name, manager_id, 1 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL                         -- MUST be UNION ALL, never UNION

    -- Recursive member: joins back to the CTE itself
    SELECT e.emp_id, e.emp_name, e.manager_id, oc.depth + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT * FROM org_chart
ORDER BY depth, emp_id;
```

## Detailed Explanation

### Why `UNION`'s de-duplication is expensive

To guarantee no duplicate survives, the engine needs every row comparable to every other row. There are two standard strategies:

- **Sort-based**: order the entire combined result, then walk it once, dropping adjacent duplicates. Cost scales as *O(n log n)* on the combined row count, and large sorts that exceed available memory spill to disk — the single most common cause of a `UNION` query suddenly becoming dramatically slower as data grows.
- **Hash-based**: build a hash table of rows seen so far, checking each new row against it. Often faster than sorting for moderate data volumes, but the hash table itself must fit in memory to avoid its own disk-spill penalty.

Which strategy the optimizer picks is not something you control directly — it's chosen based on cardinality estimates, available memory, and whether an index already provides useful ordering. What you *can* control is avoiding the step entirely with `UNION ALL` when duplicates are impossible or irrelevant (Topic 02).

### `UNION` vs `JOIN` — a correctness question wearing a performance costume

These are sometimes confused by newer engineers because both statements involve two tables and produce "combined" output. They are not interchangeable and solve opposite problems:

- `JOIN` combines **columns** from two tables **side by side**, matched on a condition — the output has *more columns* than either input alone.
- `UNION`/`UNION ALL` combines **rows** from two tables **stacked vertically** — the output has the *same number of columns* as each input, just more rows.

A query that tries to "add department name onto each employee row" using `UNION` instead of `JOIN` will run, produce no error, and return completely wrong results — this is covered concretely in Scenario 4 of the accompanying SQL file. This is a correctness bug that happens to also be worth mentioning in a performance module, because misapplied `UNION` sometimes gets progressively "optimized" (indexes added, hints applied) by an engineer trying to speed up a query that was never going to be correct at any speed.

### `INTERSECT`/`EXCEPT` vs. `EXISTS`/`NOT EXISTS`

Native `INTERSECT` and `EXCEPT` typically require materializing and sorting or hashing **both full branches** before comparing them — even if only a handful of rows actually overlap or differ. `EXISTS`/`NOT EXISTS`, by contrast, can be executed as a **semi-join** or **anti-join**: for each row on one side, the engine performs an index seek into the other side and stops at the first match (or confirms no match exists). When the compared column is indexed, this is frequently far cheaper, because the engine never has to materialize or sort the full second table — it just probes it, row by row.

This isn't a universal rule. On small tables, or when no useful index exists on the comparison column, the native set operator can be just as fast or faster, and is almost always more readable. The only reliable method is to compare execution plans against your actual data volume — never assume.

### Recursive `UNION ALL`

A recursive CTE has two parts, combined with `UNION ALL`:

1. **Anchor member** — a non-recursive query producing the starting row(s), executed exactly once.
2. **Recursive member** — a query that references the CTE **by its own name**, executed repeatedly, each time operating only on the rows produced by the *previous* iteration, until it produces zero new rows.

`UNION ALL` is mandatory here, not a style choice: using `UNION` would force the engine to de-duplicate the *entire accumulated result* on every single iteration, which is both far more expensive and, in most vendors, simply disallowed by the recursive CTE syntax entirely.

## Business Examples

```sql
-- Cheap: counting exact duplication between two sources without paying for
-- a full UNION de-dup — subtract UNION ALL's count from UNION's count
SELECT
    (SELECT COUNT(*) FROM (SELECT dept_name FROM departments UNION ALL SELECT city FROM locations) x) -
    (SELECT COUNT(*) FROM (SELECT dept_name FROM departments UNION     SELECT city FROM locations) y)
    AS duplicate_row_count;
```

```sql
-- Anti-join rewrite of an EXCEPT-based reconciliation check (Topic 05)
SELECT c.customer_id
FROM crm_customers c
LEFT JOIN erp_customers e ON c.customer_id = e.customer_id
WHERE e.customer_id IS NULL;
```

## Production Workflow

1. Before writing any set operator, ask whether de-duplication is actually needed. If not, `UNION ALL` is the answer before performance is even a consideration.
2. For `INTERSECT`/`EXCEPT` on large tables, write both the native form and the `EXISTS`/`NOT EXISTS` (or `LEFT JOIN ... IS NULL`) equivalent.
3. Run `EXPLAIN` (or your engine's equivalent) on both forms against production-scale data — never against the small teaching-sized tables used to learn the syntax.
4. Confirm the comparison column is indexed on both sides before trusting any anti-join rewrite to be faster; without an index, the anti-join degrades to a full scan per outer row, which can be the worst plan of all.
5. For hierarchical traversal, reach for recursive `UNION ALL` first; only replace it with a closure table or materialized path column if traversal depth or query frequency makes the recursive cost unacceptable.
6. Wrap any set-operator query reused more than once in a request behind a CTE, so the logic — and, on engines that support it, the computed result — isn't duplicated.

## Engineering Considerations

- Cardinality estimates drive the optimizer's choice of sort vs. hash de-duplication; badly stale table statistics can cause the engine to pick a poor plan even when the query itself is well-written. Keeping statistics current is part of set-operator performance work, not a separate DBA concern.
- A CTE is not automatically materialized on every engine — PostgreSQL (pre-12), SQL Server, and MySQL may inline a non-recursive CTE into the outer query and evaluate it multiple times if referenced more than once; PostgreSQL 12+ can choose either behavior. If you need guaranteed single evaluation, materialize explicitly into a temp table.
- Every branch of a multi-branch `UNION ALL` is planned and can be indexed independently — a slow five-branch integration query is often one slow branch, not five, and should be diagnosed branch by branch.

## Performance Notes

The single most common performance defect across this entire module is an unnecessary `UNION` where `UNION ALL` was actually correct — paying a sort or hash cost to remove duplicates that could never have existed, or that didn't matter to the business question. The second most common is a native `EXCEPT`/`INTERSECT` running against a large, unindexed table where an anti-join or semi-join rewrite would let the optimizer use an index seek instead of a full materialization. Both are worth checking, in that order, on any slow set-operator query.

## Database Compatibility

| Feature | MySQL | PostgreSQL | SQL Server | Oracle |
|---|---|---|---|---|
| Recursive CTE (`WITH RECURSIVE`) | 8.0+ | ✅ | ✅ (`WITH`, no `RECURSIVE` keyword needed) | 11gR2+ (also has legacy `CONNECT BY`) |
| CTE materialization guarantee | inlined by default | 12+: planner's choice; pre-12: always materialized | inlined by default | inlined by default |
| `EXPLAIN` / plan inspection | `EXPLAIN` | `EXPLAIN ANALYZE` | `SET SHOWPLAN_ALL` / Actual Execution Plan | `EXPLAIN PLAN FOR` |
| Anti-join optimization for `NOT EXISTS` | ✅ | ✅ | ✅ | ✅ |

## Best Practices

- Default to `UNION ALL`; treat `UNION` as an intentional, justified cost.
- Benchmark native set operators against `EXISTS`/`NOT EXISTS`/`LEFT JOIN` rewrites on real data volumes before standardizing on either for a recurring job.
- Index the columns used in set comparisons on both sides — this single step determines whether an anti-join rewrite helps at all.
- Never use `UNION` inside a recursive CTE's recursive member.
- Refresh table statistics on large tables feeding set-operator queries; stale statistics are a frequent, invisible cause of poor plan choices.

## Common Mistakes

- Assuming the native set operator is always simplest-therefore-best, without checking whether it's also cheapest at production scale.
- Using `UNION` to try to combine columns from two tables — a `JOIN` problem solved with the wrong tool entirely.
- Writing a recursive CTE with `UNION` instead of `UNION ALL` and either hitting a syntax error or paying for a full de-duplication pass on every iteration.
- Trusting a performance rule of thumb from a blog post over an actual `EXPLAIN` plan on your own data.

## Edge Cases

- A recursive CTE with a cyclical `manager_id` relationship (an employee indirectly manages themselves due to bad data) will recurse indefinitely unless the engine has a recursion limit or the query explicitly tracks visited rows to break cycles.
- An anti-join rewrite of `EXCEPT` and the native `EXCEPT` can return subtly different results if the compared columns contain `NULL` and the anti-join is written with `NOT IN` instead of `NOT EXISTS` or `LEFT JOIN ... IS NULL` — see Topic 03's `NULL` warning.

## Interview Questions

1. **(Foundational)** Why does `UNION ALL` never require a sort or hash step, while `UNION` does?
2. **(Intermediate)** When would you choose a `NOT EXISTS` anti-join over a native `EXCEPT`, and what has to be true for that choice to actually pay off?
3. **(Advanced)** Why must a recursive CTE's recursive member use `UNION ALL` rather than `UNION`?
4. **(Advanced)** A colleague "fixes" a slow report by adding an index, but the query uses `UNION` to combine an employee list with a department list to add a department column onto each employee row. What's actually wrong, and why won't an index fix it?
5. **(Staff-level)** You're handed a reconciliation job that takes ninety minutes on `EXCEPT` against two 40-million-row tables with no indexes on the compared column. Walk through your diagnostic and remediation plan.

## Summary

Set-operator performance comes down to one question: does this operation need to detect duplicates, and if so, does the engine have to sort or hash the full data to do it, or can it use an index to probe row by row instead? `UNION ALL` sidesteps the question entirely. `EXISTS`/`NOT EXISTS` rewrites of `INTERSECT`/`EXCEPT` often win on indexed, large-scale data. Recursive `UNION ALL` solves a different class of problem — hierarchy traversal — and always uses `ALL` by necessity.

## Practice Problems

1. Write both the native `INTERSECT` and the `EXISTS`-based rewrite for "customers who exist in both `crm_customers` and `erp_customers`," and describe, in a comment, what index you'd add before trusting either at scale.
2. Write a recursive CTE that returns every employee's full management chain up to the top, one row per employee, with a `depth` column.
3. Identify, in a comment, which scenario in `04_BUSINESS_DATA_INTEGRATION.sql` would benefit most from being materialized into a scheduled table rather than recomputed on every query, and explain why.

## Further Reading

- PostgreSQL Docs — Query Planning, Recursive Queries (`WITH RECURSIVE`)
- Microsoft Learn — Recursive Queries Using Common Table Expressions
- Use the Index, Luke — anti-join and semi-join optimization patterns

---
[← Data Reconciliation](05_DATA_RECONCILIATION.md) · [Next: Real-World Case Study →](07_REAL_WORLD_CASE_STUDY.md)
