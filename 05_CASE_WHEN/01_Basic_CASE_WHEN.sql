-- =============================================================
-- LESSON 01: Basic CASE WHEN
-- DIFFICULTY: Beginner
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- SCENARIO
-- HR wants a quick roster showing which employees report to someone
-- and which are top-level (no manager).
--
-- BUSINESS RULE
--   manager_id IS NULL  -> 'No Manager'
--   otherwise            -> 'Has Manager'
-- -----------------------------------------------------------------

SELECT
    emp_id,
    emp_name,
    CASE
        WHEN manager_id IS NULL THEN 'No Manager'
        ELSE 'Has Manager'
    END AS manager_status
FROM employees
ORDER BY emp_id;

-- Expected output (against seed data):
-- emp_id | emp_name        | manager_status
-- 1      | Aditi Rao       | No Manager
-- 2      | Rohan Mehta     | Has Manager
-- 3      | Sneha Kulkarni   | Has Manager
-- 4      | Karan Verma     | No Manager
-- 5      | Priya Nair      | Has Manager
-- 6      | Farhan Sheikh   | No Manager
-- 7      | Ishita Deshmukh | Has Manager
-- 8      | Vikram Joshi    | No Manager

-- -----------------------------------------------------------------
-- ALTERNATIVE SOLUTION (SQL Server / dialects with IIF)
-- IIF is shorthand for a two-branch CASE. Prefer CASE for anything
-- with more than two outcomes -- IIF nested more than one level
-- becomes unreadable fast.
-- -----------------------------------------------------------------
-- SELECT emp_id, emp_name,
--        IIF(manager_id IS NULL, 'No Manager', 'Has Manager') AS manager_status
-- FROM employees;

-- -----------------------------------------------------------------
-- PRODUCTION NOTE
-- This pattern is the backbone of dbt staging models: normalize a
-- nullable foreign key into a readable flag before it ever reaches
-- a BI tool, so every downstream model/dashboard agrees on the label.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- INTERVIEW DISCUSSION
-- Q: Why not just filter WHERE manager_id IS NULL in two separate
--    queries instead of using CASE?
-- A: Because the business wants BOTH groups in one result set for a
--    single roster/report -- CASE derives a column, it doesn't
--    filter rows. Filtering would require two queries and a UNION,
--    which is strictly worse for a single reporting output.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Add a third branch for employees who ARE a manager themselves
--    (i.e. emp_id appears in another row's manager_id).
-- 2. Rewrite using the simple CASE form by first computing a
--    0/1 flag with a subquery, then switching on that flag.
-- -----------------------------------------------------------------
