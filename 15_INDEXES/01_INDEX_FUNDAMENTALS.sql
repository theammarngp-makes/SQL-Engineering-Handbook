-- ============================================================
-- Module 15, File 01 — Index Fundamentals
-- Engine: MySQL 8.0+
-- Dataset: e-commerce `orders` table (assumes ~40M rows in production;
--          scale down row counts locally to see relative EXPLAIN cost,
--          not absolute timing)
-- ============================================================

-- ------------------------------------------------------------
-- 0. Reference schema (see 00_SETUP or handbook root README for
--    full dataset definition). Shown here for context only.
-- ------------------------------------------------------------
-- CREATE TABLE orders (
--     order_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
--     customer_id  BIGINT UNSIGNED NOT NULL,
--     order_date   DATE NOT NULL,
--     status       VARCHAR(20) NOT NULL,
--     total_amount DECIMAL(10,2) NOT NULL
-- ) ENGINE = InnoDB;

-- ------------------------------------------------------------
-- 1. Baseline: query with NO supporting index
--    Run EXPLAIN before creating any index on customer_id.
-- ------------------------------------------------------------
EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 88291;

-- Expected `type` column: ALL   (full table scan)
-- Expected `rows` column: ~ total row count in the table
-- This is the O(n) case described in the companion .md file.

-- ------------------------------------------------------------
-- 2. Create the index
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer_id
    ON orders (customer_id);

-- ------------------------------------------------------------
-- 3. Re-run the same query — compare the plan
-- ------------------------------------------------------------
EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 88291;

-- Expected `type` column: ref     (index seek on a non-unique index)
-- Expected `key` column:  idx_orders_customer_id
-- Expected `rows` column: dramatically lower than Step 1

-- ------------------------------------------------------------
-- 4. Demonstrate the optimizer IGNORING an available index
--    on a low-selectivity predicate.
-- ------------------------------------------------------------
CREATE INDEX idx_orders_status
    ON orders (status);

-- If ~50% of rows are 'completed', the optimizer will very likely
-- still choose a full scan even though idx_orders_status exists —
-- reading half the table via an index lookup is more expensive
-- than reading it sequentially.
EXPLAIN
SELECT *
FROM orders
WHERE status = 'completed';

-- Expected `type` column: ALL, despite the index existing.
-- This is the cost-based optimization behavior discussed in the
-- Engineering Notes section of 01_INDEX_FUNDAMENTALS.md.

-- ------------------------------------------------------------
-- 5. Confirm current indexes on the table
-- ------------------------------------------------------------
SHOW INDEX FROM orders;

-- ------------------------------------------------------------
-- 6. Cleanup (for repeatable local runs)
-- ------------------------------------------------------------
-- DROP INDEX idx_orders_customer_id ON orders;
-- DROP INDEX idx_orders_status ON orders;
