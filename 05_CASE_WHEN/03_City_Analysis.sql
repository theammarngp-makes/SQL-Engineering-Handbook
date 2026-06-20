SELECT
    l.city,
    CASE
        WHEN COUNT(DISTINCT d.dept_id) > 1
        THEN 'High Demand'
        ELSE 'Low Demand'
    END AS city_status
FROM locations l
JOIN departments d
ON l.location_id = d.location_id
GROUP BY l.city;

-- Insight:
-- Classifies cities according to department concentration.
