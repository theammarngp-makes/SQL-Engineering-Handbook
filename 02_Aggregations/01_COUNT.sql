-- ============================================================
-- 01_COUNT.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
--         departments(dept_id, dept_name, location_id)
--         locations(location_id, city)
-- Dialects: MySQL 8+, PostgreSQL 13+ (annotated where they diverge)
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Headcount
-- Problem: HR needs the total number of employees currently on
-- record, regardless of whether they've been assigned a manager
-- or department yet (new hires often haven't been).
-- --------------------------------------------------------------

SELECT COUNT(*) AS total_employees
FROM employes;

-- Expected Output:
-- total_employees
-- ----------------
-- 5

-- Engineering Notes:
--   COUNT(*) is used deliberately here instead of COUNT(emp_id)
--   because emp_id is the primary key and can never be NULL —
--   but COUNT(*) makes the intent ("count every row") explicit
--   and doesn't rely on the reader knowing the schema constraints.

-- Common Mistake:
--   SELECT COUNT(manager_id) AS total_employees FROM employes;
--   This under-counts because employees with no manager (e.g. the
--   most senior person in the org) have manager_id = NULL, and
--   COUNT(column) silently skips NULLs.


-- --------------------------------------------------------------
-- Q2: Business Scenario — Departmental headcount
-- Problem: Workforce planning wants employee count broken down
-- by department, to identify under- and over-staffed teams.
-- --------------------------------------------------------------

SELECT
    dept_id,
    COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id;

-- Expected Output:
-- dept_id | employee_count
-- --------|---------------
--    10   |       2
--    20   |       2
--   NULL  |       1        -- employees not yet assigned to a department

-- Engineering Notes:
--   MySQL and PostgreSQL both include a NULL dept_id as its own
--   group by default. If unassigned employees should be excluded
--   from a departmental report, add: WHERE dept_id IS NOT NULL
--   before the GROUP BY (filter rows, not groups — see 06_HAVING.md
--   for why this belongs in WHERE, not HAVING).


-- --------------------------------------------------------------
-- Q3: Business Scenario — Distinct department coverage
-- Problem: Leadership wants to know how many distinct departments
-- actually have at least one employee, not the total department
-- count in the departments table.
-- --------------------------------------------------------------

SELECT COUNT(DISTINCT dept_id) AS departments_with_staff
FROM employes;

-- Expected Output:
-- departments_with_staff
-- -----------------------
-- 2

-- Engineering Notes:
--   COUNT(DISTINCT dept_id) ignores NULL automatically — the
--   unassigned employee does not inflate this number.

-- Alternative Solution (equivalent, sometimes clearer to junior
-- readers):
--   SELECT COUNT(*) FROM (SELECT DISTINCT dept_id FROM employes
--   WHERE dept_id IS NOT NULL) AS distinct_depts;
--   This is logically identical but adds an unnecessary subquery —
--   prefer COUNT(DISTINCT ...) in production code.


-- --------------------------------------------------------------
-- Q4: Business Scenario — City-level workforce distribution
-- Problem: Real estate/facilities planning needs to know how many
-- employees are physically located in each city, to plan office
-- capacity.
-- --------------------------------------------------------------

SELECT
    l.city,
    COUNT(e.emp_id) AS employee_count
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id
JOIN locations l
    ON d.location_id = l.location_id
GROUP BY l.city;

-- Expected Output:
-- city    | employee_count
-- --------|---------------
-- Nagpur  |       3
-- Pune    |       2

-- Engineering Notes:
--   COUNT(e.emp_id) is used instead of COUNT(*) here on purpose:
--   once you're joining across three tables, COUNT(*) counts
--   result rows, which is usually correct — but COUNT(e.emp_id)
--   makes it explicit that we're counting employees specifically,
--   protecting the query's meaning if another join is added later
--   that could introduce row duplication (e.g. a future join to a
--   one-to-many "employee_skills" table).
--
-- Performance Note:
--   INNER JOIN silently excludes employees with a NULL dept_id
--   (the unassigned employee from Q2 disappears here). If facilities
--   planning needs "unassigned" as its own bucket, switch to
--   LEFT JOIN departments and LEFT JOIN locations, and expect a
--   NULL city row in the output.
