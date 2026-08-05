-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 01: SINGLE-ROW SUBQUERIES
-- File: 01_SINGLE_ROW_SUBQUERIES.sql
-- Description: Production-grade examples demonstrating single-row subqueries,
--              scalar operators, aggregate comparisons, and defensive patterns.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Basic Single-Row Comparison against Aggregate Benchmark
-- Problem: Retrieve all employees who were hired before the earliest hiring date
--          in Department 1.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date
FROM employes e
WHERE e.hire_date < (
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = 1
)
ORDER BY e.hire_date ASC;


-- ----------------------------------------------------------------------------
-- Scenario 2: Multi-Column Defensive Single-Row Subquery
-- Problem: Find employees who report to the same manager as 'Ammar'.
-- Note: Subquery uses MIN(manager_id) to guarantee single-row return.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.manager_id
FROM employes e
WHERE e.manager_id = (
    SELECT e_inner.manager_id
    FROM employes e_inner
    WHERE e_inner.emp_name = 'Ammar'
)
  AND e.emp_name <> 'Ammar';


-- ----------------------------------------------------------------------------
-- Scenario 3: Single-Row Subquery with HAVING Clause Filtering
-- Problem: Retrieve departments whose total employee count is strictly greater
--          than the overall company-wide average employees per department.
-- ----------------------------------------------------------------------------

SELECT 
    e.dept_id,
    COUNT(e.emp_id) AS dept_headcount
FROM employes e
WHERE e.dept_id IS NOT NULL
GROUP BY e.dept_id
HAVING COUNT(e.emp_id) > (
    SELECT COUNT(e_all.emp_id)::NUMERIC / COUNT(DISTINCT e_all.dept_id)
    FROM employes e_all
    WHERE e_all.dept_id IS NOT NULL
)
ORDER BY dept_headcount DESC;


-- ----------------------------------------------------------------------------
-- Scenario 4: EXPLAIN Plan Inspection Query
-- Run this query in PostgreSQL to inspect the InitPlan cost node.
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id
FROM employes e
WHERE e.dept_id = (
    SELECT d.dept_id
    FROM departments d
    WHERE d.dept_name = 'Data Analytics'
);
