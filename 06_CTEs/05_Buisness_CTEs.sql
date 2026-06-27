/*
=====================================================
TOPIC: Business Case Studies using CTEs
LEVEL: Advanced
=====================================================

LEARNING GOALS
✓ Translate business questions into SQL
✓ Build analytical thinking
✓ Produce actionable insights

BUSINESS USE:
Workforce planning
Department analysis
Location strategy
Resource allocation
=====================================================
*/

-- Q1 High Demand City Analysis

-- Business Question:
-- Which cities require more workforce expansion?

-- Stakeholder:
-- Operations Team

-- KPI:
-- Employee Count

WITH emp_cte AS
(
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
    l.city,
    COUNT(e.emp_id)emp_count,
    CASE
    WHEN COUNT(e.emp_id) >=3 THEN 'High Demanded'
    ELSE 'Low Demanded'
    END as city_demand 
FROM
    emp_cte e
        JOIN
    dept_cte d 
    ON e.dept_id = d.dept_id
        JOIN
    locations_cte l 
    ON d.location_id = l.location_id
GROUP BY l.city
;

-- Q2 Active vs Inactive Department

-- Business Question:
-- Which departments are operational?

-- Stakeholder:
-- HR Team

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
    d.dept_id,
    d.dept_name,
	count(e.emp_id) as num_of_emp,
    CASE 
    WHEN count(e.emp_id) >=1 THEN 'Active'
    ELSE 'Inactive'
    END as active_status
FROM emp_cte e
LEFT JOIN dept_cte d
	ON e.dept_id = d.dept_id
GROUP BY d.dept_name,d.dept_id
;


-- Q3 Employees working in Nagpur

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
    ON d.location_id = l.location_id
WHERE l.city ='Nagpur';

-- Q4 Department with Highest Employee Count

-- Business Question:
-- Which department manages the largest workforce?

-- Stakeholder:
-- Leadership Team

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
    d.dept_id,
    d.dept_name,
	count(e.emp_id) as num_of_emp
FROM emp_cte e
JOIN dept_cte d
	ON e.dept_id = d.dept_id
GROUP BY d.dept_name,d.dept_id
ORDER BY (Count(e.emp_id)) DESC LIMIT 1 
;

-- Q5 City with Highest Employee Count

-- Business Question:
-- Which city acts as the primary workforce hub?

-- Stakeholder:
-- Expansion Strategy Team

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
    l.city,
    COUNT(e.emp_id)emp_count
FROM
    emp_cte e
        JOIN
    dept_cte d 
    ON e.dept_id = d.dept_id
        JOIN
    locations_cte l 
    ON d.location_id = l.location_id
GROUP BY l.city
ORDER BY  (COUNT( e.emp_id)) DESC LIMIT 1
;
