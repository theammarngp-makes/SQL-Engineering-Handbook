---
id: EX-07-001
title: Top-2 Products by Monthly Revenue
module: 07_Window_Functions
category: WINDOW_FUNCTIONS
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 20
business_domain: E-commerce
dataset: ecommerce
tables: [orders, order_items, products]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` for a Top-N-per-group query.
- See why a plain `GROUP BY` with `LIMIT` cannot answer "top N per group" — `LIMIT` only caps the whole
  result set, not each group within it.

## Business context

Merchandising wants, for every month with eligible sales, the top 2 products by revenue — for a recurring
report, not a one-off.

## Scenario

Revenue is computed the same way as in earlier exercises: `order_items` for orders whose status is
`'shipped'`, `'delivered'`, or `'returned'`, summed per product per month.

## Input assumptions

- The dataset covers 8 distinct months (2024-11 through 2025-06) with eligible sales.
- No product ties for rank 1 or rank 2 within any month in this dataset — but the query must still break
  ties deterministically (by `product_id` ascending) in case that ever changes.

## Task

For each month, return the top 2 products by revenue: `sale_month`, `product_name`, `revenue`, `rank_in_month`.

## Constraints

- Exactly 2 rows per month, for every month that has at least one eligible sale.
- Ties in revenue must break by `product_id` ascending, not be arbitrary.

## Expected output

<!-- expected:start -->
| sale_month | product_name | revenue | rank_in_month |
|---|---|---|---|
| 2024-11 | 4K Monitor 27" | 1250.20 | 1 |
| 2024-11 | Air Fryer | 99.50 | 2 |
| 2024-12 | Rain Jacket | 179.20 | 1 |
| 2024-12 | Wireless Earbuds | 119.98 | 2 |
| 2025-01 | 4K Monitor 27" | 296.10 | 1 |
| 2025-01 | Mechanical Keyboard | 258.00 | 2 |
| 2025-02 | Practical SQL Paperback | 163.20 | 1 |
| 2025-02 | Running Shoes | 158.00 | 2 |
| 2025-03 | 4K Monitor 27" | 1645.00 | 1 |
| 2025-03 | Mechanical Keyboard | 357.00 | 2 |
| 2025-04 | 4K Monitor 27" | 1250.20 | 1 |
| 2025-04 | Mechanical Keyboard | 238.00 | 2 |
| 2025-05 | 4K Monitor 27" | 329.00 | 1 |
| 2025-05 | Practical SQL Paperback | 102.00 | 2 |
| 2025-06 | Coffee Grinder | 630.00 | 1 |
| 2025-06 | Air Fryer | 457.70 | 2 |

_16 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
First build one row per (month, product) with its revenue — that's a normal `GROUP BY`. The "top 2" part is a separate, second step on top of that.
</details>
<details><summary>Hint 2</summary>
Put the grouped result in a CTE, then apply `ROW_NUMBER() OVER (PARTITION BY sale_month ORDER BY revenue DESC, product_id ASC)` to it.
</details>
<details><summary>Hint 3</summary>
Filter the outer query to `WHERE rank_in_month <= 2` — you cannot filter on a window function's result in the same `SELECT` that defines it, hence the CTE.
</details>

## Solution

_MySQL 8.0+._

```sql
WITH monthly_product_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS sale_month,
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue
    FROM order_items oi
    JOIN orders o    ON o.order_id = oi.order_id
    JOIN products p  ON p.product_id = oi.product_id
    WHERE o.status IN ('shipped', 'delivered', 'returned')
    GROUP BY sale_month, p.product_id, p.product_name
),
ranked AS (
    SELECT
        sale_month,
        product_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY sale_month
            ORDER BY revenue DESC, product_id ASC
        ) AS rank_in_month
    FROM monthly_product_revenue
)
SELECT sale_month, product_name, revenue, rank_in_month
FROM ranked
WHERE rank_in_month <= 2
ORDER BY sale_month, rank_in_month;
```

## Explanation

**Grain.** The first CTE is at (month, product) grain; the second CTE adds a rank within each month,
still one row per (month, product); the final result keeps only ranks 1–2.
**Rows that survive.** Every (month, product) pair with eligible revenue makes it into
`monthly_product_revenue`; only the top 2 per month survive into the final output.
**Filtering.** Status filtering happens once, early, inside the first CTE — not repeated or applied at
the wrong grain later.
**Join cardinality.** `order_items → orders` and `order_items → products` are both many-to-one; safe.
**Aggregation.** `SUM` per (month, product) in the first CTE; `ROW_NUMBER()` is a window function, not an
aggregate — it does not collapse rows, it labels them, which is why it needs its own CTE before filtering.
**NULL behavior.** Not applicable; no NULLs flow through this path in this dataset.
**Why it is correct.** Verified against the dataset month by month; 16 rows, 2 per each of the 8 months.
**What could make it slow.** The window function requires a sort per partition; an index on
`orders.order_date` (already present) helps the underlying aggregation, not the ranking itself.
**How to validate.** `COUNT(*) FROM ranked WHERE rank_in_month = 1` must equal 8 (one #1 per month) — and
`WHERE rank_in_month = 2` must also equal 8.

## Common mistakes

**Using `GROUP BY` with `LIMIT 2`** — `LIMIT` caps the entire result set, not each group, so this returns
only the 2 highest-revenue (month, product) rows across *all* months combined, not 2 per month.
```sql wrong
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS sale_month,
    p.product_name,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue,
    1 AS rank_in_month
FROM order_items oi
JOIN orders o    ON o.order_id = oi.order_id
JOIN products p  ON p.product_id = oi.product_id
WHERE o.status IN ('shipped', 'delivered', 'returned')
GROUP BY sale_month, p.product_id, p.product_name
ORDER BY revenue DESC
LIMIT 2;
```

## Edge cases

- A month with only 1 eligible product would correctly return 1 row, not 2 — `rank_in_month <= 2` does
  not require a second row to exist. Not present in this dataset (every month has ≥ 6 products), but the
  query must not assume exactly 2 rows per month.
- `RANK()` instead of `ROW_NUMBER()` would give two products the *same* rank on a real tie and could
  return 3 rows for one month — deliberately not used here since the task asks for exactly 2 per month.

## Performance notes

`ROW_NUMBER() OVER (PARTITION BY ...)` requires MySQL to sort within each partition; for a small number
of months this is negligible. At scale, an index that already sorts by the partition/order columns can
avoid a separate sort step — verify with `EXPLAIN`.

## Optional challenge

Change the tiebreaker to `RANK()` and identify, from the "Edge cases" note above, which real business
question that answers differently than `ROW_NUMBER()`.

## Related

Module: [07_Window_Functions](../../07_Window_Functions/) · Related: [08_WINDOW_BUSINESS_CASES](../../08_WINDOW_BUSINESS_CASES/)
