-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 05: IN, ANY, AND ALL OPERATORS
-- File: 05_IN_AND_ANY_ALL.sql
-- Description: Quantified comparison operators (> ANY, > ALL, = ANY, <> ALL)
--              and mathematical equivalence demonstrations.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Quantified Operator = ANY (Syntactic Equivalent of IN)
-- Problem: Retrieve employees working in departments located in 'Nagpur'.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id
FROM employes e
WHERE e.dept_id = ANY (
    SELECT d.dept_id
    FROM departments d
    JOIN locations l ON d.location_id = l.location_id
    WHERE l.city = 'Nagpur'
)
ORDER BY e.emp_id;


-- ----------------------------------------------------------------------------
-- Scenario 2: Quantified Operator > ANY vs MIN() Aggregate Rewrite
-- Problem: Retrieve employees hired after AT LEAST ONE employee in Department 1.
-- Demonstrates optimizer equivalence.
-- ----------------------------------------------------------------------------

-- Pattern A: > ANY
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date > ANY (
    SELECT d_emp.hire_date FROM employes d_emp WHERE d_emp.dept_id = 1
);

-- Pattern B: Equivalent MIN() Aggregate Rewrite (Index Min/Max Friendly)
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date > (
    SELECT MIN(d_emp.hire_date) FROM employes d_emp WHERE d_emp.dept_id = 1
);


-- ----------------------------------------------------------------------------
-- Scenario 3: Quantified Operator > ALL vs MAX() Aggregate Rewrite
-- Problem: Retrieve employees hired after ALL employees in Department 1.
-- ----------------------------------------------------------------------------

-- Pattern A: > ALL
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date > ALL (
    SELECT d_emp.hire_date FROM employes d_emp WHERE d_emp.dept_id = 1
);

-- Pattern B: Equivalent MAX() Aggregate Rewrite
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date > (
    SELECT MAX(d_emp.hire_date) FROM employes d_emp WHERE d_emp.dept_id = 1
);


-- ----------------------------------------------------------------------------
-- Scenario 4: EXPLAIN Plan Inspection — Comparing ANY vs Aggregate Rewrite
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date > ANY (
    SELECT d_emp.hire_date FROM employes d_emp WHERE d_emp.dept_id = 1
);
