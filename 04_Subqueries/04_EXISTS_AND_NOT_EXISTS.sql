-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 04: EXISTS & NOT EXISTS
-- File: 04_EXISTS_AND_NOT_EXISTS.sql
-- Description: Production-grade Semi-Join (EXISTS) and Anti-Join (NOT EXISTS)
--              queries demonstrating short-circuit evaluation and NULL immunity.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Correlated EXISTS (Semi-Join)
-- Problem: Retrieve all departments that have AT LEAST ONE assigned employee.
-- Guarantee: Prevents department duplicate rows without needing DISTINCT.
-- ----------------------------------------------------------------------------

SELECT 
    d.dept_id,
    d.dept_name,
    d.location_id
FROM departments d
WHERE EXISTS (
    SELECT 1 
    FROM employes e
    WHERE e.dept_id = d.dept_id
)
ORDER BY d.dept_id;


-- ----------------------------------------------------------------------------
-- Scenario 2: Correlated NOT EXISTS (Anti-Join)
-- Problem: Retrieve all departments that currently have ZERO assigned employees.
-- Guarantee: 100% immune to NULL values in employes.dept_id.
-- ----------------------------------------------------------------------------

SELECT 
    d.dept_id,
    d.dept_name,
    d.location_id
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 
    FROM employes e
    WHERE e.dept_id = d.dept_id
)
ORDER BY d.dept_id;


-- ----------------------------------------------------------------------------
-- Scenario 3: Complex Multi-Table Correlated EXISTS
-- Problem: Find employees whose department is located in 'Nagpur' AND who
--          report to a manager whose department is located in 'Mumbai'.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.manager_id
FROM employes e
WHERE EXISTS (
    SELECT 1
    FROM departments d_emp
    JOIN locations l_emp ON d_emp.location_id = l_emp.location_id
    WHERE d_emp.dept_id = e.dept_id
      AND l_emp.city = 'Nagpur'
)
AND EXISTS (
    SELECT 1
    FROM employes mgr
    JOIN departments d_mgr ON mgr.dept_id = d_mgr.dept_id
    JOIN locations l_mgr ON d_mgr.location_id = l_mgr.location_id
    WHERE mgr.emp_id = e.manager_id
      AND l_mgr.city = 'Mumbai'
)
ORDER BY e.emp_id;


-- ----------------------------------------------------------------------------
-- Scenario 4: EXPLAIN Plan Inspection — Verifying Hash Anti Join
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    d.dept_id,
    d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 
    FROM employes e
    WHERE e.dept_id = d.dept_id
);
