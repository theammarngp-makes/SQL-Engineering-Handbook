-- ============================================================================
-- Module 17, Lesson 03 — Locking Mechanisms
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- Every demo below is safe to run top-to-bottom in ONE connection. Every
-- "SESSION B" / "SESSION C" block is shown commented out as a copy-paste
-- reference — paste it into a SECOND connection at the point shown to
-- actually see the blocking behavior.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Check lock wait timeout
-- ----------------------------------------------------------------------------
SELECT @@innodb_lock_wait_timeout;


-- ----------------------------------------------------------------------------
-- 2. SELECT ... FOR UPDATE closing a read-then-write race (two sessions)
-- ----------------------------------------------------------------------------
SET @l3_orig_salary_12 = (SELECT salary FROM employes WHERE emp_id = 12);

-- SESSION A:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12 FOR UPDATE;
-- do NOT commit yet

-- SESSION B (paste into a SECOND connection) — this BLOCKS until Session A commits/rolls back:
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 1000 WHERE emp_id = 12;
-- -- (waits here)

-- back in SESSION A:
UPDATE employes SET salary = salary + 500 WHERE emp_id = 12;
COMMIT;   -- Session B's blocked UPDATE, if run, now proceeds

-- cleanup — FIRST commit or roll back Session B (if you ran it) so its row lock is
-- released, then undo Session A's +500 and Session B's +1000:
UPDATE employes SET salary = @l3_orig_salary_12 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 3. FOR SHARE — concurrent readers coexist, writers still block
-- ----------------------------------------------------------------------------
-- SESSION A:
START TRANSACTION;
SELECT salary FROM employes WHERE emp_id = 12 FOR SHARE;

-- SESSION B (paste into a SECOND connection) — this does NOT block:
-- START TRANSACTION;
-- SELECT salary FROM employes WHERE emp_id = 12 FOR SHARE;
-- COMMIT;

-- SESSION C (paste into a THIRD connection) — this DOES block:
-- START TRANSACTION;
-- UPDATE employes SET salary = salary + 1 WHERE emp_id = 12;
-- -- (waits until Session A commits)

-- back in SESSION A:
COMMIT;
-- No data cleanup needed from THIS connection — it only read.
-- If you ran Session C's UPDATE, commit or roll it back there, then undo it yourself:
--   UPDATE employes SET salary = salary - 1 WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 4. Gap lock demo — locking a range blocks an insert into the gap
--    Requires: REPEATABLE READ, and an index on hire_date so the locked
--    range is the index range (see lesson §6, "Setup this example depends on").
-- ----------------------------------------------------------------------------
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SHOW INDEX FROM employes;   -- if an index already leads with hire_date, you may skip the next two statements
CREATE INDEX idx_l3_hire_date_demo ON employes (hire_date);   -- DDL: implicit commit, so run it outside a transaction
EXPLAIN SELECT * FROM employes
WHERE hire_date BETWEEN '2023-01-01' AND '2023-12-31' FOR UPDATE;   -- confirm key = idx_l3_hire_date_demo (or your own hire_date index)

-- SESSION A:
START TRANSACTION;
SELECT * FROM employes
WHERE hire_date BETWEEN '2023-01-01' AND '2023-12-31'
FOR UPDATE;

-- SESSION B (paste into a SECOND connection) — this BLOCKS even though no row
-- like this existed for A to lock directly:
-- START TRANSACTION;
-- INSERT INTO employes (emp_id, emp_name, dept_id, manager_id, hire_date, salary)
-- SELECT 9005, 'Gap Test', dept_id, manager_id, '2023-06-15', 60000.00
-- FROM employes WHERE emp_id = 12;   -- reuses emp 12's department and manager
-- -- (waits)

-- back in SESSION A:
COMMIT;   -- Session B's blocked INSERT, if run, now proceeds

-- cleanup — FIRST commit or roll back Session B in its own connection (its
-- INSERT holds locks until then), then run:
DELETE FROM employes WHERE emp_id = 9005;
DROP INDEX idx_l3_hire_date_demo ON employes;   -- remove the temporary index


-- ----------------------------------------------------------------------------
-- 5. Atomic single-statement alternative (no explicit locking read needed)
-- ----------------------------------------------------------------------------
SET @l3_orig_salary_12b = (SELECT salary FROM employes WHERE emp_id = 12);

-- Instead of: SELECT ... FOR UPDATE, then check in app code, then UPDATE —
-- do the check IN the UPDATE's WHERE clause when the logic allows it:
UPDATE employes
SET salary = salary - 1000
WHERE emp_id = 12
  AND salary >= 1000;   -- prevents salary going negative, atomically, no FOR UPDATE needed
SELECT ROW_COUNT();      -- 0 means the guard condition failed; 1 means it succeeded

-- cleanup:
UPDATE employes SET salary = @l3_orig_salary_12b WHERE emp_id = 12;


-- ----------------------------------------------------------------------------
-- 6. Diagnosing lock waits
-- ----------------------------------------------------------------------------
SELECT * FROM performance_schema.data_lock_waits;
SELECT * FROM performance_schema.data_locks;

SELECT trx_id, trx_started, trx_mysql_thread_id, trx_query
FROM information_schema.INNODB_TRX
ORDER BY trx_started;


-- ----------------------------------------------------------------------------
-- 7. Practice Challenge 1 — atomic vs. locking-read inventory decrement
-- ----------------------------------------------------------------------------
SET @l3_orig_salary_12c = (SELECT salary FROM employes WHERE emp_id = 12);

-- Version A: locking read + separate write
START TRANSACTION;
SELECT salary INTO @l3_current_val FROM employes WHERE emp_id = 12 FOR UPDATE;
-- application-level check of @l3_current_val would happen here
UPDATE employes SET salary = salary + 100 WHERE emp_id = 12;
COMMIT;

-- Version B: single atomic statement (preferred where the logic allows it)
UPDATE employes SET salary = salary + 100 WHERE emp_id = 12;
-- No explicit transaction needed for a single statement (autocommit, Lesson 01 §7);
-- inherently race-free because there is no separate read step to race against.

-- cleanup — both versions together added +200; restore the original value:
UPDATE employes SET salary = @l3_orig_salary_12c WHERE emp_id = 12;
