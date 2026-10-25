---
id: EX-02-001
title: Customers by Segment, Including Unclassified
module: 02_Aggregations
category: AGGREGATION
difficulty: EASY
level: L2
estimated_time_min: 10
business_domain: E-commerce
dataset: ecommerce
tables: [customers]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `GROUP BY` on a column that contains NULL values without silently losing rows.
- Recognize that `GROUP BY segment` produces a group *for* NULL, it does not drop NULL rows.

## Business context

Marketing wants a headcount of customers per segment (`Retail` / `Wholesale`) for a slide, and asked
specifically to be told how many customers haven't been segmented yet, rather than have them disappear
from the count.

## Scenario

`customers.segment` is `'Retail'`, `'Wholesale'`, or `NULL` for customers who signed up before the
segmentation process existed.

## Input assumptions

- `customers` has 24 rows; 4 of them have `segment IS NULL`.

## Task

Return the number of customers per segment, labeling the unclassified group `'Unclassified'` instead of
leaving it blank, ordered from most to fewest customers.

## Constraints

- Every one of the 24 customers must be counted exactly once.
- Do not filter out NULL segments.
- Break ties in `customer_count` alphabetically by the displayed segment label, so the result order is deterministic.

## Expected output

<!-- expected:start -->
| segment | customer_count |
|---|---|
| Retail | 16 |
| Unclassified | 4 |
| Wholesale | 4 |

_3 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
`GROUP BY` treats all NULLs as one group already — the question is how to *label* that group, not how to keep it.
</details>
<details><summary>Hint 2</summary>
Wrap the grouping column in `COALESCE(segment, 'Unclassified')` — but group by that same expression, not the raw column, or you'll get two groups that look identical.
</details>
<details><summary>Hint 3</summary>
`SELECT COALESCE(segment, 'Unclassified') AS segment, COUNT(*) ... GROUP BY COALESCE(segment, 'Unclassified') ORDER BY COUNT(*) DESC, segment ASC`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    COALESCE(segment, 'Unclassified') AS segment,
    COUNT(*)                          AS customer_count
FROM customers
GROUP BY COALESCE(segment, 'Unclassified')
ORDER BY customer_count DESC, segment ASC;
```

## Explanation

**Grain.** One row per `customers.segment` value as it exists today — one row per customer, before grouping.
**Rows that survive.** All 24 customers; nothing is filtered.
**Filtering.** None — this is a pure aggregation, which is the point: a WHERE clause is the wrong tool
for handling NULL here.
**Join cardinality.** N/A, single table.
**Aggregation.** `COUNT(*)` counts rows per group; grouping on `COALESCE(segment, 'Unclassified')` merges
all NULLs into one labeled bucket instead of a separate, unlabeled `NULL` row.
**NULL behavior.** `GROUP BY segment` alone would still produce a correct count — MySQL groups NULLs
together — but the output row's `segment` column would display as `NULL`, not text, which is what this
exercise actually tests: presentation, not correctness of the count.
**Why it is correct.** Verified against the dataset: 16 Retail, 4 Wholesale, 4 NULL, summing to 24.
**What could make it slow.** Nothing at this size; at scale, an index on `segment` helps only if you also
filter by it — a full aggregation still requires scanning the table.
**How to validate.** `SUM(customer_count)` across the result must equal `SELECT COUNT(*) FROM customers` (24).

## Common mistakes

**Filtering out NULL instead of labeling it** — silently drops 4 real customers from the report.
```sql wrong
SELECT segment, COUNT(*) AS customer_count
FROM customers
WHERE segment IS NOT NULL
GROUP BY segment
ORDER BY customer_count DESC;
```

**Grouping on `segment` but selecting the `COALESCE` expression** — some MySQL configurations reject this
under `ONLY_FULL_GROUP_BY`; where it is accepted, the label and the grouping can disagree.

## Edge cases

- `Wholesale` and `Unclassified` are tied at 4 customers each — without the `segment ASC` tiebreaker,
  MySQL is free to return them in either order, which would make the report non-reproducible between runs.
- If a segment value were an empty string `''` rather than NULL, `COALESCE` would not catch it — that
  would need a `CASE` or `NULLIF` and is a data-quality issue to flag, not paper over.

## Performance notes

Full scan of 24 rows either way; not a performance-sensitive exercise. At production scale, this becomes
a covering-index question — see Module 15.

## Optional challenge

Add a second column showing each segment's share of the 24 customers as a percentage, rounded to 1 decimal.

## Related

Module: [02_Aggregations](../../02_Aggregations/) · Related: [11_NULL_HANDLING_AND_DATA_CLEANING](../../11_NULL_HANDLING_AND_DATA_CLEANING/)
