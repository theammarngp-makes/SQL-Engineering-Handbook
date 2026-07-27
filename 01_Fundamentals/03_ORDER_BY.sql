-- TOPIC: ORDER BY
-- Dataset: employes (see README.md for schema + sample data)

-- Q1
-- Show employees alphabetically

SELECT *
FROM employes
ORDER BY emp_name;

-- Q2
-- Show employees from highest ID to lowest ID

SELECT *
FROM employes
ORDER BY emp_id DESC;

-- Q3
-- Show employees grouped by department order

SELECT *
FROM employes
ORDER BY dept_id;

-- Q4
-- Show employees sorted by department, then by name within each department

SELECT *
FROM employes
ORDER BY dept_id, emp_name;

-- Q5
-- Sort by manager_id, explicitly controlling where NULLs (top-level employees) land
-- PostgreSQL / Oracle: NULLS LAST is native syntax
-- MySQL / SQL Server: no NULLS LAST keyword; the (manager_id IS NULL) trick forces
-- the same ordering by sorting the boolean expression first
-- (see 03_ORDER_BY.md -> Dialect Differences for why the default varies by engine)

SELECT *
FROM employes
ORDER BY (manager_id IS NULL), manager_id;
