# ROW_NUMBER()

## Overview

`ROW_NUMBER()` assigns a **unique, sequential integer** to every row within
its window, starting at 1. Ties in the `ORDER BY` are broken arbitrarily —
no two rows ever receive the same number.

```
Ordered values: [10, 20, 20, 40]
ROW_NUMBER():   [1,  2,  3,  4]
```

## Learning Objectives

- Generate a unique sequence number per row.
- Understand that `ROW_NUMBER()` never produces duplicate values, even on ties.
- Use `ROW_NUMBER()` inside a CTE/subquery to filter on it (since window
  function results cannot be referenced directly in `WHERE`).

## Prerequisites

- Basic `SELECT` statements
- `ORDER BY`
- CTEs (`WITH` clause) — module `06_CTEs`

## Syntax

```sql
SELECT
    column_a,
    column_b,
    ROW_NUMBER() OVER (ORDER BY sort_column) AS row_seq
FROM table_name;
```

## Dataset Used

`employes` (emp_id, emp_name, dept_id, manager_id)

## Examples

See [`01_row_number.sql`](./01_row_number.sql) for five fully worked,
production-commented examples.

## Real World Applications

- Assigning display order to a paginated report.
- Deduplicating rows (keep only `ROW_NUMBER() = 1` per group).
- Generating a synthetic sequence ID when no natural key exists.

## Business Use Cases

| Domain | Scenario |
|---|---|
| HR | Assign a unique seniority sequence to employees |
| E-commerce | Number a customer's orders chronologically |
| Banking | Sequence transactions for a statement |

## Common Mistakes

- Referencing the `ROW_NUMBER()` alias directly in a `WHERE` clause on the
  same `SELECT` — this throws a syntax/semantic error because `WHERE` runs
  *before* window functions are evaluated. Always wrap in a CTE or subquery.
- Forgetting `ORDER BY` inside `OVER()`, which makes the numbering
  non-deterministic.
- Assuming `ROW_NUMBER()` respects ties like `RANK()` does — it does not.

## Best Practices

- Always give window function aliases meaningful names (`emp_seq`, not `rn`).
- Use a CTE (not a nested subquery) when the query needs to be readable and
  reused later in the file — it mirrors how production analytics code is
  reviewed on GitHub.
- Prefer `ROW_NUMBER()` over `LIMIT` alone when you need deterministic,
  per-group "top-N" results (combine with `PARTITION BY`).

## Engineering Notes

`ROW_NUMBER()` is computed by MySQL's window function engine in a single
pass after the base result set is materialized. It is O(n log n) due to the
required sort on `ORDER BY`. For very large tables, ensure the `ORDER BY`
column is indexed to avoid an expensive filesort.

## Practice Questions

1. Assign a row number to every employee ordered by `emp_id`.
2. Assign a row number ordered by `emp_name` instead.
3. Return only the employee name and its row number.
4. Return only the first 3 employees using `ROW_NUMBER()`.
5. Return the employee whose `ROW_NUMBER() = 1` (requires a CTE or subquery).

## Difficulty

Beginner

## Estimated Time

20–25 minutes

## Learning Outcomes

- Comfortably write `ROW_NUMBER() OVER (ORDER BY ...)`.
- Understand why window function aliases cannot be filtered directly in
  `WHERE`, and how to solve that with a CTE.

## Related Topics

- `02_RANK`
- `03_DENSE_RANK`
- `04_PARTITION_BY`

## Next Topic

[`02_RANK`](../02_RANK/README.md)
