-- ==========================================================
-- SQL Engineering Handbook
--
-- Topic:        FIRST_VALUE(), LAST_VALUE(), NTILE()
-- Module:       07_Window_Functions / 06_FIRST_LAST_NTILE
-- Difficulty:   Intermediate
-- Author:       SQL Engineering Handbook Contributors
-- Description:  Retrieve boundary values (first/last) within a window
--               frame and split rows into equal-sized buckets.
-- Prerequisites: 01_ROW_NUMBER, 04_PARTITION_BY
-- Dataset:      employes JOIN departments
-- Learning
-- Objectives:   1. Retrieve the first value in an ordered window.
--               2. Retrieve the true last value using the correct
--                  frame clause.
--               3. Bucket rows into equal groups with NTILE().
-- ==========================================================


-- ==========================================================
-- Q1 -- Show First Employee Using FIRST_VALUE()
-- ==========================================================
-- Problem Statement:
--   For every row, show the name of the first employee in emp_id
--   order (optionally scoped per department).

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    FIRST_VALUE(e.emp_name) OVER (
        -- PARTITION BY d.dept_name    -- uncomment to scope per department
        ORDER BY e.emp_id
    ) AS first_emp
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Explanation:
--   FIRST_VALUE() works correctly with the default frame
--   (RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) because the
--   "first" row of any growing window is always the same row.
--
-- Business Use Case:
--   Tag every row with the earliest-hired employee's name for a
--   tenure-comparison report. Uncomment PARTITION BY to get the
--   earliest hire *per department* instead of company-wide.


-- ==========================================================
-- Q2 -- Show Last Employee Using LAST_VALUE()
-- ==========================================================
-- Problem Statement:
--   For every row, show the name of the last employee in emp_id order.
--
-- Engineering Tip (critical):
--   LAST_VALUE() REQUIRES an explicit frame clause. Without
--   "ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING", the
--   default frame stops at the CURRENT ROW, so LAST_VALUE() would
--   incorrectly return the current row's own value on every row.

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    LAST_VALUE(e.emp_name) OVER (
        -- PARTITION BY d.dept_name
        ORDER BY e.emp_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_emp
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Business Use Case:
--   Show the most recently hired employee's name on every row for
--   quick "how far are we from the newest hire" comparisons.


-- ==========================================================
-- Q3 -- Divide Employees Into Buckets Using NTILE()
-- ==========================================================
-- Problem Statement:
--   Split employees into N roughly equal-sized groups using NTILE().

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    NTILE(2) OVER (
        ORDER BY e.emp_id
    ) AS emp_grp
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Explanation:
--   NTILE(2) splits the ordered result set into 2 buckets. If the row
--   count is not evenly divisible by 2, the earlier bucket(s) absorb
--   the extra row(s).
--
-- Business Use Case:
--   NTILE(4) is the standard pattern for building customer spend
--   quartiles in marketing segmentation:
--
--   SELECT
--       customer_id,
--       total_spend,
--       NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile
--   FROM customer_orders_summary;


-- ==========================================================
-- Summary
-- ==========================================================
-- FIRST_VALUE() is "safe by default"; LAST_VALUE() is not -- it
-- requires an explicit frame clause to behave intuitively. NTILE()
-- is the standard tool for equal-sized bucketing (quartiles, deciles,
-- pay-grade splits).

-- ==========================================================
-- Common Mistakes
-- ==========================================================
-- 1. Using LAST_VALUE() without the UNBOUNDED FOLLOWING frame clause.
-- 2. Expecting NTILE() buckets to always be exactly equal in size.
-- 3. Forgetting PARTITION BY when "first/last" should be scoped per
--    group rather than the whole table.

-- ==========================================================
-- Performance Notes
-- ==========================================================
-- LAST_VALUE() with an UNBOUNDED FOLLOWING frame forces the engine to
-- materialize the full partition before it can return a value for any
-- row in that partition -- more expensive than FIRST_VALUE() on very
-- large partitions. Partition aggressively where possible.

-- ==========================================================
-- Interview Questions
-- ==========================================================
-- 1. Why does LAST_VALUE() need an explicit frame clause but
--    FIRST_VALUE() does not?
-- 2. How would you assign customers into spend quartiles using SQL?
-- 3. What happens to NTILE() bucket sizes when rows aren't evenly
--    divisible by the bucket count?

-- ==========================================================
-- Further Reading
-- ==========================================================
-- https://dev.mysql.com/doc/refman/8.0/en/window-function-descriptions.html#function_first-value
-- https://dev.mysql.com/doc/refman/8.0/en/window-function-descriptions.html#function_ntile
