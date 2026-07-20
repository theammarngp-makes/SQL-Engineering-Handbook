# HAVING

## Introduction

`HAVING` is the final filter in the aggregation pipeline — it filters the *groups* that `GROUP BY` produced, based on their aggregated values. It's the single concept in this module most confused with `WHERE`, and interviewers know it.

## Learning Objectives

- Explain precisely why `HAVING` exists when `WHERE` already filters
- Use `HAVING` with aggregate conditions correctly
- Know when a condition belongs in `WHERE` vs `HAVING`
- Combine `WHERE` and `HAVING` in the same query

## Concept Overview

`WHERE` filters individual rows **before** grouping happens. `HAVING` filters groups **after** aggregation has already collapsed rows into summary values.

| Clause | Operates on | Runs |
|---|---|---|
| `WHERE` | Individual rows | Before `GROUP BY` |
| `HAVING` | Aggregated groups | After `GROUP BY` |

## Business Context

"Show me departments with more than 5 employees" cannot be expressed with `WHERE`, because "more than 5 employees" is a fact about the *group*, not about any single row — no individual employee row has a "5 employees" value to filter on. That's exactly the gap `HAVING` fills.

## Syntax

```sql
SELECT dept_id, COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id
HAVING COUNT(*) > 1;
```

## Execution Flow

```
employes rows
   │
   ▼
WHERE      -- (optional) filter rows first, e.g. WHERE dept_id IS NOT NULL
   │
   ▼
GROUP BY dept_id  -- collapse into groups
   │
   ▼
HAVING COUNT(*) > 1   -- keep only groups matching this aggregate condition
   │
   ▼
SELECT dept_id, COUNT(*)   -- final output
```

## Engineering Notes

- You **cannot** put an aggregate function inside `WHERE` — `WHERE COUNT(*) > 1` is invalid in every mainstream engine, because at the point `WHERE` executes, grouping hasn't happened yet and there's no aggregate to evaluate.
- `HAVING` can reference an aggregate that isn't even in the `SELECT` list — e.g. `HAVING AVG(salary) > 50000` is valid even if `AVG(salary)` isn't returned to the caller.
- `WHERE` should always be preferred over `HAVING` when the condition *can* be expressed on raw rows — filtering rows early with `WHERE` reduces the number of rows the engine has to group and aggregate, which is meaningfully cheaper on large tables than grouping everything and discarding whole groups afterward via `HAVING`.

## MySQL Notes

MySQL historically allowed `HAVING` to reference a `SELECT`-list alias directly (`HAVING employee_count > 1`), which is a convenient extension beyond strict ANSI SQL.

## PostgreSQL Notes

PostgreSQL also supports referencing a `SELECT`-list alias inside `HAVING`, matching MySQL's behavior here — this is one of the few areas where both engines are more permissive than strict ANSI SQL, in the same direction.

## Edge Cases

- `HAVING` with no `GROUP BY` treats the entire table as a single group — `SELECT COUNT(*) FROM employes HAVING COUNT(*) > 100;` is valid and either returns one row or zero rows.
- A `HAVING` condition that no group satisfies simply returns zero rows — not an error.

## Common Mistakes

**Wrong**:
```sql
SELECT dept_id, COUNT(*)
FROM employes
GROUP BY dept_id
WHERE COUNT(*) > 1;   -- invalid: aggregate function in WHERE
```

**Correct**:
```sql
SELECT dept_id, COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id
HAVING COUNT(*) > 1;
```

**Also wrong** (using `HAVING` for a row-level condition that belongs in `WHERE`, wasting work by grouping unfiltered rows first):
```sql
SELECT dept_id, COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id
HAVING dept_id = 10;   -- works, but should be WHERE dept_id = 10
```

## Interview Questions

1. Why can't `WHERE` reference `COUNT(*)`? What has to happen first?
2. Rewrite this to use the correct clause: `... GROUP BY dept_id WHERE AVG(salary) > 50000`.
3. Given a query with both `WHERE` and `HAVING`, in what order do they logically execute?
4. Is `HAVING` with no `GROUP BY` valid? What does it operate on?

## Summary

`WHERE` filters rows before grouping; `HAVING` filters groups after aggregation. Any condition involving an aggregate function must go in `HAVING`. Any condition that can be expressed on raw columns should go in `WHERE`, for both correctness and performance.

## Practice Challenges

1. Write a query listing cities with more than 2 employees.
2. Write a query listing departments where the average salary exceeds $50,000, using both `WHERE` (to exclude unassigned employees first) and `HAVING` (to filter the resulting averages) in the same query.

## Further Reading

- [PostgreSQL HAVING Documentation](https://www.postgresql.org/docs/current/sql-select.html#SQL-HAVING)

---
**Related Topics:** [GROUP BY](./05_GROUP_BY.md) · [COUNT()](./01_COUNT.md) · [Conditional Aggregation](./07_CONDITIONAL_AGGREGATION.md)
