-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : Common Performance Anti-Patterns
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Provide runnable before/after pairs for the anti-pattern catalog in
--   06_COMMON_PERFORMANCE_ANTI_PATTERNS.md, against the shared schema.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SELECT *
-- ----------------------------------------------------------------------------
-- POOR
SELECT * FROM employes WHERE dept_id = 4;
-- BETTER
SELECT emp_id, emp_name, hire_date FROM employes WHERE dept_id = 4;

-- ----------------------------------------------------------------------------
-- 5. Missing join condition (accidental cartesian product)
-- ----------------------------------------------------------------------------
-- POOR -- produces rows(employes) x rows(departments) results
SELECT e.emp_name, d.dept_name
FROM employes e, departments d
WHERE e.hire_date > '2023-01-01';

-- BETTER
SELECT e.emp_name, d.dept_name
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.hire_date > '2023-01-01';

-- ENGINEERING NOTES
-- Run COUNT(*) on both versions against sample data and compare -- the
-- cartesian version's row count should be dramatically, obviously wrong
-- once you know what to check for.

-- ----------------------------------------------------------------------------
-- 8. OR across unrelated columns
-- ----------------------------------------------------------------------------
-- POOR -- can't be served efficiently by a single composite index
SELECT emp_name FROM employes
WHERE dept_id = 4 OR hire_date > '2023-01-01';

-- BETTER -- each half can use its own independent index
SELECT emp_name FROM employes WHERE dept_id = 4
UNION
SELECT emp_name FROM employes WHERE hire_date > '2023-01-01';

-- ----------------------------------------------------------------------------
-- 9. Large OFFSET pagination
-- ----------------------------------------------------------------------------
-- POOR -- cost grows with OFFSET size regardless of indexing
SELECT emp_id, emp_name
FROM employes
ORDER BY emp_id
LIMIT 20 OFFSET 100000;

-- BETTER -- keyset (cursor) pagination; pass the last-seen emp_id from the
-- previous page as the new lower bound
SELECT emp_id, emp_name
FROM employes
WHERE emp_id > 100000   -- last emp_id seen on the previous page
ORDER BY emp_id
LIMIT 20;

-- PERFORMANCE COMPARISON
-- On a multi-million row table, EXPLAIN ANALYZE the OFFSET version at
-- OFFSET 10, OFFSET 100000, and OFFSET 1000000. Cost should climb roughly
-- linearly with OFFSET size. The keyset version's cost should stay flat
-- regardless of "page number," because it's a direct indexed range lookup.

-- ----------------------------------------------------------------------------
-- 10. Unnecessary DISTINCT masking a join fan-out
-- ----------------------------------------------------------------------------
-- POOR -- DISTINCT is masking a one-to-many join that duplicates
-- department names once per matching employee
SELECT DISTINCT d.dept_name
FROM departments d
JOIN employes e ON e.dept_id = d.dept_id;

-- BETTER -- EXISTS avoids ever producing the duplicate rows in the first
-- place, so there's nothing to de-duplicate
SELECT d.dept_name
FROM departments d
WHERE EXISTS (SELECT 1 FROM employes e WHERE e.dept_id = d.dept_id);

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Populate employes with 500K+ synthetic rows and benchmark the OFFSET
--    vs. keyset pagination pair directly with EXPLAIN ANALYZE.
-- 2. Audit one real query from an earlier module (e.g. Module 08 business
--    cases) for any of the ten anti-patterns in this lesson.
