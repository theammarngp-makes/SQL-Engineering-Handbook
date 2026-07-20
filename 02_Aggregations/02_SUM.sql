-- ============================================================
-- 02_SUM.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
-- Note: earlier version of this file referenced an undefined
-- `salaries` table. Corrected to use employes.salary, consistent
-- with the schema used across the rest of this module.
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Total payroll cost
-- Problem: Finance needs the total salary expense across the
-- entire company for this month's budget review.
-- --------------------------------------------------------------

SELECT SUM(salary) AS total_salary
FROM employes;

-- Expected Output:
-- total_salary
-- ------------
-- 210000

-- Engineering Notes:
--   If salary is nullable (e.g. unpaid interns awaiting contract
--   finalization), those rows are silently excluded — this is
--   almost always correct behavior for a "total payroll" figure.


-- --------------------------------------------------------------
-- Q2: Business Scenario — Payroll cost per department
-- Problem: Department heads need their team's total salary
-- expense for budget planning.
-- --------------------------------------------------------------

SELECT
    dept_id,
    SUM(salary) AS department_payroll
FROM employes
GROUP BY dept_id;

-- Expected Output:
-- dept_id | department_payroll
-- --------|--------------------
--    10   |       98000
--    20   |      112000

-- Common Mistake:
--   SELECT dept_id, SUM(salary) FROM employes GROUP BY dept_id
--   ORDER BY SUM(salary);
--   This works, but repeating the aggregate expression is
--   error-prone at scale. Prefer aliasing and ordering by the
--   alias (supported in both MySQL and PostgreSQL):
--   ... GROUP BY dept_id ORDER BY department_payroll DESC;


-- --------------------------------------------------------------
-- Q3: Business Scenario — Safe payroll total for a possibly-empty
-- department
-- Problem: A newly created department has no employees yet, but
-- the finance dashboard must still display "$0", not a blank cell.
-- --------------------------------------------------------------

SELECT
    COALESCE(SUM(salary), 0) AS total_payroll
FROM employes
WHERE dept_id = 999; -- department with no employees

-- Expected Output:
-- total_payroll
-- -------------
-- 0

-- Engineering Notes:
--   Without COALESCE, this query returns a single row containing
--   NULL, not zero rows and not 0. Dashboard code that does
--   `if (result === null) { showError() }` will misfire on this
--   perfectly valid "no data yet" case unless COALESCE is applied
--   at the SQL layer.


-- --------------------------------------------------------------
-- Q4: Business Scenario — Payroll cost by city
-- Problem: Facilities and finance jointly need a per-city cost
-- center report.
-- --------------------------------------------------------------

SELECT
    l.city,
    SUM(e.salary) AS city_payroll
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY l.city
ORDER BY city_payroll DESC;

-- Expected Output:
-- city    | city_payroll
-- --------|-------------
-- Nagpur  |    138000
-- Pune    |     72000

-- Alternative Solution:
--   If unassigned employees (NULL dept_id) must still be reflected
--   somewhere in a total, switch INNER JOIN to LEFT JOIN and group
--   on COALESCE(l.city, 'Unassigned') instead — INNER JOIN drops
--   those rows entirely, which is correct for a per-city report
--   but would be wrong for a "grand total must reconcile with Q1"
--   report.
