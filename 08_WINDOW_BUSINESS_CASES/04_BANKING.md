# 04 · Banking — Window Functions in Transaction & Risk Analytics

## Introduction

Banking data is sequential by nature: every account has an ordered history of transactions, and nearly every question a risk or operations team asks is really a question about **how a transaction relates to the ones around it** — is this withdrawal unusually large compared to this account's own history? Has the balance dropped sharply? Is there a suspicious gap or spike in transaction frequency? This chapter applies the running-total and gap-analysis patterns from earlier chapters to the highest-stakes domain in this module: financial risk.

---

## Business Background

A simplified banking schema centers on accounts and their transaction ledger:

- `accounts (account_id, customer_id FK, account_type, opened_date, ...)`
- `transactions (transaction_id, account_id FK, transaction_date, amount, transaction_type, ...)`
  - `amount` is signed: positive for deposits/credits, negative for withdrawals/debits.
- `customers (customer_id, customer_name, ...)`

Risk, fraud, and operations teams consume this data primarily through **running balances**, **outlier detection relative to an account's own history**, and **gap/frequency analysis**.

---

## Typical KPIs

- Running account balance
- Largest single transactions (company-wide and per-account)
- Transaction gap (time between consecutive transactions per account)
- Number of transactions per account per period
- Customer ranking by total transaction volume
- Flagged transactions (statistical outliers relative to account history)

---

## Typical Dashboards

- **Balance Tracker** — running balance per account over time, reconstructed from the transaction ledger.
- **Fraud Signal Dashboard** — transactions flagged as statistical outliers relative to an account's own transaction history.
- **Large Transaction Monitor** — a ranked list of the largest transactions across the bank, refreshed daily, typically feeding a manual review queue.
- **Account Activity Dashboard** — transaction frequency and gap analysis, used to detect dormant or suddenly hyperactive accounts.

---

## Business Problems

1. "Reconstruct the running balance for every account, transaction by transaction."
2. "Show me the largest transactions bank-wide, for manual review."
3. "Flag any transaction that's unusually large compared to that specific account's own transaction history - a first-pass fraud signal."
4. "What's the time gap between consecutive transactions on an account? Flag accounts with unusually long dormancy followed by sudden activity."
5. "Rank customers by total transaction volume, for a relationship-banking outreach list."
6. "Compare each account's current balance to its balance at the start of the month."

---

## Why Window Functions Are Needed

A running balance is, definitionally, a running total - `SUM(amount) OVER (PARTITION BY account_id ORDER BY transaction_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` - reusing the exact pattern from Sales Analytics, now applied per account rather than per salesperson. Fraud-style outlier detection compares a transaction to the **mean and standard deviation of that same account's own history** - the identical pattern used for the HR pay-equity screen in Chapter 01, applied here to transaction amounts instead of salaries. This consistency is intentional: window functions solve a small number of structural problems, and once you recognize the shape of the problem, the domain becomes a matter of relabeling columns.

---

## Functions Used in This Chapter

| Function | Business Explanation |
|---|---|
| `SUM() OVER (PARTITION BY account_id ORDER BY transaction_date ...)` | Running account balance reconstruction. |
| `RANK()` | Largest transactions bank-wide; customer ranking by transaction volume. |
| `AVG()` / `STDDEV() OVER (PARTITION BY account_id)` | Per-account baseline for outlier / fraud-signal detection. |
| `LAG()` | Time and amount gap between consecutive transactions on an account. |
| `FIRST_VALUE()` | Balance at the start of a period, for period-over-period balance comparison. |

---

## SQL Concepts Reinforced

- Reconstructing a running balance directly from a signed `amount` column, rather than assuming a pre-computed `balance` column exists in the ledger (which is common in real core-banking exports).
- Using `AVG()` and `STDDEV()` as windowed aggregates - not just grouped aggregates - to build a per-account statistical baseline that stays attached to every individual transaction row.
- Using `FIRST_VALUE() OVER (PARTITION BY account_id, period ORDER BY transaction_date)` to retrieve a period's opening balance without a separate query.
- The importance of a strict, gapless `ORDER BY` (transaction timestamp, not just date, when multiple transactions share a date) to avoid non-deterministic running balances.

---

## Performance Notes

- Running balance queries over a full transaction ledger are among the most expensive window function patterns in this module - ensure `(account_id, transaction_date)` (or a precise timestamp) is indexed, and consider maintaining a materialized daily balance snapshot table for accounts with very long histories, rather than recomputing the full running sum on every query.
- Per-account outlier detection (`AVG()`/`STDDEV() OVER (PARTITION BY account_id)`) recomputes the same statistics for every row in the partition; for very high-frequency accounts, consider pre-aggregating account-level statistics into a lookup table refreshed on a schedule, then joining rather than windowing over raw transactions on every query.
- Large-transaction monitoring queries that scan the entire ledger daily should filter to a rolling time window (e.g., `WHERE transaction_date >= CURRENT_DATE - INTERVAL '1 day'`) before ranking, rather than ranking the entire historical table and discarding all but the top few rows.

---

## Common Mistakes

- Ordering a running balance calculation by `transaction_date` alone when multiple transactions share the same date, producing a non-deterministic (and audit-unfriendly) running balance - always order by a full timestamp, or add a deterministic tiebreaker.
- Applying a single company-wide average/standard deviation for fraud detection instead of a **per-account** baseline - a $50,000 transaction may be entirely normal for one account and a clear anomaly for another.
- Forgetting that `amount` is signed in most ledger schemas, leading to a running balance calculation that adds withdrawals instead of subtracting them.
- Treating `RANK()` ties in a "largest transactions" report as if they were guaranteed unique, when in fact two transactions can legitimately share an identical amount.

---

## Interview Questions

1. **"How would you reconstruct a running account balance from a transaction ledger?"** — Expect `SUM(amount) OVER (PARTITION BY account_id ORDER BY transaction_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`, with attention to signed amounts and deterministic ordering.
2. **"How would you flag potentially fraudulent transactions using only SQL?"** — Expect a discussion of per-account mean/standard-deviation baselines (`AVG()`/`STDDEV() OVER (PARTITION BY account_id)`) and a threshold-based flag, with the caveat that this is a first-pass heuristic, not a full fraud model.
3. **"Why is ordering important when calculating a running balance, and what happens if two transactions share the same timestamp?"** — Expect recognition that ties in the `ORDER BY` column make the running balance non-deterministic unless a tiebreaker (e.g., `transaction_id`) is added.
4. **"How would you find the account with the largest balance drop within a single day?"** — Expect `LAG()` on the running balance itself (a window function applied to the output of another window function, typically via a CTE), then a computed delta.
5. **"What's the difference between windowing a statistic per account versus computing it once for the whole table, in a risk-detection context?"** — Expect an explanation of why global baselines under- or over-flag depending on an account's typical transaction size.

---

## Summary

Banking analytics is where the running-total pattern (Sales Analytics) and the peer/self-comparison pattern (HR Analytics) converge on the highest-stakes use case in this module: financial risk. Every pattern in this chapter - running balances, per-account outlier baselines, and transaction gap analysis - reuses tools you have already built fluency with, applied to a domain where correctness and determinism carry real financial consequences.

---

## Further Practice

- Extend the running balance query to flag any day where the balance drops below zero (an overdraft signal).
- Add a query that computes the largest single-day balance swing (max increase and max decrease) per account.
- Build a dormancy-then-spike detector: flag accounts with a transaction gap greater than 90 days immediately followed by a transaction amount more than 3 standard deviations above that account's historical average.

---

**Next:** [`04_BANKING.sql`](./04_BANKING.sql) — the fully engineered SQL chapter for this domain.
