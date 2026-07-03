-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        DENSE_RANK()
-- Module:       07_Window_Functions / 03_DENSE_RANK
-- Difficulty:   Beginner
-- Author:       SQL Engineering Handbook Contributors
-- Description:  Assigns a competition rank with NO gaps after ties,
--               unlike RANK(). [1, 2, 2, 3, 4, 5]
-- Prerequisites: 01_ROW_NUMBER, 02_RANK
-- Dataset:      employes
-- Learning
-- Objectives:   1. Assign gap-free ranks.
--               2. Compare DENSE_RANK() against RANK().
--               3. Filter dense-ranked results with a CTE.
-- ==========================================================


-- ==========================================================
-- Q1 -- Assign Dense Rank to Employees Ordered by manager_id
-- ==========================================================
-- Problem Statement:
--   Assign a dense rank to employees ordered by manager_id ascending.

SELECT
    emp_id,
    emp_name,
    DENSE_RANK() OVER (ORDER BY manager_id ASC) AS dense_ranks
FROM employes;

-- Business Use Case:
--   Group employees into consecutive "manager tiers" for an org chart
--   visualization, where no tier number should be skipped.


-- ==========================================================
-- Q2 -- Show Employee Name and Dense Rank
-- ==========================================================
-- Problem Statement:
--   Return emp_name and its dense rank, ordered by emp_id ascending.

SELECT
    emp_name,
    DENSE_RANK() OVER (ORDER BY emp_id ASC) AS dense_ranks
FROM employes;


-- ==========================================================
-- Q3 -- Show Employees With Dense Rank <= 3
-- ==========================================================
-- Problem Statement:
--   Return employees whose dense rank (by emp_id) is 3 or better.

WITH dense_ranks AS (
    SELECT
        emp_id,
        emp_name,
        DENSE_RANK() OVER (ORDER BY emp_id) AS d_ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name,
    d_ranks
FROM dense_ranks
WHERE d_ranks <= 3;

-- Variant -- same question, ranked by manager_id descending instead,
-- to show how the ORDER BY direction changes which rows qualify:

WITH dense_ranks_by_manager AS (
    SELECT
        emp_id,
        emp_name,
        manager_id,
        DENSE_RANK() OVER (ORDER BY manager_id DESC) AS d_ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name,
    d_ranks
FROM dense_ranks_by_manager
WHERE d_ranks <= 3;

-- Business Use Case:
--   Retrieve the top 3 consecutive salary/seniority bands without
--   skipping a band number, which is important for reports that must
--   show every tier that exists in the top bracket.


-- ==========================================================
-- Q4 -- Compare RANK() and DENSE_RANK()
-- ==========================================================
-- Problem Statement:
--   Show emp_id, emp_name, manager_id, RANK(), and DENSE_RANK() side
--   by side to visually confirm the gap difference.

WITH ranked_employees AS (
    SELECT
        emp_id,
        emp_name,
        manager_id,
        DENSE_RANK() OVER (ORDER BY manager_id DESC) AS d_ranks,
        RANK()       OVER (ORDER BY manager_id DESC) AS ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name,
    ranks,
    d_ranks
FROM ranked_employees;

-- Expected Output (conceptual):
-- manager_id | ranks | d_ranks
-- -----------|-------|--------
--     9      |   1   |   1
--     9      |   1   |   1     <- tie
--     7      |   3   |   2     <- RANK jumps to 3, DENSE_RANK moves to 2
--
-- Explanation:
--   RANK() "spends" rank numbers on tied rows; DENSE_RANK() does not.


-- ==========================================================
-- Q5 -- Show the Employee(s) With Dense Rank = 1
-- ==========================================================
-- Problem Statement:
--   Return the employee(s) sitting at dense rank 1 (highest manager_id).

WITH ranked_employees AS (
    SELECT
        emp_id,
        emp_name,
        manager_id,
        DENSE_RANK() OVER (ORDER BY manager_id DESC) AS d_ranks,
        RANK()       OVER (ORDER BY manager_id DESC) AS ranks
    FROM employes
)
SELECT
    emp_id,
    emp_name,
    ranks,
    d_ranks
FROM ranked_employees
WHERE d_ranks = 1;

-- Business Use Case:
--   Identify all employees reporting to the highest-ID manager in a
--   single, readable query -- reusable for any "top tier" lookup.


-- ==========================================================
-- Summary
-- ==========================================================
-- DENSE_RANK() gives consecutive ranks with no gaps, even after ties.
-- Choose it whenever the business needs a compact tier numbering
-- scheme (e.g., pay grades, pricing tiers, risk bands).

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Assuming DENSE_RANK() and RANK() are equivalent on tie-free data
--    -- they only diverge once ties appear.
-- 2. Using DENSE_RANK() when the business actually wants RANK()'s
--    "gap = number of ties" semantics.

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- Cost profile is identical to RANK() -- a single sorted pass with a
-- per-row tie comparison. No additional overhead versus RANK().

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. Give a real-world example where DENSE_RANK() is clearly the
--    correct choice over RANK().
-- 2. How would you find the "second highest" distinct salary using
--    DENSE_RANK()?

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-function-descriptions.html#function_dense-rank
