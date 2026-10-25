---
id: EX-04-001
title: Dormant Accounts, Excluding Closed Ones
module: 04_Subqueries
category: SUBQUERIES
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 20
business_domain: Banking
dataset: banking
tables: [accounts, customers, transactions]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use a correlated `NOT EXISTS` subquery to test "no matching row within a condition" — a different
  question than the plain LEFT JOIN anti-join pattern, because the condition (a date cutoff) applies
  inside the subquery, not to the outer row.
- Combine that subquery with an ordinary `WHERE` filter on the outer table (open accounts only).

## Business context

Operations wants to flag "dormant" accounts for a re-engagement campaign — but only ones that are still
open. A closed account having no recent activity is expected, not a signal.

## Scenario

An account counts as dormant if it has had no transaction in the 90 days before the as-of date
(2025-07-01, so the cutoff is 2025-04-02) and it is still open (`closed_on IS NULL`).

## Input assumptions

- 12 accounts total; 1 is closed. Some open accounts have recent activity, some don't.

## Task

Return every dormant, still-open account: `account_id`, `full_name`, `account_type`, ordered by `account_id`.

## Constraints

- The closed account must never appear, regardless of how old its last transaction is.
- An account with zero transactions ever would also count as dormant (none exist in this dataset, but the
  query must not assume every account has at least one transaction).

## Expected output

<!-- expected:start -->
| account_id | full_name | account_type |
|---|---|---|
| 1 | Aarav Sharma | CHECKING |
| 2 | Aarav Sharma | SAVINGS |
| 3 | Meera Iyer | CHECKING |
| 6 | Emily Carter | CHECKING |
| 7 | Liam O'Brien | SAVINGS |
| 8 | Sofia Rossi | CHECKING |
| 9 | Priya Nair | CHECKING |

_7 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
"No transaction after a cutoff date" is a NOT EXISTS whose inner condition includes the date — it is not the same as a LEFT JOIN anti-join, which only tests "no matching row at all."
</details>
<details><summary>Hint 2</summary>
Filter `closed_on IS NULL` on the outer `accounts` row, separately from the `NOT EXISTS` subquery.
</details>
<details><summary>Hint 3</summary>
`WHERE closed_on IS NULL AND NOT EXISTS (SELECT 1 FROM transactions t WHERE t.account_id = a.account_id AND t.txn_at >= '2025-04-02')`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    a.account_id,
    c.full_name,
    a.account_type
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
WHERE a.closed_on IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM transactions t
      WHERE t.account_id = a.account_id
        AND t.txn_at >= '2025-04-02 00:00:00'
  )
ORDER BY a.account_id;
```

## Explanation

**Grain.** One row per account.
**Rows that survive.** Open accounts with zero transactions on or after 2025-04-02.
**Filtering.** Two independent filters: `closed_on IS NULL` on the outer row, and the correlated
subquery testing recent activity — both must hold.
**Join cardinality.** `accounts` to `customers` is many-to-one, used only to display the name; it does
not affect which accounts qualify.
**Aggregation.** None — `NOT EXISTS` is a row-existence test, not a count.
**NULL behavior.** `closed_on IS NULL` is itself the "still open" test — closed accounts have a non-NULL
`closed_on` and are excluded before the subquery even runs.
**Why it is correct.** Verified against the dataset: 7 open accounts had no transaction on or after
2025-04-02 (the closed account, account 5, is excluded regardless of its own transaction history; several
other open accounts are excluded because they do have recent activity).
**What could make it slow.** A correlated subquery re-executes conceptually once per outer row; an index
on `transactions(account_id, txn_at)` — already present in this schema — lets MySQL answer each check
with a fast range lookup instead of a full scan of `transactions` per account.
**How to validate.** Manually check one excluded account (e.g., account 4, last transaction 2025-04-10)
against the 2025-04-02 cutoff to confirm it correctly falls outside the dormancy window.

## Common mistakes

**Using a LEFT JOIN anti-join instead of a date-scoped NOT EXISTS** — `LEFT JOIN transactions ... WHERE
transaction_id IS NULL` only finds accounts with *zero transactions ever*, which is a different, much
narrower question than "no transaction in the last 90 days." Every account in this dataset has at least
one transaction, so this version would wrongly return zero dormant accounts.
```sql wrong
SELECT a.account_id, c.full_name, a.account_type
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id AND t.txn_at >= '2025-04-02 00:00:00'
WHERE a.closed_on IS NULL
  AND t.transaction_id IS NOT NULL
ORDER BY a.account_id;
```

## Edge cases

- The closed account (account 5) had its last transaction on 2024-11-25 — by activity alone it looks
  "extremely dormant," which is exactly why the `closed_on IS NULL` filter must be checked independently,
  not inferred from inactivity.

## Performance notes

`NOT EXISTS` with an index on the correlated column (`transactions.account_id`) and the range column
(`txn_at`) typically performs well; verify the actual plan with `EXPLAIN` rather than assuming `NOT
EXISTS` is always faster or slower than an equivalent `LEFT JOIN ... IS NULL` — see Module 16.

## Optional challenge

Rewrite using `LEFT JOIN` with the date condition correctly placed in the `ON` clause (not `WHERE`) and
confirm it produces the same 7 rows as the `NOT EXISTS` version.

## Related

Module: [04_Subqueries](../../04_Subqueries/) · Related: [09_Date_Functions](../../09_Date_Functions/)
