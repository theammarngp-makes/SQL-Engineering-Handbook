[← Module Home](./README.md)

# Lesson 01 — ACID & Transaction Fundamentals

`Module 17: Transactions & Concurrency Control · Lesson 1 of 7`

---

## 1. Introduction

A **transaction** is a unit of work — one or more SQL statements — that
the database treats as a single, indivisible operation. Either every
statement inside it succeeds and its effects become permanent, or none
of them do. This lesson establishes *why* that guarantee exists, what
it's built from, and how it looks in practice against this handbook's
shared `employes` / `departments` / `locations` schema.

Everything in Modules 17 and 18 that talks about isolation levels,
locking, deadlocks, or MVCC assumes you're solid on this lesson first —
those are all mechanisms *for* delivering ACID guarantees, not separate
topics.

## 2. Learning Objectives

By the end of this lesson you will be able to:

- State what each ACID letter guarantees, in your own words, without
  reciting the acronym
- Identify which guarantee is at risk in a given failure scenario
  (crash mid-write, two sessions writing at once, a constraint
  violation)
- Write a transaction using explicit `START TRANSACTION` /
  `COMMIT` / `ROLLBACK`, understanding what `autocommit` does when you
  don't
- Explain why "wrap it in a transaction" is not automatically the fix
  for every concurrency bug

## 3. Why This Exists

Without transactional guarantees, a multi-statement business operation
is only as safe as the least reliable thing between your application
and the disk: a network blip, a process crash, another session's
concurrent write, or a bug in your own code that stops halfway through.
Transactions exist so that "halfway through" is a state the database
never actually exposes to anyone — you get all of an operation's
effects, or none of them, never a partial version.

## 4. Business Motivation

Consider transferring a salary adjustment between two departments'
budgets — conceptually, `UPDATE departments SET ... WHERE dept_id = 4`
paired with a compensating `UPDATE` on `dept_id = 7`. If the first
`UPDATE` commits and the process crashes before the second runs, money
has vanished from the business's point of view: department 4 lost
budget that department 7 never received. No application-level retry
logic can undo that after the fact, because the database already
made half the change permanent. A transaction wrapping both statements
guarantees that either both happen or neither does — there is no
observable in-between state, crash or no crash.

The same shape shows up constantly: creating an order and its line
items, hiring an employee and inserting their initial department
assignment, processing a refund and adjusting an account balance. Any
time "this business operation" maps to "more than one SQL statement,"
you need a transaction boundary, or a crash/race turns a single
business event into a half-completed one.

## 5. The Four ACID Properties

### 5.1 Atomicity

**A transaction's changes are committed as a unit or rolled back as a unit.**
There is no partial commit of a transaction. Atomicity is about the
transaction's final outcome: on `COMMIT`, all of its changes become
permanent together; when it is rolled back — explicitly by you, or
automatically by the server in certain cases such as being chosen as a
deadlock victim or losing its connection — all of its changes are undone
together.

Atomicity does **not** mean that any statement error automatically rolls
back the whole transaction. In MySQL/InnoDB, when a single statement
fails (for example a constraint violation), by default only that
statement is rolled back; the transaction stays open and earlier
statements remain pending. Some errors — a deadlock, for instance — do
roll back the entire transaction. The application must check for errors
and decide whether to `ROLLBACK`, retry, or continue (see §11).

```sql
START TRANSACTION;

UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 99; -- affects 0 rows, no error

-- Both statements "succeeded" in the sense of not erroring.
-- Atomicity is about the transaction as a whole, not row-level partial success —
-- if you decide dept_id 99 not existing is actually a business-logic failure,
-- that's YOUR ROLLBACK to issue, MySQL won't infer it for you:
ROLLBACK;
```

Atomicity does not mean "MySQL detects your business logic is wrong."
It means: whatever you *do* decide to commit or roll back, that
decision applies to the whole transaction atomically. A statement that
silently updates 0 rows is not a MySQL bug — it's a reminder that
atomicity protects the boundary you draw, not the correctness of the
predicate inside it.

### 5.2 Consistency

**A transaction takes the database from one valid state to another
valid state**, where "valid" means every constraint, check, foreign
key, and trigger the schema defines is satisfied both before and after.
Consistency is enforced by the schema's own rules (`NOT NULL`, foreign
keys, `CHECK` constraints) plus whatever invariants your application
logic is responsible for — the database enforces the constraints it
knows about; it has no way to enforce a business rule that was never
expressed as a constraint.

```sql
-- This schema's employes table has manager_id referencing emp_id.
-- Consistency (via the FK constraint) blocks an impossible state:
START TRANSACTION;
INSERT INTO employes (emp_id, emp_name, dept_id, manager_id, hire_date, salary)
VALUES (999, 'Test Employee', 4, 88888, '2024-01-15', 50000.00);
-- ERROR 1452: Cannot add or update a child row: a foreign key constraint fails
-- manager_id 88888 does not exist in employes.emp_id
ROLLBACK;
```

The FK constraint is what makes this a *consistency* violation MySQL can actually catch. (This example assumes `00_Schema` declares a foreign key from `employes.manager_id` to `employes.emp_id`; confirm with `SHOW CREATE TABLE employes` — without that constraint MySQL would accept the row.) A business rule like "salary raises can't exceed
15% without VP approval" is just as real a consistency requirement,
but if it's never encoded as a `CHECK` constraint or trigger, MySQL has
no way to enforce it — that's on the application layer.

### 5.3 Isolation

**Concurrent transactions don't see each other's uncommitted changes**,
to a degree controlled by the isolation level (Lesson 02 covers this
in full). At minimum, two transactions running at the same time should
produce a result equivalent to *some* serial ordering of them — as if
one ran fully, then the other, even though they actually overlapped in
time.

```sql
-- Session A                              -- Session B
START TRANSACTION;                        
UPDATE employes SET salary = 75000.00     
  WHERE emp_id = 12;                      
-- not yet committed                      START TRANSACTION;
                                           SELECT salary FROM employes WHERE emp_id = 12;
                                           -- sees the OLD salary under MySQL's default
                                           -- REPEATABLE READ, not Session A's uncommitted 75000.00
COMMIT;
```

Isolation is the property with the most moving parts (isolation
levels, locks, MVCC), because "how much does one transaction get to
see of another's in-flight work" is a spectrum, not a single yes/no —
that spectrum is Lesson 02's entire subject.

### 5.4 Durability

**Once a transaction commits, its effects survive — even a database
crash immediately after.** MySQL/InnoDB achieves this by writing to a
redo log (and, with the default `innodb_flush_log_at_trx_commit = 1`, flushing it) as part of `COMMIT` itself (looser settings trade durability for speed); recovery replays
that log on restart to reconstruct any committed-but-not-yet-flushed-
to-datafile changes.

```sql
START TRANSACTION;
UPDATE employes SET salary = 82000.00 WHERE emp_id = 12;
COMMIT;
-- If the server process crashes one millisecond after this COMMIT
-- returns, the 82000.00 salary is still there after restart —
-- that guarantee is what "durable" means. It is not about how the
-- data is stored long-term; it's about surviving a crash the instant
-- after COMMIT.
```

## 6. Transaction Control Statements (MySQL)

```sql
-- Explicit transaction boundary
START TRANSACTION;   -- equivalently: BEGIN;
UPDATE ...;
INSERT ...;
COMMIT;               -- makes all changes permanent
-- or:
ROLLBACK;             -- discards all changes since START TRANSACTION

-- Partial rollback within a transaction
START TRANSACTION;
UPDATE employes SET salary = salary * 1.05 WHERE dept_id = 4;
SAVEPOINT before_bonus;
UPDATE employes SET salary = salary + 5000 WHERE emp_id = 12;
ROLLBACK TO SAVEPOINT before_bonus;  -- undoes only the bonus UPDATE,
                                       -- the 5% raise above is still pending
COMMIT;                               -- commits the raise, not the bonus
```

`SAVEPOINT` lets you undo part of a transaction without abandoning the
whole thing — useful when a transaction has an "optional" tail
operation that might need to be undone based on a check partway
through, without re-running everything before it.

## 7. Autocommit

MySQL runs with `autocommit = 1` (ON) by default. This matters more
than it looks:

```sql
SELECT @@autocommit;  -- 1 by default

-- With autocommit ON and NO explicit START TRANSACTION:
UPDATE employes SET salary = 90000.00 WHERE emp_id = 12;
-- This single statement IS its own transaction — it commits
-- immediately when it finishes, with no separate COMMIT needed.
```

Every individual statement is implicitly wrapped in its own
single-statement transaction and committed the instant it completes.
This is why a lone `UPDATE` with no `START TRANSACTION` still behaves
safely (atomic, durable) — it's just that its transaction boundary is
exactly one statement wide. The moment you need more than one
statement to succeed-or-fail together, autocommit's default behavior
is *not* what you want, and you must issue `START TRANSACTION`
explicitly to widen the boundary — otherwise each statement commits on
its own the instant it finishes, regardless of whether a later
statement in the same "logical" operation then fails.

```sql
-- WITHOUT an explicit transaction, this is TWO independent commits,
-- not one atomic operation, even though it looks like one block:
UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
-- ^ already committed here, permanently, under autocommit
UPDATE departments SET dept_name = 'Sales & Marketing Ops' WHERE dept_id = 999;
-- ^ this one affects 0 rows (dept_id 999 doesn't exist) — no error,
-- no rollback of the first UPDATE. If the intent was "both must
-- succeed as one unit," this code never expressed that boundary.
```

## 8. Engineering Notes

- Keep transactions **short**. A transaction holds locks (Lesson 03)
  for its entire duration — the longer it's open, the longer it
  blocks other sessions and the more it contributes to deadlock risk
  (Lesson 04).
- Never leave a transaction open across a network round-trip to an
  external system (an API call, a payment gateway, a message queue
  publish) if you can avoid it. If that external call is slow or
  hangs, every lock your transaction holds stays held for exactly as
  long. Lesson 06 covers this anti-pattern in depth.
- Application frameworks that auto-wrap requests in a transaction can
  make transaction boundaries invisible in your own code — know
  whether your framework does this, and where the boundary actually
  falls, before assuming a block of code is or isn't atomic.
- `DDL` statements (`CREATE TABLE`, `ALTER TABLE`, etc.) in MySQL
  cause an **implicit commit** of any open transaction before they
  run. You cannot roll back a `CREATE TABLE` by wrapping it in
  `START TRANSACTION` / `ROLLBACK` — MySQL commits whatever was
  pending first, then runs the DDL outside any transaction.

## 9. MySQL / PostgreSQL / SQL Server Notes

**MySQL (baseline for this handbook):**
- Default storage engine InnoDB supports full ACID transactions;
  `MyISAM` does not support transactions at all — `START TRANSACTION`
  against a MyISAM table is effectively a no-op for rollback purposes.
  Always confirm the engine with `SHOW TABLE STATUS` or
  `information_schema.TABLES` before assuming transactional behavior.
- `autocommit` defaults to `1` (ON), settable per-session:
  `SET autocommit = 0;`.
- DDL causes an implicit commit (see §8) — this differs from
  PostgreSQL, where most DDL *can* participate in a transaction.

**PostgreSQL (explicitly labeled where it differs):**
- Virtually all DDL, including `CREATE TABLE` and `ALTER TABLE`, **can**
  be rolled back inside a transaction — there is no implicit commit
  before DDL the way MySQL has one. This is a real behavioral
  difference, not a minor syntax variant.
- Uses `BEGIN;` (bare, no `TRANSACTION` keyword required) alongside
  `START TRANSACTION;` — both work.

**SQL Server:**
- Default is **autocommit-like** per statement similarly to MySQL, but
  SQL Server also supports `SET IMPLICIT_TRANSACTIONS ON`, which
  changes the default boundary behavior session-wide — worth knowing
  if you ever inherit code written against that setting.
- Uses `BEGIN TRANSACTION` / `COMMIT TRANSACTION` /
  `ROLLBACK TRANSACTION` (the `TRANSACTION` keyword is idiomatic here,
  unlike MySQL where it's often dropped to `BEGIN`).

## 10. Common Mistakes

1. **Assuming a "transaction" fixes a race condition it doesn't
   address.** Wrapping two statements in `START TRANSACTION` /
   `COMMIT` gives you atomicity and (depending on isolation level)
   some isolation guarantees — it does not, by itself, prevent a
   classic read-then-write race (two sessions both reading a balance,
   both computing a new value, both writing) unless you also take
   appropriate locks or rely on the isolation level correctly.
   Lessons 02–03 cover this.
2. **Forgetting that autocommit means every unwrapped statement is
   already its own transaction.** Developers sometimes reason "I
   didn't start a transaction, so nothing committed" — that's false
   under MySQL's default `autocommit = 1`.
3. **Leaving a transaction open indefinitely** (an idle session with
   `START TRANSACTION` issued and never `COMMIT`ted or `ROLLBACK`ed)
   — this holds any locks it acquired for as long as the session
   stays open, which can silently block other work for minutes or
   hours if nobody notices.
4. **Expecting `ROLLBACK` to undo a DDL statement** issued earlier in
   the same "block" of code, not realizing MySQL already implicitly
   committed everything before the DDL ran.

## 11. Edge Cases

- **A statement fails partway through a multi-row operation** (e.g., a
  `bulk UPDATE` where row 500 of 10,000 violates a constraint). By
  default, MySQL rolls back only that one statement, not the whole
  transaction — prior statements in the same transaction remain
  pending, uncommitted, and still rollback-able. The transaction
  itself is not automatically aborted unless you explicitly check
  for errors and issue `ROLLBACK`.
- **A deadlock occurs mid-transaction** (Lesson 04): MySQL
  automatically rolls back one of the two deadlocked transactions
  entirely — this is one of the few cases where MySQL rolls back a
  whole transaction on your behalf, specifically because deadlock
  recovery has no other option.
- **Connection drops mid-transaction** (network failure, client
  crash): an in-progress, uncommitted transaction is rolled back by
  the server once it detects the dropped connection. Nothing from
  that transaction persists.

## 12. Troubleshooting Guidance

- **"My changes disappeared" after what looked like a successful run**
  — check whether the session actually issued `COMMIT`, or whether
  the client library's connection pool silently rolled back an
  idle/dropped connection. `SHOW WARNINGS;` and checking
  `SELECT @@autocommit;` for the session in question are good first
  steps.
- **"A statement I thought would fail is silently doing nothing"** —
  remember that a `WHERE` clause matching 0 rows is not an error;
  atomicity guards the transaction boundary, not your predicate logic.
  Check `ROW_COUNT()` after the statement if you need to detect this.
- **A transaction seems "stuck"** — check
  `information_schema.INNODB_TRX` for open transactions and their
  age; a long-running, forgotten transaction is a common real-world
  cause of unexplained lock waits elsewhere in the system (Lesson 03).

## 13. Scalability Considerations

Transaction duration is the lever that matters most at scale. A
transaction that's fine at low concurrency (a few sessions, brief
locks) can become a serialization bottleneck once concurrent load
rises, because every lock it holds is now contended by more competing
sessions. This is illustrative reasoning, not a benchmark claim: the
practical implication is to design transaction boundaries around "the
minimum work that must be atomic," not "the maximum work I can
conveniently group together." A transaction that includes an
unrelated `SELECT` for logging purposes, or a slow external call, is
holding locks longer than the business requirement actually needs.

## 14. Additional Dialect Notes

**Oracle:** Has no `autocommit`-by-default behavior in most standard
client configurations (SQL*Plus defaults to manual commit) — this
trips up developers moving from MySQL, who expect every statement to
commit unless told otherwise.

**SQLite:** Every statement runs in an implicit transaction by
default, similar to MySQL's autocommit, but SQLite additionally
supports `BEGIN DEFERRED` / `BEGIN IMMEDIATE` / `BEGIN EXCLUSIVE` to
control *when* the write lock is actually acquired relative to when
the transaction starts — a concept MySQL doesn't expose the same way.

**DuckDB:** Primarily used in single-process analytical contexts;
supports transactions for consistency during multi-statement scripts,
but the concurrent-write scenarios this lesson focuses on (multiple
sessions racing) are not DuckDB's primary use case.

## 15. Interview Questions

1. **"What does atomicity guarantee, and what does it explicitly NOT
   guarantee?"** — Tests whether the candidate conflates atomicity
   with "my business logic is correct." (Atomicity guarantees
   all-or-nothing execution of what you wrote; it says nothing about
   whether what you wrote matches business intent.)
2. **"If autocommit is ON and I run three UPDATE statements back to
   back with no START TRANSACTION, and the third one fails, what
   happens to the first two?"** — Tests understanding that each
   statement already committed independently; the third statement's
   failure has zero effect on the already-committed first two.
3. **"Why can't ROLLBACK undo a CREATE TABLE that ran inside what
   looked like an open transaction in MySQL?"** — Tests awareness of
   MySQL's implicit-commit-before-DDL behavior, and that this differs
   from PostgreSQL.

## 16. Summary

ACID is four separate guarantees, not one blob: atomicity (all-or-
nothing), consistency (valid-state-to-valid-state, per the
constraints you've actually declared), isolation (concurrent
transactions don't corrupt each other's view, to a degree set by
isolation level), and durability (a commit survives a crash).
MySQL's `autocommit = 1` default means every unwrapped statement is
already its own tiny transaction — explicit `START TRANSACTION` /
`COMMIT` / `ROLLBACK` is how you widen that boundary to cover more
than one statement. None of this, on its own, solves concurrent-access
races — that's what Lessons 02 and 03 build on top of this foundation.

## 17. Practice Challenges

1. Write a transaction that increases every employee's salary in
   `dept_id = 4` by 10%, but only commits if the resulting average
   salary in that department stays under 95000.00 — otherwise it
   should roll back. (Hint: you'll need to check the result before
   deciding to `COMMIT` or `ROLLBACK`; no single statement does this
   check-and-decide for you.)
2. Using `SAVEPOINT`, write a transaction that gives every employee in
   `dept_id = 7` a 5% raise, then attempts an additional flat $2,000
   bonus only for employees hired before `2020-01-01` — but if the
   bonus step would push any single salary above 120000.00, roll back
   just the bonus step and keep the 5% raise.
3. Explain, without running any SQL, what happens to a `START
   TRANSACTION` that has one `UPDATE` pending, if the session runs an
   `ALTER TABLE` next. What is committed, and what is not?

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 18. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB and the ACID Model](https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html)
- MySQL 8.4 Reference Manual — [START TRANSACTION, COMMIT, and ROLLBACK Statements](https://dev.mysql.com/doc/refman/8.4/en/commit.html)
- PostgreSQL Documentation — [Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html) (for the cross-engine contrast in §9)

---

**Next:** [Lesson 02 — Isolation Levels & Read Phenomena](./02_ISOLATION_LEVELS_AND_READ_PHENOMENA.md)
