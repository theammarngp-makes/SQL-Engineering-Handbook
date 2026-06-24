/*
=====================================================
TOPIC: Multiple CTEs
LEVEL: Intermediate
=====================================================

LEARNING GOALS
✓ Chain multiple CTEs
✓ Improve modular SQL design
✓ Prepare data for reporting

BUSINESS USE:
Break large reports into smaller logical steps.
=====================================================
*/

-- Q1 Create employee_cte and department_cte

-- Business Goal:
-- Identify department assignment of employees.

WITH emp_cte AS
(
  SELECT 
    emp_id,
    emp_name,
    dept_id
FROM
    employes
),
dept_cte AS
( 
SELECT 
    dept_id,
    dept_name
FROM
    departments
)
  
SELECT 
    emp_id,
    emp_name,
    dept_name 
    FROM emp_cte e
JOIN dept_cte d
ON  d.dept_id = e.dept_id ;

-- Q2 Join employee_cte and department_cte
-- Business Goal:
-- Identify department & employes temporary table and joining them for any future filterations or grouping.

WITH emp_cte AS
(
  SELECT 
    emp_id,
    emp_name,
    dept_id
FROM
    employes
),
dept_cte AS
( 
SELECT 
    dept_id,
    dept_name
FROM
    departments
)
SELECT e.emp_id,e.emp_name,d.dept_name 
FROM emp_cte e JOIN dept_cte d ON e.dept_id = d.dept_id ;

-- Q3 Create location_cte and combine all three tables
-- Business Goal:
-- Identify departmenst & info abt employes and locations.

WITH emp_cte AS
(
  SELECT 
    emp_id,
    emp_name,
    dept_id
FROM
    employes
),
dept_cte AS( SELECT 
    dept_id,
    dept_name,
    location_id
FROM
    departments
),
locations_cte as( SELECT 
    city, 
    location_id
FROM
    locations
)
SELECT 
    e.emp_id,
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
