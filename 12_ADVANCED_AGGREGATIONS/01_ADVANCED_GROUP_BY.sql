-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   01 · ADVANCED GROUP BY
-- ============================================================================
-- Business Objective:
--   Produce organizational headcount reports across multiple HR dimensions
--   (department, city, management status) in single, efficient queries,
--   instead of one query per breakdown.
--
-- Dataset Used (Human Resources domain):
--   employees   (emp_id PK, emp_name, dept_id FK, manager_id FK -> emp_id, hire_date)
--   departments (dept_id PK, dept_name, location_id FK)
--   locations   (location_id PK, city)
--
-- Dialect notes:
--   Written for MySQL 8+ and PostgreSQL. Dialect-specific behavior is called
--   out inline where it applies. NOTE: the source table is `employees`
--   (corrected from the common typo `employes` seen in early draft queries).
-- ============================================================================


-- ============================================================================
-- SCENARIO 1
-- Business Context:
--   HR wants a single department-level summary showing total headcount and
--   how many of those employees currently report to a manager, to flag
--   departments with unusually flat (or top-heavy) reporting structures.
--
-- Business Questions:
--   - How many employees are in each department?
--   - Of those, how many have an assigned manager vs. none (i.e., are a
--     top-level / department-head employee)?
-- ============================================================================

SELECT
    d.dept_name                                            AS department_name,
    COUNT(DISTINCT e.emp_id)                                AS total_employees,
    COUNT(CASE WHEN e.manager_id IS NOT NULL
               THEN e.emp_id END)                           AS employees_with_manager,
    COUNT(CASE WHEN e.manager_id IS NULL
               THEN e.emp_id END)                            AS employees_without_manager
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
ORDER BY total_employees DESC;

-- Explanation:
--   GROUP BY d.dept_name sets the grain to "one row per department."
--   COUNT(DISTINCT e.emp_id) is the safe headcount metric because a
--   department-to-employee join is one-to-many; COUNT(DISTINCT) guards
--   against inflation if a later join (e.g., to a certifications table)
--   is added to this query.
--   The two CASE-wrapped COUNT() calls are a preview of conditional
--   aggregation (fully covered in Topic 03) used here to split one grouped
--   metric into two mutually exclusive sub-metrics in a single pass.
--
-- Engineering Notes:
--   employees_with_manager + employees_without_manager must always equal
--   total_employees for every row -- this is a useful automated data-quality
--   check to run after every refresh of this report.
--
-- Optimization Notes:
--   A composite index on employees(dept_id, manager_id) allows the engine
--   to satisfy both the join and the conditional counts from a single index
--   scan, avoiding a full table scan of `employees`.
--
-- Expected Output (illustrative):
--   department_name | total_employees | employees_with_manager | employees_without_manager
--   Engineering      | 42              | 40                      | 2
--   Sales            | 18              | 17                      | 1


-- ============================================================================
-- SCENARIO 2
-- Business Context:
--   Facilities and regional HR leads need headcount and department coverage
--   per office city, to plan desk space and local HR staffing.
--
-- Business Questions:
--   - How many employees work out of each city?
--   - How many distinct departments have a presence in that city?
-- ============================================================================

SELECT
    l.city                                                  AS office_city,
    COUNT(DISTINCT e.emp_id)                                AS total_employees,
    COUNT(DISTINCT d.dept_id)                                AS departments_present
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
JOIN locations   AS l ON d.location_id = l.location_id
GROUP BY l.city
ORDER BY total_employees DESC;

-- Explanation:
--   Grain here is "one row per city." COUNT(DISTINCT d.dept_id) answers a
--   materially different business question than COUNT(DISTINCT e.emp_id) --
--   headcount vs. organizational breadth -- from the exact same grouped rows,
--   demonstrating why "multiple aggregations" (Topic 02) matters even inside
--   a straightforward GROUP BY report like this one.
--
-- Engineering Notes:
--   This query assumes every department maps to exactly one location. If a
--   department can legitimately span multiple cities, department_present
--   would need to be reinterpreted as "department presence," not "department
--   headquartered here."
--
-- Optimization Notes:
--   Index departments(location_id) and employees(dept_id) to keep both join
--   steps index-driven rather than triggering a hash join over full tables.
--
-- Expected Output (illustrative):
--   office_city | total_employees | departments_present
--   Nagpur      | 65              | 6
--   Pune        | 30              | 4


-- ============================================================================
-- SCENARIO 3
-- Business Context:
--   Leadership wants the department-by-city cross-tabulation itself, not
--   just city totals -- the true multi-column GROUP BY case this topic is
--   built around.
--
-- Business Questions:
--   - For every department/city combination that exists, how many
--     employees work there?
-- ============================================================================

SELECT
    d.dept_name                                             AS department_name,
    l.city                                                  AS office_city,
    COUNT(DISTINCT e.emp_id)                                AS total_employees
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
JOIN locations   AS l ON d.location_id = l.location_id
GROUP BY d.dept_name, l.city
ORDER BY department_name, office_city;

-- Explanation:
--   GROUP BY d.dept_name, l.city groups on the unique combination of both
--   columns -- the grain is now "one row per department per city," strictly
--   finer than either Scenario 1 or Scenario 2 alone. This is the query a
--   BI tool would use as the base table for a cross-tab / matrix dashboard
--   widget with department on one axis and city on the other.
--
-- Engineering Notes:
--   Departments that exist in only one city will show a single row here;
--   that is expected, not a bug -- GROUP BY only emits combinations that
--   are actually present in the joined data (see Edge Cases in the
--   companion .md file for how to force zero-count rows to appear).
--
-- Optimization Notes:
--   Composite index departments(dept_id, location_id) supports this grouping
--   directly. For very large employee tables, consider materializing this
--   exact grain as a nightly summary table if it feeds a high-traffic
--   dashboard.
--
-- Expected Output (illustrative):
--   department_name | office_city | total_employees
--   Engineering      | Nagpur      | 28
--   Engineering      | Pune        | 14
--   Sales            | Nagpur      | 18


-- ============================================================================
-- SCENARIO 4
-- Business Context:
--   The VP of People wants a one-line answer: which single city carries the
--   most headcount company-wide, to prioritize the next HR hire.
--
-- Business Questions:
--   - Which city has the highest total employee count?
-- ============================================================================

WITH city_headcount AS (
    SELECT
        l.city                                              AS office_city,
        COUNT(DISTINCT e.emp_id)                            AS total_employees
    FROM employees   AS e
    JOIN departments AS d ON e.dept_id = d.dept_id
    JOIN locations   AS l ON d.location_id = l.location_id
    GROUP BY l.city
)
SELECT
    office_city,
    total_employees
FROM city_headcount
WHERE total_employees = (SELECT MAX(total_employees) FROM city_headcount);

-- Explanation:
--   The CTE first computes the full per-city aggregation (identical shape to
--   Scenario 2), then a correlated-free scalar subquery finds the maximum
--   and the outer query filters down to it. Using WHERE (not HAVING) here
--   is correct because the filter compares against a value from a separate
--   subquery result, not directly against an aggregate computed in the same
--   GROUP BY -- HAVING MAX(total_employees) = MAX(total_employees) would be
--   a no-op, since HAVING evaluates per group.
--
-- Engineering Notes:
--   Writing this as `= (SELECT MAX(...))` rather than `ORDER BY ... LIMIT 1`
--   correctly returns *every* tied top city, not just one arbitrary row --
--   an important distinction for an executive-facing metric.
--   A window-function alternative (RANK() OVER (ORDER BY total_employees
--   DESC)) is cleaner for this and is covered in the Window Functions module
--   of this handbook.
--
-- Optimization Notes:
--   For large tables, materialize city_headcount as Scenario 2's summary
--   table and query the max from that, rather than recomputing the full
--   aggregation twice per run.
--
-- Expected Output (illustrative):
--   office_city | total_employees
--   Nagpur      | 65


-- ============================================================================
-- SCENARIO 5
-- Business Context:
--   HR wants every employee labeled by management status alongside their
--   department, to support a filterable roster view in the HRIS front end.
--
-- Business Questions:
--   - Which employees are "Top Manager" (no manager above them) versus
--     "Managed" (report to someone), grouped by department for a summary
--     count of each?
-- ============================================================================

SELECT
    d.dept_name                                             AS department_name,
    CASE
        WHEN e.manager_id IS NULL THEN 'Top Manager'
        ELSE 'Managed'
    END                                                      AS management_status,
    COUNT(DISTINCT e.emp_id)                                AS employee_count
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
GROUP BY
    d.dept_name,
    CASE
        WHEN e.manager_id IS NULL THEN 'Top Manager'
        ELSE 'Managed'
    END
ORDER BY department_name, management_status;

-- Explanation:
--   The CASE expression is repeated in both SELECT and GROUP BY because
--   most engines (including MySQL and PostgreSQL in standard mode) require
--   GROUP BY to reference the same expression, not the output alias. This
--   groups by department AND the derived management-status label together
--   -- a computed column used as a grouping dimension, not just a raw table
--   column. (Corrected from an earlier draft's 'Top_manaer' typo.)
--
-- Engineering Notes:
--   Some dialects (MySQL) permit GROUP BY 2 (ordinal position) or GROUP BY
--   management_status (the alias) as a convenience; this file uses the
--   fully explicit form for portability and readability in code review.
--
-- Optimization Notes:
--   Because the grouping key is a derived expression, the engine cannot use
--   a plain index on manager_id to pre-sort groups the way it could for a
--   raw column -- expect a sort/hash aggregation step here regardless of
--   indexing.
--
-- Expected Output (illustrative):
--   department_name | management_status | employee_count
--   Engineering      | Managed            | 40
--   Engineering      | Top Manager        | 2
--   Sales             | Managed            | 17
--   Sales             | Top Manager        | 1
