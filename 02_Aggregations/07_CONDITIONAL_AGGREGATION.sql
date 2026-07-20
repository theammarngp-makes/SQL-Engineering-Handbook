-- ============================================================
-- 07_CONDITIONAL_AGGREGATION.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
--         departments(dept_id, dept_name, location_id)
--         locations(location_id, city)
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Pay-band split per department
-- Problem: HR wants, in a single row per department, how many
-- employees earn above $50,000 vs. at or below — without running
-- two separate queries.
-- --------------------------------------------------------------

SELECT
    dept_id,
    COUNT(CASE WHEN salary > 50000 THEN 1 END) AS high_earner_count,
    COUNT(CASE WHEN salary <= 50000 THEN 1 END) AS standard_earner_count,
    COUNT(*) AS total_employees
FROM employes
GROUP BY dept_id;

-- Expected Output:
-- dept_id | high_earner_count | standard_earner_count | total_employees
-- --------|---------------------|--------------------------|------------------
--    10   |          1          |            1              |        2
--    20   |          1          |            1              |        2

-- Engineering Notes:
--   total_employees is included as a sanity check — it should
--   always equal high_earner_count + standard_earner_count when
--   the two CASE conditions are exhaustive and mutually exclusive,
--   which they are here (> 50000 and <= 50000 cover every case).


-- --------------------------------------------------------------
-- Q2: Business Scenario — Same report, PostgreSQL FILTER syntax
-- Problem: Same as Q1, written in PostgreSQL's more concise
-- FILTER (WHERE ...) form. Not portable to MySQL.
-- --------------------------------------------------------------

SELECT
    dept_id,
    COUNT(*) FILTER (WHERE salary > 50000) AS high_earner_count,
    COUNT(*) FILTER (WHERE salary <= 50000) AS standard_earner_count
FROM employes
GROUP BY dept_id;


-- --------------------------------------------------------------
-- Q3: Business Scenario — City pivot per department
-- Problem: Leadership wants department headcount broken out by
-- city, as columns rather than extra rows — a classic pivot.
-- --------------------------------------------------------------

SELECT
    d.dept_name,
    SUM(CASE WHEN l.city = 'Nagpur' THEN 1 ELSE 0 END) AS nagpur_employees,
    SUM(CASE WHEN l.city = 'Pune' THEN 1 ELSE 0 END) AS pune_employees,
    COUNT(*) AS total
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY d.dept_name;

-- Engineering Notes:
--   SUM(CASE WHEN ... THEN 1 ELSE 0 END) is used here instead of
--   COUNT(CASE WHEN ... THEN 1 END) purely by convention — both
--   produce identical results. SUM requires the explicit ELSE 0;
--   COUNT does not, since COUNT never counts NULLs.


-- --------------------------------------------------------------
-- Q4: Business Scenario — Conditional revenue-style total
-- Problem: Demonstrates the SUM-based pivot pattern using salary
-- as a stand-in for a revenue/amount column, split by pay band.
-- --------------------------------------------------------------

SELECT
    dept_id,
    SUM(CASE WHEN salary > 50000 THEN salary ELSE 0 END) AS high_band_payroll,
    SUM(CASE WHEN salary <= 50000 THEN salary ELSE 0 END) AS standard_band_payroll
FROM employes
GROUP BY dept_id;

-- Expected Output:
-- dept_id | high_band_payroll | standard_band_payroll
-- --------|---------------------|---------------------------
--    10   |        58000        |          40000
--    20   |        62000        |          50000

-- Engineering Notes:
--   Note the ELSE salary is NOT used here — ELSE 0 is required so
--   that non-matching rows contribute 0 to this specific bucket's
--   total, rather than NULL (which SUM would silently skip anyway,
--   but explicit 0 keeps the CASE expression's intent unambiguous
--   to future readers).


-- --------------------------------------------------------------
-- Q5: Common Mistake, reproduced and contrasted
-- --------------------------------------------------------------

-- WRONG — using WHERE eliminates the ability to see both buckets:
-- SELECT dept_id, COUNT(*) AS high_earner_count
-- FROM employes WHERE salary > 50000 GROUP BY dept_id;
-- (standard_earner_count is now unobtainable in this same query)

-- CORRECT:
SELECT
    dept_id,
    COUNT(CASE WHEN salary > 50000 THEN 1 END) AS high_earner_count,
    COUNT(CASE WHEN salary <= 50000 THEN 1 END) AS standard_earner_count
FROM employes
GROUP BY dept_id;
