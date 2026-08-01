-- ============================================================
-- Module 15, File 07 — Query Optimization with Indexes
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. Check current cardinality estimates
-- ------------------------------------------------------------
SHOW INDEX FROM orders;
-- Compare Cardinality across customer_id vs. status indexes —
-- customer_id should show a much higher distinct-value estimate.

-- ------------------------------------------------------------
-- 2. Refresh statistics after simulating a bulk load
-- ------------------------------------------------------------
-- (run after any large INSERT/DELETE batch)
ANALYZE TABLE orders;

-- ------------------------------------------------------------
-- 3. Demonstrate a hint overriding the optimizer's natural choice
--    (idx_orders_status already exists from 01_INDEX_FUNDAMENTALS.sql —
--    not recreated here to avoid a duplicate-key-name error if running
--    this module's files in order in one session)
-- ------------------------------------------------------------

-- Natural plan: optimizer likely ignores idx_orders_status (low
-- selectivity) and does a full scan
EXPLAIN
SELECT * FROM orders WHERE status = 'cancelled';

-- Forced plan: override the optimizer explicitly
EXPLAIN
SELECT * FROM orders FORCE INDEX (idx_orders_status)
WHERE status = 'cancelled';
-- Compare estimated rows/cost between the two plans. If
-- 'cancelled' is a rare status (long-tail value), the forced
-- index plan may actually be cheaper — this is exactly the kind
-- of skew a histogram helps the optimizer detect automatically.

-- ------------------------------------------------------------
-- 4. MySQL 8.0+ histogram creation for a skewed column
-- ------------------------------------------------------------
ANALYZE TABLE orders UPDATE HISTOGRAM ON status WITH 8 BUCKETS;

-- Re-run the natural (unhinted) query and compare the plan —
-- with a histogram in place, the optimizer may now correctly
-- choose the index for rare values like 'cancelled' without
-- needing FORCE INDEX at all.
EXPLAIN
SELECT * FROM orders WHERE status = 'cancelled';

-- ------------------------------------------------------------
-- 5. Drop the histogram / cleanup
-- ------------------------------------------------------------
-- ANALYZE TABLE orders DROP HISTOGRAM ON status;
-- DROP INDEX idx_orders_status ON orders;
