-- TOPIC: Single Row Subquery

-- Q1: Find employees whose emp_id is greater
-- than average emp_id

SELECT emp_name
FROM employes
WHERE emp_id >
(
    SELECT AVG(emp_id)
    FROM employes
);

-- Insight:
-- Compare records against company averages.
