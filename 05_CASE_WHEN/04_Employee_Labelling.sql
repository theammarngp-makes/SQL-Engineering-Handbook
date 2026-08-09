-- =============================================================
-- LESSON 04: CASE WHEN for human-readable labels (3-table join)
-- DIFFICULTY: Intermediate
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- SCENARIO
-- HR wants an employee roster with a readable "home city" label.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- ORIGINAL (BUGGY) VERSION -- kept here deliberately as a teaching
-- example. Seed data includes a third city, 'Indore', which this
-- version silently mislabels as 'Pune Employee'. Run it and check
-- Vikram Joshi's row (Finance, based in Indore) to see the bug.
-- -----------------------------------------------------------------
SELECT
    e.emp_name,
    d.dept_name,
    l.city,
    CASE
        WHEN l.city = 'Nagpur' THEN 'Nagpur Employee'
        ELSE 'Pune Employee'          -- BUG: silently absorbs Indore too
    END AS employee_city_label_BUGGY
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
ORDER BY e.emp_id;

-- -----------------------------------------------------------------
-- CORRECT SOLUTION 1 -- explicit branch per known city, honest ELSE
-- -----------------------------------------------------------------
SELECT
    e.emp_name,
    d.dept_name,
    l.city,
    CASE
        WHEN l.city = 'Nagpur' THEN 'Nagpur Employee'
        WHEN l.city = 'Pune'   THEN 'Pune Employee'
        WHEN l.city = 'Indore' THEN 'Indore Employee'
        ELSE 'Other Location Employee'
    END AS employee_city_label
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
ORDER BY e.emp_id;

-- -----------------------------------------------------------------
-- CORRECT SOLUTION 2 -- preferred. No CASE needed: the label is a
-- pure, mechanical function of `city`, so string concatenation is
-- both simpler and automatically correct for any future city.
-- -----------------------------------------------------------------
SELECT
    e.emp_name,
    d.dept_name,
    l.city,
    l.city || ' Employee' AS employee_city_label   -- PostgreSQL / Oracle
    -- CONCAT(l.city, ' Employee') AS employee_city_label  -- MySQL / SQL Server
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
ORDER BY e.emp_id;

-- -----------------------------------------------------------------
-- PRODUCTION NOTE
-- Solution 1 is correct for CLOSED sets (a fixed list of valid
-- regional hubs that will rarely change and every new value SHOULD
-- be flagged for review). Solution 2 is correct for OPEN sets (any
-- city is valid and the label is purely cosmetic). Picking the wrong
-- one is a common source of either silent mislabeling (closed-set
-- logic applied to an open set) or missed data-quality signals
-- (open-set logic applied to a set that should be validated).
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- INTERVIEW DISCUSSION
-- Q: The original ELSE branch produced no error. How would you catch
--    this kind of bug in code review or QA before it ships?
-- A: Compare DISTINCT count(*) of labels produced against DISTINCT
--    count(*) of source values -- a mismatch (fewer output labels
--    than input categories) is the tell-tale sign of an absorbing
--    ELSE branch. Alternatively, write a test asserting every known
--    city produces a distinct, non-default label.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Write a data-quality check query: SELECT city, label, COUNT(*)
--    ... GROUP BY city, label HAVING COUNT(DISTINCT label) but
--    grouped to prove each city maps to exactly one label.
-- 2. Extend Solution 2 with a CASE on top for a real business rule,
--    e.g. flag 'Remote' for any employee whose department has no
--    location_id at all.
-- -----------------------------------------------------------------
