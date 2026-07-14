# 07 — Real-World Case Study: Retail Merger Data Consolidation

## Introduction

This is the capstone of Module 13. Every operator and pattern from Topics 01–06 gets applied together against one continuous business scenario, the way they actually show up in a single real project — not as isolated syntax demonstrations.

## Concept Overview

The scenario: **GlobalMart**, a mid-size retailer, has just acquired **UrbanCart**, a regional e-commerce competitor. The data engineering team has one quarter to deliver three things leadership is asking for directly:

1. A single, unified sales report across both companies' regions
2. Proof that the customer database migration from UrbanCart's legacy CRM into GlobalMart's CRM was complete and lossless
3. A cleaned, deduplicated combined loyalty list for the first joint marketing campaign

Every one of these is a set-operator problem, and this file solves all three end to end.

## Why This Exists

Textbook examples teach one operator at a time. Production work never arrives that way — a single project typically needs integration reporting, reconciliation, and deduplication together, often against the same tables, often under a deadline. This case study is deliberately built to require moving between `UNION ALL`, `INTERSECT`, `EXCEPT`, and their `EXISTS`/`NOT EXISTS` equivalents in one coherent piece of work, so the *decision-making* — not just the syntax — gets exercised.

## Business Context

Mergers and acquisitions are one of the most common real-world triggers for heavy set-operator use: two companies, each with their own customers, sales history, and product catalogs, need one combined operational picture fast, and leadership needs proof — not a verbal assurance — that no customer or transaction was lost in the process.

## Real Company Examples

- A large grocery chain acquiring a regional chain runs a full customer and inventory reconciliation before consolidating loyalty programs, using exactly the bidirectional `EXCEPT` pattern from Topic 05.
- A telecom acquiring an MVNO (mobile virtual network operator) integrates subscriber tables with `UNION ALL` and a discriminator column while the two billing systems run in parallel for a transition period, following the pattern from Topic 04.
- A SaaS company acquiring a competitor deduplicates two overlapping trial-user lists with `UNION`/`INTERSECT` before a combined onboarding email campaign, following Topic 02's and Topic 03's patterns.

## Production Use Cases

- Post-merger customer and sales data consolidation
- Migration completeness sign-off for a compliance or audit function
- Deduplicated cross-company marketing lists
- Ongoing dual-source reporting during a transition period before systems are fully merged

## Visual Explanation

```
 UrbanCart CRM ──┐                        ┌── GlobalMart CRM
                 │                        │
                 ▼                        ▼
         ┌───────────────────────────────────────┐
         │   customer_id EXCEPT (both directions)  │  → migration gaps
         └───────────────────────────────────────┘
                 │                        │
                 ▼                        ▼
         sales_urbancart          sales_globalmart
                 │                        │
                 └──────── UNION ALL ─────┘  → unified_sales (Topic 04 pattern)

         loyalty_urbancart  UNION  loyalty_globalmart  → deduplicated campaign list
```

## Syntax

No new syntax is introduced in this file — every statement below is a direct application of `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`, and `EXISTS`/`NOT EXISTS` as taught in Topics 01–06.

## Detailed Explanation

The case study is deliberately sequenced to mirror a real project timeline:

1. **Integrate first** (Topic 04 pattern) — leadership wants a combined sales view immediately, before any cleanup work is done, because a rough combined picture today is more valuable than a perfect one next month.
2. **Reconcile second** (Topics 03 and 05 patterns) — once the combined view exists, the migration of UrbanCart's customers into GlobalMart's CRM must be formally verified, in both directions, before UrbanCart's legacy system is decommissioned.
3. **Deduplicate last** (Topic 02 pattern) — the joint loyalty list is only built once the reconciliation confirms which customers are genuinely distinct versus already-migrated duplicates.

This order is itself an engineering decision: reversing steps 2 and 3 risks building a marketing list on top of an unverified, possibly incomplete migration.

## Business Examples

```sql
-- Step 1 preview: unified sales, tagged by originating company
SELECT order_id, order_total, order_date, 'GlobalMart' AS source_company
FROM sales_globalmart
UNION ALL
SELECT order_id, order_total, order_date, 'UrbanCart' AS source_company
FROM sales_urbancart;
```

```sql
-- Step 2 preview: migration gap check, one direction
SELECT customer_id FROM urbancart_customers
EXCEPT
SELECT customer_id FROM globalmart_customers;
```

## Production Workflow

1. Confirm schema compatibility between UrbanCart and GlobalMart tables (column count, types) before writing any combining query — see Topic 01.
2. Build the unified sales report with `UNION ALL` and a `source_company` discriminator — see Topic 04.
3. Run the bidirectional `EXCEPT` migration audit on `customer_id` — see Topics 03 and 05.
4. Route any non-empty `EXCEPT` result to a manual investigation queue before proceeding.
5. Once the audit passes, build the deduplicated joint loyalty list with `UNION` — see Topic 02.
6. Re-express the costliest queries as `EXISTS`/`NOT EXISTS` and compare — see Topic 06 — before scheduling any of this as a recurring job.

## Engineering Considerations

- This case study uses three previously-independent schemas (`sales_globalmart`/`sales_urbancart`, `urbancart_customers`/`globalmart_customers`, `loyalty_globalmart`/`loyalty_urbancart`) rather than the running `employees`/`departments` schema from Topics 01–06, because a real merger scenario involves genuinely separate systems, not variations of one company's internal data.
- The migration audit (Step 2) is the query that should be automated and re-run on a schedule until UrbanCart's legacy CRM is formally decommissioned — not run once and forgotten.
- The `source_company` discriminator introduced in Step 1 is what allows leadership to ask "how is UrbanCart's book of business performing since the acquisition?" without a schema redesign.

## Performance Notes

At small scale, every form below performs indistinguishably. At the actual scale a merger reconciliation runs at — often hundreds of thousands to millions of customer records — the `EXISTS`/`NOT EXISTS` rewrites from Topic 06 are very likely to outperform the native `EXCEPT`/`INTERSECT` forms, provided `customer_id` is indexed on both sides. This file includes both forms for the migration audit specifically so the choice can be benchmarked on real data rather than assumed.

## Database Compatibility

| Feature used | MySQL | PostgreSQL | SQL Server | Oracle |
|---|---|---|---|---|
| `UNION ALL` integration (Step 1) | ✅ | ✅ | ✅ | ✅ |
| `EXCEPT` migration audit (Step 2) | 8.0.31+ | ✅ | ✅ | use `MINUS` |
| `NOT EXISTS` rewrite (Step 2 alt.) | ✅ | ✅ | ✅ | ✅ |
| `UNION` deduplication (Step 3) | ✅ | ✅ | ✅ | ✅ |

## Best Practices

- Sequence the work: integrate, reconcile, then deduplicate — not in an arbitrary order.
- Never decommission a legacy source system until its bidirectional `EXCEPT` audit against the target system returns zero rows.
- Keep the discriminator column from the integration step even after reconciliation is complete — provenance stays valuable long after the migration project ends.

## Common Mistakes

- Building the joint marketing list (`UNION`) before the migration audit passes, risking a campaign sent against an incomplete or duplicated customer base.
- Treating a passing migration audit as permanent — if UrbanCart's legacy system is still writable during the transition period, the audit must be re-run until it's formally retired.
- Forgetting that Step 1's `UNION ALL` and Step 3's `UNION` are solving different problems (integration vs. deduplication) and are not interchangeable.

## Edge Cases

- A customer who signed up independently with both UrbanCart and GlobalMart before the acquisition (same person, two different `customer_id` values, no shared key) will **not** be caught by an `EXCEPT`/`INTERSECT` audit on `customer_id` — that is a fuzzy-matching problem (name, email, address similarity), outside the scope of exact-match set operators, and worth flagging explicitly to stakeholders as a known limitation.
- Orders placed during the exact cutover window may exist in both source systems momentarily — define and document a clear cutover timestamp before running Step 1's integration query to avoid double-counting.

## Interview Questions

1. **(Foundational)** In this case study, why is `UNION ALL` correct for the sales integration but `UNION` correct for the loyalty list?
2. **(Intermediate)** Why does the workflow reconcile customers *before* building the joint loyalty list, rather than after?
3. **(Advanced)** What limitation does an exact-match `EXCEPT`/`INTERSECT` audit have when the same real-world customer has two different, unrelated ID values in each system? How would you address it?
4. **(Staff-level)** Design the recurring automated check that should run for as long as UrbanCart's legacy CRM remains writable during the transition period, and describe what should happen when it fails.

## Summary

A real merger data-consolidation project needs every pattern from this module, applied in a deliberate sequence: integrate for an immediate combined view, reconcile to prove the migration is trustworthy, then deduplicate to produce a clean downstream asset. The SQL file accompanying this topic implements all three steps against a realistic two-company schema, including a performance-rewrite comparison for the reconciliation step.

## Practice Problems

1. Extend Step 1's unified sales query to include a `product_category` breakdown, assuming both `sales_globalmart` and `sales_urbancart` gain a `product_category` column.
2. Write the `NOT EXISTS` equivalent of Step 2's migration audit for the reverse direction (GlobalMart customers missing from UrbanCart) and explain when that direction would legitimately return non-empty results.
3. Propose, in a comment, a fuzzy-matching approach (outside pure set operators) for the same-person/different-ID edge case described above.

## Further Reading

- dbt Developer Hub — data testing and reconciliation patterns
- PostgreSQL Docs — Combining Queries
- Microsoft Learn — Set Operators (Transact-SQL)

---
[← Performance and Optimization](06_PERFORMANCE_AND_OPTIMIZATION.md) · [Back to README](README.md)
