-- =============================================================================
-- TOPIC: JOIN PERFORMANCE
-- DIFFICULTY: Intermediate -> Advanced
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- NOTE: this file is written for PostgreSQL's EXPLAIN ANALYZE syntax; see the
-- paired .md file's Vendor Notes for MySQL/SQL Server/Oracle equivalents.
-- Row counts in this seed data are far too small to force a hash or merge
-- join in practice — every exercise here is about reading plan STRUCTURE,
-- not about reproducing a genuinely slow query.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Confirm the join on employees.dept_id is using the index created in
-- schema/00_schema_setup.sql.
--
-- BUSINESS SCENARIO
-- Before shipping a new "active employees by department" dashboard query to
-- production, confirm it's not going to full-scan the employees table on
-- every page load once the table grows past its current seed-data size.
-- -----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT
    e.emp_name,
    d.dept_name
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.status = 'active';

-- WHAT TO LOOK FOR
-- At this table size (10 rows), PostgreSQL will very likely choose a
-- sequential scan over BOTH tables regardless of the index — the optimizer
-- correctly judges that for 10 rows, an index lookup costs more than just
-- reading the whole (tiny) table. This is not a bug or a wasted index; it's
-- the expected, correct behavior at small scale. The exercise here is
-- learning to READ the plan, not necessarily to see an Index Scan on this
-- particular seed data.


-- -----------------------------------------------------------------------------
-- Q2. Compare the plan with and without the dept_id index (simulating what
-- happens on an under-indexed production table).
--
-- BUSINESS SCENARIO
-- A teammate asks "do we actually need this index?" before a migration.
-- Prove the answer with a plan comparison rather than an opinion.
-- -----------------------------------------------------------------------------

-- Step 1: capture the baseline plan (index present)
EXPLAIN ANALYZE
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Step 2: drop the index
DROP INDEX IF EXISTS idx_employees_dept_id;

-- Step 3: rerun and compare
EXPLAIN ANALYZE
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Step 4: restore the schema to its documented state
CREATE INDEX idx_employees_dept_id ON employees(dept_id);

-- ENGINEERING NOTES
-- On this seed data, you likely will NOT see a meaningful plan difference —
-- that's the honest, correct outcome at 10 rows, and it's worth sitting
-- with that result rather than assuming the exercise is broken. The value
-- of this drill is procedural: knowing the exact steps (drop, compare,
-- recreate) to run this comparison confidently on a real, large production
-- table where the difference would be dramatic.


-- -----------------------------------------------------------------------------
-- Q3. Identify the join algorithm chosen for a three-table join.
--
-- BUSINESS SCENARIO
-- Reviewing a slow-query report; before proposing a fix, confirm which
-- join algorithm is actually running for each step of the chain.
-- -----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT
    e.emp_name,
    d.dept_name,
    l.city
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN locations l   ON d.location_id = l.location_id;

-- Read the plan bottom-up (PostgreSQL executes the innermost/lowest nodes
-- first): identify the two join nodes and record, in a comment, which
-- algorithm (Nested Loop / Hash Join / Merge Join) appears for each of the
-- two joins in this three-table chain.

-- INTERVIEW INSIGHT
-- Being asked to read an EXPLAIN plan live and correctly identify which
-- join algorithm ran, without being told in advance, is an increasingly
-- common senior-level SQL interview format — practicing on small, fast
-- queries like these builds the plan-reading habit even though the
-- algorithm choice itself isn't meaningfully different at this scale.

-- FURTHER EXPERIMENTS
-- 1. Wrap e.emp_name in UPPER() inside the WHERE clause of Q1
--    (WHERE UPPER(e.emp_name) = 'AMMAR KHAN') and observe whether the plan
--    changes shape — this demonstrates the "wrapped column defeats the
--    index" mistake described in the paired .md file, even without a large
--    enough table to see a real timing difference.
-- 2. Research your own database's method for forcing table statistics to
--    refresh (ANALYZE employees; in PostgreSQL) and explain, in a comment,
--    why stale statistics can cause the optimizer to choose a bad plan even
--    when the right indexes exist.
-- 3. If you have access to a larger dataset (or can generate one with a
--    recursive CTE / generate_series to produce 100,000+ synthetic rows),
--    rerun Q1-Q3 against it and observe the join algorithm actually change
--    based on data volume — this is where the concepts in this file
--    become visible in practice.
