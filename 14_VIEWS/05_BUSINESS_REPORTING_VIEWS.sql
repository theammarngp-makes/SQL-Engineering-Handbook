-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 05 — Business Reporting Views
-- Business Obj: Build a governed semantic layer for a leadership revenue
--               dashboard, layering Views on top of Module 01's base View.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql first.
-- =============================================================================

-- Business Scenario:
-- Leadership wants monthly revenue trend with month-over-month growth,
-- and a customer segmentation view, both dashboard-ready.

-- Production Solution — monthly trend with window function
CREATE OR REPLACE VIEW vw_monthly_revenue_trend AS
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS revenue_month,
    SUM(oi.quantity * oi.unit_price) AS monthly_revenue,
    LAG(SUM(oi.quantity * oi.unit_price))
        OVER (ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')) AS prior_month_revenue
FROM sales_orders AS o
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'COMPLETED'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m');

SELECT * FROM vw_monthly_revenue_trend ORDER BY revenue_month;

-- Explanation:
-- LAG() over the aggregated monthly grain computes prior-month revenue in
-- the same View — no dashboard-side calculated field required.

-- Layered View: growth percentage built ON TOP of vw_monthly_revenue_trend
CREATE OR REPLACE VIEW vw_monthly_revenue_growth AS
SELECT
    revenue_month,
    monthly_revenue,
    prior_month_revenue,
    CASE
        WHEN prior_month_revenue IS NULL THEN NULL
        WHEN prior_month_revenue = 0 THEN NULL
        ELSE ROUND(
            (monthly_revenue - prior_month_revenue) / prior_month_revenue * 100, 2
        )
    END AS pct_growth_mom
FROM vw_monthly_revenue_trend;

SELECT * FROM vw_monthly_revenue_growth ORDER BY revenue_month;

-- Engineering Notes:
-- This is a nested View (vw_monthly_revenue_growth reads from
-- vw_monthly_revenue_trend, which reads from base tables). Nesting is
-- legitimate for readability and reuse, but every extra layer is a
-- candidate for the TEMPTABLE performance trap — see Module 07 before
-- nesting more than 2 levels deep in a high-traffic reporting path.

-- Production Solution — customer segmentation for dashboard filters
CREATE OR REPLACE VIEW vw_customer_segment_summary AS
SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    CASE
        WHEN DATEDIFF(CURDATE(), c.signup_date) < 90 THEN 'New'
        WHEN MAX(o.order_date) IS NULL
            OR DATEDIFF(CURDATE(), MAX(o.order_date)) > 180 THEN 'At Risk'
        ELSE 'Active'
    END AS customer_segment,
    COALESCE(SUM(CASE WHEN o.status = 'COMPLETED'
                       THEN oi.quantity * oi.unit_price END), 0) AS lifetime_revenue
FROM sales_customers AS c
LEFT JOIN sales_orders AS o ON o.customer_id = c.customer_id
LEFT JOIN sales_order_items AS oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.customer_name, c.region, c.signup_date;

SELECT * FROM vw_customer_segment_summary ORDER BY lifetime_revenue DESC;

-- Expected Output (4 rows, one per customer):
-- customer_segment reflects signup recency and completed-order recency;
-- lifetime_revenue uses COALESCE so customers with zero completed orders
-- show 0.00, not NULL, which matters directly for BI tool number formatting.

-- Performance Notes:
-- vw_customer_segment_summary aggregates and uses CASE inside aggregation —
-- this disqualifies ALGORITHM = MERGE and always runs as TEMPTABLE. Fine
-- for a dashboard refreshing every few minutes; verify with EXPLAIN before
-- using this pattern inside a high-frequency application query (Module 07).

-- Common Mistakes:
-- Returning NULL for lifetime_revenue on customers with no completed
-- orders instead of 0 — many BI tools render NULL as a blank cell or
-- break percentage-of-total calculations that assume numeric zero.

-- Alternative Solution (single-pass version without the nested View,
-- shown for comparison — less readable, harder to reuse prior_month_revenue
-- elsewhere, but avoids one layer of nesting):
CREATE OR REPLACE VIEW vw_monthly_revenue_growth_flat AS
SELECT
    revenue_month,
    monthly_revenue,
    prior_month_revenue,
    CASE
        WHEN prior_month_revenue IS NULL OR prior_month_revenue = 0 THEN NULL
        ELSE ROUND((monthly_revenue - prior_month_revenue) / prior_month_revenue * 100, 2)
    END AS pct_growth_mom
FROM (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS revenue_month,
        SUM(oi.quantity * oi.unit_price) AS monthly_revenue,
        LAG(SUM(oi.quantity * oi.unit_price))
            OVER (ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')) AS prior_month_revenue
    FROM sales_orders AS o
    INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'COMPLETED'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
) AS monthly;

-- Interview Insight:
-- Being asked to justify layered Views vs. one flat View is a design
-- question, not a syntax question — the correct answer weighs reusability
-- (other Views can reuse vw_monthly_revenue_trend) against the small
-- additional TEMPTABLE nesting cost.

-- Further Challenge:
-- Add a vw_regional_revenue_summary View that joins
-- vw_customer_segment_summary by region, and produce total lifetime_revenue
-- per region per segment using ROLLUP (Module 10 concept, reapplied here).
