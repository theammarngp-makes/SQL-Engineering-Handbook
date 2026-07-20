# SUM()

## Introduction

`SUM()` collapses a numeric column into a single total. It's the backbone of every revenue report, payroll summary, and budget rollup ever written in SQL.

## Learning Objectives

- Compute totals correctly, including how `SUM()` handles `NULL`
- Understand why `SUM()` on an empty group returns `NULL`, not `0`
- Combine `SUM()` with `GROUP BY` for per-category totals
- Recognize precision pitfalls with `SUM()` on floating-point columns

## Concept Overview

`SUM(column_name)` adds up every non-`NULL` numeric value in the target column (or group) and returns a single total.

## Business Context

Finance doesn't ask "what's my average transaction" first — they ask "what's the total." `SUM()` is the query behind every "Total Revenue" tile on every executive dashboard.

## Where Companies Use It

- **Finance**: total revenue, total expenses, quarterly budget totals
- **HR**: total payroll cost per department
- **E-commerce**: total order value per customer

## Schema Used

This file uses `employes(emp_id, emp_name, dept_id, manager_id, salary)`. *(Note: earlier drafts of this file referenced a separate, undefined `salaries` table — that has been corrected. `salary` lives directly on `employes`, consistent with the schema used in `05_GROUP_BY.sql`.)*

## Syntax

```sql
SELECT SUM(column_name) FROM table_name;
SELECT dept_id, SUM(salary) FROM employes GROUP BY dept_id;
```

## Execution Flow

```
employes.salary: [50000, NULL, 62000, 48000]
                     │
                     ▼
        SUM() skips the NULL, adds the rest
                     │
                     ▼
                 160000
```

## Engineering Notes

- `SUM()` **ignores `NULL` values** — it does not treat them as zero. `SUM(salary)` over `[50000, NULL, 62000]` is `112000`, not an error and not `112000/0` weirdness.
- `SUM()` over a group with **zero rows, or all-`NULL` values, returns `NULL`** — not `0`. This is a very common production bug: `SUM(amount)` feeding into a dashboard tile that displays `NULL` as a blank, making it look like the query silently failed. Wrap in `COALESCE(SUM(amount), 0)` when a numeric fallback is required downstream.
- Summing a `FLOAT`/`DOUBLE` column can introduce floating-point rounding error at scale. For currency, prefer `DECIMAL`/`NUMERIC` columns so `SUM()` stays exact.

## MySQL Notes

MySQL's `SUM()` on an `INT` column returns a `DECIMAL` or `DOUBLE` depending on the input type — check `SUM()`'s return type if chaining into strict-mode arithmetic.

## PostgreSQL Notes

PostgreSQL widens `SUM(int)` to `bigint` automatically to avoid overflow on large tables — no manual casting needed for typical row counts.

## Edge Cases

- `SUM()` over an empty result set (e.g., filtered to zero rows by `WHERE`) returns a single row with `NULL`, not zero rows.
- Negative values sum normally — useful for refunds/chargebacks represented as negative amounts in a transactions table.

## Common Mistakes

**Wrong** — assuming a `NULL` total means "no revenue":
```sql
SELECT SUM(salary) FROM employes WHERE dept_id = 999; -- no such department
-- Returns NULL, easy to misread as "$0 payroll" in a report
```

**Correct**:
```sql
SELECT COALESCE(SUM(salary), 0) AS total_payroll
FROM employes WHERE dept_id = 999;
```

## Interview Questions

1. Why does `SUM()` return `NULL` instead of `0` on an empty group, and how do you defend against that in a dashboard query?
2. If a `salary` column has three `NULL` rows out of ten, what does `SUM(salary)` do with those three rows?
3. What's the risk of using `FLOAT` instead of `DECIMAL` for a column that will be aggregated with `SUM()`?

## Summary

`SUM()` totals a numeric column, silently skipping `NULL`s, and returns `NULL` (not `0`) when there's nothing to sum. Always decide deliberately whether a `NULL` total should be coerced to `0` for downstream consumers.

## Practice Challenges

1. Write a query for total salary cost per department, defaulting `NULL` totals to `0`.
2. Write a query for total salary cost per city (requires the same 3-table join pattern as `01_COUNT.sql` Q4).

## Further Reading

- [PostgreSQL Numeric Types](https://www.postgresql.org/docs/current/datatype-numeric.html)

---
**Related Topics:** [COUNT()](./01_COUNT.md) · [AVG()](./03_AVG.md) · [GROUP BY](./05_GROUP_BY.md)
