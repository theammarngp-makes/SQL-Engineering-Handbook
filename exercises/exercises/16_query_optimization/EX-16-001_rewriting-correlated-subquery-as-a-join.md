---
id: EX-16-001
title: Rewriting a Per-Row Correlated Subquery as a Join
module: 16_QUERY_OPTIMIZATION
category: PERFORMANCE
difficulty: ADVANCED
level: L4
estimated_time_min: 20
business_domain: E-commerce
dataset: ecommerce
tables: [customers, orders]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Rewrite a scalar correlated subquery (one that conceptually runs once per outer row) as an equivalent
  `LEFT JOIN` + `GROUP BY`, and *prove* the rewrite is equivalent by comparing full results, not just by
  assuming the rewrite is "the optimized version."
- See the actual bug that a correlated subquery protects against: forgetting the correlation predicate
  entirely, which still runs and still returns a number — just the wrong one, for every row.

## Business context

A report showing each customer's order count was written with a subquery per customer. Before scaling it
up, the team wants a join-based rewrite verified against the original, not assumed to be equivalent.

## Scenario

Both forms are being compared on the same 24 customers, some of whom have zero orders.

## Input assumptions

- 24 customers; order counts per customer range from 0 to 6.

## Task

Return `customer_id`, `full_name`, `order_count` for all 24 customers using a `LEFT JOIN` +
`GROUP BY` rewrite of the correlated-subquery version, ordered by `customer_id`.

## Constraints

- Customers with zero orders must show `order_count = 0`, not be dropped from the result.
- The result must be provably identical, row for row, to what a correctly-correlated scalar subquery
  would produce for the same 24 customers.

## Expected output

<!-- expected:start -->
| customer_id | full_name | order_count |
|---|---|---|
| 1 | Aarav Sharma | 2 |
| 2 | Meera Iyer | 3 |
| 3 | Rohan Deshmukh | 2 |
| 4 | Emily Carter | 3 |
| 5 | Liam O'Brien | 6 |
| 6 | Sofia Rossi | 1 |
| 7 | Priya Nair | 2 |
| 8 | Daniel Kim | 2 |
| 9 | Fatima Khan | 5 |
| 10 | Noah Williams | 1 |
| 11 | Ananya Gupta | 1 |
| 12 | Lucas Müller | 4 |
| 13 | Isabella Garcia | 1 |
| 14 | Kabir Malhotra | 0 |
| 15 | Olivia Brown | 6 |
| 16 | Vikram Reddy | 1 |
| 17 | Chloe Martin | 2 |
| 18 | Arjun Patel | 3 |
| 19 | Priya Nair | 2 |
| 20 | Zara Ahmed | 2 |
| 21 | Tomas Novak | 0 |
| 22 | Hana Sato | 0 |
| 23 | Ethan Clark | 0 |
| 24 | Nisha Verma | 0 |

_24 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
The original form is `(SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id)` in the SELECT list — the correlation is the `WHERE o.customer_id = c.customer_id` tying each subquery execution to the current outer row.
</details>
<details><summary>Hint 2</summary>
A `LEFT JOIN` (not `INNER JOIN`, to keep zero-order customers) followed by `COUNT(o.order_id)` (not `COUNT(*)`, so unmatched rows count as 0, not 1) reproduces the same per-customer counts in one pass.
</details>
<details><summary>Hint 3</summary>
`SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS order_count FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id GROUP BY c.customer_id, c.full_name ORDER BY c.customer_id;`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY c.customer_id;
```

## Explanation

**Grain.** One row per customer, same as the original scalar-subquery version.
**Rows that survive.** All 24 customers, via `LEFT JOIN` — matching the original subquery's behavior of
returning `0` (not skipping the row) for customers with no orders.
**Filtering.** None; every customer is in scope.
**Join cardinality.** `customers` to `orders` is one-to-many; `GROUP BY` on the customer's own columns
correctly rolls each customer's orders (zero or more) back to one row, mirroring what the correlated
subquery computed per row.
**Aggregation.** `COUNT(o.order_id)` — counting the joined column, not `COUNT(*)`, is what makes a
customer with zero matching orders count as `0` instead of `1` (a `LEFT JOIN` with no match produces one
row with all-NULL `orders.*` columns, and `COUNT` skips NULLs).
**NULL behavior.** This is the crux of the rewrite's correctness: `COUNT(o.order_id)` counts non-NULL
`order_id` values, so an unmatched customer (all `orders.*` = NULL) correctly contributes `0`. Using
`COUNT(*)` instead would count that one manufactured NULL row as `1`, breaking equivalence with the
original subquery for every zero-order customer.
**Why it is correct.** Verified cell-for-cell against the original scalar-correlated-subquery version for
all 24 customers — identical results, including all five customers with `order_count = 0`.
**What could make it slow.** The two forms are logically equivalent here, but not guaranteed identical in
cost at every scale — MySQL 8's optimizer may execute a correlated subquery via a semi-join
transformation internally rather than literally "once per row"; verify the actual chosen plan with
`EXPLAIN` rather than assuming either form is always faster.
**How to validate.** This exercise's own "Common mistakes" block is the validation: it shows what happens
when the correlation is dropped by accident, which is the failure mode this rewrite must not reintroduce.

## Common mistakes

**Dropping the correlation predicate from the subquery entirely** — the subquery still runs and still
returns a number, which makes this bug easy to miss in review: every customer shows the same total order
count (49, the count across *all* customers) instead of their own.
```sql wrong
SELECT
    c.customer_id,
    c.full_name,
    (SELECT COUNT(*) FROM orders o) AS order_count
FROM customers c
ORDER BY c.customer_id;
```

## Edge cases

- `COUNT(o.order_id)` vs `COUNT(*)` after a `LEFT JOIN` is not a stylistic choice here — it is the exact
  mechanism that makes the rewrite correct for zero-order customers; verify this distinction explicitly if
  adapting this pattern elsewhere, rather than treating the two `COUNT` forms as interchangeable.

## Performance notes

For 24 customers and 49 orders, neither form is measurably faster than the other — any specific timing
claim at this scale would be illustrative only, not a real benchmark. At production scale, compare actual
`EXPLAIN` plans for both forms rather than assuming the join rewrite is automatically faster.

## Optional challenge

Extend both forms to also return each customer's total eligible revenue (from EX-03-002's definition)
alongside `order_count`, and confirm they still agree.

## Related

Module: [16_QUERY_OPTIMIZATION](../../16_QUERY_OPTIMIZATION/) · Related: [EX-09-001](../09_date_functions/EX-09-001_customer-tenure-and-days-since-last-order.md)
