# MIN() and MAX()

## Introduction

`MIN()` and `MAX()` find the smallest and largest values in a column. They look like the simplest aggregates in the module, but they're the only two that work natively across **numbers, dates, and text** — which makes them more versatile, and more prone to surprising behavior on non-numeric columns, than `SUM()` or `AVG()`.

## Learning Objectives

- Use `MIN()`/`MAX()` across numeric, date, and text columns
- Explain why `MIN()`/`MAX()` ignore `NULL` the same way `SUM()`/`AVG()` do
- Understand how `MIN()`/`MAX()` order text values (collation-dependent)
- Combine `MIN()`/`MAX()` with `GROUP BY` to find extremes per category

## Concept Overview

| Function | Returns |
|---|---|
| `MIN(column)` | The smallest non-`NULL` value |
| `MAX(column)` | The largest non-`NULL` value |

## Business Context

"What was our highest sale of the month?" "Who's been here the longest?" "What's the earliest unfulfilled order?" — every one of these is a `MIN()`/`MAX()` query, and they're often the first thing an executive asks after seeing a `SUM()` or `AVG()` figure.

## Where Companies Use It

- **HR**: earliest hire date, highest/lowest salary
- **E-commerce**: largest single order, earliest unshipped order
- **Operations**: longest downtime incident, latest deployment timestamp

## Syntax

```sql
SELECT MIN(column_name) FROM table_name;
SELECT MAX(column_name) FROM table_name;
```

## Execution Flow

```
salary column: [50000, NULL, 62000, 40000]

MIN() -> 40000   (NULL ignored, smallest of the rest)
MAX() -> 62000   (NULL ignored, largest of the rest)
```

## Engineering Notes

- `MIN()`/`MAX()` ignore `NULL` exactly like `SUM()`/`AVG()` — a `NULL` value is never "the minimum."
- On indexed columns, `MIN()`/`MAX()` (with no `GROUP BY`) can often be satisfied by a single index seek rather than a full table scan — one of the cheapest aggregate queries an optimizer can run. This changes once `GROUP BY` is introduced; per-group `MIN()`/`MAX()` typically requires scanning each group.
- On text columns, `MIN()`/`MAX()` use the column's **collation** to determine ordering — case sensitivity and locale can change what "largest" means (`'Zebra'` vs `'apple'` may not sort the way you expect under a case-insensitive collation).
- On `DATE`/`TIMESTAMP` columns, `MIN()` finds the earliest moment and `MAX()` the most recent — this is the standard pattern for "first order date" / "last login" style fields.

## MySQL Notes

MySQL evaluates string `MIN()`/`MAX()` using the column's collation (commonly case-insensitive by default, e.g. `utf8mb4_general_ci`).

## PostgreSQL Notes

PostgreSQL string comparisons are case-sensitive by default (`'Z' < 'a'` in the default `C`-adjacent locale in many setups) — `MIN()`/`MAX()` on text can return different results than the "same" query in MySQL. Always verify collation when porting reports between the two.

## Edge Cases

- `MIN()`/`MAX()` on an empty group returns `NULL`, matching `SUM()`/`AVG()` behavior — not an error.
- `MIN()`/`MAX()` on a single-row group simply returns that row's value.

## Common Mistakes

**Wrong** — trying to get the *entire row* containing the max salary using only `MAX()`:
```sql
-- This does NOT return the employee with the highest salary —
-- it mixes an aggregate with a non-aggregated column with no
-- GROUP BY, which is invalid or misleading depending on the engine.
SELECT emp_name, MAX(salary) FROM employes;
```

**Correct** — use `ORDER BY ... LIMIT` (covered in Module 01) or a window function (Module 07) to retrieve the full row:
```sql
SELECT emp_name, salary
FROM employes
ORDER BY salary DESC
LIMIT 1;
```

## Interview Questions

1. Why can't you reliably get "the employee with the highest salary" using `MAX(salary)` alone in a `SELECT` with other non-aggregated columns?
2. What does `MIN()` return on an empty result set?
3. Why might `MAX(employee_name)` return a different "largest" name in MySQL vs. PostgreSQL on the same data?

## Summary

`MIN()`/`MAX()` find extremes across numeric, date, and text data, ignoring `NULL`. They cannot pull an entire related row on their own — for that, pair `ORDER BY` with `LIMIT`, or use a window function.

## Practice Challenges

1. Find the earliest and latest `emp_id` per department using `GROUP BY`.
2. Find the highest-paid employee's full row (name, department, salary) using `ORDER BY ... LIMIT 1` instead of `MAX()`.

## Further Reading

- [PostgreSQL Collation Support](https://www.postgresql.org/docs/current/collation.html)

---
**Related Topics:** [COUNT()](./01_COUNT.md) · [GROUP BY](./05_GROUP_BY.md) · Window Functions (Module 07)
