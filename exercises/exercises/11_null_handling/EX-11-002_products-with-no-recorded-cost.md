---
id: EX-11-002
title: Products With No Recorded Cost
module: 11_NULL_HANDLING_AND_DATA_CLEANING
category: NULL_LOGIC
difficulty: BEGINNER
level: L1
estimated_time_min: 10
business_domain: E-commerce
dataset: ecommerce
tables: [products]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Test for missing values with `IS NULL`; understand that `= NULL` never matches any row.

## Business context

Finance cannot compute margin for products whose cost was never entered and wants a list to chase down.

## Scenario

`products.cost_price` is NULL when cost has not yet been recorded; it is not zero.

## Input assumptions

- 12 products; exactly one has a NULL `cost_price`.

## Task

List `product_id`, `product_name`, `unit_price` for every product whose cost is not recorded.

## Constraints

- A cost of 0 would be a recorded value, not a missing one; do not test for it.

## Expected output

<!-- expected:start -->
| product_id | product_name | unit_price |
|---|---|---|
| 8 | Data Storytelling Book | 28.00 |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Comparing anything to NULL with `=` yields UNKNOWN, not TRUE.
</details>
<details><summary>Hint 2</summary>
SQL has a dedicated predicate for testing missing values.
</details>
<details><summary>Hint 3</summary>
`WHERE cost_price IS NULL`.
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT product_id, product_name, unit_price
FROM products
WHERE cost_price IS NULL
ORDER BY product_id;
```

## Explanation

**Grain.** One row per product.
**Rows that survive.** Only products whose `cost_price` is NULL.
**Filtering.** `WHERE cost_price IS NULL` is evaluated per row; rows evaluating to UNKNOWN are dropped, so only IS NULL can select NULLs.
**Join cardinality.** None; a single table.
**Aggregation.** None needed.
**NULL behavior.** NULL means "unknown"; `NULL = NULL` is UNKNOWN, not TRUE, so equality can never find it.
**Why it is correct.** Verified live: exactly one product (Data Storytelling Book) has a NULL cost.
**What could make it slow.** A full scan of 12 rows is trivial; on large tables an index on `cost_price` can serve `IS NULL` lookups in InnoDB.
**How to validate.** `SELECT COUNT(*) FROM products WHERE cost_price IS NULL` equals the number of rows returned.

## Common mistakes

**Using `= NULL`** — it is syntactically valid but never true, so the query silently returns zero rows instead of failing.
```sql wrong
SELECT product_id, product_name, unit_price
FROM products
WHERE cost_price = NULL
ORDER BY product_id;
```

## Edge cases

- If a future load stored 0 instead of NULL for unknown costs, this query would miss them; check the data dictionary.

## Performance notes

At this size it is trivial; behavior with indexes should be checked with `EXPLAIN`, not assumed.

## Optional challenge

Also list products whose cost is recorded but higher than `unit_price` (negative margin).

## Related

Module: [11_NULL_HANDLING_AND_DATA_CLEANING](../../11_NULL_HANDLING_AND_DATA_CLEANING/) · Related: [EX-11-001](EX-11-001_amount-actually-collected-per-order.md)
