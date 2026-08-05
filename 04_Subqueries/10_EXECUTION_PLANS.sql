-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 10: EXECUTION PLAN INSPECTION & EXPLAIN DEEP DIVE
-- File: 10_EXECUTION_PLANS.sql
-- Description: Production diagnostic scripts for inspecting InitPlan, SubPlan,
--              Hash Semi Join, and Hash Anti Join execution nodes in PostgreSQL.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Diagnostic 1: Inspecting InitPlan Node (Single-Row Scalar Subquery)
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS)
SELECT 
    e.emp_id,
    e.emp_name,
    e.hire_date
FROM employes e
WHERE e.hire_date < (
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = 1
);


-- ----------------------------------------------------------------------------
-- Diagnostic 2: Inspecting Hash Semi Join Node (Unnested IN Subquery)
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS)
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
-- Diagnostic 3: Inspecting Hash Anti Join Node (Unnested NOT EXISTS Subquery)
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS)
SELECT 
    d.dept_id,
    d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1
    FROM employes e
    WHERE e.dept_id = d.dept_id
);


-- ----------------------------------------------------------------------------
-- Diagnostic 4: Inspecting SubPlan Bottleneck (Correlated Subquery)
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS)
SELECT 
    e.emp_id,
    e.emp_name,
    e.hire_date
FROM employes e
WHERE e.hire_date = (
    SELECT MIN(sub.hire_date)
    FROM employes sub
    WHERE sub.dept_id = e.dept_id
);
