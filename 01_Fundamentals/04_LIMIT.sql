-- TOPIC: LIMIT
-- Dataset: employes, departments (see README.md for schema + sample data)

-- Q1
-- Show first 3 employees (by emp_id, ascending)

SELECT *
FROM employes
ORDER BY emp_id
LIMIT 3;

-- Q2
-- Show first 2 departments

SELECT *
FROM departments
LIMIT 2;

-- Q3
-- Top 2 highest emp_ids

SELECT *
FROM employes
ORDER BY emp_id DESC
LIMIT 2;

-- Q4
-- Pagination: page 2 of a 2-row-per-page employee listing, sorted by name

SELECT *
FROM employes
ORDER BY emp_name
LIMIT 2 OFFSET 2;
