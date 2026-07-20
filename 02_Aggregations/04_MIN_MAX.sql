-- ============================================================
-- 04_MIN_MAX.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Salary range across the company
-- Problem: Compensation team needs the salary floor and ceiling
-- for a market-rate benchmarking exercise.
-- --------------------------------------------------------------

SELECT
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employes;

-- Expected Output:
-- lowest_salary | highest_salary
-- ---------------|----------------
--     40000      |     62000


-- --------------------------------------------------------------
-- Q2: Business Scenario — Salary range per department
-- Problem: Identify departments with unusually wide pay bands,
-- which may indicate role-scope inconsistency.
-- --------------------------------------------------------------

SELECT
    dept_id,
    MIN(salary) AS dept_min_salary,
    MAX(salary) AS dept_max_salary,
    MAX(salary) - MIN(salary) AS pay_band_spread
FROM employes
GROUP BY dept_id;

-- Expected Output:
-- dept_id | dept_min_salary | dept_max_salary | pay_band_spread
-- --------|-------------------|-------------------|------------------
--    10   |      40000        |      58000        |      18000
--    20   |      50000        |      62000        |      12000

-- Engineering Notes:
--   pay_band_spread is a derived aggregate expression — you can
--   perform arithmetic directly on aggregate results in the same
--   SELECT list, since both MIN() and MAX() have already been
--   reduced to single values per group by the time SELECT runs.


-- --------------------------------------------------------------
-- Q3: Business Scenario — Smallest and largest employee ID
-- (original module seed queries, retained and documented)
-- --------------------------------------------------------------

SELECT MIN(emp_id) AS smallest_employee_id FROM employes;

SELECT MAX(emp_id) AS largest_employee_id FROM employes;

-- Engineering Notes:
--   MIN(emp_id) / MAX(emp_id) on a primary key column is typically
--   resolved via a single index seek in both MySQL and PostgreSQL —
--   this is one of the cheapest possible aggregate queries, since
--   no full scan is required when an index exists on the column.


-- --------------------------------------------------------------
-- Q4: Business Scenario — Retrieving the full row of the
-- highest-paid employee (correct pattern, contrasted with the
-- common mistake documented in 04_MIN_MAX.md)
-- --------------------------------------------------------------

-- WRONG (invalid / misleading — do not use):
-- SELECT emp_name, MAX(salary) FROM employes;

-- CORRECT:
SELECT emp_name, dept_id, salary
FROM employes
ORDER BY salary DESC
LIMIT 1;

-- Expected Output:
-- emp_name | dept_id | salary
-- ---------|---------|-------
-- Bob      |   20    | 62000

-- Engineering Notes:
--   This pattern (ORDER BY + LIMIT) is the correct way to fetch
--   an entire row associated with an extreme aggregate value.
--   Module 07 (Window Functions) introduces RANK()/ROW_NUMBER()
--   as a more scalable alternative when you need, e.g., the
--   top earner *per department* in a single query.
