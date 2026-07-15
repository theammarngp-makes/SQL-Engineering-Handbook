# 02 — Creating Views

**Module:** 14 — Views
**Previous:** [01 — Introduction to Views](01_INTRODUCTION_TO_VIEWS.md) · **Next:** [03 — Updatable Views](03_UPDATABLE_VIEWS.md)

---

## Learning Objectives

- Use full `CREATE VIEW` syntax including options MySQL exposes
- Understand `CREATE OR REPLACE` vs `DROP` + `CREATE`
- Rename View columns explicitly and know when it's required
- Alter and drop Views safely

## Concept Overview

Creating a View is syntactically simple; the engineering decisions live in the options around it — algorithm hints, security context, and column naming — which is why this file separates *creation mechanics* from the business-logic examples in Module 01.

## Why This Exists

A repository or team with dozens of Views needs consistent, predictable creation patterns — otherwise every View becomes a one-off with different conventions, and nobody can safely modify one without reading its full definition first.

## Business Context

An Analytics Engineering team maintaining 40+ Views across Sales, Finance, and HR domains needs every View creation script to be idempotent (safe to re-run in CI/CD as schema migrates) and self-documenting.

## Where Companies Use It

- CI/CD pipelines that redeploy View definitions on every merge to `main` (dbt does this for View-materialized models)
- Migration scripts that need to safely replace a View's logic without a two-step drop/create that briefly breaks dependents

## Real Business Examples

```sql
-- Idempotent creation — safe to re-run, never errors if the View exists
CREATE OR REPLACE VIEW vw_headcount_by_department AS
SELECT
    d.department_name,
    d.region,
    COUNT(e.employee_id) AS headcount
FROM hr_departments AS d
LEFT JOIN hr_employees AS e
    ON e.department_id = d.department_id
GROUP BY d.department_name, d.region;
```

## Syntax

```sql
CREATE [OR REPLACE]
    [ALGORITHM = {UNDEFINED | MERGE | TEMPTABLE}]
    [DEFINER = user]
    [SQL SECURITY {DEFINER | INVOKER}]
    VIEW view_name [(column_list)]
    AS select_statement
    [WITH [CASCADED | LOCAL] CHECK OPTION];

ALTER VIEW view_name AS select_statement;   -- redefines, preserves privileges
DROP VIEW [IF EXISTS] view_name;
```

## Visual Explanation

```
CREATE VIEW  ──►  writes definition to information_schema.VIEWS
ALTER VIEW   ──►  overwrites definition, keeps GRANTs intact
DROP VIEW    ──►  removes definition; dependents break immediately
```

## Step-by-Step Walkthrough

1. `CREATE OR REPLACE VIEW` is the standard production pattern — it avoids the race condition and privilege loss of `DROP VIEW` followed by `CREATE VIEW` (a `DROP` briefly leaves the View absent, and re-`CREATE` resets any GRANTs made directly on the View object).
2. Use `ALTER VIEW` only when you specifically want to keep the exact same View object identity (e.g., certain privilege inheritance edge cases) — in practice, most teams standardize on `CREATE OR REPLACE`.
3. Always name columns explicitly, either via the base query's column aliases or the `(column_list)` syntax, never rely on positional inference.

## Engineering Notes

`ALGORITHM` is a hint, not a guarantee — MySQL's optimizer can override `MERGE` back to `TEMPTABLE` if the query structure disqualifies merging (aggregates, `DISTINCT`, `UNION`, subqueries in `SELECT`, etc.), covered fully in Module 07.

## Production Considerations

Every `CREATE OR REPLACE VIEW` in a migration script should be preceded by a comment block stating the business rule it encodes and the ticket/PR that introduced it — this is the difference between a maintainable View library and 40 undocumented objects nobody wants to touch.

## Performance Notes

`CREATE OR REPLACE` and `ALTER VIEW` are metadata-only operations — near-instant regardless of base table size, since no data is copied or rewritten.

## Edge Cases

- `DROP VIEW IF EXISTS` on a View that other Views depend on does not cascade — dependents break at query time with an error, not at drop time.
- Column list length in `CREATE VIEW view_name (col1, col2, ...)` must exactly match the number of columns returned by the `SELECT` — a mismatch is a hard error at creation, not query time.

## Best Practices

- Standardize on `CREATE OR REPLACE VIEW` in all migration/deployment scripts.
- Always specify explicit column names.
- Keep one View definition per file in version control, named to match the View name, for clean diffs and code review.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| `DROP` then `CREATE` instead of `CREATE OR REPLACE` | Brief window where dependents fail; GRANTs on the View object are lost |
| Relying on positional column inference | Silent column meaning swap if the base query's `SELECT` order changes |
| No documentation comment | Business rule knowledge lost when the author leaves the team |

## Interview Questions

1. "What's the difference between `CREATE OR REPLACE VIEW` and `DROP VIEW` + `CREATE VIEW`?" — atomicity and privilege preservation.
2. "Can you `ALTER` a View's columns without recreating it?" — No; `ALTER VIEW` fully redefines the `SELECT`, so it's a full column-set replacement, not incremental.

## Summary

View creation is metadata-only and near-instant. The engineering discipline is in consistent, idempotent, documented creation patterns — not the syntax itself.

## Practice Challenges

1. Write a `CREATE OR REPLACE VIEW` for "employees hired in the last 2 years" using `hr_employees`, with explicit column names.
2. Explain, without running it, why `DROP VIEW` followed immediately by `CREATE VIEW` in a deployment script run by two concurrent CI jobs is a race condition.

## Further Reading

- MySQL 8.0 Reference Manual — [CREATE VIEW](https://dev.mysql.com/doc/refman/8.0/en/create-view.html)
- MySQL 8.0 Reference Manual — [ALTER VIEW](https://dev.mysql.com/doc/refman/8.0/en/alter-view.html)
