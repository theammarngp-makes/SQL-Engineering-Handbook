-- ============================================================
-- Module      : 10_STRING_FUNCTIONS
-- Topic       : 02_STRING_SEARCH_AND_EXTRACTION
-- Objective   : Locate substrings, apply pattern matching, and
--               extract structured values from composite text
--               fields (emails, SKUs, tracking numbers).
-- Dialect     : ANSI SQL, verified against PostgreSQL and MySQL 8+
-- Dataset     : customers, orders, products
-- ============================================================

-- ------------------------------------------------------------
-- Reference schema (for context only)
-- ------------------------------------------------------------
-- customers (customer_id INT PK, customer_email VARCHAR(150))
-- products  (product_id INT PK, sku VARCHAR(30), product_name VARCHAR(150))
-- orders    (order_id INT PK, customer_id INT FK, tracking_number VARCHAR(30))


-- ============================================================
-- SCENARIO 1 — Classifying customer accounts by email domain
-- ============================================================
-- Business Context:
--   Marketing wants to segment the customer base into corporate
--   vs. personal email accounts to prioritize B2B outreach
--   campaigns differently from B2C ones.

-- Question: Extract each customer's email domain and classify
--           it against known free-email providers.
SELECT
    customer_email,
    SUBSTRING_INDEX(customer_email, '@', -1)   AS email_domain,
    CASE
        WHEN customer_email LIKE '%@gmail.com'
          OR customer_email LIKE '%@yahoo.com'
          OR customer_email LIKE '%@outlook.com'
          OR customer_email LIKE '%@hotmail.com'
            THEN 'Personal'
        ELSE 'Likely Corporate'
    END                                         AS account_classification
FROM customers;

-- Engineering Notes:
--   SUBSTRING_INDEX(email, '@', -1) is used rather than -1 being
--   confused with `1` (a frequent off-by-argument bug): count = 1
--   returns everything BEFORE the first delimiter (the local
--   part); count = -1 returns everything AFTER the last delimiter
--   (the domain) — this query needs the latter.
--
-- Performance Notes:
--   The CASE expression's LIKE conditions use trailing-anchored
--   patterns (`'%@gmail.com'`), which still requires a full scan
--   here since the wildcard is leading. For a customer table in
--   the millions of rows, this classification should be
--   materialized into a column and refreshed on write rather than
--   computed on every report run.
--
-- Expected Output (sample):
--   customer_email              | email_domain | account_classification
--   j.martinez@gmail.com         | gmail.com     | Personal
--   procurement@retailcorp.com   | retailcorp.com| Likely Corporate


-- ============================================================
-- SCENARIO 2 — Validating basic email structure
-- ============================================================
-- Business Context:
--   A batch import from a discontinued CRM introduced malformed
--   email addresses (missing '@', trailing garbage characters).
--   Before the marketing team sends a campaign, these need to be
--   flagged for manual review rather than causing bounced sends.

-- Question: Flag any customer whose email does not contain an
--           '@' character at all.
SELECT
    customer_id,
    customer_email
FROM customers
WHERE LOCATE('@', customer_email) = 0;

-- Engineering Notes:
--   LOCATE() returning 0 (not NULL) on a non-match is exactly why
--   this check uses `= 0` rather than `IS NULL` — a common bug is
--   writing `WHERE LOCATE('@', customer_email) IS NULL`, which
--   will never match and silently lets malformed rows through.
--   This is a minimal structural check, not full email validation
--   — see Topic 04 for a more complete validation pattern.
--
-- Performance Notes:
--   LOCATE() applied to every row in a WHERE clause forces a full
--   table scan; acceptable for a one-time data-quality sweep, but
--   this check should move into an application-layer validation
--   rule (e.g., a CHECK constraint or regex validation on insert)
--   rather than being re-run repeatedly against a large live table.
--
-- Expected Output (sample):
--   customer_id | customer_email
--   4471         | j.martinez.gmail.com


-- ============================================================
-- SCENARIO 3 — Extracting product category from SKU
-- ============================================================
-- Business Context:
--   Product SKUs are structured as CATEGORY-SUBCATEGORY-SEQUENCE
--   (e.g., "ELEC-TV-4521"). The category is not stored as its own
--   column; the merchandising team has relied on this SKU
--   convention since before the current product catalog system
--   was built, and a dedicated category report needs to derive it
--   directly from the SKU.

-- Question: Extract the category segment from each product's SKU.
SELECT
    sku,
    product_name,
    SUBSTRING_INDEX(sku, '-', 1)      AS category_code
FROM products;

-- Question: Extract the subcategory segment (the middle piece)
--           from each product's SKU.
SELECT
    sku,
    product_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(sku, '-', 2), '-', -1) AS subcategory_code
FROM products;

-- Engineering Notes:
--   The subcategory extraction nests SUBSTRING_INDEX() twice:
--   the inner call trims everything after the second delimiter,
--   the outer call then takes everything after the (new) last
--   delimiter — the standard pattern for extracting a "middle"
--   segment from a delimited string in engines without native
--   split-to-array support.
--   This entire approach is fragile if SKU format ever changes;
--   it is documented here as a bridge solution, with a
--   recommendation (see Production Considerations) to migrate
--   category to a first-class column.
--
-- Performance Notes:
--   Nested SUBSTRING_INDEX() calls are still O(1) per row and
--   cheap at typical catalog sizes (tens of thousands of SKUs),
--   but should not be used as a join key without materializing
--   the result — recomputing it on both sides of a JOIN condition
--   defeats index usage entirely.
--
-- Production Considerations:
--   This pattern is a strong candidate for a generated/computed
--   column (`category_code GENERATED ALWAYS AS (...) STORED`)
--   where supported, so the extraction runs once at write time
--   instead of on every read.
--
-- Expected Output (sample):
--   sku            | category_code | subcategory_code
--   ELEC-TV-4521    | ELEC           | TV
--   HOME-KITCH-0092 | HOME           | KITCH


-- ============================================================
-- SCENARIO 4 — Parsing carrier and region from tracking numbers
-- ============================================================
-- Business Context:
--   Order tracking numbers are formatted as
--   CARRIER-REGION-SEQUENCE (e.g., "FEDX-EU-88213"). Support
--   needs a quick way to filter orders by carrier without a
--   separate carrier column, ahead of a planned schema migration.

-- Question: Extract the carrier code from each order's tracking
--           number.
SELECT
    order_id,
    tracking_number,
    SUBSTRING_INDEX(tracking_number, '-', 1) AS carrier_code
FROM orders;

-- Question: Return only orders shipped via FedEx ('FEDX') using
--           a pattern match rather than the extracted column,
--           to compare approaches.
SELECT
    order_id,
    tracking_number
FROM orders
WHERE tracking_number LIKE 'FEDX-%';

-- Engineering Notes:
--   The second query is preferred over filtering on the extracted
--   carrier_code expression: `tracking_number LIKE 'FEDX-%'` is a
--   trailing-wildcard, prefix-anchored pattern, which — unlike
--   SUBSTRING_INDEX() in a WHERE clause — can use a standard
--   index on tracking_number in most engines. Prefer LIKE-based
--   prefix filtering over function-based extraction when the goal
--   is filtering rather than displaying the extracted value.
--
-- Performance Notes:
--   See above — this scenario exists specifically to contrast an
--   index-friendly filter (LIKE prefix match) against a
--   non-sargable one (function applied to the column), reinforcing
--   the pattern introduced in Topic 01.
--
-- Expected Output (sample):
--   order_id | tracking_number   | carrier_code
--   9001      | FEDX-EU-88213     | FEDX
--   9002      | UPS-NA-10442       | UPS
-- ============================================================
