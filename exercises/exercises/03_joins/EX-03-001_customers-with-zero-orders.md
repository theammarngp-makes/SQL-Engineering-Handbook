---
id: EX-03-001
title: Customers With Zero Orders
module: 03_Joins
category: JOINS
difficulty: EASY
level: L2
estimated_time_min: 10
business_domain: E-commerce
dataset: ecommerce
tables: [customers, orders]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Choose `LEFT JOIN ... WHERE right.key IS NULL` (or `NOT EXISTS`) over `INNER JOIN` when the customers
  with *no match at all* are the answer, not an error to filter away.

## Business context

Retention wants a list of signed-up customers who have never placed a single order, to target with a
first-purchase incentive.

## Scenario

`orders.customer_id` references `customers.customer_id`; not every customer has a matching row.

## Input assumptions

- 24 customers, 49 orders; the orders reference 19 distinct customers.

## Task

List every customer who has never placed an order: `customer_id`, `full_name`, `signup_date`.

## Constraints

- A customer who placed an order that was later `cancelled` HAS ordered — do not treat cancelled orders
  as "never ordered."

## Expected output

<!-- expected:start -->
| customer_id | full_name | signup_date |
|---|---|---|
| 14 | Kabir Malhotra | 2025-02-11 |
| 21 | Tomas Novak | 2025-05-13 |
| 22 | Hana Sato | 2025-05-27 |
| 23 | Ethan Clark | 2025-06-03 |
| 24 | Nisha Verma | 2025-06-10 |

_5 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
An `INNER JOIN` between `customers` and `orders` can only ever produce customers who HAVE an order — it structurally cannot answer "who has none."
</details>
<details><summary>Hint 2</summary>
`LEFT JOIN customers TO orders`, then look at which rows have no matching order — the join fills the order side with NULLs for those rows.
</details>
<details><summary>Hint 3</summary>
`LEFT JOIN orders o ON o.customer_id = c.customer_id WHERE o.order_id IS NULL` — or equivalently `NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)`.
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    c.customer_id,
    c.full_name,
    c.signup_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
```

## Explanation

**Grain.** One row per customer.
**Rows that survive.** Customers with zero matching rows in `orders`, of any status.
**Filtering.** `WHERE o.order_id IS NULL` happens *after* the LEFT JOIN and specifically tests the
right-hand table's key, not a nullable business column — filtering on `o.status IS NULL` would be wrong,
since a matched row's status is never NULL.
**Join cardinality.** LEFT JOIN preserves every `customers` row once, regardless of how many (zero, in
this filtered case) orders it matches.
**Aggregation.** None needed — this is a set-membership question, not a count.
**NULL behavior.** The NULL being tested is one the join itself manufactures (all `orders.*` columns
become NULL for an unmatched customer) — it is not a NULL that was already stored in the data.
**Why it is correct.** Verified: 19 of 24 customers appear in `orders`; these are exactly the other 5.
**What could make it slow.** A full scan of both tables is unavoidable for "customers with no match";
an index on `orders.customer_id` helps the anti-join execute as an index lookup per customer rather than
a full table scan of `orders` per customer.
**How to validate.** `(rows here) + COUNT(DISTINCT customer_id) FROM orders` should equal 24 — and does (5 + 19).

## Common mistakes

**Using `INNER JOIN` and then filtering for "no order"** — an INNER JOIN has already discarded exactly
the rows the question is asking for, so no WHERE clause can recover them; this returns an empty set, not
an error, which makes the bug easy to miss.
```sql wrong
SELECT c.customer_id, c.full_name, c.signup_date
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
```

## Edge cases

- If a customer had an order row with a NULL `order_id` this pattern would break — not possible here,
  since `order_id` is the primary key and can never be NULL.

## Performance notes

At 24 customers this is trivial; at production scale, `NOT EXISTS` and `LEFT JOIN ... IS NULL` compile
to similar anti-join plans in MySQL 8 — verify with `EXPLAIN` rather than assuming one is always faster.

## Optional challenge

Rewrite the solution using `NOT EXISTS` and confirm with `EXPLAIN` whether MySQL chooses a different plan.

## Related

Module: [03_Joins](../../03_Joins/) · Related: [EX-03-002](EX-03-002_revenue-without-shipment-fan-out.md)
