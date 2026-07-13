-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   04 · ROLLUP, CUBE, AND GROUPING SETS
-- ============================================================================
-- Business Objective:
--   Produce hierarchical retail revenue reports with subtotals and grand
--   totals in a single aggregation pass, matching the exact shape finance
--   and board-level reports expect.
--
-- Dataset Used (Retail domain):
--   regions (region_id PK, region_name)
--   stores  (store_id PK, store_name, region_id FK)
--   products(product_id PK, product_name, category)
--   sales   (sale_id PK, store_id FK, product_id FK, sale_date, revenue)
--
-- Dialect notes:
--   ROLLUP and GROUPING() are supported identically in MySQL 8+ and
--   PostgreSQL. CUBE and GROUPING SETS are supported in both as well.
--   MySQL's ROLLUP syntax also allows the legacy `GROUP BY a, b WITH ROLLUP`
--   form; this file uses the ANSI-standard `GROUP BY ROLLUP(a, b)` form for
--   portability with PostgreSQL.
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 — ROLLUP
-- Business Context:
--   Finance wants the monthly board report: revenue by region and store,
--   with a subtotal per region and one company-wide grand total, all in a
--   single exportable table.
--
-- Business Questions:
--   - What is revenue per store, per region?
--   - What is the subtotal per region?
--   - What is the company-wide grand total?
-- ============================================================================

SELECT
    COALESCE(r.region_name, 'ALL REGIONS')                     AS region_name,
    COALESCE(s.store_name,
             CASE WHEN GROUPING(s.store_name) = 1
                  THEN 'ALL STORES' END)                        AS store_name,
    SUM(sa.revenue)                                             AS total_revenue,
    GROUPING(r.region_name)                                     AS is_region_subtotal,
    GROUPING(s.store_name)                                       AS is_store_subtotal
FROM sales   AS sa
JOIN stores  AS s ON sa.store_id  = s.store_id
JOIN regions AS r ON s.region_id  = r.region_id
GROUP BY ROLLUP(r.region_name, s.store_name)
ORDER BY r.region_name, s.store_name;

-- Explanation:
--   GROUP BY ROLLUP(region_name, store_name) produces three levels in one
--   pass: detail rows (region + store), region subtotals (store rolled up
--   to NULL), and one grand-total row (both columns rolled up to NULL).
--   The COALESCE/GROUPING() combination converts those structural NULLs
--   into readable labels for the presentation layer, without hardcoding a
--   fake 'ALL REGIONS' row into the underlying data.
--
-- Engineering Notes:
--   is_region_subtotal and is_store_subtotal are included explicitly (not
--   just relied on implicitly) so a downstream BI tool or export script can
--   filter or style subtotal rows differently without re-deriving the logic.
--
-- Optimization Notes:
--   ROLLUP computes all three levels from one grouped scan of the joined
--   sales rows -- materially cheaper than three separate GROUP BY queries
--   unioned together, and guaranteed internally consistent.
--
-- Expected Output (illustrative):
--   region_name | store_name  | total_revenue | is_region_subtotal | is_store_subtotal
--   East         | Store A      | 40,000.00      | 0                    | 0
--   East         | Store B      | 35,000.00      | 0                    | 0
--   East         | ALL STORES   | 75,000.00      | 0                    | 1
--   West         | Store C      | 28,000.00      | 0                    | 0
--   West         | ALL STORES   | 28,000.00      | 0                    | 1
--   ALL REGIONS  | ALL STORES   | 103,000.00     | 1                    | 1


-- ============================================================================
-- SCENARIO 2 — CUBE
-- Business Context:
--   Merchandising wants every possible subtotal combination of region and
--   product category -- not just the region hierarchy from Scenario 1 --
--   to compare category performance both within and across regions.
--
-- Business Questions:
--   - Revenue by region and category
--   - Revenue subtotal by region alone (across all categories)
--   - Revenue subtotal by category alone (across all regions)
--   - Company-wide grand total
-- ============================================================================

SELECT
    COALESCE(r.region_name, 'ALL REGIONS')                      AS region_name,
    COALESCE(p.category, 'ALL CATEGORIES')                       AS category,
    SUM(sa.revenue)                                              AS total_revenue,
    GROUPING(r.region_name)                                      AS is_region_subtotal,
    GROUPING(p.category)                                          AS is_category_subtotal
FROM sales    AS sa
JOIN stores   AS s ON sa.store_id  = s.store_id
JOIN regions  AS r ON s.region_id  = r.region_id
JOIN products AS p ON sa.product_id = p.product_id
GROUP BY CUBE(r.region_name, p.category)
ORDER BY region_name, category;

-- Explanation:
--   CUBE(region_name, category) produces all four combinations: detail rows
--   (region + category), region-only subtotals, category-only subtotals
--   (which ROLLUP would NOT produce, since it has no "category alone"
--   level in a region-then-category hierarchy), and the grand total.
--   This is the key structural difference from Scenario 1's ROLLUP.
--
-- Engineering Notes:
--   The category-only subtotal rows (is_region_subtotal = 1,
--   is_category_subtotal = 0) are the new information CUBE adds beyond
--   ROLLUP -- verify with the business stakeholder that this extra
--   dimension is actually wanted before defaulting to CUBE, since it
--   roughly doubles the row count versus ROLLUP for two dimensions.
--
-- Optimization Notes:
--   For 2 dimensions, CUBE produces at most 4 grouping levels -- fine at
--   this scale. Confirm expected row count before applying CUBE to 4+
--   dimensions, where the combination count (2^n) grows quickly.
--
-- Expected Output (illustrative):
--   region_name | category     | total_revenue | is_region_subtotal | is_category_subtotal
--   East         | Apparel       | 22,000.00      | 0                    | 0
--   East         | Electronics   | 18,000.00      | 0                    | 0
--   East         | ALL CATEGORIES| 40,000.00      | 0                    | 1
--   ALL REGIONS  | Apparel       | 35,000.00      | 1                    | 0
--   ALL REGIONS  | ALL CATEGORIES| 103,000.00     | 1                    | 1


-- ============================================================================
-- SCENARIO 3 — GROUPING SETS
-- Business Context:
--   The executive dashboard only needs two specific views in one query:
--   revenue by region, and the overall company grand total -- not the full
--   region+store detail, and not a store-only subtotal. GROUPING SETS lets
--   this be requested explicitly rather than computing (and then
--   discarding) levels nobody asked for.
--
-- Business Questions:
--   - What is total revenue per region?
--   - What is the overall company-wide grand total?
-- ============================================================================

SELECT
    COALESCE(r.region_name, 'ALL REGIONS')                       AS region_name,
    SUM(sa.revenue)                                               AS total_revenue,
    GROUPING(r.region_name)                                        AS is_grand_total
FROM sales   AS sa
JOIN stores  AS s ON sa.store_id  = s.store_id
JOIN regions AS r ON s.region_id  = r.region_id
GROUP BY GROUPING SETS ( (r.region_name), () )
ORDER BY is_grand_total, region_name;

-- Explanation:
--   GROUPING SETS ((region_name), ()) computes exactly two grouping levels:
--   one row per region, and one grand-total row -- and nothing else. This
--   is cheaper and more explicit than ROLLUP(region_name) here (which
--   would actually produce the identical result for a single column, but
--   GROUPING SETS scales more clearly once combinations stop following a
--   strict hierarchy).
--
-- Engineering Notes:
--   For a single grouping column, ROLLUP(region_name) and
--   GROUPING SETS ((region_name), ()) are equivalent -- GROUPING SETS
--   becomes clearly superior once you need combinations that don't follow
--   the region -> store -> total hierarchy, such as Scenario 4 below.
--
-- Optimization Notes:
--   Only two grouping levels are computed, versus three for ROLLUP on two
--   columns or four for CUBE -- GROUPING SETS avoids computing subtotal
--   levels the business didn't ask for.
--
-- Expected Output (illustrative):
--   region_name | total_revenue | is_grand_total
--   East         | 75,000.00      | 0
--   West         | 28,000.00      | 0
--   ALL REGIONS  | 103,000.00     | 1


-- ============================================================================
-- SCENARIO 4 — GROUPING SETS with non-hierarchical combinations
-- Business Context:
--   Category management wants revenue by region alone AND revenue by
--   category alone, in the same result set, WITHOUT the region-by-category
--   cross-tabulation CUBE would also compute -- a combination ROLLUP
--   cannot express at all, since region and category have no hierarchy
--   between them here.
--
-- Business Questions:
--   - Revenue subtotal per region (across all categories)
--   - Revenue subtotal per category (across all regions)
-- ============================================================================

SELECT
    COALESCE(r.region_name, 'ALL REGIONS')                        AS region_name,
    COALESCE(p.category, 'ALL CATEGORIES')                         AS category,
    SUM(sa.revenue)                                                 AS total_revenue
FROM sales    AS sa
JOIN stores   AS s ON sa.store_id  = s.store_id
JOIN regions  AS r ON s.region_id  = r.region_id
JOIN products AS p ON sa.product_id = p.product_id
GROUP BY GROUPING SETS ( (r.region_name), (p.category) )
ORDER BY region_name, category;

-- Explanation:
--   This combination -- region alone, and category alone, with NEITHER the
--   full cross-tab nor a grand total -- cannot be expressed with ROLLUP at
--   all, and would require discarding unwanted rows from CUBE's output.
--   GROUPING SETS states the two independent breakdowns explicitly, computing
--   only what was asked for.
--
-- Engineering Notes:
--   Rows in this result set are NOT mutually exclusive combinations the way
--   Scenario 1's ROLLUP rows are -- each row here is one of two entirely
--   separate breakdowns sharing one result set purely for report-delivery
--   convenience. Document this clearly for anyone consuming the table.
--
-- Optimization Notes:
--   Two grouping levels computed, versus four for the equivalent CUBE --
--   a meaningful savings on a large sales table.
--
-- Expected Output (illustrative):
--   region_name | category       | total_revenue
--   East         | ALL CATEGORIES  | 75,000.00
--   West         | ALL CATEGORIES  | 28,000.00
--   ALL REGIONS  | Apparel          | 35,000.00
--   ALL REGIONS  | Electronics      | 68,000.00
