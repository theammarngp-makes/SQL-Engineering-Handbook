-- ============================================================
-- Module 15, File 05 — Covering Indexes & Index-Only Scans
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. Narrow index — NOT covering for the target query
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer_only
    ON orders (customer_id);

EXPLAIN
SELECT order_id, order_date, status
FROM orders
WHERE customer_id = 88291;
-- Expect Extra: "Using where" (or similar) — NOT "Using index"
-- The engine seeks the index, then looks up each matching row
-- in the clustered index to fetch order_date/status.

-- ------------------------------------------------------------
-- 2. Composite index that happens to cover the query
--    (idx_orders_customer_date_status already exists live from
--    03_COMPOSITE_INDEXES.sql — not recreated here to avoid a
--    duplicate-key-name error running this module's files in order)
-- ------------------------------------------------------------

EXPLAIN
SELECT order_id, order_date, status
FROM orders
WHERE customer_id = 88291;
-- Expect Extra: "Using index" — index-only scan confirmed.
-- order_id is available "for free" because InnoDB secondary
-- indexes always store the primary key at the leaf.

-- ------------------------------------------------------------
-- 3. Break covering by widening the SELECT list
-- ------------------------------------------------------------
EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 88291;
-- Expect Extra reverts to a non-covering plan — total_amount
-- (and any other column) isn't in the covering index, so the
-- engine must fall back to a table lookup.

-- ------------------------------------------------------------
-- 4. PostgreSQL equivalent using INCLUDE (run on PostgreSQL 11+)
-- ------------------------------------------------------------
-- CREATE INDEX idx_orders_customer_covering
--     ON orders (customer_id)
--     INCLUDE (order_date, status);
--
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT order_id, order_date, status
-- FROM orders
-- WHERE customer_id = 88291;
-- -- Look for "Index Only Scan" in the plan output.

-- ------------------------------------------------------------
-- 5. Cleanup
-- ------------------------------------------------------------
-- DROP INDEX idx_orders_customer_only ON orders;
-- DROP INDEX idx_orders_customer_date_status ON orders;
