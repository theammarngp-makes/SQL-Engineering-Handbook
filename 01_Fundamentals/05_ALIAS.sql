-- TOPIC: ALIAS
-- Dataset: employes, departments (see README.md for schema + sample data)

-- Q1
-- Rename emp_name column for a report header

SELECT
    emp_name AS employee_name
FROM employes;

-- Q2
-- Rename an aggregate result column

SELECT
    COUNT(*) AS total_employees
FROM employes;

-- Q3
-- Table alias — shorten table references

SELECT
    e.emp_name,
    e.dept_id
FROM employes AS e;

-- Q4
-- Table alias in a join (preview — JOIN itself is covered in 04_Joins)
-- Shows why table aliases matter once multiple tables are involved

SELECT
    e.emp_name  AS employee_name,
    d.dept_name AS department_name
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id;
