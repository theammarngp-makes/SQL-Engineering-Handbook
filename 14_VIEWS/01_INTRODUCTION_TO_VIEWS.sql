-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 01 — Introduction to Views
-- Business Obj: Establish a consistent base schema used across Module 14,
--               and demonstrate that a View reflects live base-table data.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SHARED SCHEMA FOR MODULE 14
-- These tables are referenced by every file in this module. Run this section
-- once before working through any other .sql file in 14_VIEWS/.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS sales_order_items;
DROP TABLE IF EXISTS sales_orders;
DROP TABLE IF EXISTS sales_customers;
DROP TABLE IF EXISTS hr_employees;
DROP TABLE IF EXISTS hr_departments;
DROP TABLE IF EXISTS finance_transactions;
DROP TABLE IF EXISTS finance_accounts;

CREATE TABLE sales_customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(120) NOT NULL,
    region        VARCHAR(40)  NOT NULL,
    signup_date   DATE         NOT NULL
);

CREATE TABLE sales_orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT NOT NULL,
    order_date   DATE NOT NULL,
    status       VARCHAR(20) NOT NULL,   -- COMPLETED, CANCELLED, REFUNDED, PENDING
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES sales_customers(customer_id)
);

CREATE TABLE sales_order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_name  VARCHAR(120) NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES sales_orders(order_id)
);

CREATE TABLE hr_departments (
    department_id   INT PRIMARY KEY,
    department_name VARCHAR(80) NOT NULL,
    region          VARCHAR(40) NOT NULL
);

CREATE TABLE hr_employees (
    employee_id    INT PRIMARY KEY,
    full_name      VARCHAR(120) NOT NULL,
    department_id  INT NOT NULL,
    job_title      VARCHAR(80)  NOT NULL,
    annual_salary  DECIMAL(10,2) NOT NULL,
    hire_date      DATE NOT NULL,
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES hr_departments(department_id)
);

CREATE TABLE finance_accounts (
    account_id     INT PRIMARY KEY,
    customer_id    INT NOT NULL,
    account_type   VARCHAR(30) NOT NULL,  -- CHECKING, SAVINGS, CREDIT
    opened_date    DATE NOT NULL
);

CREATE TABLE finance_transactions (
    transaction_id INT PRIMARY KEY,
    account_id     INT NOT NULL,
    txn_date       DATE NOT NULL,
    amount         DECIMAL(12,2) NOT NULL,  -- positive = credit, negative = debit
    txn_type       VARCHAR(30) NOT NULL,
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id) REFERENCES finance_accounts(account_id)
);

-- -----------------------------------------------------------------------------
-- SEED DATA (production-scale patterns, small volume for lab purposes)
-- -----------------------------------------------------------------------------

INSERT INTO sales_customers VALUES
    (1, 'Meridian Retail Group', 'APAC', '2021-03-14'),
    (2, 'Northbridge Logistics', 'EMEA', '2020-11-02'),
    (3, 'Solace Consumer Goods', 'AMER', '2022-06-19'),
    (4, 'Vantage Home Supply',   'AMER', '2019-01-08');

INSERT INTO sales_orders VALUES
    (101, 1, '2024-01-10', 'COMPLETED'),
    (102, 1, '2024-02-05', 'CANCELLED'),
    (103, 2, '2024-01-22', 'COMPLETED'),
    (104, 3, '2024-03-01', 'REFUNDED'),
    (105, 4, '2024-03-15', 'COMPLETED'),
    (106, 4, '2024-04-02', 'PENDING');

INSERT INTO sales_order_items VALUES
    (1001, 101, 'Industrial Shelving Unit', 4, 189.99),
    (1002, 101, 'Pallet Wrap (Case)',       10, 24.50),
    (1003, 102, 'Warehouse Ladder',          1, 340.00),
    (1004, 103, 'Freight Tracking License',  1, 1200.00),
    (1005, 104, 'Bulk Packaging Tape',       50, 3.75),
    (1006, 105, 'Home Storage Rack',         6, 89.00),
    (1007, 106, 'Garden Tool Set',           3, 65.00);

INSERT INTO hr_departments VALUES
    (10, 'Sales',       'AMER'),
    (20, 'Engineering', 'APAC'),
    (30, 'Finance',     'EMEA');

INSERT INTO hr_employees VALUES
    (501, 'Priya Raman',      10, 'Account Executive', 78000.00, '2021-04-01'),
    (502, 'Daniel Osei',      20, 'Data Engineer',      96000.00, '2020-09-15'),
    (503, 'Fatima Al-Sayed',  30, 'Financial Analyst',  71000.00, '2022-02-11'),
    (504, 'Marco Bellini',    10, 'Sales Manager',     102000.00, '2018-07-23');

INSERT INTO finance_accounts VALUES
    (7001, 1, 'CHECKING', '2021-03-20'),
    (7002, 2, 'SAVINGS',  '2020-11-10'),
    (7003, 3, 'CREDIT',   '2022-06-25');

INSERT INTO finance_transactions VALUES
    (90001, 7001, '2024-01-05',  1500.00, 'DEPOSIT'),
    (90002, 7001, '2024-01-18',  -320.50, 'PAYMENT'),
    (90003, 7002, '2024-02-01',  5000.00, 'DEPOSIT'),
    (90004, 7003, '2024-02-14', -1250.00, 'PURCHASE');

-- -----------------------------------------------------------------------------
-- Business Scenario
-- Sales leadership wants a single source of truth for "completed revenue per
-- customer" that every downstream report can point to.
-- -----------------------------------------------------------------------------

-- Production Solution
CREATE OR REPLACE VIEW vw_completed_order_revenue AS
SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM sales_customers AS c
INNER JOIN sales_orders AS o
    ON o.customer_id = c.customer_id
INNER JOIN sales_order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.status = 'COMPLETED'
GROUP BY c.customer_id, c.customer_name, c.region;

-- Explanation:
-- The View encodes the "completed" business rule once. Any consumer querying
-- vw_completed_order_revenue inherits that rule automatically.

SELECT * FROM vw_completed_order_revenue ORDER BY total_revenue DESC;

-- Expected Output (4 rows):
-- customer_id | customer_name           | region | total_revenue
-- 4           | Vantage Home Supply     | AMER   | 534.00
-- 1           | Meridian Retail Group   | APAC   | 1004.96
-- 2           | Northbridge Logistics   | EMEA   | 1200.00
-- (Solace Consumer Goods is excluded — its only order is REFUNDED)

-- -----------------------------------------------------------------------------
-- Demonstration: a View always reflects current data (no caching)
-- -----------------------------------------------------------------------------

INSERT INTO sales_orders VALUES (107, 3, '2024-04-10', 'COMPLETED');
INSERT INTO sales_order_items VALUES (1008, 107, 'Retail Display Case', 2, 450.00);

-- Re-querying the same View now includes Solace Consumer Goods with no DDL change:
SELECT * FROM vw_completed_order_revenue WHERE customer_id = 3;

-- Engineering Notes:
-- No REFRESH, no CACHE INVALIDATE — the View re-executed its SELECT against
-- current table state. This is the core behavioral proof that a View stores
-- a definition, not a result set.

-- Performance Notes:
-- This query cost is identical whether you run it as a View or paste the
-- SELECT inline — MySQL's optimizer treats vw_completed_order_revenue as a
-- textual substitution (ALGORITHM = MERGE candidate here, since there is no
-- DISTINCT/aggregation blocking merge — see Module 07 for when that stops
-- being true).

-- Common Mistakes:
-- 1. Assuming re-running the SELECT is "expensive" because it's a View — it's
--    exactly as expensive as the underlying query, no more, no less.
-- 2. Forgetting a View depends on base tables existing with matching column
--    names — renaming sales_order_items.unit_price breaks this View silently
--    until it's queried.

-- Alternative Solution (equivalent, using explicit column list on the View):
CREATE OR REPLACE VIEW vw_completed_order_revenue
    (customer_id, customer_name, region, total_revenue) AS
SELECT
    c.customer_id,
    c.customer_name,
    c.region,
    SUM(oi.quantity * oi.unit_price)
FROM sales_customers AS c
INNER JOIN sales_orders AS o ON o.customer_id = c.customer_id
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'COMPLETED'
GROUP BY c.customer_id, c.customer_name, c.region;

-- Interview Insight:
-- Interviewers frequently ask "if I insert a row into the base table, does
-- the View see it immediately?" — the correct MySQL answer is yes, always,
-- with no exceptions, because MySQL Views are never materialized snapshots
-- by default (contrast with Postgres MATERIALIZED VIEW — see Module 08).

-- Further Challenge:
-- Predict, then verify: what happens to vw_completed_order_revenue's output
-- if you UPDATE sales_orders SET status = 'CANCELLED' WHERE order_id = 107?
