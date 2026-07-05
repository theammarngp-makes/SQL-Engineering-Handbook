-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        Running Totals and Running Averages
-- Module:       07_Window_Functions / 07_RUNNING_TOTALS
-- Difficulty:   Intermediate
-- Author:       SQL Engineering Handbook Contributors
-- Description:  Turns SUM()/AVG() into cumulative, row-by-row
--               calculations by adding ORDER BY inside OVER().
-- Prerequisites: 01_ROW_NUMBER, 04_PARTITION_BY, 05_LAG_LEAD
-- Dataset:      employes JOIN departments
-- Learning
-- Objectives:   1. Build a running total with SUM() OVER().
--               2. Build a running average with AVG() OVER().
--               3. Restart cumulative calculations per group.
-- ==========================================================


-- ==========================================================
-- Q1 -- Create a Running Total of emp_id Using SUM() OVER()
-- ==========================================================
-- Problem Statement:
--   For every employee (ordered by emp_id), show the cumulative sum
--   of emp_id up to and including the current row.

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    SUM(e.emp_id) OVER (
        -- PARTITION BY d.dept_name    -- uncomment to run per department
        ORDER BY e.emp_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Expected Output (shape):
-- emp_id | running_total
-- -------|--------------
--  101   |     101
--  102   |     203      <- 101 + 102
--  105   |     308      <- 101 + 102 + 105
--
-- Explanation:
--   Adding ORDER BY changes the aggregate's frame from "the whole
--   table" to "every row from the start up to the current row" --
--   this is exactly what a running total is.
--
-- Business Use Case:
--   Directly transferable to real running-balance problems by
--   swapping emp_id for a transaction_amount column:
--
--   SELECT
--       transaction_date,
--       transaction_amount,
--       SUM(transaction_amount) OVER (
--           ORDER BY transaction_date
--           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--       ) AS running_balance
--   FROM account_transactions;


-- ==========================================================
-- Q2 -- Create a Running Average of emp_id Using AVG() OVER()
-- ==========================================================
-- Problem Statement:
--   For every employee (ordered by emp_id), show the cumulative
--   average of emp_id up to and including the current row.

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    AVG(e.emp_id) OVER (
        -- PARTITION BY d.dept_name
        ORDER BY e.emp_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_average
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Business Use Case:
--   The same pattern powers rolling/moving averages used to smooth
--   noisy day-to-day metrics (e.g., a 7-day moving average of sales)
--   once combined with a bounded frame such as
--   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW.


-- ==========================================================
-- Q3 (Bonus) -- Running Total Restarted Per Department
-- ==========================================================
-- Problem Statement:
--   Compute a running total of emp_id that restarts at zero for
--   every new department.

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    SUM(e.emp_id) OVER (
        PARTITION BY d.dept_name
        ORDER BY e.emp_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS dept_running_total
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Business Use Case:
--   Cumulative departmental budget consumption, where each
--   department's running total must not leak into the next
--   department's numbers.


-- ==========================================================
-- Q4 (Bonus) -- Each Employee's Share of the Final Cumulative Total
-- ==========================================================
-- Problem Statement:
--   Show what percentage of the final running total each employee
--   represents.

WITH totals AS (
    SELECT
        e.emp_id,
        e.emp_name,
        SUM(e.emp_id) OVER (
            ORDER BY e.emp_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,
        SUM(e.emp_id) OVER () AS grand_total
    FROM employes e
)
SELECT
    emp_id,
    emp_name,
    running_total,
    grand_total,
    ROUND(running_total * 100.0 / grand_total, 2) AS pct_of_total
FROM totals;

-- Explanation:
--   SUM(e.emp_id) OVER () with no ORDER BY computes one grand total
--   across the whole result set, repeated on every row -- contrast
--   this directly against Q1's running_total, which changes per row.
--
-- Business Use Case:
--   Pareto-style ("80/20") analysis: identify which employees/products
--   /customers account for the majority of a cumulative metric.


-- ==========================================================
-- Summary
-- ==========================================================
-- Adding ORDER BY to an aggregate window function converts a static
-- total into a running total. Adding PARTITION BY on top restarts
-- that running calculation per business group. This single pattern
-- covers the vast majority of "running balance" / "cumulative"
-- reporting requirements in production analytics.

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Omitting ORDER BY and getting one grand total instead of a
--    running total.
-- 2. Forgetting PARTITION BY when the running total must restart per
--    group.
-- 3. Relying on the implicit default frame instead of writing it
--    explicitly in production code.

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- Running totals are computed in a single O(n log n) sorted pass
-- (dominated by the ORDER BY sort), vastly cheaper than the legacy
-- correlated-subquery running-total pattern, which is O(n²).

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. How do you compute a running total in SQL without a self-join?
-- 2. What is the difference between SUM(x) OVER (ORDER BY y) and
--    SUM(x) OVER ()?
-- 3. How would you compute a 7-day moving average of daily sales?

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-functions-frames.html
