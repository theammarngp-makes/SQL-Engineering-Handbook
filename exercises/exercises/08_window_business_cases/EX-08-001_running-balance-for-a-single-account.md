---
id: EX-08-001
title: Running Balance for a Single Account
module: 08_WINDOW_BUSINESS_CASES
category: WINDOW_FUNCTIONS
difficulty: ADVANCED
level: L4
estimated_time_min: 20
business_domain: Banking
dataset: banking
tables: [transactions]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use `SUM(...) OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING)` to produce a running total — the business
  case a bank statement actually needs, not just a single final balance.
- Give the window frame a fully deterministic order, including a tiebreaker, so that same-timestamp rows
  don't produce an ambiguous running balance.

## Business context

A customer wants a statement showing their balance *after each transaction*, not just the final number —
the same shape as a real bank statement line.

## Scenario

This reuses the signed-amount logic from EX-05-001 (Module 05), now applied as a running total instead of
a single sum.

## Input assumptions

- Account 1 has 7 transactions between 2025-01-05 and 2025-03-05, including one reversed withdrawal.

## Task

For account 1, return every transaction with a running balance after it: `transaction_id`, `txn_type`,
`amount`, `running_balance`, ordered by transaction time.

## Constraints

- The running balance after the last row must equal 995.00, matching EX-05-001's final total.
- Two transactions with the same timestamp (none exist for this account, but the query must not assume
  otherwise) must still produce a deterministic, repeatable order.

## Expected output

<!-- expected:start -->
| transaction_id | txn_type | amount | running_balance |
|---|---|---|---|
| 1 | DEPOSIT | 1000.00 | 1000.00 |
| 2 | WITHDRAWAL | 200.00 | 800.00 |
| 3 | WITHDRAWAL | 150.00 | 650.00 |
| 4 | REVERSAL | 150.00 | 800.00 |
| 5 | FEE | 5.00 | 795.00 |
| 6 | DEPOSIT | 500.00 | 1295.00 |
| 7 | TRANSFER_OUT | 300.00 | 995.00 |

_7 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Reuse the signed-amount `CASE` from EX-05-001 as the value being summed — the only new part is turning that single `SUM` into a running one.
</details>
<details><summary>Hint 2</summary>
`SUM(...) OVER (ORDER BY txn_at ROWS UNBOUNDED PRECEDING)` gives a running total up to and including the current row.
</details>
<details><summary>Hint 3</summary>
Add `transaction_id` as a secondary `ORDER BY` key inside the window frame to break ties deterministically: `ORDER BY txn_at, transaction_id`.
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    transaction_id,
    txn_type,
    amount,
    SUM(
        CASE txn_type
            WHEN 'DEPOSIT'      THEN amount
            WHEN 'TRANSFER_IN'  THEN amount
            WHEN 'INTEREST'     THEN amount
            WHEN 'REVERSAL'     THEN amount
            WHEN 'WITHDRAWAL'   THEN -amount
            WHEN 'TRANSFER_OUT' THEN -amount
            WHEN 'FEE'          THEN -amount
        END
    ) OVER (ORDER BY txn_at, transaction_id ROWS UNBOUNDED PRECEDING) AS running_balance
FROM transactions
WHERE account_id = 1
ORDER BY txn_at, transaction_id;
```

## Explanation

**Grain.** One row per transaction — a window function does not collapse rows the way `GROUP BY` does, so
the account's 7 transactions stay 7 rows, each annotated with a running total.
**Rows that survive.** All 7 transactions on account 1.
**Filtering.** `WHERE account_id = 1` scopes to one account.
**Join cardinality.** N/A, single table.
**Aggregation.** `SUM(...) OVER (...)` is a window aggregate — it computes over a frame of rows relative
to the current one (`ROWS UNBOUNDED PRECEDING` = "every row from the start up to here") without reducing
the row count, unlike a `GROUP BY` `SUM`.
**NULL behavior.** Same signed-amount mapping as EX-05-001; not applicable here since every transaction
type on this account is explicitly handled.
**Why it is correct.** Each `running_balance` value matches a manual step-by-step accumulation:
1000 → 800 → 650 → 800 (after the reversal restores 150) → 795 → 1295 → 995.
**What could make it slow.** A window function with `ORDER BY` requires a sort; an index on
`transactions(account_id, txn_at)` — already present in this schema — lets MySQL avoid a separate sort
step for this exact access pattern.
**How to validate.** The last row's `running_balance` (995.00) must equal the single-number total from
EX-05-001 — if they disagree, one of the two queries has a bug.

## Common mistakes

**Ordering the window by the wrong column** — a running balance is only meaningful in chronological order.
Ordering by `amount` instead of `txn_at` still produces *a* running total, with no error, but it accumulates
transactions in size order instead of time order — the balance goes negative at points where it never
actually did, and every intermediate value (and the row each one is attached to) is wrong even though the
final total still happens to reach 995.00.
```sql wrong
SELECT
    transaction_id,
    txn_type,
    amount,
    SUM(
        CASE txn_type
            WHEN 'DEPOSIT'      THEN amount
            WHEN 'TRANSFER_IN'  THEN amount
            WHEN 'INTEREST'     THEN amount
            WHEN 'REVERSAL'     THEN amount
            WHEN 'WITHDRAWAL'   THEN -amount
            WHEN 'TRANSFER_OUT' THEN -amount
            WHEN 'FEE'          THEN -amount
        END
    ) OVER (ORDER BY amount ROWS UNBOUNDED PRECEDING) AS running_balance
FROM transactions
WHERE account_id = 1
ORDER BY amount;
```

## Edge cases

- Two transactions sharing an exact `txn_at` (none exist on this account, but possible elsewhere in a
  fuller ledger) would need `transaction_id` as a secondary sort key to stay deterministic, per Hint 3 —
  without it, their relative order (and which `running_balance` value lands on which row) is not
  guaranteed to be stable across runs.

## Performance notes

`ROWS UNBOUNDED PRECEDING` forces MySQL to accumulate over every prior row in the frame; for a single
account's statement this is trivial, but a running total across millions of rows benefits from the same
`(account_id, txn_at)` index used for the correlated subquery in EX-04-001.

## Optional challenge

Extend the query to all accounts at once using `PARTITION BY account_id`, and confirm each account's final
running balance matches its total from a plain `GROUP BY` sum.

## Related

Module: [08_WINDOW_BUSINESS_CASES](../../08_WINDOW_BUSINESS_CASES/) · Related: [EX-05-001](../05_case_when/EX-05-001_account-balance-from-signed-transaction-types.md), [07_Window_Functions](../../07_Window_Functions/)
