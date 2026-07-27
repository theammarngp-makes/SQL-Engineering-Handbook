-- =============================================================================
-- TOPIC: MULTI-TABLE JOINS
-- DIFFICULTY: Intermediate
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Show each employee with their department name and city.
--
-- BUSINESS SCENARIO
-- Employee location reporting for a workplace-strategy review evaluating
-- which offices are over- or under-utilized.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name,
    d.dept_name,
    l.city
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id
INNER JOIN locations l
    ON d.location_id = l.location_id
ORDER BY l.city, d.dept_name, e.emp_name;

-- EXPECTED OUTPUT: 9 rows (same 9 employees that survived the two-table
-- join in 01_INNER_JOIN.sql — no Marketing employees currently exist, so
-- the location.NULL edge case doesn't remove any additional rows here,
-- but would the moment someone is hired into Marketing).


-- -----------------------------------------------------------------------------
-- Q2. Show only employees working in Nagpur, with their department budget.
--
-- BUSINESS SCENARIO
-- City-wise workforce cost analysis ahead of a Nagpur office lease renewal.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name,
    d.dept_name,
    d.budget
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id
INNER JOIN locations l
    ON d.location_id = l.location_id
WHERE l.city = 'Nagpur'
ORDER BY d.budget DESC;

-- EXPECTED OUTPUT: 4 rows — Engineering (Nagpur) and HR (Nagpur) employees.


-- -----------------------------------------------------------------------------
-- Q3. Department headcount and city, sorted by headcount.
--
-- BUSINESS SCENARIO
-- Department staffing analysis for the annual budget review.
-- -----------------------------------------------------------------------------

SELECT
    d.dept_name,
    l.city,
    COUNT(e.emp_id) AS total_employees
FROM departments d
LEFT JOIN locations l
    ON d.location_id = l.location_id
LEFT JOIN employees e
    ON e.dept_id = d.dept_id
GROUP BY d.dept_name, l.city
ORDER BY total_employees DESC;

-- EXPECTED OUTPUT: 6 rows (every department, including Legal with 0 and
-- Marketing showing city = NULL). Note both joins are LEFT here, unlike
-- Q1/Q2's INNER — deliberately, since this report's whole point is
-- surfacing departments with zero headcount and/or no assigned city, not
-- hiding them the way an INNER JOIN chain would.


-- -----------------------------------------------------------------------------
-- Q4. SEMI JOIN — which departments have at least one employee earning
-- more than 150,000?
--
-- BUSINESS SCENARIO
-- Compensation review needs a list of departments with senior/high-earning
-- staff, without needing each individual employee's row.
-- -----------------------------------------------------------------------------

SELECT d.dept_name
FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employees e
    WHERE e.dept_id = d.dept_id AND e.salary > 150000
)
ORDER BY d.dept_name;

-- EXPECTED OUTPUT: 3 rows (Engineering, Sales, Finance). Note this returns
-- each department exactly ONCE regardless of how many high earners it has —
-- a plain INNER JOIN + DISTINCT would work too, but EXISTS never
-- materializes the matching employee rows at all, which is typically
-- cheaper when you don't need their columns.


-- -----------------------------------------------------------------------------
-- Q5. ANTI JOIN — which departments have NO employee earning more than
-- 150,000? Demonstrated three ways: two safe, one broken.
--
-- BUSINESS SCENARIO
-- The inverse of Q4 — departments that may need a compensation adjustment
-- to remain competitive for senior hiring.
-- -----------------------------------------------------------------------------

-- ✅ SAFE: NOT EXISTS
SELECT d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employees e
    WHERE e.dept_id = d.dept_id AND e.salary > 150000
)
ORDER BY d.dept_name;

-- ✅ SAFE: LEFT JOIN ... WHERE right.key IS NULL
SELECT d.dept_name
FROM departments d
LEFT JOIN employees e
    ON e.dept_id = d.dept_id AND e.salary > 150000
WHERE e.emp_id IS NULL
ORDER BY d.dept_name;

-- ❌ BROKEN if the subquery column can contain NULL: NOT IN
-- departments.location_id contains a NULL (Marketing) — reproduce the trap
-- with a DIFFERENT nullable column to see it fail concretely:
SELECT dept_name
FROM departments
WHERE dept_id NOT IN (
    SELECT dept_id FROM employees WHERE dept_id IS NULL   -- deliberately wrong subquery
);
-- Run this and observe: it returns ZERO rows, even though every department
-- should qualify (no department's dept_id is NULL). The subquery's result
-- set is just (NULL), and "dept_id NOT IN (NULL)" evaluates to NULL — never
-- TRUE — for every single row. This is the exact failure mode described in
-- the paired .md file's Semi Joins and Anti Joins section. The fix: add
-- "AND dept_id IS NOT NULL" inside the subquery, or better, use NOT EXISTS.

-- INTERVIEW INSIGHT
-- Being able to reproduce this NOT IN failure on command, explain WHY in
-- terms of three-valued logic (not just "it's buggy"), and immediately
-- name NOT EXISTS as the fix, is one of the higher-signal SQL interview
-- moments — it separates "has memorized syntax" from "understands NULL
-- semantics."

-- FURTHER EXPERIMENTS
-- 1. Rewrite Q1 to add a fourth join: each employee's manager's city
--    (requires joining employees a second time, through departments and
--    locations again, via new aliases).
-- 2. Convert Q4 (semi join) into an equivalent DISTINCT-based INNER JOIN
--    and compare EXPLAIN output between the two forms on your own database.
-- 3. Fix the broken NOT IN query in Q5 by adding "AND dept_id IS NOT NULL"
--    to the subquery, rerun it, and confirm it now returns all 6
--    departments correctly.
