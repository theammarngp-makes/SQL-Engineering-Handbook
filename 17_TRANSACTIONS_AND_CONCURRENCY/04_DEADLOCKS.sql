-- ============================================================================
-- Module 17, Lesson 04 — Deadlocks
-- Dialect: MySQL 8.x / 8.4 (InnoDB)
-- Dependencies: 00_Schema (employes, departments, locations)
-- Block 1 genuinely requires two INTERLEAVED connections to reproduce the
-- deadlock — the Session B steps are shown commented out as a copy-paste
-- reference for a second terminal, timed as the inline comments describe.
-- Block 2 is safe to run top-to-bottom in one connection (it demonstrates
-- the ABSENCE of a deadlock, which holds whether or not it's truly
-- concurrent), but is written the same way for consistency.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Reproduce the classic deadlock (requires two sessions, timed together)
-- ----------------------------------------------------------------------------
-- Precondition: both departments must exist (expect 2 rows), otherwise the
-- UPDATEs below match nothing and no locks are taken:
SELECT dept_id FROM departments WHERE dept_id IN (4, 7);
SET @l4_orig_dept4_name = (SELECT dept_name FROM departments WHERE dept_id = 4);
SET @l4_orig_dept7_name = (SELECT dept_name FROM departments WHERE dept_id = 7);

-- SESSION A (this connection):
START TRANSACTION;
UPDATE departments SET dept_name = 'A1' WHERE dept_id = 4;
-- pause here — switch to a SECOND connection and run the Session B block below

-- SESSION B (paste into a SECOND connection while Session A is paused above):
-- START TRANSACTION;
-- UPDATE departments SET dept_name = 'B1' WHERE dept_id = 7;
-- -- this succeeds immediately (dept_id=7 not yet locked by anyone)
-- UPDATE departments SET dept_name = 'B2' WHERE dept_id = 4;
-- -- this BLOCKS — Session A holds the lock on dept_id=4

-- back in SESSION A, continue (only after Session B above is blocked and waiting):
UPDATE departments SET dept_name = 'A2' WHERE dept_id = 7;
-- MySQL's deadlock detector identifies the cycle almost immediately.
-- ONE of the two sessions receives:
-- ERROR 1213 (40001): Deadlock found when trying to get lock;
-- try restarting transaction
-- The OTHER session's blocked statement then completes normally.

-- Whichever session did NOT get the error, issue in THAT session:
COMMIT;

-- View the deadlock detail (either connection):
SHOW ENGINE INNODB STATUS\G   -- \G is a mysql command-line client feature; other clients use a plain ;
-- Look for the "LATEST DETECTED DEADLOCK" section.

-- cleanup — restore the captured original names (run in either connection):
UPDATE departments SET dept_name = @l4_orig_dept4_name WHERE dept_id = 4;
UPDATE departments SET dept_name = @l4_orig_dept7_name WHERE dept_id = 7;


-- ----------------------------------------------------------------------------
-- 2. Practice Challenge 2 — fix it with consistent lock ordering
-- ----------------------------------------------------------------------------
SET @l4_orig_dept4_name_b = (SELECT dept_name FROM departments WHERE dept_id = 4);
SET @l4_orig_dept7_name_b = (SELECT dept_name FROM departments WHERE dept_id = 7);

-- For a genuine concurrent test, run SESSION A and SESSION B in two separate,
-- interleaved connections exactly like Block 1's timing. Both transactions
-- below now lock the LOWER dept_id first, regardless of "direction" — no
-- deadlock occurs even under real concurrent interleaving.

-- SESSION A (business intent: "A1" first, "A2" second — LOCK ORDER is dept 4 then 7):
START TRANSACTION;
UPDATE departments SET dept_name = 'A1' WHERE dept_id = 4;   -- lower id first
UPDATE departments SET dept_name = 'A2' WHERE dept_id = 7;   -- higher id second
COMMIT;

-- SESSION B (paste into a SECOND connection; business intent: "B1" first, "B2"
-- second — LOCK ORDER still dept 4 then 7, even though the business labels
-- are reversed from Session A's):
-- START TRANSACTION;
-- UPDATE departments SET dept_name = 'B1' WHERE dept_id = 4;   -- lower id first
-- UPDATE departments SET dept_name = 'B2' WHERE dept_id = 7;   -- higher id second
-- COMMIT;

-- Whichever session runs second simply WAITS for the first to commit —
-- no cycle can form because both always request dept_id=4 before dept_id=7.

-- cleanup:
UPDATE departments SET dept_name = @l4_orig_dept4_name_b WHERE dept_id = 4;
UPDATE departments SET dept_name = @l4_orig_dept7_name_b WHERE dept_id = 7;


-- ----------------------------------------------------------------------------
-- 3. Diagnostics
-- ----------------------------------------------------------------------------
SHOW VARIABLES LIKE 'innodb_deadlock_detect';
SHOW VARIABLES LIKE 'innodb_print_all_deadlocks';

-- Temporarily log EVERY deadlock (not just the latest) to the error log.
-- Needs a privileged account (SYSTEM_VARIABLES_ADMIN / SUPER). Capture the
-- current value first and restore it afterwards:
SET @l4_orig_print_all = @@GLOBAL.innodb_print_all_deadlocks;
SET GLOBAL innodb_print_all_deadlocks = ON;
-- ... reproduce a deadlock, then check the MySQL error log ...
SET GLOBAL innodb_print_all_deadlocks = @l4_orig_print_all;   -- restore
