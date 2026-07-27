-- =============================================================================
-- TOPIC: LEFT JOIN
-- DIFFICULTY: Beginner
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Show every employee with their department name, including employees
-- who have no department assigned.
--
-- BUSINESS SCENARIO
-- HR onboarding dashboard — new hires occasionally land in the system before
-- their department transfer paperwork clears. The dashboard must show
-- every employee, not silently omit anyone mid-onboarding.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name,
    COALESCE(d.dept_name, 'UNASSIGNED') AS dept_name
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY dept_name, e.emp_name;

-- EXPECTED OUTPUT: 10 rows (all employees). Farhan Ali shows 'UNASSIGNED'.

-- ENGINEERING NOTES
-- COALESCE is a presentation-layer decision, not a join-logic decision —
-- the JOIN already preserved the row; COALESCE just replaces the NULL with
-- a readable label for the report. Don't confuse "COALESCE hides the NULL"
-- with "the JOIN handled the missing department" — they're separate steps.


-- -----------------------------------------------------------------------------
-- Q2. Find every employee with no department assigned (data quality audit).
--
-- BUSINESS SCENARIO
-- Payroll compliance flagged that department assignment drives cost-center
-- allocation. Ops needs a weekly list of unassigned employees to chase down
-- before month-end close.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_id,
    e.emp_name,
    e.hire_date
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL     -- check the JOIN KEY, not an arbitrary selected column
ORDER BY e.hire_date;

-- EXPECTED OUTPUT: 1 row (Farhan Ali).

-- ALTERNATIVE SOLUTION
-- NOT EXISTS is equally correct and, on many optimizers, compiles to the
-- same anti-join plan as the LEFT JOIN + IS NULL pattern above:
--
-- SELECT e.emp_id, e.emp_name, e.hire_date
-- FROM employees e
-- WHERE NOT EXISTS (
--     SELECT 1 FROM departments d WHERE d.dept_id = e.dept_id
-- );
--
-- Avoid the third option — NOT IN (SELECT dept_id FROM departments) — unless
-- you are certain departments.dept_id has no NULLs. If it did, NOT IN
-- would return zero rows for EVERY employee, silently, because
-- "x NOT IN (1, 2, NULL)" evaluates to NULL (not TRUE) for any x.
-- Full comparison in 07_MULTI_TABLE_JOINS.sql.

-- INTERVIEW INSIGHT
-- This exact pattern — LEFT JOIN + WHERE right.key IS NULL — is arguably the
-- single most interview-tested join idiom after the basic INNER JOIN. Be
-- able to write it without hesitation.


-- -----------------------------------------------------------------------------
-- Q3. Demonstrate the ON-vs-WHERE placement trap directly.
--
-- BUSINESS SCENARIO
-- A teammate's PR claims to show "all employees, with Engineering
-- department info where applicable, NULL otherwise." Verify their query is
-- actually correct before approving the PR.
-- -----------------------------------------------------------------------------

-- Version A — filter in ON: correctly preserves ALL 10 employees
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id AND d.dept_name = 'Engineering'
ORDER BY e.emp_name;

-- Version B — filter in WHERE: INCORRECTLY collapses to only the 4
-- Engineering employees — this is the bug to catch in code review
SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering'
ORDER BY e.emp_name;

-- Run both and compare row counts (10 vs 4) to confirm the behavioral
-- difference before you trust this pattern in a real review.

-- FURTHER EXPERIMENTS
-- 1. Rewrite Q2 as a RIGHT JOIN with table order swapped (departments
--    first) and confirm you get the identical result set — this proves
--    LEFT and RIGHT JOIN are the same operation with sides mirrored.
-- 2. Add a NULL into departments.dept_id via a temporary INSERT (then roll
--    back) and rerun the NOT IN alternative from Q2 to see the empty-result
--    trap firsthand.
