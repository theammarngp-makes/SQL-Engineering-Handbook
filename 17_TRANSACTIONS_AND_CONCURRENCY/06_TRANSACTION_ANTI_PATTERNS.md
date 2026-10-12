[← Module Home](./README.md)

# Lesson 06 — Transaction Anti-Patterns

`Module 17: Transactions & Concurrency Control · Lesson 6 of 7`

---

## 1. Introduction

Lessons 01–05 built the mechanisms. This lesson is a catalog of how
those mechanisms get misused in real systems — patterns that "work"
under light load and quietly become the cause of lock contention,
deadlocks, or outages under real concurrency.

## 2. Learning Objectives

- Recognize each anti-pattern in this catalog in real application code
- Explain the specific mechanism (lock duration, isolation gap,
  missing atomicity) each anti-pattern violates
- Apply the corresponding fix from Lessons 01–05

## 3. Why This Exists

Every anti-pattern below is a violation of a principle already
established in Lessons 01–05, restated here as "what it looks like
when someone doesn't apply it." Interview questions and production
debugging (Module 18) both draw heavily on recognizing these patterns
under time pressure, which is why they're consolidated here rather
than left scattered across the earlier lessons.

## 4. The Anti-Pattern Catalog

### 4.1 Long-Held Transaction Around an External Call

```sql
-- ANTI-PATTERN:
START TRANSACTION;
UPDATE employes SET salary = salary + 5000 WHERE emp_id = 12;
-- application code here calls an external payroll API, waits 3+ seconds
UPDATE employes SET salary = salary - 5000 WHERE dept_id = 4 ORDER BY emp_id LIMIT 1; -- compensating entry
COMMIT;
```

Every lock this transaction holds stays held for the entire external
call's duration. If the call hangs or is merely slow, every other
session needing those locks queues up behind it. **Fix:** do the
external call *before* opening the transaction (validate/prepare
outside), or *after* committing (finalize outside) — never *during*.

### 4.2 Missing Transaction Boundaries on a Multi-Statement Operation

```sql
-- ANTI-PATTERN (relies on autocommit, no explicit boundary):
UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
-- if the application crashes HERE, only this statement is committed
UPDATE employes SET salary = salary * 1.02 WHERE dept_id = 4;
```

Under autocommit (Lesson 01, §7), each statement is its own
independent transaction — a crash between them leaves the operation
half-done, permanently. **Fix:** wrap the whole logical operation in
one explicit `START TRANSACTION` / `COMMIT`.

### 4.3 Oversized Transactions

```sql
-- ANTI-PATTERN: one transaction updating every row in a large table
START TRANSACTION;
UPDATE employes SET salary = salary * 1.03;  -- all rows, no WHERE
COMMIT;
```

A transaction touching an entire large table holds locks on all of it
for the whole duration, blocking essentially everything else against
that table. **Fix:** batch the operation into smaller transactions
(e.g., by `dept_id`, or in primary-key ranges), each committing
independently, so lock duration and blast radius per transaction stay
bounded.

### 4.4 No Retry Logic for Deadlocks / Serialization Failures

```sql
-- ANTI-PATTERN (application pseudocode):
-- try:
--     run_transaction()
-- except DeadlockError:
--     raise   -- surfaces as an unhandled 500 error to the user
```

A deadlock (Lesson 04) is an expected, occasional outcome under
concurrent access — not treating it as retryable turns a normal,
recoverable event into a user-facing failure. **Fix:** catch deadlock
(and, on engines like PostgreSQL, serialization-failure) errors
specifically and retry the transaction, typically with a brief
backoff and a retry limit.

### 4.5 Overuse of SERIALIZABLE

```sql
-- ANTI-PATTERN: SERIALIZABLE by default for everything, "to be safe"
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- ...applied to a read-heavy reporting endpoint that doesn't need it
```

`SERIALIZABLE` (Lesson 02, §6) implicitly makes plain reads shared-locking reads when autocommit is disabled (Lesson 02, §12), which can increase contention under concurrent load
for workloads that don't actually need the extra guarantee. **Fix:**
default to MySQL's `REPEATABLE READ`; reserve `SERIALIZABLE` for
operations where the specific guarantee (no phantom reads even under
locking reads / true serial-equivalent ordering) is a genuine, named
requirement — not a default reflex.

### 4.6 Read-Then-Write Without Atomicity or Locking

```sql
-- ANTI-PATTERN: plain read, application-level check, separate write
-- SELECT quantity FROM inventory WHERE product_id = 55;
-- (application code checks quantity > 0)
-- UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 55;
```

Covered fully in Lesson 03, §4 and §10 — this is the classic
lost-update race. **Fix:** `SELECT ... FOR UPDATE` on the read, or
(preferably, where the logic allows it) a single atomic statement:
`UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 55
AND quantity > 0`.

### 4.7 Ignoring Isolation-Level Defaults Across Engines

```sql
-- ANTI-PATTERN: code written and tested against MySQL's default
-- REPEATABLE READ, then deployed against a PostgreSQL instance
-- (default READ COMMITTED) without re-verifying phantom-read exposure
```

Lesson 02, §8 documents that MySQL defaults to `REPEATABLE READ` while
PostgreSQL defaults to `READ COMMITTED` — code relying on
phantom-read prevention "because that's just how the database
behaves" can silently become unsafe when the underlying engine (or
even just its configuration) changes. **Fix:** state the isolation
level a piece of logic actually depends on explicitly in code/comments,
and set it explicitly rather than relying on whichever default happens
to be in effect.

## 5. Engineering Notes

- Every anti-pattern above traces back to one of two root causes:
  **a transaction held longer than necessary** (4.1, 4.3) or **a
  concurrency guarantee assumed but never actually taken** (4.2, 4.6,
  4.7). Recognizing which of the two you're looking at usually points
  straight at the fix.
- These patterns compound: an oversized transaction (4.3) that also
  makes an external call (4.1) is worse than either alone.

## 6. MySQL / PostgreSQL / SQL Server Notes

The mechanisms behind each anti-pattern were already covered with
per-engine differences in Lessons 01–05; §4.7 above is the one
anti-pattern that is *specifically* about cross-engine differences —
treat it as a reminder to re-check the earlier lessons' dialect notes
whenever code moves between engines.

## 7. Common Mistakes

Covered inline per anti-pattern in §4 above — each entry's "ANTI-
PATTERN" block *is* the common mistake, with its fix stated directly
after.

## 8. Edge Cases

- **A short transaction that's still an anti-pattern**: brevity alone
  doesn't excuse missing atomicity (4.2) — a fast pair of unwrapped
  statements is still unsafe against a crash between them, regardless
  of how quickly they normally execute.
- **A single long transaction that's NOT an anti-pattern**: a
  genuinely large, unavoidable batch operation that has no external
  call, is deliberately scoped (not "every row, no WHERE," but a
  bounded batch), and has monitoring/alerting for unusually long
  duration is a legitimate design choice, not automatically 4.3 —
  context and intent matter, not transaction length alone.

## 9. Troubleshooting Guidance

Use Lesson 03's `information_schema.INNODB_TRX` and
`performance_schema.data_lock_waits` queries, and Lesson 04's `SHOW
ENGINE INNODB STATUS\G` deadlock report, as the concrete diagnostic
tools for spotting which of these anti-patterns is actually present in
a production incident — this lesson names the patterns; Lessons 03–04
give you the tools to catch them in the act.

## 10. Scalability Considerations

Every anti-pattern in this catalog degrades specifically under
*concurrent load* — most are invisible or harmless in single-user
testing and low-traffic staging environments, which is exactly why
they tend to reach production undetected. Load-testing with realistic
concurrency, not just realistic data volume, is what actually surfaces
these before real users do.

## 11. Additional Dialect Notes

Not applicable as a separate section here — dialect-specific detail
for each underlying mechanism lives in Lessons 01–05; this lesson is a
synthesis, not a new mechanism.

## 12. Interview Questions

1. **"A payment-processing transaction calls an external gateway API
   in the middle of its `START TRANSACTION` block. What's wrong with
   this, specifically?"** — Tests for 4.1, with the specific mechanism
   (lock duration tied to external call latency), not just "that seems
   bad."
2. **"Walk through what happens if a bulk salary-update transaction
   touching 500,000 rows runs at the same time as normal application
   traffic."** — Tests for 4.3's lock contention and blast-radius
   reasoning, ideally with a batching fix proposed.
3. **"Why is 'catch and retry' the correct response to a deadlock
   error, but not to a foreign-key-violation error?"** — Tests
   whether the candidate distinguishes a transient, environment-caused
   failure (4.4, expected to sometimes happen and safe to retry) from
   a logic/data error (retrying the same statement will fail
   identically every time).

## 13. Summary

This lesson names seven concrete anti-patterns, each a violation of a
principle from Lessons 01–05: holding a transaction across an external
call, missing transaction boundaries, oversized transactions, no
deadlock retry logic, reflexive `SERIALIZABLE` overuse, unguarded
read-then-write races, and assuming isolation-level defaults hold
across engines. Recognizing these in real code is the practical skill
this whole module has been building toward.

## 14. Practice Challenges

1. Identify which anti-pattern (4.1–4.7) best describes: "our nightly
   job updates all 50,000 employee records in one transaction, and
   application traffic times out during the run." Propose a fix.
2. Identify which anti-pattern best describes: "we deploy the same
   ORM-generated code against MySQL in staging and PostgreSQL in
   production, and started seeing occasional stale-read bugs only in
   production." Propose a fix.
3. Write a short code review comment (2–3 sentences) flagging §4.6's
   anti-pattern in a hypothetical pull request, referencing the
   specific fix from Lesson 03.

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 15. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB and the ACID Model](https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html)
- MySQL 8.4 Reference Manual — [InnoDB Deadlocks](https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlocks.html)

---

**Previous:** [Lesson 05 — MVCC](./05_MVCC.md) · **Next:** [Lesson 07 — Transaction Design Workflow](./07_TRANSACTION_DESIGN_WORKFLOW.md)
