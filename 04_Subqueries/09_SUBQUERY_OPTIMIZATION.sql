-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 09: SUBQUERY OPTIMIZATION & DECORRELATION
-- File: 09_SUBQUERY_OPTIMIZATION.sql
-- Description: Demonstrates optimizer decorrelation, predicate pushdown,
--              and session GUC parameter tuning.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Automatic Optimizer Unnesting (IN -> Hash Semi Join)
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    e.emp_id,
    e.emp_name
FROM employes e
WHERE e.dept_id IN (
    SELECT d.dept_id
    FROM departments d
    WHERE d.location_id = 1
);


-- ----------------------------------------------------------------------------
-- Scenario 2: Blocked Unnesting due to Volatile Function
-- Demonstrates how RANDOM() prevents subquery decorrelation.
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    e.emp_id,
    e.emp_name
FROM employes e
WHERE e.dept_id = (
    SELECT d.dept_id
    FROM departments d
    WHERE d.location_id = (SELECT FLOOR(RANDOM() * 5 + 1)::INT)
);


-- ----------------------------------------------------------------------------
-- Scenario 3: Manual Work_Mem Tuning for Heavy Subquery Hash Tables
-- ----------------------------------------------------------------------------

-- Increase session work_mem to allow subquery hash tables to remain in RAM
SET LOCAL work_mem = '64MB';

SELECT 
    d.dept_name,
    sub.emp_count
FROM departments d
JOIN (
    SELECT dept_id, COUNT(*) AS emp_count
    FROM employes
    GROUP BY dept_id
) sub ON d.dept_id = sub.dept_id;

RESET work_mem;
