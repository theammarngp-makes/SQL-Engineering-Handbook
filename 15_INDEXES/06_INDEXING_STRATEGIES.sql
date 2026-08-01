-- ============================================================
-- Module 15, File 06 — Indexing Strategies (OLTP vs OLAP)
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. OLTP example: minimal, purpose-built indexing on a hot
--    write table (idx_orders_customer_id already exists live from
--    01_INDEX_FUNDAMENTALS.sql — not recreated here to avoid a
--    duplicate-key-name error running this module's files in order)
--    Deliberately NOT indexing every column on this table — status,
--    total_amount, etc. stay unindexed unless a specific, frequent
--    query justifies it.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- 2. Star-schema OLAP example: broad indexing on a fact table
-- ------------------------------------------------------------
-- CREATE TABLE fact_sales (
--     sale_id       BIGINT UNSIGNED PRIMARY KEY,
--     customer_key  BIGINT UNSIGNED NOT NULL,
--     product_key   BIGINT UNSIGNED NOT NULL,
--     date_key      INT NOT NULL,
--     store_key     BIGINT UNSIGNED NOT NULL,
--     quantity      INT NOT NULL,
--     revenue       DECIMAL(12,2) NOT NULL
-- );

CREATE INDEX idx_fact_sales_customer ON fact_sales (customer_key);
CREATE INDEX idx_fact_sales_product  ON fact_sales (product_key);
CREATE INDEX idx_fact_sales_date     ON fact_sales (date_key);
CREATE INDEX idx_fact_sales_store    ON fact_sales (store_key);

-- ------------------------------------------------------------
-- 3. Identify unused indexes (MySQL 8.0+, Performance Schema
--    must be enabled)
-- ------------------------------------------------------------
SELECT object_schema, object_name, index_name
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE index_name IS NOT NULL
  AND count_star = 0
  AND object_schema = DATABASE()
ORDER BY object_name, index_name;
-- Any index appearing here has never been used since the
-- Performance Schema counters were last reset — a strong signal
-- (not a guarantee) that it may be safe to drop.

-- ------------------------------------------------------------
-- 4. PostgreSQL equivalent for unused-index detection
-- ------------------------------------------------------------
-- SELECT schemaname, relname, indexrelname, idx_scan
-- FROM pg_stat_user_indexes
-- WHERE idx_scan = 0
-- ORDER BY relname;

-- ------------------------------------------------------------
-- 5. Benchmark write cost of over-indexing (conceptual — run
--    locally against a scratch copy of orders)
-- ------------------------------------------------------------
-- 1) Time 100,000 INSERTs against orders with 1 index.
-- 2) Add 4 more indexes covering rarely-used columns.
-- 3) Time 100,000 INSERTs again and compare throughput.

-- ------------------------------------------------------------
-- 6. Cleanup
-- ------------------------------------------------------------
-- DROP INDEX idx_orders_customer_id ON orders;
-- DROP INDEX idx_fact_sales_customer ON fact_sales;
-- DROP INDEX idx_fact_sales_product ON fact_sales;
-- DROP INDEX idx_fact_sales_date ON fact_sales;
-- DROP INDEX idx_fact_sales_store ON fact_sales;
