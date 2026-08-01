-- ============================================================
-- Module 15, File 10 — Index Maintenance, Redundancy & Myths
-- Engine: MySQL 8.0+
-- Requires: 00_SETUP.sql already executed against this schema,
-- AND 09_REAL_WORLD_CASE_STUDIES.sql run first — this file
-- references indexes that file creates (idx_transactions_account_time,
-- idx_orders_customer_date, idx_claims_policy_status_filed).
-- ============================================================

-- ------------------------------------------------------------
-- 1. Check fragmentation / reclaimable space for a table
-- ------------------------------------------------------------
SELECT
    table_name,
    data_length,
    data_free,
    ROUND(data_free / NULLIF(data_length, 0) * 100, 2) AS pct_reclaimable
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name = 'transactions';

-- ------------------------------------------------------------
-- 2. Rebuild a table to remove fragmentation
--    (maintenance-window operation — locks/copies the table)
-- ------------------------------------------------------------
OPTIMIZE TABLE transactions;

-- ------------------------------------------------------------
-- 3. Refresh statistics separately from physical maintenance
--    (cheaper, does not rebuild pages)
-- ------------------------------------------------------------
ANALYZE TABLE transactions;

-- ------------------------------------------------------------
-- 4. PostgreSQL equivalents (run on PostgreSQL, not MySQL)
-- ------------------------------------------------------------
-- VACUUM (ANALYZE) transactions;
-- REINDEX INDEX CONCURRENTLY idx_transactions_account_time;
-- SELECT relname, n_live_tup, n_dead_tup,
--        round(n_dead_tup::numeric / NULLIF(n_live_tup,0) * 100, 2) AS pct_dead
-- FROM pg_stat_user_tables
-- WHERE relname = 'transactions';

-- ------------------------------------------------------------
-- 5. Redundant index detection (MySQL 8.0+ sys schema)
-- ------------------------------------------------------------
SELECT *
FROM sys.schema_redundant_indexes
WHERE table_schema = DATABASE();

-- ------------------------------------------------------------
-- 6. Demonstrate a genuinely redundant composite index
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer_only_demo ON orders (customer_id);
-- idx_orders_customer_date (customer_id, order_date DESC), created in
-- File 09, already fully covers any query idx_orders_customer_only_demo
-- could serve — confirm via the redundant-index view above, then drop:
SELECT * FROM sys.schema_redundant_indexes WHERE table_schema = DATABASE();
DROP INDEX idx_orders_customer_only_demo ON orders;

-- ------------------------------------------------------------
-- 7. Demonstrate a NON-redundant "gap" composite index
-- ------------------------------------------------------------
-- claims has idx_claims_policy_status_filed (policy_id, status, filed_at)
-- from File 09. An index on (policy_id, filed_at) — skipping status —
-- is NOT redundant against it, because filed_at isn't leftmost-reachable
-- without status in the existing index:
CREATE INDEX idx_claims_policy_filed_demo ON claims (policy_id, filed_at);

EXPLAIN
SELECT * FROM claims
WHERE policy_id = 1
  AND filed_at BETWEEN '2026-01-01 00:00:00' AND '2026-01-31 23:59:59';
-- Compare the key/key_len used here against a query that also filters
-- status — the two indexes genuinely serve different query shapes.

DROP INDEX idx_claims_policy_filed_demo ON claims;

-- ------------------------------------------------------------
-- 8. Myth-testing: "using an index" vs. "is fast"
-- ------------------------------------------------------------
-- idx_transactions_account_time exists from File 09. A query that
-- uses it but still requires a downstream sort/temp step shows the
-- gap between "uses an index" and "is optimized":
EXPLAIN
SELECT account_id, COUNT(*) AS txn_count
FROM transactions
WHERE account_id = 1
GROUP BY account_id
ORDER BY txn_count DESC;
-- Look for "Using temporary" / "Using filesort" in Extra even though
-- `key` shows an index was used for the WHERE clause.

-- ------------------------------------------------------------
-- 9. Fillfactor (PostgreSQL syntax — MySQL InnoDB has no direct
--    per-index equivalent)
-- ------------------------------------------------------------
-- CREATE INDEX idx_transactions_account_time_ff
--     ON transactions (account_id, occurred_at)
--     WITH (fillfactor = 80);
