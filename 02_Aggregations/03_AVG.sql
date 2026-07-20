-- ============================================================
-- 03_AVG.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
-- Note: corrected from an undefined `salaries` table to employes.salary.
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Company-wide average salary
-- Problem: HR benchmarking needs a single average salary figure
-- for compensation review.
-- --------------------------------------------------------------

SELECT ROUND(AVG(salary), 2) AS average_salary
FROM employes;

-- Expected Output:
-- average_salary
-- ---------------
-- 52500.00

-- Engineering Notes:
--   ROUND(..., 2) is applied for currency display. Without it,
--   PostgreSQL's numeric division may return more decimal places
--   than a payroll report should show.


-- --------------------------------------------------------------
-- Q2: Business Scenario — Average salary per department
-- Problem: Compare compensation levels across departments to spot
-- pay-equity gaps before the annual review cycle.
-- --------------------------------------------------------------

SELECT
    dept_id,
    ROUND(AVG(salary), 2) AS avg_department_salary,
    COUNT(*) AS headcount
FROM employes
GROUP BY dept_id;

-- Expected Output:
-- dept_id | avg_department_salary | headcount
-- --------|------------------------|----------
--    10   |         49000.00       |    2
--    20   |         56000.00       |    2

-- Engineering Notes:
--   headcount is included deliberately alongside the average.
--   An average without its underlying sample size is misleading —
--   a department average of one person looks identical in shape
--   to one averaged over fifty, but carries far less statistical
--   weight. Always surface COUNT(*) next to AVG() in business
--   reports.


-- --------------------------------------------------------------
-- Q3: Business Scenario — Demonstrating the "average of averages"
-- trap
-- Problem: A junior analyst rolled up department averages into a
-- company-wide figure and got a number that doesn't match Q1.
-- This query reproduces (and explains) the bug.
-- --------------------------------------------------------------

-- INCORRECT rollup:
SELECT ROUND(AVG(dept_avg), 2) AS wrong_company_average
FROM (
    SELECT dept_id, AVG(salary) AS dept_avg
    FROM employes
    GROUP BY dept_id
) per_department;

-- CORRECT rollup (matches Q1 exactly):
SELECT ROUND(AVG(salary), 2) AS correct_company_average
FROM employes;

-- Engineering Notes:
--   These two numbers only match when every department has an
--   identical headcount. In this dataset (2 and 2), they happen
--   to match by coincidence — re-run against a real, unevenly
--   sized dataset to see the discrepancy. This is the single most
--   important interview-relevant mistake in this file.


-- --------------------------------------------------------------
-- Q4: Business Scenario — Average salary by city
-- Problem: Compensation benchmarking against regional cost-of-
-- living data.
-- --------------------------------------------------------------

SELECT
    l.city,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    COUNT(e.emp_id) AS headcount
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY l.city;

-- Expected Output:
-- city    | avg_salary | headcount
-- --------|------------|----------
-- Nagpur  |  46000.00  |    3
-- Pune    |  36000.00  |    2
