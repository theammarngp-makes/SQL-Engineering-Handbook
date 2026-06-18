-- TOPIC: SELF JOIN
-- DIFFICULTY: Intermediate

-- Business Question:
-- Show each employee and their manager.

SELECT
    e2.emp_name AS employee_name,
    e1.emp_name AS manager_name
FROM employes e2
LEFT JOIN employes e1
ON e1.emp_id = e2.manager_id;

-- Insight:
-- SELF JOIN is useful for hierarchical relationships.
