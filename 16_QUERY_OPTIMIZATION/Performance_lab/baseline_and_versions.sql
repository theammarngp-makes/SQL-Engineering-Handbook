-- ============================================================================
-- PERFORMANCE LAB: SARGability Benchmark
-- ENGINE: MySQL 8.0.18+ (requires EXPLAIN ANALYZE support)
-- Baseline query — non-SARGable predicate (Version 0)
-- ============================================================================
-- Run against employes table from 00_Schema.sql.
-- See Performance_lab/README.md for full benchmark protocol.

-- Version 0: Non-SARGable (baseline)
-- Measures performance of function-wrapped predicates (forces full table scan)
EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE EXTRACT(YEAR FROM hire_date) = 2023;

-- Version 1: SARGable range rewrite
-- Measures performance of direct column range conditions (enables index range scan)
EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE hire_date >= '2023-01-01'
  AND hire_date < '2024-01-01';

-- Version 2: With covering index (create first)
-- Measures impact of covering index (eliminates row lookups)
-- MySQL doesn't use INCLUDE, so we add the column to the index
-- CREATE INDEX idx_employes_hire_covering
--     ON employes (hire_date, emp_name);

EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE hire_date >= '2023-01-01'
  AND hire_date < '2024-01-01';

-- Version 3: Functional/Expression Index (MySQL 8.0.13+)
-- Measures impact of indexing the exact expression used in the query
-- CREATE INDEX idx_employes_hire_year
--     ON employes ((EXTRACT(YEAR FROM hire_date)));

EXPLAIN ANALYZE
SELECT emp_name, hire_date
FROM employes
WHERE hire_date >= '2023-01-01'
  AND hire_date < '2024-01-01';
