-- ============================================================================
-- Module 17, Lesson 01 — ACID & Transaction Fundamentals
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- Every demo below is safe to run top-to-bottom in ONE connection: any
-- "SESSION B" / second-connection step is shown commented out as a
-- copy-paste reference — paste it into a SECOND terminal yourself to see
-- the actual cross-session behavior. Every live statement that commits a
-- change captures the original value first and restores it afterward, so
-- this file never depends on guessing what your copy of 00_Schema's seed
-- data actually contains.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Preconditions this file depends on (run first; do not continue if a
--    check returns fewer rows than expected)
-- ----------------------------------------------------------------------------
SELECT emp_id, dept_id FROM employes WHERE emp_id = 12;           -- expect 1 row
SELECT dept_id FROM departments WHERE dept_id IN (4, 7);          -- expect 2 rows

-- ----------------------------------------------------------------------------
-- 1. Baseline: confirm the engine actually supports transactions
-- ----------------------------------------------------------------------------
SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('employes', 'departments', 'locations');
-- Expected: ENGINE = InnoDB for all three. If any show MyISAM,
-- transactions against that table will not behave as this lesson describes.


-- ----------------------------------------------------------------------------
-- 2. Atomicity — explicit transaction, explicit rollback (no cleanup needed:
--    this block ends in ROLLBACK, so nothing is ever actually committed)
-- ----------------------------------------------------------------------------
START TRANSACTION;

UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
SELECT ROW_COUNT();                          -- 1 row affected

UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 99;
SELECT ROW_COUNT();                          -- 0 rows affected, no error raised

-- Nothing has been made permanent yet. Confirm from a second session:
--   SELECT dept_name FROM departments WHERE dept_id = 4;
-- still shows the OLD name, because this transaction hasn't committed.

ROLLBACK;                                    -- discards the dept_id=4 change too

SELECT dept_name FROM departments WHERE dept_id = 4;  -- back to original name


-- ----------------------------------------------------------------------------
-- 3. Consistency — a foreign key blocks an invalid state (no cleanup needed:
--    the INSERT never succeeds, so ROLLBACK has nothing to undo)
-- ----------------------------------------------------------------------------
-- This demo needs a foreign key on employes.manager_id. Check it exists
-- (expect one row naming REFERENCED_TABLE_NAME = 'employes'):
SELECT CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'employes'
  AND COLUMN_NAME = 'manager_id' AND REFERENCED_TABLE_NAME IS NOT NULL;
-- If that returns no rows, your copy of 00_Schema has no such constraint
-- and the INSERT below will SUCCEED instead of failing; it is still
-- rolled back by the ROLLBACK at the end of this block.

START TRANSACTION;

-- manager_id 88888 does not exist in employes.emp_id (dept_id is reused
-- from emp 12, so the only invalid value is the manager):
INSERT INTO employes (emp_id, emp_name, dept_id, manager_id, hire_date, salary)
SELECT 9001, 'Test Employee', dept_id, 88888, '2024-01-15', 50000.00
FROM employes WHERE emp_id = 12;
-- Expected (with the FK): ERROR 1452 (23000): Cannot add or update a
-- child row: a foreign key constraint fails

ROLLBACK;  -- nothing to commit; the INSERT above never succeeded


-- ----------------------------------------------------------------------------
-- 4. Isolation — the live statements below are SESSION A only. Paste the
--    commented SESSION B block into a SECOND connection at the point shown
--    to actually observe the cross-session behavior.
-- ----------------------------------------------------------------------------
SET @l1_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);

-- SESSION A:
START TRANSACTION;
UPDATE employes SET salary = @l1_orig_salary_12 + 7000 WHERE emp_id = 12;
-- do NOT commit yet — leave this session open and switch to a second
-- connection to run the block below before continuing here

-- SESSION B (paste into a SECOND connection, while Session A is paused above):
-- START TRANSACTION;
-- SELECT salary FROM employes WHERE emp_id = 12;
-- -- Expected under MySQL's default REPEATABLE READ: the ORIGINAL salary
-- -- value, not orig+7000 — Session B does not see Session A's uncommitted change.
-- COMMIT;

-- back in SESSION A:
COMMIT;
-- A NEW query in Session B (a fresh SELECT, new transaction) would now see orig+7000.

-- cleanup — restore the captured original value:
UPDATE employes SET salary = @l1_orig_salary_12 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 5. Durability — nothing to "run" here beyond the COMMIT itself; the point
--    is conceptual (see lesson §5.4). This block just shows the syntax.
-- ----------------------------------------------------------------------------
SET @l1_orig_salary_12b = (SELECT salary FROM employes WHERE emp_id = 12);

START TRANSACTION;
UPDATE employes SET salary = @l1_orig_salary_12b + 1 WHERE emp_id = 12;
COMMIT;
-- Once this COMMIT returns successfully, the change is durable —
-- it survives a crash the instant after, by design of InnoDB's redo log.

-- cleanup:
UPDATE employes SET salary = @l1_orig_salary_12b WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 6. SAVEPOINT — partial rollback within one transaction
-- ----------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS _l1_savepoint_backup;
CREATE TEMPORARY TABLE _l1_savepoint_backup AS
SELECT emp_id, salary FROM employes WHERE dept_id = 4;

START TRANSACTION;

UPDATE employes SET salary = salary * 1.05 WHERE dept_id = 4;
SELECT ROW_COUNT();

SAVEPOINT before_bonus;

UPDATE employes SET salary = salary + 5000 WHERE emp_id = 12;
SELECT ROW_COUNT();

ROLLBACK TO SAVEPOINT before_bonus;   -- undoes ONLY the bonus UPDATE

COMMIT;                                -- the 5% raise above IS committed

-- cleanup — restore every affected row's exact original salary:
UPDATE employes e
JOIN _l1_savepoint_backup b ON b.emp_id = e.emp_id
SET e.salary = b.salary;
DROP TEMPORARY TABLE _l1_savepoint_backup;


-- ----------------------------------------------------------------------------
-- 7. Autocommit — two unwrapped statements are two independent transactions
-- ----------------------------------------------------------------------------
SELECT @@autocommit;   -- 1 (ON) by default

SET @l1_orig_dept4_name = (SELECT dept_name FROM departments WHERE dept_id = 4);

-- Run these as two SEPARATE statements, no START TRANSACTION around them:
UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
-- ^ already committed permanently the instant this line finished

UPDATE departments SET dept_name = 'Sales & Marketing Ops' WHERE dept_id = 999;
-- ^ affects 0 rows (dept_id 999 doesn't exist); no error, and the FIRST
-- update above is NOT rolled back — it was already independently committed.

-- cleanup — restore the captured original name:
UPDATE departments SET dept_name = @l1_orig_dept4_name WHERE dept_id = 4;


-- ----------------------------------------------------------------------------
-- 8. Implicit commit before DDL — demonstrate, then clean up
-- ----------------------------------------------------------------------------
SET @l1_orig_salary_12c = (SELECT salary FROM employes WHERE emp_id = 12);

START TRANSACTION;
UPDATE employes SET salary = @l1_orig_salary_12c + 9000 WHERE emp_id = 12;
-- This next statement causes MySQL to implicitly COMMIT the UPDATE above
-- BEFORE creating the table — the UPDATE is now permanent, un-rollback-able:
CREATE TABLE IF NOT EXISTS _lesson01_scratch (id INT);
ROLLBACK;  -- has NOTHING left to roll back — the UPDATE already committed

SELECT salary FROM employes WHERE emp_id = 12;  -- shows orig+9000, NOT rolled back

-- cleanup:
DROP TABLE IF EXISTS _lesson01_scratch;
UPDATE employes SET salary = @l1_orig_salary_12c WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 9. Practice Challenge 1 — conditional commit based on a computed check
-- ----------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS _l1_practice_backup;
CREATE TEMPORARY TABLE _l1_practice_backup AS
SELECT emp_id, salary FROM employes WHERE dept_id = 4;

START TRANSACTION;

UPDATE employes SET salary = salary * 1.10 WHERE dept_id = 4;

-- Check the result BEFORE deciding to commit or roll back:
SELECT AVG(salary) AS new_avg FROM employes WHERE dept_id = 4;

-- In your OWN session, manually inspect new_avg here, then issue ONE of:
--   COMMIT;    -- if new_avg < 95000.00
--   ROLLBACK;  -- if new_avg >= 95000.00
-- This script itself closes with ROLLBACK below so the file stays safe to
-- run top-to-bottom without permanently applying a decision that depends
-- on YOUR actual data:
ROLLBACK;

DROP TEMPORARY TABLE _l1_practice_backup;
