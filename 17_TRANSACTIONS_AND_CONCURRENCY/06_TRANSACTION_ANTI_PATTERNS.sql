-- ============================================================================
-- Module 17, Lesson 06 — Transaction Anti-Patterns
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- Each block shows the ANTI-PATTERN commented out (so this file is safe to
-- run top-to-bottom) followed by the FIXED version that actually executes.
-- Original values are captured before any change and restored exactly
-- afterward, rather than assumed.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 4.1 Long-held transaction around an external call — FIX: do the slow part
--     outside the transaction boundary entirely.
-- ----------------------------------------------------------------------------
-- ANTI-PATTERN (do not run — illustrative only):
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 5000 WHERE emp_id = 12;
-- -- [application code calls external payroll API here, 3+ seconds]
-- UPDATE employes SET salary = salary - 5000 WHERE dept_id = 4 ORDER BY emp_id LIMIT 1;
-- COMMIT;

-- FIXED: validate/prepare BEFORE opening the transaction, then keep the
-- transaction itself fast and self-contained:
DROP TEMPORARY TABLE IF EXISTS _l6_backup_41;
CREATE TEMPORARY TABLE _l6_backup_41 AS
SELECT emp_id, salary FROM employes WHERE emp_id = 12 OR dept_id = 4;

-- [application code calls external payroll API here, OUTSIDE any transaction]
START TRANSACTION;
UPDATE employes SET salary = salary + 5000 WHERE emp_id = 12;
UPDATE employes SET salary = salary - 5000 WHERE dept_id = 4 ORDER BY emp_id LIMIT 1;  -- ORDER BY makes LIMIT deterministic
COMMIT;
-- cleanup — restore every touched row's exact original salary:
UPDATE employes e JOIN _l6_backup_41 b ON b.emp_id = e.emp_id SET e.salary = b.salary;
DROP TEMPORARY TABLE _l6_backup_41;


-- ----------------------------------------------------------------------------
-- 4.2 Missing transaction boundaries — FIX: wrap the whole operation
-- ----------------------------------------------------------------------------
-- ANTI-PATTERN (do not run):
-- UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
-- UPDATE employes SET salary = salary * 1.02 WHERE dept_id = 4;

-- FIXED:
SET @l6_orig_dept4_name = (SELECT dept_name FROM departments WHERE dept_id = 4);
DROP TEMPORARY TABLE IF EXISTS _l6_backup_42;
CREATE TEMPORARY TABLE _l6_backup_42 AS
SELECT emp_id, salary FROM employes WHERE dept_id = 4;

START TRANSACTION;
UPDATE departments SET dept_name = 'Sales & Marketing' WHERE dept_id = 4;
UPDATE employes SET salary = salary * 1.02 WHERE dept_id = 4;
COMMIT;

-- cleanup:
START TRANSACTION;
UPDATE departments SET dept_name = @l6_orig_dept4_name WHERE dept_id = 4;
UPDATE employes e JOIN _l6_backup_42 b ON b.emp_id = e.emp_id SET e.salary = b.salary;
COMMIT;
DROP TEMPORARY TABLE _l6_backup_42;


-- ----------------------------------------------------------------------------
-- 4.3 Oversized transaction — FIX: batch by a bounded key range
-- ----------------------------------------------------------------------------
-- ANTI-PATTERN (do not run on a real table — illustrative only):
-- START TRANSACTION;
-- UPDATE employes SET salary = salary * 1.03;  -- every row, one giant transaction
-- COMMIT;

-- FIXED: batch by dept_id, one small transaction per batch
DROP TEMPORARY TABLE IF EXISTS _l6_backup_43;
CREATE TEMPORARY TABLE _l6_backup_43 AS
SELECT emp_id, salary FROM employes WHERE dept_id IN (1, 2);

START TRANSACTION;
UPDATE employes SET salary = salary * 1.03 WHERE dept_id = 1;
COMMIT;

START TRANSACTION;
UPDATE employes SET salary = salary * 1.03 WHERE dept_id = 2;
COMMIT;
-- (repeat per dept_id — each transaction is short-lived and bounded in scope)

-- cleanup:
UPDATE employes e JOIN _l6_backup_43 b ON b.emp_id = e.emp_id SET e.salary = b.salary;
DROP TEMPORARY TABLE _l6_backup_43;


-- ----------------------------------------------------------------------------
-- 4.6 Read-then-write without atomicity — FIX: single atomic statement
-- ----------------------------------------------------------------------------
-- ANTI-PATTERN (do not run — illustrative; this is the classic lost-update race):
-- SELECT quantity FROM inventory WHERE product_id = 55;
-- -- (application checks quantity > 0 in code, time passes)
-- UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 55;

-- FIXED: guard condition inside the UPDATE itself, atomically
-- (using employes.salary as a stand-in numeric column for this schema)
SET @l6_orig_salary_12b = (SELECT salary FROM employes WHERE emp_id = 12);

UPDATE employes
SET salary = salary - 1
WHERE emp_id = 12
  AND salary >= 1;
SELECT ROW_COUNT();   -- 0 = guard failed safely; 1 = succeeded atomically

-- cleanup:
UPDATE employes SET salary = @l6_orig_salary_12b WHERE emp_id = 12;
