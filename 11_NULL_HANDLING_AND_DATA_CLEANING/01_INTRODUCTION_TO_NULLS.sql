-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 01 - Introduction to NULLs
-- OBJECTIVE   : Build a correct mental model of NULL using
--               IS NULL / IS NOT NULL against realistic data.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- ============================================================

-- ------------------------------------------------------------
-- DATASET SETUP
-- These three tables (employees, customers, orders) are used
-- consistently across every file in this module so that
-- scenarios build on each other realistically.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    emp_name    VARCHAR(100),
    manager_id  INT,               -- NULL for top-of-org-chart employees
    dept_id     INT,
    hire_date   DATE,
    salary      DECIMAL(10,2)
);

INSERT INTO employees (emp_id, emp_name, manager_id, dept_id, hire_date, salary) VALUES
(1, 'Anita Rao',        NULL, 10, '2015-03-01', 185000.00),  -- CEO, no manager
(2, 'Rahul Mehta',      1,    10, '2016-06-15', 142000.00),
(3, 'Sara Kim',         1,    20, '2017-01-10', 138000.00),
(4, 'David Chen',       2,    10, '2018-09-05', 95000.00),
(5, 'Priya Nair',       2,    10, '2019-02-20', 91000.00),
(6, 'Tom Walker',       3,    20, '2019-11-11', 87000.00),
(7, 'Meera Iyer',       3,    20, '2020-07-30', NULL),        -- salary not yet recorded
(8, 'John Fischer',     NULL, 30, '2021-04-18', 78000.00);    -- contractor, no manager on record

-- ------------------------------------------------------------
-- SCENARIO 1
-- Business Context:
--   HR wants a report of every employee who does not currently
--   report to anyone, to confirm this list matches expected
--   leadership/contractor headcount.
-- Question: Which employees have no manager assigned?
-- ------------------------------------------------------------

SELECT
    emp_id,
    emp_name,
    dept_id
FROM
    employees
WHERE
    manager_id IS NULL;   -- correct: NULL must be checked with IS NULL, never "= NULL"

-- Engineering Notes:
--   manager_id = NULL would silently return zero rows here, even
--   though two rows genuinely have a NULL manager_id. This is the
--   single most common NULL bug in production SQL.
-- Optimization Notes:
--   InnoDB indexes NULL values, so IS NULL on an indexed manager_id
--   column is efficient even on large employee tables.
-- Expected Output:
--   2 rows: Anita Rao (CEO) and John Fischer (contractor).

-- ------------------------------------------------------------
-- SCENARIO 2
-- Business Context:
--   Finance wants to confirm reporting-line completeness for
--   payroll approval workflows — every employee except leadership
--   should have an approving manager.
-- Question: Which employees DO have a manager assigned?
-- ------------------------------------------------------------

SELECT
    emp_id,
    emp_name,
    manager_id
FROM
    employees
WHERE
    manager_id IS NOT NULL;

-- Engineering Notes:
--   IS NOT NULL is the logical complement of IS NULL under
--   three-valued logic and is always safe to use for this purpose,
--   unlike manager_id <> NULL, which again returns zero rows.
-- Expected Output:
--   6 rows — every employee except the CEO and the contractor.

-- ------------------------------------------------------------
-- SCENARIO 3
-- Business Context:
--   An engineer mistakenly wrote a filter using "=" to find
--   contractors with no assigned manager, and the report came
--   back empty. This scenario demonstrates why, side by side
--   with the correct version.
-- Question: Show the broken query and the corrected query
--           for the same business question.
-- ------------------------------------------------------------

-- BROKEN — returns 0 rows regardless of actual data
SELECT emp_id, emp_name
FROM employees
WHERE manager_id = NULL;

-- CORRECTED
SELECT emp_id, emp_name
FROM employees
WHERE manager_id IS NULL;

-- Engineering Notes:
--   This pair is worth keeping in code review checklists —
--   "= NULL" passes syntax validation and returns a result set,
--   so it is easy to ship silently. The bug is behavioral, not
--   syntactic, which is exactly why it survives into production.
-- Expected Output:
--   Broken query: 0 rows (always, regardless of data).
--   Corrected query: 2 rows (Anita Rao, John Fischer).

-- ------------------------------------------------------------
-- SCENARIO 4
-- Business Context:
--   Payroll wants a completeness check: how many employees are
--   missing a recorded salary before the payroll run.
-- Question: Count employees with a NULL salary.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS missing_salary_count
FROM
    employees
WHERE
    salary IS NULL;

-- Engineering Notes:
--   COUNT(*) counts rows matching the WHERE clause, regardless of
--   NULLs in any column — it is safe here because the NULL check
--   already happened in WHERE, not inside the aggregate.
-- Expected Output:
--   1 row: missing_salary_count = 1 (Meera Iyer).

-- ------------------------------------------------------------
-- SCENARIO 5
-- Business Context:
--   A junior analyst wants to find employees who report to
--   someone in a DIFFERENT department using a self-join, but
--   the join silently drops employees with no manager. This
--   scenario shows the INNER JOIN vs LEFT JOIN distinction that
--   NULL foreign keys create.
-- Question: List every employee alongside their manager's name,
--           including employees who have no manager.
-- ------------------------------------------------------------

-- INNER JOIN version — silently excludes employees with NULL manager_id
SELECT
    e.emp_name       AS employee_name,
    m.emp_name        AS manager_name
FROM
    employees e
    INNER JOIN employees m ON e.manager_id = m.emp_id;

-- LEFT JOIN version — preserves employees with no manager
SELECT
    e.emp_name                       AS employee_name,
    COALESCE(m.emp_name, 'No Manager') AS manager_name
FROM
    employees e
    LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Engineering Notes:
--   e.manager_id = m.emp_id can never be TRUE when e.manager_id
--   is NULL (per three-valued logic), so INNER JOIN naturally
--   excludes those rows. LEFT JOIN preserves them with NULL in
--   the joined columns, which COALESCE then converts to a
--   readable business label. This pattern is foundational and
--   will reappear throughout the module.
-- Optimization Notes:
--   Self-joins on manager_id should have an index on manager_id
--   (in addition to the primary key on emp_id) for large tables.
-- Expected Output:
--   INNER JOIN: 6 rows (Anita Rao and John Fischer excluded).
--   LEFT JOIN: 8 rows, with "No Manager" for those two.
