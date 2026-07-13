-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   02 · MULTIPLE AGGREGATIONS
-- ============================================================================
-- Business Objective:
--   Combine COUNT, COUNT(DISTINCT), SUM, AVG, MIN, and MAX in single grouped
--   queries to build multi-metric customer and product summaries, instead of
--   issuing one query per metric.
--
-- Dataset Used (E-commerce domain):
--   customers    (customer_id PK, customer_name, signup_date)
--   orders       (order_id PK, customer_id FK, order_date, status)
--   order_items  (order_item_id PK, order_id FK, product_id FK, quantity, unit_price)
--   products     (product_id PK, product_name, category)
--
-- Dialect notes: MySQL 8+ / PostgreSQL compatible. NULLIF used where safe
-- division is required; both dialects support it identically.
-- ============================================================================


-- ============================================================================
-- SCENARIO 1
-- Business Context:
--   The customer success team wants a single-row-per-customer summary combining
--   order volume, distinct product breadth, total spend, and recency, for use
--   in the "customer 360" dashboard panel.
--
-- Business Questions:
--   - How many distinct orders has each customer placed?
--   - How many distinct products have they bought?
--   - What is their lifetime spend and average order value?
--   - When was their most recent order?
-- ============================================================================

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id)                              AS total_orders,
    COUNT(DISTINCT oi.product_id)                            AS distinct_products_bought,
    SUM(oi.quantity * oi.unit_price)                          AS lifetime_spend,
    ROUND(SUM(oi.quantity * oi.unit_price)
          / NULLIF(COUNT(DISTINCT o.order_id), 0), 2)         AS avg_order_value,
    MAX(o.order_date)                                          AS most_recent_order
FROM customers   AS c
JOIN orders      AS o  ON c.customer_id = o.customer_id
JOIN order_items AS oi ON o.order_id     = oi.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_spend DESC;

-- Explanation:
--   COUNT(DISTINCT o.order_id) is deliberately used (not plain COUNT) because
--   the join to order_items fans a single order out into multiple line-item
--   rows -- exactly the trap flagged in the companion .md file. avg_order_value
--   is computed as total spend divided by distinct order count, not as
--   AVG(oi.quantity * oi.unit_price), because the latter would average
--   individual line items rather than whole orders.
--
-- Engineering Notes:
--   NULLIF(COUNT(DISTINCT o.order_id), 0) prevents a division-by-zero error
--   for the (unlikely but possible) case of a customer row with no matching
--   orders after a future query change to an outer join.
--
-- Optimization Notes:
--   For very active customers, consider pre-aggregating order_items to the
--   order grain in a CTE first, then joining to orders/customers, to avoid
--   scanning the full line-item table if only order-level totals are needed
--   downstream.
--
-- Expected Output (illustrative):
--   customer_id | customer_name | total_orders | distinct_products_bought | lifetime_spend | avg_order_value | most_recent_order
--   1001        | A. Sharma      | 6            | 9                         | 42,300.00       | 7,050.00         | 2026-06-18


-- ============================================================================
-- SCENARIO 2
-- Business Context:
--   Merchandising wants a product performance table: units sold, revenue,
--   distinct buyers, and price range observed at checkout (useful for
--   catching pricing inconsistencies from historical discounts).
--
-- Business Questions:
--   - How many units of each product have sold, and for how much revenue?
--   - How many distinct customers bought it?
--   - What was the lowest and highest unit price it was ever sold at?
-- ============================================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity)                                          AS units_sold,
    SUM(oi.quantity * oi.unit_price)                           AS total_revenue,
    COUNT(DISTINCT o.customer_id)                              AS distinct_buyers,
    MIN(oi.unit_price)                                          AS lowest_price_sold,
    MAX(oi.unit_price)                                          AS highest_price_sold
FROM products    AS p
JOIN order_items AS oi ON p.product_id = oi.product_id
JOIN orders      AS o  ON oi.order_id  = o.order_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- Explanation:
--   Six independent metrics computed from one grouped pass over order_items,
--   each answering a different merchandising question: volume (units_sold),
--   revenue, reach (distinct_buyers), and pricing spread (MIN/MAX).
--
-- Engineering Notes:
--   A wide gap between lowest_price_sold and highest_price_sold on a product
--   that should have a fixed list price is a useful, cheap data-quality
--   signal for a pricing-integrity check built directly into this report.
--
-- Optimization Notes:
--   Index order_items(product_id) and orders(order_id) to keep both joins
--   index-driven; this query scans order_items once regardless of catalog
--   size, so its cost scales with transaction volume, not product count.
--
-- Expected Output (illustrative):
--   product_id | product_name     | category    | units_sold | total_revenue | distinct_buyers | lowest_price_sold | highest_price_sold
--   P-2041     | Wireless Mouse    | Electronics | 3,204       | 96,120.00      | 1,880             | 24.99               | 34.99


-- ============================================================================
-- SCENARIO 3
-- Business Context:
--   Finance wants a category-level rollup: total revenue and average
--   selling price per category, to compare against category-level cost of
--   goods sold in a separate finance system.
--
-- Business Questions:
--   - What is total revenue per product category?
--   - What is the average unit price actually realized per category
--     (accounting for real transaction volume, not a simple average of
--     list prices)?
-- ============================================================================

SELECT
    p.category,
    COUNT(DISTINCT p.product_id)                              AS distinct_products,
    SUM(oi.quantity)                                           AS units_sold,
    SUM(oi.quantity * oi.unit_price)                            AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price)
          / NULLIF(SUM(oi.quantity), 0), 2)                     AS revenue_weighted_avg_price
FROM products    AS p
JOIN order_items AS oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Explanation:
--   revenue_weighted_avg_price is intentionally computed as total revenue
--   divided by total units, not as AVG(oi.unit_price) -- the latter would
--   give every line item equal weight regardless of quantity, understating
--   the true realized average price for high-volume, lower-priced items.
--   This distinction between a "simple average" and a "weighted average"
--   is a common source of finance-vs-analytics reporting discrepancies.
--
-- Engineering Notes:
--   distinct_products confirms the category actually has active SKUs behind
--   the revenue figure -- useful for catching a category with revenue
--   concentrated in a single product, a common merchandising risk signal.
--
-- Optimization Notes:
--   No join to orders/customers is needed for this specific report, keeping
--   the scan limited to products and order_items -- always join only the
--   tables a given report's metrics actually require.
--
-- Expected Output (illustrative):
--   category    | distinct_products | units_sold | total_revenue | revenue_weighted_avg_price
--   Electronics | 128                 | 41,200      | 1,850,400.00   | 44.92
