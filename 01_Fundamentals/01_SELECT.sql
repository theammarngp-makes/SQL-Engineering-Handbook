-- TOPIC: SELECT
-- Dataset: employes (see README.md for schema + sample data)

-- Q1
-- Show all employee names

SELECT emp_name
FROM employes;

-- Q2
-- Show all employee ids

SELECT emp_id
FROM employes;

-- Q3
-- Show employee name and department id

SELECT
    emp_name,
    dept_id
FROM employes;

-- Q4
-- Explore the full employes table during initial data profiling
-- (SELECT * is fine for one-off exploration; avoid it in application code)

SELECT *
FROM employes;
