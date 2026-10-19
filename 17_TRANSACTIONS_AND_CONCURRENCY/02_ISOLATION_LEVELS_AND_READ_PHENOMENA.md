[← Module Home](./README.md)

# Lesson 02 — Isolation Levels & Read Phenomena

`Module 17: Transactions & Concurrency Control · Lesson 2 of 7`

---

## 1. Introduction

Isolation (Lesson 01, §5.3) is a spectrum, not a switch. The SQL
standard defines four isolation levels, each permitting or preventing
specific "read phenomena" — ways one transaction's view of the data can
be affected by another concurrent transaction. This lesson names each
phenomenon precisely and shows what MySQL actually does at each level,
because "isolation" without a level attached is an incomplete claim.

## 2. Learning Objectives

- Name and distinguish dirty reads, non-repeatable reads, and phantom
  reads with a concrete example of each
- State MySQL's default isolation level and what it prevents/allows
- Choose an appropriate isolation level for a given scenario, with a
  reason, not by default habit
- Recognize when an isolation level alone is *not* sufficient and
  explicit locking (Lesson 03) is required

## 3. Why This Exists

Full serializability requires that the observed results of concurrent
transactions be equivalent to the results produced by some serial
ordering of those transactions; it does not require that transactions
never overlap in time. In practice, database engines may execute
transactions concurrently while ensuring their effects match a particular
serial schedule. Serializability is therefore a correctness property
about the outcome (equivalence to a serial order), not a prohibition on
temporal overlap. Different engines implement serializability using
different mechanisms (strict locking, optimistic / SSI techniques,
etc.), and their performance and retry behaviour under contention vary.

## 4. Business Motivation

A reporting dashboard that reads "current headcount by department"
doesn't need the same isolation guarantees as a payroll job computing
"total salary to disburse this cycle" — a dashboard reading a slightly
stale but internally consistent snapshot is usually fine; a payroll run
double-counting or missing a row because of a phantom read is a real
financial defect. Picking the isolation level deliberately, per
workload, is how you get both: fast dashboards and correct payroll.

## 5. The Read Phenomena

### 5.1 Dirty Read
Transaction A reads a row that Transaction B has modified but not yet
committed. If B then rolls back, A acted on data that was never
actually true.

```sql
-- Session A                                 -- Session B
                                              START TRANSACTION;
                                              UPDATE employes SET salary = 999999.00
                                                WHERE emp_id = 12;
SET SESSION TRANSACTION ISOLATION LEVEL
  READ UNCOMMITTED;
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;
-- Under READ UNCOMMITTED: sees 999999.00 — B's UNCOMMITTED change.
COMMIT;
                                              ROLLBACK;
-- Session A already acted on a value that never actually existed
-- from the database's permanent point of view.
```

### 5.2 Non-Repeatable Read
Transaction A reads the same row twice within one transaction, and gets
different values, because Transaction B committed a change to that row
in between A's two reads.

```sql
-- Session A                                 -- Session B
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;  -- e.g. 82000.00
                                              START TRANSACTION;
                                              UPDATE employes SET salary = 88000.00
                                                WHERE emp_id = 12;
                                              COMMIT;
SELECT salary FROM employes WHERE emp_id = 12;  -- under READ COMMITTED: 88000.00 now
COMMIT;
```

### 5.3 Phantom Read
Transaction A runs the same range-based query twice, and the *set of
rows* returned changes, because Transaction B committed an insert or
delete matching that range in between.

```sql
-- Session A                                              -- Session B
START TRANSACTION;
SELECT COUNT(*) FROM employes WHERE dept_id = 4;          -- e.g. 8
                                                           START TRANSACTION;
                                                           INSERT INTO employes
                                                             (emp_id, emp_name, dept_id,
                                                              manager_id, hire_date, salary)
                                                           VALUES (9002, 'New Hire', 4,
                                                                   3, '2025-01-10', 60000.00);
                                                           COMMIT;
SELECT COUNT(*) FROM employes WHERE dept_id = 4;          -- under READ COMMITTED: 9 now
COMMIT;
```

## 6. The Four Isolation Levels

| Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|---|---|---|---|
| `READ UNCOMMITTED` | Possible | Possible | Possible |
| `READ COMMITTED` | Prevented | Possible | Possible |
| `REPEATABLE READ` (**MySQL default**) | Prevented | Prevented | Prevented by MVCC snapshot* |
| `SERIALIZABLE` | Prevented | Prevented | Prevented |

*For plain (nonlocking) `SELECT`s, MySQL's `REPEATABLE READ` reads from a
consistent snapshot, so rows inserted by other committed transactions are
not visible — stronger than the SQL standard strictly requires at this
level. Locking reads and writes (`SELECT ... FOR UPDATE`, `UPDATE`,
`DELETE`) don't use the snapshot: they read the latest committed data and,
under `REPEATABLE READ`, use next-key locks on the index ranges they scan,
which blocks concurrent inserts into those ranges. Which locks are taken
depends on the statement, the index used, and the search condition
(Lesson 03). A locking read can therefore return a newer committed row
version than an earlier plain `SELECT` in the same transaction — two
different read mechanisms, not a failure of the isolation level.

```sql
-- Setting isolation level for the NEXT transaction only:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
...
COMMIT;

-- Setting it for the whole SESSION (persists across transactions):
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Checking current setting:
SELECT @@transaction_isolation;
```

## 7. Engineering Notes

- `REPEATABLE READ` is MySQL's default for a reason: it gives strong
  guarantees for typical OLTP workloads without `SERIALIZABLE`'s full
  throughput cost. Don't downgrade to `READ COMMITTED` "for
  performance" without first measuring that `REPEATABLE READ` is
  actually the bottleneck — verify with `EXPLAIN`/profiling before
  changing an isolation level for a hypothetical performance reason.
- Isolation level is a **session-scoped or transaction-scoped**
  setting, not a table-wide or database-wide one by default — two
  concurrent sessions can run under different isolation levels at the
  same time against the same tables.
- Higher isolation is not "more correct" in the abstract — it's a
  different point on a tradeoff. A reporting query that's fine reading
  a slightly-stale-but-consistent snapshot gains nothing from
  `SERIALIZABLE` except more contention.

## 8. MySQL / PostgreSQL / SQL Server Notes

**MySQL:** Default `REPEATABLE READ`. Achieves it via InnoDB's MVCC
(Lesson 05) rather than locking every read — this is why MySQL's
`REPEATABLE READ` also happens to prevent most phantom reads for plain
`SELECT`s, which is stronger than the SQL standard's minimum
requirement for this level.

**PostgreSQL:** Default `READ COMMITTED`. PostgreSQL's `REPEATABLE
READ` is implemented differently (true snapshot isolation) and its
`SERIALIZABLE` uses Serializable Snapshot Isolation (SSI) — worth
knowing if you're used to MySQL's locking-flavored `SERIALIZABLE` and
move to Postgres, since the failure mode under contention differs
(Postgres's SSI can abort a transaction with a serialization-failure
error that the application must be prepared to retry).

**SQL Server:** Default `READ COMMITTED`, with an additional
`READ COMMITTED SNAPSHOT` database-level option that changes
`READ COMMITTED`'s underlying mechanism to MVCC-style row versioning
rather than locking — a hybrid MySQL and PostgreSQL users should be
aware exists before assuming SQL Server's `READ COMMITTED` behaves
identically to either.

## 9. Common Mistakes

1. **Assuming "the default is fine" without knowing what the default
   actually is** for the engine in front of you — MySQL's
   `REPEATABLE READ` and PostgreSQL's `READ COMMITTED` are different
   defaults with different phantom-read exposure.
2. **Treating isolation level as a substitute for explicit locking**
   in a read-then-write race — `REPEATABLE READ` prevents your
   `SELECT`s from seeing certain changes, but a plain `SELECT` followed
   by a separate `UPDATE` based on that read value can still race
   against another session's concurrent update unless you use a
   locking read (`SELECT ... FOR UPDATE`, Lesson 03) or an atomic
   single-statement update.
3. **Setting `SERIALIZABLE` everywhere "to be safe"** without
   measuring the throughput cost, then being surprised by increased
   lock waits and deadlocks (Lesson 04) under real concurrent load.

## 10. Edge Cases

- **Long-running `REPEATABLE READ` transaction**: MVCC means a
  transaction's snapshot is fixed at (roughly) its first read — a
  transaction left open for an hour continues seeing data as of that
  snapshot, even as other committed changes pile up. This can
  surprise developers expecting a `SELECT` late in a long transaction
  to reflect "current" data.
- **Locking reads under `REPEATABLE READ`**: `SELECT ... FOR UPDATE`
  and `SELECT ... FOR SHARE` don't use the MVCC snapshot the same way
  plain `SELECT`s do — they read the latest committed version and take
  a lock, which is why they can still encounter phantom-adjacent gap
  locks (Lesson 03) that plain reads don't.

## 11. Troubleshooting Guidance

- **"My report shows different numbers than a second ago, though
  nothing should have changed"** — check the isolation level actually
  in effect (`SELECT @@transaction_isolation;`), and whether the
  report logic opens a new transaction per query versus one
  transaction wrapping the whole report.
- **"Two concurrent updates to the same row produced a lost update"**
  — this is often a symptom of relying on isolation level alone
  instead of a locking read or an atomic `UPDATE ... SET x = x + 1`
  style statement; see Lesson 03.

## 12. Scalability Considerations

Isolation level choice interacts directly with lock duration and
contention (Lesson 03) — `SERIALIZABLE` under MySQL — when autocommit is disabled — implicitly turns plain `SELECT`s into `SELECT ... FOR SHARE`, taking shared locks on the rows it reads (w[...]
lock contention under concurrent load compared to `REPEATABLE READ`'s
MVCC-based reads that don't block writers. This is a structural
tradeoff to weigh against correctness needs, not a reason to avoid
`SERIALIZABLE` when it's genuinely required — measure the actual
contention on your workload before deciding.

## 13. Additional Dialect Notes

**Oracle:** Default is `READ COMMITTED`, implemented via multiversioning
similar in spirit to MySQL's MVCC; Oracle does not implement a true
`READ UNCOMMITTED`.

**SQLite:** Effectively serializes all writers (a single writer lock at
a time) regardless of isolation-level-style settings — the isolation
level conversation in SQLite is less about read phenomena between
concurrent writers and more about read/write concurrency generally.

**DuckDB:** Uses optimistic MVCC concurrency control appropriate to
its typically single-process, analytical-workload use case.

## 14. Interview Questions

1. **"Explain the difference between a non-repeatable read and a
   phantom read with an example of each."** — Tests precision: a
   non-repeatable read is about the same row changing value; a
   phantom read is about the row *set* changing.
2. **"Under REPEATABLE READ, why can a `SELECT ... FOR UPDATE` return a
   newer committed row version than a plain `SELECT` earlier in the same
   transaction, and how does InnoDB protect the scanned index range
   against concurrent inserts?"** — Tests the difference between snapshot
   reads (MVCC) and locking reads (latest committed data plus next-key
   locks), without implying the isolation level "fails" to protect
   locking reads.
3. **"When would you deliberately choose READ COMMITTED over the
   MySQL default of REPEATABLE READ?"** — Tests whether the candidate
   can reason about a real tradeoff (e.g., a high-throughput read path
   that tolerates slightly staler-but-still-committed data and wants
   to reduce long-transaction snapshot overhead) rather than reciting
   "REPEATABLE READ is always better."

## 15. Summary

Isolation level names a specific point on the correctness/throughput
tradeoff, defined by which of three read phenomena (dirty,
non-repeatable, phantom) it permits. MySQL defaults to `REPEATABLE
READ`, achieved through MVCC (Lesson 05), which happens to prevent
most phantoms for plain reads too — stronger than the standard
requires. Isolation level alone does not prevent every concurrency
bug; a read-then-write race still needs explicit locking (Lesson 03)
or an atomic statement regardless of isolation level chosen.

## 16. Practice Challenges

1. Using two sessions, reproduce a non-repeatable read under
   `READ COMMITTED`, then show the same sequence does NOT show a
   non-repeatable read under `REPEATABLE READ`.
2. Explain why setting `SESSION TRANSACTION ISOLATION LEVEL
   SERIALIZABLE` for a reporting-only read replica might be a
   reasonable choice, while doing the same for the primary
   transactional workload might not be.
3. Write a two-session demonstration of a phantom read against
   `dept_id = 7` under `READ COMMITTED`, then show that MySQL's
   default `REPEATABLE READ` prevents it for the plain `SELECT`
   version of the same query.

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 17. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.4/en/innodb-transaction-isolation-levels.html)
- PostgreSQL Documentation — [Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)

---

**Previous:** [Lesson 01 — ACID & Transaction Fundamentals](./01_ACID_AND_TRANSACTION_FUNDAMENTALS.md) · **Next:** [Lesson 03 — Locking Mechanisms](./03_LOCKING_MECHANISMS.md)
