[← Module Home](./README.md)

# Lesson 03 — Locking Mechanisms

`Module 17: Transactions & Concurrency Control · Lesson 3 of 7`

---

## 1. Introduction

Isolation levels (Lesson 02) largely describe *what a transaction sees*.
Locking describes *how the engine keeps writers from stepping on each
other*, and how a read can deliberately opt into blocking a
concurrent write when isolation-level guarantees alone aren't enough.
This lesson covers InnoDB's row-level locking model directly.

## 2. Learning Objectives

- Distinguish shared (S) and exclusive (X) locks, and when each is
  taken automatically
- Use `SELECT ... FOR UPDATE` and `SELECT ... FOR SHARE` correctly to
  close a read-then-write race
- Recognize gap locks and next-key locks and why InnoDB uses them
- Diagnose a lock wait using `information_schema` / `performance_schema`

## 3. Why This Exists

A transaction that reads a value, computes a new value based on it,
then writes the new value back — "read-then-write" — is not safe under
concurrency unless something prevents another transaction from doing
the same read-modify-write in between your read and your write.
Isolation level alone (Lesson 02) does not close this gap for a
generic read-then-write pattern; explicit locking is the mechanism
that does.

## 4. Business Motivation

Consider decrementing inventory when an order is placed:
`SELECT quantity FROM inventory WHERE product_id = 55`, check it's
`> 0` in application code, then `UPDATE inventory SET quantity =
quantity - 1 ...`. Two concurrent orders can both read `quantity = 1`,
both decide "in stock," and both decrement — selling the same unit of
inventory twice. `SELECT ... FOR UPDATE` on the read closes this
exact race by taking an exclusive lock at read time, forcing the
second transaction to wait until the first commits (and sees the now-updated quantity) before it can proceed. (The `inventory` table is illustrative and not part of `00_Schema`; the companion `.sql` uses `employes.salary` as a stand-in numeric column.)

## 5. Shared vs. Exclusive Locks

| Lock Type | Taken By | Blocks Other... |
|---|---|---|
| Shared (S) | Plain locking read: `SELECT ... FOR SHARE` | ...exclusive locks on the same row (other reads with S are fine) |
| Exclusive (X) | `UPDATE`, `DELETE`, `INSERT`, `SELECT ... FOR UPDATE` | ...both shared AND exclusive locks on the same row |

```sql
-- Exclusive lock, held until COMMIT/ROLLBACK:
START TRANSACTION;
SELECT quantity FROM inventory WHERE product_id = 55 FOR UPDATE;
-- any other session's UPDATE, DELETE, or SELECT ... FOR UPDATE
-- against product_id = 55 now BLOCKS until this transaction ends
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 55;
COMMIT;   -- lock released here
```

```sql
-- Shared lock — lets other readers proceed, blocks writers:
START TRANSACTION;
SELECT quantity FROM inventory WHERE product_id = 55 FOR SHARE;
-- another SELECT ... FOR SHARE can proceed concurrently;
-- an UPDATE from another session blocks until this COMMITs
COMMIT;
```

## 6. Gap Locks and Next-Key Locks

InnoDB locks more than the exact rows a query touches when the query
involves a range, an equality lookup on a non-unique index, or a
lookup on a value that doesn't exist yet — it also locks the **gap**
between index records, to prevent a phantom insert into that gap
(Lesson 02, §6 footnote).

```sql
START TRANSACTION;
SELECT * FROM employes WHERE hire_date BETWEEN '2023-01-01' AND '2023-12-31'
  FOR UPDATE;
-- This takes next-key locks covering the matched rows AND the gaps
-- between them within that date range, under REPEATABLE READ —
-- another session's INSERT of a NEW employee hired '2023-06-15'
-- BLOCKS, even though no such row existed for this query to have
-- locked directly. This is what makes the range phantom-safe for
-- this locking read.
COMMIT;
```

**Setup this example depends on.** The range a locking read locks depends
on the index the optimizer uses and on the isolation level. With an index
on `hire_date`, InnoDB takes next-key locks on the scanned index entries
and the gap after the last one; without one it scans the clustered index
and can lock far more rows and gaps. The companion `.sql` creates a
temporary index, confirms the plan with `EXPLAIN`, and drops it afterward
(see [Module 15 — Indexes](../15_INDEXES/README.md) for how the optimizer
chooses indexes). This requires `REPEATABLE READ`: under `READ COMMITTED`
InnoDB generally does not take gap locks for searches and index scans, so
the concurrent insert would not block.

A **next-key lock** is InnoDB's combination of a record lock (on the
row itself) plus a gap lock (on the space before it in index order).
This is InnoDB-specific machinery, not a general SQL-standard concept
— it exists because InnoDB delivers `REPEATABLE READ`'s phantom
protection for locking reads through locking rather than pure MVCC.

## 7. Lock Wait Timeout

```sql
SELECT @@innodb_lock_wait_timeout;   -- default: 50 seconds

-- A session blocked longer than this on a row lock gets:
-- ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

A lock-wait-timeout error is not a deadlock (Lesson 04) — it's one
transaction simply waiting too long for another to release a lock
voluntarily. The waiting transaction's statement fails; earlier
statements in that same transaction remain pending, uncommitted.

## 8. Engineering Notes

- `SELECT ... FOR UPDATE` is the correct tool for read-then-write
  races; a plain `SELECT` followed by an `UPDATE` is not equivalent,
  regardless of isolation level, because the plain `SELECT` takes no
  lock at all.
- Where the logic allows it, prefer a single atomic statement —
  `UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 55
  AND quantity > 0` — over a separate locking read plus a write. One
  statement is inherently race-free; two statements, even with
  `FOR UPDATE`, require correct transaction boundaries to stay safe.
- Lock rows in a **consistent order** across all code paths that touch
  more than one row (e.g., always lock the lower `emp_id` first).
  Inconsistent ordering across concurrent transactions is the single
  most common cause of deadlocks (Lesson 04).
- Locks are held until `COMMIT`/`ROLLBACK`, not until the statement
  that took them finishes — a long transaction holding a `FOR UPDATE`
  lock blocks others for its entire remaining duration, not just for
  the moment of that one statement.

## 9. MySQL / PostgreSQL / SQL Server Notes

**MySQL:** Row-level locking is InnoDB-specific; `MyISAM` uses table-level locking and has no row-level locks, so `FOR UPDATE` gives no row-level protection there. Gap locks and next-key
locks are also InnoDB-specific concepts.

**PostgreSQL:** Also supports `SELECT ... FOR UPDATE` / `FOR SHARE`
with very similar semantics, plus `FOR NO KEY UPDATE` and `FOR KEY
SHARE` for finer-grained control not present in MySQL. Postgres does
**not** use gap locks the way InnoDB does — it achieves phantom
protection differently (via its own MVCC snapshot mechanics and, at
`SERIALIZABLE`, predicate locking).

**SQL Server:** Supports table hints like `WITH (UPDLOCK)`,
`WITH (HOLDLOCK)`, `WITH (ROWLOCK)` for comparable fine-grained
locking control, syntactically distinct from MySQL/Postgres's
`FOR UPDATE` clause.

## 10. Common Mistakes

1. **Using a plain `SELECT` then a separate `UPDATE`** for a
   read-then-write, believing the isolation level alone protects it —
   it doesn't; see Lesson 02, §9 (Common Mistake #2).
2. **Holding a `FOR UPDATE` lock across a slow external call** —
   identical anti-pattern to Lesson 01/06's "don't hold a transaction
   open across a network call," but worse here because the lock is
   explicit and exclusive, actively blocking others the entire time.
3. **Inconsistent lock acquisition order** across different code paths
   — one path locks employee row then department row, another locks
   department then employee — a direct setup for deadlock (Lesson 04).
4. **Assuming `FOR UPDATE` locks only the exact rows matched** without
   accounting for gap/next-key locking on range or non-unique-index
   predicates, then being surprised an unrelated insert blocks.

## 11. Edge Cases

- **Locking a row that doesn't exist yet** (e.g., `SELECT ... FOR
  UPDATE` on a primary key value with no matching row): InnoDB still
  takes a gap lock on the space where that value *would* sort, to
  prevent a concurrent insert of exactly that value — relevant for
  patterns like "check if a unique code is taken, then insert it."
- **Locking with a secondary, non-unique index**: locks are taken on
  the index records actually scanned to satisfy the query, which can
  be more rows than the final result set if the optimizer needs to
  examine (and lock) rows it later filters out — a real reason a
  seemingly narrow `WHERE` clause can lock more than expected.

## 12. Troubleshooting Guidance

- **Diagnose an active lock wait**:
  ```sql
  SELECT * FROM performance_schema.data_lock_waits;
  SELECT * FROM performance_schema.data_locks;
  ```
- **Find long-running transactions holding locks**:
  ```sql
  SELECT trx_id, trx_started, trx_mysql_thread_id, trx_query
  FROM information_schema.INNODB_TRX
  ORDER BY trx_started;
  ```
- A session stuck on a lock wait is not itself a bug — it's evidence
  another transaction is holding a conflicting lock too long; find
  *that* transaction, not the waiting one, to fix the root cause.

## 13. Scalability Considerations

Lock contention rises with concurrent write volume against the same
rows/ranges. `FOR UPDATE` on a hot row (e.g., a shared counter) under
high concurrency serializes every transaction that touches it,
regardless of how brief each individual transaction is — the
contention is structural to the access pattern, not something a
faster query fixes. Illustrative only: this is exactly where patterns
like sharding a counter across multiple rows, or using an atomic
single-statement `UPDATE ... SET x = x + 1` instead of a
lock-then-read-then-write sequence, become relevant — measure real
contention before redesigning around it.

## 14. Additional Dialect Notes

**Oracle:** Uses `SELECT ... FOR UPDATE` with very similar semantics
to MySQL/Postgres; Oracle's multiversion read consistency means
non-locking reads never block on writer locks, similar in spirit to
InnoDB's MVCC reads.

**SQLite:** Locking model is coarser-grained (database- or table-level
depending on journal mode), not row-level — `FOR UPDATE` syntax is
not meaningfully applicable the way it is in MySQL/Postgres/Oracle.

**DuckDB:** Not designed around fine-grained row-level locking for
high-concurrency OLTP write patterns; this lesson's locking-race
scenarios are not DuckDB's primary use case.

## 15. Interview Questions

1. **"Why doesn't a plain SELECT followed by an UPDATE safely handle
   a read-then-write race, even under REPEATABLE READ?"** — Tests
   understanding that isolation level governs visibility, not
   locking; a plain SELECT takes no lock at all.
2. **"What is a gap lock, and why does InnoDB need it even though the
   SQL standard doesn't mention 'gaps' anywhere?"** — Tests whether
   the candidate understands gap locks as InnoDB's specific mechanism
   for closing the phantom-insert hole in locking reads.
3. **"You have two transactions that both need to update an employee
   row and a department row. What's the single most effective change
   to prevent deadlocks between them?"** — Tests for "acquire locks in
   a consistent order," the single highest-leverage anti-deadlock
   practice, covered fully in Lesson 04.

## 16. Summary

Shared locks let concurrent readers coexist while blocking writers;
exclusive locks block everyone. `SELECT ... FOR UPDATE` is how you
convert a read into one that participates in this locking model,
closing read-then-write races that isolation level alone doesn't
address. InnoDB additionally uses gap and next-key locks to make
locking reads phantom-safe on ranges and non-unique indexes. Locks are
held for the full transaction duration — transaction length (Lesson
01) and lock duration are the same lever.

## 17. Practice Challenges

1. Rewrite the "decrement inventory" read-then-write pattern from §4
   two ways: once using `SELECT ... FOR UPDATE`, once as a single
   atomic `UPDATE` statement. Explain which is preferable and why.
2. Using two sessions, demonstrate a `SELECT ... FOR UPDATE` on
   `emp_id = 12` blocking a concurrent `UPDATE` on the same row from
   a second session until the first session commits.
3. Explain what locks a `SELECT ... FOR UPDATE WHERE dept_id = 4` (a
   non-unique index) takes, and why a concurrent `INSERT` of a new
   employee into `dept_id = 4` can block even though that row didn't
   exist when the `FOR UPDATE` ran.

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 18. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB Locking](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking.html)
- MySQL 8.4 Reference Manual — [Locking Reads](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html)

---

**Previous:** [Lesson 02 — Isolation Levels & Read Phenomena](./02_ISOLATION_LEVELS_AND_READ_PHENOMENA.md) · **Next:** [Lesson 04 — Deadlocks](./04_DEADLOCKS.md)
