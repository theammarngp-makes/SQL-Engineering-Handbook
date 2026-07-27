-- =============================================================================
-- TOPIC: RIGHT JOIN
-- DIFFICULTY: Beginner
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Show every department with its employees, including departments with
-- zero employees — and PROVE the zero-employee departments are actually
-- present in the result (not just assert it in a comment).
--
-- BUSINESS SCENARIO
-- Workforce planning needs a department roster ahead of budget season.
-- A department with budget allocated but no staff is exactly the kind of
-- row this report must not silently drop.
-- -----------------------------------------------------------------------------

SELECT
    d.dept_name,
    e.emp_name,
    d.budget
FROM employees e
RIGHT JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- EXPECTED OUTPUT: 11 rows. Legal (0 employees) appears ONCE, with
-- emp_name = NULL. Compare this row count to Q1 in 01_INNER_JOIN.sql
-- (which returns fewer rows for a similar shape of query) to see the
-- preservation behavior directly in the numbers.


-- -----------------------------------------------------------------------------
-- Q2. Which departments have zero employees? (workforce gap analysis)
--
-- BUSINESS SCENARIO
-- Ahead of headcount planning, Finance wants a list of departments that are
-- funded (have a budget row) but currently unstaffed.
-- -----------------------------------------------------------------------------

SELECT
    d.dept_name,
    d.budget
FROM employees e
RIGHT JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL       -- check the join key on the NON-preserved side
ORDER BY d.budget DESC;

-- EXPECTED OUTPUT: 1 row (Legal, budget 500000.00).

-- ENGINEERING NOTES
-- This is the RIGHT JOIN mirror of 02_LEFT_JOIN.sql's Q2. Whichever
-- direction you write it, the rule is identical: check IS NULL on the
-- join key of the side that ISN'T guaranteed to be preserved.


-- -----------------------------------------------------------------------------
-- Q3. Headcount per department, including zero-headcount departments,
-- without using RIGHT JOIN.
--
-- BUSINESS SCENARIO
-- Demonstrate to a teammate who "doesn't like RIGHT JOIN" (most style
-- guides don't) that the identical business question is answerable with
-- LEFT JOIN alone.
-- -----------------------------------------------------------------------------

SELECT
    d.dept_name,
    COUNT(e.emp_id) AS headcount        -- COUNT(column) skips NULLs; COUNT(*) would not
FROM departments d
LEFT JOIN employees e
    ON e.dept_id = d.dept_id
GROUP BY d.dept_name
ORDER BY headcount;

-- EXPECTED OUTPUT: 6 rows (all departments). Legal shows headcount = 0.

-- ALTERNATIVE SOLUTION
-- The RIGHT JOIN equivalent, table order unchanged from Q1's style:
--
-- SELECT d.dept_name, COUNT(e.emp_id) AS headcount
-- FROM employees e
-- RIGHT JOIN departments d ON e.dept_id = d.dept_id
-- GROUP BY d.dept_name
-- ORDER BY headcount;
--
-- Both plans are typically identical after the optimizer normalizes them —
-- the choice between the two is purely a readability decision, covered in
-- the paired .md file's Best Practices section.

-- INTERVIEW INSIGHT
-- COUNT(e.emp_id) vs COUNT(*) is a frequent follow-up here: COUNT(*) counts
-- ROWS (always ≥ 1 per group after an outer join), while COUNT(column)
-- counts non-NULL VALUES. For Legal's single NULL-emp_id row,
-- COUNT(*) would incorrectly report 1, not 0. This is a real, common bug.

-- FURTHER EXPERIMENTS
-- 1. Change Q3's COUNT(e.emp_id) to COUNT(*) and rerun — confirm Legal's
--    headcount incorrectly shows 1 instead of 0, and explain why in your
--    own words.
-- 2. Extend Q1 to also show each department's location city, requiring a
--    second join — a preview of 07_MULTI_TABLE_JOINS.sql. Think carefully
--    about whether the second join should also be a RIGHT JOIN, and why.
