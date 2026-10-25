---
id: EX-10-001
title: Finding Duplicate Customers by Normalized Email
module: 10_STRING_FUNCTIONS
category: STRING_ANALYTICS
difficulty: EASY
level: L2
estimated_time_min: 15
business_domain: E-commerce
dataset: ecommerce
tables: [customers]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `LOWER()` (and `TRIM()`) to normalize a text column before comparing or grouping on it — email
  addresses are case-insensitive by convention, but stored exactly as typed.
- See why `COUNT(DISTINCT email)` and `COUNT(DISTINCT LOWER(email))` can legitimately disagree, and what
  that disagreement means operationally.

## Business context

Marketing's email tool is reporting a lower unique-recipient count than the number of customer rows, and
wants to know which rows are actually the same person typed in twice.

## Scenario

`customers.email` has no case-insensitive uniqueness constraint — two rows can hold the same address with
different capitalization and both pass validation.

## Input assumptions

- 24 customer rows. Exactly one pair shares the same email once case is normalized.

## Task

Find every group of customers who share the same email address once case differences are ignored:
`normalized_email`, `customer_ids` (comma-separated, ascending), `duplicate_count`.

## Constraints

- Only report groups with more than one customer — do not list every unique email.
- Comparison must be case-insensitive; two emails differing only in letter case count as the same address.

## Expected output

<!-- expected:start -->
| normalized_email | customer_ids | duplicate_count |
|---|---|---|
| priya.nair@example.com | 7,19 | 2 |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Grouping directly on `email` won't catch this — `'Priya.Nair@example.com'` and `'priya.nair@example.com'` are different strings to a case-sensitive `GROUP BY` on some collations, and even where the collation is case-insensitive, the *displayed* value would still differ.
</details>
<details><summary>Hint 2</summary>
Group by `LOWER(email)` instead of `email` directly, and use that same normalized expression for both grouping and display.
</details>
<details><summary>Hint 3</summary>
`SELECT LOWER(email) AS normalized_email, GROUP_CONCAT(customer_id ORDER BY customer_id) AS customer_ids, COUNT(*) AS duplicate_count FROM customers GROUP BY LOWER(email) HAVING COUNT(*) > 1;`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    LOWER(email)                                AS normalized_email,
    GROUP_CONCAT(customer_id ORDER BY customer_id) AS customer_ids,
    COUNT(*)                                    AS duplicate_count
FROM customers
GROUP BY LOWER(email)
HAVING COUNT(*) > 1;
```

## Explanation

**Grain.** One row per distinct normalized email that has more than one matching customer row.
**Rows that survive.** Only groups with `COUNT(*) > 1` — every other email is unique and excluded by the
`HAVING` clause.
**Filtering.** `HAVING COUNT(*) > 1` runs after grouping, since "more than one row in the group" can only
be evaluated once the grouping has happened.
**Join cardinality.** N/A, single table.
**Aggregation.** `COUNT(*)` per normalized-email group; `GROUP_CONCAT` collects the matching
`customer_id`s into one readable string per group, explicitly ordered for determinism.
**NULL behavior.** Not applicable — `email` is `NOT NULL` in this schema.
**Why it is correct.** Verified against the dataset: customers 7 and 19 are both "Priya Nair" with the
same address differing only in capitalization; every other email is unique.
**What could make it slow.** `LOWER(email)` on every row prevents a plain index on `email` from being used
for this specific grouping; a functional index on `(LOWER(email))` (MySQL 8.0.13+) would let this become
an index-backed aggregation at scale.
**How to validate.** `SELECT COUNT(*) FROM customers` (24) minus `SELECT COUNT(DISTINCT LOWER(email)) FROM
customers` should equal `duplicate_count - 1` summed across all groups this query returns (here: 1).

## Common mistakes

**Grouping on `email` directly without normalizing case** — this schema's `email` column uses a
case-sensitive collation (`utf8mb4_0900_as_cs`) specifically so this mistake is real, not theoretical: a
plain `GROUP BY email` treats the two spellings as different values and finds **zero** duplicate groups,
completely missing the pair that the normalized version correctly finds.
```sql wrong
SELECT
    email                                        AS normalized_email,
    GROUP_CONCAT(customer_id ORDER BY customer_id) AS customer_ids,
    COUNT(*)                                     AS duplicate_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;
```

## Edge cases

- Leading/trailing whitespace (e.g., `' priya.nair@example.com'`) would not be caught by `LOWER()` alone —
  that needs `TRIM()` as well; none of the 24 rows in this dataset has that issue, so it does not change
  this exercise's expected output, but a production version should still normalize both.

## Performance notes

At 24 rows this is instantaneous; at scale, normalize once into a stored/generated column or a functional
index rather than recomputing `LOWER(email)` on every query that needs deduplication.

## Optional challenge

Extend the query to also flag near-duplicates from whitespace using `TRIM(LOWER(email))`, and confirm the
result is unchanged for this dataset (since no row here has stray whitespace).

## Related

Module: [10_STRING_FUNCTIONS](../../10_STRING_FUNCTIONS/) · Related: [datasets/ecommerce](../../datasets/ecommerce/README.md)
