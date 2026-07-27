-- =============================================================================
-- TOPIC: CROSS JOIN
-- DIFFICULTY: Beginner -> Intermediate
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Generate every possible department-location pairing, with a flag
-- showing whether that pairing reflects the department's actual assignment.
--
-- BUSINESS SCENARIO
-- Facilities planning is evaluating whether to consolidate offices and
-- wants a full "what-if" matrix of every department against every existing
-- location, not just the current assignments.
-- -----------------------------------------------------------------------------

SELECT
    d.dept_name,
    l.city,
    CASE
        WHEN d.location_id = l.location_id THEN 'current'
        ELSE 'hypothetical'
    END AS assignment_status
FROM departments d
CROSS JOIN locations l
ORDER BY d.dept_name, l.city;

-- EXPECTED OUTPUT: 6 departments x 4 locations = 24 rows. Exactly 5 rows
-- read 'current' (departments.location_id NOT NULL count); Marketing
-- (location_id IS NULL) never shows 'current' for any city.


-- -----------------------------------------------------------------------------
-- Q2. Build a 6-month date spine, one row per department per month, ready
-- to LEFT JOIN onto real headcount-change data (which this schema doesn't
-- track historically — this produces the SPINE only).
--
-- BUSINESS SCENARIO
-- The BI team is building a headcount trend chart that must show a
-- continuous 6-month x-axis per department, including months with zero
-- headcount change, rather than a chart with gaps.
-- -----------------------------------------------------------------------------

WITH months AS (
    SELECT DATE '2024-01-01' AS month_start
    UNION ALL SELECT DATE '2024-02-01'
    UNION ALL SELECT DATE '2024-03-01'
    UNION ALL SELECT DATE '2024-04-01'
    UNION ALL SELECT DATE '2024-05-01'
    UNION ALL SELECT DATE '2024-06-01'
)
SELECT
    d.dept_name,
    m.month_start
FROM departments d
CROSS JOIN months m
ORDER BY d.dept_name, m.month_start;

-- EXPECTED OUTPUT: 6 departments x 6 months = 36 rows — one row per
-- department per month, with no gaps, regardless of whether anything
-- actually happened in that department that month.

-- ENGINEERING NOTES
-- In production, `months` would come from a proper date-dimension table or
-- a generator function (PostgreSQL: generate_series('2024-01-01'::date,
-- '2024-06-01'::date, '1 month'::interval)) rather than a hardcoded UNION
-- ALL CTE — hardcoding six literal dates here is a teaching simplification,
-- not a pattern to copy into a real pipeline.

-- ALTERNATIVE SOLUTION (PostgreSQL-specific, shown for reference)
--
-- SELECT d.dept_name, gs.month_start
-- FROM departments d
-- CROSS JOIN generate_series(
--     DATE '2024-01-01', DATE '2024-06-01', INTERVAL '1 month'
-- ) AS gs(month_start)
-- ORDER BY d.dept_name, gs.month_start;


-- -----------------------------------------------------------------------------
-- Q3. Demonstrate the accidental-CROSS-JOIN failure mode directly, so it's
-- unmistakable in a code review.
--
-- BUSINESS SCENARIO
-- A junior engineer's PR joins employees to departments but forgot the
-- join predicate. Show what actually happens so the review comment can
-- point at concrete numbers, not just "this looks wrong."
-- -----------------------------------------------------------------------------

-- What the PR actually wrote (missing predicate — silently becomes a
-- Cartesian product):
SELECT COUNT(*) AS accidental_row_count
FROM employees, departments;   -- 10 x 6 = 60 rows, NOT the ~10 rows intended

-- What it should have been:
SELECT COUNT(*) AS correct_row_count
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;   -- 9 rows

-- INTERVIEW INSIGHT
-- Being able to instantly compute "60 rows, because 10 x 6, and that's the
-- tell" from a query with a missing join predicate — without running it —
-- is exactly the kind of fast mental-math check interviewers use CROSS
-- JOIN questions to test.

-- FURTHER EXPERIMENTS
-- 1. Extend Q1 to also show d.budget, and compute the total "hypothetical"
--    budget exposure per location if every department were reassigned there
--    (SUM(d.budget) GROUP BY l.city, filtered to assignment_status =
--    'hypothetical').
-- 2. Rewrite Q2 using your database's native date-generation function
--    instead of the hardcoded UNION ALL CTE, and confirm identical output.
-- 3. Using the accidental Cartesian product from Q3 as a cautionary
--    starting point, calculate what the row count WOULD have been if
--    employees had 50,000 rows and departments had 200 — and discuss, in a
--    comment, what actually happens to a shared production database when a
--    query like that runs unnoticed.
