---
id: EX-11-001
title: Amount Actually Collected per Order
module: 11_NULL_HANDLING_AND_DATA_CLEANING
category: NULL_LOGIC
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 20
business_domain: E-commerce
dataset: ecommerce
tables: [orders, payments]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Aggregate a status-typed table (`payments`) by the status that actually matters, instead of every row.
- See that "how much did we collect" is a `payment_status = 'captured'` question, not a `COUNT(*)` question.

## Business context

Finance is reconciling orders that show more than one payment attempt — some are legitimate split
payments, others are a failed card retried on a second method. They want the real amount collected per
order, not the sum of every attempt.

## Scenario

`payments` can have several rows per order: a failed attempt followed by a successful retry, or a
deliberate split across two payment methods. `payment_status` is `'captured'`, `'failed'`, or `'pending'`.

## Input assumptions

- Exactly 2 orders in the dataset have more than one row in `payments`: order 16 (one failed attempt of
  177.50, then a captured retry of 177.50) and order 19 (two captured payments, 800.00 and 754.00, by design).

## Task

For every order with more than one payment row, return `order_id` and the amount actually collected
(the sum of `amount` where `payment_status = 'captured'`), ordered by `order_id`.

## Constraints

- A `failed` payment must contribute nothing to the collected amount, even though a real charge attempt
  was made.
- An order with zero captured payments should show `0.00`, not be silently dropped (none exist in this
  dataset, but the query must not assume every order has at least one captured row).

## Expected output

<!-- expected:start -->
| order_id | amount_collected |
|---|---|
| 16 | 177.50 |
| 19 | 1554.00 |

_2 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
More than one payment row does not mean more than one successful payment — check what `payment_status` is doing before you sum.
</details>
<details><summary>Hint 2</summary>
Sum `amount` but only where `payment_status = 'captured'` — put that condition in the SUM's CASE, or filter before aggregating, not after.
</details>
<details><summary>Hint 3</summary>
`SUM(CASE WHEN payment_status = 'captured' THEN amount ELSE 0 END)` inside a `GROUP BY order_id` on `payments` filtered or joined to the multi-payment order list.
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    p.order_id,
    SUM(CASE WHEN p.payment_status = 'captured' THEN p.amount ELSE 0 END) AS amount_collected
FROM payments p
WHERE p.order_id IN (
    SELECT order_id FROM payments GROUP BY order_id HAVING COUNT(*) > 1
)
GROUP BY p.order_id
ORDER BY p.order_id;
```

## Explanation

**Grain.** `payments` is one row per payment *attempt*, not per order — this query rolls it up to one
row per order.
**Rows that survive.** All payment attempts belonging to the two orders that have more than one attempt
each (found via the `HAVING COUNT(*) > 1` subquery).
**Filtering.** Two filters at two different stages: the subquery selects *which orders* to look at
(orders with multiple attempts); the `CASE` inside `SUM` selects *which rows count toward money* — a
failed attempt is still a row, but contributes 0.
**Join cardinality.** No join to `orders` was needed since only `payments.order_id` is used; adding
`orders` here would be an unnecessary join like the one in EX-03-002.
**Aggregation.** `SUM(CASE WHEN ... THEN amount ELSE 0 END)`, a status-filtered sum, versus a plain
`SUM(amount)` which would include failed attempts.
**NULL behavior.** Not applicable to `amount` (never NULL), but the pattern generalizes: conditional
aggregation is how you avoid a plain `SUM` silently including rows you didn't mean to count — the same
shape as excluding NULLs, just triggered by a status flag instead of a NULL.
**Why it is correct.** Verified: order 16 has one captured row (177.50) and one failed (177.50, excluded);
order 19 has two captured rows summing to 1554.00.
**What could make it slow.** Nothing here; at scale, an index on `(order_id, payment_status)` would make
both the subquery and the conditional sum efficient.
**How to validate.** For order 16, confirm `SUM(amount)` across all its rows is 355.00 (double the
collected amount) — the gap between that and 177.50 is exactly the failed retry, which is the check that
would have caught this bug before it reached finance.

## Common mistakes

**Summing every payment row regardless of status** — order 16 comes out as 355.00, double what was
actually collected, because the failed attempt is added in alongside the successful retry.
```sql wrong
SELECT
    p.order_id,
    SUM(p.amount) AS amount_collected
FROM payments p
WHERE p.order_id IN (
    SELECT order_id FROM payments GROUP BY order_id HAVING COUNT(*) > 1
)
GROUP BY p.order_id
ORDER BY p.order_id;
```

## Edge cases

- An order with multiple payment rows that are ALL failed would correctly show `0.00` under the solution
  query but would show a nonzero, wrong number under the naive `SUM(amount)` — not present in this
  dataset, but worth stating explicitly since finance will eventually see one.
- Order 19's two payments are *both* captured by design — the solution and the naive query agree there,
  which is exactly why order 16 (not order 19) is the one that exposes the bug.

## Performance notes

Conditional aggregation (`SUM(CASE WHEN ...)`) is typically cheaper than a self-join or a correlated
subquery per row for this kind of per-order, per-status rollup — one pass over `payments`.

## Optional challenge

Extend the query to every order (not just multi-payment ones), and add a column flagging orders where
`amount_collected` doesn't match the order's `order_items` total (the same mismatch tested in the
dataset's known trap on order 28).

## Related

Module: [11_NULL_HANDLING_AND_DATA_CLEANING](../../11_NULL_HANDLING_AND_DATA_CLEANING/) · Related: [EX-03-002](../03_joins/EX-03-002_revenue-without-shipment-fan-out.md)
