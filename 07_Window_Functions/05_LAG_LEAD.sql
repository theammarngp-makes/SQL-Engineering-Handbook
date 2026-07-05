-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        LAG() and LEAD()
-- Module:       07_Window_Functions / 05_LAG_LEAD
-- Difficulty:   Intermediate
-- Author:       SQL Engineering Handbook Contributors
-- Description:  LAG() looks backward to a previous row; LEAD() looks
--               forward to a following row, both relative to the
--               current row in the ORDER BY sequence.
-- Prerequisites: 01_ROW_NUMBER, 04_PARTITION_BY
-- Dataset:      employes
-- Learning
-- Objectives:   1. Retrieve previous/next row values.
--               2. Compute row-over-row differences.
--               3. Use the offset argument to look back/forward N rows.
-- ==========================================================


-- ==========================================================
-- Q1 -- Show Previous Employee ID Using LAG()
-- ==========================================================
-- Problem Statement:
--   For every employee, show the emp_id of the previous row in
--   emp_id order.

SELECT
    emp_id,
    emp_name,
    LAG(emp_id) OVER (ORDER BY emp_id) AS prev_emp_id
FROM employes;

-- Explanation:
--   The first row's prev_emp_id is NULL because there is no row
--   before it.


-- ==========================================================
-- Q2 -- Show Next Employee ID Using LEAD()
-- ==========================================================
-- Problem Statement:
--   For every employee, show the emp_id of the following row.

SELECT
    emp_id,
    emp_name,
    LEAD(emp_id) OVER (ORDER BY emp_id) AS next_emp_id
FROM employes;

-- Explanation:
--   The last row's next_emp_id is NULL because there is no row after it.


-- ==========================================================
-- Q3 -- Show Current Employee and Previous Employee Name
-- ==========================================================
-- Problem Statement:
--   Show each employee's name alongside the name of the employee
--   immediately before them.

SELECT
    emp_id,
    emp_name AS current_emp_name,
    LAG(emp_name) OVER (ORDER BY emp_id) AS prev_emp_name
FROM employes;

-- Business Use Case:
--   Useful for building "who came before you" style audit trails or
--   sequential onboarding order reports.


-- ==========================================================
-- Q4 -- Show Current Employee and Next Employee Name
-- ==========================================================
-- Problem Statement:
--   Show each employee's name alongside the name of the employee
--   immediately after them.

SELECT
    emp_id,
    emp_name AS current_emp_name,
    LEAD(emp_name) OVER (ORDER BY emp_id) AS next_emp_name
FROM employes;


-- ==========================================================
-- Q5 -- Show Difference Between Current and Previous emp_id
-- ==========================================================
-- Problem Statement:
--   Show the numeric gap between each employee's emp_id and the
--   previous employee's emp_id, plus a variant using a 2-row offset.

SELECT
    emp_name,
    emp_id AS current_emp_id,
    LAG(emp_id) OVER (ORDER BY emp_id) AS prev_emp_id,
    emp_id - LAG(emp_id) OVER (ORDER BY emp_id)    AS diff_emp_id,
    emp_id - LAG(emp_id, 2) OVER (ORDER BY emp_id) AS diff_emp_id_2
FROM employes;

-- Explanation:
--   diff_emp_id     = gap to the immediately previous row.
--   diff_emp_id_2   = gap to the row two positions back, demonstrating
--                     the optional offset argument: LAG(column, N).
--
-- Business Use Case (the classic LAG() pattern -- Month-over-Month
-- growth, generalized beyond emp_id):
--
--   SELECT
--       month,
--       sales,
--       sales - LAG(sales) OVER (ORDER BY month) AS sales_growth
--   FROM monthly_sales;
--
-- Other real-world equivalents of this exact pattern:
--   - Previous Day Sales comparison
--   - Stock Price Changes (price - LAG(price))
--   - Customer Activity Tracking (days since last login)
--   - Revenue Trend deltas


-- ==========================================================
-- Summary
-- ==========================================================
-- LAG() and LEAD() eliminate the need for self-joins when comparing a
-- row to its neighbor in an ordered sequence. Pair with PARTITION BY
-- whenever "previous" must stay scoped to a customer, account, or
-- other business entity.

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Omitting ORDER BY inside OVER(), making "previous/next" undefined.
-- 2. Forgetting the first/last row will contain NULL unless a default
--    value is supplied as the third argument.
-- 3. Comparing across partition boundaries by accident when the
--    comparison should have been scoped with PARTITION BY.

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- LAG()/LEAD() require the same sorted single pass as other window
-- functions. They are dramatically cheaper than the equivalent
-- self-join pattern (`JOIN table t2 ON t2.id = t1.id - 1`), which does
-- not generalize correctly when the sort/id column has gaps.

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. How would you calculate month-over-month growth using SQL?
-- 2. What does LAG(column, 2) do differently from LAG(column)?
-- 3. How do you avoid NULL results on the first row of a LAG() column?

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-function-descriptions.html#function_lag
