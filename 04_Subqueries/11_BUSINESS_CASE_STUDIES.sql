-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 11: ENTERPRISE BUSINESS CASE STUDIES
-- File: 11_BUSINESS_CASE_STUDIES.sql
-- Description: Complete executable SQL scripts representing the 6 enterprise
--              business case studies (FinTech, E-Commerce, Healthcare, etc.).
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Case Study 1: Departmental Hiring Velocity vs Company Benchmark
-- Problem: Retrieve departments whose earliest hiring date is earlier than
--          the overall company average hiring date.
-- ----------------------------------------------------------------------------

SELECT 
    d.dept_id,
    d.dept_name,
    dept_first.min_hire_date
FROM departments d
JOIN (
    SELECT dept_id, MIN(hire_date) AS min_hire_date
    FROM employes
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) dept_first ON d.dept_id = dept_first.dept_id
WHERE dept_first.min_hire_date < (
    SELECT AVG(hire_date - '2020-01-01'::DATE) * INTERVAL '1 day' + '2020-01-01'::DATE
    FROM employes
)
ORDER BY dept_first.min_hire_date ASC;


-- ----------------------------------------------------------------------------
-- Case Study 2: Anti-Join Customer Churn Identification
-- Problem: Find departments that have NO employees assigned (Unused Departments).
-- ----------------------------------------------------------------------------

SELECT 
    d.dept_id,
    d.dept_name,
    l.city
FROM departments d
JOIN locations l ON d.location_id = l.location_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM employes e 
    WHERE e.dept_id = d.dept_id
)
ORDER BY d.dept_id;


-- ----------------------------------------------------------------------------
-- Case Study 3: Manager Span-of-Control Optimization
-- Problem: Find managers who manage strictly MORE employees than the average
--          manager's span of control.
-- ----------------------------------------------------------------------------

SELECT 
    mgr.emp_id AS manager_id,
    mgr.emp_name AS manager_name,
    COUNT(report.emp_id) AS direct_reports
FROM employes mgr
JOIN employes report ON report.manager_id = mgr.emp_id
GROUP BY mgr.emp_id, mgr.emp_name
HAVING COUNT(report.emp_id) > (
    SELECT COUNT(e.emp_id)::NUMERIC / COUNT(DISTINCT e.manager_id)
    FROM employes e
    WHERE e.manager_id IS NOT NULL
)
ORDER BY direct_reports DESC;
