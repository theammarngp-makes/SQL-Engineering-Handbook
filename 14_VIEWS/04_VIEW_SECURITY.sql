-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 04 — View Security
-- Business Obj: Expose salary benchmarking data to regional managers without
--               granting access to individual employee salaries.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql first.
-- =============================================================================

-- Business Scenario:
-- Regional managers need department/role-level salary bands for
-- benchmarking. They must never see an individual employee's salary.

-- Production Solution
CREATE OR REPLACE
    SQL SECURITY DEFINER
    VIEW vw_salary_bands AS
SELECT
    d.department_name,
    e.job_title,
    MIN(e.annual_salary) AS min_salary,
    MAX(e.annual_salary) AS max_salary,
    ROUND(AVG(e.annual_salary), 2) AS avg_salary,
    COUNT(*) AS employee_count
FROM hr_employees AS e
INNER JOIN hr_departments AS d ON d.department_id = e.department_id
GROUP BY d.department_name, e.job_title;

SELECT * FROM vw_salary_bands ORDER BY department_name, job_title;

-- Expected Output:
-- department_name | job_title          | min_salary | max_salary | avg_salary | employee_count
-- Engineering      | Data Engineer      | 96000.00   | 96000.00   | 96000.00   | 1
-- Finance          | Financial Analyst  | 71000.00   | 71000.00   | 71000.00   | 1
-- Sales            | Account Executive  | 78000.00   | 78000.00   | 78000.00   | 1
-- Sales            | Sales Manager      | 102000.00  | 102000.00  | 102000.00  | 1

-- Explanation:
-- No individual employee_id or full_name column is exposed — the View
-- structurally cannot leak individual salary even if queried with SELECT *.

-- Role and grant setup (run as an admin account with CREATE USER privilege)
-- CREATE ROLE IF NOT EXISTS 'regional_manager';
-- GRANT SELECT ON vw_salary_bands TO 'regional_manager';
-- REVOKE ALL PRIVILEGES ON hr_employees FROM 'regional_manager';  -- explicit denial, defense in depth

-- Engineering Notes:
-- SQL SECURITY DEFINER means this View executes with the privileges of
-- whichever account ran CREATE VIEW — typically a dedicated service
-- account in production, never a named employee's login.

-- Verifying the security context in the catalog
SELECT
    TABLE_NAME AS view_name,
    SECURITY_TYPE,
    DEFINER
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'vw_salary_bands';

-- Contrast: an INVOKER-security View for row-level "my own records" pattern
CREATE OR REPLACE
    SQL SECURITY INVOKER
    VIEW vw_my_finance_transactions AS
SELECT transaction_id, account_id, txn_date, amount, txn_type
FROM finance_transactions
WHERE account_id IN (
    SELECT account_id FROM finance_accounts WHERE customer_id = 1
);
-- Under INVOKER security, the querying account still needs its own SELECT
-- grant on finance_transactions and finance_accounts — INVOKER Views are
-- not a substitute for a privilege grant, only a convenience wrapper.

-- Performance Notes:
-- vw_salary_bands costs exactly what the underlying GROUP BY query costs —
-- SQL SECURITY adds no runtime overhead, it only changes privilege
-- resolution at parse time.

-- Common Mistakes:
-- Granting a restricted role SELECT on vw_salary_bands AND SELECT on
-- hr_employees "just in case" — this defeats the entire control. Audit with:
SELECT grantee, table_name, privilege_type
FROM information_schema.TABLE_PRIVILEGES
WHERE table_name IN ('hr_employees', 'vw_salary_bands');

-- Alternative Solution (column-level GRANT, without a View — shown for
-- contrast; note this does NOT prevent aggregation-avoidance leaks the way
-- an aggregated View does):
-- GRANT SELECT (department_id, job_title) ON hr_employees TO 'regional_manager';

-- Interview Insight:
-- A strong answer to "how do you restrict salary visibility" leads with the
-- View-based aggregation approach and explicitly states why it's stronger
-- than column-level grants: column grants still expose one row per
-- employee, allowing re-identification in small departments; an aggregated
-- View structurally cannot.

-- Further Challenge:
-- Design a row-level security View for hr_employees such that each
-- manager, querying under SQL SECURITY INVOKER, only sees employees in
-- their own department_id — using CURRENT_USER() mapped to a
-- department via a lookup table.
