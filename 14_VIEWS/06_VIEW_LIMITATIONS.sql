-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 06 — View Limitations
-- Business Obj: Demonstrate dependency-breakage failure modes and the
--               correct pre-migration audit pattern.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql through 05_* first.
-- =============================================================================

-- Business Scenario:
-- Platform team is about to rename sales_order_items.unit_price to
-- item_unit_price. Before doing so, they must find every dependent View.

-- Production Solution — dependency audit query
SELECT
    TABLE_NAME AS view_name,
    VIEW_DEFINITION
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
    AND VIEW_DEFINITION LIKE '%unit_price%';

-- Expected Output: rows for vw_completed_order_revenue,
-- vw_monthly_revenue_trend, vw_customer_segment_summary, and any other
-- View built in this module referencing unit_price.

-- Explanation:
-- information_schema.VIEWS.VIEW_DEFINITION stores the View's SELECT text,
-- so a LIKE search is the practical (if blunt) dependency-finding tool
-- MySQL provides — there is no native CASCADE tracking for this.

-- Demonstrating the breakage: SELECT * View is fragile
CREATE OR REPLACE VIEW vw_fragile_star_example AS
SELECT * FROM sales_order_items;

SELECT * FROM vw_fragile_star_example LIMIT 3;

-- Simulate a column rename on the base table
ALTER TABLE sales_order_items CHANGE COLUMN unit_price item_unit_price DECIMAL(10,2);

-- The View still "exists" but the column set silently changed —
-- SELECT * FROM vw_fragile_star_example now returns item_unit_price
-- instead of unit_price, breaking any consumer that referenced the old name:
SELECT * FROM vw_fragile_star_example LIMIT 3;

-- Any View that explicitly named unit_price (not SELECT *) now fails loudly
-- at query time, e.g.:
-- SELECT * FROM vw_completed_order_revenue;
-- Expected error: 1054 (42S22): Unknown column 'oi.unit_price' in 'field list'

-- Engineering Notes:
-- Note the asymmetry: the ALTER TABLE statement itself succeeded with no
-- warning about dependent Views. Breakage is deferred to query time,
-- which is exactly why the information_schema audit step must happen
-- BEFORE the migration, not after something breaks in production.

-- Rolling back for the rest of the module to remain consistent:
ALTER TABLE sales_order_items CHANGE COLUMN item_unit_price unit_price DECIMAL(10,2);
DROP VIEW IF EXISTS vw_fragile_star_example;

-- Refresh dependent Views after rollback (idempotent — safe to rerun)
CREATE OR REPLACE VIEW vw_completed_order_revenue AS
SELECT
    c.customer_id, c.customer_name, c.region,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM sales_customers AS c
INNER JOIN sales_orders AS o ON o.customer_id = c.customer_id
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'COMPLETED'
GROUP BY c.customer_id, c.customer_name, c.region;

-- Demonstrating the "no parameters" limitation and its correct workaround
-- INVALID — Views cannot accept parameters:
-- CREATE VIEW vw_orders_by_range(p_start DATE, p_end DATE) AS
-- SELECT * FROM sales_orders WHERE order_date BETWEEN p_start AND p_end;

-- Correct workaround #1 — filter at query time against an unfiltered View:
CREATE OR REPLACE VIEW vw_all_orders_detail AS
SELECT o.order_id, o.customer_id, o.order_date, o.status,
       oi.product_name, oi.quantity, oi.unit_price
FROM sales_orders AS o
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id;

SELECT * FROM vw_all_orders_detail
WHERE order_date BETWEEN '2024-01-01' AND '2024-02-28';

-- Correct workaround #2 — stored procedure for true parameterization:
DELIMITER $$
CREATE PROCEDURE sp_orders_by_range(IN p_start DATE, IN p_end DATE)
BEGIN
    SELECT * FROM vw_all_orders_detail
    WHERE order_date BETWEEN p_start AND p_end;
END$$
DELIMITER ;

CALL sp_orders_by_range('2024-01-01', '2024-02-28');

-- Performance Notes:
-- vw_all_orders_detail filtered at query time performs identically to a
-- hand-written WHERE clause against the join directly — the View adds no
-- cost, confirming again that Views are an abstraction convenience, not a
-- caching or performance layer.

-- Common Mistakes:
-- Believing DROP TABLE protection ("table is used in a view or function")
-- extends to column-level changes. It does not — MySQL only blocks the
-- table-level DROP, never a column rename/drop that a View references.

-- Interview Insight:
-- "How would you safely rename a widely-used column?" — the strong answer
-- is: audit information_schema.VIEWS (and stored procedures/triggers) for
-- references first, update all dependents in the same migration/PR, test
-- in staging, then deploy — never rename-and-hope.

-- Further Challenge:
-- Write a single information_schema query that finds ALL Views in the
-- current schema referencing ANY column of sales_order_items, using a
-- UNION of LIKE patterns for each column name.
