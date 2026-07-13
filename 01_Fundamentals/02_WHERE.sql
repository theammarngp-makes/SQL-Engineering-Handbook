-- TOPIC: WHERE
-- Dataset: employes (see README.md for schema + sample data)

-- Q1
-- Find employees from department 2

SELECT *
FROM employes
WHERE dept_id = 2;

-- Q2
-- Find employees with a manager

SELECT *
FROM employes
WHERE manager_id IS NOT NULL;

-- Q3
-- Find employees without a manager (top-level employees)

SELECT *
FROM employes
WHERE manager_id IS NULL;

-- Q4
-- Find employees whose manager is Sahil
-- Step 1: confirm Sahil's emp_id -> 3
-- Step 2: filter employes where manager_id = 3
-- Written as a subquery so the logic doesn't depend on hardcoding Sahil's id

SELECT *
FROM employes
WHERE manager_id = (
    SELECT emp_id
    FROM employes
    WHERE emp_name = 'Sahil'
);

-- Q5
-- Find employees NOT working in department 1

SELECT *
FROM employes
WHERE dept_id <> 1;

-- ---------------------------------------------------------------------
-- CHALLENGE (forward reference — requires JOIN, covered in 04_Joins)
-- Q6: Find employees working in departments located in Nagpur.
-- Q7: Find employees whose department belongs to India.
--
-- Preview of the shape these queries will take once JOIN is covered:
--
-- SELECT e.emp_name
-- FROM employes e
-- JOIN departments d ON e.dept_id = d.dept_id
-- WHERE d.city = 'Nagpur';
-- ---------------------------------------------------------------------
