-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 07: DERIVED TABLES (INLINE VIEWS)
-- File: 07_DERIVED_TABLES.sql
-- Description: Derived tables in FROM/JOIN clauses, pre-aggregation pipelines,
--              predicate pushdown, and CTE equivalence.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Scenario 1: Derived Table for Department Pre-Aggregation
-- Problem: Join departments with their pre-calculated employee headcount
--          and minimum hire date.
-- ----------------------------------------------------------------------------

SELECT 
    d.dept_id,
    d.dept_name,
    l.city,
    agg.total_employees,
    agg.earliest_hire_date
FROM departments d
JOIN locations l ON d.location_id = l.location_id
JOIN (
    -- Inline Derived Table (Pre-aggregating headcount per department)
    SELECT 
        e.dept_id,
        COUNT(e.emp_id) AS total_employees,
        MIN(e.hire_date) AS earliest_hire_date
    FROM employes e
    WHERE e.dept_id IS NOT NULL
    GROUP BY e.dept_id
) AS agg ON d.dept_id = agg.dept_id
WHERE agg.total_employees >= 2
ORDER BY agg.total_employees DESC;


-- ----------------------------------------------------------------------------
-- Scenario 2: Multi-Layer Derived Tables (Hierarchical Aggregation)
-- Problem: Calculate city-level workforce statistics by aggregating department
--          level headcount derived tables.
-- ----------------------------------------------------------------------------

SELECT 
    city_summary.city,
    SUM(city_summary.dept_headcount) AS total_city_headcount,
    COUNT(city_summary.dept_id) AS total_active_departments
FROM (
    SELECT 
        d.dept_id,
        d.dept_name,
        l.city,
        dept_counts.dept_headcount
    FROM departments d
    JOIN locations l ON d.location_id = l.location_id
    JOIN (
        SELECT dept_id, COUNT(*) AS dept_headcount
        FROM employes
        WHERE dept_id IS NOT NULL
        GROUP BY dept_id
    ) AS dept_counts ON d.dept_id = dept_counts.dept_id
) AS city_summary
GROUP BY city_summary.city
ORDER BY total_city_headcount DESC;


-- ----------------------------------------------------------------------------
-- Scenario 3: EXPLAIN Plan Inspection — Subquery Pull-up & Hash Aggregate
-- ----------------------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    d.dept_name,
    agg.total_employees
FROM departments d
JOIN (
    SELECT dept_id, COUNT(*) AS total_employees
    FROM employes
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) AS agg ON d.dept_id = agg.dept_id;
