-- TOPIC: LEFT JOIN
-- DIFFICULTY: Beginner
-- Business Question:
-- Show all employees and their departments.
SELECT
    e.emp_name,
    d.dept_name
FROM employes e
LEFT JOIN departments d
ON e.dept_id = d.dept_id;

-- Insight:
-- LEFT JOIN keeps all rows from the left table.
