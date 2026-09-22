-- ============================================================================
-- MODULE 16 : QUERY OPTIMIZATION — SHARED SCHEMA
-- ============================================================================
-- Every lesson's SQL in this module runs against this schema, per
-- CONTRIBUTING.md's Documentation Conventions: "Every code example must run
-- against the handbook's shared employes / departments / locations schema
-- (00_Schema) unless explicitly marked as illustrative/pseudocode."
--
-- Domain: a bank's fraud-review operation. `employes` are staff, organized
-- into `departments` at physical `locations`. `transactions` are the
-- flagged-for-review bank transactions those employees process — this is
-- the module's one documented, formal exception to the core three-table
-- schema, matching the exception CONTRIBUTING.md itself anticipates
-- ("e.g. a transactions table") and the precedent already set as a
-- commented illustration in 04_JOIN_OPTIMIZATION.sql.
--
-- Run this file once before running any lesson's .sql file standalone.
-- Written for MySQL 8.0+ / MariaDB 10.5+.
-- PostgreSQL, SQL Server, and Oracle require syntax changes beyond auto-increment
-- (e.g., ELT() -> CASE, DATE_ADD -> interval arithmetic, MOD operator differences).
-- ============================================================================

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS employes;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS locations;

-- ----------------------------------------------------------------------------
-- CORE SCHEMA (Lessons 01-09)
-- ----------------------------------------------------------------------------

CREATE TABLE locations (
    location_id     INT PRIMARY KEY AUTO_INCREMENT,
    city            VARCHAR(100) NOT NULL,
    country         VARCHAR(100) NOT NULL
);

CREATE TABLE departments (
    dept_id         INT PRIMARY KEY AUTO_INCREMENT,
    dept_name       VARCHAR(100) NOT NULL,
    location_id     INT NOT NULL,
    CONSTRAINT fk_departments_location FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
);

CREATE TABLE employes (
    emp_id          INT PRIMARY KEY AUTO_INCREMENT,
    emp_name        VARCHAR(100) NOT NULL,
    dept_id         INT NOT NULL,
    manager_id      INT NULL,
    hire_date       DATE NOT NULL,
    CONSTRAINT fk_employes_department FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id),
    CONSTRAINT fk_employes_manager FOREIGN KEY (manager_id)
        REFERENCES employes(emp_id)
);

-- ----------------------------------------------------------------------------
-- SCHEMA EXTENSION: transactions (Lessons 10-12)
-- ----------------------------------------------------------------------------

CREATE TABLE transactions (
    transaction_id      INT PRIMARY KEY AUTO_INCREMENT,
    processed_by_emp_id INT NOT NULL,
    transaction_amount  DECIMAL(12,2) NOT NULL,
    transaction_date    DATE NOT NULL,
    transaction_status  VARCHAR(20) NOT NULL,
    CONSTRAINT fk_transactions_employee FOREIGN KEY (processed_by_emp_id)
        REFERENCES employes(emp_id)
);

-- ----------------------------------------------------------------------------
-- SEED DATA
-- ----------------------------------------------------------------------------

INSERT INTO locations (city, country) VALUES
    ('New York', 'USA'),
    ('London', 'UK'),
    ('Singapore', 'Singapore'),
    ('Toronto', 'Canada'),
    ('Sydney', 'Australia'),
    ('Bangalore', 'India');

INSERT INTO departments (dept_name, location_id) VALUES
    ('Fraud Review', 1),
    ('Compliance', 2),
    ('Customer Operations', 3),
    ('Risk Analytics', 1),
    ('Internal Audit', 4),
    ('Engineering', 1);

INSERT INTO employes (emp_name, dept_id, manager_id, hire_date)
SELECT
    CONCAT('Employee_', seq),
    1 + (seq MOD 6),
    NULL,
    DATE_ADD('2015-01-01', INTERVAL (seq MOD 3650) DAY)
FROM (
    SELECT (a.N + b.N * 10 + c.N * 100 + d.N * 1000 + 1) AS seq
    FROM
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d
) seq_gen
WHERE seq <= 5000;

INSERT INTO transactions (processed_by_emp_id, transaction_amount, transaction_date, transaction_status)
SELECT
    1 + (seq MOD 5000),
    ROUND(10 + (seq MOD 49990) / 10, 2),
    DATE_ADD('2024-01-01', INTERVAL (seq MOD 730) DAY),
    ELT(1 + (seq MOD 4), 'CLEARED', 'FLAGGED', 'UNDER_REVIEW', 'REJECTED')
FROM (
    SELECT (a.N + b.N * 10 + c.N * 100 + d.N * 1000 + e.N * 10000 + f.N * 100000 + 1) AS seq
    FROM
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) e,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2) f
) seq_gen
WHERE seq <= 300000;
