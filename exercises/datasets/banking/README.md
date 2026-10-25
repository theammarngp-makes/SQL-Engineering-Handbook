# Dataset: Banking

**Database:** `handbook_banking` · **Engine:** MySQL 8.0+, InnoDB, utf8mb4
**As-of date:** the data ends **2025-06-30**; exercises treat **2025-07-01** as "today".

```bash
mysql -u root < schema.sql
mysql -u root < seed.sql
```

## Grain

| Table | One row = |
|---|---|
| `branches` | one physical branch (3 rows) |
| `customers` | one account holder (10 rows) |
| `accounts` | one account belonging to one customer (12 rows) — a customer can have 0, 1, or 2 |
| `transactions` | one posted transaction on one account (27 rows) — **this is the ledger grain** |
| `loans` | one loan belonging to one customer (5 rows) |

## Relationships

`branches 1—N customers 1—N accounts 1—N transactions` · `customers 1—N loans` · a `TRANSFER_OUT` row and
its matching `TRANSFER_IN` row are two separate `transactions` rows linked only by
`counterparty_account_id` (there is no shared transfer ID) · a `REVERSAL` row points back at the
transaction it reverses via `reversed_txn_id`.

## Signed-amount convention

`transactions.amount` is **always stored positive**. Whether it adds to or subtracts from the balance
depends on `txn_type`: `DEPOSIT`, `TRANSFER_IN`, `INTEREST` and `REVERSAL` (in this dataset) add;
`WITHDRAWAL`, `TRANSFER_OUT` and `FEE` subtract. A `REVERSAL`'s true sign is the *opposite* of whatever it
reverses — here every `REVERSAL` reverses a `WITHDRAWAL`, so it adds funds back, but a query that assumes
`REVERSAL` always subtracts (by pattern-matching "reversal sounds like a debit") will get every account
with a reversal wrong.

## Known data-quality traps (intentional — teach with these, don't "fix" them)

- **One customer has no account at all** (Noah Williams, customer 10) — an INNER JOIN from `customers` to
  `accounts` silently drops him.
- **One account is closed** (account 5) with a zero final balance — closed accounts still have
  transaction history and must not be excluded from historical reports, only from "currently open"
  reports (`closed_on IS NULL`).
- **One account is overdrawn**: account 4's balance is **-500.00** (a 2000.00 deposit followed by a
  2500.00 withdrawal) — a query that assumes balances are never negative will misclassify it.
- **A reversed withdrawal**: account 1 has transaction 3 (a 150.00 withdrawal) fully reversed by
  transaction 4. Summing `amount` by a naive fixed sign map that treats every `REVERSAL` as a subtraction
  produces the wrong balance for account 1 (695.00 instead of the correct 995.00).
- **A transfer pair lives in two rows**: transactions 7 and 8 are one logical transfer (300.00 from
  account 1 to account 3) but appear as an independent `TRANSFER_OUT` and `TRANSFER_IN` row — summing
  `transactions.amount` without regard to `txn_type` double-counts every transfer as money created from
  nothing.
- **`customers.risk_rating` is NULL** for 2 customers who haven't been assessed yet — do not assume every
  customer has a rating.
- **`accounts.interest_rate` is NULL for every `CHECKING` account** by design (checking accounts don't
  earn interest here) — this is expected, not missing data, and should not be flagged the same way a
  missing `risk_rating` is.
- **One loan is `DEFAULTED`** (customer 3) and one is `PAID_OFF` (customer 4) — "outstanding loan balance"
  reports must exclude both, using `status = 'ACTIVE'`, not just `closed_on IS NULL` (a `DEFAULTED` loan
  also has a `closed_on` date, same as `PAID_OFF`).

## Recommended exercises

CASE_WHEN (signed-amount balance calculation) · Subqueries (dormant/no-activity accounts) · CTEs (avoid
repeating an aggregate subquery) · Window functions / business cases (running balance over time) · Date
functions (days since last transaction, as-of 2025-07-01) · Set operators (customers with a savings
account OR an active loan, UNION vs UNION ALL) · Views (encapsulating the signed-balance calculation so
analysts never have to re-derive the sign map themselves).
