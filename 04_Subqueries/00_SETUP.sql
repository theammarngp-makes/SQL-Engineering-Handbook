-- ============================================================================
-- SQL ENGINEERING HANDBOOK
-- MODULE 04: SUBQUERIES
-- TOPIC 00: DATABASE SCHEMA & SEED DATA SETUP
-- File: 00_SETUP.sql
-- Description: Complete self-contained DDL and DML setup script creating all
--              tables, indexes, constraints, and seed data required by Module 04.
-- Compatibility: PostgreSQL 16+ / ANSI SQL
-- ============================================================================

-- Drop existing tables if re-running setup
DROP TABLE IF EXISTS patient_vitals CASCADE;
DROP TABLE IF EXISTS warehouse_inventory CASCADE;
DROP TABLE IF EXISTS backordered_items CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS listings CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS tenant_accounts CASCADE;
DROP TABLE IF EXISTS subscription_tiers CASCADE;
DROP TABLE IF EXISTS employes CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS locations CASCADE;

-- ----------------------------------------------------------------------------
-- Core Handbook Schema: Locations, Departments, Employes
-- ----------------------------------------------------------------------------

CREATE TABLE locations (
    location_id INT PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location_id INT REFERENCES locations(location_id)
);

CREATE TABLE employes (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50) NOT NULL,
    dept_id INT REFERENCES departments(dept_id),
    manager_id INT REFERENCES employes(emp_id),
    salary NUMERIC(10, 2) NOT NULL DEFAULT 60000.00,
    hire_date DATE NOT NULL
);

-- Indexes for subquery correlation and join optimization
CREATE INDEX idx_emp_dept ON employes(dept_id);
CREATE INDEX idx_emp_manager ON employes(manager_id);
CREATE INDEX idx_emp_hire_date ON employes(hire_date);
CREATE INDEX idx_dept_location ON departments(location_id);

-- ----------------------------------------------------------------------------
-- Enterprise Case Study Tables
-- ----------------------------------------------------------------------------

-- Transactions Table (FinTech / Fraud Detection)
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    account_id INT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_tx_account_created ON transactions(account_id, created_at);

-- Listings Table (E-Commerce / Real Estate)
CREATE TABLE listings (
    listing_id INT PRIMARY KEY,
    property_name VARCHAR(100) NOT NULL,
    city_id INT NOT NULL,
    nightly_price NUMERIC(10, 2) NOT NULL
);

-- Patient Vitals Table (Healthcare ICU Telemetry)
CREATE TABLE patient_vitals (
    vital_id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL,
    heart_rate INT NOT NULL,
    is_admission_baseline BOOLEAN NOT NULL DEFAULT FALSE,
    room_number VARCHAR(20) NOT NULL,
    reading_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Warehouses & Backorder Inventory (Logistics & Supply Chain)
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL
);

CREATE TABLE backordered_items (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(50) NOT NULL
);

CREATE TABLE warehouse_inventory (
    warehouse_id INT REFERENCES warehouses(warehouse_id),
    item_id INT REFERENCES backordered_items(item_id),
    available_quantity INT NOT NULL,
    PRIMARY KEY (warehouse_id, item_id)
);

-- Orders & Subscription Tiers (SaaS & E-Commerce Analytics)
CREATE TABLE subscription_tiers (
    tier_id INT PRIMARY KEY,
    tier_name VARCHAR(50) NOT NULL,
    max_storage_bytes BIGINT NOT NULL
);

CREATE TABLE tenant_accounts (
    tenant_id INT PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    tier_id INT REFERENCES subscription_tiers(tier_id),
    current_storage_bytes BIGINT NOT NULL
);

-- ----------------------------------------------------------------------------
-- Seed Data Insertion
-- ----------------------------------------------------------------------------

-- Locations
INSERT INTO locations (location_id, city, country) VALUES
(1, 'Nagpur', 'India'),
(2, 'Pune', 'India'),
(3, 'Mumbai', 'India'),
(4, 'Bengaluru', 'India'),
(5, 'Hyderabad', 'India');

-- Departments
INSERT INTO departments (dept_id, dept_name, location_id) VALUES
(1, 'Data Analytics', 1),
(2, 'Engineering', 2),
(3, 'Product Operations', 1),
(4, 'Executive Leadership', 3),
(5, 'Unassigned Innovation Lab', NULL);

-- Employes
INSERT INTO employes (emp_id, emp_name, dept_id, manager_id, salary, hire_date) VALUES
(11, 'Rohit', 1, NULL, 120000.00, '2020-04-11'),
(3,  'Sahil', 1, 11,   95000.00,  '2022-11-10'),
(1,  'Ammar', 1, 11,   85000.00,  '2023-01-15'),
(4,  'Priya', 2, NULL, 130000.00, '2019-08-01'),
(5,  'Vikram',2, 4,    105000.00, '2021-03-15'),
(6,  'Neha',  2, 4,    98000.00,  '2022-06-20'),
(7,  'Ananya',3, 11,   78000.00,  '2023-05-10');

-- Transactions
INSERT INTO transactions (account_id, amount, created_at) VALUES
(101, 150.00,  CURRENT_TIMESTAMP - INTERVAL '10 days'),
(101, 200.00,  CURRENT_TIMESTAMP - INTERVAL '5 days'),
(101, 180.00,  CURRENT_TIMESTAMP - INTERVAL '2 days'),
(101, 2500.00, CURRENT_TIMESTAMP - INTERVAL '1 hour'), -- Fraud anomaly!
(102, 50.00,   CURRENT_TIMESTAMP - INTERVAL '1 day');

-- Warehouses & Backorder Inventory
INSERT INTO warehouses (warehouse_id, warehouse_name, region) VALUES
(1, 'Nagpur Central Hub', 'West'),
(2, 'Pune Fulfillment Center', 'West'),
(3, 'Mumbai Port Warehouse', 'West');

INSERT INTO backordered_items (item_id, item_name) VALUES
(501, 'High-Density Server Rack'),
(502, 'Fiber Optic Transceiver');

INSERT INTO warehouse_inventory (warehouse_id, item_id, available_quantity) VALUES
(1, 501, 10),
(2, 501, 0),
(3, 502, 5);

-- Subscription Tiers & Tenants
INSERT INTO subscription_tiers (tier_id, tier_name, max_storage_bytes) VALUES
(1, 'Starter Tier', 10737418240),      -- 10 GB
(2, 'Enterprise Tier', 1099511627776);  -- 1 TB

INSERT INTO tenant_accounts (tenant_id, company_name, tier_id, current_storage_bytes) VALUES
(1001, 'Alpha Tech Solutions', 1, 15000000000), -- Exceeds 10 GB limit!
(1002, 'Beta Cloud Corp', 2, 50000000000);

-- Verify Setup Execution
SELECT 'Setup complete! Tables, constraints, and seed records initialized successfully.' AS status;
