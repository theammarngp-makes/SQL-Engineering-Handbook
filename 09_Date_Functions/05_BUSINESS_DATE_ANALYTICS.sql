-- =====================================================================
-- MODULE      : 09_Date_Functions
-- TOPIC       : 05_BUSINESS_DATE_ANALYTICS
-- OBJECTIVE   : Combine current-date, extraction, calculation, and
--               formatting functions into production reporting
--               patterns: rolling windows, MTD/QTD/YTD, fiscal
--               calendars, tenure, SLA monitoring, and cohort
--               bucketing foundations.
-- DIALECT     : MySQL 8.0 (PostgreSQL / SQL Server notes inline)
--
-- DATASET USED
-- -----------------------------------------------------------------------
-- employes      (emp_id, emp_name, hire_date, dept_id, salary, termination_date)
-- departments   (dept_id, dept_name)
-- orders        (order_id, customer_id, order_date, order_amount)
-- subscriptions (subscription_id, customer_id, start_date, end_date, plan_amount)
-- =====================================================================


-- =====================================================================
-- SCENARIO 1 — Rolling trailing-window revenue (last 7 and last 30 days)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   The sales operations dashboard shows trailing 7-day and trailing
--   30-day revenue, refreshed every morning with zero manual date
--   maintenance.
--
-- QUESTION
--   Compute total revenue for the trailing 7 days and trailing 30
--   days, using a single, consistent definition of "today."
-- =====================================================================

WITH reporting_window AS (
    SELECT CURRENT_DATE AS as_of_date          -- computed once, reused everywhere
)
SELECT
    SUM(CASE WHEN o.order_date >= rw.as_of_date - INTERVAL 7 DAY
              AND o.order_date <  rw.as_of_date + INTERVAL 1 DAY
             THEN o.order_amount END) AS revenue_last_7_days,
    SUM(CASE WHEN o.order_date >= rw.as_of_date - INTERVAL 30 DAY
              AND o.order_date <  rw.as_of_date + INTERVAL 1 DAY
             THEN o.order_amount END) AS revenue_last_30_days
FROM orders AS o
CROSS JOIN reporting_window AS rw;

-- ENGINEERING NOTES
--   * The reporting_window CTE freezes "today" once for the entire
--     query, guaranteeing the 7-day and 30-day figures are measured
--     from the exact same instant — critical when a dashboard query
--     computes many window metrics side by side.
--   * Half-open ranges (>= start AND < end) are used throughout,
--     matching the sargability discipline from every prior file in
--     this module.


-- =====================================================================
-- SCENARIO 2 — MTD, QTD, and YTD in a single consistent query
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   The executive revenue dashboard shows month-to-date, quarter-to-
--   date, and year-to-date figures side by side. All three must be
--   anchored to the same "today," including correct behavior on the
--   1st of the month, quarter, or year.
--
-- QUESTION
--   Compute MTD, QTD, and YTD revenue in one query.
-- =====================================================================

WITH period_boundaries AS (
    SELECT
        CURRENT_DATE                                            AS as_of_date,
        DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')                    AS month_start,
        DATE_FORMAT(
            CURRENT_DATE - INTERVAL ((MONTH(CURRENT_DATE) - 1) % 3) MONTH,
            '%Y-%m-01'
        )                                                        AS quarter_start,
        DATE_FORMAT(CURRENT_DATE, '%Y-01-01')                     AS year_start
)
SELECT
    SUM(CASE WHEN o.order_date >= pb.month_start
              AND o.order_date <  pb.as_of_date + INTERVAL 1 DAY
             THEN o.order_amount END) AS revenue_mtd,
    SUM(CASE WHEN o.order_date >= pb.quarter_start
              AND o.order_date <  pb.as_of_date + INTERVAL 1 DAY
             THEN o.order_amount END) AS revenue_qtd,
    SUM(CASE WHEN o.order_date >= pb.year_start
              AND o.order_date <  pb.as_of_date + INTERVAL 1 DAY
             THEN o.order_amount END) AS revenue_ytd
FROM orders AS o
CROSS JOIN period_boundaries AS pb;

-- ENGINEERING NOTES
--   * quarter_start is derived by rolling CURRENT_DATE back to the
--     first day of its own calendar month, then subtracting however
--     many extra months into the current quarter we already are —
--     (MONTH(CURRENT_DATE) - 1) % 3 — which is 0, 1, or 2.
--   * All three periods reuse as_of_date as their common upper bound,
--     so MTD/QTD/YTD are always measured "as of the same moment."
--   * Tested edge case: on the 1st of a month, month_start equals
--     as_of_date, correctly returning exactly one day of MTD data —
--     not zero, not an error.


-- =====================================================================
-- SCENARIO 3 — Fiscal quarter labeling (fiscal year starts in April)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Finance operates on a fiscal year starting April 1, not January 1.
--   Calendar QUARTER() cannot be used directly; each order must be
--   labeled with its correct fiscal quarter.
--
-- QUESTION
--   Label every order with its fiscal year and fiscal quarter, given
--   a fiscal year that starts in April.
-- =====================================================================

SELECT
    o.order_id,
    o.order_date,
    -- Fiscal year: if the calendar month is Jan-Mar, the order belongs
    -- to the fiscal year that STARTED the previous April.
    CASE
        WHEN MONTH(o.order_date) >= 4
            THEN YEAR(o.order_date)
        ELSE YEAR(o.order_date) - 1
    END AS fiscal_year,
    -- Fiscal quarter: shift the calendar month so April becomes
    -- "fiscal month 1," then derive the quarter from that shifted month.
    FLOOR((((MONTH(o.order_date) - 4 + 12) % 12)) / 3) + 1 AS fiscal_quarter
FROM orders AS o
ORDER BY fiscal_year, fiscal_quarter, o.order_date;

-- ENGINEERING NOTES
--   * (MONTH(order_date) - 4 + 12) % 12 shifts April (month 4) to
--     fiscal-month-index 0, May to 1, ... March to 11. Dividing by 3
--     and flooring produces fiscal quarters 0-3, so +1 yields 1-4.
--   * In a production system, hard-coding "4" for the fiscal year
--     start month in multiple queries is a maintainability risk —
--     store it once as a configuration value (e.g., a single-row
--     fiscal_calendar_config table) and reference it consistently,
--     rather than repeating the literal across every report.
--   * PostgreSQL / SQL Server: the same shift-and-divide arithmetic
--     applies identically; only the modulo and floor syntax differ.


-- =====================================================================
-- SCENARIO 4 — Employee tenure by department (production-grade rewrite)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   The workforce dashboard's core table shows every employee's
--   department alongside their tenure — this is the production-grade
--   successor to the original ad hoc "tenure in days" query, now
--   including department context and multiple tenure grains.
--
-- QUESTION
--   For every employee, show department, tenure in days, tenure in
--   full years, and a tenure bucket label used for a workforce
--   segmentation chart.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.hire_date,
    DATEDIFF(CURRENT_DATE, e.hire_date)              AS tenure_days,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURRENT_DATE)    AS tenure_full_years,
    CASE
        WHEN e.hire_date > CURRENT_DATE - INTERVAL 90 DAY  THEN 'ON_PROBATION'
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURRENT_DATE) < 1  THEN 'UNDER_1_YEAR'
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURRENT_DATE) < 5  THEN '1_TO_5_YEARS'
        ELSE '5_PLUS_YEARS'
    END AS tenure_bucket
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id
ORDER BY tenure_days DESC;

-- ENGINEERING NOTES
--   * This consolidates and extends the original Q20 ("employee
--     tenure in days, joined to departments") with the calendar-aware
--     patterns established across this entire module: full-year
--     tenure via TIMESTAMPDIFF (Module 03), and a readable business
--     segmentation label built with CASE (Module 05).
--   * tenure_bucket boundaries are evaluated in order from most
--     specific (ON_PROBATION) to least specific — CASE evaluates
--     top-down and stops at the first TRUE condition, so ordering
--     matters here exactly as it does in any CASE expression.


-- =====================================================================
-- SCENARIO 5 — Subscriptions renewing in the next 30 days
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Customer success needs a proactive outreach list: every
--   subscription due to renew within the next 30 days, so the team
--   can reach out before churn risk increases.
--
-- QUESTION
--   List active subscriptions with an end_date within the next 30
--   days, along with days remaining until renewal.
-- =====================================================================

SELECT
    s.subscription_id,
    s.customer_id,
    s.end_date                                    AS renewal_date,
    DATEDIFF(s.end_date, CURRENT_DATE)             AS days_until_renewal
FROM subscriptions AS s
WHERE s.end_date >= CURRENT_DATE
  AND s.end_date <  CURRENT_DATE + INTERVAL 30 DAY
ORDER BY days_until_renewal ASC;

-- ENGINEERING NOTES
--   * The lower bound (s.end_date >= CURRENT_DATE) excludes already-
--     expired subscriptions from a renewal outreach list — those
--     belong in a separate "lapsed" report, not a proactive one.
--   * DATEDIFF(end_date, CURRENT_DATE) is deliberately ordered with
--     the future date first, producing a positive "days remaining"
--     count consistent with the tenure-calculation argument-order
--     discipline established in Module 03.


-- =====================================================================
-- SCENARIO 6 — Cohort bucketing foundation (signup month retention shape)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Product analytics wants the foundational shape of a cohort
--   retention report: customers grouped by signup month, alongside
--   whether they placed an order within their first 30 days. This is
--   the direct precursor to the full cohort-analysis techniques
--   covered in a later module.
--
-- QUESTION
--   Bucket customers by signup month (using their first order date as
--   a proxy for signup) and compute what fraction placed a second
--   order within 30 days of their first.
-- =====================================================================

WITH first_orders AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS first_order_date
    FROM orders AS o
    GROUP BY o.customer_id
),
cohort_activity AS (
    SELECT
        fo.customer_id,
        DATE_FORMAT(fo.first_order_date, '%Y-%m-01') AS cohort_month,  -- truncated to month
        EXISTS (
            SELECT 1
            FROM orders AS o2
            WHERE o2.customer_id = fo.customer_id
              AND o2.order_date >  fo.first_order_date
              AND o2.order_date <= fo.first_order_date + INTERVAL 30 DAY
        ) AS reordered_within_30_days
    FROM first_orders AS fo
)
SELECT
    ca.cohort_month,
    COUNT(*)                                                   AS cohort_size,
    SUM(ca.reordered_within_30_days)                            AS reordered_customers,
    ROUND(100 * SUM(ca.reordered_within_30_days) / COUNT(*), 1) AS reorder_rate_pct
FROM cohort_activity AS ca
GROUP BY ca.cohort_month
ORDER BY ca.cohort_month;

-- ENGINEERING NOTES
--   * DATE_FORMAT(first_order_date, '%Y-%m-01') truncates each
--     customer's signup date down to the first of their signup month
--     — this is the critical step that turns individual signup dates
--     into a small number of comparable cohort buckets. Grouping by
--     the raw first_order_date instead would produce one "cohort" per
--     calendar day, which is not a usable retention grid.
--   * This scenario intentionally stops at the single-window
--     (30-day) reorder rate per cohort — extending this into a full
--     multi-period retention grid (month 1, month 2, month 3...) is
--     the subject of the dedicated Cohort & Retention Analysis module
--     that follows this one.
