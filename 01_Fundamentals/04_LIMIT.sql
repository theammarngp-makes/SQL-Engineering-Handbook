-- TOPIC: LIMIT
-- Dataset: employes, departments (see README.md for schema + sample data)

-- Q1
-- Show first 3 employees (by emp_id, ascending)
-- Written for MySQL / PostgreSQL. Equivalent forms on other engines:
--   SQL Server : SELECT TOP 3 * FROM employes ORDER BY emp_id;
--   Oracle 12c+: SELECT * FROM employes ORDER BY emp_id FETCH FIRST 3 ROWS ONLY;
-- See 04_LIMIT.md -> Dialect Differences for the full comparison table.

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

-- Q5
-- Same query as Q4, written in the ANSI-standard portable form
-- (works unmodified on PostgreSQL, SQL Server, and Oracle 12c+ -- not on MySQL)

SELECT *
FROM employes
ORDER BY emp_name
OFFSET 2 ROWS
FETCH NEXT 2 ROWS ONLY;
