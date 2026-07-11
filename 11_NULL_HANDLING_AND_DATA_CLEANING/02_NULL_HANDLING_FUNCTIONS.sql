-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 02 - NULL Handling Functions
-- OBJECTIVE   : Apply COALESCE, IFNULL, and NULLIF correctly
--               against realistic HR and sales data.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- DATASET     : employees (see 01_INTRODUCTION_TO_NULLS.sql)
--               orders (created below for divide-by-zero scenarios)
-- ============================================================

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id       INT PRIMARY KEY,
    customer_name  VARCHAR(100),
    units_sold     INT,
    revenue        DECIMAL(10,2),
    discount_code  VARCHAR(20)
);

INSERT INTO orders (order_id, customer_name, units_sold, revenue, discount_code) VALUES
(1, 'Nilesh Patel',   4,  1200.00, 'SAVE10'),
(2, 'Grace Liu',      0,     0.00, NULL),        -- order created but cancelled before fulfillment
(3, 'Omar Farouk',    2,   450.00, NULL),
(4, 'Beatriz Souza',  0,     0.00, 'SAVE10'),    -- discount applied, then order cancelled
(5, 'Wei Zhang',      6,  1890.00, NULL);

-- ------------------------------------------------------------
-- SCENARIO 1
-- Business Context:
--   HR wants an org chart export where every employee shows a
--   manager name — the CEO and contractors should show a
--   readable label instead of a blank cell.
-- Question: Replace NULL manager_id with a readable fallback
--           using COALESCE on the SELF-JOINED manager name,
--           not on the raw manager_id itself.
-- ------------------------------------------------------------

SELECT
    e.emp_id,
    e.emp_name,
    COALESCE(m.emp_name, 'No Manager') AS manager_name
FROM
    employees e
    LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY
    e.emp_id;

-- Engineering Notes:
--   The original version of this exercise used
--   COALESCE(manager_id, emp_id) — falling back to the employee's
--   own emp_id, which incorrectly implies self-management. The
--   fix here is twofold: (1) fall back to a business-meaningful
--   label, not another ID column, and (2) resolve manager_id to
--   an actual manager NAME via LEFT JOIN before applying COALESCE,
--   since manager_id alone is not useful to a report reader.
-- Expected Output:
--   8 rows; Anita Rao and John Fischer show "No Manager".

-- ------------------------------------------------------------
-- SCENARIO 2
-- Business Context:
--   A payroll export needs manager_id as a raw numeric column
--   (for a downstream system join), where 0 is the agreed
--   sentinel value for "no manager" in that legacy system.
-- Question: Replace NULL manager_id with 0 using IFNULL.
-- ------------------------------------------------------------

SELECT
    emp_id,
    emp_name,
    IFNULL(manager_id, 0) AS manager_id_for_export
FROM
    employees;

-- Engineering Notes:
--   Using 0 here is safe ONLY because emp_id is guaranteed to
--   start at 1 in this system, so 0 cannot collide with a real
--   employee ID. This is an example of a sentinel value that is
--   safe in one context and would be dangerous in another —
--   always confirm the domain before choosing a fallback like 0.
-- Optimization Notes:
--   IFNULL is MySQL-specific; the equivalent PostgreSQL query
--   would use COALESCE(manager_id, 0) instead, since PostgreSQL
--   has no IFNULL function.
-- Expected Output:
--   8 rows; manager_id_for_export = 0 for Anita Rao and John Fischer.

-- ------------------------------------------------------------
-- SCENARIO 3
-- Business Context:
--   An engineer needs to decide between COALESCE and IFNULL for
--   a new pipeline that may eventually be ported to PostgreSQL.
-- Question: Demonstrate the two functions side by side and
--           show WHY COALESCE is the safer long-term choice.
-- ------------------------------------------------------------

SELECT
    emp_id,
    emp_name,
    COALESCE(manager_id, 0)               AS via_coalesce,   -- ANSI standard, portable
    IFNULL(manager_id, 0)                 AS via_ifnull,     -- MySQL-only
    COALESCE(manager_id, dept_id, 0)      AS via_coalesce_chained -- 3-argument fallback, IFNULL cannot do this
FROM
    employees;

-- Engineering Notes:
--   via_coalesce and via_ifnull will always match for a single
--   fallback value in MySQL — the meaningful difference is
--   portability and the ability to chain fallbacks, demonstrated
--   in via_coalesce_chained (which IFNULL cannot express directly
--   without nesting IFNULL calls inside each other).
-- Expected Output:
--   8 rows; via_coalesce and via_ifnull identical in every row;
--   via_coalesce_chained equal to via_coalesce here since
--   manager_id is the first-checked value in all cases.

-- ------------------------------------------------------------
-- SCENARIO 4
-- Business Context:
--   Finance is calculating revenue-per-unit for a sales report.
--   Two orders in the dataset have zero units sold (cancelled
--   after creation), which would otherwise raise a
--   divide-by-zero error and break the entire report.
-- Question: Safely calculate revenue per unit, guarding
--           against division by zero with NULLIF.
-- ------------------------------------------------------------

SELECT
    order_id,
    customer_name,
    units_sold,
    revenue,
    revenue / NULLIF(units_sold, 0) AS revenue_per_unit
FROM
    orders;

-- Engineering Notes:
--   NULLIF(units_sold, 0) evaluates to NULL whenever units_sold
--   is exactly 0, turning "revenue / 0" into "revenue / NULL",
--   which safely evaluates to NULL instead of raising a
--   divide-by-zero error. NULL is the correct business answer
--   here — "revenue per unit" is genuinely undefined when zero
--   units were sold.
-- Optimization Notes:
--   This pattern (NULLIF as a divide-by-zero guard) is the
--   single most common real-world use of NULLIF and should be
--   the default association, not comparing two unrelated columns.
-- Expected Output:
--   5 rows; revenue_per_unit is NULL for order_id 2 and 4
--   (both have units_sold = 0), and a computed value for the rest.

-- ------------------------------------------------------------
-- SCENARIO 5
-- Business Context:
--   A previous version of this codebase used
--   NULLIF(dept_id, manager_id) intending to find some kind of
--   "mismatch" between department and manager. This scenario
--   shows why that logic is meaningless and what the analyst
--   actually needed instead.
-- Question: Correct the flawed NULLIF usage and replace it with
--           the CASE logic the business question actually required —
--           flag employees whose manager is in a different
--           department than they are.
-- ------------------------------------------------------------

-- INCORRECT — NULLIF here only returns NULL when dept_id and
-- manager_id happen to share the same number, which is a
-- coincidence, not a meaningful business condition.
-- (Shown for reference; do not use.)
--
-- SELECT emp_id, emp_name, dept_id,
--        NULLIF(dept_id, manager_id) AS meaningless_result
-- FROM employees;

-- CORRECTED — compare the employee's department to their
-- manager's actual department via self-join.
SELECT
    e.emp_id,
    e.emp_name,
    e.dept_id             AS employee_dept,
    m.dept_id              AS manager_dept,
    CASE
        WHEN m.dept_id IS NULL THEN 'No Manager on Record'
        WHEN e.dept_id <> m.dept_id THEN 'Cross-Department Reporting'
        ELSE 'Same Department'
    END AS reporting_line_flag
FROM
    employees e
    LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Engineering Notes:
--   This is the correct pattern for the business question the
--   original NULLIF misuse was reaching for: compare the actual
--   resolved values (via self-join), not the raw ID columns,
--   and use CASE for multi-branch business logic rather than
--   trying to force NULLIF to do work it isn't designed for.
-- Expected Output:
--   8 rows; each employee flagged as same-department,
--   cross-department, or having no manager on record.
