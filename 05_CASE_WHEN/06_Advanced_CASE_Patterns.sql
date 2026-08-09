-- =============================================================
-- LESSON 06: Advanced CASE Patterns
-- DIFFICULTY: Advanced
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- PATTERN 1: Conditional Aggregation (pivot rows -> columns)
-- SCENARIO: Sales ops wants one row per rep showing delivered
-- revenue, cancelled order count, and delivered order count -- all
-- in a single pass over `orders`.
-- -----------------------------------------------------------------
SELECT
    e.emp_id,
    e.emp_name,
    SUM(CASE WHEN o.order_status = 'delivered' THEN o.order_amount ELSE 0 END) AS delivered_revenue,
    SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END)              AS cancelled_orders,
    COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END)                   AS delivered_count
FROM employees e
JOIN orders o ON e.emp_id = o.emp_id
GROUP BY e.emp_id, e.emp_name
ORDER BY delivered_revenue DESC;

-- Expected output (against seed data):
-- emp_id | emp_name    | delivered_revenue | cancelled_orders | delivered_count
-- 4      | Karan Verma | 15000.00           | 1                | 1
-- 5      | Priya Nair  | 2200.00            | 0                | 1

-- -----------------------------------------------------------------
-- PATTERN 2: CASE + Window Function
-- SCENARIO: Flag each employee as their department's top earner
-- without collapsing the result to one row per department.
-- -----------------------------------------------------------------
SELECT
    e.emp_name,
    e.dept_id,
    e.salary,
    MAX(e.salary) OVER (PARTITION BY e.dept_id) AS dept_max_salary,
    CASE
        WHEN e.salary = MAX(e.salary) OVER (PARTITION BY e.dept_id) THEN 'Top Earner'
        ELSE 'Standard'
    END AS pay_tier
FROM employees e
ORDER BY e.dept_id, e.salary DESC;

-- -----------------------------------------------------------------
-- PATTERN 3: Nested CASE
-- SCENARIO: Distinguish "not yet reviewed" (NULL score) from actual
-- low performance -- collapsing them into one branch would be a
-- data-quality bug (treats missing data as bad data).
-- -----------------------------------------------------------------
SELECT
    e.emp_name,
    e.performance_score,
    CASE
        WHEN e.performance_score IS NULL THEN 'Not Yet Reviewed'
        ELSE
            CASE
                WHEN e.performance_score >= 4 THEN 'High Performer'
                WHEN e.performance_score >= 2 THEN 'Meets Expectations'
                ELSE 'Needs Improvement'
            END
    END AS performance_label
FROM employees e
ORDER BY e.emp_id;

-- -----------------------------------------------------------------
-- PATTERN 4: CASE inside ORDER BY -- custom priority sort
-- SCENARIO: Show Engineering department rows first, then everyone
-- else alphabetically -- a sort order no single column expresses.
-- -----------------------------------------------------------------
SELECT emp_name, dept_id
FROM employees
ORDER BY
    CASE WHEN dept_id = 1 THEN 0 ELSE 1 END,
    emp_name;

-- -----------------------------------------------------------------
-- PRODUCTION NOTE
-- Conditional aggregation (Pattern 1) is the pattern most likely to
-- show up verbatim in a dbt mart model or an executive dashboard
-- query -- it replaces what would otherwise be N separate queries
-- (one per status) plus an application-side join, with a single
-- efficient pass over the fact table.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- INTERVIEW DISCUSSION
-- Q: In Pattern 2, why use a window function instead of a subquery
--    joined back to employees?
-- A: The window function computes the per-department maximum
--    without a second pass over the table or an extra join -- one
--    query, one scan (logically), same result. It's also far more
--    composable if you later need multiple window-based flags in the
--    same SELECT.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Extend Pattern 1 to also compute a "refund_rate" column:
--    refunded revenue / total revenue per rep.
-- 2. Rewrite Pattern 3 flattened into a single CASE with an ordered
--    list of WHEN branches (score IS NULL first) and compare
--    readability against the nested version.
-- -----------------------------------------------------------------
