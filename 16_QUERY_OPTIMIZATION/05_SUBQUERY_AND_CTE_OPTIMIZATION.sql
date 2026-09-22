-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : Subquery and CTE Optimization
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Compare IN / EXISTS / correlated subquery / window function approaches
--   to the same HR reporting questions.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CASE 1: "departments with at least one employee hired in the last 30 days"
-- ----------------------------------------------------------------------------

-- VERSION A: IN
SELECT dept_name
FROM departments d
WHERE d.dept_id IN (
    SELECT e.dept_id
    FROM employes e
    WHERE e.hire_date > CURRENT_DATE - INTERVAL 30 DAY
);

-- VERSION B: EXISTS (recommended default)
SELECT dept_name
FROM departments d
WHERE EXISTS (
    SELECT 1
    FROM employes e
    WHERE e.dept_id = d.dept_id
      AND e.hire_date > CURRENT_DATE - INTERVAL 30 DAY
);

-- VERSION C: JOIN + DISTINCT (also valid, sometimes clearer downstream)
SELECT DISTINCT d.dept_name
FROM departments d
JOIN employes e ON e.dept_id = d.dept_id
WHERE e.hire_date > CURRENT_DATE - INTERVAL 30 DAY;

-- EXECUTION PLAN DISCUSSION
-- Run EXPLAIN ANALYZE on all three. On a modern optimizer (PostgreSQL 12+,
-- MySQL 8+), expect Versions A and B to converge to a nearly identical
-- semi-join plan. Version C additionally requires a DISTINCT/dedup step
-- that A and B don't need -- worth confirming whether that step shows up
-- as a real added cost in your EXPLAIN output.

-- ----------------------------------------------------------------------------
-- CASE 2: the NOT IN / NULL trap
-- ----------------------------------------------------------------------------

-- DANGEROUS VERSION -- returns ZERO rows if manager_id contains any NULL,
-- because `x NOT IN (a, b, NULL)` evaluates to UNKNOWN for every row, not
-- TRUE, due to three-valued logic.
SELECT emp_name
FROM employes
WHERE emp_id NOT IN (SELECT manager_id FROM employes);
-- (manager_id is NULL for top-level managers in this schema -- see 00_Schema)

-- CORRECT / SAFE VERSION
SELECT e.emp_name
FROM employes e
WHERE NOT EXISTS (
    SELECT 1 FROM employes m WHERE m.manager_id = e.emp_id
);

-- INTERVIEW INSIGHT
-- This is one of the most common real production bugs in SQL codebases:
-- a NOT IN filter that silently returns nothing (or the wrong rows) the
-- moment a NULL enters the subquery's column, often long after the query
-- was written and "tested" against NULL-free sample data.

-- ----------------------------------------------------------------------------
-- CASE 3: correlated subquery vs. window function for per-group ranking
-- ----------------------------------------------------------------------------

-- CORRELATED SUBQUERY VERSION (harder to optimize, re-evaluated per row
-- in engines that can't rewrite it)
SELECT
    e.emp_name,
    e.dept_id,
    (SELECT COUNT(*)
     FROM employes e2
     WHERE e2.dept_id = e.dept_id
       AND e2.hire_date <= e.hire_date) AS hire_rank
FROM employes e;

-- WINDOW FUNCTION VERSION (recommended -- see Module 07)
SELECT
    e.emp_name,
    e.dept_id,
    RANK() OVER (PARTITION BY e.dept_id ORDER BY e.hire_date) AS hire_rank
FROM employes e;

-- PERFORMANCE COMPARISON
-- Run EXPLAIN ANALYZE on both against a department with many employees.
-- The window function version should show a single Sort + WindowAgg pass;
-- the correlated version may show a much higher estimated cost tied to
-- repeated per-row subquery evaluation, depending on your engine's ability
-- to rewrite it.

-- ----------------------------------------------------------------------------
-- CASE 4: CTE inlining check
-- ----------------------------------------------------------------------------
EXPLAIN
WITH fraud_dept AS (
    SELECT dept_id FROM departments WHERE dept_name = 'Fraud Review'
)
SELECT e.emp_name
FROM employes e
JOIN fraud_dept fd ON e.dept_id = fd.dept_id;

-- Compare against the equivalent plain subquery form:
EXPLAIN
SELECT e.emp_name
FROM employes e
JOIN (
    SELECT dept_id FROM departments WHERE dept_name = 'Fraud Review'
) AS fd
    ON e.dept_id = fd.dept_id;

-- On PostgreSQL 12+, these should produce identical plans (the CTE is
-- inlined by default since it's referenced only once and isn't recursive).

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Force materialization with `WITH fraud_dept AS MATERIALIZED (...)` on
--    PostgreSQL and compare the plan to the inlined version.
-- 2. Populate employes.manager_id with at least one NULL and confirm the
--    NOT IN version above returns zero rows while NOT EXISTS returns the
--    correct set.
