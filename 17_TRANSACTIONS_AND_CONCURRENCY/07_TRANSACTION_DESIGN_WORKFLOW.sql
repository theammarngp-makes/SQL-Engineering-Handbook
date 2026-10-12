-- ============================================================================
-- Module 17, Lesson 07 — Transaction Design Workflow
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Worked example from the lesson: promotion = salary UPDATE as one atomic unit
-- (promotion_history table is illustrative only — not part of 00_Schema)
-- ----------------------------------------------------------------------------
SET @l7_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);

START TRANSACTION;
UPDATE employes SET salary = @l7_orig_salary_12 + 7000 WHERE emp_id = 12;
-- INSERT INTO promotion_history (emp_id, new_salary, effective_date)
-- VALUES (12, @l7_orig_salary_12 + 7000, CURRENT_DATE);
COMMIT;

-- cleanup:
UPDATE employes SET salary = @l7_orig_salary_12 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- Practice Challenge 1 scaffold — department transfer with concurrent batch job
-- Step 3 check: is the new department assignment a direct SET, or computed
-- from a prior read? If computed, this needs FOR UPDATE or an atomic statement.
-- ----------------------------------------------------------------------------
SET @l7_orig_dept_12 = (SELECT dept_id FROM employes WHERE emp_id = 12);

START TRANSACTION;
SELECT dept_id FROM employes WHERE emp_id = 12 FOR UPDATE;  -- Step 3: locking read,
                                                              -- because a concurrent HR
                                                              -- batch job (Step 2) might
                                                              -- also target this row
UPDATE employes SET dept_id = 7 WHERE emp_id = 12;
COMMIT;

-- cleanup:
UPDATE employes SET dept_id = @l7_orig_dept_12 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- Practice Challenge 2 scaffold — nightly company-wide raise, batched
-- (Step 1/7 risk: Lesson 06 §4.3 oversized transaction if run as ONE statement
-- with no WHERE; fix is the same per-department batching shown in Lesson 06)
-- ----------------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS _l7_backup_challenge2;
CREATE TEMPORARY TABLE _l7_backup_challenge2 AS
SELECT emp_id, salary FROM employes WHERE dept_id IN (1, 2);

START TRANSACTION;
UPDATE employes SET salary = salary * 1.02 WHERE dept_id = 1;
COMMIT;

START TRANSACTION;
UPDATE employes SET salary = salary * 1.02 WHERE dept_id = 2;
COMMIT;
-- (repeat per dept_id)

-- cleanup:
UPDATE employes e JOIN _l7_backup_challenge2 b ON b.emp_id = e.emp_id SET e.salary = b.salary;
DROP TEMPORARY TABLE _l7_backup_challenge2;


-- ----------------------------------------------------------------------------
-- Practice Challenge 3 — example code-comment style for a non-default isolation level
-- ----------------------------------------------------------------------------
-- Example comment (not SQL) to place directly above a transaction boundary:
--
-- -- ISOLATION: SERIALIZABLE (non-default) — required here because this
-- -- transaction validates a cross-row invariant (total department headcount
-- -- must not exceed budgeted_headcount) that only SERIALIZABLE's phantom-safe
-- -- locking guarantees under concurrent inserts from multiple hiring flows.
-- -- Do not relax to REPEATABLE READ without re-verifying this invariant.
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
SELECT COUNT(*) FROM employes WHERE dept_id = 4;
-- (application-level check against a budgeted headcount would occur here)
COMMIT;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- restore default
