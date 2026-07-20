# AVG()

## Introduction

`AVG()` returns the arithmetic mean of a numeric column. It looks trivial and is one of the most misused aggregate functions in production reporting — mostly because of how it interacts with `NULL`.

## Learning Objectives

- Compute averages correctly across a table or group
- Explain precisely how `AVG()` treats `NULL` values (this is the crux of the whole file)
- Avoid the classic "average of an average" mistake when combining pre-aggregated data
- Round `AVG()` output appropriately for currency and reporting

## Concept Overview

`AVG(column_name)` = `SUM(column_name) / COUNT(column_name)` — critically, the denominator is `COUNT(column_name)` (non-`NULL` rows), **not** `COUNT(*)` (all rows).

## Business Context

"Average order value," "average salary," "average handling time" — these numbers drive pricing decisions, compensation benchmarking, and SLA reporting. An `AVG()` computed over the wrong denominator silently skews every one of them.

## Where Companies Use It

- **HR**: average salary by department, average tenure
- **E-commerce**: average order value (AOV), average basket size
- **Support**: average ticket resolution time

## Syntax

```sql
SELECT AVG(column_name) FROM table_name;
SELECT dept_id, AVG(salary) FROM employes GROUP BY dept_id;
```

## Execution Flow

```
salary column: [50000, NULL, 60000, 40000]

SUM (NULL skipped)  = 150000
COUNT (NULL skipped)=      3     <- NOT 4
AVG                 =  50000
```

## Engineering Notes

- **`AVG()` divides by the count of non-`NULL` values, not the total row count.** This is the single most important fact in this file. If 2 out of 10 employees have a `NULL` salary, `AVG(salary)` divides by 8, not 10.
- `AVG()`, like `SUM()`, returns `NULL` on an empty or all-`NULL` group.
- **Never average pre-averaged numbers directly.** `AVG(AVG(x))` across groups of different sizes is mathematically wrong unless every group has the same row count — this is a very common analyst mistake when rolling up department averages into a company-wide average. The correct rollup is `SUM(x) / COUNT(x)` at the ungrouped level, not the mean of the per-group means.

## MySQL Notes

`AVG()` returns a `DECIMAL` for exact-numeric input and a `DOUBLE` for approximate-numeric input — round explicitly for display: `ROUND(AVG(salary), 2)`.

## PostgreSQL Notes

Same rounding guidance applies; PostgreSQL's `AVG(integer)` returns `numeric`, which is exact but may print with more decimal places than desired without `ROUND()`.

## Edge Cases

- If a `WHERE` clause filters out every row before aggregation, `AVG()` returns one row containing `NULL` — same empty-group behavior as `SUM()`.
- Averaging a column with extreme outliers (e.g., one $10M enterprise deal among $500 average deals) can produce a misleading mean — consider reporting the median (via `PERCENTILE_CONT` in Postgres, or window functions) alongside `AVG()` for skewed distributions. That's outside this module's scope but worth flagging.

## Common Mistakes

**Wrong** — rolling up department averages into a company average by averaging the averages:
```sql
-- WRONG if departments have different headcounts
SELECT AVG(dept_avg_salary) FROM (
  SELECT dept_id, AVG(salary) AS dept_avg_salary
  FROM employes GROUP BY dept_id
) t;
```

**Correct**:
```sql
SELECT AVG(salary) AS company_avg_salary FROM employes;
```

## Interview Questions

1. What does `AVG()` divide by — total rows or non-`NULL` rows? Why does this distinction matter?
2. If department A has 2 employees averaging $80,000 and department B has 8 employees averaging $50,000, what is the company-wide average salary, and why isn't it $65,000?
3. Why might a company report both `AVG()` and `MAX()`/`MIN()` together rather than `AVG()` alone?

## Summary

`AVG()` is `SUM() / COUNT(column)`, both of which silently skip `NULL`. It returns `NULL` on empty groups. Never average pre-aggregated averages across groups of unequal size.

## Practice Challenges

1. Compute the correct company-wide average salary, and separately the (incorrect) average-of-department-averages, to see the discrepancy on your own data.
2. Write a query for average salary per city.

## Further Reading

- [PostgreSQL Aggregate Functions](https://www.postgresql.org/docs/current/functions-aggregate.html)

---
**Related Topics:** [SUM()](./02_SUM.md) · [MIN() & MAX()](./04_MIN_MAX.md) · [HAVING](./06_HAVING.md)
