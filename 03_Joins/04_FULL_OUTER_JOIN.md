# 04 — FULL OUTER JOIN

> Keep every row from both tables — matched pairs, unmatched left rows, and unmatched right rows all appear, with `NULL` filling whichever side didn't match.

**Difficulty:** Beginner → Intermediate · **Estimated time:** 30–40 min · **Prerequisites:** `02_LEFT_JOIN.md`, `03_RIGHT_JOIN.md`

---

## 📑 Contents

- [Learning Objectives](#learning-objectives)
- [Concept Overview](#concept-overview)
- [Business Context](#business-context)
- [Syntax](#syntax)
- [Execution Flow](#execution-flow)
- [Engineering Notes](#engineering-notes)
- [Vendor Notes — the MySQL Gap](#vendor-notes--the-mysql-gap)
- [Edge Cases](#edge-cases)
- [Common Mistakes](#common-mistakes)
- [Best Practices](#best-practices)
- [Interview Questions](#interview-questions)
- [Practice Challenges](#practice-challenges)
- [Further Reading](#further-reading)

---

## Learning Objectives

1. Explain FULL OUTER JOIN as the union of what LEFT JOIN and RIGHT JOIN each produce.
2. Write a portable FULL OUTER JOIN emulation for MySQL, which has no native `FULL OUTER JOIN` keyword.
3. Use FULL OUTER JOIN to do genuine two-sided reconciliation — the class of business problem it exists for.

---

## Concept Overview

<p align="center">
  <img src="./assets/diagrams/full-outer-join.svg" width="70%" alt="FULL OUTER JOIN Venn diagram — both circles fully shaded"/>
</p>

FULL OUTER JOIN (`FULL JOIN`) preserves rows from **both** tables regardless of whether a match exists on the other side. Conceptually, it's `LEFT JOIN` and `RIGHT JOIN` merged into a single result set: every matched pair appears once, every unmatched left row appears with `NULL` on the right, and every unmatched right row appears with `NULL` on the left.

```
   employees only          matched (both sides)          departments only
  ┌───────────────┐      ┌────────────────────┐        ┌────────────────┐
  │  Farhan Ali    │      │ 9 employee rows ↔   │        │  Legal (dept)   │
  │  dept_id: NULL │      │ their departments   │        │  0 employees    │
  └───────────────┘      └────────────────────┘        └────────────────┘
        ▲                          ▲                              ▲
        └── LEFT JOIN keeps this ──┴── RIGHT JOIN keeps this ─────┘
                        FULL OUTER JOIN keeps ALL THREE
```

## Business Context

**Where companies use it:** reconciliation problems — anywhere two datasets are supposed to represent the same entities but might disagree. Classic examples: comparing a payroll system's employee list against an HR system's employee list to find records that exist in one but not the other; comparing expected vs. actual inventory counts; comparing a source system export against a data warehouse load to find drift. FULL OUTER JOIN is the query that answers "where do these two datasets disagree, in either direction?" in a single pass.

---

## Syntax

```sql
SELECT
    e.emp_name,
    d.dept_name
FROM employees e
FULL OUTER JOIN departments d
    ON e.dept_id = d.dept_id;
```

`OUTER` is optional (`FULL JOIN` is equivalent) but conventionally kept for symmetry with `LEFT OUTER JOIN` / `RIGHT OUTER JOIN` in codebases that write those out in full.

---

## Execution Flow

```
FROM employees e
    │
    ▼
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id
    │   ├─ matched rows:        both sides populated
    │   ├─ unmatched employees: dept_name = NULL
    │   └─ unmatched departments: emp_name = NULL
    ▼
SELECT e.emp_name, d.dept_name
```

### Step-by-Step Walkthrough

Against the seed data: 9 employees match a department, Farhan Ali (`dept_id = NULL`) doesn't match anything and appears with `dept_name = NULL`, and Legal (`dept_id = 60`, no employees) appears with `emp_name = NULL`. Total: **11 rows** — the same 9 matched rows as the INNER JOIN, plus the 1 unmatched-left row LEFT JOIN would add, plus the 1 unmatched-right row RIGHT JOIN would add.

---

## Engineering Notes

**FULL OUTER JOIN is genuinely `LEFT JOIN UNION RIGHT JOIN`** where native support is missing (see the MySQL workaround below) — but even where it's natively supported, it's worth understanding this equivalence because it explains the performance characteristics: the engine typically executes it as something functionally close to that union internally, which is more expensive than a plain LEFT or RIGHT JOIN. Don't reach for FULL OUTER JOIN by default "to be safe" — use it specifically when the business question genuinely requires seeing gaps on *both* sides at once. If you only care about one side's gaps, LEFT or RIGHT JOIN alone is cheaper and clearer.

## Vendor Notes — the MySQL Gap

**MySQL (all versions through 8.0 at time of writing) has no `FULL OUTER JOIN` keyword.** This is the single most important vendor difference in this entire module, and it's a frequent interview question specifically because it separates candidates who've only used Postgres/SQL Server from those who've had to actually solve this in MySQL production code.

**PostgreSQL / SQL Server / Oracle:** `FULL OUTER JOIN` is fully native — use the syntax above directly.

**MySQL workaround** — `UNION` (not `UNION ALL`) of a LEFT JOIN and a RIGHT JOIN:

```sql
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id

UNION

SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;
```

`UNION` (which deduplicates) rather than `UNION ALL` is required here — without it, every genuinely matched row (present in both the LEFT and RIGHT JOIN results) would be duplicated. This has a real cost: `UNION`'s deduplication requires sorting or hashing the combined result, which is more expensive than a native FULL OUTER JOIN would be. On large tables, this is a legitimate reason some teams choose to materialize a reconciliation as two separate queries (missing-on-the-right, missing-on-the-left) rather than paying for the union.

---

## Edge Cases

**NULL behavior:** exactly as in LEFT and RIGHT JOIN, mirrored to both sides simultaneously — a row can have `NULL` on the left, `NULL` on the right, but never `NULL` on both (a row with no join-key match on either side simply doesn't exist to join).

**The MySQL UNION workaround's own NULL trap:** if `emp_name` itself can legitimately be `NULL` in real data (unlike this schema, where it's `NOT NULL`), the `UNION` deduplication could incorrectly collapse two genuinely different rows that happen to both have `NULL` in the same column — worth testing explicitly if your MySQL emulation involves a nullable column in the `SELECT` list, not just the join key.

**Cardinality:** minimum row count is `MAX(unmatched left rows, 0) + MAX(unmatched right rows, 0) + matched rows` — always greater than or equal to what either LEFT JOIN or RIGHT JOIN alone would return.

---

## Common Mistakes

**❌ Using `UNION ALL` instead of `UNION` in the MySQL workaround** — silently duplicates every matched row. This is easy to miss because the query still runs without error; it just returns a subtly wrong row count.

**❌ Reaching for FULL OUTER JOIN when a plain LEFT JOIN would answer the question** — if you only need "employees with no department," you're paying for a two-sided reconciliation you don't need. Match the join to the actual business question.

---

## Best Practices

- Reserve FULL OUTER JOIN for genuine two-sided reconciliation problems — data migration validation, source-vs-warehouse drift detection, cross-system comparisons.
- On MySQL, know the `UNION` workaround well enough to write it from memory — it's asked often enough in interviews that hesitating on it is a real signal.
- When reconciling two large datasets in MySQL, consider whether two separate, indexed anti-join queries (missing-on-left, missing-on-right — see `07_MULTI_TABLE_JOINS.md`) would be cheaper than the `UNION`-based FULL OUTER JOIN emulation, especially if you need the two directions reported separately anyway.

---

## Interview Questions

1. **"How do you write a FULL OUTER JOIN in MySQL?"** — see the [Vendor Notes](#vendor-notes--the-mysql-gap) section; this is asked constantly.
2. **"Why is `UNION`, not `UNION ALL`, required in the MySQL FULL OUTER JOIN emulation?"** — matched rows would otherwise be counted twice, once from each half of the union.
3. **"Write a query to find records that exist in table A but not table B, OR in table B but not table A, in a single result set."** — this is precisely what FULL OUTER JOIN + a `WHERE a.key IS NULL OR b.key IS NULL` filter accomplishes; a strong candidate volunteers this filter unprompted.

---

## Summary

FULL OUTER JOIN preserves unmatched rows from both sides at once — it's the join for two-sided reconciliation, not a "safer default" for everyday queries. Postgres, SQL Server, and Oracle support it natively; MySQL requires a `UNION` of a LEFT and RIGHT JOIN, a gap worth memorizing precisely because it's a favorite interview probe.

## Practice Challenges

1. Write the FULL OUTER JOIN of `employees` and `departments`, then filter it (in a second query) to show only the rows representing a genuine mismatch on either side — i.e., exclude the 9 matched rows.
2. Rewrite Q1 as the MySQL-compatible `UNION` emulation and confirm the row count matches the native version exactly.
3. Using `locations` and `departments`, write a FULL OUTER JOIN that would reveal both "a location with no departments" and "a department with no location" in one query, if either currently exists in the seed data.

## Further Reading

- [`02_LEFT_JOIN.md`](./02_LEFT_JOIN.md) · [`03_RIGHT_JOIN.md`](./03_RIGHT_JOIN.md) — the two joins FULL OUTER JOIN combines.
- [`07_MULTI_TABLE_JOINS.md`](./07_MULTI_TABLE_JOINS.md) — anti-join patterns as a lighter-weight alternative for one-directional gap detection.
