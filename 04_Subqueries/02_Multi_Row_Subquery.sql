-- Q1: Departments having employees

SELECT dept_name
FROM departments
WHERE dept_id IN
(
    SELECT dept_id
    FROM employes
);

-- Q2: Employees NOT in Marketing

SELECT emp_name
FROM employes
WHERE dept_id NOT IN
(
    SELECT dept_id
    FROM departments
    WHERE dept_name = 'Marketing'
);
