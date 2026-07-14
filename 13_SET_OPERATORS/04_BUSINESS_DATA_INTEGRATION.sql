/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 04 — Business Data Integration
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Turn the source material's "combine into one report" queries into
   production-grade, discriminator-column-bearing integration queries, and
   extend into a realistic cross-region sales integration.

   AUDIT NOTES ON SOURCE QUERIES
   ------------------------------
   1. `employes` corrected to `employees` throughout.
   2. None of the original report queries included a discriminator column —
      every one is corrected below to add one, since a "combined report"
      without a source indicator is a known production anti-pattern
      (see 04_BUSINESS_DATA_INTEGRATION.md, Common Mistakes).
   3. Original Q3 used UNION ALL to combine "managers" and "all employees" —
      audited below: this is logically redundant (every manager is already
      included in "all employees"), and the corrected version demonstrates
      the fix directly.

   DATASET
   -------
   Reuses employees / departments / locations from Topic 01, and introduces:
     sales_us(order_id, order_total, order_date)
     sales_emea(order_id, order_total, order_date)
   ============================================================================ */

CREATE TABLE sales_us (
    order_id    INT PRIMARY KEY,
    order_total DECIMAL(10,2) NOT NULL,
    order_date  DATE NOT NULL
);

CREATE TABLE sales_emea (
    order_id    INT PRIMARY KEY,
    order_total DECIMAL(10,2) NOT NULL,
    order_date  DATE NOT NULL
);

INSERT INTO sales_us (order_id, order_total, order_date) VALUES
    (9001, 482.50, '2026-05-02'),
    (9002, 129.99, '2026-05-03'),
    (9003, 875.00, '2026-05-04');

INSERT INTO sales_emea (order_id, order_total, order_date) VALUES
    (7001, 340.00, '2026-05-02'),
    (7002, 998.20, '2026-05-05');


/* ----------------------------------------------------------------------------
   SCENARIO 1 — Unified personnel + department directory report (UNION ALL)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The company intranet needs one "everything" report listing every employee
   name and every department name, tagged so the page can render them in
   separate sections.

   BUSINESS QUESTION
   Produce one combined report of all employee names and department names.
   (Original Q1, corrected spelling, added discriminator column.)
---------------------------------------------------------------------------- */

SELECT
    emp_name    AS directory_name,
    'employee'  AS entity_type          -- Added: discriminator column
FROM employees

UNION ALL

SELECT
    dept_name   AS directory_name,
    'department' AS entity_type
FROM departments

ORDER BY entity_type, directory_name;

/*
EXPECTED OUTPUT (8 rows):
 directory_name   | entity_type
 -----------------|-------------
 Engineering      | department
 Finance          | department
 Sales            | department
 Aisha Bello      | employee
 Elena Petrova    | employee
 Marcus Johnson   | employee
 Ravi Kulkarni    | employee
 Wen Zhao         | employee

ENGINEERING NOTES
- The original query returned a single unlabeled column — functionally
  correct, but a report consumer would have no way to tell an employee name
  from a department name once combined. The entity_type column fixes this
  without changing the underlying logic.

OPTIMIZATION NOTES
- UNION ALL is correct: this is a directory listing, not a deduplication
  task, and adding the entity_type column means two genuinely different
  entities (an employee and a department) are never mistakenly collapsed
  even if their names happened to be textually identical.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 2 — Departments and cities combined report (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A one-page "where we operate" report needs department names and the
   cities the company has offices in, deduplicated, since this is a
   reference page, not an audit log.

   BUSINESS QUESTION
   Show all department names and city names in one combined, deduplicated
   report.
   (Original Q2 — UNION was already the correct choice here; formatting
   and aliasing corrected, discriminator column added for clarity.)
---------------------------------------------------------------------------- */

SELECT
    dept_name    AS place_or_dept,
    'department' AS entry_type
FROM departments

UNION

SELECT
    city         AS place_or_dept,
    'city'       AS entry_type
FROM locations

ORDER BY entry_type, place_or_dept;

/*
EXPECTED OUTPUT (6 rows):
 place_or_dept | entry_type
 --------------|------------
 Berlin        | city
 Chicago       | city
 Toronto       | city
 Engineering   | department
 Finance       | department
 Sales         | department

ENGINEERING NOTES
- UNION remains correct here (this is a reference page), but adding
  entry_type as part of the SELECT means UNION's deduplication now operates
  on the (name, type) pair — which is actually safer: a department and a
  city that happen to share a name will no longer be incorrectly collapsed
  into one ambiguous row, since their entry_type differs.

OPTIMIZATION NOTES
- Including entry_type in the UNION comparison technically makes true
  duplicates (same name AND same type) less likely, which is desirable for
  a reference page where every row should represent a distinct real entity.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 3 — Company directory: managers highlighted, then everyone (audited)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   HR wants a directory that lists managers first (for a leadership section)
   followed by the full staff list.

   BUSINESS QUESTION
   Produce a directory showing managers, then all employees.
   (Original Q3 — AUDIT FINDING: the original UNION ALL of "employees with
   NULL manager_id" and "all employees" is logically valid SQL, but based on
   the stated intent — "combine managers and employees into one directory" —
   it does not actually filter to managers; it filters to employees who have
   NO manager (i.e., top-level staff), which is a different business concept.
   Corrected below to reflect actual managers: employees who appear in
   someone else's manager_id.)
---------------------------------------------------------------------------- */

SELECT
    emp_name     AS directory_name,
    'manager'    AS directory_section
FROM employees
WHERE emp_id IN (
    SELECT DISTINCT manager_id
    FROM employees
    WHERE manager_id IS NOT NULL
)

UNION ALL

SELECT
    emp_name     AS directory_name,
    'all_staff'  AS directory_section
FROM employees

ORDER BY directory_section DESC, directory_name;

/*
EXPECTED OUTPUT:
 directory_name   | directory_section
 ------------------|-------------------
 Aisha Bello       | all_staff
 Elena Petrova     | all_staff
 Marcus Johnson    | all_staff
 Ravi Kulkarni     | all_staff
 Wen Zhao          | all_staff
 Marcus Johnson    | manager
 Ravi Kulkarni     | manager

ENGINEERING NOTES
- UNION ALL is intentional here: managers are DELIBERATELY duplicated —
  once in the "manager" section, once again in "all_staff" — because this
  is a display/report requirement (a leadership callout section), not a
  deduplication problem. This is the clearest example in the module of
  UNION ALL being correct specifically because duplication is the intent.

OPTIMIZATION NOTES
- The IN (subquery) filter for "is a manager" mirrors the INTERSECT logic
  taught in 03_INTERSECT_AND_EXCEPT.md — this is a deliberate cross-reference
  showing the same business concept solved with a different tool.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 4 — All company-wide IDs, tagged by source (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   IT's new unified ID scheme needs every existing ID (employee and
   department) listed once, tagged with its origin, to plan non-colliding
   ranges for future IDs.

   BUSINESS QUESTION
   Show all IDs used in the company, tagged by whether they're an employee
   ID or a department ID.
   (Original Q4, corrected spelling, added discriminator column.)
---------------------------------------------------------------------------- */

SELECT
    emp_id    AS company_id,
    'employee' AS id_source
FROM employees

UNION

SELECT
    dept_id   AS company_id,
    'department' AS id_source
FROM departments

ORDER BY company_id;

/*
EXPECTED OUTPUT (8 rows, ordered by ID):
 company_id | id_source
 -----------|-----------
 10         | department
 20         | department
 30         | department
 1001       | employee
 1002       | employee
 1003       | employee
 1004       | employee
 1005       | employee

ENGINEERING NOTES
- Because id_source is now part of the row, UNION's deduplication would only
  collapse a row if BOTH the ID and the source matched — which, given IDs
  are unique within each table, means this UNION can never actually remove
  a row in practice. It is retained instead of UNION ALL purely as defensive
  documentation of intent ("this is a reference list, treat it as such").

OPTIMIZATION NOTES
- Since deduplication is a no-op here, UNION ALL would be marginally cheaper
  with identical results — a good example of choosing the operator that
  documents intent even when the performance difference is negligible at
  this scale.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 5 — Cross-region sales integration report (UNION ALL)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Leadership wants one global sales feed combining the US and EMEA regional
   order tables for a unified revenue dashboard.

   BUSINESS QUESTION
   Show every order from both regions in one report, tagged by region.
---------------------------------------------------------------------------- */

SELECT
    order_id,
    order_total,
    order_date,
    'US'   AS region
FROM sales_us

UNION ALL

SELECT
    order_id,
    order_total,
    order_date,
    'EMEA' AS region
FROM sales_emea

ORDER BY order_date, region;

/*
EXPECTED OUTPUT (5 rows):
 order_id | order_total | order_date | region
 ---------|-------------|------------|--------
 9001     | 482.50      | 2026-05-02 | US
 7001     | 340.00      | 2026-05-02 | EMEA
 9002     | 129.99      | 2026-05-03 | US
 9003     | 875.00      | 2026-05-04 | US
 7002     | 998.20      | 2026-05-05 | EMEA

ENGINEERING NOTES
- UNION ALL is correct and required: order_id ranges for US (9xxx) and EMEA
  (7xxx) don't overlap, and even if they did, an order from two different
  regional systems is never a true duplicate — it's two distinct business
  events.
- The region column is the discriminator that makes this query safe to hand
  directly to a dashboard tool for regional breakdowns and filters.

OPTIMIZATION NOTES
- For a frequently-refreshed dashboard, this pattern is a strong candidate
  for a materialized view or a scheduled table (e.g., `global_sales`)
  rather than recomputing the UNION ALL on every dashboard load.
*/
