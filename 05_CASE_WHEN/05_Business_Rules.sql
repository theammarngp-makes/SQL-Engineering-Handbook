SELECT
    emp_id,
    emp_name,
    CASE
        WHEN emp_id <= 2 THEN 'Senior'
        WHEN emp_id <= 4 THEN 'Mid'
        ELSE 'Junior'
    END AS seniority_status
FROM employes;

-- Insight:
-- Demonstrates business rule implementation.

-- Interview Note:
-- CASE stops evaluating after the first TRUE condition.
