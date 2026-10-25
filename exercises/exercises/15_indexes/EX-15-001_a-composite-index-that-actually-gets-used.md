---
id: EX-15-001
title: A Composite Index That Actually Gets Used
module: 15_INDEXES
category: PERFORMANCE
difficulty: ADVANCED
level: L4
estimated_time_min: 25
business_domain: E-commerce
dataset: ecommerce
tables: [orders]
mysql_version: "8.0"
mutates: "true"
related_interview: null
---

## Learning objectives

- Read `EXPLAIN`'s `type`, `key`, `key_len`, and `filtered` columns to tell whether an index is actually
  being used the way you intend — not just whether a query "has an index available."
- See a real, measured case where adding a second column to an existing single-column index changes the
  optimizer's choice, instead of assuming it will.

## Business context

A dashboard query filtering orders by status and a date range is under review before the orders table
grows much larger. The team wants to confirm, with evidence, that the right index exists — not just that
*an* index exists on the queried columns.

## Scenario

`orders` already has a single-column index on `order_date` (`idx_orders_order_date`) from the base schema.
The dashboard query filters on `status` and `order_date` together.

## Input assumptions

- 49 rows in `orders` today — small enough that MySQL's optimizer may reasonably choose a full scan over
  an index it judges not selective enough, which is itself the first thing to check, not assume away.

## Task

1. Confirm (informationally, not part of the graded answer) that on the base schema, `EXPLAIN` for
   `SELECT order_id, order_date FROM orders WHERE status = 'delivered' AND order_date >= '2025-01-01'`
   shows `type = ALL` (a full table scan) even though `idx_orders_order_date` exists.
2. Create a composite index on `orders(status, order_date)`.
3. Return the full `EXPLAIN` output for the same query after adding that index (`EXPLAIN` always returns
   its own fixed set of columns — read `key`, `key_len`, `rows`, and `filtered` from it).

## Constraints

- The new index must cover both `status` and `order_date`, in that column order, so the optimizer can
  filter by status *within* the index itself rather than after fetching rows.
- Do not drop or alter the existing `idx_orders_order_date` index.

## Expected output

<!-- expected:start -->
| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | orders | NULL | range | idx_orders_order_date,idx_orders_status_date | idx_orders_status_date | 87 | NULL | 26 | 100.00 | Using where; Using index |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Think about which two columns the query filters on, and in what order they'd need to appear in an index for MySQL to use both as part of one index range scan rather than one lookup plus a row-by-row recheck.
</details>
<details><summary>Hint 2</summary>
Put the equality-filtered column (`status`) before the range-filtered column (`order_date`) in a composite index — `CREATE INDEX ... ON orders(status, order_date)` — and `EXPLAIN` the query before making the change too, so you have a real baseline instead of assuming what "no good index" looks like.
</details>
<details><summary>Hint 3</summary>
After creating the index, `EXPLAIN SELECT order_id, order_date FROM orders WHERE status='delivered' AND order_date >= '2025-01-01';` and read the `key` column to see which index MySQL actually chose.
</details>

## Solution

_MySQL 8.0+._

```sql setup
CREATE INDEX idx_orders_status_date ON orders(status, order_date);
```

```sql
EXPLAIN
SELECT order_id, order_date
FROM orders
WHERE status = 'delivered'
  AND order_date >= '2025-01-01';
```

## Explanation

**Grain.** N/A — this exercise is about the execution plan, not the result rows.
**Rows that survive.** Whatever the underlying `SELECT` would return; the graded output here is `EXPLAIN`
metadata about *how* MySQL would get those rows, not the rows themselves.
**Filtering.** Two conditions (`status = ...` and `order_date >= ...`) — the whole point of the composite
index is letting both be evaluated as part of one index range scan instead of one index lookup followed
by a row-by-row recheck of the second condition.
**Join cardinality.** N/A, single table.
**Aggregation.** None.
**NULL behavior.** Not applicable.
**Why it is correct.** Measured directly on this schema: before the composite index, `EXPLAIN` shows
`type = ALL` (full scan of all 49 rows) even with `idx_orders_order_date` listed as a *possible* key —
MySQL's cost estimate judged the single-column index not worth using here. After adding
`idx_orders_status_date`, the same query shows `type = range`, `key = idx_orders_status_date`, examining
only 26 rows with `filtered = 100.00` (every row the index range returns already satisfies both
conditions) and `Extra: Using where; Using index` (a covering index for this query's columns).
**What could make it slow.** The opposite of what this exercise demonstrates: an index that exists but
that the optimizer doesn't choose provides zero benefit — its presence in `possible_keys` is not the same
as its use in `key`.
**How to validate.** Compare `filtered` between the two plans: the single-column index's plan (if forced)
shows a much lower `filtered` percentage, meaning it accepts a candidate set that then needs substantial
extra rechecking — see the Common mistakes block below for that exact comparison.

## Common mistakes

**Assuming any index touching the queried columns is "good enough," and not checking `filtered`** — the
pre-existing single-column `idx_orders_order_date` index alone still leaves MySQL needing `Using where` to
recheck the `status` condition row by row after the index narrows by date, rather than the two conditions
being answered directly out of the index range itself.
```sql wrong
EXPLAIN
SELECT order_id, order_date
FROM orders FORCE INDEX (idx_orders_order_date)
WHERE status = 'delivered'
  AND order_date >= '2025-01-01';
```
This plan uses `key_len = 5` (the `order_date` column alone) versus the composite index's `key_len = 87`
(both columns), and a much lower `filtered` estimate than the composite index's 100.00 — concretely
showing that "an index exists" and "the right index exists" are different claims.

## Edge cases

- At only 49 rows, MySQL may still choose a full table scan for some *other* filter combination even with
  the composite index present — the optimizer's cost model, not the mere existence of an index, always
  makes the final call. Never claim an index "will always be used"; verify with `EXPLAIN` for the specific
  query and data distribution in question, per the handbook's engineering-language standard.
- Row-count and cost estimates (`rows`, `filtered`, `query_cost` in `EXPLAIN FORMAT=JSON`) are based on
  table statistics that can shift after `ANALYZE TABLE` or as data grows — treat the exact numbers as
  representative of this dataset's current state, not as permanent constants.

## Performance notes

This is itself the performance note: read `EXPLAIN`'s `key`, `key_len`, and `filtered` together, not
`key` alone — a query can use *an* index and still recheck most of its own filter conditions afterward if
the index doesn't cover them all.

## Optional challenge

Run `EXPLAIN FORMAT=JSON` for the same query and locate `"using_index": true` and the `cost_info` block,
then explain in your own words why `query_cost` dropped after the composite index was added.

## Related

Module: [15_INDEXES](../../15_INDEXES/) · Related: [16_QUERY_OPTIMIZATION](../../16_QUERY_OPTIMIZATION/)
