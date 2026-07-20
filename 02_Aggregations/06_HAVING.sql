-- ============================================================
-- 06_HAVING.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
--         departments(dept_id, dept_name, location_id)
--         locations(location_id, city)
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Overstaffed departments
-- (original seed query, retained)
-- Problem: Identify departments with more than one employee, as
-- a first-pass workforce distribution check.
-- --------------------------------------------------------------

SELECT
    dept_id,
    COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id
HAVING COUNT(*) > 1;


-- --------------------------------------------------------------
-- Q2: Business Scenario — Cities with more than one employee
-- (original seed query, retained)
-- --------------------------------------------------------------

SELECT
    l.city,
    COUNT(e.emp_id) AS employee_count
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY l.city
HAVING COUNT(e.emp_id) > 1;


-- --------------------------------------------------------------
-- Q3: Business Scenario — High-cost departments
-- Problem: Finance wants departments whose total payroll exceeds
-- a budget threshold, flagged for review.
-- --------------------------------------------------------------

SELECT
    dept_id,
    SUM(salary) AS total_payroll
FROM employes
GROUP BY dept_id
HAVING SUM(salary) > 100000;

-- Engineering Notes:
--   SUM(salary) is referenced identically in SELECT and HAVING —
--   this is intentional and required (unless using the MySQL/
--   PostgreSQL alias-in-HAVING extension shown in Q4).


-- --------------------------------------------------------------
-- Q4: Business Scenario — Combining WHERE and HAVING correctly
-- Problem: Compensation review should only consider departments
-- with assigned employees (exclude the NULL-department bucket via
-- WHERE), and only surface departments where the average salary
-- exceeds $50,000 (via HAVING).
-- --------------------------------------------------------------

SELECT
    dept_id,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employes
WHERE dept_id IS NOT NULL
GROUP BY dept_id
HAVING AVG(salary) > 50000;

-- Engineering Notes:
--   WHERE dept_id IS NOT NULL removes the unassigned-employee row
--   BEFORE grouping — cheaper than grouping everything and then
--   discarding a "NULL department" group via HAVING. This is the
--   canonical example of choosing the right clause for the right
--   filtering stage.


-- --------------------------------------------------------------
-- Q5: Common Mistake, reproduced and contrasted
-- --------------------------------------------------------------

-- WRONG (aggregate function inside WHERE — invalid):
-- SELECT dept_id, COUNT(*) FROM employes GROUP BY dept_id
-- WHERE COUNT(*) > 1;

-- CORRECT:
SELECT dept_id, COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id
HAVING COUNT(*) > 1;
