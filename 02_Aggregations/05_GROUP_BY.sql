-- ============================================================
-- 05_GROUP_BY.sql
-- Module 02: Aggregations
-- Schema: employes(emp_id, emp_name, dept_id, manager_id, salary)
--         departments(dept_id, dept_name, location_id)
--         locations(location_id, city)
-- ============================================================

-- --------------------------------------------------------------
-- Q1: Business Scenario — Employee count by city
-- (original seed query, retained, reformatted for consistency)
-- Problem: Facilities wants total headcount per office city.
-- --------------------------------------------------------------

SELECT
    l.city,
    COUNT(e.emp_id) AS number_of_employees
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY l.city;

-- Expected Output:
-- city    | number_of_employees
-- --------|---------------------
-- Nagpur  |          3
-- Pune    |          2


-- --------------------------------------------------------------
-- Q2: Business Scenario — Department headcount, filtered to a
-- single city
-- (original seed query, retained)
-- Problem: The Nagpur site lead wants a department-level headcount
-- breakdown for their office only.
-- --------------------------------------------------------------

SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
WHERE l.city = 'Nagpur'
GROUP BY d.dept_name;

-- Engineering Notes:
--   WHERE l.city = 'Nagpur' filters ROWS before grouping — it
--   excludes Pune-based employees entirely, so they never form
--   groups in the first place. This is more efficient than
--   grouping over the whole table and filtering groups afterward.


-- --------------------------------------------------------------
-- Q3: Business Scenario — Average department salary, Nagpur only
-- Problem: Compensation review scoped to a single site.
-- --------------------------------------------------------------

SELECT
    d.dept_name,
    ROUND(AVG(e.salary), 2) AS avg_department_salary,
    COUNT(*) AS headcount
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
WHERE l.city = 'Nagpur'
GROUP BY d.dept_name;


-- --------------------------------------------------------------
-- Q4: Business Scenario — Multi-column grouping
-- Problem: HR wants headcount broken down by both department AND
-- manager, to spot managers with unusually large direct-report
-- counts within a single department.
-- --------------------------------------------------------------

SELECT
    dept_id,
    manager_id,
    COUNT(*) AS direct_reports
FROM employes
WHERE manager_id IS NOT NULL
GROUP BY dept_id, manager_id
ORDER BY dept_id, direct_reports DESC;

-- Engineering Notes:
--   GROUP BY dept_id, manager_id creates one group per unique
--   (dept_id, manager_id) PAIR — not one group per department and
--   a separate one per manager. This is the most common multi-
--   column GROUP BY misunderstanding: it's a composite key, not
--   two independent groupings.


-- --------------------------------------------------------------
-- Q5: Common Mistake, reproduced and contrasted
-- --------------------------------------------------------------

-- WRONG (invalid under strict SQL / PostgreSQL, undefined under
-- lenient MySQL):
-- SELECT emp_name, COUNT(*) FROM employes GROUP BY dept_id;

-- CORRECT:
SELECT dept_id, COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id;
