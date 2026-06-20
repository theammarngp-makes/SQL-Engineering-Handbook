SELECT
    e.emp_name,
    d.dept_name,
    CASE
        WHEN l.city = 'Nagpur'
        THEN 'Nagpur Employee'
        ELSE 'Pune Employee'
    END AS employee_city
FROM employes e
JOIN departments d
ON e.dept_id = d.dept_id
JOIN locations l
ON d.location_id = l.location_id;

-- Insight:
-- Creates readable employee location labels.
