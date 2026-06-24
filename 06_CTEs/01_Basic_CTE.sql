/*
TOPIC: Basic CTEs
LEVEL: Beginner

LEARNING GOALS
Create a CTE
Query a CTE
Improve query readability

REAL WORLD USE:
Create temporary datasets before analysis.*/

-- Q1 Create employee_cte and display all employees
-- Business Goal:
-- Create a reusable employee dataset.

WITH employes_CTE AS 
(
SELECT 
    emp_id,
    emp_name,
    dept_id,
    manager_id
    
FROM
    EMPLOYES
)
SELECT 
    *
FROM
    employes_CTE ;

-- Q2 Create department_cte and display all departments
-- Business Goal:
-- Create a reusable deaprtments dataset.

WITH dept_CTE AS 
(
SELECT 
    dept_id,
    dept_name,
    location_id
FROM
    departments
)
SELECT 
    *
FROM
    dept_CTE;

-- Q3 Create location_cte and display all locations
-- Business Goal:
-- Create a reusable locations dataset.

WITH location_CTE AS 
(
SELECT 
    location_id,
    city
FROM
    locations
)
SELECT 
    *
FROM
    location_CTE;
