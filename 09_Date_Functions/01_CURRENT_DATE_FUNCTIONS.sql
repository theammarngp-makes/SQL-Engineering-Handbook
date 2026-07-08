-- =====================================================================
-- MODULE      : 09_Date_Functions
-- TOPIC       : 01_CURRENT_DATE_FUNCTIONS
-- OBJECTIVE   : Retrieve and reason about "now" safely inside SQL,
--               and understand statement-time vs. call-time evaluation.
-- DIALECT     : MySQL 8.0 (PostgreSQL / SQL Server notes inline)
--
-- DATASET USED
-- -----------------------------------------------------------------------
-- employes    (emp_id, emp_name, hire_date, dept_id, salary, termination_date)
-- departments (dept_id, dept_name)
-- =====================================================================


-- =====================================================================
-- SCENARIO 1 — Payroll system audit stamp
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Payroll runs a nightly batch report. Every report row must be
--   stamped with the exact date and time the report was generated,
--   so auditors can trace which run produced which numbers.
--
-- QUESTION
--   Return, in one row, today's date, the current time, and the
--   current timestamp, each clearly labeled.
-- =====================================================================

SELECT
    CURRENT_DATE      AS report_date,        -- DATE      : 2026-07-07
    CURRENT_TIME       AS report_time,        -- TIME      : 14:32:07
    CURRENT_TIMESTAMP  AS report_generated_at -- DATETIME  : 2026-07-07 14:32:07
;

-- ENGINEERING NOTES
--   * CURRENT_DATE / CURRENT_TIME / CURRENT_TIMESTAMP are ANSI-standard
--     keywords, portable to PostgreSQL and SQL Server (SQL Server uses
--     GETDATE() / SYSDATETIME() as its native equivalents).
--   * Prefer these over the MySQL-only aliases (CURDATE(), NOW()) in
--     code intended to be dialect-portable; use the aliases freely in
--     MySQL-only codebases, since they are shorter and equally correct.


-- =====================================================================
-- SCENARIO 2 — Employees hired before today (baseline filter)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   HR wants a standing report — one that stays correct every day it
--   runs — listing every employee whose hire date is in the past.
--
-- QUESTION
--   List employee names and hire dates for everyone hired before today.
-- =====================================================================

SELECT
    e.emp_name,
    e.hire_date
FROM employes AS e
WHERE e.hire_date < CURRENT_DATE          -- self-updating: correct every day
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * CURRENT_DATE (or its alias CURDATE()) is evaluated ONCE at the
--     start of the statement and reused for every row — this is safe
--     and predictable even on a table with millions of rows.
--   * Never replace CURRENT_DATE with a hard-coded literal like
--     '2026-07-07' in a report that will be re-run in the future.


-- =====================================================================
-- SCENARIO 3 — 90-day probation flag (self-updating business rule)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   HR needs to flag employees who are still within their 90-day
--   probation window, evaluated as of today. This report runs daily
--   and must never require manual date updates.
--
-- QUESTION
--   Flag each employee as 'ON_PROBATION' or 'CONFIRMED' based on
--   whether fewer than 90 days have passed since their hire date.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    e.hire_date,
    CASE
        WHEN e.hire_date > CURRENT_DATE - INTERVAL 90 DAY
            THEN 'ON_PROBATION'
        ELSE 'CONFIRMED'
    END AS probation_status
FROM employes AS e
ORDER BY e.hire_date DESC;

-- ENGINEERING NOTES
--   * CURRENT_DATE - INTERVAL 90 DAY is computed once, giving every
--     row a consistent, session-safe comparison boundary.
--   * This is the pattern that keeps a "rule" (90-day probation)
--     correct indefinitely without a scheduled maintenance task.


-- =====================================================================
-- SCENARIO 4 — Sargable "today" filter on a DATETIME audit column
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Operations wants "employees whose record was touched today,"
--   assuming an audit column `updated_at DATETIME`. The naive version
--   of this query wraps the column in a function and silently
--   disables any index on `updated_at`.
--
-- QUESTION
--   Write the query BOTH the wrong way and the correct, sargable way,
--   and explain the difference.
-- =====================================================================

-- ANTI-PATTERN (do not use in production):
--   WHERE DATE(updated_at) = CURRENT_DATE
--   Wrapping the column in DATE() forces MySQL to evaluate the
--   function for every row, disabling any index on updated_at.

-- CORRECT, SARGABLE VERSION:
SELECT
    e.emp_id,
    e.emp_name
FROM employes AS e
WHERE e.hire_date >= CURRENT_DATE
  AND e.hire_date <  CURRENT_DATE + INTERVAL 1 DAY;

-- ENGINEERING NOTES
--   * The half-open range (>= start AND < end) leaves the raw column
--     untouched, so any index on hire_date / updated_at remains usable.
--   * This pattern generalizes to every "on this day" filter in the
--     handbook — you will see it again in 03_DATE_CALCULATIONS and
--     05_BUSINESS_DATE_ANALYTICS.


-- =====================================================================
-- SCENARIO 5 — NOW() vs. SYSDATE(): statement-time vs. call-time
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A junior engineer asks why a batch UPDATE using SYSDATE() produced
--   slightly different timestamps across rows in the same statement,
--   while a version using NOW() did not. This scenario demonstrates
--   the distinction directly.
--
-- QUESTION
--   Show that NOW() is frozen for the duration of a statement while
--   SYSDATE() is re-evaluated at each call.
-- =====================================================================

SELECT
    NOW()               AS now_call_1,
    SLEEP(1)             AS pause_marker,   -- forces ~1 second of elapsed time
    NOW()               AS now_call_2,      -- identical to now_call_1
    SYSDATE()            AS sysdate_call_1,
    SYSDATE()            AS sysdate_call_2  -- may differ from sysdate_call_1
;

-- ENGINEERING NOTES
--   * now_call_1 and now_call_2 will always be identical within one
--     statement — NOW() is fixed at statement start.
--   * sysdate_call_1 and sysdate_call_2 can legitimately differ if the
--     statement takes measurable time to execute — SYSDATE() is
--     re-evaluated live.
--   * PRODUCTION GUIDANCE: use NOW() / CURRENT_TIMESTAMP for anything
--     that touches replication, audit columns, or row-consistent
--     "as of" logic. Reserve SYSDATE() for the rare case where live
--     re-evaluation is an explicit, intentional requirement.
--   * PostgreSQL equivalent: NOW() behaves the same way; PostgreSQL's
--     `clock_timestamp()` is the SYSDATE()-equivalent live function.
--   * SQL Server equivalent: GETDATE() behaves like NOW(); SYSDATETIME()
--     is generally statement-consistent as well, but always test
--     against your specific SQL Server version and isolation level.
