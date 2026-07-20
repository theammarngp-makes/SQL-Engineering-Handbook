-- ============================================================
-- 08_BUSINESS_CASES.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
--         departments(dept_id, dept_name, location_id)
--         locations(location_id, city)
-- These queries combine every concept taught in this module into
-- realistic, end-to-end business reports.
-- ============================================================

-- --------------------------------------------------------------
-- Q1: HR — Department Scorecard
-- Business question: For each department with more than one
-- employee, show headcount, average salary, salary range, and the
-- high/low pay-band split — sorted by headcount, largest first.
-- --------------------------------------------------------------

SELECT
    d.dept_name,
    COUNT(*) AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    COUNT(CASE WHEN e.salary > 50000 THEN 1 END) AS high_earners,
    COUNT(CASE WHEN e.salary <= 50000 THEN 1 END) AS standard_earners
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING COUNT(*) > 1
ORDER BY headcount DESC;

-- Engineering Notes:
--   This single query layers every clause from the module:
--   JOIN (relational context) -> GROUP BY (per-department buckets)
--   -> HAVING (only meaningfully-sized departments) -> ORDER BY
--   (executive-friendly sort). This is the shape of a real BI
--   dashboard query, not a toy example.


-- --------------------------------------------------------------
-- Q2: Workforce Planning — City Capacity Report
-- Business question: Headcount and average salary per city,
-- limited to cities with at least 2 employees.
-- --------------------------------------------------------------

SELECT
    l.city,
    COUNT(e.emp_id) AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MAX(e.salary) AS highest_salary_in_city
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY l.city
HAVING COUNT(e.emp_id) >= 2
ORDER BY headcount DESC;


-- --------------------------------------------------------------
-- Q3: Compensation — Pay Equity Check
-- Business question: Departments with a pay-band spread greater
-- than $15,000, flagged for compensation review.
-- --------------------------------------------------------------

SELECT
    d.dept_name,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    MAX(e.salary) - MIN(e.salary) AS pay_band_spread
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING MAX(e.salary) - MIN(e.salary) > 15000
ORDER BY pay_band_spread DESC;

-- Engineering Notes:
--   The HAVING condition repeats the derived expression from the
--   SELECT list (MAX - MIN) — this is required under strict ANSI
--   SQL. MySQL and PostgreSQL both also permit referencing a
--   SELECT-list alias here (HAVING pay_band_spread > 15000) if one
--   is defined, as noted in 06_HAVING.md.


-- --------------------------------------------------------------
-- Q4: Org Design — Manager Span of Control
-- Business question: Managers with more than one direct report,
-- and the average salary of their team.
-- --------------------------------------------------------------

SELECT
    manager_id,
    COUNT(*) AS direct_reports,
    ROUND(AVG(salary), 2) AS avg_team_salary
FROM employes
WHERE manager_id IS NOT NULL
GROUP BY manager_id
HAVING COUNT(*) > 1
ORDER BY direct_reports DESC;

-- Engineering Notes:
--   WHERE manager_id IS NOT NULL removes employees with no manager
--   (e.g. the most senior person in the org) BEFORE grouping — if
--   this filter were omitted, a "NULL manager" group could appear
--   in the output, misrepresenting an unmanaged employee as a
--   "manager with 1 direct report" in some join topologies.


-- --------------------------------------------------------------
-- Q5: Executive Summary — Single-row Company KPIs
-- Business question: One row for the executive dashboard header:
-- total headcount, total payroll, average salary, highest salary.
-- --------------------------------------------------------------

SELECT
    COUNT(*) AS total_headcount,
    COALESCE(SUM(salary), 0) AS total_payroll,
    ROUND(AVG(salary), 2) AS avg_salary,
    MAX(salary) AS highest_salary
FROM employes;

-- Expected Output:
-- total_headcount | total_payroll | avg_salary | highest_salary
-- -----------------|-----------------|-------------|-----------------
--        5         |     210000      |   52500.00  |     62000

-- Engineering Notes:
--   No GROUP BY at all — the entire table is treated as a single
--   implicit group. Every aggregate function in this module works
--   identically whether or not GROUP BY is present; GROUP BY just
--   determines how many groups exist (one, versus many).
--   COALESCE guards the total_payroll figure against a NULL
--   result if the table were ever empty, consistent with the
--   defensive pattern established in 02_SUM.sql Q3.
