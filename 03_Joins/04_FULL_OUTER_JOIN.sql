-- =============================================================================
-- TOPIC: FULL OUTER JOIN
-- DIFFICULTY: Beginner -> Intermediate
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- DIALECT NOTE: Q1 and Q2 use native FULL OUTER JOIN (PostgreSQL/SQL Server/
-- Oracle). Q3 provides the MySQL-compatible UNION emulation of the same query.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Reconcile employees against departments: show every employee-department
-- pairing, including employees with no department and departments with no
-- employees, in a single result set.
--
-- BUSINESS SCENARIO
-- A new HRIS migration is underway. Before cutover, the migration team must
-- reconcile the legacy `employees`/`departments` tables to confirm there are
-- no orphaned records on either side before the new system goes live.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name,
    d.dept_name
FROM employees e
FULL OUTER JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- EXPECTED OUTPUT: 11 rows — 9 matched pairs, 1 row with dept_name = NULL
-- (Farhan Ali), 1 row with emp_name = NULL (Legal).


-- -----------------------------------------------------------------------------
-- Q2. Isolate ONLY the mismatches — records with no counterpart on the other
-- side — which is the actual deliverable for a pre-cutover reconciliation
-- report (nobody wants to review 9 rows they already know are fine).
--
-- BUSINESS SCENARIO
-- Same migration reconciliation, but the migration lead only wants the
-- exceptions, not the full 11-row dump.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name,
    d.dept_name,
    CASE
        WHEN e.emp_id IS NULL THEN 'department with no employees'
        WHEN d.dept_id IS NULL THEN 'employee with no department'
    END AS mismatch_type
FROM employees e
FULL OUTER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- EXPECTED OUTPUT: 2 rows — Farhan Ali ('employee with no department') and
-- Legal ('department with no employees').

-- ENGINEERING NOTES
-- This WHERE clause is safe here specifically because it's checking IS NULL
-- (not applying an equality filter) — the ON-vs-WHERE trap from
-- 02_LEFT_JOIN.md is about equality/inequality filters degrading an outer
-- join to an inner join. IS NULL checks on the join key are the one
-- category of WHERE-clause filter that's always safe to apply after an
-- outer join, because they specifically target the NULL-filled rows the
-- join produced rather than filtering matched rows out.


-- -----------------------------------------------------------------------------
-- Q3. MySQL-compatible emulation of Q1 (no native FULL OUTER JOIN in MySQL).
--
-- BUSINESS SCENARIO
-- Same reconciliation report, but the migration's staging database runs
-- MySQL 8.0, which has no FULL OUTER JOIN keyword.
-- -----------------------------------------------------------------------------

SELECT e.emp_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id

UNION   -- NOT UNION ALL — see paired .md file for why this distinction matters

SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- EXPECTED OUTPUT: identical 11 rows to Q1 — confirm this by running both
-- versions against the same seed data and diffing the results.

-- ALTERNATIVE SOLUTION
-- For the "mismatches only" version of Q2 on MySQL, it's usually cheaper to
-- run two separate anti-join queries rather than paying for a UNION-based
-- FULL OUTER JOIN emulation and then filtering it:
--
-- -- employees with no department
-- SELECT emp_name, NULL AS dept_name, 'employee with no department' AS mismatch_type
-- FROM employees e
-- WHERE NOT EXISTS (SELECT 1 FROM departments d WHERE d.dept_id = e.dept_id)
--
-- UNION ALL   -- safe here: the two halves can never overlap by construction
--
-- -- departments with no employees
-- SELECT NULL, dept_name, 'department with no employees'
-- FROM departments d
-- WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id);
--
-- Note UNION ALL is correct (not UNION) in THIS version, because the two
-- SELECTs are structurally guaranteed never to produce overlapping rows —
-- unlike Q3's LEFT/RIGHT union, where the matched rows genuinely appear in
-- both halves and must be deduplicated.

-- INTERVIEW INSIGHT
-- Being asked to produce Q3 from memory, and explain UNION vs UNION ALL in
-- that specific context, is one of the highest-frequency "do they actually
-- know MySQL" interview checks in this entire module.

-- FURTHER EXPERIMENTS
-- 1. Run Q1 and Q3 side by side (if you have access to both a Postgres and
--    a MySQL instance) and confirm identical output.
-- 2. Change Q3's UNION to UNION ALL and count the rows — confirm it returns
--    20 instead of 11, and identify exactly which 9 rows are duplicated.
-- 3. Extend Q2 to also reconcile locations against departments in the same
--    query (a three-way reconciliation) — this will require restructuring
--    into a multi-table query; see 07_MULTI_TABLE_JOINS.sql first.
