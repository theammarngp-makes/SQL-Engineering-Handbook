-- Q1: Managers managing more than one employee

SELECT emp_name
FROM employes
WHERE emp_id IN
(
    SELECT manager_id
    FROM employes
    GROUP BY manager_id
    HAVING COUNT(emp_id) > 1
);

-- Q2: Employees with no manager

SELECT emp_name
FROM employes
WHERE manager_id IS NULL;
