-- ============================================================================
-- MODULE      : 08_WINDOW_FUNCTION_APPLICATIONS
-- CHAPTER     : 03_ECOMMERCE
-- OBJECTIVE   : Apply window functions to customer and product analytics -
--               lifetime value, repeat purchase behavior, and product/
--               category leaderboards.
--
-- ASSUMED SCHEMA
-- ----------------------------------------------------------------------------
-- customers   (customer_id PK, customer_name, signup_date)
-- orders      (order_id PK, customer_id FK, order_date, order_total)
-- order_items (order_item_id PK, order_id FK, product_id FK, quantity, unit_price)
-- products    (product_id PK, product_name, category_id FK)
-- categories  (category_id PK, category_name)
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 : Customer Value Leaderboard
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Growth and CRM teams want to identify VIP customers - ranked by total
--   lifetime spend - to prioritize retention and loyalty outreach.
-- ============================================================================

-- Q1. Rank customers by total lifetime spend.
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(o.order_total) AS lifetime_spend
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    lifetime_spend,
    RANK() OVER (ORDER BY lifetime_spend DESC) AS spend_rank
FROM customer_spend
ORDER BY spend_rank;


-- Q2. Bucket customers into value tiers using NTILE(4) for a tiered loyalty
--     program (tier 1 = top 25% by lifetime spend).
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(o.order_total) AS lifetime_spend
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    lifetime_spend,
    NTILE(4) OVER (ORDER BY lifetime_spend DESC) AS value_tier
FROM customer_spend
ORDER BY value_tier, lifetime_spend DESC;


-- ============================================================================
-- SCENARIO 2 : Running Customer Lifetime Value
-- ----------------------------------------------------------------------------
-- Business explanation:
--   For any customer, show how their lifetime spend accumulates over time -
--   used to visualize a customer's growing (or stalling) relationship value.
-- ============================================================================

-- Q3. Running lifetime value per customer, ordered by order date.
SELECT
    o.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.order_total,
    SUM(o.order_total) OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_clv
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;


-- Q4. Identify each customer's first order - a common building block for
--     cohort analysis and CLV-start reporting.
WITH ordered_orders AS (
    SELECT
        o.customer_id,
        c.customer_name,
        o.order_id,
        o.order_date,
        o.order_total,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS order_seq
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
)
SELECT
    customer_id,
    customer_name,
    order_id,
    order_date,
    order_total
FROM ordered_orders
WHERE order_seq = 1
ORDER BY order_date;


-- ============================================================================
-- SCENARIO 3 : Repeat Purchase Behavior
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Retention teams need to know what fraction of customers return for a
--   second purchase, and how long the gap is between orders.
-- ============================================================================

-- Q5. Flag repeat purchasers using a per-customer order count, and compute
--     the gap between each customer's consecutive orders.
SELECT
    o.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    COUNT(o.order_id) OVER (PARTITION BY o.customer_id) AS total_orders,
    LAG(o.order_date) OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date
    ) AS previous_order_date,
    o.order_date - LAG(o.order_date) OVER (
        PARTITION BY o.customer_id
        ORDER BY o.order_date
    ) AS days_since_previous_order
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;


-- Q6. Repeat purchase rate: percentage of customers with more than one
--     order, computed from the per-customer order counts above.
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(order_id) OVER (PARTITION BY customer_id) AS total_orders,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS row_seq
    FROM orders
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_purchase_rate_pct
FROM customer_order_counts
WHERE row_seq = 1;   -- one row per customer to avoid double-counting


-- ============================================================================
-- SCENARIO 4 : Product & Category Performance
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Merchandising teams want to know the best-selling products within each
--   category, and average order value trends.
-- ============================================================================

-- Q7. Rank products by revenue within their own category.
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_id,
        cat.category_name,
        SUM(oi.quantity * oi.unit_price) AS product_revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN categories cat
        ON p.category_id = cat.category_id
    GROUP BY p.product_id, p.product_name, p.category_id, cat.category_name
)
SELECT
    product_id,
    product_name,
    category_name,
    product_revenue,
    DENSE_RANK() OVER (
        PARTITION BY category_id
        ORDER BY product_revenue DESC
    ) AS rank_within_category
FROM product_revenue
ORDER BY category_name, rank_within_category;


-- Q8. Compare each customer's order value to their own historical average
--     order value - flags orders that are unusually large or small relative
--     to that customer's typical behavior.
SELECT
    o.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.order_total,
    ROUND(AVG(o.order_total) OVER (PARTITION BY o.customer_id), 2) AS customer_avg_order_value,
    ROUND(
        o.order_total - AVG(o.order_total) OVER (PARTITION BY o.customer_id),
        2
    ) AS deviation_from_own_average
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;


-- Q9. Rank the top 10 largest baskets (orders) by total value, company-wide.
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.order_total,
    RANK() OVER (ORDER BY o.order_total DESC) AS basket_rank
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
QUALIFY basket_rank <= 10   -- use a CTE + WHERE instead of QUALIFY on engines that don't support it
ORDER BY basket_rank;

-- ============================================================================
-- END OF CHAPTER 03 - E-COMMERCE
-- ============================================================================
