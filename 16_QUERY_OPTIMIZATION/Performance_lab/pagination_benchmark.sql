-- ============================================================================
-- PERFORMANCE LAB: Pagination Benchmark
-- ENGINE: MySQL 8.0.18+ (requires EXPLAIN ANALYZE support)
-- OFFSET vs. Keyset pagination at scale
-- ============================================================================
-- The 00_Schema.sql seeds 5,000 employees. The OFFSET values below are
-- chosen to work with the seed data. For a more dramatic demonstration,
-- increase the seed data size (e.g., 100K+ rows).

-- Version 0: OFFSET pagination (baseline — cost grows with page number)
-- With 5,000 rows, OFFSET 4000 demonstrates the pattern.
-- In production with millions of rows, OFFSET 100000+ becomes very expensive.
EXPLAIN ANALYZE
SELECT emp_id, emp_name
FROM employes
ORDER BY emp_id
LIMIT 20 OFFSET 4000;

-- Version 1: Keyset pagination (consistent cost regardless of page)
-- Uses the last emp_id seen on the previous page as a cursor.
EXPLAIN ANALYZE
SELECT emp_id, emp_name
FROM employes
WHERE emp_id > 4000
ORDER BY emp_id
LIMIT 20;

-- Version 2: Keyset with covering index
-- MySQL InnoDB doesn't support INCLUDE — use a composite index instead.
-- The primary key (emp_id) is already included in all secondary indexes.
-- CREATE INDEX idx_employes_id_name ON employes (emp_id, emp_name);

EXPLAIN ANALYZE
SELECT emp_id, emp_name
FROM employes
WHERE emp_id > 4000
ORDER BY emp_id
LIMIT 20;

-- Benchmark at multiple OFFSET values to demonstrate linear cost growth:
-- OFFSET 100, OFFSET 1000, OFFSET 4000
-- Compare each against the equivalent keyset query.
