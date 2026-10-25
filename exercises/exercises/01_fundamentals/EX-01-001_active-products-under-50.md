---
id: EX-01-001
title: Active Products Under $50
module: 01_Fundamentals
category: FOUNDATIONS
difficulty: BEGINNER
level: L1
estimated_time_min: 5
business_domain: E-commerce
dataset: ecommerce
tables: [products]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Combine `WHERE` with more than one condition and `ORDER BY` on a single table — the foundation every
  later module builds on.

## Business context

A merchandiser is putting together a "budget picks" shelf and wants only products that are both
currently sellable and priced under $50.

## Scenario

`products.is_active` marks whether a product can currently be sold; `unit_price` is its current list price.

## Input assumptions

- 12 products total; 1 is inactive (`is_active = 0`).

## Task

List every active product priced under $50: `product_name`, `unit_price`, cheapest first.

## Constraints

- Exclude the inactive product even if it would otherwise qualify on price.
- Exclude any active product priced at exactly $50 or more.

## Expected output

<!-- expected:start -->
| product_name | unit_price |
|---|---|
| Data Storytelling Book | 28.00 |
| Practical SQL Paperback | 34.00 |
| USB-C Hub | 39.00 |
| Coffee Grinder | 45.00 |

_4 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Two independent conditions on the same table both belong in one `WHERE` clause, joined with `AND`.
</details>
<details><summary>Hint 2</summary>
`is_active` is a `TINYINT(1)` flag — compare it to `1`, not to the string `'true'`.
</details>
<details><summary>Hint 3</summary>
`WHERE is_active = 1 AND unit_price < 50 ORDER BY unit_price ASC`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    product_name,
    unit_price
FROM products
WHERE is_active = 1
  AND unit_price < 50
ORDER BY unit_price ASC;
```

## Explanation

**Grain.** One row per product.
**Rows that survive.** Active products (`is_active = 1`) priced strictly under $50.
**Filtering.** Both conditions are independent facts about the same row, so a single `AND`ed `WHERE`
clause is sufficient — no join or subquery is needed.
**Join cardinality.** N/A, single table.
**Aggregation.** None; this is a row-level filter and sort.
**NULL behavior.** Not applicable — `is_active` and `unit_price` are both `NOT NULL` in this schema.
**Why it is correct.** Verified against the dataset: 4 of the 11 active products are under $50.
**What could make it slow.** Nothing at this size; an index on `(is_active, unit_price)` would help this
exact filter+sort pattern at production scale.
**How to validate.** Manually check the excluded inactive product's price against $50 — if it happens to
be under $50, confirming it does NOT appear in the result proves the `is_active` filter is working.

## Common mistakes

**Forgetting the active-only filter** — the inactive product is a Desk Lamp priced at 29.50, which would
incorrectly appear in the "budget picks" list if `is_active` isn't checked.
```sql wrong
SELECT product_name, unit_price
FROM products
WHERE unit_price < 50
ORDER BY unit_price ASC;
```

## Edge cases

- A product priced at exactly $50.00 would correctly be excluded by `< 50`; using `<= 50` would be a
  different, wider question than the one asked.

## Performance notes

Trivial at this table size; this exercise exists to establish the WHERE/ORDER BY pattern, not to teach
performance — see Module 15 for indexing this kind of filter at scale.

## Optional challenge

Add a column showing each product's discount-from-$50 (`50 - unit_price`) to support a "how much cheaper"
follow-up question from merchandising.

## Related

Module: [01_Fundamentals](../../01_Fundamentals/)
