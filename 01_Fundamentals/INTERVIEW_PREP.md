# Interview Prep — Module 01: Fundamentals

A consolidated review sheet pulling the **Interview Tip** from every topic file into one place, plus the follow-ups an interviewer is likely to ask next. Use this the night before an interview instead of re-reading all five files.

---

## 1. "Why can't I use a `SELECT` alias in `WHERE`?"

**Source topic:** [`01_SELECT.md`](./01_SELECT.md), [`05_ALIAS.md`](./05_ALIAS.md)

**Answer:** Logical execution order runs `WHERE` before `SELECT`. The alias doesn't exist yet when `WHERE` is evaluated, because `SELECT` — the clause that creates it — hasn't run.

**Likely follow-up:** *"So why does it work in `ORDER BY`?"* — Because `ORDER BY` runs after `SELECT` in the logical order, the alias already exists by the time `ORDER BY` evaluates it.

---

## 2. "Write a query for the 2nd highest salary."

**Source topic:** [`04_LIMIT.md`](./04_LIMIT.md)

**Answer:** The instinctive `ORDER BY salary DESC LIMIT 1 OFFSET 1` is a reasonable first answer, but flag its weakness unprompted: it silently breaks on ties. If two employees share the highest salary, `OFFSET 1` skips a *row*, not a *distinct value*, so the "2nd highest" returned is actually the 3rd row, not the 2nd distinct salary.

**Stronger answer:** Use `DENSE_RANK()` (covered in the window functions module) to rank by distinct value, then filter `WHERE rnk = 2`. Naming this trade-off unprompted is what separates a syntax-level answer from an engineering-level one.

---

## 3. `WHERE` vs `HAVING`

**Source topic:** [`02_WHERE.md`](./02_WHERE.md)

| WHERE | HAVING |
|---|---|
| Filters rows | Filters groups |
| Runs before `GROUP BY` | Runs after `GROUP BY` |
| Cannot use aggregate functions | Can use aggregate functions |

**Memory hook:** WHERE → rows. HAVING → groups.

---

## 4. `= NULL` vs `IS NULL`

**Source topic:** [`02_WHERE.md`](./02_WHERE.md)

**Answer:** `NULL` represents an unknown/absent value, not a comparable value. `column = NULL` doesn't error — it evaluates to `UNKNOWN` for every row, which is treated as "not a match," so the query silently returns zero rows even where `column` genuinely is `NULL`. `IS NULL` is a dedicated test built for this case.

**Likely follow-up:** *"What does `NOT IN` return if the list contains a `NULL`?"* — The whole `NOT IN` predicate evaluates to `UNKNOWN` for every row once any list member is `NULL`, so the query returns zero rows even for values that are clearly not in the list. This is a well-known SQL trap; prefer `NOT EXISTS` when a subquery result might contain `NULL`.

---

## 5. Why is `LIMIT` without `ORDER BY` considered non-deterministic?

**Source topic:** [`04_LIMIT.md`](./04_LIMIT.md)

**Answer:** Without an explicit sort, the engine is free to return rows in whatever order its execution plan finds cheapest — which can change between runs based on indexes, caching, or parallel execution, even if the underlying data hasn't changed. "First 3 rows" is only meaningful once "first" is defined by a sort.

---

## 6. Is `LIMIT` part of the ANSI SQL standard?

**Source topic:** [`04_LIMIT.md`](./04_LIMIT.md)

**Answer:** No. `LIMIT` is a MySQL/PostgreSQL extension. The ANSI-standard, portable equivalent is `OFFSET n ROWS FETCH FIRST m ROWS ONLY`, which SQL Server and Oracle also support. SQL Server additionally has the non-standard `TOP`, and legacy Oracle code often uses `ROWNUM` instead of `FETCH FIRST`. Knowing this distinction signals you've written SQL against more than one engine.

---

## 7. Does `ORDER BY` put `NULL`s first or last?

**Source topic:** [`03_ORDER_BY.md`](./03_ORDER_BY.md)

**Answer:** It's engine-dependent, which is exactly why this is a good interview question. PostgreSQL and Oracle default to `NULL`s **last** in ascending order; MySQL and SQL Server default to `NULL`s **first**. `NULLS FIRST` / `NULLS LAST` (PostgreSQL, Oracle) makes the behavior explicit and portable-by-intent; MySQL/SQL Server need a `CASE`-based workaround to force the other order.

---

## Rapid-Fire Round

Quick answers you should be able to give in one sentence each:

1. **What's the difference between `WHERE dept_id <> 1` and `WHERE dept_id != 1`?** — None functionally in most engines; `<>` is the ANSI-standard operator, `!=` is a widely supported alias.
2. **Is `AS` required when aliasing?** — No, in every major dialect it's optional for column aliases; this handbook always includes it for readability.
3. **What does `SELECT DISTINCT` have to do with this module?** — Nothing directly — it's a separate topic (deduplication), commonly confused with `WHERE` because both "narrow" a result set, but by different mechanisms (filtering rows vs. collapsing duplicate rows).
4. **Can `LIMIT` return more rows than exist in the table?** — No, it silently returns however many rows are actually available, even if fewer than the requested limit.
5. **Can two columns be aliased to the same name in one `SELECT`?** — Syntactically yes in most engines, but the output becomes ambiguous to reference — avoid it.

---

## Related

- [`GLOSSARY.md`](./GLOSSARY.md) — term definitions
- [`FAQ.md`](./FAQ.md) — recurring learner questions
- [`README.md`](./README.md) — module overview
