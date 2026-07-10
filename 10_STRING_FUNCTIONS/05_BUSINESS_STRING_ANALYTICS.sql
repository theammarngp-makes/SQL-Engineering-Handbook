-- ============================================================
-- Module      : 10_STRING_FUNCTIONS
-- Topic       : 05_BUSINESS_STRING_ANALYTICS
-- Objective   : Combine cleaning, extraction, and transformation
--               into end-to-end business reports grouped on
--               derived string dimensions.
-- Dialect     : ANSI SQL, verified against PostgreSQL and MySQL 8+
-- Dataset     : shipments
-- ============================================================

-- ------------------------------------------------------------
-- Reference schema (for context only)
-- ------------------------------------------------------------
-- shipments (shipment_id INT PK, tracking_number VARCHAR(30),
--            delivery_days INT, warehouse_label VARCHAR(50))
--
-- tracking_number format: "CARRIER-REGION-SEQUENCE"
--   e.g. "FEDX-EU-88213"  (may contain inconsistent whitespace/casing)


-- ============================================================
-- SCENARIO 1 — Carrier performance report (clean, then group)
-- ============================================================
-- Business Context:
--   Operations leadership wants a weekly report of shipment
--   volume and average delivery time per carrier. tracking_number
--   is the only source of carrier identity; it has known
--   whitespace and casing inconsistencies from multiple
--   warehouse-scanning systems feeding the table.

WITH cleaned_shipments AS (
    SELECT
        shipment_id,
        delivery_days,
        UPPER(TRIM(SUBSTRING_INDEX(tracking_number, '-', 1))) AS carrier_code
    FROM shipments
)
SELECT
    carrier_code,
    COUNT(*)                       AS shipment_count,
    ROUND(AVG(delivery_days), 1)   AS avg_delivery_days
FROM cleaned_shipments
GROUP BY carrier_code
ORDER BY shipment_count DESC;

-- Engineering Notes:
--   The CTE computes the cleaned carrier_code exactly once; the
--   outer query groups on the CTE's already-clean column rather
--   than repeating the extraction expression in SELECT, GROUP BY,
--   and ORDER BY. This is the pattern recommended in the topic's
--   Best Practices section, specifically to avoid the "cleaned in
--   SELECT but not in GROUP BY" defect class.
--
-- Performance Notes:
--   GROUP BY on the CTE's derived column still cannot use an
--   index on the underlying tracking_number column — expected for
--   a periodic report. If this report runs daily against a large
--   shipments table, carrier_code should be promoted to a stored,
--   indexed column populated at write time.
--
-- Expected Output (sample):
--   carrier_code | shipment_count | avg_delivery_days
--   FEDX           | 1,204            | 3.2
--   UPS             | 987               | 2.9


-- ============================================================
-- SCENARIO 2 — Isolating malformed tracking numbers before reporting
-- ============================================================
-- Business Context:
--   Before trusting Scenario 1's report, data quality needs to
--   confirm that every tracking_number actually contains the
--   expected two delimiters (three segments). Records that don't
--   would otherwise silently fold into an incorrect carrier group.

SELECT
    shipment_id,
    tracking_number
FROM shipments
WHERE
    -- A well-formed tracking number has exactly 2 dashes.
    -- CHAR_LENGTH difference before/after removing dashes counts them.
    (CHAR_LENGTH(tracking_number) - CHAR_LENGTH(REPLACE(tracking_number, '-', ''))) <> 2;

-- Engineering Notes:
--   Counting delimiter occurrences via a length-difference trick
--   (original length minus length-with-delimiter-removed) is a
--   standard portable pattern for engines without a native
--   "count occurrences" function. Records failing this check
--   should be excluded from Scenario 1's report and routed to a
--   data-quality worklist, not silently aggregated.
--
-- Performance Notes:
--   Two REPLACE()/CHAR_LENGTH() calls per row; acceptable for a
--   pre-report validation sweep, not intended for high-frequency
--   execution.
--
-- Expected Output (sample):
--   shipment_id | tracking_number
--   77213         | FEDX88213         (missing both delimiters)
--   77490         | FEDX-EU-EXTRA-88 (one delimiter too many)


-- ============================================================
-- SCENARIO 3 — Regional shipment volume report
-- ============================================================
-- Business Context:
--   Regional operations managers each want a filtered view of
--   shipment counts for their own region, extracted as the middle
--   segment of tracking_number.

WITH cleaned_shipments AS (
    SELECT
        shipment_id,
        UPPER(TRIM(
            SUBSTRING_INDEX(SUBSTRING_INDEX(tracking_number, '-', 2), '-', -1)
        )) AS region_code
    FROM shipments
)
SELECT
    region_code,
    COUNT(*) AS shipment_count
FROM cleaned_shipments
GROUP BY region_code
ORDER BY shipment_count DESC;

-- Engineering Notes:
--   Reuses the nested SUBSTRING_INDEX() "middle segment" pattern
--   introduced in Topic 02, now wrapped in TRIM()/UPPER() before
--   grouping — directly applying this topic's central lesson:
--   extraction alone is not sufficient input to a GROUP BY.
--
-- Performance Notes:
--   Equivalent cost profile to Scenario 1; same materialization
--   recommendation applies if run frequently.
--
-- Expected Output (sample):
--   region_code | shipment_count
--   EU            | 2,110
--   NA            | 1,876


-- ============================================================
-- SCENARIO 4 — Formatted carrier performance summary for email
-- ============================================================
-- Business Context:
--   The weekly carrier report from Scenario 1 is also distributed
--   as a plain-text email to operations leadership, requiring
--   fixed-width columns for legible monospace rendering.

WITH cleaned_shipments AS (
    SELECT
        shipment_id,
        delivery_days,
        UPPER(TRIM(SUBSTRING_INDEX(tracking_number, '-', 1))) AS carrier_code
    FROM shipments
),
carrier_summary AS (
    SELECT
        carrier_code,
        COUNT(*)                     AS shipment_count,
        ROUND(AVG(delivery_days), 1) AS avg_delivery_days
    FROM cleaned_shipments
    GROUP BY carrier_code
)
SELECT
    CONCAT(
        RPAD(carrier_code, 8, ' '),
        RPAD(CAST(shipment_count AS CHAR), 10, ' '),
        LPAD(CAST(avg_delivery_days AS CHAR), 6, ' ')
    ) AS report_line
FROM carrier_summary
ORDER BY shipment_count DESC;

-- Engineering Notes:
--   RPAD() left-aligns the text (carrier_code) and count columns
--   as is conventional for plain-text tabular reports, while
--   LPAD() right-aligns the numeric average column — this mixed
--   alignment mirrors standard fixed-width report formatting
--   conventions (text left-aligned, numbers right-aligned) and is
--   a deliberate formatting choice, not an inconsistency.
--
-- Performance Notes:
--   This is purely a presentation-layer transformation applied to
--   an already-aggregated, small result set (one row per carrier)
--   — cost is negligible regardless of underlying shipments table
--   size.
--
-- Expected Output (sample):
--   report_line
--   "FEDX    1204       3.2"
--   "UPS     987         2.9"
-- ============================================================
