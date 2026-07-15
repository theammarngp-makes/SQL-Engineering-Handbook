-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 02 — Creating Views
-- Business Obj: Standardize idempotent, well-documented View creation patterns.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql first (creates base schema).
-- =============================================================================

-- Business Scenario:
-- HR wants a governed headcount-by-department View for a monthly leadership
-- report, deployed via CI/CD, safe to redeploy on every merge.

-- Production Solution
CREATE OR REPLACE VIEW vw_headcount_by_department
    (department_name, region, headcount) AS
SELECT
    d.department_name,
    d.region,
    COUNT(e.employee_id)
FROM hr_departments AS d
LEFT JOIN hr_employees AS e
    ON e.department_id = d.department_id
GROUP BY d.department_name, d.region;

SELECT * FROM vw_headcount_by_department ORDER BY headcount DESC;

-- Expected Output:
-- department_name | region | headcount
-- Sales            | AMER   | 2
-- Engineering      | APAC   | 1
-- Finance          | EMEA   | 1

-- Explanation:
-- CREATE OR REPLACE is idempotent — safe to run in a CI/CD pipeline on every
-- deploy without a DROP step, preserving any GRANTs issued directly on the
-- View object.

-- Engineering Notes:
-- LEFT JOIN is required here, not INNER JOIN — a department with zero
-- employees should still appear with headcount = 0, not disappear from the
-- report. This is a common interview trap.

-- Redefining a View safely (idempotent redeploy)
CREATE OR REPLACE VIEW vw_headcount_by_department
    (department_name, region, headcount) AS
SELECT
    d.department_name,
    d.region,
    COUNT(e.employee_id)
FROM hr_departments AS d
LEFT JOIN hr_employees AS e
    ON e.department_id = d.department_id
WHERE e.hire_date IS NULL OR e.hire_date <= CURDATE()   -- guards against future-dated test data
GROUP BY d.department_name, d.region;

-- Demonstrating ALTER VIEW (full redefinition, same object identity)
ALTER VIEW vw_headcount_by_department
    (department_name, region, headcount) AS
SELECT
    d.department_name,
    d.region,
    COUNT(e.employee_id)
FROM hr_departments AS d
LEFT JOIN hr_employees AS e
    ON e.department_id = d.department_id
GROUP BY d.department_name, d.region;

-- Inspecting stored View definitions (production debugging pattern)
SELECT
    TABLE_NAME       AS view_name,
    VIEW_DEFINITION,
    IS_UPDATABLE,
    SECURITY_TYPE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'vw_headcount_by_department';

-- Performance Notes:
-- CREATE/ALTER/DROP VIEW are all metadata-catalog operations only — cost is
-- O(1) with respect to base table row count.

-- Common Mistakes:
-- Using DROP VIEW IF EXISTS + CREATE VIEW as two separate statements in a
-- deploy script — during that gap, any process querying the View fails.

DROP VIEW IF EXISTS vw_headcount_by_department_deprecated;  -- safe cleanup pattern

-- Alternative Solution (explicit two-step, only when object identity change
-- is genuinely required, e.g. changing SQL SECURITY definer — ALTER VIEW
-- cannot change DEFINER):
-- DROP VIEW IF EXISTS vw_headcount_by_department;
-- CREATE VIEW vw_headcount_by_department ... ;

-- Interview Insight:
-- "Why not just always DROP + CREATE?" — because GRANT ... ON vw_x TO user
-- statements are tied to the View object; DROP removes the object and its
-- direct grants, forcing you to re-grant after every deploy. CREATE OR
-- REPLACE avoids this entirely.

-- Further Challenge:
-- Write a CREATE OR REPLACE VIEW for "departments with zero headcount" using
-- vw_headcount_by_department as a base (nested View) — verify it returns
-- the correct result after the LEFT JOIN behavior above.
