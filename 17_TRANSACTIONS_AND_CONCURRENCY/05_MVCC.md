[← Module Home](./README.md)

# Lesson 05 — MVCC (Multi-Version Concurrency Control)

`Module 17: Transactions & Concurrency Control · Lesson 5 of 7`

---

## 1. Introduction

Lessons 02 and 03 referenced "MVCC" repeatedly without fully explaining
it. This lesson does: MVCC is the mechanism that lets InnoDB give a
`REPEATABLE READ` transaction a consistent snapshot of the data without
making readers block writers, or writers block readers.

## 2. Learning Objectives

- Explain how InnoDB keeps multiple versions of a row and picks the
  right one for a given transaction's snapshot
- State why MVCC readers never block writers (and vice versa) under
  MySQL's default isolation level
- Understand the role of the undo log in reconstructing older row
  versions
- Recognize a scenario where MVCC's snapshot behavior surprises
  someone expecting "current" data

## 3. Why This Exists

Without MVCC, giving a reader a consistent view of the data while
writers are concurrently active would require blocking one or the
other — either readers wait for writers to finish, or writers wait for
readers. MVCC avoids that tradeoff: it keeps old row versions around
long enough for in-flight readers to still see the version consistent
with their transaction's snapshot, while writers proceed independently
by creating new versions rather than overwriting in place.

## 4. Business Motivation

A long-running analytics query scanning `employes` for a report should
not block payroll from concurrently updating salaries, and payroll's
updates shouldn't force the analytics query to abort or see a
half-updated table. MVCC is exactly what makes both true at once: the
analytics query gets a stable snapshot as of when it started, and
payroll's writes create new versions that simply don't exist yet from
that snapshot's point of view.

## 5. How InnoDB's MVCC Works

Every row in InnoDB carries hidden metadata beyond its visible columns:
a transaction ID indicating which transaction last modified it, and a
pointer into the **undo log** — a record of the row's previous
version(s), maintained specifically so an older snapshot can be
reconstructed on demand.

```sql
-- Conceptually (not runnable — hidden system columns aren't exposed
-- via ordinary SELECT):
-- employes row for emp_id=12 has:
--   DB_TRX_ID   -> the transaction ID that last wrote this version
--   DB_ROLL_PTR -> pointer to this row's PREVIOUS version in the undo log
```

When a transaction under `REPEATABLE READ` takes its first read (its
snapshot is established at that point), every subsequent `SELECT`
within that transaction checks each row's `DB_TRX_ID`: if the row was
modified by a transaction that committed *after* this transaction's
snapshot was taken, InnoDB walks the undo log to reconstruct the
version of the row as it existed *at* the snapshot, rather than
returning the newer committed version.

```sql
-- SESSION A                                    -- SESSION B
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;
-- snapshot established HERE, e.g. reads 82000.00
                                                 START TRANSACTION;
                                                 UPDATE employes SET salary = 95000.00
                                                   WHERE emp_id = 12;
                                                 COMMIT;
                                                 -- a NEW row version now exists,
                                                 -- with a newer DB_TRX_ID
SELECT salary FROM employes WHERE emp_id = 12;
-- STILL 82000.00 — InnoDB reconstructs the pre-snapshot version
-- from the undo log, because Session B's committing transaction
-- ID is newer than Session A's snapshot.
COMMIT;
```

## 6. Why Readers Don't Block Writers

Because a reader under MVCC never needs the *current* row — it
reconstructs whatever version its snapshot requires from the undo log
— it never needs to wait for a writer to finish and never needs to
take a lock that would block the writer either. This is the direct
mechanical reason MySQL's default `REPEATABLE READ` achieves strong
isolation without the throughput cost of making every read block on
every concurrent write — a real, structural advantage, not just
"MySQL is fast."

This applies specifically to **plain, non-locking reads**. A locking
read (`SELECT ... FOR UPDATE`, Lesson 03) deliberately opts out of
pure MVCC behavior — it reads the *latest committed* version and takes
a real lock, which is exactly why it can block and be blocked.

## 7. The Undo Log's Role

The undo log isn't just for `ROLLBACK` (though that's its other job,
per Lesson 01) — under MVCC it's the mechanism that makes old row
versions reconstructible for snapshots that started before the latest
committed change. This is also why a very long-running transaction can
have a real cost: InnoDB can't purge undo log entries that a still-open
old snapshot might still need, so a transaction left open for hours
can cause undo log growth that a purely short-lived workload wouldn't
otherwise create.

## 8. Engineering Notes

- MVCC is why "just add a long-running read query, it won't hurt
  anything" isn't quite true at scale — it doesn't block writers, but
  it does keep undo log entries alive that would otherwise be purged,
  which has its own resource cost under sustained write load.
- Don't confuse MVCC's snapshot consistency with "the data is always
  current" — a `REPEATABLE READ` transaction's plain reads are
  deliberately, correctly stale relative to commits that happened
  after its snapshot was established. That's the feature, not a bug.
- A locking read (`FOR UPDATE`/`FOR SHARE`) always reads the latest
  committed version, not the transaction's MVCC snapshot — know which
  behavior a given `SELECT` in your code actually needs.

## 9. MySQL / PostgreSQL / SQL Server Notes

**MySQL:** InnoDB's MVCC implementation, using the undo log for
version reconstruction, as described above.

**PostgreSQL:** Also MVCC-based, but implemented differently —
Postgres keeps old row versions directly in the table's heap itself
(not a separate undo log structure), which is why `VACUUM` exists: to
reclaim space from dead row versions that MySQL's separate undo-log
approach handles differently.

**SQL Server:** Uses locking by default for `READ COMMITTED`, not
MVCC — but offers `READ_COMMITTED_SNAPSHOT` and
`ALLOW_SNAPSHOT_ISOLATION` database options that switch to an
MVCC-style row-versioning model closer to MySQL/Postgres's default
behavior. This is opt-in in SQL Server, unlike MySQL where MVCC is
simply how `REPEATABLE READ` works by default.

## 10. Common Mistakes

1. **Expecting a long-open `REPEATABLE READ` transaction's SELECTs to
   reflect "current" data** — they reflect the snapshot from that
   transaction's first read, by design (Lesson 02, §10 edge case).
2. **Assuming MVCC means locks are never needed** — MVCC solves the
   reader/writer blocking problem for plain reads; it does not solve
   the read-then-write race (Lesson 03) or the deadlock risk
   (Lesson 04) that explicit multi-statement locking can still create.
3. **Not accounting for undo log growth from a long-running
   transaction** — treating "it's just a SELECT, it can't hurt
   anything" as universally true regardless of how long it stays open.

## 11. Edge Cases

- **When exactly the snapshot is taken**: under `REPEATABLE READ` the
  snapshot is established by the transaction's first consistent
  (nonlocking) read, not by `START TRANSACTION` itself — unless you use
  `START TRANSACTION WITH CONSISTENT SNAPSHOT`, which establishes it
  immediately. A transaction always sees its own earlier writes. Check
  the MySQL manual's consistent-read section for the full rules,
  including how DML interacts with the snapshot, before relying on exact
  timing.
- **Extremely long-running transaction alongside heavy concurrent
  writes**: undo log entries pile up because they can't be purged
  while the old snapshot might still need them — this is a genuine,
  measurable operational cost, not a purely theoretical concern.

## 12. Troubleshooting Guidance

- **"History list length" growing unexpectedly** — check
  `SHOW ENGINE INNODB STATUS\G` for the `History list length` figure
  under `TRANSACTIONS`; a large and growing value alongside heavy
  write activity often points to a long-running open transaction
  (check `information_schema.INNODB_TRX`) preventing undo log purge.
- **"My transaction's SELECT doesn't reflect a change I just
  committed elsewhere"** — confirm whether this is a *plain* read
  within an already-open `REPEATABLE READ` transaction (expected MVCC
  snapshot behavior, see §10 Mistake #1) versus a genuinely new
  transaction that should see the change.

## 13. Scalability Considerations

MVCC is a major reason MySQL/InnoDB handles read-heavy concurrent
workloads well without readers and writers serializing against each
other. The tradeoff surfaces specifically under sustained long-running
transactions combined with high write volume: undo log growth from
unpurgeable old versions. This is illustrative, not a benchmark claim:
the practical implication is that "keep transactions short" (Lesson
01, §8) has a second, MVCC-specific justification beyond just reducing
lock contention — it also lets the undo log purge normally.

## 14. Additional Dialect Notes

**Oracle:** Uses multiversioning conceptually similar to InnoDB's
approach (a form of undo-based version reconstruction), giving
Oracle's default read consistency non-blocking-reader behavior as well.

**SQLite:** In WAL (Write-Ahead Logging) mode, readers can proceed
concurrently with a single writer without blocking, which is
MVCC-adjacent in effect though architecturally distinct from InnoDB's
row-versioning approach.

**DuckDB:** Implements its own MVCC appropriate to its typically
single-process analytical workload, conceptually related but not
identical in mechanism to InnoDB's undo-log-based approach.

## 15. Interview Questions

1. **"How does InnoDB let a REPEATABLE READ transaction see a
   consistent snapshot without blocking concurrent writers?"** — Tests
   for the core MVCC mechanism: old versions reconstructed from the
   undo log rather than reads blocking on writer locks.
2. **"Why does a locking read like SELECT ... FOR UPDATE behave
   differently from a plain SELECT under MVCC?"** — Tests
   understanding that locking reads deliberately read the latest
   committed version and take a real lock, opting out of pure
   snapshot-based MVCC behavior.
3. **"What's a real operational cost of leaving a REPEATABLE READ
   transaction open for a very long time, beyond lock contention?"**
   — Tests for undo log growth / purge prevention, not just the more
   commonly-cited lock-holding cost.

## 16. Summary

MVCC lets InnoDB give each `REPEATABLE READ` transaction a consistent
snapshot by reconstructing older row versions from the undo log,
rather than by blocking readers against writers or vice versa. This is
the mechanical explanation behind Lesson 02's phantom-read prevention
and Lesson 03's "plain reads don't block writers" behavior. The
tradeoff is that long-running transactions delay undo log purging,
which is a second, distinct reason (beyond lock duration) to keep
transactions short.

## 17. Practice Challenges

1. Using two sessions, reproduce the snapshot behavior from §5:
   confirm a `REPEATABLE READ` transaction's second read of a row
   still shows the pre-update value even after another session
   commits a change to it.
2. Explain, without running SQL, why a `SELECT ... FOR UPDATE` on the
   same row in the same scenario as Challenge 1 WOULD see the
   updated value, while the plain `SELECT` does not.
3. Look up `SHOW ENGINE INNODB STATUS\G`'s `History list length`
   figure on a test instance. Explain in your own words what a
   steadily growing value alongside active writes would indicate.

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 18. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB Multi-Versioning](https://dev.mysql.com/doc/refman/8.4/en/innodb-multi-versioning.html)
- MySQL 8.4 Reference Manual — [Undo Logs](https://dev.mysql.com/doc/refman/8.4/en/innodb-undo-logs.html)

---

**Previous:** [Lesson 04 — Deadlocks](./04_DEADLOCKS.md) · **Next:** [Lesson 06 — Transaction Anti-Patterns](./06_TRANSACTION_ANTI_PATTERNS.md)
