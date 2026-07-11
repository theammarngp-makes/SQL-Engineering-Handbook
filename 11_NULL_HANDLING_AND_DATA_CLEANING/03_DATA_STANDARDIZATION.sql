-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 03 - Data Standardization
-- OBJECTIVE   : Clean and normalize free-text data using TRIM,
--               REPLACE, UPPER, and LOWER against realistic
--               customer and employee data.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- DATASET     : employees (see 01_INTRODUCTION_TO_NULLS.sql)
--               customers (created below)
-- ============================================================

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id     INT PRIMARY KEY,
    customer_name   VARCHAR(100),
    email           VARCHAR(150),
    city            VARCHAR(100)
);

INSERT INTO customers (customer_id, customer_name, email, city) VALUES
(1, '  Ananya Gupta',       'Ananya.Gupta@MAIL.com',   'Mumbai'),
(2, 'ROHAN verma',          'rohan.verma@mail.com',    'mumbai '),
(3, 'John  Smith',          'JOHNSMITH@mail.com',      'MUMBAI'),
(4, 'lakshmi Pillai ',      'lakshmi.pillai@mail.com', 'Chennai'),
(5, 'Carlos   Diaz',        'carlos.diaz@mail.com',    'chennai');

-- ------------------------------------------------------------
-- SCENARIO 1
-- Business Context:
--   A regional sales report is showing five separate "cities"
--   for what should be two: Mumbai and Chennai. Leading/trailing
--   whitespace and inconsistent casing are fragmenting the group.
-- Question: Remove leading/trailing whitespace from employee
--           names using TRIM().
-- ------------------------------------------------------------

SELECT
    emp_id,
    TRIM(emp_name) AS clean_emp_name
FROM
    employees;

-- Engineering Notes:
--   TRIM() only strips leading and trailing whitespace — it will
--   NOT fix internal double spaces (see Scenario 5 in this file
--   for that case). This distinction is a common source of
--   confusion and should be called out explicitly in code review.
-- Expected Output:
--   8 rows with any accidental leading/trailing whitespace removed;
--   internal spacing (if any) unchanged.

-- ------------------------------------------------------------
-- SCENARIO 2
-- Business Context:
--   A support ticket references a customer by a slightly
--   different spelling than what's on file. The team wants to
--   demonstrate REPLACE() for controlled substring substitution,
--   using a masked-name example rather than an arbitrary letter
--   swap.
-- Question: Standardize a legacy "Mgr." prefix in employee names
--           by removing it, using REPLACE().
-- ------------------------------------------------------------

-- Demonstration data note: assume some emp_name values were
-- migrated from a legacy system with a "Mgr. " prefix baked in.
-- REPLACE() removes the prefix in a single pass:

SELECT
    emp_id,
    REPLACE(emp_name, 'Mgr. ', '') AS clean_emp_name
FROM
    employees;

-- Engineering Notes:
--   The original version of this exercise replaced the letter
--   'a' with '@' — a syntactically valid REPLACE() call, but not
--   a realistic data cleaning operation (it would corrupt any
--   name containing the letter 'a', which is most names). REPLACE
--   should target a specific, known problem substring — a prefix,
--   a formatting artifact, or a double space — not an arbitrary
--   single character.
-- Expected Output:
--   8 rows; unchanged here since no emp_name in this dataset
--   contains the "Mgr. " prefix, but the query is safe to run
--   against data that does.

-- ------------------------------------------------------------
-- SCENARIO 3
-- Business Context:
--   Marketing needs employee names in a consistent uppercase
--   format for printed name badges.
-- Question: Convert employee names to uppercase.
-- ------------------------------------------------------------

SELECT
    emp_id,
    UPPER(TRIM(emp_name)) AS badge_name
FROM
    employees;

-- Engineering Notes:
--   TRIM() is applied before UPPER() so that any accidental
--   whitespace doesn't survive into the final badge text.
--   Ordering matters less here for correctness (UPPER and TRIM
--   don't interfere with each other) but combining them in one
--   pass is more efficient than two separate queries.
-- Expected Output:
--   8 rows, e.g., "ANITA RAO", "RAHUL MEHTA".

-- ------------------------------------------------------------
-- SCENARIO 4
-- Business Context:
--   An internal system requires lowercase, whitespace-trimmed
--   emails as unique lookup keys for customer matching across
--   the CRM and the billing system.
-- Question: Standardize customer emails to a consistent
--           lowercase, trimmed format.
-- ------------------------------------------------------------

SELECT
    customer_id,
    customer_name,
    LOWER(TRIM(email)) AS standardized_email
FROM
    customers;

-- Engineering Notes:
--   This is the canonical pattern for matching keys across
--   systems: TRIM removes accidental whitespace, LOWER removes
--   casing inconsistency. Applying both consistently at every
--   point emails are compared prevents "the same customer,
--   twice" bugs in joins and deduplication.
-- Expected Output:
--   5 rows; all emails lowercase and trimmed,
--   e.g., "ananya.gupta@mail.com".

-- ------------------------------------------------------------
-- SCENARIO 5
-- Business Context:
--   A data quality audit found that TRIM() alone did not fully
--   clean a customer_name column — some names still have
--   internal double spaces left over from a bad CSV import.
-- Question: Generate fully standardized customer names:
--           trimmed, single-spaced internally, and properly
--           cased for display.
-- ------------------------------------------------------------

SELECT
    customer_id,
    TRIM(REPLACE(REPLACE(customer_name, '   ', ' '), '  ', ' ')) AS clean_display_name,
    LOWER(TRIM(REPLACE(REPLACE(customer_name, '   ', ' '), '  ', ' '))) AS clean_comparison_name
FROM
    customers;

-- Engineering Notes:
--   TRIM alone leaves internal double/triple spaces untouched
--   (e.g., "Carlos   Diaz" stays "Carlos   Diaz" after TRIM).
--   Chaining REPLACE() calls collapses triple spaces down to
--   single spaces in two passes: first collapsing runs of three
--   spaces, then any remaining runs of two. MySQL 8 also supports
--   REGEXP_REPLACE(customer_name, ' +', ' ') as a single-step
--   alternative for arbitrary-length whitespace runs.
--   clean_comparison_name is provided separately from
--   clean_display_name because comparison keys should be
--   lowercase, while display names typically should preserve
--   proper casing for the end user.
-- Optimization Notes:
--   Chained REPLACE() calls on every row of a large table are
--   CPU-bound but not index-usable — for very large customer
--   tables, this cleanup is better done once during ETL load
--   and stored, rather than recomputed on every query.
-- Expected Output:
--   5 rows; e.g., "Carlos   Diaz" becomes clean_display_name
--   "Carlos Diaz" and clean_comparison_name "carlos diaz".

-- ------------------------------------------------------------
-- SCENARIO 6
-- Business Context:
--   Customer support wants a clean login-style username for
--   each employee: first 3 letters of their name (uppercase)
--   plus their employee ID, with no unintended separator.
-- Question: Generate usernames as first 3 letters + emp_id.
-- ------------------------------------------------------------

SELECT
    emp_id,
    emp_name,
    CONCAT(UPPER(LEFT(TRIM(emp_name), 3)), emp_id) AS username
FROM
    employees;

-- Engineering Notes:
--   The original version of this exercise included an empty
--   string ('') as a middle argument to CONCAT(), which does
--   nothing and should be removed rather than left as dead code.
--   TRIM() is applied before LEFT() so that any leading
--   whitespace doesn't end up inside the first three characters
--   used for the username. UPPER() makes the username case
--   convention explicit and consistent rather than depending on
--   however the name happened to be entered.
-- Expected Output:
--   8 rows, e.g., emp_id 1 "Anita Rao" -> username "ANI1".
