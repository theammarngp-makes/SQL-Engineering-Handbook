-- ============================================================
-- Module 15, File 02 — B-Tree Indexes
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. Range scan WITHOUT a supporting index
-- ------------------------------------------------------------
EXPLAIN
SELECT *
FROM orders
WHERE order_date BETWEEN '2026-01-01' AND '2026-01-31';
-- Expected type: ALL (full scan)

-- ------------------------------------------------------------
-- 2. Create a B-Tree index on the range column
-- ------------------------------------------------------------
CREATE INDEX idx_orders_order_date
    ON orders (order_date);

-- ------------------------------------------------------------
-- 3. Re-run — the optimizer should now walk the leaf chain
--    instead of scanning the full table
-- ------------------------------------------------------------
EXPLAIN
SELECT *
FROM orders
WHERE order_date BETWEEN '2026-01-01' AND '2026-01-31';
-- Expected type: range
-- Expected key:  idx_orders_order_date

-- ------------------------------------------------------------
-- 4. Demonstrate ordered traversal for free: ORDER BY on an
--    indexed column can avoid a separate sort step
-- ------------------------------------------------------------
EXPLAIN
SELECT order_id, order_date
FROM orders
ORDER BY order_date
LIMIT 50;
-- Look for absence of "Using filesort" in the Extra column —
-- the B+Tree's sorted leaf order satisfies ORDER BY directly.

-- ------------------------------------------------------------
-- 5. Illustrate page-split cost: sequential vs. random insert
--    pattern (conceptual — run against a scratch table locally)
-- ------------------------------------------------------------
-- CREATE TABLE scratch_seq (id BIGINT UNSIGNED PRIMARY KEY, payload CHAR(50));
-- CREATE TABLE scratch_uuid (id CHAR(36) PRIMARY KEY, payload CHAR(50));
-- Insert 1M sequential integers into scratch_seq and 1M random UUIDs
-- into scratch_uuid, then compare INSERT throughput and resulting
-- table fragmentation (SHOW TABLE STATUS) between the two.

-- ------------------------------------------------------------
-- 6. Cleanup
-- ------------------------------------------------------------
-- DROP INDEX idx_orders_order_date ON orders;
