-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        RANK()
-- Module:       07_Window_Functions / 02_RANK
-- Difficulty:   Beginner
-- Author:       SQL Engineering Handbook Contributors
-- Description:  Assigns a competition-style rank. Tied rows share the
--               same rank, and the following rank skips ahead by the
--               number of tied rows.
-- Prerequisites: 01_ROW_NUMBER
-- Dataset:      employes, departments, locations
-- Learning
-- Objectives:   1. Rank rows while correctly handling ties.
--               2. Filter on RANK() using a CTE.
--               3. Compare RANK() against ROW_NUMBER().
-- ==========================================================


-- ==========================================================
-- Q1 -- Assign Rank to Employees Ordered by emp_id
-- ==========================================================
-- Problem Statement:
--   Assign a rank to each employee ordered by emp_id.
--
-- Engineering Tip:
--   RANK() behavior: [1, 2, 2, 4, 5] -- notice rank 3 is skipped
--   after the tie at rank 2.

SELECT
    emp_id,
    emp_name,
    RANK() OVER (ORDER BY emp_id) AS ranks
FROM employes;

-- Business Use Case:
--   Since emp_id is typically unique, this example demonstrates the
--   syntax; ties become visible once we rank by a non-unique column
--   such as manager_id (see Q5).


-- ==========================================================
-- Q2 -- Show Employee Name and Rank
-- ==========================================================
-- Problem Statement:
--   Return only emp_name and its rank.

SELECT
    emp_name,
    RANK() OVER (ORDER BY emp_id) AS ranks
FROM employes;


-- ==========================================================
-- Q3 -- Show the Employee With Rank = 1
-- ==========================================================
-- Problem Statement:
--   Return the employee(s) whose rank equals 1.
--
-- Engineering Tip:
--   As with ROW_NUMBER(), you cannot filter the alias directly in
--   WHERE -- wrap the ranking logic in a CTE first.

WITH emp_ranks AS (
    SELECT
        emp_id,
        emp_name,
        RANK() OVER (ORDER BY emp_id) AS ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name
FROM emp_ranks
WHERE ranks = 1;

-- Business Use Case:
--   Identify the record(s) that occupy the top rank -- useful when
--   ties mean multiple rows can legitimately be "rank 1".


-- ==========================================================
-- Q4 -- Show the Top 3 Ranked Employees
-- ==========================================================
-- Problem Statement:
--   Return all employees whose rank is 3 or better.
--
-- Engineering Tip:
--   Because RANK() can tie, "top 3 ranked" may return MORE than 3
--   rows if there are ties within the top positions -- this is
--   correct business behavior, not a bug.

WITH emp_ranks AS (
    SELECT
        emp_id,
        emp_name,
        RANK() OVER (ORDER BY emp_id) AS ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name
FROM emp_ranks
WHERE ranks <= 3;


-- ==========================================================
-- Q5 -- Compare ROW_NUMBER() and RANK()
-- ==========================================================
-- Problem Statement:
--   Show emp_id, emp_name, manager_id, and both ROW_NUMBER() and
--   RANK() computed over manager_id, so ties become visible.

-- Reference data (for exploration while learning):
SELECT * FROM departments;
SELECT * FROM locations;
SELECT * FROM employes;

WITH emp_ranks AS (
    SELECT
        emp_id,
        emp_name,
        manager_id,
        ROW_NUMBER() OVER (ORDER BY manager_id) AS nums,
        RANK()       OVER (ORDER BY manager_id) AS ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name,
    manager_id,
    nums,
    ranks
FROM emp_ranks;

-- Expected Output (conceptual):
-- manager_id | nums | ranks
-- -----------|------|------
--     5      |  1   |   1
--     5      |  2   |   1     <- tie: same manager_id
--     5      |  3   |   1     <- tie: same manager_id
--     7      |  4   |   4     <- RANK() skips to 4, ROW_NUMBER() continues to 4
--
-- Explanation:
--   ROW_NUMBER() always increments by exactly 1, ignoring ties.
--   RANK() keeps tied rows at the same value and then jumps forward
--   by the count of tied rows.
--
-- Business Use Case:
--   Grouping employees under the same manager and understanding how
--   many "positions" a tie consumes -- directly relevant to org-chart
--   and workload-distribution reporting.


-- ==========================================================
-- Summary
-- ==========================================================
-- RANK() is tie-aware but leaves gaps in the ranking sequence after
-- ties. Use DENSE_RANK() (next module) when gaps are undesirable.

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Expecting RANK() to behave like ROW_NUMBER() on tied data.
-- 2. Forgetting that "top 3" via RANK() can return more than 3 rows.
-- 3. Filtering the alias directly in WHERE without a CTE/subquery.

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- RANK() carries the same sort cost as ROW_NUMBER() plus a tie check
-- per row. On very large partitions, ensure the ORDER BY column is
-- indexed to minimize filesort overhead.

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. What happens to the "missing" rank number after a tie in RANK()?
-- 2. Give a real business scenario where gaps after ties are desired.
-- 3. How would you get exactly the top 3 rows even when ties exist?
--    (Hint: combine RANK() with a secondary ROW_NUMBER() tiebreaker.)

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-function-descriptions.html#function_rank
