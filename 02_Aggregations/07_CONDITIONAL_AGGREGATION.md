# Conditional Aggregation

## Introduction

Every function so far aggregated *all* rows in a group. Real reports almost never want that — they want "count how many were **active**" and "count how many were **inactive**" side by side, in a single row, without running two separate queries. That's conditional aggregation, and it's one of the highest-value, most interview-relevant patterns in all of SQL.

## Learning Objectives

- Combine `CASE WHEN` with aggregate functions to compute conditional totals and counts
- Pivot category values into columns using conditional `SUM()`
- Use PostgreSQL's `FILTER (WHERE ...)` syntax as a cleaner alternative to `CASE WHEN` inside aggregates
- Recognize when conditional aggregation replaces the need for multiple separate queries or self-joins

## Concept Overview

Wrapping a `CASE WHEN` expression inside an aggregate function lets you aggregate *only the rows matching a condition*, without filtering the whole query down with `WHERE` — because `WHERE` would remove the other rows from the group entirely, and you need all rows present to compute several conditional metrics side by side.

```sql
SELECT
    dept_id,
    SUM(CASE WHEN salary > 50000 THEN 1 ELSE 0 END) AS high_earners,
    SUM(CASE WHEN salary <= 50000 THEN 1 ELSE 0 END) AS standard_earners
FROM employes
GROUP BY dept_id;
```

## Business Context

This is the exact pattern behind almost every "pivoted" dashboard tile you've ever seen: "Orders: Pending / Shipped / Delivered" as three columns in one row, "Tickets: Open / Closed" side by side, "Revenue: This Year / Last Year" in adjacent columns. Without conditional aggregation, each of those requires a separate query (or a self-join) per condition.

## Where Companies Use It

- **Support**: open vs. closed ticket counts per team, in one row per team
- **Sales**: revenue this month vs. revenue same month last year, side by side
- **HR**: headcount by employment type (full-time vs. contractor) per department

## Syntax

```sql
-- Conditional COUNT (the CASE WHEN ... THEN 1 ELSE 0 END pattern)
SELECT
    dept_id,
    SUM(CASE WHEN salary > 50000 THEN 1 ELSE 0 END) AS high_earner_count
FROM employes
GROUP BY dept_id;

-- Conditional COUNT, shorthand using COUNT() + CASE returning NULL
SELECT
    dept_id,
    COUNT(CASE WHEN salary > 50000 THEN 1 END) AS high_earner_count
FROM employes
GROUP BY dept_id;

-- PostgreSQL only: FILTER clause (cleaner, and typically faster to read)
SELECT
    dept_id,
    COUNT(*) FILTER (WHERE salary > 50000) AS high_earner_count
FROM employes
GROUP BY dept_id;
```

## Execution Flow

```
Per row, before aggregation:
  salary=62000 -> CASE WHEN salary > 50000 THEN 1 ELSE 0 END -> 1
  salary=40000 -> CASE WHEN salary > 50000 THEN 1 ELSE 0 END -> 0
  salary=58000 -> CASE WHEN salary > 50000 THEN 1 ELSE 0 END -> 1

SUM() of those per-row 1s and 0s, per group
  = the conditional count for that group
```

## Engineering Notes

- `SUM(CASE WHEN cond THEN 1 ELSE 0 END)` and `COUNT(CASE WHEN cond THEN 1 END)` (note: **no `ELSE`**, defaulting to `NULL`) are functionally equivalent — both count only matching rows. The `COUNT` form is slightly more idiomatic since `COUNT()` already ignores `NULL` by design, removing the need for an explicit `ELSE 0`.
- Never write `WHERE salary > 50000` when you need conditional counts *alongside* other conditions in the same row — `WHERE` would discard the other rows entirely, making it impossible to also compute `standard_earner_count` in the same query.
- Conditional `SUM()` (rather than `COUNT()`) is the standard "pivot" pattern: `SUM(CASE WHEN category = 'A' THEN amount ELSE 0 END) AS category_a_total` turns row-level categories into report columns.

## PostgreSQL Notes

`FILTER (WHERE ...)` is PostgreSQL-specific (and supported by some other engines like SQLite) but **not available in MySQL** — MySQL requires the `CASE WHEN` form shown above. If a query needs to run identically on both engines, use `CASE WHEN`.

## MySQL Notes

MySQL has no `FILTER` clause — always use `SUM(CASE WHEN ...)` or `COUNT(CASE WHEN ... THEN 1 END)`.

## Edge Cases

- If **no** row in a group matches the `CASE WHEN` condition, the conditional `SUM()` returns `0` (not `NULL`) — because `CASE WHEN false THEN 1 ELSE 0 END` still produces a real `0` for every row, and `SUM()` of all-zeros is `0`. This is different from a plain `SUM(salary)` on an empty group, which returns `NULL`. Conditional `COUNT(CASE WHEN ... THEN 1 END)` (without `ELSE`) also returns `0` on no matches, because `COUNT()` never returns `NULL`.
- Multiple `CASE WHEN` conditions in the same query can overlap or be mutually exclusive depending on how they're written — be deliberate about which.

## Common Mistakes

**Wrong** — using `WHERE` when multiple conditional metrics are needed side by side:
```sql
-- This only computes high earners — standard earners are gone entirely
SELECT dept_id, COUNT(*) AS high_earner_count
FROM employes
WHERE salary > 50000
GROUP BY dept_id;
```

**Correct**:
```sql
SELECT
    dept_id,
    COUNT(CASE WHEN salary > 50000 THEN 1 END) AS high_earner_count,
    COUNT(CASE WHEN salary <= 50000 THEN 1 END) AS standard_earner_count
FROM employes
GROUP BY dept_id;
```

## Interview Questions

1. Why would you use `CASE WHEN` inside an aggregate instead of just filtering with `WHERE`?
2. What's the difference between `SUM(CASE WHEN cond THEN 1 ELSE 0 END)` and `COUNT(CASE WHEN cond THEN 1 END)` — and why do they produce the same result?
3. Write a query that returns, per department, both the count of employees earning above $50,000 and the count earning at or below $50,000, in a single row per department.
4. Why is PostgreSQL's `FILTER (WHERE ...)` not portable to MySQL?

## Summary

Conditional aggregation — `CASE WHEN` (or PostgreSQL's `FILTER`) nested inside `SUM()`/`COUNT()` — lets a single query compute multiple category-specific metrics side by side, without the row-elimination that `WHERE` would cause. It's the standard technique behind pivoted dashboard reporting.

## Practice Challenges

1. Write a query returning, per city, the count of employees earning above $55,000 vs. at or below, using `CASE WHEN`.
2. Rewrite challenge 1 using PostgreSQL's `FILTER (WHERE ...)` syntax instead.
3. Write a query pivoting department headcount into columns for "Nagpur employees" and "Pune employees" per department, using conditional `SUM()`.

## Further Reading

- [PostgreSQL Aggregate Expressions — FILTER clause](https://www.postgresql.org/docs/current/sql-expressions.html#SYNTAX-AGGREGATES)
- [MySQL CASE Operator](https://dev.mysql.com/doc/refman/8.0/en/case-operator.html)

---
**Related Topics:** [GROUP BY](./05_GROUP_BY.md) · [HAVING](./06_HAVING.md) · [Business Cases](./08_BUSINESS_CASES.md) · Advanced Aggregations (Module 12)
