[← Level 3](../04_ADVANCED_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Level 4 (of 0–9)

# Level 4 — Database Engineering

Pilot set: 8 of ~70 target questions. Heavily cross-references [`16_QUERY_OPTIMIZATION`](../../16_QUERY_OPTIMIZATION) and [`17_TRANSACTIONS_AND_CONCURRENCY`](../../17_TRANSACTIONS_AND_CONCURRENCY) — this level tests *application*, not re-teaching.

---

## Q017 — SARGability Diagnosis

**Difficulty:** 🟠 Advanced
**Category:** Indexing
**Type:** C — Debug SQL
**Related Modules:** [`16_QUERY_OPTIMIZATION` Lesson 03](../../16_QUERY_OPTIMIZATION/03_SARGABILITY_AND_INDEX_USAGE.md)

### Problem
`hire_date` is indexed. This still runs a full table scan:
```sql
SELECT emp_name FROM employes WHERE YEAR(hire_date) = 2023;
```

### Explanation
Wrapping the indexed column in `YEAR()` prevents the standard B-tree
index on `hire_date` from being used for a seek — the optimizer can't
map a per-row function result back to the index's sorted order, so it
falls back to a full scan on a plain (non-expression) index. This isn't
an absolute law of SQL, though: with a matching expression/functional
index on `YEAR(hire_date)` (supported in MySQL 8.0.13+ and PostgreSQL),
the optimizer could use *that* index instead — which is exactly what
the follow-up below gets at.

### Fix
```sql
SELECT emp_name FROM employes
WHERE hire_date >= '2023-01-01' AND hire_date < '2024-01-01';
```

### Interviewer Follow-Up
"If the app genuinely needs YEAR() filtering constantly, what are two schema/index-level fixes, not just query-level?" (Expression index on YEAR(hire_date), or a generated/computed indexed column.)

---

## Q018 — Reading an Execution Plan

**Difficulty:** 🔴 Expert
**Category:** EXPLAIN
**Type:** H — Execution Plan
**Related Modules:** [`16_QUERY_OPTIMIZATION` Lesson 02](../../16_QUERY_OPTIMIZATION/02_EXPLAIN_AND_EXECUTION_PLANS.md)

### Problem
This is a **PostgreSQL** `EXPLAIN ANALYZE` example — `Seq Scan` is
PostgreSQL-specific plan terminology, not part of MySQL's `EXPLAIN`
output. It shows `Seq Scan on employes estimated rows=400,000 actual
rows=3` inside a fast-running query. Is this a problem?

*(MySQL equivalent: the same stale-statistics symptom shows as a large
`rows` estimate in a standard `EXPLAIN` with `type: ALL`, versus a tiny
actual row count from `EXPLAIN ANALYZE` — supported since MySQL 8.0.18
— or `SHOW STATUS LIKE 'Handler_read%'` counters after running the
query.)*

### Expected Answer
Yes, worth investigating even though currently fast: the huge estimate/actual gap indicates badly stale statistics. It happens to run fast here (3 rows is trivial regardless of scan method), but the optimizer's decisions for THIS and OTHER queries against this table are based on wrong information.

### Interviewer Follow-Up
"What would you check and run to fix the underlying issue, not just this instance?"

### Senior-Level Extension
"How do you decide if this is urgent if the query is already fast?" (Tests judgment: risk is other queries and future data growth, not this instance.)

---

## Q019 — Composite Index Column Order

**Difficulty:** 🟠 Advanced
**Category:** Indexing
**Type:** I — Design
**Related Modules:** [`16_QUERY_OPTIMIZATION` Lesson 03](../../16_QUERY_OPTIMIZATION/03_SARGABILITY_AND_INDEX_USAGE.md)

### Problem
Design the composite index best serving:
```sql
SELECT emp_name FROM employes
WHERE dept_id = 4 AND hire_date > '2023-01-01' ORDER BY hire_date;
```

### Expected Answer
```sql
CREATE INDEX idx_employes_dept_hiredate ON employes (dept_id, hire_date);
```
`dept_id` leads (equality filter, most selective leading access); `hire_date` follows since it's both a range filter and the ORDER BY column, letting the index satisfy the sort too.

### Interviewer Follow-Up
"If a second, equally frequent query filters ONLY by hire_date, does this same index serve it well?"

---

## Q020 — Lost Update Diagnosis

**Difficulty:** 🔴 Expert
**Category:** Transactions, Concurrency
**Type:** J — Production Incident
**Related Modules:** [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 02](../../17_TRANSACTIONS_AND_CONCURRENCY/02_ISOLATION_LEVELS_AND_READ_PHENOMENA.md)

### Scenario
An app reads a salary, computes a raise in code, writes it back with a plain UPDATE. Under load, some raises are "not applied" despite success logs.

### Expected Answer
Classic **lost update**: two concurrent requests read the same starting salary, each write their own computed value; whichever UPDATE commits second silently overwrites the first — no error, since both UPDATEs individually succeeded.

### Fix
Atomic `UPDATE ... SET salary = salary + :raise_amount` where possible, or `SELECT ... FOR UPDATE` when logic can't be a single atomic statement.

### Interviewer Follow-Up
"How would you reproduce this in a test environment before shipping a fix?"

### Senior-Level Extension
"What isolation level would have prevented this without an app code change? What would that cost?"

---

## Q021 — Deadlock from Reversed Lock Order

**Difficulty:** ⚫ Staff/Production
**Category:** Transactions, Deadlocks
**Type:** J — Production Incident
**Related Modules:** [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 04](../../17_TRANSACTIONS_AND_CONCURRENCY/04_DEADLOCKS.md)

### Scenario
A payroll batch job and an HR self-service endpoint occasionally deadlock, always involving exactly two specific employee rows.

### Expected Answer
The batch job likely updates multiple rows in one order (e.g. by department); the self-service endpoint updates a single row by whatever emp_id the user has. When both touch the same two rows in different acquisition orders concurrently, a deadlock cycle forms. Permanent fix: enforce consistent lock acquisition order (e.g. ascending primary key) across BOTH code paths — not just retry logic, which treats the symptom.

### Interviewer Follow-Up
"Why does this only involve two SPECIFIC rows rather than being random?"

---

## Q067 — Covering Index Concept

**Difficulty:** 🟠 Advanced
**Category:** Indexing
**Type:** F — Compare Approaches
**Related Modules:** [`15_INDEXES`](../../15_INDEXES)

### Problem
A query `SELECT emp_name, salary FROM employes WHERE dept_id = 4;` runs
fast with an index on `dept_id` alone, but still shows a lookup step
back to the table in `EXPLAIN`. What index change removes that lookup
entirely?

### Explanation
An index on `dept_id` alone lets the engine seek matching rows quickly,
but it still must go back to the heap/clustered table to fetch
`emp_name` and `salary`, since those columns aren't in the index. A
**covering index** — `(dept_id, emp_name, salary)`, or `dept_id` with
`emp_name, salary` as included columns where the engine supports it —
lets the entire query answer from the index alone, skipping the
table lookup ("index-only scan").

### Interviewer Follow-Up
"What's the tradeoff of adding more columns to an index to make it
cover more queries?"

---

## Q068 — Index Selectivity and Cardinality

**Difficulty:** 🟠 Advanced
**Category:** Indexing, Query Planning
**Type:** F — Compare Approaches

### Problem
An index exists on `departments.dept_name` (10 distinct values across
50-ish rows) and one on `employes.emp_id` (unique, primary key). Why
would the optimizer readily use the second index but often ignore the
first?

### Explanation
Selectivity is what fraction of rows a condition filters out.
`emp_id = X` is maximally selective — exactly one row, so index seek is
always cheaper than a scan. `dept_name = X` against only ~10 distinct
values across the table means each value matches roughly 1/10 of all
rows; past a certain selectivity threshold, the optimizer decides a
full table scan (sequential I/O) is actually cheaper than the random
I/O of many index lookups, and skips the index entirely even though it
exists.

### Interviewer Follow-Up
"If this table had 5 million rows instead of ~50, would the optimizer's
decision about the `dept_name` index change? Why?"

---

## Q069 — Isolation Level and a Non-Repeatable Read

**Difficulty:** 🟠 Advanced
**Category:** Transactions, Isolation
**Type:** B — Predict Output
**Related Modules:** [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 02](../../17_TRANSACTIONS_AND_CONCURRENCY/02_ISOLATION_LEVELS_AND_READ_PHENOMENA.md)

### Problem
Transaction A reads `salary` for `emp_id = 12` under
`READ COMMITTED`. Before A commits, Transaction B updates and commits
that same row's `salary`. A then re-reads the same row in the same
transaction. What does A see, and would `REPEATABLE READ` change that?

### Explanation
Under `READ COMMITTED`, A's second read sees B's committed change — a
**non-repeatable read**, since the same row returned two different
values within one transaction. Under `REPEATABLE READ`, A's snapshot is
fixed at (engine-dependent) either transaction start or first read, so
the second read returns the original value regardless of B's commit —
at the cost of A potentially working against increasingly stale data
for the rest of its transaction.

### Interviewer Follow-Up
"Which isolation level would you pick for a report that reads the same
aggregate multiple times and needs internal consistency across those
reads — and what's the cost of that choice?"

---

[← Level 3](../04_ADVANCED_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 5 — Real-World SQL](../06_REAL_WORLD_SQL/QUESTION_BANK.md)
