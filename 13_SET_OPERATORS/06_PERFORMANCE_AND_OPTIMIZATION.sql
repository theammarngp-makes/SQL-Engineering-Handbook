/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 06 — Performance and Optimization
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Demonstrate, with runnable queries, every performance rewrite promised
   throughout Topics 01-05: cheap duplicate counting, INTERSECT/EXCEPT vs.
   EXISTS/NOT EXISTS rewrites, the UNION-vs-JOIN correctness trap, and
   recursive UNION ALL for hierarchy traversal.

   DATASET
   -------
   Reuses employees / departments / locations (Topic 01) and
   crm_customers / erp_customers (Topic 03). Introduces:
     loyalty_members(customer_id, customer_name)
     newsletter_subscribers(customer_id, customer_name)
   ============================================================================ */

CREATE TABLE loyalty_members (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL
);

CREATE TABLE newsletter_subscribers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL
);

INSERT INTO loyalty_members (customer_id, customer_name) VALUES
    (501, 'Northwind Traders'),
    (502, 'Blue Harbor Foods'),
    (503, 'Solstice Analytics');

INSERT INTO newsletter_subscribers (customer_id, customer_name) VALUES
    (502, 'Blue Harbor Foods'),
    (503, 'Solstice Analytics'),
    (506, 'Ferngrove Traders');
    -- Note: 502 and 503 are on both lists; 501 is loyalty-only;
    -- 506 is newsletter-only — intentional, to exercise both operators.


/* ----------------------------------------------------------------------------
   SCENARIO 1 — Cheap duplicate counting: UNION cost, without paying for it
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Before deciding whether a reporting query needs UNION's de-duplication at
   all, a data engineer wants to know: how much actual duplication exists
   between departments.dept_name and locations.city? If the answer is zero,
   UNION ALL is provably just as correct as UNION, and cheaper.

   BUSINESS QUESTION
   How many duplicate rows would UNION's de-duplication step actually remove?
---------------------------------------------------------------------------- */

SELECT
    (SELECT COUNT(*) FROM (
        SELECT dept_name AS place_name FROM departments
        UNION ALL
        SELECT city AS place_name FROM locations
    ) all_rows) AS union_all_count,
    (SELECT COUNT(*) FROM (
        SELECT dept_name AS place_name FROM departments
        UNION
        SELECT city AS place_name FROM locations
    ) distinct_rows) AS union_count,
    (SELECT COUNT(*) FROM (
        SELECT dept_name AS place_name FROM departments
        UNION ALL
        SELECT city AS place_name FROM locations
    ) all_rows) -
    (SELECT COUNT(*) FROM (
        SELECT dept_name AS place_name FROM departments
        UNION
        SELECT city AS place_name FROM locations
    ) distinct_rows) AS duplicate_rows_removed;

/*
EXPECTED OUTPUT:
 union_all_count | union_count | duplicate_rows_removed
 -----------------|-------------|-------------------------
 6                | 6           | 0

ENGINEERING NOTES
- Zero duplicates removed proves, empirically rather than by assumption,
  that UNION's extra sort/hash cost bought nothing here — UNION ALL would
  have produced an identical result for less work.
- This diagnostic pattern is worth running once against production-scale
  data before deciding, for a recurring job, whether UNION is pulling its
  weight or is a leftover habit.

OPTIMIZATION NOTES
- This query itself runs the combined set twice (once for each COUNT), which
  is acceptable for a one-time diagnostic but should not be the pattern used
  inside a hot-path production report — there, compute the duplicate count
  once, materialized, if you need it repeatedly.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 2 — INTERSECT vs. EXISTS: same answer, different execution shape
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Marketing wants customers enrolled in both the loyalty program and the
   newsletter, to exclude them from a "join both programs" acquisition
   campaign. At small scale either form works; at large scale, the shape of
   the execution plan matters.

   BUSINESS QUESTION
   Which customers are on both lists?
---------------------------------------------------------------------------- */

-- Form A: native INTERSECT — materializes and compares two full sets
SELECT customer_id
FROM loyalty_members

INTERSECT

SELECT customer_id
FROM newsletter_subscribers;

-- Form B: EXISTS-based semi-join rewrite — probes newsletter_subscribers
-- once per loyalty_members row, using an index seek if customer_id is indexed
SELECT DISTINCT l.customer_id
FROM loyalty_members l
WHERE EXISTS (
    SELECT 1
    FROM newsletter_subscribers n
    WHERE n.customer_id = l.customer_id
);

/*
EXPECTED OUTPUT (both forms, identical): 502, 503

ENGINEERING NOTES
- Both forms are correct and, on tables this small, will perform
  indistinguishably. The distinction only matters once both tables are
  large enough that materializing and sorting/hashing the full
  newsletter_subscribers table (Form A) becomes measurably more expensive
  than seeking into it per row (Form B).

OPTIMIZATION NOTES
- Form B's plan quality depends entirely on customer_id being indexed on
  newsletter_subscribers (it is here, as the primary key). Without that
  index, Form B degrades to a nested-loop scan — often worse than Form A.
- Rule of thumb, to be confirmed with EXPLAIN on real data, not trusted
  blindly: Form B tends to win when one side is much smaller than the other
  and the larger side is indexed on the compared column; Form A tends to be
  competitive or better when both sides are large and roughly similar size.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 3 — EXCEPT vs. NOT EXISTS vs. LEFT JOIN: a three-way comparison
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The migration-gap check from Topic 03 (CRM customers missing from ERP)
   is run nightly and has grown slow as both tables have grown. Before
   optimizing, the engineer writes all three equivalent forms to compare.

   BUSINESS QUESTION
   Which CRM customers are missing from the ERP? (Three equivalent ways to
   ask the same question.)
---------------------------------------------------------------------------- */

-- Form A: native EXCEPT
SELECT customer_id
FROM crm_customers
EXCEPT
SELECT customer_id
FROM erp_customers;

-- Form B: NOT EXISTS anti-join
SELECT c.customer_id
FROM crm_customers c
WHERE NOT EXISTS (
    SELECT 1 FROM erp_customers e WHERE e.customer_id = c.customer_id
);

-- Form C: LEFT JOIN ... IS NULL anti-join
SELECT c.customer_id
FROM crm_customers c
LEFT JOIN erp_customers e ON c.customer_id = e.customer_id
WHERE e.customer_id IS NULL;

/*
EXPECTED OUTPUT (all three forms, identical): 503, 504

ENGINEERING NOTES
- All three are semantically equivalent here because customer_id is NOT
  NULL and primary-keyed on both tables. Form C is frequently the most
  familiar to engineers coming from a JOIN-heavy background and performs
  identically to Form B on every major engine's optimizer — the choice
  between B and C is a style preference, not a performance one.
- Form A remains the most readable statement of business intent ("what's
  the difference between these two sets") and should be preferred in code
  review UNLESS a specific EXPLAIN comparison on production data justifies
  the rewrite.

OPTIMIZATION NOTES
- On a table with tens of millions of rows and an index on
  erp_customers(customer_id), Forms B and C typically outperform Form A
  because the optimizer can plan an index-seek anti-join instead of
  materializing and sorting/hashing the full erp_customers table.
- Never rewrite Form A to a NOT IN equivalent — see Topic 03's NULL warning;
  Forms B and C are the only NULL-safe anti-join rewrites.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 4 — The UNION/JOIN trap: a common mistake, corrected
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A junior analyst wants a report of each employee's name alongside their
   department's name, and writes a UNION because "it combines two tables."
   The query runs, returns no error, and is silently wrong.

   BUSINESS QUESTION
   Show each employee's name next to their department's name.
---------------------------------------------------------------------------- */

-- INCORRECT — this is what NOT to do. Included for teaching contrast only.
-- SELECT emp_name, NULL AS dept_name FROM employees
-- UNION ALL
-- SELECT NULL, dept_name FROM departments;
-- This stacks employees and departments into separate ROWS with a NULL
-- placeholder column — it does NOT attach each employee to their actual
-- department. Every row has a NULL in one of the two columns. No error is
-- raised because the statement is syntactically valid; it simply answers a
-- different, useless question.

-- CORRECT — this business question requires combining COLUMNS, which means
-- a JOIN, not a set operator
SELECT
    e.emp_name,
    d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY e.emp_name;

/*
EXPECTED OUTPUT (5 rows):
 emp_name        | dept_name
 -----------------|-------------
 Aisha Bello      | Sales
 Elena Petrova    | Engineering
 Marcus Johnson   | Sales
 Ravi Kulkarni    | Engineering
 Wen Zhao         | Finance

ENGINEERING NOTES
- The diagnostic question that prevents this mistake: "does the output need
  MORE COLUMNS than either input alone (JOIN), or MORE ROWS with the SAME
  columns (UNION/UNION ALL)?" Here, the answer is unambiguously "more
  columns" — dept_name needs to sit beside emp_name, not below it.

OPTIMIZATION NOTES
- No amount of indexing "fixes" the incorrect UNION ALL version above,
  because the query is answering the wrong question, not answering the
  right question slowly. Diagnosing correctness before performance is the
  correct order of operations every time.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 5 — Recursive UNION ALL: traversing the management hierarchy
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   HR needs a full reporting-chain view: for every employee, their entire
   management line up to the top of the org, with a depth indicator for
   an indented org-chart visualization.

   BUSINESS QUESTION
   What is each employee's full management chain, from the top down?
---------------------------------------------------------------------------- */

WITH RECURSIVE org_chart AS (
    -- Anchor member: top-level employees (no manager), evaluated once
    SELECT
        emp_id,
        emp_name,
        manager_id,
        1 AS depth,
        CAST(emp_name AS VARCHAR(500)) AS reporting_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL                          -- MUST be ALL — see 06.md for why

    -- Recursive member: each pass finds the direct reports of the PREVIOUS
    -- pass's rows, referencing org_chart by its own name
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        oc.depth + 1,
        CAST(oc.reporting_path || ' > ' || e.emp_name AS VARCHAR(500))
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT
    emp_id,
    emp_name,
    depth,
    reporting_path
FROM org_chart
ORDER BY depth, emp_name;

/*
EXPECTED OUTPUT:
 emp_id | emp_name        | depth | reporting_path
 -------|------------------|-------|--------------------------------
 1001   | Ravi Kulkarni    | 1     | Ravi Kulkarni
 1003   | Marcus Johnson   | 1     | Marcus Johnson
 1005   | Wen Zhao         | 1     | Wen Zhao
 1002   | Elena Petrova    | 2     | Ravi Kulkarni > Elena Petrova
 1004   | Aisha Bello      | 2     | Marcus Johnson > Aisha Bello

ENGINEERING NOTES
- This dataset is only two levels deep, but the query is written to handle
  arbitrary depth — it will correctly traverse a ten-level hierarchy with no
  changes, because the recursive member always operates only on the most
  recently produced rows, not the entire accumulated result.
- || is the ANSI string concatenation operator (PostgreSQL, Oracle); MySQL
  requires CONCAT(oc.reporting_path, ' > ', e.emp_name); SQL Server uses +.

OPTIMIZATION NOTES
- An index on employees(manager_id) is essential once this hierarchy grows
  beyond a few hundred rows — each recursive pass performs a join against
  employees filtered by manager_id, and an unindexed manager_id column
  forces a full table scan on every single pass.
- If this query is run frequently against a deep, slowly-changing hierarchy
  (e.g., a multi-thousand-employee org chart queried on every dashboard
  load), materializing it into a scheduled "closure table" — one row per
  (ancestor, descendant) pair — usually outperforms recomputing the
  recursion on every request.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 6 — CTE reuse: computing a UNION ALL once, querying it twice
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A dashboard needs both a headcount-style summary AND a name listing from
   the same combined employee/department directory built in Topic 04. Without
   a CTE, that UNION ALL logic would be written out twice in one report.

   BUSINESS QUESTION
   From one unified directory (employees + departments), produce both an
   entity-type count summary and the raw combined listing, without repeating
   the UNION ALL logic.
---------------------------------------------------------------------------- */

WITH unified_directory AS (
    SELECT emp_name AS directory_name, 'employee' AS entity_type
    FROM employees

    UNION ALL

    SELECT dept_name AS directory_name, 'department' AS entity_type
    FROM departments
)
SELECT entity_type, COUNT(*) AS entity_count
FROM unified_directory
GROUP BY entity_type

ORDER BY entity_type;

/*
EXPECTED OUTPUT:
 entity_type | entity_count
 -------------|--------------
 department  | 3
 employee    | 5

ENGINEERING NOTES
- The UNION ALL logic — the exact query from Topic 04, Scenario 1 — is
  written once, in the CTE, and referenced once here. A second query in the
  same session (e.g., SELECT * FROM unified_directory ORDER BY entity_type,
  directory_name) could reuse it without duplicating the UNION ALL text.

OPTIMIZATION NOTES
- Whether unified_directory is computed once and reused, or re-evaluated
  per reference, is engine-dependent (see 06.md, Database Compatibility).
  If this CTE were expensive and referenced many times in one statement,
  confirm your engine's materialization behavior with EXPLAIN before
  assuming the cost is paid only once.
*/
