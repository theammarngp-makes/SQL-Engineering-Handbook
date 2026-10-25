---
id: EX-05-001
title: Account Balance from Signed Transaction Types
module: 05_CASE_WHEN
category: FILTERING
difficulty: INTERMEDIATE
level: L3
estimated_time_min: 20
business_domain: Banking
dataset: banking
tables: [transactions]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Build a `CASE WHEN` expression that maps a categorical column (`txn_type`) to a signed numeric value,
  the standard pattern for turning an always-positive "amount" column into a real balance.
- Recognize that a `CASE` mapping is only as correct as its understanding of every category — a
  plausible-sounding rule for one label (`REVERSAL` "sounds like" a debit) can be flatly wrong.

## Business context

A customer disputes their checking account balance. Support needs to recompute it from the raw ledger to
confirm what the system shows.

## Scenario

`transactions.amount` is always stored positive; `txn_type` determines whether it adds to or subtracts
from the balance. In this account's history, one withdrawal was fully reversed by the bank (a `REVERSAL`
row), which should add the money back.

## Input assumptions

- Account 1 has 7 transactions: a deposit, two withdrawals, a reversal of the second withdrawal, a fee, a
  second deposit, and an outbound transfer.

## Task

Compute the current balance of account 1 as a single number: the sum of every transaction, signed
correctly by `txn_type`.

## Constraints

- `DEPOSIT`, `TRANSFER_IN`, `INTEREST`, and `REVERSAL` add to the balance; `WITHDRAWAL`, `TRANSFER_OUT`,
  and `FEE` subtract.
- Every transaction type present in the data must be handled explicitly — do not rely on a silent
  fallback for a type you didn't think about.

## Expected output

<!-- expected:start -->
| account_id | balance |
|---|---|
| 1 | 995.00 |

_1 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
Build one `CASE WHEN txn_type = ... THEN amount ... END` expression that returns a *signed* amount per row, then `SUM` it.
</details>
<details><summary>Hint 2</summary>
List every `txn_type` value present in the data on its own `WHEN` — don't leave any type to an `ELSE`, since a wrong guess there is invisible.
</details>
<details><summary>Hint 3</summary>
`SUM(CASE txn_type WHEN 'DEPOSIT' THEN amount WHEN 'TRANSFER_IN' THEN amount WHEN 'INTEREST' THEN amount WHEN 'REVERSAL' THEN amount WHEN 'WITHDRAWAL' THEN -amount WHEN 'TRANSFER_OUT' THEN -amount WHEN 'FEE' THEN -amount END)`
</details>

## Solution

_MySQL 8.0+._

```sql
SELECT
    account_id,
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
    ) AS balance
FROM transactions
WHERE account_id = 1
GROUP BY account_id;
```

## Explanation

**Grain.** One row per transaction, rolled up to one row per account by the `GROUP BY`.
**Rows that survive.** All 7 transactions on account 1.
**Filtering.** `WHERE account_id = 1` scopes to the disputed account only.
**Join cardinality.** N/A, single table.
**Aggregation.** `SUM` over a per-row signed value produced by `CASE` — the `CASE` does the sign logic,
`SUM` does the rollup; conflating the two into one step is how the common mistake below happens.
**NULL behavior.** If a `txn_type` appeared that wasn't listed in any `WHEN`, `CASE` without an `ELSE`
returns `NULL` for that row, and `SUM` silently ignores NULLs — meaning an unhandled type doesn't error,
it just vanishes from the total. That's why the constraint requires listing every real `txn_type`.
**Why it is correct.** Verified step by step: 1000 − 200 − 150 + 150 (reversal) − 5 + 500 − 300 = 995.00,
matching the query result.
**What could make it slow.** Nothing at this size; the `CASE` runs per row regardless of index use.
**How to validate.** Sum only the `DEPOSIT`/`TRANSFER_IN`/`INTEREST`/`REVERSAL` rows separately from the
`WITHDRAWAL`/`TRANSFER_OUT`/`FEE` rows and confirm (credits) − (debits) = 995.00 independently of the
single combined query.

## Common mistakes

**Assuming `REVERSAL` is a debit because the word sounds negative** — this account's one `REVERSAL`
actually reverses a *withdrawal*, so it should add money back. Flipping its sign produces 695.00 instead
of the correct 995.00 — a 300.00 error that would make support tell the customer they're missing money
they actually have.
```sql wrong
SELECT
    account_id,
    SUM(
        CASE txn_type
            WHEN 'DEPOSIT'      THEN amount
            WHEN 'TRANSFER_IN'  THEN amount
            WHEN 'INTEREST'     THEN amount
            WHEN 'WITHDRAWAL'   THEN -amount
            WHEN 'TRANSFER_OUT' THEN -amount
            WHEN 'FEE'          THEN -amount
            WHEN 'REVERSAL'     THEN -amount
        END
    ) AS balance
FROM transactions
WHERE account_id = 1
GROUP BY account_id;
```

## Edge cases

- A `REVERSAL` of a *deposit* (not present on this account, but present elsewhere in a fuller ledger)
  would need the opposite sign from a reversal of a withdrawal — a fixed sign for `REVERSAL` only happens
  to be correct here because every reversal in this dataset reverses a withdrawal. A general-purpose
  version would need to join back to `reversed_txn_id` to look up the original transaction's own sign,
  rather than hard-coding one — see the Optional challenge.

## Performance notes

A single pass, one `CASE` evaluation per row — negligible cost regardless of table size; this exercise is
about correctness of the mapping, not performance.

## Optional challenge

Rewrite the query so `REVERSAL` rows derive their sign from the transaction they reverse
(`reversed_txn_id`) via a self-join, instead of assuming `REVERSAL` is always a credit — then confirm the
result is still 995.00 for account 1, and reason about what would change if a reversed deposit existed.

## Related

Module: [05_CASE_WHEN](../../05_CASE_WHEN/) · Related: [08_WINDOW_BUSINESS_CASES](../../08_WINDOW_BUSINESS_CASES/)
