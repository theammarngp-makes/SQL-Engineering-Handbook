-- =============================================================================
-- Module      : 14 — Views
-- Topic       : 07 — View Performance
-- Business Obj: Diagnose MERGE vs TEMPTABLE behavior across the Views built
--               so far in this module using EXPLAIN.
-- Prerequisite: Run 01_INTRODUCTION_TO_VIEWS.sql through 06_* first.
-- =============================================================================

-- Business Scenario:
-- Before promoting vw_completed_order_revenue and vw_pending_orders to a
-- production dashboard and an application hot path respectively, the
-- platform team must verify their execution characteristics.

-- Production Solution — EXPLAIN a MERGE-eligible, single-table, filtered View
EXPLAIN SELECT * FROM vw_pending_orders WHERE customer_id = 4;

-- Expected: no "Using temporary" in Extra — this View is MERGE-eligible
-- (single table, no aggregation, no DISTINCT) so the WHERE customer_id = 4
-- filter is folded directly into a scan/lookup against sales_orders,
-- exactly as if you'd written the WHERE clause against the base table.

-- Production Solution — EXPLAIN an aggregating, TEMPTABLE-forced View
EXPLAIN SELECT * FROM vw_completed_order_revenue WHERE region = 'APAC';

-- Expected: "Using temporary" (and often "Using filesort") appears in
-- Extra — GROUP BY forces TEMPTABLE materialization. Critically, the
-- region = 'APAC' filter is NOT pushed into the View's own WHERE o.status
-- = 'COMPLETED' clause before aggregation — MySQL aggregates ALL customers
-- across ALL regions first, materializes that full result, THEN applies
-- the outer region filter.

-- Explanation:
-- This is the single most important performance fact in this module: an
-- outer WHERE against a TEMPTABLE-algorithm View does not reduce the work
-- the View itself does. At small scale this is invisible; at millions of
-- rows this is the difference between a dashboard query and a timeout.

-- Demonstrating algorithm hints (advisory only)
CREATE OR REPLACE ALGORITHM = MERGE VIEW vw_pending_orders_merge_hint AS
SELECT order_id, customer_id, order_date, status
FROM sales_orders
WHERE status = 'PENDING';

EXPLAIN SELECT * FROM vw_pending_orders_merge_hint WHERE customer_id = 4;
-- Succeeds as MERGE — the query shape supports it.

-- This ALGORITHM=MERGE hint is silently overridden by the optimizer,
-- because GROUP BY structurally disqualifies merging:
CREATE OR REPLACE ALGORITHM = MERGE VIEW vw_revenue_merge_attempt AS
SELECT c.region, SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM sales_customers AS c
INNER JOIN sales_orders AS o ON o.customer_id = c.customer_id
INNER JOIN sales_order_items AS oi ON oi.order_id = o.order_id
GROUP BY c.region;

EXPLAIN SELECT * FROM vw_revenue_merge_attempt WHERE region = 'APAC';
-- Still shows "Using temporary" despite the ALGORITHM=MERGE hint —
-- confirming the hint is advisory, not a guarantee.

-- Demonstrating nested-View TEMPTABLE compounding
-- (rebuilding the Module 05 chain for direct comparison here)
EXPLAIN SELECT * FROM vw_monthly_revenue_growth;
-- This queries a View (aggregation + window function) built on another
-- View (aggregation + window function) — expect TEMPTABLE behavior
-- compounding across both layers when inspected with EXPLAIN FORMAT=TREE.

EXPLAIN FORMAT=TREE SELECT * FROM vw_monthly_revenue_growth;
-- The tree output shows each materialization step explicitly — useful for
-- diagnosing exactly which layer of a nested View chain is expensive.

-- Performance Notes:
-- A flattened, single-query equivalent (see 05_BUSINESS_REPORTING_VIEWS.sql
-- vw_monthly_revenue_growth_flat) avoids one layer of View-to-View
-- materialization, though the base GROUP BY + window function still forces
-- TEMPTABLE at some level regardless of nesting.

-- Common Mistakes:
-- Concluding "this View is fast" from testing against a few hundred rows
-- without ever running EXPLAIN, or testing at production data volume.

-- Alternative Solution — when a View's aggregation cost genuinely can't be
-- reduced further and the data changes infrequently, the correct move is
-- OUT of Views entirely: a physical summary table refreshed on a schedule
-- (via an EVENT or ETL job), trading real-time accuracy for read speed:
CREATE TABLE IF NOT EXISTS tbl_monthly_revenue_snapshot (
    revenue_month VARCHAR(7) PRIMARY KEY,
    monthly_revenue DECIMAL(14,2) NOT NULL,
    refreshed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- Refresh pattern (run on a schedule, not per-request):
-- REPLACE INTO tbl_monthly_revenue_snapshot (revenue_month, monthly_revenue)
-- SELECT revenue_month, monthly_revenue FROM vw_monthly_revenue_trend;

-- Interview Insight:
-- "Would a View ever make a query faster?" is a deliberately loaded
-- interview question — the correct answer is an unambiguous no, and the
-- strong follow-up is explaining the MERGE/TEMPTABLE distinction and the
-- summary-table alternative unprompted.

-- Further Challenge:
-- EXPLAIN both vw_customer_segment_summary (Module 05) and
-- vw_salary_bands (Module 04); predict which columns, if any, could
-- benefit from a base-table index once you reach Module 15, given that
-- indexing cannot change MERGE-vs-TEMPTABLE algorithm selection but can
-- still reduce the cost of the underlying scan.
