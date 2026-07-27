-- =============================================================================
-- TOPIC: BUSINESS CASES (Capstone)
-- DIFFICULTY: Advanced
-- SCHEMA: Scenarios A & C use schema/00_schema_setup.sql (run that first).
--         Scenario B is a SELF-CONTAINED star-schema demo with its own
--         CREATE TABLE / INSERT statements — it intentionally does not
--         reuse the HR schema, since the whole point is practicing an
--         unfamiliar schema shape under time pressure, the way a real
--         onboarding-to-a-new-codebase moment actually feels.
-- =============================================================================


-- =============================================================================
-- SCENARIO A — HR: Compensation Equity Review
-- =============================================================================

-- CTE + re-join version
WITH dept_stats AS (
    SELECT
        dept_id,
        COUNT(*)    AS headcount,
        AVG(salary) AS avg_salary
    FROM employees
    WHERE status = 'active'
    GROUP BY dept_id
    HAVING COUNT(*) > 1
)
SELECT
    e.emp_name,
    d.dept_name,
    e.salary,
    ROUND(ds.avg_salary, 2) AS dept_avg_salary,
    ROUND((e.salary - ds.avg_salary) / ds.avg_salary * 100, 1) AS pct_above_avg
FROM employees e
INNER JOIN dept_stats ds ON e.dept_id = ds.dept_id
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > ds.avg_salary * 1.2
ORDER BY pct_above_avg DESC;

-- EXPECTED OUTPUT: depends on exact seed salaries in schema/00_schema_setup.sql —
-- run it and manually verify at least one flagged row's math by hand
-- (recompute that department's average salary yourself) before trusting the
-- query on real payroll data. This manual spot-check habit matters more
-- than the specific row count here.

-- Window-function alternative (see paired .md file for full discussion)
SELECT emp_name, dept_name, salary, pct_above_avg
FROM (
    SELECT
        e.emp_name,
        d.dept_name,
        e.salary,
        ROUND(
            (e.salary - AVG(e.salary) OVER (PARTITION BY e.dept_id))
            / AVG(e.salary) OVER (PARTITION BY e.dept_id) * 100, 1
        ) AS pct_above_avg,
        COUNT(*) OVER (PARTITION BY e.dept_id) AS dept_headcount
    FROM employees e
    INNER JOIN departments d ON e.dept_id = d.dept_id
    WHERE e.status = 'active'
) sub
WHERE dept_headcount > 1 AND pct_above_avg > 20
ORDER BY pct_above_avg DESC;

-- Confirm both versions return the identical set of flagged employees.


-- =============================================================================
-- SCENARIO B — E-Commerce: Star Schema Sales Analysis (self-contained demo)
-- =============================================================================

DROP TABLE IF EXISTS fact_order_line_items;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_dates;

CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    name        VARCHAR(50),
    country     VARCHAR(50)
);

CREATE TABLE dim_products (
    product_id  INT PRIMARY KEY,
    category    VARCHAR(50)
);

CREATE TABLE dim_dates (
    date_id     INT PRIMARY KEY,
    month       VARCHAR(10),
    quarter     VARCHAR(10)
);

CREATE TABLE fact_order_line_items (
    line_item_id INT PRIMARY KEY,
    customer_id  INT REFERENCES dim_customers(customer_id),
    product_id   INT REFERENCES dim_products(product_id),
    date_id      INT REFERENCES dim_dates(date_id),
    quantity     INT NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL
);

CREATE INDEX idx_fact_customer ON fact_order_line_items(customer_id);
CREATE INDEX idx_fact_product  ON fact_order_line_items(product_id);
CREATE INDEX idx_fact_date     ON fact_order_line_items(date_id);

INSERT INTO dim_customers VALUES
    (1, 'Aarav Singh', 'India'), (2, 'Zoe Turner', 'UK'), (3, 'Liam Chen', 'India');

INSERT INTO dim_products VALUES
    (1, 'Electronics'), (2, 'Home & Kitchen'), (3, 'Electronics');

INSERT INTO dim_dates VALUES
    (1, 'Jan', 'Q1-2024'), (2, 'Feb', 'Q1-2024'), (3, 'Mar', 'Q1-2024');

INSERT INTO fact_order_line_items VALUES
    (1, 1, 1, 1, 2, 15000.00),
    (2, 2, 2, 1, 1, 4500.00),
    (3, 1, 3, 2, 1, 22000.00),
    (4, 3, 1, 2, 3, 15000.00),
    (5, 3, 2, 3, 2, 4500.00);

-- BUSINESS QUESTION: monthly revenue by product category, per customer
-- country, for Q1-2024.

SELECT
    dc.country,
    dp.category,
    dd.month,
    SUM(f.quantity * f.unit_price) AS revenue
FROM fact_order_line_items f
INNER JOIN dim_customers dc ON f.customer_id = dc.customer_id
INNER JOIN dim_products  dp ON f.product_id  = dp.product_id
INNER JOIN dim_dates     dd ON f.date_id     = dd.date_id
WHERE dd.quarter = 'Q1-2024'
GROUP BY dc.country, dp.category, dd.month
ORDER BY dc.country, revenue DESC;

-- EXPECTED OUTPUT: 4 grouped rows across India/UK x Electronics/Home & Kitchen
-- x Jan/Feb/Mar, reflecting the 5 seeded line items above.

-- JOIN ORDER DISCUSSION
-- fact_order_line_items is the driving table — every dimension join is a
-- lookup FROM the fact table INTO a small dimension, on an indexed key.
-- This is the standard, performance-favorable shape for star-schema
-- queries; see 08_JOIN_PERFORMANCE.md's Star Schema section.


-- =============================================================================
-- SCENARIO C — Data Migration Reconciliation
-- =============================================================================
-- (back to the HR schema — schema/00_schema_setup.sql)

SELECT
    e.emp_name,
    d.dept_name,
    CASE
        WHEN e.emp_id IS NULL THEN 'department with no employees — verify before cutover'
        WHEN d.dept_id IS NULL THEN 'employee with no department — will fail migration validation'
        ELSE 'clean'
    END AS migration_status
FROM employees e
FULL OUTER JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL
ORDER BY migration_status;

-- EXPECTED OUTPUT: 2 rows — Farhan Ali (employee, no department) and Legal
-- (department, no employees) — same pair identified in 04_FULL_OUTER_JOIN.sql,
-- now framed as a migration-blocking classification rather than a generic
-- reconciliation.

-- MySQL note: FULL OUTER JOIN isn't native — see 04_FULL_OUTER_JOIN.sql's
-- Q3 for the UNION-based emulation, adapted here with the same CASE logic
-- applied to each half of the UNION individually.

-- FURTHER EXPERIMENTS
-- 1. In Scenario A, add a THIRD flagging tier — employees more than 40%
--    above their department average — and report both tiers with a
--    severity column.
-- 2. In Scenario B, add SUM(...) OVER () (unpartitioned) to compute each
--    country's revenue as a percentage of total Q1 revenue across all rows.
-- 3. In Scenario C, extend the reconciliation to a three-way check across
--    employees, departments, AND locations — decide whether this needs two
--    chained FULL OUTER JOINs and justify your structural choice in a comment.
