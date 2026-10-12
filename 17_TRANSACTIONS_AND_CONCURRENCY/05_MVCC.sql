-- ============================================================================
-- Module 17, Lesson 05 — MVCC (Multi-Version Concurrency Control)
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- Every demo below is safe to run top-to-bottom in ONE connection. Every
-- "SESSION B" block is shown commented out as a copy-paste reference —
-- paste it into a SECOND connection at the point shown to actually see
-- the snapshot behavior. Running it inline in the same connection would
-- just merge both into one transaction and would NOT demonstrate MVCC.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Snapshot demo — plain SELECT does NOT see a concurrent committed change
-- ----------------------------------------------------------------------------
SET @l5_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);

-- SESSION A:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;   -- snapshot established here

-- SESSION B (paste into a SECOND connection):
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 13000 WHERE emp_id = 12;
-- COMMIT;

-- back in SESSION A (same open transaction):
SELECT salary FROM employes WHERE emp_id = 12;   -- STILL the snapshot value — MVCC snapshot held
COMMIT;

-- a NEW transaction would now see the change (if Session B ran):
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;
COMMIT;

-- cleanup (only needed if you ran the commented Session B block above):
UPDATE employes SET salary = @l5_orig_salary_12 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 2. Contrast: a locking read DOES see the latest committed version
-- ----------------------------------------------------------------------------
SET @l5_orig_salary_12b = (SELECT salary FROM employes WHERE emp_id = 12);

-- SESSION A:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12;                 -- plain read, snapshot set

-- SESSION B (paste into a SECOND connection):
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 14000 WHERE emp_id = 12;
-- COMMIT;

-- back in SESSION A (same open transaction):
SELECT salary FROM employes WHERE emp_id = 12;                 -- STILL shows the pre-B value
SELECT salary FROM employes WHERE emp_id = 12 FOR UPDATE;      -- would show the latest committed value
COMMIT;

-- cleanup (only needed if you ran the commented Session B block above):
UPDATE employes SET salary = @l5_orig_salary_12b WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 3. Inspecting undo log / history list activity
-- ----------------------------------------------------------------------------
SHOW ENGINE INNODB STATUS\G
-- Look under TRANSACTIONS for "History list length" — grows with
-- unpurgeable undo log entries; check alongside:
SELECT trx_id, trx_started, trx_mysql_thread_id, trx_query
FROM information_schema.INNODB_TRX
ORDER BY trx_started;
-- A long-running open transaction here, combined with active writes
-- elsewhere, is a common cause of a steadily growing history list length.
