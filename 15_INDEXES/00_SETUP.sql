-- ============================================================
-- Module 15 — 00_SETUP.sql
-- Engine: MySQL 8.0+
--
-- Run this file FIRST. Every other .sql file in this module
-- assumes these tables exist. After running this file, every
-- CREATE INDEX / EXPLAIN / query in Files 01-13 executes without
-- a missing-table error.
--
-- IMPORTANT — sample data scale:
-- Sample INSERTs below are deliberately small (dozens of rows,
-- not millions) so this file runs in under a second and is easy
-- to read. Because of that, EXPLAIN plans you run against this
-- exact dataset will often show a full scan even where the module
-- text describes an index seek — the optimizer correctly judges
-- a full scan of 20 rows as cheap regardless of available indexes
-- (see 01_INDEX_FUNDAMENTALS.md, Edge Cases). To see the plans
-- described in the module text, either load a larger synthetic
-- dataset (a companion generator script is a good contributor
-- project — see the README) or trust the module's row-count
-- annotations, which assume production scale (10M-40M rows).
--
-- Idempotency: every statement below is safe to re-run from a
-- clean schema. Run `DROP DATABASE`/`CREATE DATABASE` first if
-- re-running against a schema with leftover module tables.
-- ============================================================


-- ============================================================
-- CORE: customers & orders
-- Used by: Files 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 12, 13
-- ============================================================

CREATE TABLE customers (
    id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    email          VARCHAR(255) NOT NULL,
    full_name      VARCHAR(120) NOT NULL,
    country        VARCHAR(2)   NOT NULL,       -- ISO 3166-1 alpha-2
    referral_code  VARCHAR(20)  NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE orders (
    order_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id   BIGINT UNSIGNED NOT NULL,
    order_date    DATE NOT NULL,
    status        VARCHAR(20) NOT NULL,          -- pending|completed|cancelled
    total_amount  DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
) ENGINE = InnoDB;

INSERT INTO customers (email, full_name, country) VALUES
    ('a@example.com', 'Amara Chen',      'US'),
    ('b@example.com', 'Ben Osei',        'GH'),
    ('c@example.com', 'Carla Ruiz',      'MX'),
    ('d@example.com', 'Dev Patel',       'IN'),
    ('e@example.com', 'Elin Svensson',   'SE');

INSERT INTO orders (customer_id, order_date, status, total_amount) VALUES
    (1, '2026-01-02', 'completed', 84.50),
    (1, '2026-01-09', 'completed', 22.10),
    (2, '2026-01-01', 'completed', 199.99),
    (2, '2026-01-03', 'cancelled', 45.00),
    (3, '2026-01-04', 'pending',   12.75),
    (4, '2026-01-05', 'completed', 301.20),
    (5, '2026-01-06', 'pending',   58.40);


-- ============================================================
-- E-COMMERCE: shipments
-- Used by: File 09
-- ============================================================

CREATE TABLE shipments (
    shipment_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    order_id         BIGINT UNSIGNED NOT NULL,
    origin_warehouse_id BIGINT UNSIGNED NOT NULL,
    tracking_number  VARCHAR(40) NOT NULL,
    expected_delivery DATE NOT NULL,
    shipped_at       DATETIME NULL,
    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
) ENGINE = InnoDB;

INSERT INTO shipments (order_id, origin_warehouse_id, tracking_number, expected_delivery) VALUES
    (1, 10, 'TRK-0001', '2026-01-06'),
    (3, 11, 'TRK-0002', '2026-01-05'),
    (6, 10, 'TRK-0003', '2026-01-09');


-- ============================================================
-- BANKING: accounts, transactions
-- Used by: File 09 (account search + fraud/settlement scenario)
-- ============================================================

CREATE TABLE accounts (
    account_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id     BIGINT UNSIGNED NOT NULL,
    account_number  VARCHAR(24) NOT NULL,
    account_type    VARCHAR(20) NOT NULL,        -- checking|savings
    opened_at       DATE NOT NULL,
    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
) ENGINE = InnoDB;

-- Transactions are the highest-volume, append-mostly table in a
-- banking schema — the canonical example for both fraud-velocity
-- queries (File 09) and index maintenance/bloat discussion (File 10).
CREATE TABLE transactions (
    transaction_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    account_id       BIGINT UNSIGNED NOT NULL,
    counterparty_account VARCHAR(24) NULL,
    amount           DECIMAL(12,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,       -- debit|credit|transfer
    status           VARCHAR(20) NOT NULL,       -- posted|pending|reversed
    occurred_at      DATETIME NOT NULL,
    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
) ENGINE = InnoDB;

INSERT INTO accounts (customer_id, account_number, account_type, opened_at) VALUES
    (1, '000123456789', 'checking', '2022-04-01'),
    (2, '000987654321', 'savings',  '2021-11-15'),
    (3, '000456789123', 'checking', '2023-02-20');

INSERT INTO transactions (account_id, counterparty_account, amount, transaction_type, status, occurred_at) VALUES
    (1, '000987654321', 250.00, 'transfer', 'posted', '2026-01-02 09:14:00'),
    (1, NULL,            84.50, 'debit',    'posted', '2026-01-02 18:40:00'),
    (2, '000123456789', 250.00, 'transfer', 'posted', '2026-01-02 09:14:02'),
    (3, NULL,           500.00, 'credit',   'pending','2026-01-04 12:00:00');


-- ============================================================
-- HEALTHCARE: patients, appointments, insurance_verifications
-- Used by: File 09 (patient search, appointment lookup, insurance
-- verification scenario)
-- ============================================================

CREATE TABLE patients (
    patient_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    mrn            VARCHAR(20) NOT NULL,          -- medical record number
    last_name      VARCHAR(80) NOT NULL,
    first_name     VARCHAR(80) NOT NULL,
    date_of_birth  DATE NOT NULL
) ENGINE = InnoDB;

CREATE TABLE appointments (
    appointment_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    patient_id       BIGINT UNSIGNED NOT NULL,
    provider_id      BIGINT UNSIGNED NOT NULL,
    scheduled_at     DATETIME NOT NULL,
    status           VARCHAR(20) NOT NULL,        -- scheduled|checked_in|completed|no_show
    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
) ENGINE = InnoDB;

CREATE TABLE insurance_verifications (
    verification_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    patient_id       BIGINT UNSIGNED NOT NULL,
    payer_id         BIGINT UNSIGNED NOT NULL,
    verified_at      DATETIME NULL,
    status           VARCHAR(20) NOT NULL,        -- pending|verified|denied
    CONSTRAINT fk_insverif_patient
        FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
) ENGINE = InnoDB;

INSERT INTO patients (mrn, last_name, first_name, date_of_birth) VALUES
    ('MRN-00001', 'Nguyen', 'Linh',  '1988-03-14'),
    ('MRN-00002', 'Nguyen', 'Trang', '1990-07-02'),
    ('MRN-00003', 'Fischer','Otto',  '1975-12-30');

INSERT INTO appointments (patient_id, provider_id, scheduled_at, status) VALUES
    (1, 501, '2026-01-10 09:00:00', 'scheduled'),
    (2, 502, '2026-01-10 09:30:00', 'scheduled'),
    (3, 501, '2026-01-11 14:00:00', 'checked_in');

INSERT INTO insurance_verifications (patient_id, payer_id, status) VALUES
    (1, 77, 'pending'),
    (2, 77, 'verified'),
    (3, 12, 'verified');


-- ============================================================
-- MANUFACTURING: warehouses, inventory, inventory_movements,
-- suppliers, supplier_deliveries
-- Used by: File 09 (inventory lookup, warehouse scanning,
-- supplier performance scenario)
-- ============================================================

CREATE TABLE warehouses (
    warehouse_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    code           VARCHAR(10) NOT NULL,
    region         VARCHAR(40) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE inventory (
    sku            VARCHAR(30) NOT NULL,
    warehouse_id   BIGINT UNSIGNED NOT NULL,
    quantity       INT NOT NULL DEFAULT 0,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    -- composite PRIMARY KEY added via ALTER below (File 04/09 pattern)
) ENGINE = InnoDB;

-- Append-heavy scan/movement log — every unit move, in or out,
-- gets a row. This table grows fast and is the realistic anchor
-- for the "warehouse scanning" access pattern named in File 09.
CREATE TABLE inventory_movements (
    movement_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    sku            VARCHAR(30) NOT NULL,
    warehouse_id   BIGINT UNSIGNED NOT NULL,
    movement_type  VARCHAR(20) NOT NULL,          -- receive|pick|adjust|transfer
    quantity_delta INT NOT NULL,
    scanned_at     DATETIME NOT NULL
) ENGINE = InnoDB;

CREATE TABLE suppliers (
    supplier_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(120) NOT NULL,
    country        VARCHAR(2) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE supplier_deliveries (
    delivery_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    supplier_id       BIGINT UNSIGNED NOT NULL,
    warehouse_id      BIGINT UNSIGNED NOT NULL,
    expected_at       DATETIME NOT NULL,
    delivered_at      DATETIME NULL,
    on_time           BOOLEAN NULL,
    CONSTRAINT fk_supdel_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id)
) ENGINE = InnoDB;

INSERT INTO warehouses (code, region) VALUES
    ('WH-EAST', 'US-EAST'), ('WH-WEST', 'US-WEST');

INSERT INTO inventory (sku, warehouse_id, quantity) VALUES
    ('SKU-1001', 1, 240),
    ('SKU-1001', 2, 58),
    ('SKU-2002', 1, 12);

ALTER TABLE inventory ADD PRIMARY KEY (sku, warehouse_id);

INSERT INTO inventory_movements (sku, warehouse_id, movement_type, quantity_delta, scanned_at) VALUES
    ('SKU-1001', 1, 'receive', 300, '2026-01-01 08:00:00'),
    ('SKU-1001', 1, 'pick',    -60, '2026-01-02 10:15:00'),
    ('SKU-2002', 1, 'adjust',   -3, '2026-01-03 16:40:00');

INSERT INTO suppliers (name, country) VALUES
    ('Meridian Components', 'DE'), ('Pacific Fasteners', 'VN');

INSERT INTO supplier_deliveries (supplier_id, warehouse_id, expected_at, delivered_at, on_time) VALUES
    (1, 1, '2026-01-01 08:00:00', '2026-01-01 07:40:00', TRUE),
    (2, 2, '2026-01-02 08:00:00', '2026-01-03 11:00:00', FALSE);


-- ============================================================
-- HR: employees
-- Used by: File 09 (payroll scenario)
-- ============================================================

CREATE TABLE employees (
    employee_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    full_name      VARCHAR(120) NOT NULL,
    status         VARCHAR(20) NOT NULL,          -- active|leave|terminated
    pay_period     VARCHAR(10) NOT NULL           -- e.g. '2026-01A'
) ENGINE = InnoDB;

INSERT INTO employees (full_name, status, pay_period) VALUES
    ('Priya Raman',   'active', '2026-01A'),
    ('Sam Idowu',     'active', '2026-01A'),
    ('Jonas Kallio',  'leave',  '2026-01A');


-- ============================================================
-- RETAIL: categories, products, promotions
-- Used by: File 09 (product search, seasonal analytics,
-- promotion filtering scenario)
-- ============================================================

CREATE TABLE categories (
    category_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(80) NOT NULL,
    seasonal       BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE = InnoDB;

CREATE TABLE products (
    product_id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    category_id        BIGINT UNSIGNED NOT NULL,
    name               VARCHAR(160) NOT NULL,
    price              DECIMAL(10,2) NOT NULL,
    popularity_score   INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
) ENGINE = InnoDB;

CREATE TABLE promotions (
    promotion_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    category_id      BIGINT UNSIGNED NOT NULL,
    starts_at        DATE NOT NULL,
    ends_at          DATE NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL,
    CONSTRAINT fk_promotions_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
) ENGINE = InnoDB;

INSERT INTO categories (name, seasonal) VALUES
    ('Outdoor Gear', TRUE), ('Electronics', FALSE), ('Winter Apparel', TRUE);

INSERT INTO products (category_id, name, price, popularity_score) VALUES
    (1, 'Trail Backpack 32L', 84.00, 210),
    (1, 'Camp Stove Mini',    38.50, 95),
    (3, 'Insulated Parka',    159.00, 340);

INSERT INTO promotions (category_id, starts_at, ends_at, discount_percent) VALUES
    (3, '2026-01-01', '2026-01-31', 20.00),
    (1, '2026-05-01', '2026-06-15', 15.00);


-- ============================================================
-- INSURANCE: policies, claims
-- Used by: File 09 (claim validation, fraud investigation
-- scenario)
-- ============================================================

CREATE TABLE policies (
    policy_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id    BIGINT UNSIGNED NOT NULL,
    policy_number  VARCHAR(24) NOT NULL,
    policy_type    VARCHAR(20) NOT NULL,          -- auto|home|health
    CONSTRAINT fk_policies_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
) ENGINE = InnoDB;

CREATE TABLE claims (
    claim_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    policy_id       BIGINT UNSIGNED NOT NULL,
    claim_number    VARCHAR(24) NOT NULL,
    status          VARCHAR(20) NOT NULL,         -- filed|under_review|approved|denied|flagged
    filed_at        DATETIME NOT NULL,
    amount_claimed  DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_claims_policy
        FOREIGN KEY (policy_id) REFERENCES policies (policy_id)
) ENGINE = InnoDB;

INSERT INTO policies (customer_id, policy_number, policy_type) VALUES
    (1, 'POL-AUTO-001', 'auto'),
    (2, 'POL-HOME-002', 'home');

INSERT INTO claims (policy_id, claim_number, status, filed_at, amount_claimed) VALUES
    (1, 'CLM-000001', 'under_review', '2026-01-05 10:00:00', 4200.00),
    (1, 'CLM-000002', 'flagged',      '2026-01-08 15:30:00', 9800.00),
    (2, 'CLM-000003', 'approved',     '2026-01-03 09:00:00', 1200.00);


-- ============================================================
-- RIDE-SHARING: drivers, rides
-- Used by: File 09 (ride history + nearby-driver spatial query)
-- Riders are modeled as customers (id reused as rider_id) to
-- avoid an unnecessary duplicate person table.
-- ============================================================

CREATE TABLE drivers (
    driver_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    full_name      VARCHAR(120) NOT NULL,
    location       POINT NOT NULL SRID 4326,
    is_available   BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE = InnoDB;

CREATE TABLE rides (
    ride_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    rider_id       BIGINT UNSIGNED NOT NULL,       -- references customers.id
    driver_id      BIGINT UNSIGNED NOT NULL,
    requested_at   DATETIME NOT NULL,
    status         VARCHAR(20) NOT NULL,           -- requested|in_progress|completed|cancelled
    CONSTRAINT fk_rides_rider
        FOREIGN KEY (rider_id) REFERENCES customers (id),
    CONSTRAINT fk_rides_driver
        FOREIGN KEY (driver_id) REFERENCES drivers (driver_id)
) ENGINE = InnoDB;

INSERT INTO drivers (full_name, location, is_available) VALUES
    ('Marcus Webb', ST_SRID(POINT(-122.42, 37.77), 4326), TRUE),
    ('Rina Kobayashi', ST_SRID(POINT(-122.41, 37.78), 4326), FALSE);

INSERT INTO rides (rider_id, driver_id, requested_at, status) VALUES
    (1, 1, '2026-01-02 08:15:00', 'completed'),
    (2, 2, '2026-01-03 18:40:00', 'completed');


-- ============================================================
-- STREAMING: content_catalog, recommendations
-- Used by: File 09 (recommendation lookup scenario)
-- ============================================================

CREATE TABLE content_catalog (
    content_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    title          VARCHAR(200) NOT NULL,
    content_type   VARCHAR(20) NOT NULL           -- movie|series|documentary
) ENGINE = InnoDB;

CREATE TABLE recommendations (
    user_id        BIGINT UNSIGNED NOT NULL,       -- references customers.id
    content_id     BIGINT UNSIGNED NOT NULL,
    score          DECIMAL(6,4) NOT NULL,
    generated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recommendations_content
        FOREIGN KEY (content_id) REFERENCES content_catalog (content_id)
) ENGINE = InnoDB;

INSERT INTO content_catalog (title, content_type) VALUES
    ('Northbound', 'series'), ('The Long Table', 'documentary');

INSERT INTO recommendations (user_id, content_id, score) VALUES
    (1, 1, 0.9421),
    (1, 2, 0.8112),
    (2, 1, 0.7765);


-- ============================================================
-- SAAS: tenants, audit_log
-- Used by: File 09 (tenant isolation + audit logging scenario)
-- ============================================================

CREATE TABLE tenants (
    tenant_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(120) NOT NULL,
    plan           VARCHAR(20) NOT NULL            -- free|pro|enterprise
) ENGINE = InnoDB;

-- Append-only, high-write, compliance-retained log — the canonical
-- "why not just index everything" table used in Files 06 and 10.
CREATE TABLE audit_log (
    audit_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    tenant_id      BIGINT UNSIGNED NOT NULL,
    actor_user_id  BIGINT UNSIGNED NOT NULL,
    event_type     VARCHAR(40) NOT NULL,           -- login|record_update|export|permission_change
    occurred_at    DATETIME NOT NULL,
    metadata_json  JSON NULL,
    CONSTRAINT fk_auditlog_tenant
        FOREIGN KEY (tenant_id) REFERENCES tenants (tenant_id)
) ENGINE = InnoDB;

INSERT INTO tenants (name, plan) VALUES
    ('Northwind Analytics', 'enterprise'), ('Fernbank Clinic', 'pro');

INSERT INTO audit_log (tenant_id, actor_user_id, event_type, occurred_at, metadata_json) VALUES
    (1, 501, 'login',            '2026-01-02 08:01:00', NULL),
    (1, 501, 'record_update',    '2026-01-02 08:05:00', JSON_OBJECT('table', 'invoices', 'id', 8842)),
    (2, 118, 'permission_change','2026-01-02 09:12:00', JSON_OBJECT('role', 'admin'));


-- ============================================================
-- MARKETING: campaigns, touchpoints
-- Used by: File 09 (attribution + campaign performance scenario)
-- ============================================================

CREATE TABLE campaigns (
    campaign_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(160) NOT NULL,
    channel        VARCHAR(40) NOT NULL,           -- email|paid_search|social|affiliate
    starts_at      DATE NOT NULL,
    ends_at        DATE NOT NULL
) ENGINE = InnoDB;

-- One row per marketing touch a customer had before converting —
-- the table multi-touch attribution queries run against.
CREATE TABLE touchpoints (
    touchpoint_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id     BIGINT UNSIGNED NOT NULL,
    campaign_id     BIGINT UNSIGNED NOT NULL,
    occurred_at     DATETIME NOT NULL,
    converted       BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_touchpoints_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id),
    CONSTRAINT fk_touchpoints_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns (campaign_id)
) ENGINE = InnoDB;

INSERT INTO campaigns (name, channel, starts_at, ends_at) VALUES
    ('New Year Outdoor Push', 'paid_search', '2026-01-01', '2026-01-31'),
    ('Referral Spring',       'affiliate',   '2026-03-01', '2026-04-15');

INSERT INTO touchpoints (customer_id, campaign_id, occurred_at, converted) VALUES
    (1, 1, '2026-01-01 10:00:00', FALSE),
    (1, 1, '2026-01-02 07:50:00', TRUE),
    (4, 1, '2026-01-04 21:15:00', FALSE);


-- ============================================================
-- OLAP / WAREHOUSE: star schema (fact_sales + dimensions)
-- Used by: Files 06, 10 (indexing strategy, star schema examples)
-- ============================================================

CREATE TABLE dim_date (
    date_key    INT PRIMARY KEY,      -- YYYYMMDD
    full_date   DATE NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    month       TINYINT NOT NULL,
    year        SMALLINT NOT NULL
) ENGINE = InnoDB;

CREATE TABLE dim_customer (
    customer_key   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    natural_customer_id BIGINT UNSIGNED NOT NULL,   -- links back to customers.id
    full_name      VARCHAR(120) NOT NULL,
    country        VARCHAR(2) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE dim_product (
    product_key    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    natural_product_id BIGINT UNSIGNED NOT NULL,    -- links back to products.product_id
    name           VARCHAR(160) NOT NULL,
    category       VARCHAR(80) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE dim_store (
    store_key      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(120) NOT NULL,
    region         VARCHAR(40) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE fact_sales (
    sale_id       BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_key  BIGINT UNSIGNED NOT NULL,
    product_key   BIGINT UNSIGNED NOT NULL,
    date_key      INT NOT NULL,
    store_key     BIGINT UNSIGNED NOT NULL,
    quantity      INT NOT NULL,
    revenue       DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_fact_sales_customer FOREIGN KEY (customer_key) REFERENCES dim_customer (customer_key),
    CONSTRAINT fk_fact_sales_product  FOREIGN KEY (product_key)  REFERENCES dim_product (product_key),
    CONSTRAINT fk_fact_sales_date     FOREIGN KEY (date_key)     REFERENCES dim_date (date_key),
    CONSTRAINT fk_fact_sales_store    FOREIGN KEY (store_key)    REFERENCES dim_store (store_key)
) ENGINE = InnoDB;

INSERT INTO dim_date (date_key, full_date, day_of_week, month, year) VALUES
    (20260101, '2026-01-01', 'Thursday', 1, 2026),
    (20260102, '2026-01-02', 'Friday',   1, 2026);

INSERT INTO dim_customer (natural_customer_id, full_name, country) VALUES
    (1, 'Amara Chen', 'US'), (2, 'Ben Osei', 'GH');

INSERT INTO dim_product (natural_product_id, name, category) VALUES
    (1, 'Trail Backpack 32L', 'Outdoor Gear');

INSERT INTO dim_store (name, region) VALUES
    ('Flagship Downtown', 'US-EAST');

INSERT INTO fact_sales (customer_key, product_key, date_key, store_key, quantity, revenue) VALUES
    (1, 1, 20260101, 1, 2, 168.00),
    (2, 1, 20260102, 1, 1, 84.00);


-- ============================================================
-- Verification query — run after this file to confirm every
-- table Module 15 references now exists.
-- ============================================================
SHOW TABLES;
