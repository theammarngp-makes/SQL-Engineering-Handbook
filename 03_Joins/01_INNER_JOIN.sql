-- =============================================================================
-- TOPIC: INNER JOIN
-- DIFFICULTY: Beginner
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Show each active employee's name, department, and salary.
--
-- BUSINESS SCENARIO
-- HR wants a clean payroll-readiness report. Employees without a resolved
-- department should not appear — an unassigned department is a data-entry
-- problem to flag separately (see 02_LEFT_JOIN.sql), not something payroll
-- should silently include or crash on.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name,
    d.dept_name,
    e.salary
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.status = 'active'
ORDER BY d.dept_name, e.salary DESC;

-- EXPECTED OUTPUT (9 employees have a dept_id; Divya Rao is on_leave and
-- excluded by the WHERE; Farhan Ali has no dept_id and is excluded by the JOIN)
-- 8 rows, grouped by department, highest salary first within each department.

-- ENGINEERING NOTES
-- WHERE e.status = 'active' is applied AFTER the join (see execution flow in
-- the paired .md file) — the engine still has to locate the matching
-- department row for every employee before status filtering ever happens.
-- On a large employees table, pushing status into the JOIN predicate
-- (`ON e.dept_id = d.dept_id AND e.status = 'active'`) can let the optimizer
-- filter earlier, which occasionally changes the chosen join algorithm.
-- Test both forms with EXPLAIN before assuming one is faster — the optimizer
-- often rewrites them identically.

-- INDEX RECOMMENDATION
-- idx_employees_dept_id (already created in schema/00_schema_setup.sql) is
-- what makes this an index-nested-loop rather than a full scan of employees
-- for every department row.


-- -----------------------------------------------------------------------------
-- Q2. Which departments currently have at least one active employee, and
-- how many?
--
-- BUSINESS SCENARIO
-- Finance is sanity-checking department budgets against headcount before
-- the quarterly review — a department with budget but zero staff is worth
-- flagging, but that's a different query (see 03_RIGHT_JOIN.sql).
-- -----------------------------------------------------------------------------

SELECT
    d.dept_name,
    COUNT(e.emp_id) AS active_headcount
FROM departments d
INNER JOIN employees e
    ON e.dept_id = d.dept_id
   AND e.status = 'active'
GROUP BY d.dept_name
ORDER BY active_headcount DESC;

-- EXPECTED OUTPUT
-- Engineering: 4, Sales: 2, Finance: 1, HR: 1  (4 rows — Marketing and Legal
-- have zero matching employees and are absent entirely; this is INNER JOIN's
-- defining behavior, not a bug)

-- ALTERNATIVE SOLUTION
-- The same result via a correlated subquery — slower on most optimizers for
-- this shape of question, but useful to recognize in someone else's code:
--
-- SELECT d.dept_name,
--        (SELECT COUNT(*) FROM employees e
--          WHERE e.dept_id = d.dept_id AND e.status = 'active') AS active_headcount
-- FROM departments d
-- WHERE EXISTS (SELECT 1 FROM employees e
--               WHERE e.dept_id = d.dept_id AND e.status = 'active');
--
-- Prefer the JOIN + GROUP BY form: it's a single pass over both tables
-- instead of one subquery execution per department row, and it's the
-- idiomatic form every SQL engineer will expect to see.

-- JOIN ORDER DISCUSSION
-- departments is written first here (as the "one" side of a one-to-many
-- relationship) purely for readability — "for each department, count its
-- employees" reads naturally left-to-right. The optimizer does not care
-- about this ordering for an INNER JOIN; it will reorder freely based on
-- cost estimates. Table order only affects readability, never correctness
-- or (for INNER JOIN specifically) performance guarantees.


-- -----------------------------------------------------------------------------
-- Q3. List every employee-manager pair where both people are in the same
-- department (a data-quality check: managers should generally sit in the
-- same department as their reports).
--
-- BUSINESS SCENARIO
-- Org-design audit ahead of a restructuring — surfacing cross-department
-- reporting lines that may be legitimate (a shared VP) or may be stale data.
-- -----------------------------------------------------------------------------

SELECT
    emp.emp_name  AS employee_name,
    mgr.emp_name  AS manager_name,
    emp.dept_id   AS employee_dept,
    mgr.dept_id   AS manager_dept
FROM employees emp
INNER JOIN employees mgr
    ON emp.manager_id = mgr.emp_id
WHERE emp.dept_id IS DISTINCT FROM mgr.dept_id;   -- PostgreSQL; MySQL: use <=> negated or COALESCE

-- INTERVIEW INSIGHT
-- This is an INNER JOIN of employees against itself — a preview of
-- 06_SELF_JOIN.md. Note IS DISTINCT FROM rather than <>: if either dept_id
-- were NULL, <> would silently evaluate to NULL (and the row would be
-- excluded by WHERE) instead of correctly flagging a real mismatch.
-- This exact NULL trap is a common senior-level SQL interview probe.

-- FURTHER EXPERIMENTS
-- 1. Rewrite Q1 pushing the status filter into the ON clause and compare
--    EXPLAIN output on your own database — do the plans differ?
-- 2. Add a department with a duplicate dept_id via a second, uncommitted
--    INSERT (roll it back after) and rerun Q1 — confirm the row-duplication
--    behavior described in the "Duplicate Rows" section of 01_INNER_JOIN.md.
-- 3. Rewrite Q2 to also include departments with zero active employees,
--    without changing GROUP BY — you'll need a different join type
--    entirely (03_RIGHT_JOIN.md or 02_LEFT_JOIN.md, depending on table order).
