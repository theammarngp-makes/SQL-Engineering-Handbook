-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 03 — Updatable Views
-- Business Obj: Give a fulfillment tool safe, restricted write access to
--               pending orders only, via an updatable View.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql first.
-- =============================================================================

-- Business Scenario:
-- Fulfillment tooling should update order status for PENDING orders only,
-- and must never be able to "update its way out" of the View's own filter.

-- Production Solution
CREATE OR REPLACE VIEW vw_pending_orders AS
SELECT order_id, customer_id, order_date, status
FROM sales_orders
WHERE status = 'PENDING'
WITH CASCADED CHECK OPTION;

SELECT * FROM vw_pending_orders;

-- Expected Output (1 row):
-- order_id | customer_id | order_date | status
-- 106      | 4           | 2024-04-02 | PENDING

-- Explanation:
-- This View is structurally updatable: single table, no aggregation, no
-- DISTINCT, no joins.

-- This UPDATE is REJECTED by WITH CHECK OPTION, because the new row would
-- no longer satisfy status = 'PENDING':
-- UPDATE vw_pending_orders SET status = 'COMPLETED' WHERE order_id = 106;
-- Expected error: 1369 (HY000): CHECK OPTION failed 'vw_pending_orders'

-- This UPDATE succeeds — it stays within the View's own filter:
UPDATE vw_pending_orders SET order_date = '2024-04-03' WHERE order_id = 106;

SELECT * FROM vw_pending_orders;

-- Engineering Notes:
-- Without WITH CHECK OPTION, the earlier status='COMPLETED' UPDATE would
-- succeed silently, and the row would simply vanish from
-- vw_pending_orders's result set on the next SELECT — a classic
-- "disappearing row" bug that's very hard to diagnose from the application
-- side, since the UPDATE itself reports success.

-- Demonstrating INSERT through an updatable View
INSERT INTO vw_pending_orders (order_id, customer_id, order_date, status)
VALUES (108, 2, '2024-04-20', 'PENDING');

SELECT * FROM sales_orders WHERE order_id = 108;   -- confirms row landed in base table

-- This INSERT is REJECTED — the new row wouldn't satisfy the View's filter:
-- INSERT INTO vw_pending_orders (order_id, customer_id, order_date, status)
-- VALUES (109, 2, '2024-04-21', 'COMPLETED');
-- Expected error: 1369 (HY000): CHECK OPTION failed 'vw_pending_orders'

-- Performance Notes:
-- Writes through vw_pending_orders cost the same as writing directly to
-- sales_orders — MySQL performs no extra materialization for a MERGE-
-- eligible, single-table updatable View.

-- Demonstrating a NON-updatable View (for contrast)
CREATE OR REPLACE VIEW vw_orders_with_item_count AS
SELECT o.order_id, o.status, COUNT(oi.order_item_id) AS item_count
FROM sales_orders AS o
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.status;

-- This fails — aggregation + join disqualify updatability:
-- UPDATE vw_orders_with_item_count SET status = 'COMPLETED' WHERE order_id = 101;
-- Expected error: 1288 (HY000): The target table vw_orders_with_item_count
-- of the UPDATE is not updatable

-- Common Mistakes:
-- Assuming ANY View can be written through if you just try hard enough —
-- updatability is structural, determined at CREATE time by query shape, not
-- something you can force with a hint.

-- Alternative Solution (LOCAL vs CASCADED check option contrast):
CREATE OR REPLACE VIEW vw_pending_orders_local AS
SELECT order_id, customer_id, order_date, status
FROM sales_orders
WHERE status = 'PENDING'
WITH LOCAL CHECK OPTION;
-- With only one filter level here, LOCAL and CASCADED behave identically.
-- The distinction only matters once this View is nested inside another
-- filtered View — see 06_VIEW_LIMITATIONS.md.

-- Interview Insight:
-- A strong candidate volunteers the disappearing-row failure mode
-- unprompted when asked "what's WITH CHECK OPTION for?" — reciting the
-- syntax without explaining the bug it prevents signals shallow knowledge.

-- Further Challenge:
-- Build an updatable vw_active_customers View (signup_date <= CURDATE())
-- with WITH CHECK OPTION, and identify a write that WITH CHECK OPTION would
-- correctly reject.
