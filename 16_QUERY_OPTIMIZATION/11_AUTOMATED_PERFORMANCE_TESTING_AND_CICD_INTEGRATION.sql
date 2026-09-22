-- ============================================================================
-- MODULE 16, LESSON 11 : AUTOMATED PERFORMANCE TESTING & CI/CD INTEGRATION
-- ============================================================================
-- SETUP: Run 00_Schema.sql first. Adds supporting indexes on `transactions`.
-- ============================================================================

-- idx_transactions_employee exists separately so the FK constraint still
-- has a supporting index after idx_transactions_emp_date is dropped --
-- exactly how a real schema "still works" after a regression-causing
-- migration; nothing errors, it just gets slower.
CREATE INDEX idx_transactions_employee ON transactions (processed_by_emp_id);
CREATE INDEX idx_transactions_emp_date ON transactions (processed_by_emp_id, transaction_date);

-- QUERY UNDER TEST: fraud-review workbench "reviewer's 10 most recent
-- processed transactions" lookup. This is the exact query
-- ci/run_benchmark.sh times and plan-checks.
SELECT transaction_id, transaction_date, transaction_status
FROM transactions
WHERE processed_by_emp_id = 42
ORDER BY transaction_date DESC
LIMIT 10;

-- HEALTHY BASELINE PLAN CHECK
EXPLAIN
SELECT transaction_id, transaction_date, transaction_status
FROM transactions
WHERE processed_by_emp_id = 42
ORDER BY transaction_date DESC
LIMIT 10;

-- REGRESSION SIMULATION: what an "unrelated" migration can do
-- Uncomment to reproduce the lesson's "Business Motivation" incident.
-- DROP INDEX idx_transactions_emp_date ON transactions;
--
-- EXPLAIN
-- SELECT transaction_id, transaction_date, transaction_status
-- FROM transactions
-- WHERE processed_by_emp_id = 42
-- ORDER BY transaction_date DESC
-- LIMIT 10;
--
-- EXPLAIN / COST ANALYSIS DISCUSSION
-- Dropping idx_transactions_emp_date doesn't error -- idx_transactions_employee
-- still covers the filter. What breaks is ORDER BY: the engine can find
-- rows quickly but can't read them pre-sorted, so it adds an explicit
-- sort -- `Using filesort` in MySQL/MariaDB, a Sort node above an Index
-- Scan in Postgres. Nothing errors, the query still "works," and it
-- silently gets slower as history grows. This plan shape is exactly what
-- a CI gate should assert on directly (plan-node type is deterministic;
-- wall-clock latency on a shared runner is not).

-- INTERVIEW INSIGHT
-- Q: "A regression shipped because the PR that caused it touched a
--     different table. How would you prevent this?"
-- A: The failure is a missing automated check, not a missing code review.
--    A CI gate re-running this EXPLAIN assertion on every PR
--    (github-actions-perf-gate.yml) turns an invisible cross-cutting
--    regression into a blocked-merge failure with a specific message.

-- FURTHER EXPERIMENTS
-- 1. Run ci/run_benchmark.sh locally to see the healthy baseline.
-- 2. Drop idx_transactions_emp_date, re-run, confirm a plan-shape failure.
-- 3. Extend with a compliance report query (status + date range) and
--    design a performance budget for it.
