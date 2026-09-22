-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION
-- TOPIC     : Query Execution Lifecycle
-- ============================================================================
-- BUSINESS OBJECTIVE
--   Demonstrate how logical SQL order and physical execution order diverge,
--   using a fraud-review reporting query against the handbook's shared
--   employes / departments / locations schema.
--
-- PRODUCTION SCENARIO
--   A bank's fraud-review team pulls a daily leaderboard of which staff
--   members are logging the most flagged-transaction reviews, broken out
--   by department. At production scale, `employes` represents 40M+ rows
--   across a multinational staff directory.
--
-- DATASET
--   employes(emp_id, emp_name, dept_id, manager_id, hire_date)
--   departments(dept_id, dept_name, location_id)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PROBLEM STATEMENT
-- Business question: "Which employees in the Fraud Review department have
-- the most activity, ranked highest first?"
-- ----------------------------------------------------------------------------

-- PRODUCTION SQL SOLUTION
-- Written in logical order — this is what you SHOULD write. The optimizer,
-- not the author, decides the physical order it runs in.
SELECT
    e.emp_name,
    d.dept_name,
    COUNT(*) AS activity_count
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Fraud Review'
GROUP BY
    e.emp_name,
    d.dept_name
ORDER BY
    activity_count DESC;

-- ----------------------------------------------------------------------------
-- ENGINEERING NOTES
-- ----------------------------------------------------------------------------
-- Although WHERE is logically applied AFTER the JOIN, a cost-based optimizer
-- will typically push the `d.dept_name = 'Fraud Review'` predicate down so
-- that `departments` is filtered to a single row BEFORE the join executes —
-- because filtering first is cheaper than joining the full table and
-- filtering after. This is called PREDICATE PUSHDOWN and is covered in full
-- in Lesson 04. You do not need to manually reorder anything for this to
-- happen; it happens during the Optimization stage regardless of how you
-- wrote the query, as long as the predicate is SARGable (Lesson 03).

-- ----------------------------------------------------------------------------
-- ANTI-EXAMPLE: a "manually optimized" rewrite that does NOT help
-- ----------------------------------------------------------------------------
-- Some SQL authors instinctively try to "help" the optimizer by pre-filtering
-- in a subquery. For a well-indexed, cost-based optimizer this is usually
-- unnecessary work for the author and provides zero performance benefit,
-- because the optimizer already considers this exact plan on its own.
SELECT
    e.emp_name,
    fd.dept_name,
    COUNT(*) AS activity_count
FROM employes AS e
JOIN (
    SELECT dept_id, dept_name
    FROM departments
    WHERE dept_name = 'Fraud Review'
) AS fd
    ON e.dept_id = fd.dept_id
GROUP BY
    e.emp_name,
    fd.dept_name
ORDER BY
    activity_count DESC;

-- PERFORMANCE COMPARISON
-- Run both versions through EXPLAIN (Lesson 02) against a production-sized
-- copy of this schema. In virtually every modern engine, the two plans are
-- IDENTICAL — the manual pre-filter subquery gets "flattened" by the
-- optimizer into the same predicate-pushdown plan as the first query. The
-- lesson: prefer the more readable form (the first query) unless EXPLAIN
-- proves the optimizer isn't flattening it for your specific engine/version.

-- ----------------------------------------------------------------------------
-- INTERVIEW INSIGHT
-- ----------------------------------------------------------------------------
-- Q: "Does rewriting a WHERE clause into a subquery make a query faster?"
-- A: Almost never, for a modern cost-based optimizer. The interviewer is
--    testing whether you understand that the optimizer, not query text
--    structure, determines physical execution — the correct answer explains
--    predicate pushdown, not query-writing superstition.

-- ----------------------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- ----------------------------------------------------------------------------
-- 1. Run EXPLAIN on both queries above against your engine and compare the
--    plan trees directly.
-- 2. Add a third version using a CTE instead of a derived-table subquery and
--    compare all three plans.
