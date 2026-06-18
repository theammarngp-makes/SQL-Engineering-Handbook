-- TOPIC: RIGHT JOIN
-- DIFFICULTY: Beginner

-- Business Question:
-- Show all departments even if they have no employees.

SELECT
    e.emp_name,
    d.dept_name
FROM employes e
RIGHT JOIN departments d
ON e.dept_id = d.dept_id;

-- Insight:
-- RIGHT JOIN keeps all rows from the right table.
