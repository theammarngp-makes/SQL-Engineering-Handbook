-- =============================================================================
-- Module      : 14 — Views
-- File        : 11 — Solutions to 10_PRACTICE_PROBLEMS.md
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql and 08_REAL_WORLD_CASE_STUDIES.sql first.
-- =============================================================================

-- =============================================================================
-- SECTION A — Foundational
-- =============================================================================

-- A1
CREATE OR REPLACE VIEW vw_amer_customers
    (customer_id, customer_name, region, signup_date) AS
SELECT customer_id, customer_name, region, signup_date
FROM sales_customers
WHERE region = 'AMER';

SELECT * FROM vw_amer_customers;

-- A2
CREATE OR REPLACE VIEW vw_completed_orders
    (order_id, customer_id, order_date) AS
SELECT order_id, customer_id, order_date
FROM sales_orders
WHERE status = 'COMPLETED'
WITH CHECK OPTION;

SELECT * FROM vw_completed_orders;

-- A3
-- vw_completed_order_revenue is NOT updatable: it joins three tables
-- (sales_customers, sales_orders, sales_order_items) and uses SUM() with
-- GROUP BY. Both a multi-table join and an aggregate function individually
-- disqualify updatability per the rules in Module 03.

-- =============================================================================
-- SECTION B — Intermediate
-- =============================================================================

-- B1
CREATE OR REPLACE VIEW vw_department_headcount_costs
    (department_name, headcount, total_annual_cost) AS
SELECT
    d.department_name,
    COUNT(e.employee_id),
    COALESCE(SUM(e.annual_salary), 0)
FROM hr_departments AS d
LEFT JOIN hr_employees AS e ON e.department_id = d.department_id
GROUP BY d.department_name;

SELECT * FROM vw_department_headcount_costs ORDER BY total_annual_cost DESC;
-- LEFT JOIN + COALESCE ensures zero-headcount departments show 0, not NULL.

-- B2
CREATE OR REPLACE
    SQL SECURITY DEFINER
    VIEW vw_customer_order_counts
    (customer_name, completed_order_count) AS
SELECT
    c.customer_name,
    COUNT(o.order_id)
FROM sales_customers AS c
LEFT JOIN sales_orders AS o
    ON o.customer_id = c.customer_id AND o.status = 'COMPLETED'
GROUP BY c.customer_name;

SELECT * FROM vw_customer_order_counts ORDER BY completed_order_count DESC;
-- GRANT SELECT ON vw_customer_order_counts TO 'some_role';
-- (no direct grant on sales_orders required for that role)

-- B3
EXPLAIN SELECT * FROM vw_department_headcount_costs;
-- TEMPTABLE — the GROUP BY + COUNT()/SUM() aggregation structurally
-- disqualifies MERGE, exactly as with vw_completed_order_revenue in
-- Module 07. Expect "Using temporary" in the Extra column.

-- B4
CREATE OR REPLACE VIEW vw_active_hr_departments
    (department_id, department_name, region) AS
SELECT department_id, department_name, region
FROM hr_departments
WHERE region != 'EMEA'
WITH LOCAL CHECK OPTION;

SELECT * FROM vw_active_hr_departments;

-- Should SUCCEED — region stays 'AMER', still satisfies the View's filter:
UPDATE vw_active_hr_departments
SET department_name = 'Sales & Revenue'
WHERE department_id = 10;

-- Should FAIL — changing region to 'EMEA' makes the row no longer satisfy
-- the View's own WHERE clause, and WITH CHECK OPTION rejects it:
-- UPDATE vw_active_hr_departments SET region = 'EMEA' WHERE department_id = 10;
-- Expected error: 1369 (HY000): CHECK OPTION failed 'vw_active_hr_departments'

-- =============================================================================
-- SECTION C — Advanced / Architecture
-- =============================================================================

-- C1
-- Layer 2 — Staging
CREATE OR REPLACE VIEW vw_stg_order_revenue_detail AS
SELECT
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.status,
    (oi.quantity * oi.unit_price) AS line_revenue
FROM sales_customers AS c
INNER JOIN sales_orders AS o ON o.customer_id = c.customer_id
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH);

-- Layer 3 — Marketing definition: reachable = any completed order, refunds ignored
CREATE OR REPLACE VIEW vw_marketing_reachable_customers AS
SELECT DISTINCT customer_id, customer_name
FROM vw_stg_order_revenue_detail
WHERE status = 'COMPLETED';

-- Layer 3 — Finance definition: net revenue = completed minus refunded value
CREATE OR REPLACE VIEW vw_finance_net_revenue AS
SELECT
    customer_id,
    customer_name,
    SUM(CASE WHEN status = 'COMPLETED' THEN line_revenue ELSE 0 END)
        - SUM(CASE WHEN status = 'REFUNDED' THEN line_revenue ELSE 0 END)
        AS net_revenue_ltm
FROM vw_stg_order_revenue_detail
GROUP BY customer_id, customer_name;

SELECT * FROM vw_marketing_reachable_customers;
SELECT * FROM vw_finance_net_revenue ORDER BY net_revenue_ltm DESC;
-- Both reporting Views read the same staging View but apply divergent,
-- explicitly named business rules — matching the Module 08 pattern.

-- C2
SELECT TABLE_NAME, VIEW_DEFINITION
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
    AND VIEW_DEFINITION LIKE '%annual_salary%';
-- Should find: vw_salary_bands (04), vw_department_headcount_costs (B1),
-- and any other View in this module referencing annual_salary directly.

-- C3
CREATE TABLE IF NOT EXISTS tbl_monthly_revenue_growth_snapshot (
    revenue_month VARCHAR(7) PRIMARY KEY,
    monthly_revenue DECIMAL(14,2) NOT NULL,
    prior_month_revenue DECIMAL(14,2),
    pct_growth_mom DECIMAL(6,2),
    refreshed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_refresh_monthly_revenue_growth
ON SCHEDULE EVERY 1 DAY STARTS (CURDATE() + INTERVAL 1 DAY + INTERVAL 2 HOUR)
DO
BEGIN
    REPLACE INTO tbl_monthly_revenue_growth_snapshot
        (revenue_month, monthly_revenue, prior_month_revenue, pct_growth_mom)
    SELECT revenue_month, monthly_revenue, prior_month_revenue, pct_growth_mom
    FROM vw_monthly_revenue_growth;
END$$
DELIMITER ;

-- Justification: order data arrives throughout each business day, so a
-- MONTHLY trend metric doesn't need intraday freshness — a daily refresh
-- at 2 AM (low-traffic window) after the prior day's orders are fully
-- settled is sufficient accuracy for a monthly-grain dashboard metric,
-- and far cheaper than refreshing on every read.

-- C4
-- Risk: vw_customer_segment_summary is already TEMPTABLE (aggregation +
-- CASE, per Module 07). Nesting it into another join for a real-time,
-- per-support-ticket query means paying that full aggregation cost on
-- EVERY ticket open — this will not scale and will add latency directly
-- to a customer-facing support tool.
--
-- Alternative: maintain tbl_customer_360_snapshot as a physical summary
-- table refreshed on a schedule (e.g., every 15 minutes via EVENT, or
-- triggered by an ETL job on order/account change), and have the support
-- tool query that table directly — trading a small staleness window for
-- guaranteed low, predictable read latency on a customer-facing path.
CREATE TABLE IF NOT EXISTS tbl_customer_360_snapshot (
    customer_id INT PRIMARY KEY,
    customer_segment VARCHAR(20),
    lifetime_revenue DECIMAL(14,2),
    account_type VARCHAR(30),
    refreshed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- Refresh via scheduled EVENT joining vw_customer_segment_summary and
-- finance_accounts, following the same REPLACE INTO pattern as C3.
