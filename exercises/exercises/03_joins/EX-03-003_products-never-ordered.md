---
id: EX-03-003
title: Products That Have Never Been Ordered
module: 03_Joins
category: JOINS
difficulty: EASY
level: L2
estimated_time_min: 10
business_domain: E-commerce
dataset: ecommerce
tables: [products, order_items]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `LEFT JOIN ... IS NULL` to find parents with no children, here at the product level.

## Business context

Merchandising wants to know which catalog products have never sold, to decide what to discount or delist.

## Scenario

`order_items.product_id` references `products.product_id`; not every product appears in an order line.

## Input assumptions

- 12 products, 91 order items; exactly one product has no order line.

## Task

List `product_id`, `product_name`, `is_active` for every product that appears in no order item.

## Constraints

- Cancelled orders still count as the product having been ordered.

## Expected output

<!-- expected:start -->
| product_id | product_name | is_active |
|---|---|---|
| 12 | Desk Lamp | 0 |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
An INNER JOIN can only return products that DO have order lines.
</details>
<details><summary>Hint 2</summary>
Keep every product with a LEFT JOIN and look for the missing match.
</details>
<details><summary>Hint 3</summary>
`LEFT JOIN order_items i ON i.product_id = p.product_id WHERE i.order_item_id IS NULL`.
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT p.product_id, p.product_name, p.is_active
FROM products p
LEFT JOIN order_items i ON i.product_id = p.product_id
WHERE i.order_item_id IS NULL
ORDER BY p.product_id;
```

## Explanation

**Grain.** One row per product.
**Rows that survive.** Products with zero matching order items.
**Filtering.** The IS NULL test targets the right table's primary key, which is never NULL in real rows.
**Join cardinality.** LEFT JOIN keeps each unmatched product exactly once.
**Aggregation.** None needed; this is an existence question.
**NULL behavior.** The NULLs are manufactured by the join, not stored in the data.
**Why it is correct.** Verified live: the only unmatched product is Desk Lamp.
**What could make it slow.** Without an index on `order_items.product_id` each product needs a scan of order items; the foreign key creates that index automatically in InnoDB.
**How to validate.** Count of rows here plus `COUNT(DISTINCT product_id)` from order_items equals 12.

## Common mistakes

**Joining with INNER JOIN and then filtering for no match** — the INNER JOIN already discarded the unmatched products, so the result is always empty.
```sql wrong
SELECT p.product_id, p.product_name, p.is_active
FROM products p
INNER JOIN order_items i ON i.product_id = p.product_id
WHERE i.order_item_id IS NULL
ORDER BY p.product_id;
```

## Edge cases

- A product with sales only on cancelled orders would not appear; that is intended by the constraint.

## Performance notes

`NOT EXISTS` and `LEFT JOIN ... IS NULL` normally compile to the same anti-join in MySQL 8; confirm with `EXPLAIN`.

## Optional challenge

Restrict the result to products that never sold on any non-cancelled order.

## Related

Module: [03_Joins](../../03_Joins/) · Related: [EX-03-001](EX-03-001_customers-with-zero-orders.md)
