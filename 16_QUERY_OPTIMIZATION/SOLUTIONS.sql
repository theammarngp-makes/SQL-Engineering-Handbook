-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION -- PRACTICE PROBLEM SOLUTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SOLUTION 1 -- Spot the non-SARGable predicate
-- ----------------------------------------------------------------------------
-- `dept_id + 0 = 4` wraps the indexed column in an expression, making it
-- non-SARGable even though `+ 0` is mathematically a no-op. The engine
-- cannot know the expression is a no-op without evaluating it per row.
-- FIX:
SELECT emp_name FROM employes WHERE dept_id = 4;

-- ----------------------------------------------------------------------------
-- SOLUTION 2 -- Composite index design
-- ----------------------------------------------------------------------------
-- CREATE INDEX idx_employes_dept_hiredate ON employes (dept_id, hire_date);
--
-- dept_id leads because the query filters on it with equality (`= 4`),
-- which is the most selective, most restrictive access pattern the index
-- can serve directly. hire_date follows because it's used both as a range
-- filter AND as the ORDER BY column -- placing it second lets the index
-- also satisfy the ORDER BY without a separate sort step, since rows for a
-- given dept_id are stored in hire_date order within the index.

-- ----------------------------------------------------------------------------
-- SOLUTION 3 -- NOT IN vs. NOT EXISTS
-- ----------------------------------------------------------------------------
-- `manager_id` is NULL for top-level managers in this schema (00_Schema).
-- `NOT IN (SELECT manager_id FROM employes)` evaluates to UNKNOWN for every
-- row the moment the subquery's result set contains a NULL, because
-- `x <> NULL` is UNKNOWN, not TRUE -- and `NOT IN` requires every
-- comparison to be TRUE. The query silently returns zero rows.
-- FIX:
SELECT e.emp_name
FROM employes e
WHERE NOT EXISTS (
    SELECT 1 FROM employes m WHERE m.manager_id = e.emp_id
);

-- ----------------------------------------------------------------------------
-- SOLUTION 4 -- Predict the join algorithm
-- ----------------------------------------------------------------------------
-- Expected: departments and locations are both small enough to use as the
-- build side of a Hash Join (or even be read entirely into memory), while
-- employes -- large, but with an index on dept_id -- is likely probed via
-- Nested Loop against the already-filtered, tiny department set (since
-- `l.country = 'India'` filters locations/departments down to a handful of
-- rows BEFORE the employes join, via predicate pushdown). Overall: expect
-- Hash Join for locations/departments, feeding a Nested Loop (indexed) into
-- employes -- but the only way to be certain is EXPLAIN ANALYZE on your
-- actual data and engine.

-- ----------------------------------------------------------------------------
-- SOLUTION 5 -- Anti-pattern audit
-- ----------------------------------------------------------------------------
-- Anti-patterns present:
--   1. SELECT DISTINCT * -- unnecessary DISTINCT masking a likely join
--      fan-out, and SELECT * pulling unneeded columns
--   2. Implicit cross join (comma join with no explicit ON, missing the
--      e.dept_id = d.dept_id relationship entirely) -- likely a cartesian
--      product bug, not just a style issue
--   3. UPPER(d.dept_name) = 'ENGINEERING' -- non-SARGable, function wraps
--      the indexed column
--   4. OR across unrelated columns (dept_name filter OR hire_date filter)
--      -- can't be served by a single composite index
--   5. Large OFFSET pagination (OFFSET 50000) -- cost grows with offset size
--
-- FIX:
SELECT e.emp_id, e.emp_name, e.dept_id, e.hire_date
FROM employes e
JOIN departments d
    ON e.dept_id = d.dept_id
   AND d.dept_name = 'Engineering'
WHERE e.emp_id > 50000   -- keyset pagination cursor, replacing OFFSET
ORDER BY e.emp_id
LIMIT 20;
-- Note: the original query's OR logic (dept_name = 'Engineering' OR
-- hire_date > '2023-01-01') materially changes the result set compared to
-- this AND-based fix -- in a real audit, confirm the actual business intent
-- before collapsing an OR into an AND; if OR is genuinely required, use the
-- UNION pattern from Lesson 06 instead.

-- ----------------------------------------------------------------------------
-- SOLUTION 6 -- Correlated subquery to window function
-- ----------------------------------------------------------------------------
SELECT
    e.emp_name,
    e.dept_id,
    MAX(e.hire_date) OVER (PARTITION BY e.dept_id) AS latest_hire_in_dept
FROM employes e;

-- ----------------------------------------------------------------------------
-- SOLUTION 7 -- Diagnose from a plan description
-- ----------------------------------------------------------------------------
-- Hypothesis: statistics are badly stale. An estimated/actual row gap this
-- large (400,000 estimated vs. 3 actual) means the optimizer's cost model
-- was working from wrong assumptions about this table's data distribution
-- -- it may have chosen a full table scan (Seq Scan in PostgreSQL,
-- type: ALL in MySQL) believing the filter was much less selective than
-- it actually is.
-- What to check next:
--   1. When statistics were last refreshed (ANALYZE / UPDATE STATISTICS)
--      for this table, and whether recent data changes (bulk load, delete)
--      happened since.
--   2. Whether an index exists on the filtered column at all -- if not,
--      stale stats aren't even the primary issue; the fix is adding one.

-- ----------------------------------------------------------------------------
-- SOLUTION 8 -- Full tuning workflow (template answer)
-- ----------------------------------------------------------------------------
-- 1. MEASURE: run EXPLAIN ANALYZE on the reported-slow query, record actual
--    elapsed time as the baseline.
-- 2. READ THE PLAN: locate the single most expensive node in the plan tree
--    (read bottom-up).
-- 3. HYPOTHESIS: match the expensive node against the table in Lesson 07
--    (e.g. a full table scan — Seq Scan in PostgreSQL, type: ALL in MySQL —
--    on the largest joined table suggests a missing index or non-SARGable
--    predicate on that table).
-- 4. CHANGE ONE THING: apply exactly one fix (e.g. add the missing index).
-- 5. VERIFY: re-run EXPLAIN ANALYZE, compare actual time against the
--    Step 1 baseline; if it didn't help, revert and return to Step 3 with
--    a new hypothesis rather than stacking additional unproven changes.

-- ----------------------------------------------------------------------------
-- SOLUTION 9 -- Cost surface diagnosis (Lesson 10, template answer)
-- ----------------------------------------------------------------------------
-- Latency-only review missed the bytes-scanned cost surface entirely.
-- The field that would have caught it: total_bytes_billed in
-- `region-us`.INFORMATION_SCHEMA.JOBS, checked via a recurring
-- waste-detection query (Lesson 10), not a one-time launch review.

-- ----------------------------------------------------------------------------
-- SOLUTION 10 -- CI performance gate decision tree (Lesson 11, template answer)
-- ----------------------------------------------------------------------------
-- 1. Hot path? YES.
-- 2. Affected by future schema/data changes outside this PR? YES -- the
--    lab's own regression scenario demonstrates this directly.
-- 3. Expressible as a concrete, versioned budget? YES -- plan-node
--    assertion + p95 latency threshold, as ci/run_benchmark.sh implements.
-- Conclusion: automate.

-- ----------------------------------------------------------------------------
-- SOLUTION 11 -- Validating an AI-suggested EXISTS-to-JOIN rewrite
-- ----------------------------------------------------------------------------
SELECT 'exists_only' AS diff_source, x.emp_id, x.emp_name
FROM (
    SELECT emp_id, emp_name FROM employes e
    WHERE EXISTS (
        SELECT 1 FROM transactions t
        WHERE t.processed_by_emp_id = e.emp_id AND t.transaction_status = 'FLAGGED'
    )
) x
LEFT JOIN (
    SELECT DISTINCT e.emp_id, e.emp_name FROM employes e
    JOIN transactions t ON t.processed_by_emp_id = e.emp_id
    WHERE t.transaction_status = 'FLAGGED'
) j ON j.emp_id = x.emp_id
WHERE j.emp_id IS NULL
UNION ALL
SELECT 'join_only' AS diff_source, j.emp_id, j.emp_name
FROM (
    SELECT DISTINCT e.emp_id, e.emp_name FROM employes e
    JOIN transactions t ON t.processed_by_emp_id = e.emp_id
    WHERE t.transaction_status = 'FLAGGED'
) j
LEFT JOIN (
    SELECT emp_id, emp_name FROM employes e
    WHERE EXISTS (
        SELECT 1 FROM transactions t
        WHERE t.processed_by_emp_id = e.emp_id AND t.transaction_status = 'FLAGGED'
    )
) x ON x.emp_id = j.emp_id
WHERE x.emp_id IS NULL;

-- The one condition under which these are NOT equivalent: if DISTINCT
-- were removed from the JOIN rewrite. Without it, an employee who
-- processed multiple FLAGGED transactions appears once per matching row
-- (a join fan-out) instead of once, as EXISTS guarantees by construction.
