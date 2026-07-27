# FAQ — Module 01: Fundamentals

Questions that come up repeatedly while learning `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`, and `ALIAS` — collected here instead of repeated across topic files.

---

## Is SQL case-sensitive?

Keywords (`SELECT`, `WHERE`) are never case-sensitive in any major engine — `select` works identically to `SELECT`. This handbook uses uppercase keywords by convention (readability), not because lowercase would fail.

Unquoted **identifiers** (table/column names) are a different story: MySQL and SQL Server generally preserve but don't require exact case, PostgreSQL folds unquoted identifiers to lowercase, and Oracle folds them to uppercase. Quoted identifiers (`"Emp_Name"`, `` `Emp_Name` ``) preserve exact case everywhere. See each topic file's **Dialect Differences** section for specifics.

String *values* (`WHERE emp_name = 'ammar'` vs `'Ammar'`) are case-sensitive or not depending on the column's **collation** — a database setting, not a SQL-language rule.

---

## Why does my query return rows in a different order every time, even without changing the data?

Because you didn't include `ORDER BY`. SQL is not required to preserve insertion order, and query engines are free to return rows in whatever order is cheapest given the current execution plan — which can change between runs (index usage, caching, parallelism). If order matters at all, add `ORDER BY`. See [`03_ORDER_BY.md`](./03_ORDER_BY.md).

---

## What's the actual difference between `SELECT *` being "convenient" and being "wrong"?

It's never syntactically wrong. It's a maintainability and performance judgment call:

- **Fine**: ad-hoc exploration of a table you're unfamiliar with, one-off debugging queries you'll delete.
- **Risky in production code**: the query silently changes behavior if someone adds/drops/reorders a column later; it also transfers more data than the application actually uses.

See [`01_SELECT.md`](./01_SELECT.md) → Common Mistakes.

---

## Why can't I use a column alias in `WHERE`, but I *can* use it in `ORDER BY`?

Because of logical execution order: `WHERE` runs before `SELECT` creates the alias; `ORDER BY` runs after. This single rule explains a huge share of "why did my query error" questions once you internalize the execution order diagram in each topic file. See [`05_ALIAS.md`](./05_ALIAS.md).

---

## Do I need `ORDER BY` before I can use `LIMIT`?

Not syntactically — `LIMIT 5` alone is valid everywhere. But without `ORDER BY`, *which* 5 rows you get back is undefined, so `LIMIT` without `ORDER BY` should be treated as "give me some N rows," never "give me the top N" or "give me a specific page." See [`04_LIMIT.md`](./04_LIMIT.md).

---

## The datasets in this module only have 5 employee rows. Is that a bug?

No — it's intentional. The full canonical dataset (in [`00_Schema`](../00_Schema)) has 50 employees across 10 departments and 5 locations, which is useful once you're joining and aggregating, but adds noise while you're still learning what `WHERE` and `ORDER BY` individually do. This module uses a small, deliberately simplified subset so you can eyeball the entire result set by reading the table. See the note in [`README.md`](./README.md) → Datasets Used in This Module for exactly how the two relate.

---

## Will the SQL I write in this module actually run on any database?

Everything except `LIMIT`/`OFFSET` syntax is portable across MySQL, PostgreSQL, SQL Server, and Oracle as written. `LIMIT` itself is **not** ANSI-standard and has a different keyword on SQL Server (`TOP` / `OFFSET...FETCH`) and Oracle (`ROWNUM` / `FETCH FIRST`). Every topic file's **Dialect Differences** table shows the equivalent syntax per engine.

---

## Related

- [`GLOSSARY.md`](./GLOSSARY.md) — term definitions
- [`INTERVIEW_PREP.md`](./INTERVIEW_PREP.md) — consolidated interview question bank
- [`README.md`](./README.md) — module overview
