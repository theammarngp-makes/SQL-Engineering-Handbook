---
id: EX-14-001
title: A View That Encodes "Eligible Revenue" Once
module: 14_VIEWS
category: DATABASE_ENGINEERING
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 15
business_domain: E-commerce
dataset: ecommerce
tables: [orders, order_items]
mysql_version: "8.0"
mutates: "true"
related_interview: null
---

## Learning objectives

- Create a view that encapsulates a business rule (which order statuses count as "eligible revenue") so
  every analyst queries the same definition instead of re-typing the status list — and re-risking the
  exact join-fan-out mistake from EX-03-002 by "helpfully" adding a table the view never needed.
- Query a view exactly like a table, confirming it behaves as a saved, reusable `SELECT`.

## Business context

After EX-03-002 surfaced a revenue-inflating bug from an unnecessary join, the team wants a single,
reviewed definition of "eligible revenue" that every future report reads from, instead of every analyst
re-deriving the status filter (and the risk of getting it wrong) themselves.

## Scenario

"Eligible" order statuses for revenue purposes are `'shipped'`, `'delivered'`, and `'returned'` — the same
definition already established in earlier exercises.

## Input assumptions

- `order_items` has 91 rows across 49 orders; the eligible subset was already computed in EX-03-002.

## Task

Create a view named `vw_eligible_order_items` that exposes `order_item_id`, `order_id`, `product_id`,
`quantity`, `unit_price`, `discount_pct`, and `line_revenue` (the per-line revenue, already computed) for
order items belonging only to eligible orders. Then query it for the total revenue across all eligible
line items.

## Constraints

- The view itself must contain the status filter — a caller must not need to know or repeat which
  statuses count as eligible.
- The final total must match EX-03-002's verified figure exactly.

## Expected output

<!-- expected:start -->
| total_revenue |
|---|
| 10911.41 |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
A view is just a saved `SELECT` — write the correct query first (you already have it from EX-03-002), then wrap it in `CREATE VIEW ... AS`.
</details>
<details><summary>Hint 2</summary>
Compute `line_revenue` inside the view itself so callers never repeat the `quantity * unit_price * (1 - discount_pct/100)` formula either.
</details>
<details><summary>Hint 3</summary>
`CREATE VIEW vw_eligible_order_items AS SELECT oi.*, oi.quantity*oi.unit_price*(1-oi.discount_pct/100) AS line_revenue FROM order_items oi JOIN orders o ON o.order_id=oi.order_id WHERE o.status IN ('shipped','delivered','returned');` then `SELECT ROUND(SUM(line_revenue),2) AS total_revenue FROM vw_eligible_order_items;`
</details>

## Solution

_MySQL 8.0+._

```sql setup
CREATE VIEW vw_eligible_order_items AS
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100) AS line_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status IN ('shipped', 'delivered', 'returned');
```

```sql
SELECT ROUND(SUM(line_revenue), 2) AS total_revenue
FROM vw_eligible_order_items;
```

## Explanation

**Grain.** The view is at `order_items` grain (one row per eligible line item); the final query
aggregates that down to a single total.
**Rows that survive.** Only line items whose parent order is shipped, delivered, or returned — the
filter lives inside the view, not in the caller's query.
**Filtering.** `WHERE o.status IN (...)` is written exactly once, inside `CREATE VIEW`, permanently.
**Join cardinality.** The view itself joins `order_items` to `orders` many-to-one to apply the status
filter — the same safe join used correctly in EX-03-002, and the view exists specifically so nobody adds
`shipments` back in "to be thorough" as EX-03-002's wrong-answer did.
**Aggregation.** The view does no aggregation; `SUM` happens only in the query against the view, which is
free to aggregate the view's rows however each report needs.
**NULL behavior.** Not applicable to the underlying columns.
**Why it is correct.** The total (10911.41) is identical to EX-03-002's independently-verified figure,
which is exactly the point: the view is a saved version of that same correct query, not a new calculation.
**What could make it slow.** A view is not materialized in MySQL by default — querying it re-runs its
definition each time, so the view itself doesn't add or remove any performance characteristic already
discussed for the underlying join in EX-03-002.
**How to validate.** Re-run EX-03-002's original query directly (without the view) and confirm it still
produces 10911.41 — if the view and the original query ever disagree, the view's definition has drifted.

## Common mistakes

**Adding `shipments` into the view "to be complete about shipping status"** — this reintroduces the exact
fan-out bug from EX-03-002, except now it's baked into a view every future report will silently inherit,
making the bug far more expensive to find because it no longer looks like a one-off query mistake.
```sql wrong
SELECT ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN shipments s ON s.order_id = o.order_id
WHERE o.status IN ('shipped', 'delivered', 'returned');
```

## Edge cases

- Dropping or altering the view later would silently change every report built on top of it — a view
  centralizes the definition, which is the goal, but also means a single mistaken edit now has a wider
  blast radius than a mistake in one report's own query.

## Performance notes

MySQL does not materialize this view automatically; each query against it re-executes the underlying join
and filter. For a genuinely expensive underlying query used very frequently, a materialized-table
refresh strategy would be a separate, deliberate engineering decision — not something a plain view gives
you for free.

## Optional challenge

Add a second view, `vw_monthly_eligible_revenue`, built on top of `vw_eligible_order_items`, that
pre-aggregates revenue by month — and confirm its numbers tie back to a direct `GROUP BY` query.

## Related

Module: [14_VIEWS](../../14_VIEWS/) · Related: [EX-03-002](../03_joins/EX-03-002_revenue-without-shipment-fan-out.md)
