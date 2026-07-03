-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        ROW_NUMBER()
-- Module:       07_Window_Functions / 01_ROW_NUMBER
-- Difficulty:   Beginner
-- Author:       SQL Engineering Handbook Contributors
-- Description:  Assigns a unique, sequential integer to every row in a
--               result set. Ties are broken arbitrarily -- no two rows
--               ever share the same ROW_NUMBER() value.
-- Prerequisites: SELECT, ORDER BY, CTEs
-- Dataset:      employes(emp_id, emp_name, dept_id, manager_id)
-- Learning
-- Objectives:   1. Generate a unique row sequence.
--               2. Filter on a window function result via CTE/subquery.
--               3. Understand ROW_NUMBER() vs RANK() vs DENSE_RANK().
-- ==========================================================


-- ==========================================================
-- Q1 -- Assign a Row Number to Every Employee (by emp_id)
-- ==========================================================
-- Problem Statement:
--   Assign a row number to every employee ordered by emp_id.
--
-- Business Use Case:
--   Generate a stable display sequence for an HR report, independent
--   of the underlying primary key gaps.
--
-- Engineering Tip:
--   ORDER BY inside OVER() is mandatory for deterministic results.

SELECT
    emp_id,
    emp_name,
    ROW_NUMBER() OVER (ORDER BY emp_id) AS emp_seq
FROM employes;

-- Expected Output (shape):
-- emp_id | emp_name | emp_seq
-- -------|----------|--------
--   101  |  Aisha    |   1
--   102  |  Farhan   |   2
--   ...  |   ...     |  ...
--
-- Explanation:
--   Every row receives a strictly increasing integer starting at 1,
--   following the emp_id sort order. No duplicates and no gaps.


-- ==========================================================
-- Q2 -- Assign a Row Number Ordered by Employee Name
-- ==========================================================
-- Problem Statement:
--   Assign a row number ordered by employee name instead of emp_id.
--
-- Business Use Case:
--   Alphabetical staff directories for internal HR portals.

SELECT
    emp_id,
    emp_name,
    ROW_NUMBER() OVER (ORDER BY emp_name) AS emp_seq
FROM employes;

-- Explanation:
--   Changing the ORDER BY column inside OVER() changes the sequencing
--   logic without touching the rest of the query -- this is the core
--   flexibility window functions provide over manual sequencing.


-- ==========================================================
-- Q3 -- Show Employee Name and Row Number Only
-- ==========================================================
-- Problem Statement:
--   Return only emp_name and its row number (by emp_id order).
--
-- Business Use Case:
--   Trim unnecessary columns for a lightweight API response.

SELECT
    emp_name,
    ROW_NUMBER() OVER (ORDER BY emp_id) AS emp_seq
FROM employes;

-- Engineering Tip:
--   The window calculation still uses emp_id internally, even though
--   emp_id is not projected in the final SELECT list.


-- ==========================================================
-- Q4 -- Show the Top 3 Employees Using ROW_NUMBER()
-- ==========================================================
-- Problem Statement:
--   Show the top 3 employees using ROW_NUMBER().
--
-- Business Use Case:
--   Quick "top of the list" preview for a dashboard widget.

SELECT
    emp_id,
    emp_name,
    ROW_NUMBER() OVER (ORDER BY emp_id) AS emp_seq
FROM employes
LIMIT 3;

-- Explanation:
--   LIMIT here is safe because ORDER BY emp_id inside OVER() and the
--   natural sort produce a deterministic top-3. In general, prefer
--   filtering on the ROW_NUMBER() value itself (see Q5) when the
--   "top N" needs to survive further WHERE conditions or joins.


-- ==========================================================
-- Q5 -- Show the Employee Having ROW_NUMBER() = 1
-- ==========================================================
-- Problem Statement:
--   Show the employee whose ROW_NUMBER() equals 1.
--
-- Common Mistake (kept intentionally to teach the failure mode):
--   The query below is INVALID SQL. WHERE is evaluated before window
--   functions, so the alias `emp_seq` does not exist yet at that stage.
--
--   SELECT emp_id, emp_name,
--          ROW_NUMBER() OVER (ORDER BY emp_id) AS emp_seq
--   FROM employes
--   WHERE emp_seq = 1;   -- ERROR: unknown column 'emp_seq'
--
-- Correct Solution #1 -- Using a CTE:

WITH row_num AS (
    SELECT
        emp_id,
        emp_name,
        ROW_NUMBER() OVER (ORDER BY emp_id) AS emp_seq
    FROM employes
)
SELECT
    emp_id,
    emp_name,
    emp_seq
FROM row_num
WHERE emp_seq = 1;

-- Correct Solution #2 -- Using a Subquery:

SELECT
    emp_id,
    emp_name,
    emp_seq
FROM (
    SELECT
        e.emp_id,
        e.emp_name,
        ROW_NUMBER() OVER (ORDER BY e.emp_id) AS emp_seq
    FROM employes e
) AS temp_table
WHERE emp_seq = 1;

-- Business Use Case:
--   Retrieve the "first" record per business rule (e.g., earliest hire,
--   lowest ID) without relying on LIMIT, which does not compose well
--   inside joins or further filtering.
--
-- Engineering Tip:
--   Prefer the CTE form for readability and reuse; prefer the subquery
--   form only for one-off, throwaway queries.


-- ==========================================================
-- Summary
-- ==========================================================
-- ROW_NUMBER() gives every row a unique sequential number. It has no
-- concept of ties -- for tie-aware ranking, see RANK() and DENSE_RANK()
-- in the next two modules.

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Referencing the window function alias directly in WHERE.
-- 2. Omitting ORDER BY inside OVER(), producing non-deterministic order.
-- 3. Assuming ties get the same number (they never do with ROW_NUMBER()).

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- ROW_NUMBER() requires a sort on the ORDER BY column(s). Index the
-- sort column when working with large tables to avoid an expensive
-- filesort in the query execution plan (check with EXPLAIN).

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. How does ROW_NUMBER() handle duplicate values in ORDER BY?
-- 2. Why can't you filter on a window function alias in WHERE?
-- 3. How would you deduplicate rows using ROW_NUMBER()?

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-functions-usage.html
