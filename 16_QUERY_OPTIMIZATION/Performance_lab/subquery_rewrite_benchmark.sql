-- ============================================================================
-- PERFORMANCE LAB: Subquery Rewrite Benchmark
-- ENGINE: MySQL 8.0.18+ (requires EXPLAIN ANALYZE support)
-- Correlated subquery vs. Window function vs. Pre-aggregated join
-- ============================================================================

-- Version 0: Correlated subquery (baseline)
EXPLAIN ANALYZE
SELECT
    e.emp_name,
    e.dept_id,
    (SELECT MAX(e2.hire_date)
     FROM employes e2
     WHERE e2.dept_id = e.dept_id) AS latest_hire_in_dept
FROM employes e;

-- Version 1: Window function rewrite
EXPLAIN ANALYZE
SELECT
    e.emp_name,
    e.dept_id,
    MAX(e.hire_date) OVER (PARTITION BY e.dept_id) AS latest_hire_in_dept
FROM employes e;

-- Version 2: Pre-aggregated join (alternative for filtering, not projection)
EXPLAIN ANALYZE
SELECT e.emp_name, e.dept_id, d.latest_hire
FROM employes e
JOIN (
    SELECT dept_id, MAX(hire_date) AS latest_hire
    FROM employes
    GROUP BY dept_id
) d ON e.dept_id = d.dept_id;

-- Check query execution plan in Version 0 to see how many times the correlated subquery executes
