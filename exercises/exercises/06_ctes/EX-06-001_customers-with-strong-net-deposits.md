---
id: EX-06-001
title: Customers With Strong Net Deposits
module: 06_CTEs
category: CTES
difficulty: EASY
level: L2
estimated_time_min: 15
business_domain: Banking
dataset: banking
tables: [customers, accounts, transactions]
mysql_version: "8.0"
related_interview: null
---

## Learning objectives

- Use a CTE to name and reuse an aggregation once, instead of repeating the same `CASE`-based sum
  expression in both the `SELECT` list and a filter — a readability and maintainability win, not (at this
  scale) a performance one.
- Filter on a computed aggregate cleanly with an outer `WHERE`, rather than depending on whether the
  engine happens to allow referencing a `SELECT`-list alias inside `HAVING`.

## Business context

A relationship manager wants a short list of customers who are clearly net savers — depositing much more
than they withdraw — to prioritize for a savings-product pitch.

## Scenario

A customer's deposits and withdrawals can be spread across more than one of their accounts.

## Input assumptions

- 10 customers, 12 accounts, 27 transactions across `DEPOSIT`, `WITHDRAWAL`, and other transaction types.

## Task

List every customer whose total `DEPOSIT` amount (across all their accounts) exceeds their total
`WITHDRAWAL` amount by more than $500: `customer_id`, `full_name`, `net_deposits`, ordered highest first.

## Constraints

- Only `DEPOSIT` and `WITHDRAWAL` transactions count toward this figure — ignore `FEE`, `INTEREST`,
  `TRANSFER_IN`, `TRANSFER_OUT`, and `REVERSAL` for this particular report.
- A customer's transactions across multiple accounts must be combined into one figure per customer.

## Expected output

<!-- expected:start -->
| customer_id | full_name | net_deposits |
|---|---|---|
| 1 | Aarav Sharma | 6150.00 |
| 7 | Priya Nair | 5200.00 |
| 4 | Emily Carter | 3000.00 |
| 5 | Liam O'Brien | 1500.00 |
| 2 | Meera Iyer | 700.00 |

_5 row(s)_
<!-- expected:end -->

## Hints

<details><summary>Hint 1</summary>
First compute one row per customer with their total deposits and total withdrawals — that's a `GROUP BY` across joined `customers`, `accounts`, and `transactions`.
</details>
<details><summary>Hint 2</summary>
Put that aggregation in a CTE, giving the difference a name (e.g. `net_deposits`), then filter the CTE's result in an ordinary outer `WHERE` — you don't need `HAVING` at all once the aggregate has its own name.
</details>
<details><summary>Hint 3</summary>
`WITH customer_cash_flow AS (SELECT customer_id, full_name, SUM(CASE WHEN txn_type='DEPOSIT' THEN amount ELSE 0 END) - SUM(CASE WHEN txn_type='WITHDRAWAL' THEN amount ELSE 0 END) AS net_deposits FROM ... GROUP BY customer_id, full_name) SELECT * FROM customer_cash_flow WHERE net_deposits > 500 ORDER BY net_deposits DESC;`
</details>

## Solution

_MySQL 8.0+._

```sql
WITH customer_cash_flow AS (
    SELECT
        c.customer_id,
        c.full_name,
        SUM(CASE WHEN t.txn_type = 'DEPOSIT'    THEN t.amount ELSE 0 END)
      - SUM(CASE WHEN t.txn_type = 'WITHDRAWAL' THEN t.amount ELSE 0 END) AS net_deposits
    FROM customers c
    JOIN accounts a      ON a.customer_id = c.customer_id
    JOIN transactions t  ON t.account_id  = a.account_id
    GROUP BY c.customer_id, c.full_name
)
SELECT customer_id, full_name, net_deposits
FROM customer_cash_flow
WHERE net_deposits > 500
ORDER BY net_deposits DESC;
```

## Explanation

**Grain.** The CTE is at customer grain (after joining through accounts to transactions); the final
result is the same grain, just filtered.
**Rows that survive.** Every customer makes it into the CTE; only those with `net_deposits > 500` survive
the outer `WHERE`.
**Filtering.** The filter is applied *after* the aggregate has a name, in a plain `WHERE` on the CTE — no
`HAVING` needed, and no risk of the filter expression drifting out of sync with the `SELECT` expression
because there is only one copy of the calculation.
**Join cardinality.** `customers → accounts → transactions` is one-to-many at each step; grouping by
`customer_id` correctly rolls every account's transactions up to the customer level.
**Aggregation.** Two conditional sums combined into one derived column, computed once in the CTE.
**NULL behavior.** Not applicable — every transaction has a non-NULL `amount` and `txn_type`.
**Why it is correct.** Verified against the dataset: exactly 5 customers clear the $500 net-deposit bar,
matching a manual per-customer calculation.
**What could make it slow.** At this scale, nothing; the CTE here is for readability, not performance —
MySQL 8 materializes or inlines CTEs based on cost, the same as an equivalent subquery would be.
**How to validate.** Spot check customer 2 (Meera Iyer): 800.00 in deposits, 100.00 in withdrawals, net
700.00 — above the 500 bar by exactly 200.00, the smallest margin in the result, which is worth confirming
by hand.

## Common mistakes

**Repeating the full `CASE` expression in a `HAVING` clause instead of naming it once** — this works in
MySQL for a `SELECT`-list alias, but duplicates the business logic; if someone changes the `WHEN` clauses
in the `SELECT` and forgets to also change them in `HAVING`, the filter and the displayed number silently
disagree. This version is not wrong today, but it is the more fragile approach the CTE is meant to replace.
```sql wrong
SELECT
    c.customer_id,
    c.full_name,
    SUM(CASE WHEN t.txn_type = 'DEPOSIT' THEN t.amount ELSE 0 END) AS net_deposits
FROM customers c
JOIN accounts a      ON a.customer_id = c.customer_id
JOIN transactions t  ON t.account_id  = a.account_id
GROUP BY c.customer_id, c.full_name
HAVING SUM(CASE WHEN t.txn_type = 'DEPOSIT' THEN t.amount ELSE 0 END) > 500
ORDER BY net_deposits DESC;
```
(This version also forgets to subtract withdrawals at all — a second, independent bug: it would rank
customers by gross deposits, not net cash flow, changing both the membership and the order of the result.)

## Edge cases

- A customer with only `FEE`/`INTEREST`/transfer activity and no `DEPOSIT` or `WITHDRAWAL` rows at all
  would show `net_deposits = 0` under this query (via the `ELSE 0`), not NULL and not an error — worth
  confirming explicitly rather than assuming.

## Performance notes

Materialization of the CTE is a MySQL 8 optimizer decision, not something the query author controls
directly; if this became a performance concern at scale, `EXPLAIN` would show whether the CTE was
inlined or materialized — see Module 16.

## Optional challenge

Extend the CTE to also flag which customers have net deposits per account (not just per customer), and
identify whether any customer's positive overall net deposits are masking one account that is actually
net-negative.

## Related

Module: [06_CTEs](../../06_CTEs/) · Related: [05_CASE_WHEN](../../05_CASE_WHEN/)
