
-- TOPIC: Basic CASE WHEN
-- DIFFICULTY: Beginner


-- Business Question:
-- Label employees as Has Manager or No Manager.

SELECT
    emp_id,
    emp_name,
    CASE
        WHEN manager_id IS NULL THEN 'No Manager'
        ELSE 'Has Manager'
    END AS manager_status
FROM employes;

-- Insight:
-- Useful for organization hierarchy analysis.
