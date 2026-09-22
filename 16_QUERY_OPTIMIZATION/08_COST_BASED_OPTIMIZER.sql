-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : The Cost-Based Optimizer
-- ENGINE    : MySQL 8.0+ (primary), PostgreSQL notes included for reference
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Demonstrate statistics inspection, histogram creation, stale-statistics
--   symptoms, and optimizer hint behavior against the shared
--   employes/departments schema.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- INSPECTING WHAT THE OPTIMIZER KNOWS (MySQL 8.0+)
-- ----------------------------------------------------------------------------

-- MySQL: View index statistics for a table
SELECT *
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'employes';

-- MySQL: View table-level statistics (row estimates, avg row length)
SELECT TABLE_NAME, TABLE_ROWS, AVG_ROW_LENGTH, DATA_LENGTH, INDEX_LENGTH
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'employes';

-- MySQL 8.0+: Inspect column histograms (after creating them)
-- Note: MySQL does not maintain histograms automatically — you must
-- create them explicitly with ANALYZE TABLE ... UPDATE HISTOGRAM.
SELECT SCHEMA_NAME, TABLE_NAME, COLUMN_NAME,
       JSON_EXTRACT(HISTOGRAM, '$.\"number-of-buckets-specified\"') AS buckets,
       JSON_EXTRACT(HISTOGRAM, '$.\"sampling-rate\"') AS sampling_rate,
       JSON_EXTRACT(HISTOGRAM, '$.\"histogram-type\"') AS hist_type
FROM information_schema.COLUMN_STATISTICS
WHERE SCHEMA_NAME = DATABASE()
  AND TABLE_NAME = 'employes';

-- ENGINEERING NOTES
-- MySQL's optimizer uses index statistics (cardinality estimates stored in
-- each index) plus optional column histograms (MySQL 8.0+) to estimate
-- selectivity. Unlike PostgreSQL's pg_stats which exposes most_common_vals
-- and histogram_bounds directly, MySQL stores histogram data as a JSON
-- blob in information_schema.COLUMN_STATISTICS.

-- ----------------------------------------------------------------------------
-- CREATING AND INSPECTING HISTOGRAMS (MySQL 8.0+)
-- ----------------------------------------------------------------------------

-- Create histograms on columns used in WHERE clauses
ANALYZE TABLE employes UPDATE HISTOGRAM ON dept_id WITH 100 BUCKETS;
ANALYZE TABLE employes UPDATE HISTOGRAM ON hire_date WITH 100 BUCKETS;

-- Inspect the histogram detail
SELECT COLUMN_NAME, HISTOGRAM->>'$."histogram-type"' AS type,
       HISTOGRAM->>'$."number-of-buckets-specified"' AS buckets
FROM information_schema.COLUMN_STATISTICS
WHERE SCHEMA_NAME = DATABASE()
  AND TABLE_NAME = 'employes';

-- ----------------------------------------------------------------------------
-- REPRODUCING A STALE-STATISTICS SYMPTOM
-- ----------------------------------------------------------------------------
-- Simulate a bulk load, then compare plans before and after refreshing
-- statistics.

-- Step 1: baseline plan (assume statistics are current)
ANALYZE TABLE employes;

EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE dept_id = 4;

-- Step 2: simulate a large bulk insert that changes the table's actual
-- distribution significantly (illustrative — adjust volume for your
-- environment)
-- INSERT INTO employes (emp_name, dept_id, manager_id, hire_date)
-- SELECT CONCAT('Bulk_', seq), 4, NULL, CURRENT_DATE
-- FROM (
--     SELECT (a.N + b.N*10 + c.N*100 + d.N*1000 + e.N*10000 + 1) AS seq
--     FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
--           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
--          (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
--           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
--          (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
--           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
--          (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
--           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d,
--          (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
--           UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) e
-- ) seq_gen
-- WHERE seq <= 50000;

-- Step 3: re-run WITHOUT refreshing statistics — the optimizer may still
-- be planning against the OLD cardinality estimates
EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE dept_id = 4;

-- Step 4: refresh statistics, then re-run
ANALYZE TABLE employes;
ANALYZE TABLE employes UPDATE HISTOGRAM ON dept_id WITH 100 BUCKETS;

EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE dept_id = 4;

-- PERFORMANCE COMPARISON
-- Compare "estimated rows" (in EXPLAIN output) across steps 1, 3, and 4.
-- Step 3's estimate should diverge from the true row count for dept_id = 4
-- after the bulk load; step 4's estimate should realign with reality
-- after ANALYZE TABLE.

-- ----------------------------------------------------------------------------
-- MULTI-COLUMN CORRELATION
-- ----------------------------------------------------------------------------
-- If dept_id and location_id are correlated in departments (e.g. certain
-- departments only exist at certain locations), a combined filter on both
-- is often mis-estimated because the optimizer multiplies each column's
-- independent selectivity together by default.

EXPLAIN ANALYZE
SELECT *
FROM departments
WHERE dept_id = 4
  AND location_id = 2;

-- MySQL 8.0 does not have PostgreSQL-style extended statistics
-- (CREATE STATISTICS ... ON col1, col2). To help MySQL with correlated
-- columns, consider:
-- 1. A composite index on (dept_id, location_id) so the optimizer sees
--    the combined cardinality directly from index statistics.
-- 2. Histogram on each individual column (limited help for correlation).
-- 3. Optimizer hints to override bad estimates if needed.

-- ----------------------------------------------------------------------------
-- DROPPING HISTOGRAMS
-- ----------------------------------------------------------------------------
-- Remove histograms when they are no longer needed or before re-creating:
ANALYZE TABLE employes DROP HISTOGRAM ON dept_id;
ANALYZE TABLE employes DROP HISTOGRAM ON hire_date;

-- ----------------------------------------------------------------------------
-- INTERVIEW INSIGHT
-- ----------------------------------------------------------------------------
-- Q: "A stored procedure runs fast for you locally but a colleague reports
--     it's slow in production with different input. Same code, same
--     schema. What do you check first?"
-- A: Parameter sniffing / plan caching — check whether the cached plan was
--    compiled against a parameter value with very different selectivity
--    than the production caller's value. In MySQL, prepared statements
--    do not cache plans across connections, but application-level query
--    caching or connection poolers may exhibit similar symptoms.
--    In SQL Server: consider OPTION (RECOMPILE) or OPTIMIZE FOR hints.

-- ============================================================================
-- POSTGRESQL REFERENCE (for cross-database learning)
-- ============================================================================
-- The following queries are PostgreSQL-specific and will NOT run on MySQL.
-- They are included for engineers working in PostgreSQL environments.

-- PostgreSQL: Inspect statistics directly
-- SELECT attname, n_distinct, most_common_vals, most_common_freqs
-- FROM pg_stats
-- WHERE tablename = 'employes'
--   AND attname IN ('dept_id', 'hire_date');

-- PostgreSQL: Refresh statistics
-- ANALYZE employes;

-- PostgreSQL 10+: Extended statistics for correlated columns
-- CREATE STATISTICS dept_location_stats (dependencies)
--     ON dept_id, location_id FROM departments;
-- ANALYZE departments;

-- PostgreSQL: Bulk insert with generate_series
-- INSERT INTO employes (emp_name, dept_id, hire_date)
-- SELECT 'Bulk Employee ' || gs, 4, CURRENT_DATE
-- FROM generate_series(1, 500000) AS gs;

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Create histograms with different bucket counts (10 vs 100 vs 254)
--    on a skewed column and observe how histogram granularity changes
--    the estimate accuracy in EXPLAIN output.
-- 2. Compare MySQL's ANALYZE TABLE behavior with PostgreSQL's ANALYZE
--    and SQL Server's UPDATE STATISTICS.
-- 3. Test the effect of InnoDB's innodb_stats_persistent_sample_pages
--    setting on cardinality estimate accuracy.
