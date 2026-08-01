-- ============================================================
-- Module 15, File 08 — EXPLAIN & Execution Plans
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. Baseline EXPLAIN (estimate only, safe on production)
-- ------------------------------------------------------------
EXPLAIN
SELECT o.order_id, c.email
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.status = 'completed';

-- ------------------------------------------------------------
-- 2. EXPLAIN FORMAT=JSON for full cost detail
-- ------------------------------------------------------------
EXPLAIN FORMAT=JSON
SELECT o.order_id, c.email
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.status = 'completed';

-- ------------------------------------------------------------
-- 3. EXPLAIN ANALYZE — actual execution stats (executes the
--    query; safe here since it's read-only)
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT o.order_id, c.email
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.status = 'completed';
-- Compare "rows" (estimate) against "actual rows" per node —
-- large divergence signals a statistics problem, per File 07.

-- ------------------------------------------------------------
-- 4. Spot a filesort — ORDER BY on a non-indexed column
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM orders
ORDER BY total_amount DESC
LIMIT 10;
-- Expect Extra: "Using filesort" — total_amount has no supporting
-- index for this ORDER BY.

-- ------------------------------------------------------------
-- 5. Remove the filesort by indexing the ORDER BY column
-- ------------------------------------------------------------
CREATE INDEX idx_orders_total_amount ON orders (total_amount);

EXPLAIN
SELECT * FROM orders
ORDER BY total_amount DESC
LIMIT 10;
-- "Using filesort" should now be absent — the B+Tree's sorted
-- order satisfies ORDER BY directly (File 02).

-- ------------------------------------------------------------
-- 6. PostgreSQL equivalent with buffer detail
-- ------------------------------------------------------------
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT o.order_id, c.email
-- FROM orders o
-- JOIN customers c ON o.customer_id = c.id
-- WHERE o.status = 'completed';

-- ------------------------------------------------------------
-- 7. Cleanup
-- ------------------------------------------------------------
-- DROP INDEX idx_orders_total_amount ON orders;
