-- ============================================================
-- Module 15, File 03 — Composite Indexes & Leftmost Prefix Rule
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. Create the composite index
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer_date_status
    ON orders (customer_id, order_date, status);

-- ------------------------------------------------------------
-- 2. Uses column 1 only — still benefits from the index
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM orders
WHERE customer_id = 88291;
-- Expected key: idx_orders_customer_date_status, key_len covers col 1 only

-- ------------------------------------------------------------
-- 3. Uses columns 1-2 — narrower seek
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM orders
WHERE customer_id = 88291
  AND order_date = '2026-01-01';
-- Expected key_len covers cols 1-2

-- ------------------------------------------------------------
-- 4. Uses all three columns
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM orders
WHERE customer_id = 88291
  AND order_date = '2026-01-01'
  AND status = 'completed';
-- Expected key_len covers all 3 columns

-- ------------------------------------------------------------
-- 5. Skips column 1 — index CANNOT be used for this predicate
-- ------------------------------------------------------------
EXPLAIN
SELECT * FROM orders
WHERE status = 'completed';
-- Expected type: ALL (full scan) — leftmost prefix rule violated

-- ------------------------------------------------------------
-- 6. Compare: range column placed before trailing equality
--    (demonstrates why column ORDER matters, not just presence)
-- ------------------------------------------------------------
-- Poor ordering: range column (order_date) placed second-to-last
-- still works here since status IS the last column and unused
-- after a range predicate on order_date — status will be applied
-- as a post-filter, not part of the index seek.
EXPLAIN
SELECT * FROM orders
WHERE customer_id = 88291
  AND order_date > '2026-01-01'
  AND status = 'completed';
-- Expected: key_len covers cols 1-2 only; status filtered afterward
-- Compare against idx_orders_customer_status_date (below) where
-- status is placed BEFORE the range column.

-- ------------------------------------------------------------
-- 7. Better ordering for this exact query shape
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer_status_date
    ON orders (customer_id, status, order_date);

EXPLAIN
SELECT * FROM orders
WHERE customer_id = 88291
  AND status = 'completed'
  AND order_date > '2026-01-01';
-- Expected: key_len now covers all 3 columns — both equality
-- predicates (customer_id, status) narrow the seek before the
-- range predicate (order_date) is applied.

-- ------------------------------------------------------------
-- 8. Cleanup
-- ------------------------------------------------------------
-- DROP INDEX idx_orders_customer_date_status ON orders;
-- DROP INDEX idx_orders_customer_status_date ON orders;
