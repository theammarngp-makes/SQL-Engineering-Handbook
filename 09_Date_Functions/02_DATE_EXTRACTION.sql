-- =====================================================================
-- MODULE      : 09_Date_Functions
-- TOPIC       : 02_DATE_EXTRACTION
-- OBJECTIVE   : Decompose date values into business-meaningful periods
--               (year, quarter, month, week, weekday) for grouping and
--               segmentation.
-- DIALECT     : MySQL 8.0 (PostgreSQL / SQL Server notes inline)
--
-- DATASET USED
-- -----------------------------------------------------------------------
-- employes    (emp_id, emp_name, hire_date, dept_id, salary, termination_date)
-- departments (dept_id, dept_name)
-- =====================================================================


-- =====================================================================
-- SCENARIO 1 — Hiring year, quarter, month, and weekday in one row
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Workforce planning wants a single reference view showing every
--   extracted component of each employee's hire date, to feed a
--   downstream BI tool without recomputing extractions repeatedly.
--
-- QUESTION
--   For every employee, show the hire year, quarter, month number,
--   month name, day of month, and weekday name of their hire date.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    e.hire_date,
    YEAR(e.hire_date)       AS hire_year,
    QUARTER(e.hire_date)    AS hire_quarter,
    MONTH(e.hire_date)      AS hire_month_number,
    MONTHNAME(e.hire_date)  AS hire_month_name,
    DAY(e.hire_date)        AS hire_day_of_month,
    DAYNAME(e.hire_date)    AS hire_weekday
FROM employes AS e
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * All extractions are computed once per row directly in SELECT —
--     this is the correct place for extraction functions; avoid the
--     same pattern inside WHERE against an indexed column (Scenario 6
--     demonstrates why).


-- =====================================================================
-- SCENARIO 2 — Employees hired in a specific calendar year (2023)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   HR wants a year-in-review report of everyone hired specifically
--   in 2023, for a hiring-cohort retrospective.
--
-- QUESTION
--   List employees hired in 2023, and separately, employees hired
--   after 2023.
-- =====================================================================

-- Hired in 2023 (SELECT-side extraction is fine here for a small,
-- ad-hoc report; see Scenario 6 for the sargable production version):
SELECT
    e.emp_name,
    e.hire_date
FROM employes AS e
WHERE YEAR(e.hire_date) = 2023
ORDER BY e.hire_date;

-- Hired after 2023:
SELECT
    e.emp_name,
    e.hire_date
FROM employes AS e
WHERE YEAR(e.hire_date) > 2023
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * These two queries are fine for small, infrequently run reports.
--     For a large, frequently queried employes table, rewrite using
--     the sargable pattern shown in Scenario 6.


-- =====================================================================
-- SCENARIO 3 — Multi-year monthly hiring trend (the classic pitfall)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Leadership wants a monthly hiring trend chart spanning multiple
--   years. A naive GROUP BY MONTH(hire_date) silently merges January
--   2023 hires with January 2024 hires into one bucket — this
--   scenario shows the wrong version and the correct fix.
--
-- QUESTION
--   Count employees hired in each (year, month) period, correctly
--   separated across years.
-- =====================================================================

-- ANTI-PATTERN (merges all years together — do not use):
--   SELECT MONTHNAME(hire_date) AS hire_month, COUNT(*) AS emp_count
--   FROM employes
--   GROUP BY hire_month;
--   -- January 2023 and January 2024 collapse into a single 'January' row.

-- CORRECT VERSION — group by year AND month:
SELECT
    YEAR(e.hire_date)       AS hire_year,
    MONTH(e.hire_date)      AS hire_month_number,
    MONTHNAME(e.hire_date)  AS hire_month_name,
    COUNT(*)                 AS employees_hired
FROM employes AS e
GROUP BY
    YEAR(e.hire_date),
    MONTH(e.hire_date),
    MONTHNAME(e.hire_date)
ORDER BY hire_year, hire_month_number;

-- ENGINEERING NOTES
--   * Always include YEAR() alongside any sub-year extraction in
--     GROUP BY when the dataset spans more than one year.
--   * MONTHNAME() is included in GROUP BY here purely for readability
--     in the output; MONTH() is the true grouping key that guarantees
--     correct ordering and correctness (month names sort alphabetically,
--     not chronologically, if used as the ORDER BY key alone).


-- =====================================================================
-- SCENARIO 4 — Headcount by year, ordered chronologically
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Finance wants total hires per year for a headcount growth chart.
--
-- QUESTION
--   Count employees hired in each year, ordered chronologically
--   (not by count).
-- =====================================================================

SELECT
    YEAR(e.hire_date)  AS hire_year,
    COUNT(*)            AS employees_hired
FROM employes AS e
GROUP BY YEAR(e.hire_date)
ORDER BY hire_year;                 -- chronological, not COUNT-based

-- ENGINEERING NOTES
--   * Ordering by the grouping key (hire_year) rather than the
--     aggregate (employees_hired) is the correct choice for a trend
--     chart — a chart's x-axis must be chronological regardless of
--     which year had the most hires.


-- =====================================================================
-- SCENARIO 5 — Employee tenure with department, using ISO week context
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   Workforce analytics wants each employee's department alongside
--   the ISO-8601 week number of their hire date, since the company's
--   reporting calendar aligns to ISO weeks, not MySQL's default week
--   numbering.
--
-- QUESTION
--   Show employee name, department name, and hire week using
--   ISO-8601 week semantics (mode 3 in MySQL's WEEK() function).
-- =====================================================================

SELECT
    e.emp_name,
    d.dept_name,
    e.hire_date,
    WEEK(e.hire_date, 3)  AS hire_iso_week   -- mode 3 = ISO-8601 weeks
FROM employes AS e
JOIN departments AS d
    ON e.dept_id = d.dept_id
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * MySQL's WEEK() function supports modes 0–7, controlling both the
--     first day of the week and how the first week of the year is
--     defined. Mode 3 matches the ISO-8601 standard used by most
--     international reporting calendars.
--   * ALWAYS pass the mode explicitly in production code — relying on
--     the server's default mode causes numbers to silently diverge
--     between environments with different configurations.
--   * PostgreSQL equivalent: EXTRACT(WEEK FROM hire_date) is ISO-8601
--     by default. SQL Server equivalent: DATEPART(ISO_WEEK, hire_date).


-- =====================================================================
-- SCENARIO 6 — Sargable year filter (production-safe rewrite of Scenario 2)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   The same "hired in 2023" report from Scenario 2 now needs to run
--   nightly against a much larger, indexed employes table. Wrapping
--   hire_date in YEAR() disables the index; this scenario shows the
--   sargable, production-grade rewrite.
--
-- QUESTION
--   Rewrite the "hired in 2023" filter so it remains index-friendly.
-- =====================================================================

SELECT
    e.emp_name,
    e.hire_date
FROM employes AS e
WHERE e.hire_date >= '2023-01-01'
  AND e.hire_date <  '2024-01-01'      -- half-open range: sargable
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * This is functionally identical to `WHERE YEAR(hire_date) = 2023`
--     but leaves the raw hire_date column untouched, allowing an index
--     on hire_date to be used for a range seek instead of a full scan.
--   * This is the single most common date-related performance fix
--     requested in SQL code review.
