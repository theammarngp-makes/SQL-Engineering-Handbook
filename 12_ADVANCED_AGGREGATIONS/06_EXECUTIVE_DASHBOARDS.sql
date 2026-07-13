-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   06 · EXECUTIVE DASHBOARDS
-- ============================================================================
-- Business Objective:
--   Produce clean, presentation-ready, dashboard-panel queries -- combining
--   multi-column grouping, conditional aggregation, and ROLLUP -- shaped for
--   direct consumption by a BI tool with no post-processing required.
--
-- Dataset Used (Healthcare domain):
--   departments (department_id PK, department_name)
--   providers   (provider_id PK, provider_name, department_id FK)
--   patients    (patient_id PK, patient_name)
--   visits      (visit_id PK, patient_id FK, provider_id FK, department_id FK,
--               visit_date, visit_type, wait_time_minutes)
--               -- visit_type IN ('SCHEDULED','SAME_DAY')
--
-- Dialect notes: CURRENT_DATE is supported identically in MySQL 8+ and
-- PostgreSQL. ROUND() and NULLIF() are used identically across both.
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 — Daily Visit Volume Panel
-- Business Context:
--   Hospital operations leadership opens a dashboard each morning showing
--   today's visit volume, average wait time, and same-day-visit share, by
--   department, with a hospital-wide total row.
--
-- Business Questions:
--   - How many visits has each department had today?
--   - What is the average patient wait time per department?
--   - What share of today's visits were same-day (unscheduled) visits?
-- ============================================================================

SELECT
    COALESCE(dept.department_name, 'All Departments')                  AS department,
    COUNT(v.visit_id)                                                    AS total_visits,
    ROUND(AVG(v.wait_time_minutes), 1)                                    AS avg_wait_minutes,
    ROUND(100.0 * COUNT(CASE WHEN v.visit_type = 'SAME_DAY' THEN 1 END)
          / NULLIF(COUNT(v.visit_id), 0), 1)                               AS same_day_pct,
    GROUPING(dept.department_name)                                          AS is_hospital_total
FROM visits      AS v
JOIN departments AS dept ON v.department_id = dept.department_id
WHERE v.visit_date = CURRENT_DATE
GROUP BY ROLLUP(dept.department_name)
ORDER BY is_hospital_total, department;

-- Explanation:
--   WHERE v.visit_date = CURRENT_DATE scopes the panel to today, filtering
--   before aggregation for efficiency. ROLLUP(department_name) adds the
--   hospital-wide total row in the same pass as the per-department detail.
--   COALESCE hands the BI tool a ready-to-render 'All Departments' string
--   instead of a bare NULL it would otherwise have to special-case.
--
-- Engineering Notes:
--   is_hospital_total is exposed explicitly so the dashboard's rendering
--   layer can bold or visually separate that row without re-deriving which
--   row is the total from the label text alone.
--
-- Optimization Notes:
--   Index visits(visit_date, department_id) so the date filter and the
--   department grouping/join are both served efficiently -- critical for a
--   panel refreshed frequently throughout an operational day.
--
-- Expected Output (illustrative):
--   department   | total_visits | avg_wait_minutes | same_day_pct | is_hospital_total
--   Cardiology    | 142           | 18.4                | 22.5           | 0
--   Emergency     | 310           | 41.2                | 88.1           | 0
--   Pediatrics    | 96            | 12.7                | 15.6           | 0
--   All Departments| 548           | 27.9               | 45.2           | 1


-- ============================================================================
-- SCENARIO 2 — Provider Staffing Panel
-- Business Context:
--   Operations wants to see, per department today, how many distinct
--   providers actually saw patients, alongside visit volume -- to spot
--   departments that are busy but understaffed relative to their volume.
--
-- Business Questions:
--   - How many distinct providers saw patients in each department today?
--   - What is the average number of visits per provider, per department?
-- ============================================================================

SELECT
    dept.department_name                                                AS department,
    COUNT(DISTINCT v.provider_id)                                        AS active_providers,
    COUNT(v.visit_id)                                                     AS total_visits,
    ROUND(COUNT(v.visit_id)
          / NULLIF(COUNT(DISTINCT v.provider_id), 0), 1)                   AS visits_per_provider
FROM visits      AS v
JOIN departments AS dept ON v.department_id = dept.department_id
WHERE v.visit_date = CURRENT_DATE
GROUP BY dept.department_name
ORDER BY visits_per_provider DESC;

-- Explanation:
--   COUNT(DISTINCT v.provider_id) counts unique providers, not visits --
--   a provider who saw ten patients today should count once toward
--   active_providers, but ten times toward total_visits. visits_per_provider
--   composes both metrics into a workload-per-provider ratio, a direct
--   staffing-adequacy signal for operations leadership.
--
-- Engineering Notes:
--   No ROLLUP is used here -- this panel intentionally shows only
--   per-department rows, since a hospital-wide "average visits per
--   provider" total would blend departments with very different visit
--   complexity and isn't a meaningful single number for this specific
--   panel's purpose.
--
-- Optimization Notes:
--   Index visits(visit_date, department_id, provider_id) to support the
--   date filter, department grouping, and distinct provider counting from
--   a single composite index.
--
-- Expected Output (illustrative):
--   department | active_providers | total_visits | visits_per_provider
--   Emergency   | 8                  | 310           | 38.8
--   Cardiology  | 6                  | 142           | 23.7


-- ============================================================================
-- SCENARIO 3 — Weekly Wait-Time Trend Panel
-- Business Context:
--   A separate dashboard panel tracks this week's average wait time by day,
--   as a trend line, kept independent from the daily snapshot panel above
--   so each panel can be refreshed and debugged on its own schedule.
--
-- Business Questions:
--   - What has average wait time looked like, day by day, this week?
--   - How many visits occurred each day, for context alongside the trend?
-- ============================================================================

SELECT
    v.visit_date,
    COUNT(v.visit_id)                                                     AS total_visits,
    ROUND(AVG(v.wait_time_minutes), 1)                                     AS avg_wait_minutes,
    CASE WHEN v.visit_date = CURRENT_DATE
         THEN TRUE ELSE FALSE END                                           AS is_partial_day
FROM visits AS v
WHERE v.visit_date >= CURRENT_DATE - INTERVAL '6 days'
GROUP BY v.visit_date
ORDER BY v.visit_date;

-- Explanation:
--   This panel is deliberately kept separate from Scenario 1's daily
--   snapshot -- different grain (per day, not per department), different
--   refresh cadence, and a different consumer question ("is wait time
--   trending up?" vs. "how are we doing right now?"). Combining the two
--   into one query would make both harder to maintain independently.
--   is_partial_day flags today's row so viewers don't misread a partial
--   day's average as a real day-over-day trend point.
--
-- Engineering Notes:
--   CURRENT_DATE - INTERVAL '6 days' gives a rolling 7-day window (today
--   plus six prior days) -- confirm with the dashboard designer whether
--   "this week" should mean a rolling window or a calendar week
--   (Monday-Sunday), since the two produce different results.
--
-- Optimization Notes:
--   Index visits(visit_date) alone is sufficient here, since this panel
--   does not join to departments or providers -- keep this query as narrow
--   as its one job requires.
--
-- Expected Output (illustrative):
--   visit_date | total_visits | avg_wait_minutes | is_partial_day
--   2026-07-05  | 501           | 26.4                | false
--   2026-07-06  | 489           | 28.1                | false
--   2026-07-11  | 214           | 24.0                | true
