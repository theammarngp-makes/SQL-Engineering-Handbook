# COUNT()

## Introduction

`COUNT()` answers the single most common question asked of any dataset: *how many?* It's usually the first aggregate function anyone writes, and it's also the one most often used incorrectly — the difference between `COUNT(*)`, `COUNT(column)`, and `COUNT(DISTINCT column)` trips up even experienced engineers under interview pressure.

## Learning Objectives

By the end of this file you should be able to:
- Explain the behavioral difference between `COUNT(*)`, `COUNT(column)`, and `COUNT(DISTINCT column)`
- Predict what `COUNT()` returns when a table or group contains `NULL` values
- Use `COUNT()` correctly inside `GROUP BY` queries
- Recognize when `COUNT(*)` is a performance smell on very large tables

## Concept Overview

`COUNT()` returns the number of rows matched by a query, or the number of non-`NULL` values in a specific column.

| Form | Counts |
|---|---|
| `COUNT(*)` | Every row, including rows where every column is `NULL` |
| `COUNT(column_name)` | Only rows where `column_name` is **not** `NULL` |
| `COUNT(DISTINCT column_name)` | Only the number of unique non-`NULL` values |

## Business Context

Almost every dashboard has a headline number in the top-left corner — total customers, total orders, total open tickets. That number is a `COUNT()`. Getting it wrong (e.g., silently excluding rows with a `NULL` email) means shipping a dashboard that under-reports reality.

## Where Companies Use It

- **HR**: total headcount, active employees per department
- **E-commerce**: total orders, total distinct customers who ordered this month
- **Support**: total open tickets, tickets with no assigned agent (`NULL` check)

## Syntax

```sql
SELECT COUNT(*) FROM table_name;
SELECT COUNT(column_name) FROM table_name;
SELECT COUNT(DISTINCT column_name) FROM table_name;
```

## Execution Flow

```
employes table
┌────────┬──────────┬─────────┐
│ emp_id │ emp_name │ dept_id │
├────────┼──────────┼─────────┤
│   1    │  Alice   │   10    │
│   2    │  Bob     │  NULL   │   <- unassigned
│   3    │  Carol   │   10    │
│   4    │  Dave    │   20    │
└────────┴──────────┴─────────┘

COUNT(*)              -> 4   (every row)
COUNT(dept_id)        -> 3   (NULL row excluded)
COUNT(DISTINCT dept_id)-> 2  (10, 20)
```

## Engineering Notes

- `COUNT(*)` does **not** need to reference any particular column, so the optimizer is free to use the smallest available index (or table metadata, in some engines) rather than scanning wide rows — this is why `COUNT(*)` is generally *not* slower than `COUNT(1)`, contrary to a common myth.
- `COUNT(1)` and `COUNT(*)` are functionally identical in every mainstream RDBMS. Prefer `COUNT(*)` for clarity; it's the ANSI-idiomatic form.
- `COUNT(column)` forces a `NOT NULL` check on every row, which can matter on very large, sparsely-indexed columns.

## MySQL Notes

`COUNT(DISTINCT col1, col2)` is a **MySQL extension** — it counts distinct combinations of `col1` and `col2` together. This is not standard ANSI SQL.

## PostgreSQL Notes

PostgreSQL does not support multi-column `COUNT(DISTINCT col1, col2)`. Use `COUNT(DISTINCT (col1, col2))` (a row constructor) instead.

## Edge Cases

- `COUNT(*)` on an empty table returns `0`, never `NULL`. This is different from `SUM()`/`AVG()`, which return `NULL` on an empty group — a frequent source of bugs when the result feeds into further arithmetic.
- Inside `GROUP BY`, a group with zero matching rows never appears in the output at all (there's nothing to count `0` of) — don't confuse "group has 0 rows" with "group exists with a count of 0."

## Common Mistakes

**Wrong** — assuming `COUNT(column)` behaves like `COUNT(*)`:
```sql
-- Silently under-counts if manager_id has NULLs (e.g., the CEO)
SELECT COUNT(manager_id) AS total_employees FROM employes;
```

**Correct**:
```sql
SELECT COUNT(*) AS total_employees FROM employes;
```

## Interview Questions

1. What's the difference between `COUNT(*)` and `COUNT(1)`? *(Trick question — there isn't one in practice.)*
2. If a table has 100 rows and a column `email` is `NULL` in 5 of them, what does `COUNT(email)` return?
3. Write a query to count the number of **distinct** departments represented in the `employes` table.
4. Why does `COUNT(*)` return `0` instead of `NULL` on an empty table, while `SUM()` returns `NULL`?

## Summary

`COUNT(*)` counts rows. `COUNT(column)` counts non-`NULL` values in that column. `COUNT(DISTINCT column)` counts unique non-`NULL` values. Choosing the wrong form is the single most common aggregation bug in production reporting code.

## Practice Challenges

1. Write a query returning the number of employees with a non-`NULL` `dept_id`.
2. Write a query returning the number of distinct cities employees work in (requires joining to `locations`).
3. Predict — without running it — what `COUNT(*)` returns on the result of a `LEFT JOIN` where the right table has no match for some rows.

## Further Reading

- [PostgreSQL Aggregate Functions](https://www.postgresql.org/docs/current/functions-aggregate.html)
- [MySQL COUNT() Reference](https://dev.mysql.com/doc/refman/8.0/en/aggregate-functions.html#function_count)

---
**Related Topics:** [SUM()](./02_SUM.md) · [GROUP BY](./05_GROUP_BY.md) · [HAVING](./06_HAVING.md)
