-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   07 · REAL-WORLD ANALYTICS PROJECT (CAPSTONE)
-- ============================================================================
-- Business Objective:
--   Build the full on-time delivery performance report a supply-chain VP
--   would request: shipment volume, on-time rate, and average delay, by
--   warehouse and carrier, with subtotals and a grand total, scoped to the
--   current month -- composing every technique from Topics 01-06.
--
-- Dataset Used (Logistics / Supply Chain domain):
--   warehouses (warehouse_id PK, warehouse_name)
--   carriers   (carrier_id PK, carrier_name)
--   orders     (order_id PK, warehouse_id FK, order_date)
--   shipments  (shipment_id PK, order_id FK, carrier_id FK,
--               promised_date, delivered_date)
--
-- Dialect notes: DATE_TRUNC is PostgreSQL syntax; the MySQL 8+ equivalent
-- for "first day of current month" is DATE_FORMAT(CURRENT_DATE,'%Y-%m-01').
-- GREATEST() is supported identically in both dialects.
--
-- This file is built as four progressive scenarios, each layering on the
-- previous one -- read them in order, the way a real analytics ticket
-- evolves through iteration and stakeholder review.
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 — Establish the Base Grain and Core Metrics
-- Business Context:
--   Before any subtotal or KPI composition, confirm the base report is
--   correct: shipment volume and on-time rate, at the warehouse x carrier
--   grain, for the current month. This is the foundation every later
--   scenario builds on -- get this right first.
--
-- Business Questions:
--   - How many shipments has each warehouse/carrier combination handled
--     this month?
--   - What percentage were delivered on or before the promised date?
-- ============================================================================

SELECT
    w.warehouse_name,
    c.carrier_name,
    COUNT(sh.shipment_id)                                                AS total_shipments,
    ROUND(100.0 * COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                              AND sh.delivered_date <= sh.promised_date
                             THEN 1 END)
          / NULLIF(COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                              THEN 1 END), 0), 1)                          AS on_time_pct
FROM shipments AS sh
JOIN orders     AS o  ON sh.order_id     = o.order_id
JOIN warehouses AS w  ON o.warehouse_id  = w.warehouse_id
JOIN carriers   AS c  ON sh.carrier_id   = c.carrier_id
WHERE sh.promised_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY w.warehouse_name, c.carrier_name
ORDER BY w.warehouse_name, c.carrier_name;

-- Explanation:
--   The on_time_pct denominator deliberately counts only shipments with a
--   non-NULL delivered_date -- still-in-transit shipments are excluded from
--   both the numerator and denominator, per the Edge Cases discussion in the
--   companion .md file, rather than being miscounted as either on-time or
--   late.
--
-- Engineering Notes:
--   This scenario intentionally has NO subtotal structure yet -- validating
--   the base grain and metrics against a few known shipments manually,
--   before adding ROLLUP in Scenario 2, is what prevents "confidently wrong
--   subtotals" further down the pipeline.
--
-- Optimization Notes:
--   Index shipments(order_id, carrier_id, promised_date, delivered_date)
--   and orders(warehouse_id) to support the joins, date filter, and
--   conditional counts from a minimal number of index scans.
--
-- Expected Output (illustrative):
--   warehouse_name | carrier_name | total_shipments | on_time_pct
--   Nagpur DC        | CarrierX      | 1,204             | 94.2
--   Nagpur DC        | CarrierY      | 860               | 81.5


-- ============================================================================
-- SCENARIO 2 — Add ROLLUP Subtotal Structure
-- Business Context:
--   With Scenario 1 validated, the VP's actual request -- a subtotal per
--   warehouse and one company-wide grand total -- can now be layered on top
--   using ROLLUP, per Topic 04.
--
-- Business Questions:
--   - What is the on-time rate and shipment volume per warehouse (across
--     all its carriers)?
--   - What is the company-wide grand total?
-- ============================================================================

SELECT
    COALESCE(w.warehouse_name, 'Company Total')                          AS warehouse_name,
    COALESCE(c.carrier_name,
             CASE WHEN GROUPING(w.warehouse_name) = 0
                  THEN 'Subtotal' END)                                     AS carrier_name,
    COUNT(sh.shipment_id)                                                  AS total_shipments,
    ROUND(100.0 * COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                              AND sh.delivered_date <= sh.promised_date
                             THEN 1 END)
          / NULLIF(COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                              THEN 1 END), 0), 1)                            AS on_time_pct,
    GROUPING(w.warehouse_name)                                              AS is_grand_total
FROM shipments AS sh
JOIN orders     AS o  ON sh.order_id     = o.order_id
JOIN warehouses AS w  ON o.warehouse_id  = w.warehouse_id
JOIN carriers   AS c  ON sh.carrier_id   = c.carrier_id
WHERE sh.promised_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY ROLLUP(w.warehouse_name, c.carrier_name)
ORDER BY is_grand_total, warehouse_name, GROUPING(c.carrier_name), carrier_name;

-- Explanation:
--   ROLLUP(warehouse_name, carrier_name) adds warehouse-level subtotal rows
--   (carrier_name rolled up to NULL) and one grand-total row (both columns
--   rolled up) on top of Scenario 1's exact detail rows and on_time_pct
--   logic, unchanged -- confirming the subtotal structure didn't
--   accidentally alter the base metric definition.
--   The nested CASE/COALESCE on carrier_name distinguishes a warehouse
--   subtotal ('Subtotal') from the grand total (which also shows
--   'Company Total' for warehouse_name) using GROUPING(warehouse_name).
--
-- Engineering Notes:
--   ORDER BY deliberately sorts on GROUPING() values first, so subtotal
--   and total rows land in a predictable position (after their detail
--   rows) regardless of how warehouse/carrier names alphabetize.
--
-- Optimization Notes:
--   Identical join and filter footprint to Scenario 1 -- ROLLUP adds
--   subtotal computation within the same grouped scan, not an additional
--   table scan.
--
-- Expected Output (illustrative):
--   warehouse_name  | carrier_name | total_shipments | on_time_pct | is_grand_total
--   Nagpur DC         | CarrierX      | 1,204             | 94.2          | 0
--   Nagpur DC         | CarrierY      | 860               | 81.5          | 0
--   Nagpur DC         | Subtotal      | 2,064             | 89.1          | 0
--   Company Total     | Company Total | 3,316             | 90.5          | 1


-- ============================================================================
-- SCENARIO 3 — Add the Delay KPI and a Chronic-Delay Flag
-- Business Context:
--   The VP's brief also asked for average delivery delay in days, and
--   operations wants an explicit flag for carrier/warehouse combinations
--   whose on-time rate is below the company's 90% SLA target -- turning a
--   raw number into an actionable signal, per Topic 05's KPI-composition
--   approach.
--
-- Business Questions:
--   - What is the average delivery delay, in days, per warehouse/carrier?
--   - Which combinations are below the 90% on-time SLA target?
-- ============================================================================

SELECT
    w.warehouse_name,
    c.carrier_name,
    COUNT(sh.shipment_id)                                                 AS total_shipments,
    ROUND(100.0 * COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                              AND sh.delivered_date <= sh.promised_date
                             THEN 1 END)
          / NULLIF(COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                              THEN 1 END), 0), 1)                            AS on_time_pct,
    ROUND(AVG(CASE WHEN sh.delivered_date IS NOT NULL
                   THEN GREATEST(sh.delivered_date - sh.promised_date, 0)
              END), 1)                                                       AS avg_delay_days,
    CASE
        WHEN 100.0 * COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                                 AND sh.delivered_date <= sh.promised_date
                                THEN 1 END)
             / NULLIF(COUNT(CASE WHEN sh.delivered_date IS NOT NULL
                                 THEN 1 END), 0) < 90.0
        THEN 'BELOW SLA'
        ELSE 'MEETS SLA'
    END                                                                       AS sla_status
FROM shipments AS sh
JOIN orders     AS o  ON sh.order_id     = o.order_id
JOIN warehouses AS w  ON o.warehouse_id  = w.warehouse_id
JOIN carriers   AS c  ON sh.carrier_id   = c.carrier_id
WHERE sh.promised_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY w.warehouse_name, c.carrier_name
HAVING COUNT(sh.shipment_id) >= 20   -- exclude low-volume combinations from the SLA flag
ORDER BY on_time_pct ASC;

-- Explanation:
--   avg_delay_days uses GREATEST(delivered_date - promised_date, 0) so an
--   early delivery (a negative difference) floors to zero delay rather than
--   offsetting genuinely late shipments in the average -- an early delivery
--   is not "negative lateness" for this metric's purpose.
--   HAVING COUNT(sh.shipment_id) >= 20 filters the GROUPED result (correctly
--   using HAVING, not WHERE, since it depends on an aggregate) to exclude
--   low-volume combinations from the SLA flag, directly addressing the
--   companion .md file's Edge Cases warning about misleading rates on small
--   samples.
--
-- Engineering Notes:
--   The sla_status CASE expression repeats the on_time_pct calculation
--   rather than referencing its alias, because most SQL engines (including
--   MySQL and PostgreSQL in standard evaluation order) do not allow a
--   SELECT-list alias to be reused within the same SELECT list -- a common,
--   easy-to-miss constraint when composing several derived metrics together.
--
-- Optimization Notes:
--   Consider computing on_time_pct once in a CTE and referencing it in both
--   the SELECT list and the sla_status CASE expression in a later revision,
--   to avoid the duplicated calculation shown here -- an explicit tradeoff
--   between query length and computation reuse worth discussing in a real
--   code review.
--
-- Expected Output (illustrative):
--   warehouse_name | carrier_name | total_shipments | on_time_pct | avg_delay_days | sla_status
--   Nagpur DC        | CarrierY      | 860               | 81.5          | 1.4              | BELOW SLA
--   Pune DC          | CarrierY      | 512               | 85.0          | 1.1              | BELOW SLA
--   Nagpur DC        | CarrierX      | 1,204             | 94.2          | 0.3              | MEETS SLA


-- ============================================================================
-- SCENARIO 4 — Final Dashboard-Ready Assembly
-- Business Context:
--   Combine Scenario 2's ROLLUP subtotal structure with Scenario 3's delay
--   and SLA-status KPIs into the single, final query that gets handed to the
--   BI tool as the actual dashboard panel -- the complete capstone
--   deliverable.
--
-- Business Questions:
--   - The full VP brief, in one query: volume, on-time rate, and average
--     delay by warehouse and carrier, with subtotals and a grand total.
-- ============================================================================

WITH monthly_shipments AS (
    SELECT
        w.warehouse_name,
        c.carrier_name,
        sh.shipment_id,
        sh.delivered_date,
        sh.promised_date
    FROM shipments AS sh
    JOIN orders     AS o ON sh.order_id    = o.order_id
    JOIN warehouses AS w ON o.warehouse_id = w.warehouse_id
    JOIN carriers   AS c ON sh.carrier_id  = c.carrier_id
    WHERE sh.promised_date >= DATE_TRUNC('month', CURRENT_DATE)
)
SELECT
    COALESCE(warehouse_name, 'Company Total')                             AS warehouse,
    COALESCE(carrier_name,
             CASE WHEN GROUPING(warehouse_name) = 0
                  THEN 'Subtotal' END)                                      AS carrier,
    COUNT(shipment_id)                                                      AS total_shipments,
    ROUND(100.0 * COUNT(CASE WHEN delivered_date IS NOT NULL
                              AND delivered_date <= promised_date
                             THEN 1 END)
          / NULLIF(COUNT(CASE WHEN delivered_date IS NOT NULL
                              THEN 1 END), 0), 1)                             AS on_time_pct,
    ROUND(AVG(CASE WHEN delivered_date IS NOT NULL
                   THEN GREATEST(delivered_date - promised_date, 0)
              END), 1)                                                        AS avg_delay_days,
    GROUPING(warehouse_name)                                                   AS is_grand_total,
    CURRENT_TIMESTAMP                                                          AS report_generated_at
FROM monthly_shipments
GROUP BY ROLLUP(warehouse_name, carrier_name)
ORDER BY is_grand_total, warehouse, GROUPING(carrier_name), carrier;

-- Explanation:
--   The CTE pre-joins and pre-filters to exactly the rows this report
--   needs, once -- keeping the final ROLLUP query itself focused purely on
--   aggregation, matching Topic 06's guidance to keep dashboard queries as
--   narrow and readable as their one job requires.
--   report_generated_at is included per Topic 06's best practice of
--   timestamping dashboard panels so viewers can judge data freshness at a
--   glance.
--
-- Engineering Notes:
--   This is the query that would actually be scheduled and materialized
--   into a summary table for the operations dashboard -- Scenarios 1-3
--   existed to validate each piece independently before assembling this
--   final version, exactly the way a real analytics ticket is built and
--   reviewed incrementally rather than delivered as one untested query.
--
-- Optimization Notes:
--   If this panel refreshes more than a few times per day, materialize its
--   output into a summary table on a schedule rather than recomputing the
--   full join, conditional aggregation, and ROLLUP live on every dashboard
--   page load.
--
-- Expected Output (illustrative):
--   warehouse       | carrier   | total_shipments | on_time_pct | avg_delay_days | is_grand_total | report_generated_at
--   Nagpur DC         | CarrierX   | 1,204             | 94.2          | 0.3              | 0                | 2026-07-13 09:02:11
--   Nagpur DC         | CarrierY   | 860               | 81.5          | 1.4              | 0                | 2026-07-13 09:02:11
--   Nagpur DC         | Subtotal   | 2,064             | 89.1          | 0.8              | 0                | 2026-07-13 09:02:11
--   Company Total     | Company Total | 3,316          | 90.5          | 0.7              | 1                | 2026-07-13 09:02:11
