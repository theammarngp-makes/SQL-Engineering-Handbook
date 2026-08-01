-- ============================================================
-- Module 15, File 09 — Real-World Case Studies
-- Engine: MySQL 8.0+
-- Requires: 00_SETUP.sql already executed against this schema.
-- ============================================================

-- ------------------------------------------------------------
-- E-COMMERCE: order history + shipment tracking
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer_date
    ON orders (customer_id, order_date DESC);

CREATE UNIQUE INDEX uq_shipments_tracking_number
    ON shipments (tracking_number);

EXPLAIN
SELECT order_id, order_date, status, total_amount
FROM orders
WHERE customer_id = 1
ORDER BY order_date DESC;

-- ------------------------------------------------------------
-- BANKING: fraud velocity check + settlement reconciliation
-- ------------------------------------------------------------
CREATE INDEX idx_transactions_account_time
    ON transactions (account_id, occurred_at);

EXPLAIN
SELECT COUNT(*) FROM transactions
WHERE account_id = 1
  AND occurred_at >= '2026-01-02 00:00:00' - INTERVAL 10 MINUTE;

-- Reconciliation needs the OTHER direction of the same table —
-- a single index rarely serves both directions well.
CREATE INDEX idx_transactions_counterparty
    ON transactions (counterparty_account, amount, occurred_at);

EXPLAIN
SELECT * FROM transactions
WHERE counterparty_account = '000123456789'
  AND amount = 250.00
  AND transaction_type = 'transfer'
  AND occurred_at BETWEEN '2026-01-02 00:00:00' AND '2026-01-02 23:59:59';

-- ------------------------------------------------------------
-- HEALTHCARE: patient search, appointment conflicts, insurance
-- verification status
-- ------------------------------------------------------------
CREATE UNIQUE INDEX uq_patients_mrn ON patients (mrn);
CREATE INDEX idx_patients_lastname_dob ON patients (last_name, date_of_birth);
CREATE INDEX idx_appointments_provider_time ON appointments (provider_id, scheduled_at);

EXPLAIN
SELECT * FROM appointments
WHERE provider_id = 501
  AND scheduled_at BETWEEN '2026-01-10 00:00:00' AND '2026-01-10 23:59:59';

-- Low-selectivity column — verify with SHOW INDEX before assuming
-- an index on `status` helps (File 07).
EXPLAIN
SELECT * FROM insurance_verifications WHERE status = 'pending';

-- ------------------------------------------------------------
-- MANUFACTURING: inventory lookup, warehouse scan logging,
-- supplier performance
-- ------------------------------------------------------------
-- (sku, warehouse_id) is already the table's PRIMARY KEY per
-- 00_SETUP.sql — no additional index needed for this lookup.
EXPLAIN
SELECT quantity FROM inventory WHERE sku = 'SKU-1001' AND warehouse_id = 1;

-- inventory_movements is deliberately left with ONLY its primary
-- key — a high-write scan log per File 06's OLTP budget reasoning.
-- Do not index it further without a specific, observed, frequent
-- query that justifies the write cost.

CREATE INDEX idx_supplierdeliveries_warehouse_expected
    ON supplier_deliveries (warehouse_id, expected_at);

EXPLAIN
SELECT
    supplier_id,
    SUM(on_time) / COUNT(*) AS on_time_rate
FROM supplier_deliveries
WHERE warehouse_id = 1
  AND expected_at >= '2026-01-01 00:00:00'
GROUP BY supplier_id;

-- ------------------------------------------------------------
-- HR: payroll run
-- ------------------------------------------------------------
CREATE INDEX idx_employees_payperiod_status
    ON employees (pay_period, status);

-- PostgreSQL equivalent, partial index (MySQL has no partial index
-- support as of 8.0):
-- CREATE INDEX idx_employees_active_payperiod
--     ON employees (pay_period)
--     WHERE status = 'active';

EXPLAIN
SELECT * FROM employees
WHERE status = 'active'
  AND pay_period = '2026-01A';

-- ------------------------------------------------------------
-- RETAIL: product search + dual-range promotion filtering
-- ------------------------------------------------------------
CREATE INDEX idx_products_category_price
    ON products (category_id, price);

EXPLAIN
SELECT * FROM products
WHERE category_id = 1
  AND price BETWEEN 20.00 AND 100.00
ORDER BY popularity_score DESC;

-- Two independent range conditions — no single composite index
-- fully resolves this; category_id narrows, one range boundary
-- narrows further, the other is a post-filter.
CREATE INDEX idx_promotions_category_starts
    ON promotions (category_id, starts_at);

EXPLAIN
SELECT * FROM promotions
WHERE category_id = 3
  AND starts_at <= CURDATE()
  AND ends_at >= CURDATE();

-- ------------------------------------------------------------
-- INSURANCE: claim validation + flagged-claim investigation
-- ------------------------------------------------------------
CREATE UNIQUE INDEX uq_claims_claim_number ON claims (claim_number);
CREATE INDEX idx_claims_policy_status_filed
    ON claims (policy_id, status, filed_at);

EXPLAIN
SELECT * FROM claims
WHERE policy_id = 1
  AND status = 'flagged'
  AND filed_at BETWEEN '2026-01-01 00:00:00' AND '2026-01-31 23:59:59';

-- Optional: MySQL 8.0+ histogram, since 'flagged' is a rare value
-- within an otherwise common status distribution (File 07).
-- ANALYZE TABLE claims UPDATE HISTOGRAM ON status WITH 4 BUCKETS;

-- ------------------------------------------------------------
-- RIDE-SHARING: ride history + spatial proximity search
-- ------------------------------------------------------------
CREATE INDEX idx_rides_rider_requested
    ON rides (rider_id, requested_at DESC);

CREATE SPATIAL INDEX idx_drivers_location ON drivers (location);

EXPLAIN
SELECT driver_id
FROM drivers
WHERE is_available = TRUE
  AND ST_Distance_Sphere(location, ST_SRID(POINT(-122.42, 37.77), 4326)) < 5000;

-- ------------------------------------------------------------
-- STREAMING: covering recommendation lookup
-- ------------------------------------------------------------
CREATE INDEX idx_recommendations_user_score
    ON recommendations (user_id, score DESC, content_id);

EXPLAIN
SELECT content_id, score
FROM recommendations
WHERE user_id = 1
ORDER BY score DESC
LIMIT 20;

-- ------------------------------------------------------------
-- SAAS: tenant-first audit log indexing
-- ------------------------------------------------------------
CREATE INDEX idx_auditlog_tenant_actor_event_time
    ON audit_log (tenant_id, actor_user_id, event_type, occurred_at DESC);

EXPLAIN
SELECT * FROM audit_log
WHERE tenant_id = 1
  AND actor_user_id = 501
  AND event_type = 'record_update'
ORDER BY occurred_at DESC;

-- ------------------------------------------------------------
-- MARKETING: two indexes for two different dominant queries on
-- the same table
-- ------------------------------------------------------------
CREATE INDEX idx_touchpoints_customer_time
    ON touchpoints (customer_id, occurred_at);

CREATE INDEX idx_touchpoints_campaign_converted
    ON touchpoints (campaign_id, converted);

EXPLAIN
SELECT campaign_id, occurred_at, converted
FROM touchpoints
WHERE customer_id = 1
ORDER BY occurred_at;

EXPLAIN
SELECT
    campaign_id,
    SUM(converted) / COUNT(*) AS conversion_rate
FROM touchpoints
WHERE campaign_id = 1
GROUP BY campaign_id;

-- ------------------------------------------------------------
-- SUPPLY CHAIN: shipment tracking by warehouse + delivery window
-- (same pattern as e-commerce shipments and manufacturing
-- supplier deliveries above — included to demonstrate recognizing
-- a repeated pattern, not a new one)
-- ------------------------------------------------------------
CREATE INDEX idx_shipments_origin_delivery
    ON shipments (origin_warehouse_id, expected_delivery);

EXPLAIN
SELECT * FROM shipments
WHERE origin_warehouse_id = 10
  AND expected_delivery BETWEEN '2026-01-01' AND '2026-01-31';
