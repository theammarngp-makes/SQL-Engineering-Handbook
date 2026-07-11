# 05 — Business Data Quality Case Studies

## Introduction

Individual techniques — NULL handling, standardization, deduplication — only prove their value when combined against a realistic business problem. This chapter walks through multi-step case studies across different domains, each requiring several techniques from this module chained together.

## Concept Overview

A case study differs from a scenario in scope: rather than demonstrating one function, each case study starts from a business question, requires diagnosing what's wrong with the data, and ends with a cleaned, trustworthy result — the way this work actually happens in production.

## Why This Exists

In practice, data quality problems rarely arrive labeled. A stakeholder says "our monthly active customer count looks wrong" — it's the analyst's job to figure out whether that's a NULL handling issue, a duplication issue, a standardization issue, or some combination, and fix it end to end.

## Business Context

Retail, finance, healthcare, and HR each have characteristic data quality failure modes: retail struggles with duplicate/fragmented customer records across channels, finance struggles with NULL propagation into totals, healthcare struggles with incomplete records that have compliance implications, and HR struggles with inconsistent categorical data (department names, job titles) entered by different people over time.

## Real Company Examples

- **Retail**: a "unique customers this quarter" metric that's actually overcounting because the same customer has three slightly different name/email combinations across online and in-store purchases.
- **Finance**: a quarterly revenue total that's understated because `SUM()` silently skips NULL transaction amounts from a partially-failed data sync, and nobody validated completeness first.
- **Healthcare**: a patient intake report flagged by a compliance audit because a meaningful fraction of records have NULL insurance information that should have been caught before reporting, not after.

## Business Problems Solved

These case studies mirror the actual shape of "clean this dataset" tickets an analytics engineer receives — vague on the surface, requiring diagnostic thinking, and demanding a defensible, explainable fix.

## Visual Explanation

```
Typical Data Quality Investigation Flow
─────────────────────────────────────────
1. Stakeholder reports a suspicious number
              │
              ▼
2. Profile the data: NULL rates, duplicate rates,
   distinct-value counts on key columns
              │
              ▼
3. Isolate the specific rows causing the discrepancy
              │
              ▼
4. Decide the correct handling (fix, flag, or exclude)
              │
              ▼
5. Re-run the original business question against
   cleaned data, and document what changed and why
```

## Syntax

This chapter is scenario-driven rather than syntax-driven — see the accompanying SQL file for the full worked queries. It combines syntax already introduced in files 01–04: `IS NULL`/`IS NOT NULL`, `COALESCE`, `NULLIF`, `TRIM`, `REPLACE`, `UPPER`/`LOWER`, `GROUP BY ... HAVING`, and `ROW_NUMBER()`.

## Detailed Explanation

Each case study in the accompanying SQL file follows the same shape: a stated business question, a diagnostic query that reveals the underlying data quality issue, and a corrected query that answers the original business question correctly. This mirrors how real investigations are documented — not just "here's the fix," but "here's the evidence for why the fix is needed."

## Production Workflow

1. Reproduce the stakeholder's reported number using the existing (possibly flawed) query
2. Profile the underlying tables for NULL rates, duplicate rates, and format inconsistency on the columns involved
3. Write a diagnostic query isolating the specific rows responsible for the discrepancy
4. Apply the minimum correct fix — don't over-clean columns unrelated to the reported problem
5. Document the root cause and the fix for future readers of the query

## Engineering Considerations

- Case studies like these are exactly what should be captured in code comments and PR descriptions when fixing a reporting bug — the "why," not just the "what"
- A fix that changes a reported number should always be validated against a manual sample of the affected rows, not just trusted because the query runs without error

## Performance Notes

Diagnostic profiling queries (NULL rate, distinct value counts) can be expensive on very large tables — consider running them against a sampled subset first when initially investigating, then validating against the full table once a hypothesis is formed.

## Common Mistakes

- Fixing the symptom (patching one report's number) without fixing or flagging the underlying data quality issue for other consumers of the same table
- Over-cleaning: applying standardization or deduplication logic more aggressively than the specific business question requires, potentially hiding real distinctions
- Not documenting why a number changed after a data quality fix, causing confusion when a stakeholder compares against a previous report

## Edge Cases

- A "data quality issue" sometimes turns out to be correct data and a wrong business assumption (e.g., assuming every order has a discount code, when most orders legitimately don't) — case studies should include verifying the assumption itself, not just the data
- Fixes applied at report time (rather than upstream) will need to be reapplied in every other report touching the same raw data — a strong signal that the fix belongs in an ETL/staging layer instead

## Best Practices

- Always show your diagnostic work, not just the final fixed query — future maintainers need the reasoning, not just the result
- Validate a data-quality fix against a small manual sample before trusting it at scale
- Push validated fixes upstream into the data pipeline when the same issue would recur across multiple reports

## Interview Questions

1. Walk through how you would investigate a stakeholder's report that "our customer count looks too high this month."
2. How would you distinguish a genuine data quality bug from a wrong business assumption about the data?
3. Why is it important to document the root cause of a data quality fix, not just the corrected query?
4. When should a data cleaning fix live in a report query versus further upstream in the pipeline?

## Summary

Real data quality work is diagnostic, not just mechanical — it requires forming a hypothesis about what's wrong, proving it with a query, and applying the narrowest correct fix. This chapter's case studies practice that full cycle across retail, finance, and healthcare-style scenarios.

## Practice Challenges

1. Given a "monthly unique customers" metric that seems inflated, write a diagnostic query to check for duplicate customer records caused by inconsistent name/email formatting.
2. Given a revenue total that seems understated, write a diagnostic query to check what percentage of transaction rows have a NULL amount.
3. Write up, in a short paragraph, the root-cause documentation you would attach to a PR that fixes one of the above issues.

## Further Reading

- [MySQL Documentation — Aggregate Functions](https://dev.mysql.com/doc/refman/8.0/en/aggregate-functions.html)
- [PostgreSQL Documentation — Aggregate Functions](https://www.postgresql.org/docs/current/functions-aggregate.html)
