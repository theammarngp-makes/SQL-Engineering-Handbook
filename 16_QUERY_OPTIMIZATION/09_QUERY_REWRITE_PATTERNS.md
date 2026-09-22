# Query Rewrite Patterns

## Introduction

This lesson is a pattern catalog: eight recurring "bad shape → better
shape" rewrites, each with the reasoning for *why* the optimizer prefers
the rewrite — not just the rewrite itself. Memorizing the pattern without
the reasoning makes you someone who follows rules; understanding the
reasoning makes you someone who can invent the ninth pattern when you hit
one this list doesn't cover.

## Learning Objectives

- Apply eight standard query rewrite patterns correctly
- Explain, for each pattern, *why* the rewritten form is cheaper — not just
  that it is
- Recognize when a pattern does **not** apply (rewrites are not universal
  laws)

## Why This Exists

Lessons 03–06 introduced these rewrites individually, scattered across
their relevant topics. This lesson collects them in one place, in a
consistent before/after/why format, so they function as a fast reference
during code review or live query tuning.

---

## Pattern 1: OR → UNION ALL

```sql
-- BEFORE
SELECT emp_name FROM employes
WHERE dept_id = 4 OR hire_date > '2023-01-01';

-- AFTER
SELECT emp_name FROM employes WHERE dept_id = 4
UNION ALL
SELECT emp_name FROM employes WHERE hire_date > '2023-01-01'
  AND (dept_id <> 4 OR dept_id IS NULL);  -- exclude branch 1's rows, NULLs included
```

**Why the optimizer prefers this:** a single composite index generally
can't serve an `OR` across unrelated columns efficiently — the engine often
falls back to a full scan to evaluate the whole condition. Splitting into
`UNION ALL` lets each half use its own independent index, then combines
results. Note the explicit exclusion guard (`AND (dept_id <> 4 OR dept_id
IS NULL)`) — `UNION ALL` doesn't deduplicate, so without it, rows matching
both conditions appear twice; use plain `UNION` instead if you want
deduplication and don't mind its extra sort/hash cost. This is not a
universal law: `OR` can be rewritten as `UNION ALL` only when the branches
are made mutually exclusive and the exclusion guard is NULL-safe. A plain
`dept_id <> 4` guard is **wrong** here — if `dept_id IS NULL`, that
comparison evaluates to `UNKNOWN` (false in `WHERE`), which would silently
drop rows the original `OR` correctly included via the `hire_date`
condition. Always validate the rewrite (NULL behavior, branch overlap,
duplicate rows) against the original query before adopting it.

---

## Pattern 2: DISTINCT → GROUP BY (or eliminate entirely)

```sql
-- BEFORE
SELECT DISTINCT d.dept_name
FROM departments d
JOIN employes e ON e.dept_id = d.dept_id;

-- AFTER (if you don't need employee-level detail at all)
SELECT d.dept_name
FROM departments d
WHERE EXISTS (SELECT 1 FROM employes e WHERE e.dept_id = d.dept_id);
```

**Why the optimizer prefers this:** `DISTINCT` is usually masking a
join-fan-out problem rather than solving one — it computes the full,
duplicated result set, then sorts/hashes to remove duplicates after the
fact. `EXISTS` never produces the duplicates in the first place, so
there's nothing to deduplicate. Where you genuinely need grouped
aggregates (not just existence), `GROUP BY` is the correct tool, and most
optimizers cost it similarly to `DISTINCT` — the real fix in both cases is
asking "do I need this join at all for what I'm actually computing?"

---

## Pattern 3: IN → EXISTS (and NOT IN → NOT EXISTS)

```sql
-- BEFORE
SELECT dept_name FROM departments d
WHERE d.dept_id IN (SELECT dept_id FROM employes WHERE hire_date > '2023-01-01');

-- AFTER
SELECT dept_name FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employes e
    WHERE e.dept_id = d.dept_id AND e.hire_date > '2023-01-01'
);
```

**Why the optimizer prefers this:** `EXISTS` can short-circuit — it stops
scanning as soon as one match is found per outer row — while `IN`
conceptually needs the full subquery result materialized to check
membership against (though modern optimizers often rewrite `IN` into an
equivalent semi-join automatically). The much stronger reason to prefer
the `EXISTS`/`NOT EXISTS` family: `NOT IN` is **unsafe**, not just
slower — see Lesson 05's `NULL` trap. Prefer `EXISTS`/`NOT EXISTS` by
default, and treat any performance difference as a secondary benefit.

---

## Pattern 4: Correlated Subquery → JOIN or Window Function

```sql
-- BEFORE
SELECT e.emp_name,
    (SELECT COUNT(*) FROM employes e2
     WHERE e2.dept_id = e.dept_id AND e2.hire_date <= e.hire_date) AS hire_rank
FROM employes e;

-- AFTER
SELECT e.emp_name,
    RANK() OVER (PARTITION BY e.dept_id ORDER BY e.hire_date) AS hire_rank
FROM employes e;
```

**Why the optimizer prefers this:** a correlated subquery conceptually
re-evaluates once per outer row; a window function computes the same
per-group result in a single pass (sort once, aggregate once). Not every
correlated subquery has a window-function equivalent — but per-group
ranks, running totals, and "compare to peers" problems almost always do.

---

## Pattern 5: SELECT * → Explicit Projection

```sql
-- BEFORE
SELECT * FROM employes WHERE dept_id = 4;

-- AFTER
SELECT emp_id, emp_name, hire_date FROM employes WHERE dept_id = 4;
```

**Why the optimizer prefers this:** explicit projection is the only way a
covering index (Lesson 03) can actually cover the query — `SELECT *`
guarantees the engine needs every column, defeating any index that doesn't
include all of them. It also reduces network transfer and insulates the
query from schema changes silently altering its output shape.

---

## Pattern 6: Leading Wildcard LIKE → Prefix Search (or Full-Text/Trigram Index)

```sql
-- BEFORE
SELECT emp_name FROM employes WHERE emp_name LIKE '%mmar';

-- AFTER (if prefix search satisfies the business need)
SELECT emp_name FROM employes WHERE emp_name LIKE 'Ammar%';

-- AFTER (if genuine substring search is required)
-- CREATE INDEX idx_employes_name_trgm ON employes USING GIN (emp_name gin_trgm_ops);
```

**Why the optimizer prefers this:** a standard B-tree index is ordered,
so it can jump to a prefix match directly, but can't do the same for a
suffix/substring match — the engine has no ordering to exploit, so it
scans everything. If substring search is a genuine requirement, the fix
isn't rewriting the query — it's a different index type (trigram/full-text)
built for that access pattern.

---

## Pattern 7: Large OFFSET → Keyset (Cursor) Pagination

```sql
-- BEFORE
SELECT emp_id, emp_name FROM employes
ORDER BY emp_id LIMIT 20 OFFSET 100000;

-- AFTER
SELECT emp_id, emp_name FROM employes
WHERE emp_id > 100000  -- last emp_id seen on the previous page
ORDER BY emp_id LIMIT 20;
```

**Why the optimizer prefers this:** `OFFSET` still requires the engine to
generate (or at least count through) every skipped row before it can
start returning results — cost grows with page depth. A keyset predicate
is a direct, indexed range lookup — cost stays flat regardless of "page
number," because there's no concept of skipping, only "start after this
key."

---

## Pattern 8: Functions in WHERE → Bare Column + Rewritten Constant

```sql
-- BEFORE
SELECT emp_name FROM employes WHERE YEAR(hire_date) = 2023;

-- AFTER
SELECT emp_name FROM employes
WHERE hire_date >= '2023-01-01' AND hire_date < '2024-01-01';
```

**Why the optimizer prefers this:** this is SARGability (Lesson 03) in its
most common form — wrapping the column in a function forces per-row
evaluation, moving the transformation to the constant side keeps the
column bare and index-usable.

---

## When These Patterns Don't Apply

Every pattern here assumes the rewrite is *logically equivalent* to the
original — verify that before applying one under time pressure:

- `UNION` vs `UNION ALL` changes result semantics (dedup vs not) — Pattern
  1's rewrite must handle overlap explicitly, as shown.
- `DISTINCT` → `EXISTS` (Pattern 2) is only valid if you don't actually
  need columns from the many-side of the join in your result.
- A correlated subquery → window function rewrite (Pattern 4) only applies
  to per-group aggregate/ranking problems — not every correlated subquery
  fits this shape.

## Common Mistakes

- Applying a rewrite pattern by memory without confirming it preserves the
  original query's exact semantics
- Assuming a pattern from this list is *always* faster without confirming
  with `EXPLAIN` against your actual engine and data — see Lesson 08 on
  the risk of trusting rules of thumb over measurement

## Interview Questions

- "Walk me through the OR-to-UNION-ALL rewrite and explain exactly why it
  helps."
- "When would a correlated-subquery-to-window-function rewrite NOT apply?"

## Summary

These eight patterns cover the large majority of "obviously improvable"
queries you'll encounter in code review. The pattern is a starting
hypothesis, not a guarantee — confirm every rewrite preserves the original
result and actually improves the plan via `EXPLAIN`, per the workflow in
Lesson 07.

## Practice Challenges

1. Take a query from your own past work using one of these eight
   "before" shapes and apply the matching rewrite.
2. Construct a case where the DISTINCT → EXISTS rewrite (Pattern 2) is
   **not** valid, and explain why.

## Further Reading

- Use-the-index-luke.com — pattern-by-pattern rewrite guidance
- See also: Lessons 03, 04, 05, and 06, which introduced these patterns
  individually in their original context
