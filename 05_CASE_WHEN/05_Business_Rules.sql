-- =============================================================
-- LESSON 05: Business Rules with CASE WHEN
-- DIFFICULTY: Intermediate
-- SCHEMA: 00_Sample_Schema.sql
-- =============================================================

-- -----------------------------------------------------------------
-- SCENARIO
-- Leadership wants employees tagged Senior / Mid / Junior for a
-- compensation review.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- ORIGINAL (FLAWED) VERSION -- kept as a teaching example.
-- This "works" on the demo data only because low emp_id values
-- happen to belong to early hires. It is NOT a real business rule.
-- -----------------------------------------------------------------
SELECT
    emp_id,
    emp_name,
    CASE
        WHEN emp_id <= 2 THEN 'Senior'   -- BUG: emp_id is a surrogate key, not tenure
        WHEN emp_id <= 4 THEN 'Mid'
        ELSE 'Junior'
    END AS seniority_status_FLAWED
FROM employees
ORDER BY emp_id;

-- -----------------------------------------------------------------
-- CORRECT SOLUTION -- classify by actual tenure (hire_date), which
-- is the column that genuinely carries the business meaning
-- "seniority" is supposed to represent.
-- -----------------------------------------------------------------
SELECT
    emp_id,
    emp_name,
    hire_date,
    CURRENT_DATE - hire_date AS tenure_days,          -- PostgreSQL
    CASE
        WHEN CURRENT_DATE - hire_date > 1825 THEN 'Senior'  -- > 5 years
        WHEN CURRENT_DATE - hire_date > 730  THEN 'Mid'     -- > 2 years
        ELSE 'Junior'
    END AS seniority_status
FROM employees
ORDER BY hire_date;

-- -----------------------------------------------------------------
-- MySQL / SQL Server variant:
-- -----------------------------------------------------------------
-- SELECT emp_id, emp_name, hire_date,
--        DATEDIFF(day, hire_date, GETDATE()) AS tenure_days,   -- SQL Server
--        CASE
--            WHEN DATEDIFF(day, hire_date, GETDATE()) > 1825 THEN 'Senior'
--            WHEN DATEDIFF(day, hire_date, GETDATE()) > 730  THEN 'Mid'
--            ELSE 'Junior'
--        END AS seniority_status
-- FROM employees;

-- -----------------------------------------------------------------
-- PRODUCTION NOTE
-- Notice the thresholds (1825 / 730 days) are documented in the
-- comment as "5 years / 2 years" -- always pair a raw numeric
-- threshold with its business-meaning equivalent. A future
-- maintainer reading "1825" alone has to do the math themselves,
-- and might get it wrong when adjusting for leap years.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- INTERVIEW DISCUSSION
-- Q: Two employees were hired on the same date. Could this CASE
--    ever assign them different seniority tiers?
-- A: No -- CURRENT_DATE - hire_date is identical for both, so the
--    CASE evaluates identically. If they later diverge in tier,
--    that means the query was re-run on different dates, not that
--    the logic is nondeterministic within a single run.
-- -----------------------------------------------------------------

-- -----------------------------------------------------------------
-- FURTHER EXPERIMENTS
-- 1. Combine tenure tier with performance_score to build a 2-factor
--    "Promotion Readiness" label (e.g. Senior + score >= 4 -> 'Eligible').
-- 2. Handle employees with a NULL performance_score explicitly
--    rather than letting them fall through to a misleading branch.
-- -----------------------------------------------------------------
