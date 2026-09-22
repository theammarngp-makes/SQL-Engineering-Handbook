-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : Query Rewrite Patterns
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Runnable before/after pairs for all 8 rewrite patterns in
--   09_QUERY_REWRITE_PATTERNS.md, against the shared schema.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PATTERN 1: OR -> UNION ALL
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT emp_name FROM employes
WHERE dept_id = 4 OR hire_date > '2023-01-01';

-- AFTER
EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE dept_id = 4
UNION ALL
SELECT emp_name FROM employes
WHERE hire_date > '2023-01-01' AND (dept_id <> 4 OR dept_id IS NULL);
-- NOTE: the guard must be NULL-safe. A bare "dept_id <> 4" evaluates to
-- UNKNOWN (false) when dept_id IS NULL, which would silently drop rows
-- the original OR predicate included. Validate NULL behavior, branch
-- overlap, and duplicate rows for every OR -> UNION ALL rewrite before
-- adopting it -- it is not a universal substitution.

-- ----------------------------------------------------------------------------
-- PATTERN 2: DISTINCT -> EXISTS
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT DISTINCT d.dept_name
FROM departments d
JOIN employes e ON e.dept_id = d.dept_id;

-- AFTER
EXPLAIN ANALYZE
SELECT d.dept_name
FROM departments d
WHERE EXISTS (SELECT 1 FROM employes e WHERE e.dept_id = d.dept_id);

-- ----------------------------------------------------------------------------
-- PATTERN 3: IN -> EXISTS
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT dept_name FROM departments d
WHERE d.dept_id IN (
    SELECT dept_id FROM employes WHERE hire_date > '2023-01-01'
);

-- AFTER
EXPLAIN ANALYZE
SELECT dept_name FROM departments d
WHERE EXISTS (
    SELECT 1 FROM employes e
    WHERE e.dept_id = d.dept_id AND e.hire_date > '2023-01-01'
);

-- ----------------------------------------------------------------------------
-- PATTERN 4: Correlated subquery -> window function
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT e.emp_name,
    (SELECT COUNT(*) FROM employes e2
     WHERE e2.dept_id = e.dept_id AND e2.hire_date <= e.hire_date) AS hire_rank
FROM employes e;

-- AFTER
EXPLAIN ANALYZE
SELECT e.emp_name,
    RANK() OVER (PARTITION BY e.dept_id ORDER BY e.hire_date) AS hire_rank
FROM employes e;

-- ----------------------------------------------------------------------------
-- PATTERN 5: SELECT * -> explicit projection
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT * FROM employes WHERE dept_id = 4;

-- AFTER (assumes a covering index exists -- see Lesson 03)
EXPLAIN ANALYZE
SELECT emp_id, emp_name, hire_date FROM employes WHERE dept_id = 4;

-- ----------------------------------------------------------------------------
-- PATTERN 6: leading wildcard -> prefix search
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE emp_name LIKE '%mmar';

-- AFTER
EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE emp_name LIKE 'Ammar%';

-- ----------------------------------------------------------------------------
-- PATTERN 7: large OFFSET -> keyset pagination
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT emp_id, emp_name FROM employes
ORDER BY emp_id LIMIT 20 OFFSET 100000;

-- AFTER
EXPLAIN ANALYZE
SELECT emp_id, emp_name FROM employes
WHERE emp_id > 100000
ORDER BY emp_id LIMIT 20;

-- ----------------------------------------------------------------------------
-- PATTERN 8: function in WHERE -> bare column + rewritten constant
-- ----------------------------------------------------------------------------
-- BEFORE
EXPLAIN ANALYZE
SELECT emp_name FROM employes WHERE YEAR(hire_date) = 2023;

-- AFTER
EXPLAIN ANALYZE
SELECT emp_name FROM employes
WHERE hire_date >= '2023-01-01' AND hire_date < '2024-01-01';

-- ----------------------------------------------------------------------------
-- INTERVIEW INSIGHT
-- ----------------------------------------------------------------------------
-- Q: "Give me a query rewrite that looks like an improvement but changes
--     the result set. What's a real example?"
-- A: UNION ALL without an explicit overlap guard when rewriting an OR
--    (Pattern 1) -- rows matching both original conditions get duplicated,
--    silently changing COUNT(*) and aggregate results downstream. A second,
--    subtler failure: an overlap guard written as a bare "<> value" instead
--    of "<> value OR value IS NULL" silently DROPS rows where that column
--    is NULL, because SQL's three-valued logic treats the plain inequality
--    as UNKNOWN (not true) for NULL input.

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Run every BEFORE/AFTER pair above through EXPLAIN ANALYZE on a
--    production-scale copy of the schema and record the actual time delta
--    for each pattern.
-- 2. Find one query in your own codebase matching a "BEFORE" shape here
--    and confirm the rewrite is safe before applying it.
