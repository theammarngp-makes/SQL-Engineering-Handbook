/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 02 — UNION and UNION ALL
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Audit, correct, and expand a set of hand-written UNION / UNION ALL queries
   into production-quality reporting logic, and use them to demonstrate the
   measurable difference between the two operators.

   AUDIT NOTES ON THE SOURCE QUERIES PROVIDED
   -------------------------------------------
   1. The source table was referenced as `employes` — corrected to the
      correct spelling `employees` throughout, matching 01_INTRODUCTION.
   2. `SELECT DISTINCT(emp_id)` used DISTINCT as if it were a function call.
      DISTINCT is a keyword, not a function — corrected to `SELECT DISTINCT
      emp_id`. `DISTINCT(x)` "works" in most engines only because the
      parentheses are interpreted as a no-op expression grouping, not because
      DISTINCT takes an argument — this is a common, easy-to-miss mistake.
   3. Inconsistent spacing/alignment corrected to a single formatting
      convention for readability and diff-friendliness in version control.
   4. Every branch now has an explicit, business-meaningful alias.

   DATASET
   -------
   Reuses employees / departments / locations from 01_INTRODUCTION_TO_SET_OPERATORS.sql
   ============================================================================ */


/* ----------------------------------------------------------------------------
   SCENARIO 1 — Company-wide "named entities" directory (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The intranet directory page needs one list of every department name and
   every office city the company has, with no repeats.

   BUSINESS QUESTION
   What are all the distinct department names and city names in the company?
   (Original Q1, corrected and aliased.)
---------------------------------------------------------------------------- */

SELECT dept_name AS directory_entry
FROM departments

UNION

SELECT city AS directory_entry
FROM locations

ORDER BY directory_entry;

/*
EXPECTED OUTPUT:
 directory_entry
 ----------------
 Berlin
 Chicago
 Engineering
 Finance
 Sales
 Toronto

ENGINEERING NOTES
- UNION is correct: this is a reference list, and an accidental duplicate
  between a department name and a city name should collapse, not repeat.

OPTIMIZATION NOTES
- Small, static tables — cost is negligible. At scale, indexing dept_name and
  city allows the engine to merge two pre-sorted streams instead of hashing
  the full combined result.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 2 — Combined "people and departments" name list (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A search-autocomplete feature needs a single list of every searchable
   name in the org — employee names and department names — deduplicated.

   BUSINESS QUESTION
   What are all unique names across employees and departments?
   (Original Q2, corrected: `employes` → `employees`.)
---------------------------------------------------------------------------- */

SELECT emp_name AS searchable_name
FROM employees

UNION

SELECT dept_name AS searchable_name
FROM departments

ORDER BY searchable_name;

/*
EXPECTED OUTPUT (8 rows — every employee name plus every department name,
since none happen to collide):
 searchable_name
 ----------------
 Aisha Bello
 Elena Petrova
 Engineering
 Finance
 Marcus Johnson
 Ravi Kulkarni
 Sales
 Wen Zhao

ENGINEERING NOTES
- Both branches must return a single VARCHAR-compatible column; emp_name and
  dept_name satisfy this.
- Business risk: if a department is ever literally named after a person
  (rare, but possible with founder-named divisions), UNION would collapse
  a real employee and a real department into one visually identical row.
  A discriminator column (see Scenario 4) removes this ambiguity.

OPTIMIZATION NOTES
- ANSI SQL — portable across all four target databases without modification.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 3 — Combined authority IDs: managers and departments (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   An access-control migration needs the full set of "authority IDs" —
   anyone who is a manager, plus every department — to grant a matching
   set of admin permissions in a new system.

   BUSINESS QUESTION
   What is the combined, deduplicated set of manager IDs and department IDs?
   (Original Q3, corrected and clarified with NULL handling.)
---------------------------------------------------------------------------- */

SELECT manager_id AS authority_id
FROM employees
WHERE manager_id IS NOT NULL         -- Added: excludes top-level employees
                                      -- whose manager_id is NULL; including
                                      -- NULL here would silently inject a
                                      -- meaningless NULL row into the report

UNION

SELECT dept_id AS authority_id
FROM departments

ORDER BY authority_id;

/*
EXPECTED OUTPUT:
 authority_id
 ------------
 10
 20
 30
 1001
 1003

ENGINEERING NOTES
- The original query omitted the WHERE manager_id IS NOT NULL filter. Because
  three employees (Ravi, Marcus, Wen) have no manager, the unfiltered version
  would produce a single misleading NULL row representing "no manager,"
  mixed in with genuine department IDs. Filtering it out is a correction,
  not just a style choice.

OPTIMIZATION NOTES
- Filtering NULL out of the manager_id branch before the UNION reduces the
  rows the deduplication step has to process — always filter inside each
  branch, never after combining.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 4 — All unique employee and department identifiers (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   IT needs the complete pool of numeric IDs already assigned anywhere in the
   HR system before generating new IDs for an upcoming acquisition's staff.

   BUSINESS QUESTION
   What are all distinct IDs currently used for employees and departments?
   (Original Q4 — corrected DISTINCT(...) syntax and mislabeled business
   intent: the original comment said "location IDs" but the query actually
   selected emp_id and dept_id.)
---------------------------------------------------------------------------- */

SELECT DISTINCT emp_id AS used_id     -- Corrected: DISTINCT is a keyword,
FROM employees                        -- not a function — DISTINCT(emp_id)
                                       -- is misleading, not an error, but
                                       -- should never be written that way

UNION

SELECT DISTINCT dept_id AS used_id
FROM departments

ORDER BY used_id;

/*
EXPECTED OUTPUT:
 used_id
 -------
 10
 20
 30
 1001
 1002
 1003
 1004
 1005

ENGINEERING NOTES
- The inner SELECT DISTINCT is actually redundant here, since emp_id and
  dept_id are primary keys and already unique within their own tables — the
  outer UNION alone would produce the same result. It is kept only to make
  the query self-documenting in a context where uniqueness at the source
  isn't guaranteed (e.g., a view instead of a raw table).

OPTIMIZATION NOTES
- Redundant DISTINCT on an already-unique primary key column adds an
  unnecessary sort/hash step. In a hot-path query, remove it; in a
  defensive/self-documenting query against uncertain sources, keep it.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 5 — Combined employee and manager ID pool (UNION)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Payroll needs to confirm that every manager referenced in the org chart
   is also a valid employee ID, as part of a data quality check before
   year-end processing.

   BUSINESS QUESTION
   What is the deduplicated set of all employee IDs and all manager IDs?
   (Original Q5, corrected DISTINCT(...) syntax.)
---------------------------------------------------------------------------- */

SELECT DISTINCT emp_id AS person_id
FROM employees

UNION

SELECT DISTINCT manager_id AS person_id
FROM employees
WHERE manager_id IS NOT NULL

ORDER BY person_id;

/*
EXPECTED OUTPUT:
 person_id
 ---------
 1001
 1002
 1003
 1004
 1005

ENGINEERING NOTES
- This result being IDENTICAL to plain "SELECT DISTINCT emp_id FROM
  employees" is itself the data quality signal payroll wants: every
  manager_id already exists as an emp_id, so no orphaned manager reference
  exists. If a manager_id appeared here that was absent from the plain
  employee ID list, that would indicate a broken foreign key relationship.

OPTIMIZATION NOTES
- This exact pattern — UNION of a table's key against a self-referencing
  foreign key — is a lightweight referential-integrity check that avoids
  needing a full JOIN-based validation query.
*/


/* ============================================================================
   PART 2 — UNION ALL: the same style of questions, now where duplicates
            are real business events that must be preserved.
   ============================================================================ */


/* ----------------------------------------------------------------------------
   SCENARIO 6 — Combined names report, duplicates preserved (UNION ALL)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   An audit log export must show every employee name and every department
   name exactly as they appear in source, with no silent collapsing — this
   feeds a compliance system that expects a 1:1 row count match with source.

   BUSINESS QUESTION
   List every employee name and every department name, preserving row counts.
   (Original Q1 of the UNION ALL batch, corrected `employes` spelling.)
---------------------------------------------------------------------------- */

SELECT emp_name AS audit_entry
FROM employees

UNION ALL

SELECT dept_name AS audit_entry
FROM departments;

/*
EXPECTED OUTPUT: 8 rows — 5 employee names + 3 department names, in that
order, with no deduplication or resorting.

ENGINEERING NOTES
- UNION ALL is correct: a compliance export must reflect exactly what exists
  in source, including any coincidental duplicate text.

OPTIMIZATION NOTES
- No sort/hash step at all — this is the cheapest possible way to combine
  two result sets.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 7 — Intentional self-duplication for weighted sampling (UNION ALL)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A data science team is building a training sample and wants every city
   in `locations` to appear twice, doubling its sampling weight relative to
   a control group appended elsewhere in the pipeline.

   BUSINESS QUESTION
   Produce the city list with each city counted twice.
   (Original Q2, preserved as-is — this is a legitimate and correct use of
   UNION ALL against the same table twice.)
---------------------------------------------------------------------------- */

SELECT city AS weighted_city
FROM locations

UNION ALL

SELECT city AS weighted_city
FROM locations;

/*
EXPECTED OUTPUT: 6 rows — each of the 3 cities appears exactly twice.

ENGINEERING NOTES
- This pattern only makes sense with UNION ALL. Using UNION here would
  silently collapse the intentional duplication back down to 3 rows,
  defeating the entire purpose of the query.

OPTIMIZATION NOTES
- Trivial cost; the pattern generalizes to weighting a subquery result by
  wrapping it once per desired weight — avoid doing this for large row
  counts inline; consider a numbers/tally table with a CROSS JOIN instead
  for weights greater than 2 or 3.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 8 — Manager ID frequency check (UNION ALL)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   HR wants to see manager_id listed twice per occurrence as an input to a
   downstream aggregation step that counts direct-report load per manager.

   BUSINESS QUESTION
   List manager_id twice for every employee row.
   (Original Q3, corrected `employes` spelling.)
---------------------------------------------------------------------------- */

SELECT manager_id AS manager_ref
FROM employees
WHERE manager_id IS NOT NULL

UNION ALL

SELECT manager_id AS manager_ref
FROM employees
WHERE manager_id IS NOT NULL;

/*
EXPECTED OUTPUT: 4 rows — manager_id 1001 and 1003 each appearing twice
(Elena and Aisha are the only employees with a non-null manager_id).

ENGINEERING NOTES
- Added WHERE manager_id IS NOT NULL to both branches; the original query
  would otherwise emit two NULL rows with no business meaning.

OPTIMIZATION NOTES
- Filtering NULL out before UNION ALL avoids carrying meaningless rows
  through the rest of the pipeline — always cheaper to filter early.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 9 — UNION vs UNION ALL, same source, side by side (Comparison)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Before deciding how to merge a partitioned table, an engineer wants direct,
   side-by-side proof of what each operator does to the exact same input.

   BUSINESS QUESTION
   Compare the row count and content of UNION ALL vs UNION on dept_id vs
   itself. (Original Q4, preserved and annotated.)
---------------------------------------------------------------------------- */

-- UNION ALL: every department ID listed twice (6 rows)
SELECT dept_id AS dept_ref
FROM departments

UNION ALL

SELECT dept_id AS dept_ref
FROM departments;

-- UNION: every department ID appears exactly once (3 rows)
SELECT dept_id AS dept_ref
FROM departments

UNION

SELECT dept_id AS dept_ref
FROM departments;

/*
EXPECTED OUTPUT
UNION ALL → 6 rows (10, 20, 30, 10, 20, 30)
UNION     → 3 rows (10, 20, 30)

ENGINEERING NOTES
- This pair of queries is the clearest possible demonstration that a table
  UNIONed with itself is a deduplication idiom, while UNION ALL with itself
  is a pure doubling idiom. Neither is "correct" in isolation — they answer
  different questions.

OPTIMIZATION NOTES
- Running both in the same session against the same table is a cheap,
  reliable way to measure exactly how many duplicate rows a table contains:
  (UNION ALL row count) − (UNION row count) = number of duplicate rows.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 10 — Quantifying duplication via aggregate comparison
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A data quality dashboard needs a single automated check: "how much
   duplication exists between UNION ALL and UNION on this key column?"

   BUSINESS QUESTION
   Compare COUNT results between UNION ALL and UNION.
   (Original Q5 — corrected an important logical error: the original wrapped
   COUNT(dept_id) inside each branch BEFORE combining, which combines two
   pre-aggregated scalars, not the underlying rows. Rewritten to aggregate
   the combined result instead, which is what "count duplicates" actually
   requires.)
---------------------------------------------------------------------------- */

-- INCORRECT (preserved from source, for teaching contrast):
--   SELECT COUNT(dept_id) FROM departments
--   UNION ALL
--   SELECT COUNT(dept_id) FROM departments;
-- This returns two identical scalar rows (e.g., 3 and 3) — it compares the
-- count of each branch to itself, not the effect of the set operator.

-- CORRECTED: aggregate AFTER combining, using a derived table
SELECT
    (SELECT COUNT(*) FROM (
        SELECT dept_id FROM departments
        UNION ALL
        SELECT dept_id FROM departments
    ) AS all_rows)                          AS union_all_row_count,
    (SELECT COUNT(*) FROM (
        SELECT dept_id FROM departments
        UNION
        SELECT dept_id FROM departments
    ) AS distinct_rows)                     AS union_row_count;

/*
EXPECTED OUTPUT:
 union_all_row_count | union_row_count
 --------------------|------------------
 6                   | 3

ENGINEERING NOTES
- The corrected version answers the real business question: "how many rows
  does UNION ALL keep that UNION would discard?" (6 − 3 = 3 duplicate rows).
- The original pattern (COUNT before combining) is a common and easy mistake:
  it looks like it measures duplication, but it only ever compares a branch's
  aggregate to itself.

OPTIMIZATION NOTES
- For a one-time audit this derived-table approach is fine. For a recurring
  data quality check across large tables, prefer a single GROUP BY with
  HAVING COUNT(*) > 1 against the raw table — it avoids scanning the table
  twice via two independent set-operator branches.
*/
