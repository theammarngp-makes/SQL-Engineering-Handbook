-- =============================================================
-- LESSON 03: CASE WHEN over a multi-table aggregate
-- DIFFICULTY: Intermediate
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- SCENARIO
-- Real-estate / expansion planning wants to know which cities have
-- meaningful department concentration vs which are thin.
--
-- BUSINESS RULE
--   more than 1 distinct department in the city -> 'High Demand'
--   otherwise                                    -> 'Low Demand'
-- -----------------------------------------------------------------

SELECT
    l.city,
    COUNT(DISTINCT d.dept_id) AS department_count,
    CASE
        WHEN COUNT(DISTINCT d.dept_id) > 1 THEN 'High Demand'
        ELSE 'Low Demand'
    END AS city_status
FROM locations l
JOIN departments d ON l.location_id = d.location_id
GROUP BY l.city
ORDER BY department_count DESC;

-- Expected output (against seed data):
-- city   | department_count | city_status
-- Nagpur | 2                | High Demand
-- Pune   | 1                | Low Demand
-- Indore | 1                | Low Demand

-- -----------------------------------------------------------------
-- ALTERNATIVE SOLUTION -- include cities with zero departments
-- -----------------------------------------------------------------
SELECT
    l.city,
    COALESCE(COUNT(d.dept_id), 0) AS department_count,
    CASE
        WHEN COUNT(d.dept_id) > 1 THEN 'High Demand'
        WHEN COUNT(d.dept_id) = 1 THEN 'Low Demand'
        ELSE 'No Presence'
    END AS city_status
FROM locations l
LEFT JOIN departments d ON l.location_id = d.location_id
GROUP BY l.city
ORDER BY department_count DESC;

-- -----------------------------------------------------------------
-- PRODUCTION NOTE
-- The LEFT JOIN version surfaces a third, business-critical category
-- ('No Presence') that the INNER JOIN version cannot represent at
-- all. Whenever a CASE classification is meant to describe "the
-- state of the world," default to LEFT JOIN from the anchor entity
-- (here, locations) so absence is a visible category, not a missing
-- row.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- INTERVIEW DISCUSSION
-- Q: How would you extend this to a 3-tier system
--    (High / Medium / Low) using department budgets instead of count?
-- A: Aggregate SUM(d.budget) per city instead of COUNT(DISTINCT
--    d.dept_id), then apply CASE thresholds against the summed
--    budget -- same shape, different aggregate.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Add a region-level rollup: classify each region ('West',
--    'Central') by total department count across its cities.
-- 2. Combine city_status with department_status (Lesson 02) to find
--    "High Demand cities with mostly Small departments" -- a signal
--    that headcount hasn't caught up to office footprint.
-- -----------------------------------------------------------------
