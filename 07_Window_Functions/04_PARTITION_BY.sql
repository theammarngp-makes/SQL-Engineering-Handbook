
---

### 📄 '04_PARTITION_BY.sql'

```sql
-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        PARTITION BY
-- Module:       07_Window_Functions / 04_PARTITION_BY
-- Difficulty:   Intermediate
-- Author:       SQL Engineering Handbook Contributors
-- Description:  Splits the result set into independent groups so a
--               window function resets and recalculates per group,
--               without collapsing rows the way GROUP BY does.
-- Prerequisites: 01_ROW_NUMBER, 02_RANK, 03_DENSE_RANK, 03_Joins
-- Dataset:      employes JOIN departments ON dept_id
-- Learning
-- Objectives:   1. Compute per-group rankings and counts.
--               2. Retrieve the first row of every group.
--               3. Build a multi-function department leaderboard.
-- ==========================================================

-- Reference data (for exploration while learning):
SELECT * FROM departments;
SELECT * FROM locations;
SELECT * FROM employes;


-- ==========================================================
-- Q1 -- Assign Row Numbers Within Each Department
-- ==========================================================
-- Problem Statement:
--   Assign a row number to each employee, restarting the sequence at
--   the beginning of every department.

SELECT
    emp_id,
    emp_name,
    dept_name,
    ROW_NUMBER() OVER (
        PARTITION BY dept_name
        ORDER BY emp_id
    ) AS dept_seq
FROM employes
JOIN departments
    ON employes.dept_id = departments.dept_id;

-- Expected Output (shape):
-- dept_name | emp_id | dept_seq
-- ----------|--------|--------
-- Sales     |  101   |   1
-- Sales     |  105   |   2
-- Finance   |  102   |   1     <- resets for the new partition
--
-- Business Use Case:
--   Number employees within their own department for a per-team
--   directory listing.


-- ==========================================================
-- Q2 -- Assign Ranks Within Each Department
-- ==========================================================
-- Problem Statement:
--   Assign a rank to each employee, scoped to their department.

SELECT
    emp_id,
    emp_name,
    dept_name,
    RANK() OVER (
        PARTITION BY dept_name
        ORDER BY emp_id
    ) AS dept_ranks
FROM employes
JOIN departments
    ON employes.dept_id = departments.dept_id;

-- Business Use Case:
--   Department-level performance leaderboards where ties should share
--   a position within that department only.


-- ==========================================================
-- Q3 -- Count Employees in Each Department Using a Window Function
-- ==========================================================
-- Problem Statement:
--   Show, on every employee row, the total headcount of their
--   department -- without collapsing rows via GROUP BY.

SELECT
    emp_id,
    emp_name,
    dept_name,
    COUNT(emp_id) OVER (
        PARTITION BY dept_name
    ) AS emp_count
FROM employes
JOIN departments
    ON employes.dept_id = departments.dept_id;

-- Engineering Tip:
--   This is the key advantage of window functions over GROUP BY: you
--   get the aggregate (emp_count) AND every individual row's detail
--   in the same result set, with no self-join required.


-- ==========================================================
-- Q4 -- Show the First Employee From Every Department
-- ==========================================================
-- Problem Statement:
--   Return exactly one employee per department -- the one with the
--   lowest emp_id.

WITH dept_ranks AS (
    SELECT
        emp_id,
        emp_name,
        dept_name,
        ROW_NUMBER() OVER (
            PARTITION BY dept_name
            ORDER BY emp_id
        ) AS emp_rank
    FROM employes
    JOIN departments
        ON employes.dept_id = departments.dept_id
)
SELECT
    emp_id,
    emp_name,
    dept_name,
    emp_rank
FROM dept_ranks
WHERE emp_rank = 1;

-- Business Use Case:
--   The classic "top-N per group" pattern -- here N = 1. Swap
--   `emp_rank = 1` for `emp_rank <= 3` to get the top 3 per department.


-- ==========================================================
-- Q5 -- Create a Department Leaderboard
-- ==========================================================
-- Problem Statement:
--   Combine ROW_NUMBER(), RANK(), and DENSE_RANK() -- all partitioned
--   by department and ordered by manager_id -- into a single
--   leaderboard view.

SELECT
    emp_id,
    emp_name,
    dept_name,
    ROW_NUMBER() OVER (
        PARTITION BY dept_name
        ORDER BY manager_id
    ) AS emp_seq,
    RANK() OVER (
        PARTITION BY dept_name
        ORDER BY manager_id
    ) AS emp_ranks,
    DENSE_RANK() OVER (
        PARTITION BY dept_name
        ORDER BY manager_id
    ) AS rankings
FROM employes
JOIN departments
    ON employes.dept_id = departments.dept_id;

-- Business Use Case:
--   A single query that gives report authors every ranking flavor
--   they might need, scoped correctly to each department, ready to
--   be filtered or exported into a dashboard.


-- ==========================================================
-- Summary
-- ==========================================================
-- PARTITION BY is the mechanism that turns any window function from a
-- "whole table" calculation into a "per group" calculation. It is the
-- single most reused clause in production analytics SQL.

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Forgetting PARTITION BY and computing a global rank by accident.
-- 2. Joining incorrectly and duplicating rows before partitioning,
--    which silently corrupts every downstream calculation.
-- 3. Assuming PARTITION BY filters data -- it only scopes the window.

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- A composite index on (dept_id, emp_id) (or the equivalent
-- partition/order columns) lets the engine avoid a full re-sort per
-- partition, which matters significantly once the employee table
-- grows past a few hundred thousand rows.

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. How does PARTITION BY differ from GROUP BY?
-- 2. How would you find the top 2 highest-paid employees per
--    department?
-- 3. Can you use multiple columns in PARTITION BY? Give an example.

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-functions-usage.html
