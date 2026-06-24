/*
=====================================================
TOPIC: CTEs with Joins
LEVEL: Intermediate
=====================================================

LEARNING GOALS
✓ Combine multiple datasets
✓ Use CTEs before joins
✓ Build reporting datasets

BUSINESS USE:
Employee location reporting.
=====================================================
*/

-- Q1 Show employee name and department name

WITH emp_cte AS ( 
SELECT 
    emp_id,
    emp_name,
    dept_id
FROM
    employes
),
dept_cte AS ( 
SELECT 
    dept_id,
    dept_name
FROM
    departments
)
SELECT 
    e.emp_name, 
    d.dept_name
FROM emp_cte e
JOIN dept_cte d
	ON e.dept_id = d.dept_id;
    
-- Q2 Show employee name, department name and city

WITH emp_cte AS (
SELECT 
    emp_id,
    emp_name,
    dept_id
FROM
    employes
),
dept_cte AS ( 
 SELECT 
    dept_id,
    dept_name,
    location_id
FROM
    departments
),
locations_cte AS ( 
SELECT 
    city, 
    location_id
FROM
    locations
)
SELECT 
    e.emp_name,
    d.dept_name,
    l.city
FROM
    emp_cte e
        JOIN
    dept_cte d 
    ON e.dept_id = d.dept_id
        JOIN
    locations_cte l 
    ON d.location_id = l.location_id;

-- Q3 Show employees working in Nagpur using CTE

-- Business Goal:
-- Find employees assigned to Nagpur offices.

-- Stakeholder:
-- HR / Workforce Planning Team
WITH emp_cte AS (
SELECT 
    emp_id,
    emp_name,
    dept_id
FROM
    employes
),
dept_cte AS ( 
 SELECT 
    dept_id,
    dept_name,
    location_id
FROM
    departments
),
locations_cte AS ( 
SELECT 
    city, 
    location_id
FROM
    locations
)
SELECT 
    e.emp_name,
    d.dept_name,
    l.city
FROM
    emp_cte e
        JOIN
    dept_cte d 
    ON e.dept_id = d.dept_id
        JOIN
    locations_cte l 
    ON d.location_id = l.location_id
WHERE l.city = 'Nagpur'   ;
