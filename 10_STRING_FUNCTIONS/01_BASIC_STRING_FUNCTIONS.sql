-- ============================================================
-- Module      : 10_STRING_FUNCTIONS
-- Topic       : 01_BASIC_STRING_FUNCTIONS
-- Objective   : Apply measurement, case conversion, slicing,
--               assembly, trimming, and positional search to
--               real HR reporting and identity-generation problems.
-- Dialect     : ANSI SQL, verified against PostgreSQL and MySQL 8+
-- Dataset     : employees, departments
-- ============================================================

-- ------------------------------------------------------------
-- Reference schema (for context only — do not re-run if tables
-- already exist in your practice environment)
-- ------------------------------------------------------------
-- employees   (emp_id INT PK, emp_name VARCHAR(100), dept_id INT FK)
-- departments (dept_id INT PK, dept_name VARCHAR(100))


-- ============================================================
-- SCENARIO 1 — Standardizing employee name casing for reporting
-- ============================================================
-- Business Context:
--   Payroll exports and executive dashboards require employee
--   names in a single, predictable case. Source data is entered
--   by multiple regional HR teams and arrives inconsistently
--   cased (Mixed Case, ALL CAPS, all lowercase).

-- Question: Produce employee names normalized to uppercase, for
--           use on printed payroll reports.
SELECT
    emp_name                          AS original_name,
    UPPER(emp_name)                   AS report_name_upper
FROM employees;

-- Question: Produce employee names normalized to lowercase, for
--           use as a case-insensitive comparison key downstream.
SELECT
    emp_name                          AS original_name,
    LOWER(emp_name)                   AS normalized_key
FROM employees;

-- Engineering Notes:
--   Case normalization is typically needed twice: once for
--   *display* (usually UPPER for printed/legal documents, or
--   Proper Case via application logic) and once for *matching*
--   (usually LOWER, used as a join/comparison key). Never rely
--   on the raw column for equality comparisons across systems
--   that may have entered data with different casing conventions.
--
-- Performance Notes:
--   UPPER()/LOWER() are cheap per-row operations. The real cost
--   appears if either is applied inside a WHERE clause on a large
--   table — see Topic 04 for indexing strategies around
--   case-insensitive lookups.
--
-- Expected Output (sample):
--   original_name   | report_name_upper | normalized_key
--   Sarah Connor     | SARAH CONNOR      | sarah connor
--   JOHN smith       | JOHN SMITH        | john smith


-- ============================================================
-- SCENARIO 2 — Auditing name field length for data quality
-- ============================================================
-- Business Context:
--   The HR system enforces a 50-character limit on emp_name at
--   the application layer, but historical migrated records were
--   never validated against that rule. Before a planned schema
--   change tightens the column to VARCHAR(50), data quality needs
--   to identify any existing violations.

-- Question: List each employee name with its character length,
--           for use in a pre-migration audit.
SELECT
    emp_name,
    CHAR_LENGTH(emp_name)             AS name_char_length
FROM employees
ORDER BY name_char_length DESC;

-- Engineering Notes:
--   CHAR_LENGTH() is used here instead of LENGTH() deliberately.
--   LENGTH() returns byte length, which overstates true character
--   count for any name containing accented or non-Latin
--   characters (e.g., "José", "Müller") — exactly the kind of
--   name likely to appear in an HR system with global staff.
--   Using LENGTH() here would generate false-positive migration
--   failures for valid names.
--
-- Performance Notes:
--   Negligible per-row cost; the ORDER BY on a computed column
--   forces a full scan and sort, which is expected and acceptable
--   for a one-time audit query but should not be run repeatedly
--   against a large live table without a LIMIT.
--
-- Expected Output (sample):
--   emp_name          | name_char_length
--   Alexandra Whitfield| 19
--   Sarah Connor        | 12
--   Wu Li                | 5


-- ============================================================
-- SCENARIO 3 — Deriving name-prefix codes for badge printing
-- ============================================================
-- Business Context:
--   The facilities team prints physical access badges showing a
--   3-letter name prefix (for quick visual matching at security
--   desks) and a 2-letter suffix (used internally as a legacy
--   printer-batch code inherited from the old badge system).

-- Question: Show each employee's first 3 letters of their name.
SELECT
    emp_name,
    LEFT(emp_name, 3)                 AS badge_prefix
FROM employees;

-- Question: Show each employee's last 2 letters of their name.
SELECT
    emp_name,
    RIGHT(emp_name, 2)                AS badge_suffix_legacy
FROM employees;

-- Engineering Notes:
--   LEFT()/RIGHT() with a fixed length is safe here only because
--   badge_prefix/suffix are cosmetic and collisions are acceptable
--   (multiple employees can share a badge_prefix; the badge's
--   actual unique identifier is emp_id, encoded separately as a
--   barcode). This pattern should NOT be used to derive anything
--   that must be unique — see Scenario 5.
--
-- Performance Notes:
--   Fixed-length slicing is one of the cheapest string operations
--   available; no indexing concerns at any realistic table size.
--
-- Expected Output (sample):
--   emp_name       | badge_prefix
--   Sarah Connor    | Sar
--   JOHN smith       | JOH


-- ============================================================
-- SCENARIO 4 — Cross-referencing employees with their department
-- ============================================================
-- Business Context:
--   The internal directory tool displays a single human-readable
--   sentence per employee row rather than separate name/department
--   columns, matching the UX pattern used in the company's Slack
--   directory bot.

-- Question: Produce a single descriptive sentence combining each
--           employee's name and department.
SELECT
    e.emp_name,
    d.dept_name,
    CONCAT(e.emp_name, ' works in the ', d.dept_name, ' department') AS directory_entry
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id;

-- Engineering Notes:
--   A JOIN is required here (not a subquery) because dept_name
--   lives in a normalized departments table, not on employees
--   directly. Note the alias discipline: e/d prefixes make the
--   join condition self-documenting even as the query grows.
--   CONCAT() is safe here specifically because dept_id is
--   enforced NOT NULL with a foreign key — if department
--   assignment were optional, this query would need CONCAT_WS()
--   or a LEFT JOIN plus COALESCE() to avoid silently dropping
--   unassigned employees from the concatenated output (it wouldn't
--   drop rows, but directory_entry would render NULL for them).
--
-- Performance Notes:
--   The JOIN cost dominates here, not the CONCAT(). Ensure
--   dept_id is indexed on both tables (typically enforced
--   automatically via the PK/FK constraints) so the join uses an
--   index lookup rather than a full scan on departments.
--
-- Expected Output (sample):
--   emp_name       | dept_name  | directory_entry
--   Sarah Connor    | Engineering| Sarah Connor works in the Engineering department


-- ============================================================
-- SCENARIO 5 — Cleaning whitespace before storage-key comparisons
-- ============================================================
-- Business Context:
--   A nightly reconciliation job compares emp_name between the
--   HR system and the payroll vendor's export. Mismatches have
--   been traced to invisible leading/trailing spaces introduced
--   by the payroll vendor's CSV export process.

-- Question: Produce a whitespace-trimmed version of emp_name
--           suitable for use as a reconciliation comparison key.
SELECT
    emp_name,
    TRIM(emp_name)                    AS reconciliation_key
FROM employees;

-- Engineering Notes:
--   TRIM() with no arguments removes leading AND trailing
--   whitespace, which is the correct default here — internal
--   spaces (e.g., "Sarah  Connor" with a double space) are a
--   separate data-quality issue and are NOT addressed by TRIM()
--   alone; that requires REPLACE()-based collapsing, covered in
--   Topic 03.
--
-- Performance Notes:
--   Cheap per-row. If this comparison key is used repeatedly
--   (e.g., in a nightly job join), consider persisting a
--   normalized column via a generated/computed column rather
--   than recomputing TRIM() on every run.
--
-- Expected Output (sample):
--   emp_name        | reconciliation_key
--   " Sarah Connor " | "Sarah Connor"


-- ============================================================
-- SCENARIO 6 — Locating a character for a legacy validation rule
-- ============================================================
-- Business Context:
--   A legacy naming-convention audit (inherited from a prior data
--   governance initiative) flags names containing the letter "a"
--   for manual review, as part of a now-informal check against a
--   discontinued naming taxonomy. The rule is preserved here only
--   because downstream reports still reference its output column.

-- Question: Return the position of the first occurrence of the
--           letter 'a' within each employee name.
SELECT
    emp_name,
    LOCATE('a', emp_name)             AS first_a_position
FROM employees;

-- Engineering Notes:
--   LOCATE() returns 0 (not NULL) when no match is found, which
--   is a common source of bugs when the result is later used in
--   a CASE expression or WHERE filter — 0 must be handled
--   explicitly, since `first_a_position = 0` and
--   `first_a_position IS NULL` are different conditions and only
--   one of them will ever be true here.
--   Whether this match is case-sensitive depends entirely on the
--   column's collation, not on LOCATE() itself — verify collation
--   before relying on this for a case-sensitive business rule.
--
-- Performance Notes:
--   LOCATE() cannot use a standard index for a WHERE filter
--   (e.g. WHERE LOCATE('a', emp_name) > 0), since it must inspect
--   every row's full string value. For simple substring existence
--   checks, prefer `emp_name LIKE '%a%'` for query-planner
--   clarity, and see Topic 02 for indexed alternatives on large
--   tables.
--
-- Expected Output (sample):
--   emp_name       | first_a_position
--   Sarah Connor    | 1
--   JOHN smith       | 0


-- ============================================================
-- SCENARIO 7 — Generating unique employee login usernames
-- ============================================================
-- Business Context:
--   IT provisioning needs a deterministic, script-generatable
--   username for new-hire account creation: first 3 letters of
--   the employee's name, uppercased, followed by their employee
--   ID to guarantee uniqueness even when multiple employees share
--   the same first three letters.

-- Question: Generate the standardized username for every employee.
SELECT
    emp_name,
    emp_id,
    CONCAT(UPPER(LEFT(emp_name, 3)), emp_id) AS username
FROM employees;

-- Engineering Notes:
--   This is the pattern Scenario 3 explicitly warned against
--   using for anything requiring uniqueness — resolved correctly
--   here by anchoring the derived value to emp_id, which is
--   guaranteed unique by the primary key constraint. UPPER() is
--   applied to guarantee consistent output regardless of source
--   name casing, which matters because usernames are frequently
--   used in case-sensitive authentication systems.
--
-- Performance Notes:
--   Trivial per-row cost. If usernames are queried frequently
--   (e.g., login lookups), this value should be materialized as
--   a stored/generated column with its own index rather than
--   recomputed on every authentication request.
--
-- Expected Output (sample):
--   emp_name       | emp_id | username
--   Sarah Connor    | 1042   | SAR1042
--   JOHN smith       | 1043   | JOH1043
-- ============================================================
