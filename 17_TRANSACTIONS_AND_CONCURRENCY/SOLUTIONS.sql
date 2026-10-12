-- ============================================================================
-- Module 17 — Solutions to PRACTICE_PROBLEMS.md
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Solution 1 — Atomic Transfer (Lesson 01)
-- ----------------------------------------------------------------------------
SET @sol1_orig_dept_12 = (SELECT dept_id FROM employes WHERE emp_id = 12);
SET @sol1_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);

START TRANSACTION;
UPDATE employes SET dept_id = 7 WHERE emp_id = 12;
UPDATE employes SET salary = salary + 3000 WHERE emp_id = 12;
COMMIT;
-- Explanation: both statements share one transaction boundary. If the
-- second UPDATE fails for any reason, the application must issue
-- ROLLBACK to undo the first — atomicity doesn't auto-detect that you
-- WANT both-or-nothing; it just makes both-or-nothing POSSIBLE once
-- you issue the matching COMMIT/ROLLBACK decision.

-- cleanup — restore the captured original values exactly:
START TRANSACTION;
UPDATE employes SET dept_id = @sol1_orig_dept_12, salary = @sol1_orig_salary_12
WHERE emp_id = 12;
COMMIT;


-- ----------------------------------------------------------------------------
-- Solution 2 — Isolation Level Choice (Lesson 02)
-- ----------------------------------------------------------------------------
-- Explanation (no SQL change needed): each dashboard refresh opens a NEW
-- connection, which means a NEW transaction with a NEW MVCC snapshot each
-- time. REPEATABLE READ's "stale within one transaction" behavior (Lesson
-- 02 §10, Lesson 05 §10) only matters WITHIN a single open transaction —
-- it does not apply across separate connections/transactions. So the
-- default isolation level creates NO problem here: each refresh correctly
-- sees the latest committed data as of ITS OWN new snapshot. If the
-- dashboard instead kept one connection/transaction open for the full
-- 30-second interval and re-queried within it, REPEATABLE READ WOULD show
-- stale data — the fix there would be a fresh transaction per query, which
-- this scenario already does.


-- ----------------------------------------------------------------------------
-- Solution 3 — Closing a Read-Then-Write Race (Lesson 03)
-- ----------------------------------------------------------------------------
SET @sol3_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);

UPDATE employes
SET salary = salary + 2000
WHERE emp_id = 12
  AND salary < 50000;
SELECT ROW_COUNT();   -- 1 = raise applied; 0 = guard failed (already >= 50000,
                       -- including because a concurrent run already raised it)
-- Explanation: the condition `salary < 50000` is evaluated and the write
-- applied atomically within InnoDB's row-level locking for this single
-- statement — a second concurrent run of the exact same statement against
-- the same row cannot both see salary < 50000 AND both apply the raise,
-- because the first one to acquire the row's lock commits its change
-- before the second's WHERE clause is evaluated against the row.

-- cleanup — restore the captured original value exactly (NOTE: a guarded
-- reversal like "salary - 2000 WHERE salary >= 50000" would be WRONG here —
-- it would incorrectly also modify a row that was already >= 50000 BEFORE
-- this solution ran, since the forward UPDATE's own guard would have
-- skipped that row in the first place):
UPDATE employes SET salary = @sol3_orig_salary_12 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- Solution 4 — Diagnosing a Lock Wait (Lesson 03)
-- ----------------------------------------------------------------------------
-- Explanation (no SQL fix — diagnostic steps):
-- 1. Run: SELECT * FROM information_schema.INNODB_TRX ORDER BY trx_started;
--    — confirm which transaction is the 40-minute-old one and what its
--    trx_query shows (is it even still actively running, or idle-in-transaction?).
-- 2. Run: SELECT * FROM performance_schema.data_lock_waits;
--    — see which OTHER transactions are blocked waiting on locks this
--    old transaction holds.
-- 3. The fix is almost never "increase the timeout" — it's finding why
--    that transaction has been open 40 minutes (forgotten COMMIT? a
--    long-held transaction around an external call, Lesson 06 §4.1?)
--    and addressing THAT root cause.
SELECT * FROM information_schema.INNODB_TRX ORDER BY trx_started;
SELECT * FROM performance_schema.data_lock_waits;


-- ----------------------------------------------------------------------------
-- Solution 5 — Preventing a Deadlock (Lesson 04)
-- ----------------------------------------------------------------------------
-- Explanation: "give a raise" locks employee-then-department; "rename
-- department" locks department-then-employee — this is the exact
-- opposite-order pattern from Lesson 04 §5 and will deadlock under
-- concurrent execution. FIX: pick ONE order and enforce it in BOTH
-- code paths — e.g., always lock the department row before the
-- employee row, everywhere in the codebase that touches both.

SET @sol5_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);
SET @sol5_orig_dept4_name = (SELECT dept_name FROM departments WHERE dept_id = 4);

-- "give a raise" — FIXED to lock department first, then employee:
START TRANSACTION;
SELECT dept_id FROM departments WHERE dept_id = 4 FOR UPDATE;  -- department first
UPDATE employes SET salary = salary + 2000 WHERE emp_id = 12;  -- employee second
COMMIT;

-- "rename department" — must ALSO lock department first, then employee,
-- even though this feature's natural order would be department-first anyway;
-- the point is BOTH features now agree on the same order:
START TRANSACTION;
SELECT dept_id FROM departments WHERE dept_id = 4 FOR UPDATE;  -- department first
UPDATE departments SET dept_name = 'Sales Ops' WHERE dept_id = 4;
-- (if this feature also needed to touch the employee row, it would go HERE,
--  second, matching the other feature's order)
COMMIT;

-- cleanup — restore the captured original values exactly:
UPDATE employes SET salary = @sol5_orig_salary_12 WHERE emp_id = 12;
UPDATE departments SET dept_name = @sol5_orig_dept4_name WHERE dept_id = 4;


-- ----------------------------------------------------------------------------
-- Solution 6 — MVCC Snapshot Reasoning (Lesson 05)
-- ----------------------------------------------------------------------------
-- Explanation (no SQL needed to "solve" — this is a reasoning question):
-- The second read STILL shows 80000, not 95000. Under REPEATABLE READ,
-- this transaction's MVCC snapshot was established at its FIRST read.
-- All subsequent plain reads within the SAME transaction reconstruct
-- that same snapshot-consistent version from the undo log, regardless
-- of what other transactions commit in the meantime (Lesson 05 §5).
-- A NEW transaction (fresh START TRANSACTION) would see 95000.


-- ----------------------------------------------------------------------------
-- Solution 7 — Anti-Pattern Identification (Lesson 06)
-- ----------------------------------------------------------------------------
-- Explanation: this is Lesson 06 §4.1 — a transaction held open across
-- an external call (the shipping API). Every lock this transaction holds
-- on the orders row stays held for the FULL ~2 seconds (or longer if the
-- API is slow/hangs), blocking any other session needing that row.
-- FIX: split into two short, independent transactions, with the external
-- call happening BETWEEN them, not inside either:
START TRANSACTION;
-- UPDATE orders SET status = 'processing' WHERE order_id = 501;
COMMIT;
-- [application code calls shipping API here, OUTSIDE any transaction]
START TRANSACTION;
-- UPDATE orders SET status = 'shipped' WHERE order_id = 501;
COMMIT;
-- (orders table is illustrative — not part of this handbook's 00_Schema)


-- ----------------------------------------------------------------------------
-- Solution 8 — Full Workflow Application (Lesson 07)
-- ----------------------------------------------------------------------------
-- Explanation, walking Lesson 07's 7 steps:
-- Step 1 (atomic unit): all line-item restock UPDATEs for this one order,
--   together — not more, not less.
-- Step 2 (concurrent access): yes — another process could delete the
--   product referenced by a line item at any time.
-- Step 3 (read-then-write?): checking "was this product deleted" before
--   restocking IS a read-then-write shape if done as a separate SELECT
--   then UPDATE — prefer a single statement with the check in the WHERE/
--   JOIN condition, or a FOR UPDATE read if a separate check is unavoidable.
-- Step 4 (isolation level): REPEATABLE READ (MySQL default) is sufficient;
--   no named requirement for SERIALIZABLE here.
-- Step 5 (lock ordering): if restocking multiple line items' products in
--   one transaction, lock them in a CONSISTENT order (e.g., ascending
--   product_id) to avoid deadlocking against another order's cancellation
--   restocking the same products in a different order.
-- Step 6 (failure modes): catch and retry on deadlock; if a line item's
--   product truly no longer exists, that's a logic case to handle
--   explicitly (skip that line item? abort the whole restock?), not a
--   retryable error.
-- Step 7 (anti-pattern audit): no external call in the boundary; scope is
--   bounded to one order's line items, not unbounded; boundary is explicit.

-- (inventory/order_items tables are illustrative — not part of 00_Schema.)
-- NOTE: MySQL does not allow ORDER BY or LIMIT in a multi-table UPDATE, so a
-- consistent lock order must come from a separate locking read first:
START TRANSACTION;
-- SELECT i.product_id
-- FROM inventory i
-- JOIN order_items oi ON oi.product_id = i.product_id
-- WHERE oi.order_id = 501
-- ORDER BY i.product_id          -- same ascending order in every code path
-- FOR UPDATE;                    -- locks the inventory rows in that order
--
-- UPDATE inventory i
-- JOIN order_items oi ON oi.product_id = i.product_id
-- SET i.quantity = i.quantity + oi.quantity
-- WHERE oi.order_id = 501;       -- rows are already locked; this just applies the change
COMMIT;
