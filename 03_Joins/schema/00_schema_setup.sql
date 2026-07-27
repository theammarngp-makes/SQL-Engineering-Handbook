-- =============================================================================
-- MODULE 03 — JOINS
-- Canonical Schema & Seed Data
-- =============================================================================
--
-- PURPOSE
-- Every query in this module runs against this exact schema. Run this file
-- once before working through any topic file. If a query in another file
-- doesn't return what the file says it should, the first thing to check is
-- whether your local data matches this file, not whether the query is wrong.
--
-- DIALECT
-- Written in ANSI-compatible SQL that runs unmodified on PostgreSQL and MySQL
-- 8.0+. Vendor-specific deviations (auto-increment syntax, etc.) are called
-- out inline where they exist.
--
-- SCHEMA SHAPE
--
--     locations (1) ──────< departments (1) ──────< employees
--                                                        │
--                                                        │ manager_id (self-FK)
--                                                        └──────┘
--
-- =============================================================================

DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS locations;

-- -----------------------------------------------------------------------------
-- locations: physical offices the company operates
-- -----------------------------------------------------------------------------
CREATE TABLE locations (
    location_id     INT PRIMARY KEY,
    city            VARCHAR(50)  NOT NULL,
    country         VARCHAR(50)  NOT NULL
);

-- -----------------------------------------------------------------------------
-- departments: business units, each anchored to exactly one location
-- -----------------------------------------------------------------------------
CREATE TABLE departments (
    dept_id         INT PRIMARY KEY,
    dept_name       VARCHAR(50)  NOT NULL,
    location_id     INT          NULL,   -- nullable: a dept can be unassigned to a site
    budget          DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_departments_location
        FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

-- -----------------------------------------------------------------------------
-- employees: self-referencing via manager_id (used in 06_SELF_JOIN)
-- dept_id is intentionally NULLABLE — a handful of employees are unassigned,
-- which is the entire point of LEFT/RIGHT JOIN in this module (02, 03).
-- -----------------------------------------------------------------------------
CREATE TABLE employees (
    emp_id          INT PRIMARY KEY,
    emp_name        VARCHAR(50)  NOT NULL,
    dept_id         INT          NULL,
    manager_id      INT          NULL,
    hire_date       DATE         NOT NULL,
    salary          DECIMAL(10,2) NOT NULL,
    status          VARCHAR(10)  NOT NULL DEFAULT 'active',  -- active | on_leave | terminated
    CONSTRAINT fk_employees_department
        FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    CONSTRAINT fk_employees_manager
        FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Indexes a production schema would carry — referenced throughout
-- 08_JOIN_PERFORMANCE.md. Primary keys are indexed automatically; these
-- cover the foreign keys used as join predicates.
CREATE INDEX idx_departments_location_id ON departments(location_id);
CREATE INDEX idx_employees_dept_id       ON employees(dept_id);
CREATE INDEX idx_employees_manager_id    ON employees(manager_id);

-- =============================================================================
-- SEED DATA
-- =============================================================================

INSERT INTO locations (location_id, city, country) VALUES
    (1, 'Nagpur', 'India'),
    (2, 'Pune', 'India'),
    (3, 'Bengaluru', 'India'),
    (4, 'Remote', 'India');
    -- Note: no location_id = 5 exists anywhere — used deliberately in
    -- 03_RIGHT_JOIN and 04_FULL_OUTER_JOIN to demonstrate an unmatched row.

INSERT INTO departments (dept_id, dept_name, location_id, budget) VALUES
    (10, 'Engineering', 1, 4200000.00),
    (20, 'Sales',       2, 1800000.00),
    (30, 'HR',           1, 900000.00),
    (40, 'Finance',      3, 1500000.00),
    (50, 'Marketing',   NULL, 700000.00);   -- unassigned to any office (remote-first)
    -- Note: dept_id = 60 ("Legal") is intentionally NOT inserted here — used
    -- in 03_RIGHT_JOIN.sql to demonstrate a department with zero employees.

INSERT INTO departments (dept_id, dept_name, location_id, budget) VALUES
    (60, 'Legal', 3, 500000.00);

INSERT INTO employees (emp_id, emp_name, dept_id, manager_id, hire_date, salary, status) VALUES
    (1, 'Sahil Verma',    10, NULL, '2019-01-14', 210000.00, 'active'),  -- top of org, no manager
    (2, 'Ammar Khan',     10, 1,    '2020-03-02', 165000.00, 'active'),
    (3, 'Riya Sharma',    10, 1,    '2021-06-21', 158000.00, 'active'),
    (4, 'Neha Joshi',     20, NULL, '2018-11-09', 190000.00, 'active'),
    (5, 'Karan Patel',    20, 4,    '2022-02-17', 120000.00, 'active'),
    (6, 'Priya Nair',     30, NULL, '2020-08-30', 140000.00, 'active'),
    (7, 'Arjun Mehta',    40, NULL, '2019-05-04', 175000.00, 'active'),
    (8, 'Divya Rao',      40, 7,    '2023-01-10', 98000.00,  'on_leave'),
    (9, 'Farhan Ali',     NULL, NULL, '2023-09-18', 85000.00, 'active'), -- unassigned dept
    (10, 'Meera Iyer',    10, 2,    '2023-11-01', 102000.00, 'active');
    -- Note: dept_id = 60 (Legal) has zero employees — the RIGHT JOIN / FULL
    -- OUTER JOIN files depend on this being true. Do not add an employee here.
