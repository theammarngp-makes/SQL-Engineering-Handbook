-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 06: SCALAR SUBQUERIES IN PROJECTIONS
-- File: 06_SCALAR_SUBQUERIES.sql
-- Description: Projected scalar subqueries in SELECT statements, scalar caching,
--              and performance rewrites to Window Functions and LEFT JOINs.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Uncorrelated & Correlated Projected Scalar Subqueries
-- Problem: Display employee info alongside total company headcount and
--          the specific department name.
-- ----------------------------------------------------------------------------

SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    -- Uncorrelated Scalar Projection (Evaluated once via InitPlan)
    (SELECT COUNT(*) FROM employes) AS company_total_employees,
    -- Correlated Scalar Projection (Evaluated via SubPlan with scalar caching)
    (SELECT d.dept_name FROM departments d WHERE d.dept_id = e.dept_id) AS dept_name
FROM employes e
ORDER BY e.emp_id;


-- ----------------------------------------------------------------------------
-- Scenario 2: Scalar Projection with Default NULL Handling (COALESCE)
-- Problem: Calculate total subordinates reporting to each employee.
-- ----------------------------------------------------------------------------

SELECT 
    mgr.emp_id,
    mgr.emp_name,
    COALESCE(
        (SELECT COUNT(*) 
         FROM employes report 
         WHERE report.manager_id = mgr.emp_id), 
        0
    ) AS total_direct_reports
FROM employes mgr
ORDER BY total_direct_reports DESC;


-- ----------------------------------------------------------------------------
-- Scenario 3: Performance Rewrite — Scalar Projection to Window Function
-- Problem: Compare employee hire date against department earliest hire date.
-- ----------------------------------------------------------------------------

-- Pattern A: Slow Correlated Scalar Subquery
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date,
    (SELECT MIN(d.hire_date) FROM employes d WHERE d.dept_id = e.dept_id) AS dept_first_hire
FROM employes e;

-- Pattern B: High-Performance Window Function Rewrite
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date,
    MIN(e.hire_date) OVER (PARTITION BY e.dept_id) AS dept_first_hire
FROM employes e;


-- ----------------------------------------------------------------------------
-- Scenario 4: EXPLAIN Plan Inspection — Scalar SubPlan Node Analysis
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    e.emp_id,
    e.emp_name,
    (SELECT d.dept_name FROM departments d WHERE d.dept_id = e.dept_id) AS dept_name
FROM employes e;
