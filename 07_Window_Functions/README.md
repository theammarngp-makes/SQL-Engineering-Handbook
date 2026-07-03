# Module 07 — Window Functions

## Introduction

Window functions let you perform calculations across a set of rows that are
related to the current row, **without collapsing the result set** the way
`GROUP BY` does. They are the single most important tool for turning a
raw SQL developer into someone who can answer real analytics questions:
rankings, leaderboards, running totals, period-over-period comparisons, and
department-wise breakdowns — all in one query.

## What Is a Window Function?

A window function operates over a "window" of rows defined by an `OVER()`
clause. Unlike aggregate functions used with `GROUP BY`, window functions
**do not reduce the number of rows returned**. Each row keeps its identity
while also gaining access to a calculation performed across its window.

```sql
<function_name>(<arguments>) OVER (
    [PARTITION BY <column_list>]
    [ORDER BY <column_list>]
    [<frame_clause>]
)
```

## Why Learn Window Functions?

- They are asked in almost every mid-to-senior Data Analyst / Data Engineer
  interview.
- They replace fragile, slow correlated subqueries with a single readable
  pass over the data.
- They are the backbone of real business reporting: leaderboards, cohort
  analysis, growth rates, running balances, and top-N-per-group queries.

## Syntax Overview

```sql
SELECT
    column_a,
    column_b,
    WINDOW_FUNCTION() OVER (
        PARTITION BY grouping_column
        ORDER BY sort_column
    ) AS result_column
FROM table_name;
```

## Diagram Suggestion

```
[ Full Result Set ]
        |
        v
[ PARTITION BY dept_name ]  --> splits rows into independent windows
        |
        v
[ ORDER BY emp_id within each window ] --> defines row sequence
        |
        v
[ Window Function applied per row, per partition ]
```

## Module Roadmap

| # | Folder | Function(s) | Core Idea |
|---|--------|-------------|-----------|
| 01 | `01_ROW_NUMBER` | `ROW_NUMBER()` | Unique sequential numbering, ties broken arbitrarily |
| 02 | `02_RANK` | `RANK()` | Competition ranking, gaps after ties |
| 03 | `03_DENSE_RANK` | `DENSE_RANK()` | Competition ranking, no gaps after ties |
| 04 | `04_PARTITION_BY` | `PARTITION BY` | Reset any window function per group |
| 05 | `05_LAG_LEAD` | `LAG()` / `LEAD()` | Look at previous / next row |
| 06 | `06_FIRST_LAST_NTILE` | `FIRST_VALUE()` / `LAST_VALUE()` / `NTILE()` | Boundary values and bucketing |
| 07 | `07_RUNNING_TOTALS` | `SUM() OVER()` / `AVG() OVER()` | Cumulative and moving calculations |

## Business Scenarios Covered

| Domain | Use Case |
|---|---|
| HR | Employee seniority ranking, department leaderboards |
| Finance | Running balances, month-over-month growth |
| Retail | Top-N products per category |
| Banking | Rolling averages for risk monitoring |
| E-commerce | Customer order sequencing, cohort tiers |

## Learning Objectives

By the end of this module you will be able to:

1. Explain the difference between `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`.
2. Use `PARTITION BY` to compute per-group metrics without `GROUP BY`.
3. Retrieve previous/next row values using `LAG()`/`LEAD()`.
4. Retrieve boundary values with `FIRST_VALUE()` / `LAST_VALUE()`.
5. Bucket rows into equal groups using `NTILE()`.
6. Build running totals and running averages with frame clauses.
7. Know why `WHERE` cannot filter directly on a window function result, and
   how to work around it with a CTE or subquery.

## Practice Checklist

- [ ] I can write `ROW_NUMBER()` with and without `PARTITION BY`.
- [ ] I can explain the ranking gap behavior of `RANK()` vs `DENSE_RANK()`.
- [ ] I can filter window function output using a CTE.
- [ ] I can compute a running total with `SUM() OVER (ORDER BY ...)`.
- [ ] I can compute month-over-month style deltas using `LAG()`.

## Common Mistakes

- Trying to reference a window function alias directly in `WHERE` (illegal —
  window functions are evaluated after `WHERE`, so wrap in a CTE/subquery).
- Forgetting `ORDER BY` inside `OVER()` when using `LAG()`/`LEAD()`, which
  makes row order (and therefore the result) undefined.
- Using `LAST_VALUE()` without an explicit frame clause
  (`ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`), which
  silently returns the *current* row instead of the true last row.
- Confusing `RANK()` (leaves gaps) with `DENSE_RANK()` (no gaps).

## Interview Questions

1. What is the difference between a window function and a `GROUP BY` aggregate?
2. Why can't you filter directly on a window function alias in `WHERE`?
3. Walk through `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` on a tied dataset.
4. How would you find the second-highest salary per department?
5. How would you calculate a 3-month moving average in SQL?

## Resources

- [PostgreSQL Window Functions Documentation](https://www.postgresql.org/docs/current/tutorial-window.html)
- [MySQL Window Functions Reference](https://dev.mysql.com/doc/refman/8.0/en/window-functions.html)

## Prerequisites

- `06_CTEs` (Common Table Expressions)
- `03_Joins`
- `02_Aggregations`

