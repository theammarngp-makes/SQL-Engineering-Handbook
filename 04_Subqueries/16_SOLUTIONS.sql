-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 16: SOLUTIONS TO PRACTICE PROBLEMS
-- File: 16_SOLUTIONS.sql
-- Description: Complete, production-ready ANSI SQL solutions for all 15
--              practice problems defined in 15_PRACTICE_PROBLEMS.md.
-- Schema Context: employes, departments, locations
-- ============================================================================

-- ============================================================================
-- TIER 1: FUNDAMENTALS & SET SEMANTICS (EASY)
-- ============================================================================

-- Solution 1: Department Aggregate Benchmark
SELECT e.emp_id, e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date < (
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = 2
)
ORDER BY e.hire_date ASC;

-- Solution 2: Multi-City Location Filtering
SELECT e.emp_id, e.emp_name, e.dept_id
FROM employes e
WHERE e.dept_id IN (
    SELECT d.dept_id
    FROM departments d
    JOIN locations l ON d.location_id = l.location_id
    WHERE l.city IN ('Nagpur', 'Pune')
)
ORDER BY e.emp_id;

-- Solution 3: Basic Anti-Join Identification
SELECT d.dept_id, d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 FROM employes e WHERE e.dept_id = d.dept_id
)
ORDER BY d.dept_id;

-- Solution 4: Scalar Projection Benchmark
SELECT 
    e.emp_name,
    e.dept_id,
    (SELECT COUNT(*) FROM employes) AS total_company_headcount
FROM employes e
ORDER BY e.emp_id;

-- Solution 5: Direct Manager Lookup
SELECT e.emp_id, e.emp_name, e.manager_id
FROM employes e
WHERE e.manager_id = (
    SELECT e_inner.manager_id 
    FROM employes e_inner 
    WHERE e_inner.emp_name = 'Ammar'
)
  AND e.emp_name <> 'Ammar';


-- ============================================================================
-- TIER 2: CORRELATION & OPTIMIZATIONS (MEDIUM)
-- ============================================================================

-- Solution 6: Department-Relative Earliest Hire (Correlated)
SELECT e.emp_id, e.emp_name, e.dept_id, e.hire_date
FROM employes e
WHERE e.hire_date = (
    SELECT MIN(sub.hire_date)
    FROM employes sub
    WHERE sub.dept_id = e.dept_id
)
ORDER BY e.dept_id;

-- Solution 7: Derived Table Pre-Aggregation Refactor
SELECT e.emp_id, e.emp_name, e.dept_id, e.hire_date
FROM employes e
JOIN (
    SELECT dept_id, MIN(hire_date) AS min_hire_date
    FROM employes
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) dept_min ON e.dept_id = dept_min.dept_id AND e.hire_date = dept_min.min_hire_date
ORDER BY e.dept_id;

-- Solution 8: Window Function Projection Refactor
SELECT 
    e.emp_name,
    e.dept_id,
    e.hire_date,
    MIN(e.hire_date) OVER (PARTITION BY e.dept_id) AS dept_first_hire
FROM employes e
ORDER BY e.dept_id;

-- Solution 9: Quantified Comparison (> ANY)
SELECT e.emp_name, e.hire_date
FROM employes e
WHERE e.hire_date > ANY (
    SELECT sub.hire_date FROM employes sub WHERE sub.dept_id = 1
)
ORDER BY e.hire_date;

-- Solution 10: Defensive NOT IN Set Matching
SELECT d.dept_id, d.dept_name
FROM departments d
WHERE d.dept_id NOT IN (
    SELECT e.dept_id FROM employes e WHERE e.dept_id IS NOT NULL
)
ORDER BY d.dept_id;


-- ============================================================================
-- TIER 3: PRODUCTION ENGINEERING & COMPLEX CASES (HARD)
-- ============================================================================

-- Solution 11: Cross-Location Manager Relationship
SELECT e.emp_id, e.emp_name, e.dept_id, e.manager_id
FROM employes e
WHERE EXISTS (
    SELECT 1 FROM departments d_emp
    JOIN locations l_emp ON d_emp.location_id = l_emp.location_id
    WHERE d_emp.dept_id = e.dept_id AND l_emp.city = 'Nagpur'
)
AND EXISTS (
    SELECT 1 FROM employes mgr
    JOIN departments d_mgr ON mgr.dept_id = d_mgr.dept_id
    JOIN locations l_mgr ON d_mgr.location_id = l_mgr.location_id
    WHERE mgr.emp_id = e.manager_id AND l_mgr.city = 'Mumbai'
);

-- Solution 12: Manager Span-of-Control Outliers
SELECT 
    mgr.emp_id AS manager_id,
    mgr.emp_name AS manager_name,
    COUNT(report.emp_id) AS direct_reports
FROM employes mgr
JOIN employes report ON report.manager_id = mgr.emp_id
GROUP BY mgr.emp_id, mgr.emp_name
HAVING COUNT(report.emp_id) > (
    SELECT COUNT(e.emp_id)::NUMERIC / COUNT(DISTINCT e.manager_id)
    FROM employes e
    WHERE e.manager_id IS NOT NULL
);

-- Solution 13: Unassigned Locations Identification
SELECT l.location_id, l.city, l.country
FROM locations l
WHERE NOT EXISTS (
    SELECT 1 FROM departments d WHERE d.location_id = l.location_id
);

-- Solution 14: Above-Average Department Headcount
SELECT d.dept_id, d.dept_name, counts.dept_headcount
FROM departments d
JOIN (
    SELECT dept_id, COUNT(*) AS dept_headcount
    FROM employes
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) counts ON d.dept_id = counts.dept_id
WHERE counts.dept_headcount > (
    SELECT COUNT(e.emp_id)::NUMERIC / COUNT(DISTINCT e.dept_id)
    FROM employes e
    WHERE e.dept_id IS NOT NULL
);

-- Solution 15: Department Seniority Ranking via Correlated Subquery
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date,
    (
        SELECT COUNT(*) + 1
        FROM employes sub
        WHERE sub.dept_id = e.dept_id
          AND sub.hire_date < e.hire_date
    ) AS dept_seniority_rank
FROM employes e
ORDER BY e.dept_id, dept_seniority_rank;
