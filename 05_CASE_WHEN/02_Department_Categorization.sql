-- =============================================================
-- LESSON 02: CASE WHEN + GROUP BY + Aggregates
-- DIFFICULTY: Intermediate
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- SCENARIO
-- Workforce planning needs each department tagged by headcount tier
-- to decide hiring priority for next quarter.
--
-- BUSINESS RULE
--   headcount > 2   -> 'Large'
--   headcount = 2   -> 'Medium'
--   otherwise       -> 'Small'
-- -----------------------------------------------------------------

SELECT
    d.dept_name,
    COUNT(DISTINCT e.emp_id) AS headcount,
    CASE
        WHEN COUNT(DISTINCT e.emp_id) > 2 THEN 'Large'
        WHEN COUNT(DISTINCT e.emp_id) = 2 THEN 'Medium'
        ELSE 'Small'
    END AS department_status
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY headcount DESC;

-- Expected output (against seed data):
-- dept_name   | headcount | department_status
-- Engineering | 3         | Large
-- Sales       | 2         | Medium
-- Support     | 2         | Medium
-- Finance     | 1         | Small

-- -----------------------------------------------------------------
-- ALTERNATIVE SOLUTION -- CTE form (recommended once you add more
-- tiers or need to reuse `headcount` in multiple places, e.g. a
-- later ORDER BY that also needs the tier logic)
-- -----------------------------------------------------------------
WITH dept_counts AS (
    SELECT
        d.dept_name,
        COUNT(DISTINCT e.emp_id) AS headcount
    FROM departments d
    JOIN employees e ON d.dept_id = e.dept_id
    GROUP BY d.dept_name
)
SELECT
    dept_name,
    headcount,
    CASE
        WHEN headcount > 2 THEN 'Large'
        WHEN headcount = 2 THEN 'Medium'
        ELSE 'Small'
    END AS department_status
FROM dept_counts
ORDER BY headcount DESC;

-- -----------------------------------------------------------------
-- PRODUCTION NOTE
-- Using INNER JOIN means a department with zero employees never
-- appears in this report at all -- not even as "Small". If the
-- business wants ALL departments represented, switch to LEFT JOIN
-- and wrap the count so NULL headcounts read as 0:
-- -----------------------------------------------------------------
-- SELECT d.dept_name,
--        COALESCE(COUNT(e.emp_id), 0) AS headcount,
--        CASE
--            WHEN COUNT(e.emp_id) > 2 THEN 'Large'
--            WHEN COUNT(e.emp_id) = 2 THEN 'Medium'
--            ELSE 'Small'
--        END AS department_status
-- FROM departments d
-- LEFT JOIN employees e ON d.dept_id = e.dept_id
-- GROUP BY d.dept_name;

-- -----------------------------------------------------------------
-- PERFORMANCE NOTE
-- COUNT(DISTINCT ...) is more expensive than plain COUNT(*) because
-- the engine must deduplicate before counting. Here it's used
-- defensively in case the join fans out (e.g. an employee linked to
-- multiple department records). If dept_id -> emp_id is guaranteed
-- 1:many with no duplication risk, COUNT(e.emp_id) is cheaper.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- INTERVIEW DISCUSSION
-- Q: Why can't you write
--      SELECT COUNT(*) AS headcount, CASE WHEN headcount > 2 ...
--    in a single flat SELECT?
-- A: The alias `headcount` doesn't exist yet when the CASE
--    expression next to it is being evaluated -- SELECT-list aliases
--    aren't visible to sibling expressions in standard SQL. Repeat
--    the full aggregate expression, or move it into a CTE/subquery.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Add a 4th tier: 'Enterprise' for headcount > 5.
-- 2. Rewrite the tiering to also factor in department `budget`
--    (e.g. Large AND budget > 2,000,000 -> 'Strategic').
-- -----------------------------------------------------------------
