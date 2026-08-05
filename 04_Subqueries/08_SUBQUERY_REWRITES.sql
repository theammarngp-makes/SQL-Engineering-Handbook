-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 08: SUBQUERY REWRITES & PATTERN CATALOG
-- File: 08_SUBQUERY_REWRITES.sql
-- Description: Complete executable implementations of all 6 canonical subquery
--              rewrite patterns for production database refactoring.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Pattern 1: IN Subquery -> EXISTS / Semi-Join
-- ----------------------------------------------------------------------------

-- Before (IN)
SELECT emp_name FROM employes 
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location_id = 1);

-- After (EXISTS Semi-Join)
SELECT e.emp_name FROM employes e
WHERE EXISTS (
    SELECT 1 FROM departments d 
    WHERE d.dept_id = e.dept_id AND d.location_id = 1
);


-- ----------------------------------------------------------------------------
-- Pattern 2: NOT IN Subquery -> NOT EXISTS Anti-Join
-- ----------------------------------------------------------------------------

-- Before (NOT IN - Dangerous if NULLs present)
SELECT dept_name FROM departments 
WHERE dept_id NOT IN (SELECT dept_id FROM employes WHERE dept_id IS NOT NULL);

-- After (NOT EXISTS - 100% Safe Anti-Join)
SELECT d.dept_name FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employes e WHERE e.dept_id = d.dept_id
);


-- ----------------------------------------------------------------------------
-- Pattern 3: Correlated Aggregate Subquery -> Derived Table Pre-Aggregation
-- ----------------------------------------------------------------------------

-- Before (Correlated SubPlan O(N*M))
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date = (
    SELECT MIN(sub.hire_date) FROM employes sub WHERE sub.dept_id = e.dept_id
);

-- After (Derived Table Hash Join O(N+M))
SELECT e.emp_name, e.hire_date
FROM employes e
JOIN (
    SELECT dept_id, MIN(hire_date) AS min_hire
    FROM employes
    GROUP BY dept_id
) d_min ON e.dept_id = d_min.dept_id AND e.hire_date = d_min.min_hire;


-- ----------------------------------------------------------------------------
-- Pattern 4: Projected Scalar Subquery -> Window Function
-- ----------------------------------------------------------------------------

-- Before (Projected SubPlan)
SELECT 
    e.emp_name,
    (SELECT COUNT(*) FROM employes sub WHERE sub.dept_id = e.dept_id) AS dept_count
FROM employes e;

-- After (Window Function Single Pass)
SELECT 
    e.emp_name,
    COUNT(*) OVER (PARTITION BY e.dept_id) AS dept_count
FROM employes e;


-- ----------------------------------------------------------------------------
-- Pattern 5: Duplicated Subquery -> Common Table Expression (CTE)
-- ----------------------------------------------------------------------------

WITH target_depts AS (
    SELECT dept_id FROM departments WHERE location_id = 1
)
SELECT e.emp_name, e.dept_id
FROM employes e
WHERE e.dept_id IN (SELECT dept_id FROM target_depts);
