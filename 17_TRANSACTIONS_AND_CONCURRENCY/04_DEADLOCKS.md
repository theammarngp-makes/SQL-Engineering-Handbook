[← Module Home](./README.md)

# Lesson 04 — Deadlocks

`Module 17: Transactions & Concurrency Control · Lesson 4 of 7`

---

## 1. Introduction

A deadlock is two (or more) transactions each holding a lock the other
needs, with neither able to proceed. Locking (Lesson 03) makes
deadlocks *possible*; this lesson covers how they happen, how MySQL
resolves them automatically, and — more importantly — how to design
around them so they're rare rather than routine.

## 2. Learning Objectives

- Explain the cyclic-wait condition that defines a deadlock
- Read MySQL's `SHOW ENGINE INNODB STATUS` deadlock report
- State MySQL's automatic deadlock resolution behavior
- Apply the primary engineering practice that prevents most deadlocks:
  consistent lock ordering

## 3. Why This Exists

Locking exists to make concurrent writes safe (Lesson 03), but
locking two or more resources across multiple statements creates a new
risk: if two transactions each need both resources but acquire them
in opposite order, they can each end up holding one and waiting for
the other — permanently, without intervention. A database must detect
this and break the cycle, because neither transaction will ever
release its lock on its own.

## 4. Business Motivation

A "transfer budget between departments" operation that locks the
source department row, then the destination department row, will
deadlock against a *second* transfer running in the opposite direction
(source and destination swapped) if both transactions started at
roughly the same time and each grabbed its first lock before either
could grab its second. This isn't a rare edge case in any system with
symmetric operations between two resources — it's a predictable
consequence of not imposing a consistent lock order.

## 5. The Deadlock Scenario

```sql
-- Session A                                    -- Session B
START TRANSACTION;                              START TRANSACTION;
UPDATE departments SET dept_name = 'A1'         UPDATE departments SET dept_name = 'B1'
  WHERE dept_id = 4;   -- locks dept_id=4          WHERE dept_id = 7;   -- locks dept_id=7
                                                 
UPDATE departments SET dept_name = 'A2'         UPDATE departments SET dept_name = 'B2'
  WHERE dept_id = 7;   -- BLOCKS, waiting          WHERE dept_id = 4;   -- BLOCKS, waiting
  -- (Session B holds this lock)                   -- (Session A holds this lock)

-- Neither can proceed: A waits for the lock B holds on dept_id=7,
-- B waits for the lock A holds on dept_id=4. This is the cycle.
-- MySQL's deadlock detector identifies this and kills ONE of the
-- two transactions automatically (typically the one with less
-- rollback work), returning:
-- ERROR 1213 (40001): Deadlock found when trying to get lock;
-- try restarting transaction
```

The survivor's transaction proceeds normally once the victim rolls
back and releases its locks. The victim's application code must catch
this error and decide whether to retry.

## 6. Reading the Deadlock Report

```sql
SHOW ENGINE INNODB STATUS\G
```

Look at the `LATEST DETECTED DEADLOCK` section: it lists each
transaction involved, the statement it was running, the lock(s) it
held, and the lock it was waiting for — reading these two transaction
blocks side by side directly shows you the cycle (what each held vs.
what each wanted), which is the fastest way to identify exactly which
two resources need lock-order discipline.

## 7. Engineering Notes

- **Acquire locks in a consistent order across every code path.** If
  any operation ever needs to lock both a department row and an
  employee row, always lock departments before employes (or always
  the reverse) — pick one order and enforce it everywhere. This single
  practice prevents the overwhelming majority of real-world deadlocks.
- **Keep transactions short** (Lesson 01, §8) — the longer a
  transaction holds its first lock before requesting its second, the
  wider the window for another transaction to grab the second lock
  first and create a cycle.
- **Always implement retry logic for deadlock victims.** A deadlock
  error is not "your query is wrong" — it's an expected, occasional
  outcome of concurrent access that the application layer must be
  prepared to retry (typically with a brief backoff), not surface as
  an unhandled failure.
- Access rows in the **same order** a natural key or index would sort
  them, where feasible (e.g., always process `emp_id` values in
  ascending order within a multi-row operation) — this is a specific
  case of "consistent lock ordering."

## 8. MySQL / PostgreSQL / SQL Server Notes

**MySQL:** Detects deadlocks quickly (in normal operation, near-
immediately upon the cyclic wait forming) via InnoDB's built-in
deadlock detector, and automatically rolls back one transaction —
typically the one InnoDB estimates has done less work, to minimize
rollback cost. No configuration is required for basic detection;
`innodb_deadlock_detect` can be disabled in very high-concurrency
setups where the detector itself becomes a bottleneck, at the cost of
then relying purely on lock wait timeout instead.

**PostgreSQL:** Also detects deadlocks automatically and aborts one
transaction with a `deadlock_detected` error, conceptually similar,
though implementation details (detection interval configurable via
`deadlock_timeout`) differ from MySQL's near-immediate detection.

**SQL Server:** Also has automatic deadlock detection, and additionally
lets you set `DEADLOCK_PRIORITY` per session to influence which
transaction SQL Server chooses as the victim — a level of control
MySQL doesn't expose the same way.

## 9. Common Mistakes

1. **Treating every deadlock as a bug to eliminate entirely.** In a
   system with real concurrent access to shared resources, occasional
   deadlocks are expected, not a sign something is fundamentally
   broken — the goal is minimizing frequency (via lock ordering,
   short transactions) and handling them gracefully (via retry), not
   assuming zero deadlocks is achievable or even meaningful as a goal.
2. **No retry logic on deadlock errors** — letting `ERROR 1213`
   surface as an unhandled application error instead of catching it
   and retrying the transaction.
3. **Inconsistent lock ordering across different features/code paths**
   that happen to touch the same two tables — this is usually not
   visible from reading any single code path in isolation; it only
   shows up when you compare lock-acquisition order across *all* paths
   that touch the same resources.
4. **Confusing a deadlock with a lock wait timeout** (Lesson 03, §7) —
   they're different errors with different causes: a lock wait
   timeout is one transaction waiting too long for a lock that *will*
   eventually free up (no cycle); a deadlock is a cycle that can never
   resolve on its own.

## 10. Edge Cases

- **Deadlock involving gap locks**: a next-key lock (Lesson 03, §6)
  can participate in a deadlock cycle just like a row lock — two
  transactions both inserting into overlapping ranges can deadlock on
  gap locks even though neither is updating the same existing row.
- **Self-deadlock within one transaction is not possible** in the
  cyclic-wait sense — a single session cannot deadlock against itself,
  though it can encounter a lock wait timeout if it (unusually)
  tries to lock something it already holds in a conflicting mode via
  a bug in application logic.
- **A single statement affecting many rows can deadlock against
  another multi-row statement** if they touch overlapping rows in
  different orders — this is the multi-row generalization of the
  two-row scenario in §5, and is exactly why bulk `UPDATE`s should
  process rows in a consistent, predictable order (e.g., `ORDER BY`
  the primary key) where the engine and query shape allow it.

## 11. Troubleshooting Guidance

- **`SHOW ENGINE INNODB STATUS\G`** — read the `LATEST DETECTED
  DEADLOCK` section first; it directly names the two transactions,
  what each held, and what each wanted.
- Enable `innodb_print_all_deadlocks` to log every deadlock (not just
  the latest) to the error log — invaluable for diagnosing a
  deadlock that recurs intermittently under production load but isn't
  easily reproduced on demand.
- If deadlocks cluster around specific tables/rows, that's a direct
  signal to audit every code path touching those tables for lock
  order consistency — the fix is almost always there, not in the
  isolation level or retry logic.

## 12. Scalability Considerations

Deadlock frequency generally rises with concurrent write volume
against overlapping resources and with transaction length (more time
holding a first lock before acquiring a second widens the collision
window). This is illustrative reasoning: the practical response is
not "avoid all multi-row transactions," but rather enforce consistent
lock ordering and keep transactions as short as the business operation
allows, since both directly shrink the window in which a cycle can
form.

## 13. Additional Dialect Notes

**Oracle:** Automatic deadlock detection with a comparable
victim-selection approach; Oracle's error is `ORA-00060: deadlock
detected while waiting for resource`.

**SQLite:** Its coarser table/database-level locking model (Lesson 03)
makes classic row-level cyclic deadlocks largely inapplicable in the
same form — contention manifests more as `SQLITE_BUSY` from the
single-writer constraint than as a multi-row lock cycle.

**DuckDB:** Not designed around the high-concurrency multi-writer
patterns that produce classic deadlocks; not a primary concern for
DuckDB's typical analytical, single-process usage.

## 14. Interview Questions

1. **"What is the single most effective code-level change to reduce
   deadlock frequency in a system with symmetric two-resource
   operations?"** — Tests for "consistent lock acquisition order,"
   the highest-leverage practice covered in this lesson.
2. **"Your application just received a MySQL deadlock error. What
   should it do?"** — Tests for "catch it and retry the transaction,"
   not treating it as a fatal, unretryable error.
3. **"What's the difference between a deadlock and a lock wait
   timeout?"** — Tests precise understanding: a deadlock is an
   unresolvable cycle, requiring one participant to be killed; a lock
   wait timeout is a transaction giving up on a lock that would
   eventually have become available with no cycle involved.

## 15. Summary

A deadlock is a cycle of transactions each waiting on a lock the next
one holds. MySQL detects this automatically and kills one transaction
to break the cycle, returning `ERROR 1213`. The primary engineering
defense is consistent lock ordering across every code path touching
the same resources, backed by short transactions and application-level
retry logic for the (expected, not exceptional) deadlock errors that
still occur under real concurrent load.

## 16. Practice Challenges

1. Reproduce the §5 deadlock scenario yourself using two sessions
   against `departments` `dept_id` 4 and 7. Observe which session
   receives `ERROR 1213`.
2. Rewrite the two transactions from Challenge 1 so that BOTH always
   lock the lower `dept_id` first, regardless of which "direction"
   the business operation is conceptually going. Confirm the deadlock
   no longer occurs.
3. Explain, in your own words, why "just retry on deadlock" is a
   correct, production-appropriate response, while "just increase
   `innodb_lock_wait_timeout`" is not a fix for deadlocks specifically
   (connect this back to Lesson 03, §7 on what a lock wait timeout
   actually is).

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 17. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB Deadlocks](https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlocks.html)
- MySQL 8.4 Reference Manual — [Deadlock Detection](https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlock-detection.html)

---

**Previous:** [Lesson 03 — Locking Mechanisms](./03_LOCKING_MECHANISMS.md) · **Next:** [Lesson 05 — MVCC](./05_MVCC.md)
