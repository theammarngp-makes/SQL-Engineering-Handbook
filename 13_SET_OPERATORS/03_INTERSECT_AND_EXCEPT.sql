/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 03 — INTERSECT and EXCEPT
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Formalize the INTERSECT/EXCEPT simulation the source material sketched
   only as a comment, using employees/departments, then extend into a
   realistic customer-overlap and migration-gap scenario.

   AUDIT NOTE ON SOURCE MATERIAL
   ------------------------------
   The original source contained only a comment describing INTERSECT and
   EXCEPT conceptually, with no working query, and noted (correctly) that
   MySQL historically lacked support. This file replaces that comment with
   full native syntax, a portable EXISTS/NOT EXISTS simulation, and realistic
   business scenarios.

   DATASET
   -------
   Reuses employees / departments from Topic 01, and introduces:
     crm_customers(customer_id, customer_name, signup_date)
     erp_customers(customer_id, customer_name, region)
   ============================================================================ */

CREATE TABLE crm_customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    signup_date   DATE
);

CREATE TABLE erp_customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    region        VARCHAR(50)
);

INSERT INTO crm_customers (customer_id, customer_name, signup_date) VALUES
    (501, 'Northwind Traders',  '2022-04-11'),
    (502, 'Blue Harbor Foods',  '2023-01-19'),
    (503, 'Solstice Analytics', '2023-08-02'),
    (504, 'Pinehill Logistics', '2024-02-27');

INSERT INTO erp_customers (customer_id, customer_name, region) VALUES
    (501, 'Northwind Traders',  'Midwest'),
    (502, 'Blue Harbor Foods',  'Northeast'),
    (505, 'Cedar Ridge Supply', 'South');
    -- Note: 503 and 504 exist only in CRM; 505 exists only in ERP —
    -- this asymmetry is intentional, to demonstrate directional EXCEPT.


/* ----------------------------------------------------------------------------
   SCENARIO 1 — Employees who are also managers (INTERSECT)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   HR wants a list of employees who manage at least one other person, to
   assign management-training enrollment.

   BUSINESS QUESTION
   Which employee IDs also appear as a manager_id elsewhere in the table?
---------------------------------------------------------------------------- */

SELECT emp_id AS manager_employee_id
FROM employees

INTERSECT

SELECT manager_id AS manager_employee_id
FROM employees
WHERE manager_id IS NOT NULL;

/*
EXPECTED OUTPUT:
 manager_employee_id
 --------------------
 1001
 1003

ENGINEERING NOTES
- INTERSECT here directly answers "who is in both the employee list and the
  manager list" — exactly the business question, with no JOIN required.

OPTIMIZATION NOTES
- Equivalent EXISTS-based rewrite (Scenario 2) often outperforms this on
  large tables because it can use an index seek per row instead of a full
  set comparison.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 2 — Same question, simulated with EXISTS (portable to any MySQL)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The same HR check, running on a MySQL version prior to 8.0.31, where
   INTERSECT is unavailable.

   BUSINESS QUESTION
   Same as Scenario 1, expressed without native INTERSECT support.
---------------------------------------------------------------------------- */

SELECT DISTINCT e.emp_id AS manager_employee_id
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM employees m
    WHERE m.manager_id = e.emp_id
);

/*
EXPECTED OUTPUT: identical to Scenario 1 — 1001, 1003

ENGINEERING NOTES
- SELECT DISTINCT is required here because INTERSECT de-duplicates
  automatically, but EXISTS does not — without DISTINCT, an employee who
  manages three people would appear... actually only once here, since EXISTS
  only checks for existence, not count; DISTINCT is a defensive habit in
  case the underlying query is later changed to a JOIN, which would
  duplicate per match.

OPTIMIZATION NOTES
- With an index on employees(manager_id), this EXISTS form allows an index
  seek per outer row rather than materializing and comparing two full sets —
  typically the faster choice at scale.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 3 — Customer migration reconciliation: matched customers (INTERSECT)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The company is retiring its legacy CRM in favor of the ERP system's
   built-in customer registry. Before decommissioning the CRM, the migration
   team must confirm which customers successfully exist in both systems.

   BUSINESS QUESTION
   Which customer_ids exist in both the CRM and the ERP?
---------------------------------------------------------------------------- */

SELECT customer_id
FROM crm_customers

INTERSECT

SELECT customer_id
FROM erp_customers

ORDER BY customer_id;

/*
EXPECTED OUTPUT:
 customer_id
 -----------
 501
 502

ENGINEERING NOTES
- Only customer_id is selected (not customer_name) deliberately: comparing
  on the full row would fail to match 501/502 if, say, name formatting
  differs slightly between systems (a very common real-world migration
  problem). Compare on the stable business key, not on descriptive columns.

OPTIMIZATION NOTES
- Selecting the minimum necessary columns for the comparison keeps the
  de-duplication/sort step as cheap as possible.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 4 — Migration gap detection, both directions (EXCEPT)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The migration is only considered complete when nothing is missing in
   either direction. This is the actual audit query that gates the CRM
   decommission decision.

   BUSINESS QUESTION
   Which customers exist in the CRM but not the ERP, and vice versa?
---------------------------------------------------------------------------- */

-- Direction 1: in CRM, missing from ERP — migration gap requiring action
SELECT customer_id
FROM crm_customers

EXCEPT                              -- Oracle: replace EXCEPT with MINUS

SELECT customer_id
FROM erp_customers

ORDER BY customer_id;

-- Direction 2: in ERP, missing from CRM — likely a customer created
-- directly in the new system, not a migration failure, but still worth
-- confirming with the business owner
SELECT customer_id
FROM erp_customers

EXCEPT

SELECT customer_id
FROM crm_customers

ORDER BY customer_id;

/*
EXPECTED OUTPUT
Direction 1 (CRM − ERP): 503, 504   → these two customers did NOT migrate
Direction 2 (ERP − CRM): 505        → this customer exists only in ERP

ENGINEERING NOTES
- Neither query alone proves the migration status; both are required. A
  migration is only "clean" when Direction 1 returns zero rows — Direction 2
  returning rows may be entirely expected (new customers created after
  migration began) and is a separate business conversation, not necessarily
  a defect.

OPTIMIZATION NOTES
- In a recurring reconciliation job, wrap Direction 1 as an automated test
  asserting zero rows; treat any non-zero result as a pipeline failure that
  pages the data engineering on-call.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 5 — EXCEPT simulated with NOT EXISTS (portable, NULL-safe)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The same migration-gap check (Direction 1), rewritten for a database or
   review process that prefers explicit joins over set operators, and to
   demonstrate the NULL-safety advantage over NOT IN.

   BUSINESS QUESTION
   Same as Scenario 4, Direction 1, without using EXCEPT/MINUS.
---------------------------------------------------------------------------- */

SELECT c.customer_id
FROM crm_customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM erp_customers e
    WHERE e.customer_id = c.customer_id
)
ORDER BY c.customer_id;

/*
EXPECTED OUTPUT: identical to Scenario 4, Direction 1 — 503, 504

ENGINEERING NOTES
- NOT EXISTS is preferred over `WHERE customer_id NOT IN (SELECT customer_id
  FROM erp_customers)`. If erp_customers.customer_id ever contained a NULL
  (e.g., from a bad load), NOT IN would return zero rows for the ENTIRE
  query — silently hiding every real migration gap. NOT EXISTS has no such
  failure mode.

OPTIMIZATION NOTES
- With an index on erp_customers(customer_id), this form performs an index
  seek per CRM row — typically fast even at large scale, and often easier
  for a query optimizer to plan efficiently than a native EXCEPT across two
  large tables.
*/
