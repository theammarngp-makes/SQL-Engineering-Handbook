-- ============================================================================
-- MODULE 16, LESSON 10 : CLOUD COST OPTIMIZATION & RESOURCE GOVERNANCE
-- ============================================================================
-- SETUP: Run 00_Schema.sql first. Uses the shared `transactions` table.
-- ENGINE NOTE: EXPLAIN ANALYZE syntax (Postgres/MySQL 8+). On MariaDB,
-- substitute `ANALYZE` for `EXPLAIN ANALYZE`.
-- ============================================================================

-- CASE 1: "recent high-value transactions" dashboard -- fast in isolation,
-- expensive at scale on a non-SARGable scan.

-- POOR PERFORMING / EXPENSIVE VERSION
-- Non-SARGable (Lesson 03), defeats partition pruning on a cloud warehouse.
EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE YEAR(transaction_date) = 2025
    AND transaction_amount > 500;

-- OPTIMIZED VERSION
-- SARGable range predicate + explicit column projection. Narrowed to a
-- month (2025 alone is ~half the table -- Lesson 07's "measure, don't
-- assume": a low-selectivity range legitimately won't be chosen).
CREATE INDEX idx_transactions_date_amount ON transactions (transaction_date, transaction_amount);

EXPLAIN ANALYZE
SELECT transaction_id, processed_by_emp_id, transaction_date, transaction_amount
FROM transactions
WHERE transaction_date >= '2025-06-01'
    AND transaction_date <  '2025-07-01'
    AND transaction_amount > 500;

-- EXPLAIN / COST ANALYSIS DISCUSSION
-- The poor version evaluates YEAR() for every row, forcing a full scan
-- regardless of the index, and returns every column. The optimized
-- version seeks into idx_transactions_date_amount's June-2025 range and
-- reads ~2 orders of magnitude fewer rows.
--
-- CLOUD COST TRANSLATION:
--   BigQuery:  poor scans every byte of every column across the whole
--              table; optimized, on a table partitioned by
--              transaction_date, prunes to one month's partition.
--   Snowflake: poor scans most/all micro-partitions; optimized prunes to
--              only the partitions overlapping June 2025.
--   RDS/Aurora: poor's `shared read` (billed IOPS) scales with table size;
--              optimized's scales with the matching index range only.

-- CASE 2: wide SELECT * vs. explicit projection at join scale

-- POOR PERFORMING / EXPENSIVE VERSION
EXPLAIN ANALYZE
SELECT *
FROM transactions t
JOIN employes e ON e.emp_id = t.processed_by_emp_id
JOIN departments d ON d.dept_id = e.dept_id
WHERE t.transaction_status = 'FLAGGED';

-- OPTIMIZED VERSION
EXPLAIN ANALYZE
SELECT
    t.transaction_id, e.emp_name, d.dept_name,
    t.transaction_amount, t.transaction_date
FROM transactions t
JOIN employes e ON e.emp_id = t.processed_by_emp_id
JOIN departments d ON d.dept_id = e.dept_id
WHERE t.transaction_status = 'FLAGGED';

-- EXECUTION PLAN DISCUSSION
-- On a wide production table (30-40+ columns), SELECT * across a
-- three-way join multiplies wasted bytes on every table -- the highest
-- blast-radius cost anti-pattern on columnar cloud warehouses, precisely
-- because it causes no visible latency problem at review-time volumes.

-- WASTE DETECTION: local equivalent of the lesson's metadata queries
SELECT table_schema, table_name, data_length, index_length,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_size_mb
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY (data_length + index_length) DESC;

-- CLOUD-NATIVE REFERENCE (not runnable locally):
-- BigQuery:
-- SELECT user_email, query, total_bytes_billed
-- FROM `region-us`.INFORMATION_SCHEMA.JOBS
-- WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
-- ORDER BY total_bytes_billed DESC LIMIT 10;
-- Snowflake:
-- SELECT warehouse_name, SUM(credits_used) AS total_credits
-- FROM snowflake.account_usage.warehouse_metering_history
-- WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
-- GROUP BY warehouse_name ORDER BY total_credits DESC;

-- INTERVIEW INSIGHT
-- Q: "Your query passes every latency SLA. Why block it in cost review?"
-- A: Latency and cost are correlated, not identical, on any
--    consumption-billed engine. Check the bytes-scanned/I/O-cost signal
--    explicitly, exactly as Case 1 demonstrates.

-- FURTHER EXPERIMENTS
-- 1. `SHOW STATUS LIKE 'Handler_read%'` before/after each query above.
-- 2. Add (transaction_status, transaction_id) and re-check Case 2's plan.
-- 3. Compare `bq query --dry_run` bytes-processed on real BigQuery if available.
