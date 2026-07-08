-- =====================================================================
-- MODULE      : 09_Date_Functions
-- TOPIC       : 03_DATE_CALCULATIONS
-- OBJECTIVE   : Perform calendar-aware date arithmetic and measure
--               precise gaps between dates/timestamps.
-- DIALECT     : MySQL 8.0 (PostgreSQL / SQL Server notes inline)
--
-- DATASET USED
-- -----------------------------------------------------------------------
-- employes    (emp_id, emp_name, hire_date, dept_id, salary, termination_date)
-- departments (dept_id, dept_name)
-- orders      (order_id, customer_id, order_date, order_amount,
--              order_timestamp, delivered_timestamp)
-- =====================================================================


-- =====================================================================
-- SCENARIO 1 — Probation end date and 1-year anniversary
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   HR needs each employee's 90-day probation end date and their
--   1-year anniversary date, both computed with calendar-correct
--   interval arithmetic rather than fixed day-count approximations.
--
-- QUESTION
--   For every employee, compute probation_end (hire_date + 90 days)
--   and first_anniversary (hire_date + 1 calendar year).
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    e.hire_date,
    DATE_ADD(e.hire_date, INTERVAL 90 DAY)  AS probation_end,
    DATE_ADD(e.hire_date, INTERVAL 1 YEAR)  AS first_anniversary
FROM employes AS e
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * DATE_ADD(..., INTERVAL 1 YEAR) correctly handles leap years —
--     an employee hired on 2024-02-29 receives a valid anniversary
--     date the following non-leap year (2025-02-28), rather than an
--     invalid date or a silent error.
--   * ADDDATE(e.hire_date, INTERVAL 90 DAY) is a valid MySQL alias for
--     DATE_ADD and is functionally identical.


-- =====================================================================
-- SCENARIO 2 — Pre-hire reference marker (one month before hire)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Recruiting analytics wants a reference date one calendar month
--   before each hire date, to measure application-to-offer lead time
--   against a separate applications table.
--
-- QUESTION
--   Compute a date exactly one calendar month before each hire_date.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    e.hire_date,
    DATE_SUB(e.hire_date, INTERVAL 1 MONTH) AS pre_hire_reference_date
FROM employes AS e
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * The original version of this query used
--     DATE_SUB(hire_date, INTERVAL 90 DAY) while being labeled
--     "one month before hire" — a naming/logic mismatch. This
--     corrected version uses INTERVAL 1 MONTH to match its stated
--     business intent exactly. Always make the interval unit match
--     the business language used to describe the requirement.


-- =====================================================================
-- SCENARIO 3 — Employee tenure in days (baseline duration metric)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   The workforce dashboard's headline metric is "days since hired,"
--   refreshed daily.
--
-- QUESTION
--   Compute each employee's tenure in whole days as of today.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    DATEDIFF(CURRENT_DATE, e.hire_date) AS days_since_hired
FROM employes AS e
ORDER BY days_since_hired DESC;

-- ENGINEERING NOTES
--   * Argument order matters: DATEDIFF(date1, date2) = date1 − date2.
--     CURRENT_DATE must come first to produce a positive "days since"
--     value; reversing the arguments silently returns a negative number.


-- =====================================================================
-- SCENARIO 4 — Tenure in exact months and years (precision upgrade)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A "days since hired" number is hard for executives to interpret
--   at a glance. Workforce planning wants tenure expressed in whole
--   months and whole years as well.
--
-- QUESTION
--   Compute tenure in days, months, and years for every employee,
--   each using the correct function for that grain.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    DATEDIFF(CURRENT_DATE, e.hire_date)                    AS tenure_days,
    TIMESTAMPDIFF(MONTH, e.hire_date, CURRENT_DATE)         AS tenure_months,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURRENT_DATE)          AS tenure_years
FROM employes AS e
ORDER BY tenure_days DESC;

-- ENGINEERING NOTES
--   * tenure_months is NOT simply tenure_days / 30 — TIMESTAMPDIFF(MONTH, ...)
--     counts completed calendar months, which is the correct business
--     definition of "how many months has this person worked here."
--   * This is the standard pattern for any "duration in calendar units"
--     requirement: pick TIMESTAMPDIFF with the exact unit requested,
--     never approximate by dividing a day-count.


-- =====================================================================
-- SCENARIO 5 — Employees with more than one year of experience
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Promotion eligibility requires at least one full year of tenure.
--   The original query approximated this as "more than 365 days,"
--   which is incorrect on leap years. This scenario fixes it using
--   calendar-correct interval arithmetic.
--
-- QUESTION
--   List employees who have completed at least one full calendar
--   year of tenure, without approximating a year as 365 days.
-- =====================================================================

-- ANTI-PATTERN (breaks on leap years — do not use):
--   WHERE DATEDIFF(CURRENT_DATE, hire_date) > 365

-- CORRECT, CALENDAR-AWARE VERSION:
SELECT
    e.emp_name,
    e.hire_date,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURRENT_DATE) AS full_years_tenure
FROM employes AS e
WHERE e.hire_date <= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
ORDER BY full_years_tenure DESC;

-- ENGINEERING NOTES
--   * DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR) computes the correct
--     cutoff hire_date regardless of leap years, unlike a fixed
--     365-day approximation.
--   * The WHERE clause remains sargable — the raw hire_date column is
--     compared directly against a precomputed boundary, so an index
--     on hire_date is still usable.


-- =====================================================================
-- SCENARIO 6 — Longest-tenured and most recently hired employee
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   The HR dashboard highlights the longest-tenured employee (for a
--   service-anniversary spotlight) and the most recently hired
--   employee (for a "welcome" widget). This scenario shows three
--   equally valid approaches with different performance and
--   readability trade-offs.
--
-- QUESTION
--   Identify the employee with the longest tenure and the employee
--   with the shortest tenure.
-- =====================================================================

-- APPROACH A — ORDER BY + LIMIT (simplest, most readable):
SELECT
    e.emp_name,
    DATEDIFF(CURRENT_DATE, e.hire_date) AS tenure_days
FROM employes AS e
ORDER BY tenure_days DESC
LIMIT 1;                                  -- longest-tenured

SELECT
    e.emp_name,
    DATEDIFF(CURRENT_DATE, e.hire_date) AS tenure_days
FROM employes AS e
ORDER BY tenure_days ASC
LIMIT 1;                                  -- most recently hired

-- APPROACH B — window function (needed when ties must be preserved
-- or when the "top 1" logic must be combined with other analytics
-- in the same query):
WITH tenure_ranked AS (
    SELECT
        e.emp_name,
        DATEDIFF(CURRENT_DATE, e.hire_date) AS tenure_days,
        ROW_NUMBER() OVER (ORDER BY DATEDIFF(CURRENT_DATE, e.hire_date) DESC) AS tenure_rank
    FROM employes AS e
)
SELECT emp_name, tenure_days
FROM tenure_ranked
WHERE tenure_rank = 1;

-- ENGINEERING NOTES
--   * Approach A (ORDER BY / LIMIT) is preferred for a simple "top 1"
--     lookup — it is easier to read and typically executes with a
--     single index-backed sort.
--   * Approach B (window function) is preferred when ties must be
--     handled explicitly (e.g., RANK() to return all employees tied
--     for the longest tenure) or when the result feeds into a larger
--     CTE-based analytical query. Reserve it for cases where LIMIT 1
--     genuinely isn't expressive enough.
--   * The original version of this scenario used a correlated
--     subquery comparing MAX(DATEDIFF(...)) against every row — this
--     is the least efficient of the three approaches on a large table
--     and has been retired here in favor of Approaches A and B.


-- =====================================================================
-- SCENARIO 7 — SLA breach detection with hour-level precision
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Operations enforces a 48-hour delivery SLA. Using DATEDIFF() here
--   would truncate to whole days and hide same-day-boundary breaches;
--   TIMESTAMPDIFF(HOUR, ...) is required for correct SLA enforcement.
--
-- QUESTION
--   Flag every order where delivery exceeded 48 hours from order time.
-- =====================================================================

SELECT
    o.order_id,
    o.order_timestamp,
    o.delivered_timestamp,
    TIMESTAMPDIFF(HOUR, o.order_timestamp, o.delivered_timestamp) AS delivery_hours,
    CASE
        WHEN TIMESTAMPDIFF(HOUR, o.order_timestamp, o.delivered_timestamp) > 48
            THEN 'SLA_BREACHED'
        ELSE 'ON_TIME'
    END AS sla_status
FROM orders AS o
WHERE o.delivered_timestamp IS NOT NULL
ORDER BY delivery_hours DESC;

-- ENGINEERING NOTES
--   * DATEDIFF(delivered_timestamp, order_timestamp) would return the
--     whole-day difference and could report "0 days" — appearing
--     compliant — for an order that took 47 hours and crossed one
--     midnight boundary in a way that still fits within one calendar
--     day pair, while actually missing a same-day-of-week SLA
--     definition. TIMESTAMPDIFF(HOUR, ...) removes this ambiguity
--     entirely by measuring true elapsed hours.
--   * PostgreSQL equivalent: EXTRACT(EPOCH FROM (delivered_timestamp -
--     order_timestamp)) / 3600. SQL Server equivalent:
--     DATEDIFF(HOUR, order_timestamp, delivered_timestamp).
