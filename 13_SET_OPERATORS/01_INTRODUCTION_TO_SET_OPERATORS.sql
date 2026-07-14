/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 01 — Introduction to Set Operators
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Establish the foundational schema used across this entire module and
   demonstrate the first correct, production-style UNION query — combining
   two structurally identical single-column result sets into one report.

   DATASET
   -------
   departments(dept_id, dept_name, location_id, budget)
   locations(location_id, city, country)
   employees(emp_id, emp_name, manager_id, dept_id, hire_date, salary, email)
   ============================================================================ */

CREATE TABLE departments (
    dept_id     INT PRIMARY KEY,
    dept_name   VARCHAR(100) NOT NULL,
    location_id INT,
    budget      DECIMAL(12,2)
);

CREATE TABLE locations (
    location_id INT PRIMARY KEY,
    city        VARCHAR(100) NOT NULL,
    country     VARCHAR(100) NOT NULL
);

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    emp_name    VARCHAR(100) NOT NULL,
    manager_id  INT,
    dept_id     INT,
    hire_date   DATE,
    salary      DECIMAL(10,2),
    email       VARCHAR(150)
);

INSERT INTO locations (location_id, city, country) VALUES
    (1, 'Chicago', 'USA'),
    (2, 'Toronto', 'Canada'),
    (3, 'Berlin',  'Germany');

INSERT INTO departments (dept_id, dept_name, location_id, budget) VALUES
    (10, 'Engineering', 1, 2500000.00),
    (20, 'Sales',       2,  900000.00),
    (30, 'Finance',     3, 1200000.00);

INSERT INTO employees (emp_id, emp_name, manager_id, dept_id, hire_date, salary, email) VALUES
    (1001, 'Ravi Kulkarni',  NULL, 10, '2019-03-01', 145000.00, 'ravi.k@company.com'),
    (1002, 'Elena Petrova',  1001, 10, '2020-06-15', 118000.00, 'elena.p@company.com'),
    (1003, 'Marcus Johnson', NULL, 20, '2018-11-20',  98000.00, 'marcus.j@company.com'),
    (1004, 'Aisha Bello',    1003, 20, '2021-01-10',  76000.00, 'aisha.b@company.com'),
    (1005, 'Wen Zhao',       NULL, 30, '2017-09-05', 132000.00, 'wen.z@company.com');


/* ----------------------------------------------------------------------------
   SCENARIO 1 — One combined list of every place name the business references
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Leadership wants a single reference list of every named entity in the org
   chart — department names and office cities — for a company directory page.

   BUSINESS QUESTION
   What are all the distinct "place names" (departments and cities) the
   business currently operates?
---------------------------------------------------------------------------- */

SELECT
    dept_name AS place_name          -- Column name is set by the FIRST branch
FROM departments

UNION                                -- De-duplicates: correct here, since a
                                      -- department name and a city name being
                                      -- accidentally identical should collapse
SELECT
    city AS place_name
FROM locations

ORDER BY place_name;                 -- ORDER BY applies once, to the final set

/*
EXPECTED OUTPUT (6 rows, alphabetical):
 place_name
 -----------
 Berlin
 Chicago
 Engineering
 Finance
 Sales
 Toronto

ENGINEERING NOTES
- Both branches return exactly one column of type VARCHAR — column count and
  type compatibility rules are satisfied.
- UNION (not UNION ALL) is correct here because "place_name" is a reference
  list; a duplicate entry would be a data quality defect, not a valid business
  fact worth preserving.

OPTIMIZATION NOTES
- With only two small branches, the optimizer will likely choose a hash-based
  deduplication rather than a full sort — but at scale, an index on
  departments(dept_name) and locations(city) allows each branch to be
  pre-sorted, letting the engine merge-deduplicate instead of sorting the
  full combined set from scratch.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 2 — Combined identifier pool (employee IDs and department IDs)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A new company-wide numbering system needs to confirm there is no overlap
   between existing employee IDs and department IDs before assigning new,
   unified record IDs.

   BUSINESS QUESTION
   What is the full set of numeric IDs already in use across employees and
   departments?
---------------------------------------------------------------------------- */

SELECT emp_id  AS existing_id
FROM employees

UNION

SELECT dept_id AS existing_id
FROM departments

ORDER BY existing_id;

/*
EXPECTED OUTPUT (8 rows):
 existing_id
 -----------
 10
 20
 30
 1001
 1002
 1003
 1004
 1005

ENGINEERING NOTES
- This is a genuine business question ("what IDs are taken") that a UNION
  answers directly — no JOIN could express this, since employees and
  departments are not being related to each other, only pooled together.
- If emp_id and dept_id ever overlapped (e.g., both containing the value 10),
  UNION would silently collapse them into a single row — acceptable here
  since the goal is exactly "the set of IDs in use," not a row-level audit.

OPTIMIZATION NOTES
- Both columns are already indexed as primary keys, so each branch is
  effectively pre-sorted; the deduplication step is inexpensive at this scale.
- ANSI SQL: fully portable across MySQL, PostgreSQL, SQL Server, and Oracle
  with no syntax changes.
*/
