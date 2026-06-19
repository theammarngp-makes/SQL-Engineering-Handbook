-- Q1: Employees working in same city
-- as Engineering department

SELECT e.emp_name
FROM employes e
JOIN departments d
ON e.dept_id = d.dept_id
JOIN locations l
ON d.location_id = l.location_id
WHERE l.city =
(
    SELECT l2.city
    FROM locations l2
    JOIN departments d2
    ON l2.location_id = d2.location_id
    WHERE d2.dept_name = 'Engineering'
);

-- Q2: Employees working in departments
-- not located in Pune

SELECT emp_name
FROM employes e
JOIN departments d
ON e.dept_id = d.dept_id
WHERE d.dept_id NOT IN
(
    SELECT d1.dept_id
    FROM departments d1
    JOIN locations l1
    ON d1.location_id = l1.location_id
    WHERE l1.city = 'Pune'
);
