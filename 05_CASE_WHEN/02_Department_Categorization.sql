-- TOPIC: CASE WHEN + GROUP BY
-- DIFFICULTY: Intermediate
SELECT
    d.dept_name,
    CASE
        WHEN COUNT(DISTINCT e.emp_id) > 2 THEN 'Large'
        WHEN COUNT(DISTINCT e.emp_id) = 2 THEN 'Medium'
        ELSE 'Small'
    END AS department_status
FROM departments d
JOIN employes e
ON d.dept_id = e.dept_id
GROUP BY d.dept_name;

-- Insight:
-- Categorizes departments by workforce size.
