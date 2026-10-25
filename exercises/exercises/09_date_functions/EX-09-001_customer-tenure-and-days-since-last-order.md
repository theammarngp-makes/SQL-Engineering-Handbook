---
id: EX-09-001
title: Customer Tenure and Days Since Last Order
module: 09_Date_Functions
category: DATE_ANALYTICS
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 15
business_domain: E-commerce
dataset: ecommerce
tables: [customers, orders]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `TIMESTAMPDIFF` for a whole-unit calendar difference (months) versus `DATEDIFF` for a simple day
  count, and know which one answers which kind of question.
- Handle customers with no matching rows in an aggregate date calculation without losing them from the
  result — `MAX()` over zero rows is `NULL`, not zero or an error.

## Business context

Customer success wants two numbers per customer for a health-score model: how long they've been a
customer, and how long since they last ordered — including customers who have never ordered at all.

## Scenario

"As of" date for this report is 2025-07-01, one day after the dataset's last recorded activity.

## Input assumptions

- 24 customers; 5 of them have never placed an order.

## Task

For every customer, return `customer_id`, `full_name`, `tenure_months` (whole months since signup, as of
2025-07-01), and `days_since_last_order` (as of 2025-07-01, `NULL` if they've never ordered).

## Constraints

- Every one of the 24 customers must appear exactly once, including the 5 with no orders.
- `days_since_last_order` must be `NULL`, not `0` or an error, for customers with no orders.

## Expected output

<!-- expected:start -->
| customer_id | full_name | tenure_months | days_since_last_order |
|---|---|---|---|
| 1 | Aarav Sharma | 12 | 35 |
| 2 | Meera Iyer | 11 | 28 |
| 3 | Rohan Deshmukh | 10 | 61 |
| 4 | Emily Carter | 9 | 25 |
| 5 | Liam O'Brien | 9 | 14 |
| 6 | Sofia Rossi | 8 | 131 |
| 7 | Priya Nair | 7 | 148 |
| 8 | Daniel Kim | 7 | 17 |
| 9 | Fatima Khan | 6 | 136 |
| 10 | Noah Williams | 6 | 108 |
| 11 | Ananya Gupta | 5 | 162 |
| 12 | Lucas Müller | 5 | 16 |
| 13 | Isabella Garcia | 4 | 39 |
| 14 | Kabir Malhotra | 4 | NULL |
| 15 | Olivia Brown | 4 | 15 |
| 16 | Vikram Reddy | 3 | 83 |
| 17 | Chloe Martin | 3 | 77 |
| 18 | Arjun Patel | 2 | 2 |
| 19 | Priya Nair | 2 | 57 |
| 20 | Zara Ahmed | 2 | 4 |
| 21 | Tomas Novak | 1 | NULL |
| 22 | Hana Sato | 1 | NULL |
| 23 | Ethan Clark | 0 | NULL |
| 24 | Nisha Verma | 0 | NULL |

_24 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
`LEFT JOIN` from `customers` to `orders` so customers with none are kept, then aggregate.
</details>
<details><summary>Hint 2</summary>
`TIMESTAMPDIFF(MONTH, signup_date, '2025-07-01')` counts whole calendar months; `DATEDIFF('2025-07-01', MAX(order_date))` counts plain days and automatically returns NULL if `MAX(order_date)` is NULL.
</details>
<details><summary>Hint 3</summary>
`SELECT c.customer_id, c.full_name, TIMESTAMPDIFF(MONTH, c.signup_date, '2025-07-01') AS tenure_months, DATEDIFF('2025-07-01', MAX(o.order_date)) AS days_since_last_order FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id GROUP BY c.customer_id, c.full_name, c.signup_date ORDER BY c.customer_id;`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    c.customer_id,
    c.full_name,
    TIMESTAMPDIFF(MONTH, c.signup_date, '2025-07-01') AS tenure_months,
    DATEDIFF('2025-07-01', MAX(o.order_date))         AS days_since_last_order
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.signup_date
ORDER BY c.customer_id;
```

## Explanation

**Grain.** One row per customer.
**Rows that survive.** All 24 customers, via `LEFT JOIN` — the 5 with no orders keep their row with
`MAX(order_date)` evaluating to `NULL`.
**Filtering.** None; this is a full-population report by design.
**Join cardinality.** `customers` to `orders` is one-to-many; `GROUP BY` on the customer's own columns
correctly rolls each customer's (possibly zero) orders back down to one row.
**Aggregation.** `MAX(order_date)` per customer, fed into `DATEDIFF`; `TIMESTAMPDIFF` operates directly on
`signup_date`, which needs no aggregation since it's already one value per customer.
**NULL behavior.** `MAX()` over an empty group (a customer with a LEFT JOIN match of all-NULL) returns
`NULL`, and `DATEDIFF(date, NULL)` correctly returns `NULL` rather than erroring — this is exactly the
propagation the constraint requires, and it happens automatically as long as `LEFT JOIN` (not `INNER
JOIN`) is used.
**Why it is correct.** Verified against the dataset for all 24 rows; customers 14, 21, 22, 23, and 24
correctly show `NULL` for `days_since_last_order`.
**What could make it slow.** Nothing at this size; an index on `orders.customer_id` (present via the
foreign key) supports the join efficiently at scale.
**How to validate.** The count of `NULL` rows in `days_since_last_order` (5) must equal the count of
customers with zero rows in `orders` — a separate `NOT EXISTS` check, as used in EX-03-001.

## Common mistakes

**Using `INNER JOIN` instead of `LEFT JOIN`** — silently drops the 5 never-ordered customers from the
report entirely, rather than showing them with a `NULL` recency value, which is a materially different
(and wrong, per the constraints) answer for a customer health-score model that specifically needs to see
who has never ordered.
```sql wrong
SELECT
    c.customer_id,
    c.full_name,
    TIMESTAMPDIFF(MONTH, c.signup_date, '2025-07-01') AS tenure_months,
    DATEDIFF('2025-07-01', MAX(o.order_date))         AS days_since_last_order
FROM customers c
INNER JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.signup_date
ORDER BY c.customer_id;
```

## Edge cases

- Customers 23 and 24 show `tenure_months = 0` — they signed up within the last month before the as-of
  date; this is a correct, expected value, not a sign of a bug.
- `TIMESTAMPDIFF(MONTH, ...)` counts whole elapsed months (e.g., Jan 15 to Feb 14 is 0 months, not 1) —
  worth confirming against the actual signup dates if the numbers ever look off by one.

## Performance notes

A single `LEFT JOIN` and aggregation pass; at scale, this pattern benefits from an index on
`orders.customer_id`, which already exists via the foreign key constraint in this schema.

## Optional challenge

Add a `customer_status` column that buckets each row into `'Never ordered'`, `'Active in last 90 days'`,
or `'Lapsed'` based on `days_since_last_order`, handling the `NULL` case explicitly rather than letting it
fall through a `CASE` with no matching branch.

## Related

Module: [09_Date_Functions](../../09_Date_Functions/) · Related: [EX-03-001](../03_joins/EX-03-001_customers-with-zero-orders.md)
