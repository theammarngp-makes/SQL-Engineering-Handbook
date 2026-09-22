-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : Join Optimization
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Show how table size and indexing shape which join algorithm the
--   optimizer picks, using the shared employes/departments/locations schema
--   scaled to production volumes.
--
-- PRODUCTION SCENARIO
--   Global staffing report: join a large employes table against small
--   departments and locations lookup tables.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CASE 1: small table joined to large table (expect Nested Loop or Hash Join)
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT e.emp_name, d.dept_name
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE d.location_id = 3;

-- ENGINEERING NOTES
-- With an index on employes(dept_id) and departments filtered down to a
-- handful of rows by location_id = 3 (predicate pushdown), expect a Nested
-- Loop: for each qualifying department, index-lookup matching employes rows.
-- Without that index, expect a Hash Join instead, since a full scan of
-- employes becomes the cheaper build/probe strategy.

-- ----------------------------------------------------------------------------
-- CASE 2: large table joined to large table (expect Hash Join or Merge Join)
-- ----------------------------------------------------------------------------
-- Simulated production scenario: employes joined against a large
-- transaction-style table (not in the base schema — illustrative).
--
-- EXPLAIN ANALYZE
-- SELECT e.emp_name, t.transaction_amount
-- FROM employes AS e
-- JOIN transactions AS t
--     ON e.emp_id = t.processed_by_emp_id
-- WHERE t.transaction_date >= '2026-01-01';
--
-- With BOTH e.emp_id (primary key, effectively indexed) and
-- t.processed_by_emp_id indexed, and both sides large, expect a Merge Join
-- if the engine can obtain both sides pre-sorted cheaply, or a Hash Join
-- if not — compare actual EXPLAIN output on your own transactions-scale
-- table to confirm which your engine picks.

-- ----------------------------------------------------------------------------
-- ANTI-PATTERN: join predicate that can't use an index (forces Nested Loop
-- with no index support -- i.e. the expensive kind)
-- ----------------------------------------------------------------------------

-- POOR PERFORMING VERSION
SELECT e.emp_name, d.dept_name
FROM employes AS e
JOIN departments AS d
    ON UPPER(CAST(e.dept_id AS CHAR)) = UPPER(CAST(d.dept_id AS CHAR));
    -- casting + UPPER() on both sides destroys SARGability on the join key

-- OPTIMIZED VERSION
SELECT e.emp_name, d.dept_name
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id;

-- EXECUTION PLAN DISCUSSION
-- The first version cannot use any index on dept_id in either table because
-- both sides are wrapped in expressions (Lesson 03's SARGability rule
-- applies to join predicates exactly as it does to WHERE predicates).
-- Expect a full, unindexed Nested Loop -- the worst-case join shape.

-- ----------------------------------------------------------------------------
-- PREDICATE PUSHDOWN DEMONSTRATION
-- ----------------------------------------------------------------------------
-- These two queries are logically identical. A cost-based optimizer should
-- produce the SAME plan for both, because it pushes the WHERE predicate
-- down past the join on its own.

-- Written naturally:
SELECT e.emp_name, d.dept_name
FROM employes AS e
JOIN departments AS d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering';

-- "Manually pre-filtered" -- should compile to the same plan:
SELECT e.emp_name, fd.dept_name
FROM employes AS e
JOIN (
    SELECT dept_id, dept_name
    FROM departments
    WHERE dept_name = 'Engineering'
) AS fd
    ON e.dept_id = fd.dept_id;

-- INTERVIEW INSIGHT
-- Q: "When would you manually rewrite a join to pre-filter one side in a
--     subquery instead of trusting the optimizer?"
-- A: Almost never for standard predicate pushdown -- modern optimizers do
--    this automatically. The rare exception is when the pre-filter also
--    needs deduplication or aggregation the optimizer can't infer is safe
--    to push down, e.g. filtering to "most recent record per key" before
--    joining, which genuinely changes cardinality and must be explicit.

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Run EXPLAIN on both predicate-pushdown queries above and confirm
--    whether your engine produces identical plans.
-- 2. Drop the index on employes(dept_id) (if created in Lesson 03) and
--    re-run Case 1 -- observe whether the optimizer switches from Nested
--    Loop to Hash Join.
