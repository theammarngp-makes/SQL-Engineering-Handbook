---
id: EX-13-001
title: Customers With a Savings Account or an Active Loan
module: 13_SET_OPERATORS
category: SET_OPERATORS
difficulty: EASY
level: L2
estimated_time_min: 15
business_domain: Banking
dataset: banking
tables: [accounts, loans]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Choose `UNION` over `UNION ALL` when the question is about *which customers* qualify, not how many
  qualifying rows exist — `UNION`'s implicit deduplication is the correct tool here, not a side effect to
  work around.
- See concretely how `UNION ALL` can overcount when a customer satisfies both underlying conditions.

## Business context

Wealth management wants a single list of customers who are either already a savings customer or already
carrying an active loan — either relationship qualifies them for a "existing relationship" upsell segment,
and a customer with both should appear exactly once.

## Scenario

`accounts.account_type` distinguishes `SAVINGS` from `CHECKING`; `loans.status` distinguishes `ACTIVE` from
`PAID_OFF`/`DEFAULTED`.

## Input assumptions

- 10 customers; 4 have a savings account, 3 have an active loan, and exactly 2 customers have both.

## Task

Return the distinct list of `customer_id`s who have a savings account, an active loan, or both, ordered
ascending.

## Constraints

- A customer with both a savings account and an active loan must appear exactly once, not twice.

## Expected output

<!-- expected:start -->
| customer_id |
|---|
| 1 |
| 3 |
| 5 |
| 7 |
| 8 |

_5 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Write the savings-account customers as one `SELECT` and the active-loan customers as another `SELECT` with the same single column, then combine them.
</details>
<details><summary>Hint 2</summary>
`UNION` (no `ALL`) removes duplicate rows across both halves — exactly what "appears once even if both are true" needs.
</details>
<details><summary>Hint 3</summary>
`SELECT customer_id FROM accounts WHERE account_type = 'SAVINGS' UNION SELECT customer_id FROM loans WHERE status = 'ACTIVE' ORDER BY customer_id;`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT customer_id FROM accounts WHERE account_type = 'SAVINGS'
UNION
SELECT customer_id FROM loans WHERE status = 'ACTIVE'
ORDER BY customer_id;
```

## Explanation

**Grain.** Each half produces one row per qualifying customer (a customer with two savings accounts would
still need `DISTINCT` within that half alone — not an issue in this dataset, where no customer has more
than one savings account).
**Rows that survive.** Every customer appearing in either half, deduplicated by `UNION`.
**Filtering.** `account_type = 'SAVINGS'` in the first half, `status = 'ACTIVE'` in the second — two
independent business conditions, each simple enough not to need a join between `accounts` and `loans`.
**Join cardinality.** No join at all — `UNION` combines two independent row sets vertically, not
horizontally, which is why the two `SELECT`s need the same number and type of columns, not related tables.
**Aggregation.** None; this is set combination, not aggregation.
**NULL behavior.** Not applicable — `customer_id` is never NULL in either source table.
**Why it is correct.** Verified against the dataset: savings customers are {1, 3, 5, 7}, active-loan
customers are {1, 7, 8} — the union is {1, 3, 5, 7, 8}, exactly 5 distinct customers, with customers 1
and 7 present in both underlying sets but appearing only once in the result.
**What could make it slow.** `UNION`'s deduplication requires an internal sort/hash pass across the
combined rows; at this scale it's free. At large scale, if duplicates across the two halves are known to
be impossible, `UNION ALL` avoids that pass — but here they are not impossible, so correctness comes first.
**How to validate.** Count the rows from each half separately (4 and 3) — if the combined distinct count
were 7, that would mean no customer appears in both; since it's 5, exactly `4 + 3 - 5 = 2` customers must
be in both, matching the input assumption.

## Common mistakes

**Using `UNION ALL` when duplicates across the two conditions are possible** — customers 1 and 7 each have
both a savings account and an active loan, so `UNION ALL` returns each of them twice, inflating the
segment from 5 customers to 7 rows and effectively double-targeting them in any downstream campaign.
```sql wrong
SELECT customer_id FROM accounts WHERE account_type = 'SAVINGS'
UNION ALL
SELECT customer_id FROM loans WHERE status = 'ACTIVE'
ORDER BY customer_id;
```

## Edge cases

- If a customer had two separate savings accounts, the first `SELECT` alone would produce two identical
  rows for them before the `UNION` even runs its own deduplication — `UNION`'s dedup still catches this
  correctly, since it dedupes the final combined set, not each half independently.

## Performance notes

For two small, independently-filterable row sets like these, `UNION` at this scale costs nothing
noticeable; the choice between `UNION` and `UNION ALL` should be driven by whether duplicates are possible
and unwanted, not by an assumption that one is always faster.

## Optional challenge

Rewrite this using `NOT EXISTS` twice combined with `OR` on a single `SELECT ... FROM customers` instead
of a `UNION`, and confirm it produces the same 5 customers.

## Related

Module: [13_SET_OPERATORS](../../13_SET_OPERATORS/) · Related: [datasets/banking](../../datasets/banking/README.md)
