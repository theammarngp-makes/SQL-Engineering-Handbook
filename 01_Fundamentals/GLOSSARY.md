# Glossary — Module 01: Fundamentals

> Terms used throughout this module's `.md` files, defined once here instead of repeated inline. Linked from every topic file.

| Term | Definition |
|---|---|
| **Clause** | A distinct part of a SQL statement, each starting with a keyword — `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `LIMIT` are all clauses. |
| **Predicate** | A condition that evaluates to `TRUE`, `FALSE`, or `UNKNOWN` for a given row — e.g. `dept_id = 2` in a `WHERE` clause. `UNKNOWN` (not just `TRUE`/`FALSE`) is why `NULL` comparisons behave the way they do; see [`02_WHERE.md`](./02_WHERE.md). |
| **Projection** | The relational-algebra term for choosing which *columns* appear in a result — what `SELECT` does. Filtering rows (`WHERE`) is a separate operation called *selection*, which is a common source of terminology confusion since SQL's `SELECT` keyword actually performs projection, not selection. |
| **Logical execution order** | The fixed sequence in which SQL clauses are conceptually evaluated (`FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`), which is different from the order they're *written* in. Real engines may reorder physical execution for performance, but must produce a result consistent with this logical order. |
| **Deterministic** | A query is deterministic if it returns the same rows in the same order every time it runs against unchanged data. `LIMIT`/`TOP` without `ORDER BY` is a classic non-deterministic pattern — see [`04_LIMIT.md`](./04_LIMIT.md). |
| **Alias** | A temporary name assigned to a column or table for the duration of one query, using `AS` (optional in most dialects). See [`05_ALIAS.md`](./05_ALIAS.md). |
| **Identifier** | The name of a database object — a table, column, or alias. Identifiers may need quoting if they contain spaces, match a reserved keyword, or need to preserve case. |
| **Collation** | The rule set a database uses to compare and sort text (case sensitivity, accent sensitivity, locale-specific ordering). Two engines can sort the same text differently depending on collation, which is why `ORDER BY` on text columns isn't always portable across databases. |
| **Pagination** | Returning results in fixed-size pages using `LIMIT`/`OFFSET` (or engine-specific equivalents) rather than the whole result set at once — the backbone of "page 2 of 10" UI patterns. |
| **Dialect** | The specific variant of SQL implemented by a given database engine (MySQL, PostgreSQL, SQL Server, Oracle). All are close to the ANSI SQL standard but diverge in specific clauses — `LIMIT` is the most divergent clause covered in this module. |
| **ANSI SQL** | The SQL standard maintained by ANSI/ISO. No commercial engine implements 100% of it or avoids extensions beyond it; "ANSI-standard" in this handbook means "works unmodified on every major engine," which `FETCH FIRST ... ROWS ONLY` satisfies but plain `LIMIT` does not. |
| **Result set** | The rows and columns returned by a query — not a physical table, and not stored anywhere unless you explicitly materialize it (e.g. `CREATE TABLE AS`). |

---

## Related

- [`FAQ.md`](./FAQ.md) — recurring learner questions
- [`INTERVIEW_PREP.md`](./INTERVIEW_PREP.md) — consolidated interview question bank for this module
- [`README.md`](./README.md) — module overview
