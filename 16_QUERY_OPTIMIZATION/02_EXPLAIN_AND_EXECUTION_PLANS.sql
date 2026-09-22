-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : EXPLAIN and Execution Plans
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Show how to diagnose a nightly retail staffing dashboard query using
--   EXPLAIN / EXPLAIN ANALYZE.
--
-- PRODUCTION SCENARIO
--   Staff-count-by-department-and-city report. Assume employes and
--   departments each hold several million rows in production.
-- ============================================================================

-- BUSINESS QUESTION
-- "How many staff members does each department have, per city, for India?"

-- PRODUCTION SQL SOLUTION (unoptimized baseline — no assumed indexes)
EXPLAIN ANALYZE
SELECT
    d.dept_name,
    l.city,
    COUNT(*) AS staff_count
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id
JOIN locations AS l
    ON d.location_id = l.location_id
WHERE l.country = 'India'
GROUP BY
    d.dept_name,
    l.city;

-- ----------------------------------------------------------------------------
-- ENGINEERING NOTES: reading the output
-- ----------------------------------------------------------------------------
-- Look for, in order of priority (MySQL EXPLAIN column names; PostgreSQL
-- equivalent noted in parentheses):
--   1. Any row for "employes" with type: ALL and key: NULL (PostgreSQL:
--      "Seq Scan on employes") — at production scale this is almost always
--      the single biggest cost in this plan, since employes is the largest
--      table and has no filter directly on it.
--   2. The estimated vs. actual row counts on the locations filter
--      (`country = 'India'`) — a big mismatch signals stale statistics.
--   3. The join algorithm chosen for employes/departments (Lesson 04
--      explains how to read this) — a hash join (MySQL 8.0.18+) or nested
--      loop join is expected here given employes' size relative to
--      departments.

-- ----------------------------------------------------------------------------
-- OPTIMIZED VERSION — after adding a supporting index
-- ----------------------------------------------------------------------------
-- CREATE INDEX idx_employes_dept_id ON employes (dept_id);
--
-- Re-run the same EXPLAIN ANALYZE after adding this index and compare:
--   - Does the "employes" row now show type: ref/range with
--     key: idx_employes_dept_id instead of type: ALL (PostgreSQL:
--     Index Scan or Index Only Scan instead of Seq Scan)?
--   - Did the total cost / actual time drop?
--   - Did the JOIN algorithm chosen change?

EXPLAIN ANALYZE
SELECT
    d.dept_name,
    l.city,
    COUNT(*) AS staff_count
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id
JOIN locations AS l
    ON d.location_id = l.location_id
WHERE l.country = 'India'
GROUP BY
    d.dept_name,
    l.city;

-- ----------------------------------------------------------------------------
-- PERFORMANCE COMPARISON (template — fill in with your actual EXPLAIN output)
-- ----------------------------------------------------------------------------
-- | Version              | MySQL type on employes | PostgreSQL equivalent | Total cost | Actual time |
-- |-----------------------|-------------------------|------------------------|------------|-------------|
-- | Before index          | ALL                     | Seq Scan               | (fill in)  | (fill in)   |
-- | After index           | ref / range             | Index Scan             | (fill in)  | (fill in)   |

-- ----------------------------------------------------------------------------
-- INTERVIEW INSIGHT
-- ----------------------------------------------------------------------------
-- Q: "You add an index and the query doesn't get faster. What are three
--     possible reasons?"
-- A: (1) The predicate isn't SARGable so the index can't be used (Lesson 03),
--    (2) the table is small enough that a sequential scan is genuinely
--    cheaper and the optimizer is correct to ignore the index, or
--    (3) statistics are stale and the optimizer doesn't know the index
--    would help — running ANALYZE / UPDATE STATISTICS may be the real fix.

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Compare EXPLAIN ANALYZE output for this query with and without the
--    `WHERE l.country = 'India'` filter — observe how row estimates cascade
--    through the plan tree.
-- 2. Try EXPLAIN (ANALYZE, BUFFERS) on PostgreSQL and identify whether the
--    query is CPU-bound or I/O-bound.
