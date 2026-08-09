-- =============================================================
-- LESSON 07: Business Case Studies
-- DIFFICULTY: Advanced
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- CASE STUDY 1: Customer/Rep Value Segmentation (Retail)
-- -----------------------------------------------------------------
WITH rep_revenue AS (
    SELECT
        e.emp_id,
        e.emp_name,
        SUM(CASE WHEN o.order_status = 'delivered' THEN o.order_amount ELSE 0 END) AS lifetime_revenue
    FROM employees e
    JOIN orders o ON e.emp_id = o.emp_id
    GROUP BY e.emp_id, e.emp_name
)
SELECT
    emp_id,
    emp_name,
    lifetime_revenue,
    CASE
        WHEN lifetime_revenue >= 40000 THEN 'VIP'
        WHEN lifetime_revenue >= 10000 THEN 'Regular'
        ELSE 'New / Low Value'
    END AS value_segment
FROM rep_revenue
ORDER BY lifetime_revenue DESC;

-- -----------------------------------------------------------------
-- CASE STUDY 2: Employee Performance Bands (HR)
-- (see Lesson 06 Pattern 3 for the full nested-CASE explanation)
-- -----------------------------------------------------------------
SELECT
    emp_name,
    performance_score,
    CASE
        WHEN performance_score IS NULL THEN 'Not Yet Reviewed'
        WHEN performance_score >= 4 THEN 'High Performer'
        WHEN performance_score >= 2 THEN 'Meets Expectations'
        ELSE 'Needs Improvement'
    END AS performance_band
FROM employees
ORDER BY emp_id;

-- -----------------------------------------------------------------
-- CASE STUDY 3: Order Status / Fulfillment Monitoring (Logistics)
-- -----------------------------------------------------------------
SELECT
    e.emp_id,
    e.emp_name,
    SUM(CASE WHEN o.order_status = 'placed'    THEN 1 ELSE 0 END) AS placed_count,
    SUM(CASE WHEN o.order_status = 'shipped'   THEN 1 ELSE 0 END) AS shipped_count,
    SUM(CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_count,
    SUM(CASE WHEN o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
    SUM(CASE WHEN o.order_status = 'refunded'  THEN 1 ELSE 0 END) AS refunded_count
FROM employees e
JOIN orders o ON e.emp_id = o.emp_id
GROUP BY e.emp_id, e.emp_name
ORDER BY e.emp_id;

-- -----------------------------------------------------------------
-- CASE STUDY 4: Department Budget Risk Tiers (Finance)
-- Includes an explicit divide-by-zero guard.
-- -----------------------------------------------------------------
WITH dept_headcount AS (
    SELECT
        d.dept_id,
        d.dept_name,
        d.budget,
        COUNT(e.emp_id) AS headcount
    FROM departments d
    LEFT JOIN employees e ON d.dept_id = e.dept_id
    GROUP BY d.dept_id, d.dept_name, d.budget
)
SELECT
    dept_name,
    budget,
    headcount,
    CASE
        WHEN headcount = 0 THEN 'No Staff -- Review Required'
        WHEN budget / headcount < 200000 THEN 'Overstaffed Relative to Budget'
        WHEN budget / headcount > 800000 THEN 'Understaffed Relative to Budget'
        ELSE 'Balanced'
    END AS budget_risk_tier
FROM dept_headcount
ORDER BY budget_risk_tier;

-- -----------------------------------------------------------------
-- CASE STUDY 5: Relative Sales Rep Tiers with Window Functions (BI)
-- Uses PERCENT_RANK() so tiers stay meaningful as the business grows,
-- unlike Case Study 1's fixed-dollar thresholds.
-- -----------------------------------------------------------------
WITH rep_revenue AS (
    SELECT
        e.emp_id,
        e.emp_name,
        SUM(CASE WHEN o.order_status = 'delivered' THEN o.order_amount ELSE 0 END) AS lifetime_revenue
    FROM employees e
    JOIN orders o ON e.emp_id = o.emp_id
    GROUP BY e.emp_id, e.emp_name
),
ranked AS (
    SELECT
        emp_id,
        emp_name,
        lifetime_revenue,
        PERCENT_RANK() OVER (ORDER BY lifetime_revenue DESC) AS revenue_percentile
    FROM rep_revenue
)
SELECT
    emp_id,
    emp_name,
    lifetime_revenue,
    CASE
        WHEN revenue_percentile <= 0.20 THEN 'Top 20%'
        WHEN revenue_percentile <= 0.50 THEN 'Middle 50%'
        ELSE 'Bottom Tier'
    END AS performance_tier
FROM ranked
ORDER BY lifetime_revenue DESC;

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Case Study 1: add a fourth tier, 'Churn Risk', for customers
--    whose lifetime_revenue > 0 but who have zero orders in the last
--    90 days (requires adding a "last order date" comparison).
-- 2. Case Study 4: replace the fixed ratio thresholds with
--    percentile-based thresholds across all departments, same idea
--    as Case Study 5.
-- -----------------------------------------------------------------
