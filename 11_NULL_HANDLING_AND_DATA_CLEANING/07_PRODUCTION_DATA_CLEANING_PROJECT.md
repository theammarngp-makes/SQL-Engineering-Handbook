# 07 — Production Data Cleaning Project

## Introduction

This capstone combines every technique from the module — NULL handling, standardization, deduplication, and validation — into a single, realistic pipeline: cleaning a multi-table SaaS customer dataset before it feeds a monthly active accounts report.

## Concept Overview

Rather than isolated scenarios, this chapter presents one continuous dataset with multiple, layered data quality problems, and walks through building a clean, trustworthy staging layer from raw, messy source tables — the way this work is actually structured in a production analytics engineering role.

## Why This Exists

Real data cleaning is rarely one function applied once. It's a sequence: validate structure, standardize text, resolve duplicates, handle NULLs meaningfully, and only then compute business metrics — each step depending on the one before it. This chapter exists to practice that full sequence end to end, rather than each technique in isolation.

## Business Context

A SaaS company tracks `accounts` (companies) and `subscriptions` (billing records) across two data sources — a self-serve signup flow and a sales-assisted enterprise flow — that were merged into one warehouse without full reconciliation. Company names are inconsistently formatted, some subscriptions reference accounts that don't exist, some accounts are duplicated across the two sources, and NULL `cancelled_at` values are the correct signal for "still active" rather than a data quality problem.

## Real Company Examples

- **SaaS billing rollups**: distinguishing "still active" (NULL cancelled_at) from "data quality gap" (NULL where a cancellation clearly should have been recorded) is a recurring real-world distinction.
- **B2B account merging**: sales-assisted and self-serve signups for the same company routinely need deduplication by domain or standardized company name, not just exact string match.

## Business Problems Solved

This project produces a clean `accounts` view suitable for a monthly active accounts (MAA) metric — free of duplicate accounts, orphaned subscriptions, and inconsistent naming — while correctly preserving the business meaning of NULL where NULL is the right answer (active subscriptions).

## Visual Explanation

```
Raw Layer                  Cleaning Steps                Trusted Layer
───────────                ──────────────                ─────────────
accounts_raw   ──┐
                 │   1. Validate FKs (orphan check)
subscriptions_raw─┤   2. Standardize company_name
                 │   3. Deduplicate accounts
                 │   4. Resolve NULL semantics
                 │   5. Recompute MAA metric
                 └──────────────────────────────►   accounts_clean
                                                      monthly_active_accounts
```

## Syntax

This chapter is a synthesis of prior syntax — see the accompanying SQL file for the complete pipeline. No new functions are introduced; the focus is sequencing and combining `LEFT JOIN`, `ROW_NUMBER()`, `COALESCE`, `TRIM`/`LOWER`, and `CASE` correctly, in the right order, against a connected dataset.

## Detailed Explanation

The order of operations matters. Standardizing company names *before* deduplicating is required — deduplication logic that groups on raw, unstandardized names will miss duplicates that only differ by casing or whitespace. Validating orphaned foreign keys *before* computing the final metric prevents a subscription with no valid account from silently contributing to (or breaking) an aggregate. NULL handling for `cancelled_at` must be resolved last and carefully, since collapsing "still active" into a fallback value like `'N/A'` would destroy the exact signal the business relies on to compute active accounts.

## Production Workflow

1. Load raw data into staging tables, untouched
2. Run validation checks (orphaned foreign keys, structural issues) and quarantine/flag failures
3. Standardize text fields needed for deduplication or grouping
4. Deduplicate using a confirmed natural key and an explicit "keep" rule
5. Resolve NULL semantics deliberately, per column, based on business meaning
6. Compute the final business metric against the now-trusted layer
7. Document every transformation applied, in order, for future maintainers

## Engineering Considerations

- Each step in this pipeline should be a separate, testable query or view — not one giant nested query — so any single step can be audited or re-run independently
- The final trusted layer should be materialized (a table, not just a query) if it's queried frequently downstream, to avoid recomputing the full cleaning pipeline on every report run
- Every transformation applied should be reversible or at least fully traceable back to the raw layer, in case a cleaning assumption turns out to be wrong

## Performance Notes

For large SaaS datasets, deduplication and standardization steps should run as a scheduled batch job against the staging layer, not inline inside a live reporting query — recomputing `ROW_NUMBER()` over millions of rows on every dashboard refresh is unnecessary and slow when the result changes only as often as new data loads.

## Common Mistakes

- Deduplicating before standardizing, which misses duplicates that only differ by formatting
- Treating NULL `cancelled_at` as a data quality gap and "fixing" it with a fallback value, destroying the correct "still active" signal
- Skipping the orphaned foreign key check and letting invalid subscriptions inflate or corrupt the final metric
- Building the entire pipeline as one unreadable nested query instead of sequential, auditable steps

## Edge Cases

- An account legitimately cancelled and re-subscribed will have a non-NULL `cancelled_at` from its first subscription and a NULL `cancelled_at` from its second — both records are correct and neither should be deduplicated away
- A duplicate account pair might have genuinely different data quality in each copy (one has a phone number, the other doesn't) — the "keep" rule may need to prefer the more complete row rather than simply the earliest one

## Best Practices

- Build cleaning pipelines as a sequence of named, auditable steps, not a single opaque query
- Resolve NULL semantics last, and only after confirming what NULL actually means for that specific column in that specific business
- Materialize the trusted layer for anything queried repeatedly downstream

## Interview Questions

1. Why does the order of operations matter when standardizing text before deduplicating records?
2. How would you design a data cleaning pipeline to be auditable, so each step can be reviewed independently?
3. Give an example of a NULL value that should NOT be replaced with a fallback value, and explain why.
4. How would you decide which row to keep when two duplicate records have different degrees of completeness?

## Summary

This capstone project demonstrates that production data cleaning is a sequence, not a single query: validate, standardize, deduplicate, then resolve NULL semantics — each step depending on correct execution of the one before it. Getting the order right, and understanding what NULL actually means for each specific column, is what separates a fragile one-off fix from a durable, trustworthy pipeline.

## Practice Challenges

1. Using the accompanying dataset, identify which accounts are duplicates and decide a "keep" rule based on data completeness rather than just insertion order.
2. Write the final monthly active accounts (MAA) query using the cleaned, deduplicated account list.
3. Explain, in a short paragraph, why `cancelled_at` should not be run through `COALESCE()` with a fallback value in this pipeline.
4. Extend the pipeline with a new validation rule of your own choosing, and justify why it belongs in this specific dataset.

## Further Reading

- [MySQL Documentation — Views](https://dev.mysql.com/doc/refman/8.0/en/views.html)
- [PostgreSQL Documentation — Materialized Views](https://www.postgresql.org/docs/current/rules-materializedviews.html)
