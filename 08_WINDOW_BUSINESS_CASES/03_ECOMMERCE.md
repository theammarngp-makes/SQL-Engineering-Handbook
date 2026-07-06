# 03 · E-Commerce — Window Functions in Customer & Product Analytics

## Introduction

E-commerce analytics blends the two patterns you've already built: peer comparison (Chapter 01) and time-based comparison (Chapter 02) - then adds a third dimension unique to this domain: **the customer as the unit of analysis over their entire relationship with the business**. Customer Lifetime Value, repeat purchase behavior, and order-level ranking all require looking at a customer's or product's full history, not just a single transaction.

---

## Business Background

A typical e-commerce schema centers on orders and order line items:

- `customers (customer_id, customer_name, signup_date, ...)`
- `orders (order_id, customer_id FK, order_date, order_total, ...)`
- `order_items (order_item_id, order_id FK, product_id FK, quantity, unit_price, ...)`
- `products (product_id, product_name, category_id FK, ...)`
- `categories (category_id, category_name)`

Analytics and growth teams use this data to understand **who** is buying, **what** they're buying, and **how often** they return.

---

## Typical KPIs

- Customer Lifetime Value (CLV)
- Average Order Value (AOV)
- Repeat purchase rate
- Top products / top categories by revenue
- Customer rank by total spend
- Running revenue per customer over their lifecycle
- Basket size ranking (largest orders by item count or value)

---

## Typical Dashboards

- **Customer Value Dashboard** — ranks customers by lifetime spend, flags top-tier ("VIP") customers.
- **Product Performance Dashboard** — ranks products and categories by revenue and units sold.
- **Retention Dashboard** — repeat purchase rate, time between orders, churn risk signals.
- **Order Analytics Dashboard** — average order value trends, largest baskets, order frequency.

---

## Business Problems

1. "Rank our customers by total lifetime spend - who are our VIP customers?"
2. "What's the running revenue contributed by each customer over time, so we can see growth in their relationship with us?"
3. "Rank our products within each category by revenue."
4. "What percentage of customers make more than one purchase, and how long is the gap between their first and second order?"
5. "What's the average order value, and how does it compare to each customer's own historical average?"
6. "Rank our largest baskets (orders) by total value, for a case study on high-value orders."

---

## Why Window Functions Are Needed

Customer Lifetime Value and repeat-purchase analysis both require comparing a customer's current order to **their own history** - not to a fixed group like a department, and not strictly to a calendar period like a fiscal month, but to *their own prior orders*, in sequence. This is a natural extension of `LAG()`/`LEAD()` and running-total patterns, partitioned by `customer_id` instead of `salesperson_id` or `dept_id`. Product and category rankings reuse the exact `RANK()`/`DENSE_RANK()` leaderboard pattern from Chapters 01 and 02, now applied to `product_id` and `category_id` partitions.

---

## Functions Used in This Chapter

| Function | Business Explanation |
|---|---|
| `RANK()` / `DENSE_RANK()` | Customer value leaderboard; product ranking within category. |
| `SUM() OVER (PARTITION BY customer_id ORDER BY order_date ...)` | Running lifetime revenue per customer. |
| `LAG()` | Time between a customer's consecutive orders (repeat purchase gap). |
| `AVG() OVER (PARTITION BY customer_id)` | Customer's own historical average order value, for anomaly comparison. |
| `ROW_NUMBER()` | Identifying each customer's first order (for cohort and CLV-start analysis). |

---

## SQL Concepts Reinforced

- Using `ROW_NUMBER() = 1` per `customer_id` (ordered by `order_date`) to isolate each customer's **first order**, a common building block for cohort and CLV-start analysis.
- Distinguishing a "customer-level" running total (`PARTITION BY customer_id`) from a "company-level" running total (no partition) - the same distinction introduced in Sales Analytics, now reused for a different grain.
- Using `COUNT() OVER (PARTITION BY customer_id)` to determine whether a customer is a repeat purchaser (count > 1) without a separate aggregation query.
- Nesting a product-within-category rank alongside a category-level rank, to answer two related but distinct business questions in one query.

---

## Performance Notes

- CLV and running-revenue queries partitioned by `customer_id` scale well when `(customer_id, order_date)` is indexed - without it, the engine must sort the entire `orders` table per partition on every query execution.
- Repeat-purchase and basket analyses are frequently requested on a rolling basis (e.g., "repeat rate this month") - consider materializing a customer-level summary table (first order date, order count, lifetime revenue) refreshed on a schedule, rather than recomputing window functions over the full order history on every dashboard load.
- Product-within-category ranking benefits from partitioning on `category_id` directly rather than joining to `categories` purely for the category name inside the window - join the name in an outer `SELECT` after ranking, if the ranking column itself doesn't require it.

---

## Common Mistakes

- Computing "average order value" as a single global average when the business actually wants **per-customer** AOV for anomaly detection - always confirm the partition scope.
- Using `COUNT(*)` instead of `COUNT(DISTINCT order_id)` when counting orders per customer in the presence of a joined `order_items` table, silently inflating the count by line-item quantity.
- Forgetting to handle customers with exactly one order when computing "gap between first and second order" - a `LAG()` will correctly return `NULL` for such rows, but downstream aggregate calculations must explicitly exclude or handle these `NULL`s.
- Ranking products by total revenue without partitioning by category, when the business intent was "best-selling product **within** its category," not company-wide.

---

## Interview Questions

1. **"How would you calculate Customer Lifetime Value using window functions?"** — Expect a running `SUM(order_total) OVER (PARTITION BY customer_id ORDER BY order_date)`, and a discussion of the difference between "running CLV" and "final/total CLV."
2. **"How would you identify each customer's very first order?"** — Expect `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) = 1`.
3. **"How would you calculate the repeat purchase rate for a cohort of customers?"** — Expect a `COUNT() OVER (PARTITION BY customer_id)` (or a `GROUP BY` + `HAVING COUNT(*) > 1`) to identify repeat purchasers, divided by total customers in the cohort.
4. **"Rank products by revenue within their category - how would you write this?"** — Expect `RANK() OVER (PARTITION BY category_id ORDER BY SUM(revenue) DESC)` over a pre-aggregated product-revenue CTE.
5. **"What's the difference between average order value calculated globally vs. per customer, and why does the distinction matter for a churn model?"** — Expect a discussion of how global AOV can mask individual behavioral drift that a churn model needs to detect.

---

## Summary

E-commerce analytics is where peer comparison (Chapter 01) and time-based comparison (Chapter 02) combine and extend to a new grain: the customer's own history. Running lifetime value, first-order detection, and repeat-purchase gap analysis are the foundational building blocks of nearly every growth and retention dashboard in the industry.

---

## Further Practice

- Extend the CLV query to bucket customers into value tiers (e.g., `NTILE(4)`) for a tiered loyalty program.
- Add a query that computes the average time between a customer's first and second order, segmented by acquisition channel (if such a column exists).
- Build a "basket ranking" report that ranks the top 10 largest orders by total value, joined back to customer and product detail.

---

**Next:** [`03_ECOMMERCE.sql`](./03_ECOMMERCE.sql) — the fully engineered SQL chapter for this domain.
