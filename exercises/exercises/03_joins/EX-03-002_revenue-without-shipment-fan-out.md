---
id: EX-03-002
title: Revenue Without the Shipment Fan-Out
module: 03_Joins
category: JOINS
difficulty: ADVANCED
level: L4
estimated_time_min: 20
business_domain: E-commerce
dataset: ecommerce
tables: [orders, order_items, shipments]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Recognize that joining a "one-to-many" table you don't need multiplies rows and inflates any SUM
  computed after the join — a fan-out, not a bug in the aggregate function.
- Compute a total from the correct grain instead of joining extra tables "just in case."

## Business context

A finance report asked "total revenue for orders that have shipped" and someone wrote a query that joins
`orders`, `order_items`, and `shipments` because shipping status lives in `shipments`. The number came out
too high and nobody could see why.

## Scenario

One order in the dataset was split into two physical shipments. `shipments` has one row per shipment, not
per order — an order can have more than one.

## Input assumptions

- Order 21 has exactly 2 rows in `shipments` (a split shipment); every other shipped/delivered/returned
  order has exactly 1.

## Task

Return the total revenue (`quantity * unit_price * (1 - discount_pct/100)`, rounded to 2 decimals) across
all `order_items` belonging to orders with status `'shipped'`, `'delivered'`, or `'returned'`. You do not
need shipment-level detail for this — only the fact that the order *has* shipped.

## Constraints

- Every order line must be counted exactly once, even if its order was split into multiple shipments.
- Do not include `'placed'` or `'cancelled'` orders.

## Expected output

<!-- expected:start -->
| total_revenue |
|---|
| 10911.41 |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Ask what table actually tells you "this order has shipped" — you need that fact, not a join to every shipment row.
</details>
<details><summary>Hint 2</summary>
`orders.status` already carries shipped/delivered/returned — `shipments` is not needed at all to answer this question.
</details>
<details><summary>Hint 3</summary>
`SELECT ROUND(SUM(quantity*unit_price*(1-discount_pct/100)),2) FROM order_items oi JOIN orders o ON o.order_id=oi.order_id WHERE o.status IN ('shipped','delivered','returned')` — two tables, not three.
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status IN ('shipped', 'delivered', 'returned');
```

## Explanation

**Grain.** The natural grain of "revenue" is `order_items` — one row per product line. `orders` is
joined only to filter by status, at a 1:1 relationship (each item's order is exactly one order).
**Rows that survive.** Every `order_items` row whose parent order is shipped, delivered, or returned.
**Filtering.** `o.status IN (...)` on the `orders` side, applied after a join that does not change
`order_items`' row count.
**Join cardinality.** `order_items` to `orders` is many-to-one — safe to join without inflating rows.
`order_items` and `shipments` are two independent one-to-many children of the same order (there is no
direct relationship between them). Joining both through `orders` multiplies rows — an order with N items
and M shipments produces N×M joined rows, so each item row repeats once per shipment (a fan-out) — and
that join is not needed here, so it must be avoided.
**Aggregation.** `SUM` over the correctly-scoped row set, rounded once at the end rather than per row.
**NULL behavior.** Not applicable — `quantity`, `unit_price`, and `discount_pct` are all `NOT NULL` in
this schema.
**Why it is correct.** Verified against the dataset: 10911.41, matching a manual per-order-item sum.
**What could make it slow.** Nothing at this size; at scale, an index on `orders.status` helps the filter,
and the join itself is on primary/foreign keys already indexed.
**How to validate.** Add `shipments` back with a `COUNT(DISTINCT oi.order_item_id)` alongside `SUM` — if
the distinct-item count matches the row count, no fan-out occurred; here it would not match once
`shipments` is joined, because order 21's items appear twice.

## Common mistakes

**Joining `shipments` because "shipped" sounds like it belongs there** — order 21 has 2 shipment rows, so
every one of its order-item rows is counted twice, inflating the total from 10911.41 to 11360.39.
```sql wrong
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN shipments s ON s.order_id = o.order_id
WHERE o.status IN ('shipped', 'delivered', 'returned');
```

## Edge cases

- If an order had zero shipment rows (e.g., still `'placed'`), joining `shipments` would drop it entirely
  via INNER JOIN — a second, opposite failure mode from the same unnecessary join.
- Order 21's fan-out inflates by exactly its own item total (repeated once) — always check whether a
  "wrong" total is *higher* than a trusted baseline; inflation is the fingerprint of a fan-out.

## Performance notes

Removing the unneeded `shipments` join also removes an unneeded table scan/index lookup — this is a case
where the more "correct" query is also the cheaper one, not a trade-off.

## Optional challenge

Write a version that also reports how many shipments each affected order had, in a separate query,
without letting that join touch the revenue calculation.

## Related

Module: [03_Joins](../../03_Joins/) · Related: [EX-03-001](EX-03-001_customers-with-zero-orders.md)
