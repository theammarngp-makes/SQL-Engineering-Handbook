-- =====================================================================
-- MODULE      : 09_Date_Functions
-- TOPIC       : 04_DATE_FORMATTING
-- OBJECTIVE   : Convert dates to human-readable strings for reporting,
--               and parse external date strings into proper date types.
-- DIALECT     : MySQL 8.0 (PostgreSQL / SQL Server notes inline)
--
-- DATASET USED
-- -----------------------------------------------------------------------
-- employes         (emp_id, emp_name, hire_date, dept_id, salary, termination_date)
-- departments      (dept_id, dept_name)
-- vendor_import_raw (row_id, raw_hire_date_text)   -- simulates a messy CSV import
-- =====================================================================


-- =====================================================================
-- SCENARIO 1 — Reporting-friendly hire date display
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A quarterly HR report needs hire dates displayed in a fully
--   readable format for a non-technical audience, e.g. "July 07, 2026",
--   rather than the raw ISO storage format.
--
-- QUESTION
--   Display each employee's hire date as "<Month> <Day>, <Year>".
-- =====================================================================

SELECT
    e.emp_name,
    e.hire_date,                                    -- raw stored value, for reference
    DATE_FORMAT(e.hire_date, '%M %d, %Y') AS hire_date_display
FROM employes AS e
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * The original version of this query used the mask '%M/%d/%y',
--     mixing a full month name with a slash-separated numeric layout
--     and a two-digit year — an inconsistent, hard-to-read format.
--     This corrected version uses a clean, fully-worded mask suited
--     to human-facing reports.
--   * %Y (four-digit year) is used deliberately instead of %y
--     (two-digit year) to avoid any century ambiguity in the output.


-- =====================================================================
-- SCENARIO 2 — ISO-8601 export format for downstream systems
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A nightly export feeds an external payroll API that requires
--   dates in strict ISO-8601 format (YYYY-MM-DD).
--
-- QUESTION
--   Produce hire dates formatted as ISO-8601 strings for API export.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    DATE_FORMAT(e.hire_date, '%Y-%m-%d') AS hire_date_iso
FROM employes AS e
ORDER BY e.emp_id;

-- ENGINEERING NOTES
--   * ISO-8601 is the safest cross-system exchange format precisely
--     because it removes the MM/DD vs. DD/MM ambiguity that plagues
--     locale-specific formats.
--   * If the downstream system requires a full timestamp, extend the
--     mask: DATE_FORMAT(hire_timestamp, '%Y-%m-%dT%H:%i:%s').


-- =====================================================================
-- SCENARIO 3 — Custom DD-MM-YYYY format for a regional stakeholder
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A European regional office requests hire dates in DD-MM-YYYY
--   format for their local reporting standard.
--
-- QUESTION
--   Format hire_date as DD-MM-YYYY.
-- =====================================================================

SELECT
    e.emp_id,
    e.emp_name,
    DATE_FORMAT(e.hire_date, '%d-%m-%Y') AS hire_date_eu_format
FROM employes AS e
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * The original version of this query used '%d-%m-%y' (two-digit
--     year). This corrected version uses '%Y' to remove any
--     century-ambiguity risk in a report that may be archived and
--     reviewed years later.


-- =====================================================================
-- SCENARIO 4 — Parsing a messy vendor CSV import (String → Date)
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A third-party vendor's HR export loads hire dates as free-text
--   strings in the format 'DD-Mon-YYYY' (e.g., '07-Jul-2026') into a
--   staging table. These must be parsed into a real DATE type before
--   they can be loaded into the production employes table.
--
-- QUESTION
--   Parse the raw text hire dates in vendor_import_raw into proper
--   DATE values, and flag any rows that fail to parse.
-- =====================================================================

SELECT
    v.row_id,
    v.raw_hire_date_text,
    STR_TO_DATE(v.raw_hire_date_text, '%d-%b-%Y') AS parsed_hire_date,
    CASE
        WHEN STR_TO_DATE(v.raw_hire_date_text, '%d-%b-%Y') IS NULL
            THEN 'PARSE_FAILED'
        ELSE 'PARSE_OK'
    END AS parse_status
FROM vendor_import_raw AS v
ORDER BY parse_status DESC, v.row_id;

-- ENGINEERING NOTES
--   * STR_TO_DATE() returns NULL — not an error — when a string
--     doesn't match the supplied mask. The parse_status flag here is
--     a mandatory production safeguard: without it, malformed rows
--     silently become NULL hire dates with no visible trace of failure.
--   * If a single staging table mixes multiple source formats (e.g.,
--     one vendor sends 'DD-Mon-YYYY' and another sends 'MM/DD/YYYY'),
--     a single STR_TO_DATE() mask cannot correctly parse all rows —
--     each source format requires its own parsing pass, typically
--     segmented by a source_system column.


-- =====================================================================
-- SCENARIO 5 — CAST and CONVERT for straightforward type conversion
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   An analyst receives a well-formed ISO-8601 string column and
--   simply needs it treated as a real DATE for joining against the
--   employes table — no custom format mask is required.
--
-- QUESTION
--   Convert a clean ISO-formatted string to a native DATE using both
--   CAST() and CONVERT(), and compare the two approaches.
-- =====================================================================

SELECT
    CAST('2026-07-07' AS DATE)      AS cast_result,      -- ANSI-standard, portable
    CONVERT('2026-07-07', DATE)     AS convert_result     -- MySQL-specific syntax
;

-- ENGINEERING NOTES
--   * CAST() is ANSI-standard SQL and portable across MySQL,
--     PostgreSQL, and SQL Server — prefer it in code intended to be
--     dialect-portable.
--   * CONVERT() is MySQL-specific in this argument order; SQL Server's
--     CONVERT() uses a different argument order and an additional
--     style code parameter — never assume CONVERT() syntax is
--     identical across dialects.
--   * Both CAST() and CONVERT() only work reliably on already
--     well-formed, unambiguous date strings (like ISO-8601). For
--     non-standard layouts, STR_TO_DATE() with an explicit mask
--     (Scenario 4) is the correct and safer tool.


-- =====================================================================
-- SCENARIO 6 — Anti-pattern: filtering on a formatted string
-- -----------------------------------------------------------------------
-- BUSINESS CONTEXT
--   A dashboard filter for "employees hired in July 2026" was
--   originally written by formatting the column and comparing it to
--   a string. This scenario demonstrates the anti-pattern and its
--   sargable, production-grade fix.
--
-- QUESTION
--   Rewrite a formatted-string filter as a sargable date-range filter.
-- =====================================================================

-- ANTI-PATTERN (formats every row before comparing — disables indexes):
--   SELECT emp_name, hire_date
--   FROM employes
--   WHERE DATE_FORMAT(hire_date, '%Y-%m') = '2026-07';

-- CORRECT, SARGABLE VERSION:
SELECT
    e.emp_name,
    e.hire_date
FROM employes AS e
WHERE e.hire_date >= '2026-07-01'
  AND e.hire_date <  '2026-08-01'
ORDER BY e.hire_date;

-- ENGINEERING NOTES
--   * Formatting belongs at the presentation layer of a query
--     (SELECT), never inside a WHERE clause used to filter an indexed
--     column. This is the same sargability principle introduced in
--     01_CURRENT_DATE_FUNCTIONS.sql and 02_DATE_EXTRACTION.sql,
--     applied here specifically to string-formatted comparisons.
