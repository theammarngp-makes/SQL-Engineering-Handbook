-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 08 — Real-World Case Studies
-- Business Obj: Build a full layered View architecture (raw → staging →
--               reporting) for SaaS MRR and churn reporting, plus a
--               scheduled "materialized view equivalent" for MySQL.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql first (uses shared schema
--               plus new SaaS tables defined below).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Additional schema for this case study
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS saas_subscriptions;
DROP TABLE IF EXISTS saas_customers;

CREATE TABLE saas_customers (
    customer_id   INT PRIMARY KEY,
    company_name  VARCHAR(120) NOT NULL,
    signup_date   DATE NOT NULL
);

CREATE TABLE saas_subscriptions (
    subscription_id  INT PRIMARY KEY,
    customer_id       INT NOT NULL,
    status            VARCHAR(30) NOT NULL,   -- inconsistent casing on purpose
    mrr_amount        DECIMAL(10,2),          -- nullable on purpose (data quality issue)
    plan_started_at   DATE NOT NULL,
    plan_ended_at     DATE,
    CONSTRAINT fk_sub_customer FOREIGN KEY (customer_id) REFERENCES saas_customers(customer_id)
);

INSERT INTO saas_customers VALUES
    (1, 'Northlight Analytics', '2023-05-01'),
    (2, 'Cobalt Freight Systems', '2023-08-14'),
    (3, 'Havenwood Retail', '2024-01-09');

INSERT INTO saas_subscriptions VALUES
    (2001, 1, 'active',    499.00, '2023-05-01', NULL),
    (2002, 2, ' Trialing', NULL,   '2024-02-01', NULL),
    (2003, 3, 'ACTIVE',    899.00, '2024-01-09', NULL),
    (2004, 1, 'cancelled', 499.00, '2023-05-01', '2024-03-01');

-- Business Scenario:
-- Finance needs MRR excluding trialing/cancelled subscriptions. Product
-- needs a churn cohort view that INCLUDES trialing accounts (to measure
-- trial-to-paid conversion loss). Same raw data, two governed definitions.

-- -----------------------------------------------------------------------------
-- Layer 2 — Staging View: normalize, no business rules yet
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_stg_subscriptions AS
SELECT
    subscription_id,
    customer_id,
    UPPER(TRIM(status)) AS status,
    COALESCE(mrr_amount, 0) AS mrr_amount,
    plan_started_at,
    plan_ended_at
FROM saas_subscriptions;

SELECT * FROM vw_stg_subscriptions;

-- Explanation:
-- UPPER(TRIM(status)) fixes the ' Trialing' / 'active' / 'ACTIVE'
-- inconsistency once, here, so no reporting View downstream has to repeat
-- this cleaning logic.

-- -----------------------------------------------------------------------------
-- Layer 3 — Reporting View: Finance MRR definition
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_mrr_by_month AS
SELECT
    DATE_FORMAT(plan_started_at, '%Y-%m') AS revenue_month,
    SUM(mrr_amount) AS total_mrr
FROM vw_stg_subscriptions
WHERE status NOT IN ('TRIALING', 'CANCELLED')
GROUP BY DATE_FORMAT(plan_started_at, '%Y-%m');

SELECT * FROM vw_mrr_by_month ORDER BY revenue_month;

-- -----------------------------------------------------------------------------
-- Layer 3 — Reporting View: Product churn cohort definition (divergent rule)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_churn_cohort AS
SELECT
    subscription_id,
    customer_id,
    status,
    plan_started_at,
    plan_ended_at,
    CASE WHEN plan_ended_at IS NOT NULL THEN 1 ELSE 0 END AS is_churned
FROM vw_stg_subscriptions;   -- deliberately includes TRIALING, unlike vw_mrr_by_month

SELECT * FROM vw_churn_cohort;

-- Engineering Notes:
-- Both reporting Views read from the SAME staging View but apply
-- DIFFERENT, deliberately documented business rules. This is correct
-- design, not duplication — the comment on each View is what prevents it
-- from becoming a silent inconsistency.

-- -----------------------------------------------------------------------------
-- "Materialized View equivalent" — MySQL has no native materialized view,
-- so the production pattern is a physical summary table + scheduled EVENT.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tbl_mrr_snapshot (
    revenue_month VARCHAR(7) PRIMARY KEY,
    total_mrr DECIMAL(14,2) NOT NULL,
    refreshed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Enable the event scheduler (typically a server-level/DBA setting in prod)
-- SET GLOBAL event_scheduler = ON;

DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_refresh_mrr_snapshot
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    REPLACE INTO tbl_mrr_snapshot (revenue_month, total_mrr)
    SELECT revenue_month, total_mrr FROM vw_mrr_by_month;
END$$
DELIMITER ;

-- Manual one-time refresh for this lab (since the EVENT runs hourly):
REPLACE INTO tbl_mrr_snapshot (revenue_month, total_mrr)
SELECT revenue_month, total_mrr FROM vw_mrr_by_month;

SELECT * FROM tbl_mrr_snapshot;

-- Performance Notes:
-- Dashboards reading tbl_mrr_snapshot instead of vw_mrr_by_month directly
-- get O(1) read cost regardless of how expensive the underlying aggregation
-- is — the tradeoff is up to 1 hour of staleness, which is the same
-- freshness/speed tradeoff a Postgres MATERIALIZED VIEW makes explicit via
-- its REFRESH command, just handled manually here.

-- Common Mistakes:
-- Porting a Postgres tutorial's "CREATE MATERIALIZED VIEW" syntax directly
-- into a MySQL migration script — it's not valid MySQL syntax and fails
-- immediately with a syntax error.

-- Interview Insight:
-- A strong candidate, when asked "does MySQL support materialized views,"
-- doesn't just say "no" — they immediately describe the summary-table +
-- scheduled-refresh pattern as the practical equivalent, showing they
-- understand the underlying tradeoff, not just a trivia fact.

-- Further Challenge:
-- Extend vw_churn_cohort into a monthly cohort retention View (customers
-- retained N months after plan_started_at), and decide, with justification,
-- whether it belongs as a live View or a scheduled summary table given its
-- likely query pattern (ad hoc analyst exploration vs. daily dashboard).
