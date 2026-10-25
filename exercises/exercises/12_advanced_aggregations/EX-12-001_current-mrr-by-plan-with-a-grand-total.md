---
id: EX-12-001
title: Current MRR by Plan, With a Grand Total
module: 12_ADVANCED_AGGREGATIONS
category: AGGREGATION
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 15
business_domain: SaaS
dataset: saas
tables: [accounts, subscriptions, plans]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `WITH ROLLUP` to add a grand-total row to a grouped aggregation in one query, instead of a separate
  `UNION` query for the total.
- Correctly scope "current" revenue to the subscriptions that are actually in effect right now, not every
  subscription row that ever existed.

## Business context

Finance wants current Monthly Recurring Revenue broken down by plan, with a total row, for a board slide
— one query, one number that ties to the individual plan figures below it.

## Scenario

An account's subscription history is a sequence of rows (see `datasets/saas/README.md`); only the row with
`status = 'ACTIVE' AND end_date IS NULL` represents what that account is paying right now.

## Input assumptions

- 4 plans, 10 accounts, 14 subscription rows total; 8 of those rows are currently active.

## Task

Return current MRR by plan name, plus a grand-total row: `plan_name` (`NULL` for the total row),
`mrr`, ordered alphabetically by plan name with the total last.

## Constraints

- Only subscriptions with `status = 'ACTIVE' AND end_date IS NULL` count toward MRR.
- `EXPIRED` rows (superseded by an upgrade/downgrade) and `CANCELED` rows must not contribute, even though
  they were once revenue-generating.

## Expected output

<!-- expected:start -->
| plan_name | mrr |
|---|---|
| Business | 398.00 |
| Enterprise | 499.00 |
| Pro | 237.00 |
| Starter | 58.00 |
| NULL | 1192.00 |

_5 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Filter to only currently-active subscriptions first, then join to `plans` for the price and name.
</details>
<details><summary>Hint 2</summary>
`GROUP BY plan_name` normally gives one row per plan — adding `WITH ROLLUP` after the `GROUP BY` list appends a super-aggregate row. That row's `plan_name` is `NULL`, and `NULL` sorts first under a plain `ORDER BY` — think about how to keep the total last.
</details>
<details><summary>Hint 3</summary>
`SELECT plan_name, SUM(monthly_price) AS mrr FROM subscriptions s JOIN plans p USING(plan_id) WHERE s.status='ACTIVE' AND s.end_date IS NULL GROUP BY plan_name WITH ROLLUP ORDER BY GROUPING(plan_name), plan_name;`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    p.plan_name,
    SUM(p.monthly_price) AS mrr
FROM subscriptions s
JOIN plans p ON p.plan_id = s.plan_id
WHERE s.status = 'ACTIVE'
  AND s.end_date IS NULL
GROUP BY p.plan_name WITH ROLLUP
ORDER BY GROUPING(p.plan_name), p.plan_name;
```

## Explanation

**Grain.** One row per plan among currently-active subscriptions, plus one extra super-aggregate row
added by `ROLLUP` for the grand total.
**Rows that survive.** Only subscription rows that are both `ACTIVE` and have `end_date IS NULL` — the
combination that means "this is what the account pays today."
**Filtering.** Both conditions in `WHERE` are necessary: `status = 'ACTIVE'` alone would be insufficient
on its own if the schema ever allowed an ACTIVE row with a past end_date, and this schema's own
convention ties "currently in effect" to both fields together.
**Join cardinality.** `subscriptions` to `plans` is many-to-one — safe, no fan-out.
**Aggregation.** `SUM(monthly_price)` per plan; `WITH ROLLUP` adds one additional row where the grouping
column is `NULL`, representing the sum across all groups.
**NULL behavior.** The `NULL` in the final row's `plan_name` is `ROLLUP`'s own marker for "this row is the
super-aggregate," not missing data — it must not be confused with an actual NULL plan name (which cannot
occur here since `plan_id` is `NOT NULL`).
**Ordering.** MySQL does not guarantee row order without an explicit `ORDER BY`, including for
`WITH ROLLUP`, so the order is stated in the query. A plain `ORDER BY p.plan_name` would sort the
rollup row's `NULL` *first*; `GROUPING(p.plan_name)` returns `1` only for the super-aggregate row, so
ordering by it first keeps the total last, then plan name orders the rest alphabetically.
**Why it is correct.** Verified against the dataset: 398.00 + 499.00 + 237.00 + 58.00 = 1192.00, matching
the ROLLUP total exactly.
**What could make it slow.** Nothing at this size; `ROLLUP` computes the extra aggregate from the same
grouped data, not an additional pass over the base tables.
**How to validate.** Sum the 4 plan-level `mrr` values by hand and confirm they equal the final row's
value — any mismatch would mean the `ROLLUP` total and the visible breakdown have gone out of sync, which
should not happen but is worth checking once.

## Common mistakes

**Summing `monthly_price` across every subscription row regardless of status** — this counts revenue from
plans customers have since upgraded away from (`EXPIRED`) or canceled (`CANCELED`) as if it were still
being collected today, overstating MRR by including money that isn't actually coming in.
```sql wrong
SELECT
    p.plan_name,
    SUM(p.monthly_price) AS mrr
FROM subscriptions s
JOIN plans p ON p.plan_id = s.plan_id
GROUP BY p.plan_name WITH ROLLUP
ORDER BY GROUPING(p.plan_name), p.plan_name;
```

## Edge cases

- Account 5's reactivation (canceled Pro, later restarted on Starter) contributes only to `Starter`'s
  current total, not `Pro` — the old canceled Pro row is correctly excluded by the `status`/`end_date`
  filter, even though that account did pay for Pro in the past.
- Account 7 has 3 historical subscription rows (2 `EXPIRED`, 1 `ACTIVE`) from two plan changes — only its
  current `Business` row contributes to MRR; neither of its earlier `EXPIRED` rows should be mistaken for
  churn or double-counted.

## Performance notes

`GROUP BY ... WITH ROLLUP` is computed from the already-grouped result; at production scale, filtering to
active subscriptions first (as the `WHERE` clause does here) keeps the grouped set small before any
rollup work happens.

## Optional challenge

Add a second `ROLLUP` dimension — country (via `accounts`) alongside plan — and confirm the subtotal rows
this produces at each level still foot to the same 1192.00 grand total.

## Related

Module: [12_ADVANCED_AGGREGATIONS](../../12_ADVANCED_AGGREGATIONS/) · Related: [datasets/saas](../../datasets/saas/README.md)
