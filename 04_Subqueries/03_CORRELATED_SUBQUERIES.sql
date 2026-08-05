-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 03: CORRELATED SUBQUERIES
-- File: 03_CORRELATED_SUBQUERIES.sql
-- Description: Correlated subquery examples, row-by-row correlation mechanics,
--              and production decorrelation rewrites.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Correlated Subquery — Earliest Hired Employee per Department
-- Problem: Find the employee(s) who have the earliest hire date within THEIR OWN
--          respective department.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date
FROM employes e
WHERE e.hire_date = (
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = e.dept_id -- Outer correlation key
)
ORDER BY e.dept_id, e.emp_id;


-- ----------------------------------------------------------------------------
-- Scenario 2: Correlated Subquery with Multi-Table Joins
-- Problem: Retrieve employees whose manager is located in the same city
--          as the employee's own department.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.manager_id
FROM employes e
WHERE e.manager_id IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM employes mgr
      JOIN departments mgr_d ON mgr.dept_id = mgr_d.dept_id
      JOIN departments emp_d ON e.dept_id = emp_d.dept_id
      WHERE mgr.emp_id = e.manager_id
        AND mgr_d.location_id = emp_d.location_id -- Correlated Location Check
);


-- ----------------------------------------------------------------------------
-- Scenario 3: Decorrelated Rewrite — Derived Table Pre-Aggregation
-- Problem: Optimizing Scenario 1 to eliminate SubPlan row-by-row execution.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date
FROM employes e
JOIN (
    -- Pre-aggregate minimum hire date per department ONCE
    SELECT 
        dept_id,
        MIN(hire_date) AS min_hire_date
    FROM employes
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) dept_min 
  ON e.dept_id = dept_min.dept_id 
 AND e.hire_date = dept_min.min_hire_date
ORDER BY e.dept_id, e.emp_id;


-- ----------------------------------------------------------------------------
-- Scenario 4: EXPLAIN Plan Benchmark Comparison
-- Inspect the SubPlan node in PostgreSQL for the correlated subquery.
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id
FROM employes e
WHERE e.hire_date = (
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = e.dept_id
);
