-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 02: MULTI-ROW SUBQUERIES
-- File: 02_MULTI_ROW_SUBQUERIES.sql
-- Description: Multi-row set matching with IN, ANY, ALL operators and
--              demonstration of the NULL trap in NOT IN queries.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Multi-Row IN Subquery (Unnested to Hash Semi Join)
-- Problem: Retrieve all employees working in departments located in 'Nagpur' or 'Pune'.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id
FROM employes e
WHERE e.dept_id IN (
    SELECT d.dept_id
    FROM departments d
    JOIN locations l ON d.location_id = l.location_id
    WHERE l.city IN ('Nagpur', 'Pune')
)
ORDER BY e.emp_id;


-- ----------------------------------------------------------------------------
-- Scenario 2: Quantified Operator ANY (> ANY)
-- Problem: Find employees hired after AT LEAST ONE employee in Department 1.
-- Equivalent to: hire_date > MIN(hire_date of Dept 1).
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.hire_date,
    e.dept_id
FROM employes e
WHERE e.hire_date > ANY (
    SELECT d_emp.hire_date
    FROM employes d_emp
    WHERE d_emp.dept_id = 1
)
ORDER BY e.hire_date ASC;


-- ----------------------------------------------------------------------------
-- Scenario 3: Quantified Operator ALL (> ALL)
-- Problem: Find employees hired after ALL employees in Department 1.
-- Equivalent to: hire_date > MAX(hire_date of Dept 1).
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.hire_date,
    e.dept_id
FROM employes e
WHERE e.hire_date > ALL (
    SELECT d_emp.hire_date
    FROM employes d_emp
    WHERE d_emp.dept_id = 1
)
ORDER BY e.hire_date ASC;


-- ----------------------------------------------------------------------------
-- Scenario 4: Defensive NOT IN Pattern vs NULL Trap
-- Problem: Retrieve departments that currently have NO assigned employees.
-- Defensive: Must explicitly add IS NOT NULL filter on subquery.
-- ----------------------------------------------------------------------------

SELECT 
    d.dept_id,
    d.dept_name
FROM departments d
WHERE d.dept_id NOT IN (
    SELECT e.dept_id
    FROM employes e
    WHERE e.dept_id IS NOT NULL  -- Critical defensive filter!
)
ORDER BY d.dept_id;
