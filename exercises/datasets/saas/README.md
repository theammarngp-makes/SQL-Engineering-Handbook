# Dataset: SaaS

**Database:** `handbook_saas` · **Engine:** MySQL 8.0+, InnoDB, utf8mb4
**As-of date:** the data ends **2025-06-30**; exercises treat **2025-07-01** as "today".

```bash
mysql -u root < schema.sql
mysql -u root < seed.sql
```

**Scope note:** this release ships `plans`, `accounts`, and `subscriptions` only — enough for MRR, churn,
and upgrade/downgrade analytics. `invoices`, `usage events`, and `payments` are deferred to a later
release rather than shipped half-verified; see "Recommended exercises" below for what's already possible.

## Grain

| Table | One row = |
|---|---|
| `plans` | one pricing tier (4 rows: Starter/Pro/Business/Enterprise) |
| `accounts` | one customer company (10 rows) |
| `subscriptions` | one **continuous period** an account spent on one plan (14 rows) — an account can have several, over time |

## Relationships

`accounts 1—N subscriptions N—1 plans`. An account's subscription history is a timeline of
non-overlapping periods, not a single row — the current plan is whichever row has `end_date IS NULL`.

## The three subscription statuses (the core teaching point of this dataset)

- **`ACTIVE`** — currently in effect; `end_date IS NULL`.
- **`EXPIRED`** — this period ended because the account **upgraded or downgraded** to a different plan;
  the very next row (by `start_date`) for the same account continues without a gap. Not churn.
- **`CANCELED`** — this period ended because the customer **left**; `cancel_reason` is filled in. May or
  may not be followed by a later reactivation.

Conflating `EXPIRED` with `CANCELED` is the single most common mistake with this dataset: counting every
row with a non-NULL `end_date` as "lost" overstates churn by including every upgrade and downgrade.

## Known data-quality traps (intentional — teach with these, don't "fix" them)

- **Account 7 (Wayne Security) changed plans twice** (Starter → Pro → Business), producing 2 `EXPIRED`
  rows and 1 `ACTIVE` row — none of the `EXPIRED` rows are churn.
- **Account 5 (Soylent Foods) churned and came back**: a `CANCELED` Pro subscription (2024-05-05 to
  2025-01-31) followed by a new `ACTIVE` Starter subscription starting 2025-03-01. A query that treats
  "has any CANCELED row" as "currently churned" wrongly flags a paying customer.
- **Only 2 accounts are truly churned as of 2025-06-30** with no reactivation: account 3 (Initech Labs)
  and account 9 (Hooli Cloud).
- **Reactivation happened on a *different* plan** than the one that was canceled (Pro → Starter) — "what
  plan is this account on" must always look at the current `ACTIVE` row, never assume it matches history.
- **Current MRR (`ACTIVE AND end_date IS NULL`) is 1192.00** across 8 currently-active subscriptions —
  verified by summing `plans.monthly_price` directly; a query that sums over *all* subscription rows
  (including `EXPIRED`/`CANCELED`) overstates this substantially by counting plans no one is still paying for.
- **Gaps are real and meaningful**: account 5's gap (2025-01-31 to 2025-03-01) is over a month with zero
  active subscription — do not assume every account has continuous coverage.

## Recommended exercises

Advanced aggregations (MRR by plan with `WITH ROLLUP`) · CTEs/window functions (subscription sequence
per account, detecting upgrades vs cancellations from row order) · Set operators (accounts that ever
churned UNION accounts that ever upgraded, and where those sets overlap) · Date functions (tenure in
months as of 2025-07-01, accounting for the gap in account 5's history).
