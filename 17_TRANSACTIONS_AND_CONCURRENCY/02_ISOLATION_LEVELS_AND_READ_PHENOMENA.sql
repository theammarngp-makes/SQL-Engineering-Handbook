-- ============================================================================
-- Module 17, Lesson 02 — Isolation Levels & Read Phenomena
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- Every demo below is safe to run top-to-bottom in ONE connection. Every
-- "SESSION B" block is shown commented out as a copy-paste reference —
-- paste it into a SECOND connection at the point shown to actually see the
-- cross-session behavior. Running "Session B" inline in the same
-- connection as "Session A" would just merge both into one transaction
-- and would NOT demonstrate the phenomenon described.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Check current and default isolation level
-- ----------------------------------------------------------------------------
SELECT @@transaction_isolation;         -- session-level current setting
SELECT @@global.transaction_isolation;  -- server default (typically REPEATABLE-READ)


-- ----------------------------------------------------------------------------
-- 2. Dirty read demo (requires READ UNCOMMITTED — normally disallowed by default)
-- ----------------------------------------------------------------------------
-- SESSION A (this is the only live session in this block):
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- SESSION B (paste into a SECOND connection FIRST, leave its transaction open):
-- START TRANSACTION;
-- UPDATE employes SET salary = 999999.00 WHERE emp_id = 12;
-- -- do NOT commit yet

-- back in SESSION A (this connection) — with Session B's change still open elsewhere:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;   -- would see 999999.00 (uncommitted!)
COMMIT;

-- now go back to SESSION B and roll it back:
-- ROLLBACK;   -- the 999999.00 never actually existed permanently

-- SESSION A (new query, fresh transaction) would then confirm it's gone:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;   -- back to the original value
COMMIT;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- restore default
-- No data cleanup needed in THIS connection — it only ever read, never wrote.
-- (Session B's own ROLLBACK, run in the second connection, already undoes its write.)


-- ----------------------------------------------------------------------------
-- 3. Non-repeatable read demo under READ COMMITTED
-- ----------------------------------------------------------------------------
SET @l2_orig_salary_12b = (SELECT salary FROM employes WHERE emp_id = 12);

-- SESSION A:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;   -- first read

-- SESSION B (paste into a SECOND connection):
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 6000 WHERE emp_id = 12;
-- COMMIT;

-- back in SESSION A (same open transaction) — after Session B above has committed:
SELECT salary FROM employes WHERE emp_id = 12;   -- would show a DIFFERENT value — non-repeatable read
COMMIT;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- restore default

-- cleanup — restore the captured original value (only needed if you actually
-- ran the commented Session B block above in a second connection):
UPDATE employes SET salary = @l2_orig_salary_12b WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 4. Same sequence under REPEATABLE READ — should NOT show the non-repeatable read
-- ----------------------------------------------------------------------------
SET @l2_orig_salary_12c = (SELECT salary FROM employes WHERE emp_id = 12);

-- SESSION A:
START TRANSACTION;  -- REPEATABLE READ is the session default already
SELECT salary FROM employes WHERE emp_id = 12;   -- first read, snapshot established here

-- SESSION B (paste into a SECOND connection):
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 6000 WHERE emp_id = 12;
-- COMMIT;

-- back in SESSION A (same open transaction):
SELECT salary FROM employes WHERE emp_id = 12;   -- STILL the snapshot value — MVCC held it
COMMIT;

-- a NEW transaction in Session A would now see the update:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;   -- the updated value, if Session B ran
COMMIT;

-- cleanup (only needed if you ran the commented Session B block above):
UPDATE employes SET salary = @l2_orig_salary_12c WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 5. Phantom read demo under READ COMMITTED
-- ----------------------------------------------------------------------------
SET @l2_dept = (SELECT dept_id FROM employes WHERE emp_id = 12);  -- same dept used by the insert below
-- SESSION A:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT COUNT(*) AS headcount FROM employes WHERE dept_id = @l2_dept;   -- baseline count

-- SESSION B (paste into a SECOND connection):
-- START TRANSACTION;
-- INSERT INTO employes (emp_id, emp_name, dept_id, manager_id, hire_date, salary)
-- SELECT 9003, 'Phantom Hire', dept_id, manager_id, '2025-02-01', 62000.00
-- FROM employes WHERE emp_id = 12;   -- same department (and valid manager) as emp 12
-- COMMIT;

-- back in SESSION A:
SELECT COUNT(*) AS headcount FROM employes WHERE dept_id = @l2_dept;   -- one higher — phantom row appeared
COMMIT;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- cleanup (only needed if you ran the commented Session B block above):
DELETE FROM employes WHERE emp_id = 9003;


-- ----------------------------------------------------------------------------
-- 6. Same sequence under REPEATABLE READ — MySQL's MVCC prevents the phantom
--    for this plain SELECT (stronger than the SQL standard strictly requires)
-- ----------------------------------------------------------------------------
-- SESSION A:
START TRANSACTION;
SELECT COUNT(*) AS headcount FROM employes WHERE dept_id = @l2_dept;   -- baseline count

-- SESSION B (paste into a SECOND connection):
-- START TRANSACTION;
-- INSERT INTO employes (emp_id, emp_name, dept_id, manager_id, hire_date, salary)
-- SELECT 9004, 'Phantom Hire 2', dept_id, manager_id, '2025-02-02', 63000.00
-- FROM employes WHERE emp_id = 12;
-- COMMIT;

-- back in SESSION A (same transaction):
SELECT COUNT(*) AS headcount FROM employes WHERE dept_id = @l2_dept;   -- STILL the baseline — no phantom seen
COMMIT;

-- cleanup (only needed if you ran the commented Session B block above):
DELETE FROM employes WHERE emp_id = 9004;
