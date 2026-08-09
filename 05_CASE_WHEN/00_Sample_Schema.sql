-- =============================================================
-- MODULE: 05_CASE_WHEN
-- FILE:   00_Sample_Schema.sql
-- PURPOSE: Shared schema + seed data used by every lesson in this
--          module. Run this once before working through 01-08.
-- DIALECT: Standard SQL (tested against PostgreSQL syntax).
--          MySQL/SQL Server notes are called out inline where the
--          syntax diverges.
-- ERD:     See ./assets/00_schema_erd.svg for the entity-relationship
--          diagram of locations / departments / employees / orders.
-- =============================================================

-- ---------------------------------------------------------------
-- Table: locations
-- ---------------------------------------------------------------
CREATE TABLE locations (
    location_id INT PRIMARY KEY,
    city        VARCHAR(50) NOT NULL,
    region      VARCHAR(50) NOT NULL
);

INSERT INTO locations (location_id, city, region) VALUES
    (1, 'Nagpur', 'West'),
    (2, 'Pune',   'West'),
    (3, 'Indore', 'Central');

-- ---------------------------------------------------------------
-- Table: departments
-- ---------------------------------------------------------------
CREATE TABLE departments (
    dept_id     INT PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL,
    location_id INT REFERENCES locations(location_id),
    budget      NUMERIC(12,2) NOT NULL
);

INSERT INTO departments (dept_id, dept_name, location_id, budget) VALUES
    (1, 'Engineering', 1, 4200000.00),
    (2, 'Sales',       2, 1800000.00),
    (3, 'Support',     1,  650000.00),
    (4, 'Finance',     3,  900000.00);

-- ---------------------------------------------------------------
-- Table: employees
-- NOTE: the original module used the misspelling "employes" as the
-- table name throughout. It is kept here as an alias-free rename to
-- "employees" for correctness, and every lesson file in this module
-- has been updated to match. If you are integrating this module
-- into a repo that still references "employes" elsewhere, either
-- rename that table too, or add:
--   CREATE VIEW employes AS SELECT * FROM employees;
-- ---------------------------------------------------------------
CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    emp_name    VARCHAR(100) NOT NULL,
    dept_id     INT REFERENCES departments(dept_id),
    manager_id  INT REFERENCES employees(emp_id),
    salary      NUMERIC(10,2) NOT NULL,
    hire_date   DATE NOT NULL,
    performance_score INT -- 1 (lowest) to 5 (highest), nullable = not yet reviewed
);

INSERT INTO employees (emp_id, emp_name, dept_id, manager_id, salary, hire_date, performance_score) VALUES
    (1, 'Aditi Rao',      1, NULL, 210000, '2018-03-01', 5),
    (2, 'Rohan Mehta',    1, 1,    165000, '2019-06-15', 4),
    (3, 'Sneha Kulkarni',  1, 1,    142000, '2021-01-10', 3),
    (4, 'Karan Verma',    2, NULL, 190000, '2017-11-20', 5),
    (5, 'Priya Nair',     2, 4,    118000, '2022-04-05', 2),
    (6, 'Farhan Sheikh',  3, NULL, 98000,  '2020-09-01', 3),
    (7, 'Ishita Deshmukh',3, 6,    76000,  '2023-02-14', NULL),
    (8, 'Vikram Joshi',   4, NULL, 132000, '2016-05-30', 4);

-- ---------------------------------------------------------------
-- Table: orders (introduced for aggregate / revenue-bucket lessons)
-- ---------------------------------------------------------------
CREATE TABLE orders (
    order_id    INT PRIMARY KEY,
    emp_id      INT REFERENCES employees(emp_id), -- sales rep who owns the order
    order_amount NUMERIC(10,2) NOT NULL,
    order_status VARCHAR(20) NOT NULL, -- 'placed', 'shipped', 'delivered', 'cancelled', 'refunded'
    order_date  DATE NOT NULL
);

INSERT INTO orders (order_id, emp_id, order_amount, order_status, order_date) VALUES
    (101, 4, 15000.00, 'delivered', '2026-01-05'),
    (102, 4, 500.00,   'cancelled', '2026-01-08'),
    (103, 5, 2200.00,  'delivered', '2026-01-12'),
    (104, 5, 75.00,    'refunded',  '2026-01-15'),
    (105, 4, 42000.00, 'shipped',   '2026-01-20'),
    (106, 5, 300.00,   'placed',    '2026-01-22');
