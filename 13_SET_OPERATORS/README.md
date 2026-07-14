# Module 13 — Set Operators

> Combine, compare, and reconcile result sets using `UNION`, `UNION ALL`, `INTERSECT`, and `EXCEPT`/`MINUS` — the tools behind every migration audit, multi-source report, and data reconciliation pipeline.

## Why Set Operators Matter

Every prior module in this handbook taught you how to shape **one** result set — filtering it, aggregating it, joining it to related tables. Set operators answer a different class of question: *how do two or more result sets of the same shape relate to each other?*

That question is not academic. Organizations rarely store all of one kind of data in one place. Regional offices keep regional tables. Mergers leave two HR systems running side by side. ETL pipelines produce a staging copy that must be checked against production before it's trusted. Every one of these situations is a set-operator problem, and getting the operator wrong has real consequences — silently dropped duplicate transactions, silently duplicated report rows, or a migration declared "complete" when it isn't.

This module teaches set operators the way they are actually used in analytics engineering and data engineering: as reconciliation tools, integration tools, and reporting tools — not as syntax trivia.

## Learning Objectives

By the end of this module, you will be able to:

- Combine result sets correctly using `UNION` and `UNION ALL`, and explain the cost and correctness difference between them
- Use `INTERSECT` to find overlap between two populations, and `EXCEPT`/`MINUS` to find one-directional gaps
- Simulate `INTERSECT`/`EXCEPT` with `EXISTS`/`NOT EXISTS` on engines or versions that lack native support
- Build multi-source integration reports (cross-region, cross-year, cross-system) with a discriminator column
- Design and run a complete data reconciliation suite: row-count check, bidirectional `EXCEPT`, and value-level comparison
- Diagnose and avoid the most common set-operator mistakes, including the `UNION`-instead-of-`JOIN` trap
- Reason about the performance cost of deduplication and choose between native set operators and anti-join rewrites
- Answer set-operator interview questions from foundational to staff-engineer level

## Repository Navigation

| File | Covers |
|---|---|
| [`01_INTRODUCTION_TO_SET_OPERATORS.md`](01_INTRODUCTION_TO_SET_OPERATORS.md) / `.sql` | Set theory foundations, column/type rules, first-branch naming |
| [`02_UNION_AND_UNION_ALL.md`](02_UNION_AND_UNION_ALL.md) / `.sql` | Deduplication vs. concatenation, choosing correctly |
| [`03_INTERSECT_AND_EXCEPT.md`](03_INTERSECT_AND_EXCEPT.md) / `.sql` | Overlap and directional difference, `EXISTS`/`NOT EXISTS` simulation |
| [`04_BUSINESS_DATA_INTEGRATION.md`](04_BUSINESS_DATA_INTEGRATION.md) / `.sql` | Multi-source reporting, discriminator columns |
| [`05_DATA_RECONCILIATION.md`](05_DATA_RECONCILIATION.md) / `.sql` | Row-count checks, bidirectional `EXCEPT`, value-level joins |
| [`06_PERFORMANCE_AND_OPTIMIZATION.md`](06_PERFORMANCE_AND_OPTIMIZATION.md) / `.sql` | Cost of dedup, `EXISTS`/anti-join rewrites, recursive `UNION ALL` |
| `07_REAL_WORLD_CASE_STUDY.md` / `.sql` | *Pending — end-to-end case study, next in the module sequence* |

## Folder Structure

```
13_SET_OPERATORS/
├── README.md
├── 01_INTRODUCTION_TO_SET_OPERATORS.md
├── 01_INTRODUCTION_TO_SET_OPERATORS.sql
├── 02_UNION_AND_UNION_ALL.md
├── 02_UNION_AND_UNION_ALL.sql
├── 03_INTERSECT_AND_EXCEPT.md
├── 03_INTERSECT_AND_EXCEPT.sql
├── 04_BUSINESS_DATA_INTEGRATION.md
├── 04_BUSINESS_DATA_INTEGRATION.sql
├── 05_DATA_RECONCILIATION.md
├── 05_DATA_RECONCILIATION.sql
├── 06_PERFORMANCE_AND_OPTIMIZATION.md
├── 06_PERFORMANCE_AND_OPTIMIZATION.sql
├── 07_REAL_WORLD_CASE_STUDY.md      (pending)
└── 07_REAL_WORLD_CASE_STUDY.sql     (pending)
```

## Learning Flow

```
 01 Introduction ──► 02 UNION / UNION ALL ──► 03 INTERSECT / EXCEPT
                                                        │
                                                        ▼
 06 Performance ◄── 05 Reconciliation ◄── 04 Business Integration
        │
        ▼
 07 Real-World Case Study (synthesizes 01–06)
```

Each file assumes everything before it. `04` and `05` in particular are where the mechanics from `01`–`03` turn into the actual production work — integration reporting and reconciliation — that most analytics and data engineers do with set operators day to day.

## Engineering Mindset

Treat every set-operator query as a design decision, not a syntax shortcut:

- **Ask what a duplicate row means** before choosing `UNION` vs. `UNION ALL` — is it noise, or a real business event?
- **Ask which direction matters** before writing `EXCEPT`/`MINUS` — `A − B` and `B − A` answer different questions, and reconciliation requires both.
- **Ask whether you need more rows or more columns** — this single question prevents the most common production mistake in this module: reaching for `UNION` when the actual need is a `JOIN`.
- **Treat reconciliation as a testable assertion**, not a manual inspection — "zero rows returned" is a pass/fail condition your CI or pipeline can enforce.

## Business Motivation

Set operators exist because centralized, perfectly clean data is the exception, not the rule. Regional tables, legacy-and-new system pairs, yearly archives, and independently-built reports are the normal state of a growing business. Set operators are how a single, trustworthy report or a single, provable reconciliation gets built on top of that reality — without rearchitecting the underlying systems first.

## Architecture Overview

This module's SQL files share one evolving schema so that concepts compound instead of resetting with every file:

- `employees`, `departments`, `locations` — introduced in `01`, reused throughout
- `crm_customers`, `erp_customers` — introduced in `03` for migration/reconciliation scenarios
- `sales_us`, `sales_emea` — introduced in `04` for cross-region integration
- `expected_shipments`, `received_shipments`, `inventory_warehouse`, `inventory_erp` — introduced in `05` for full reconciliation suites
- `loyalty_members`, `newsletter_subscribers` — introduced in `06` for performance comparisons

Every `CREATE TABLE` and `INSERT` block is self-contained per file, so any file can be run independently, but the *business narrative* — an org with departments, a CRM/ERP split, and a multi-region sales operation — is continuous across the module.

## Production Applications

- Cross-region and cross-year reporting (`04`)
- ERP vs. CRM, production vs. staging, and warehouse vs. ERP reconciliation (`05`)
- ETL migration validation gated on zero-row `EXCEPT` checks (`03`, `05`)
- Fraud and compliance overlap analysis via `INTERSECT` (`03`, `06`)
- Recursive `UNION ALL` for hierarchy and org-chart traversal (`06`)
- Duplicate-detection diagnostics before a cleanup or dedup project (`02`, `06`)

## Performance Discussion

`UNION`, `INTERSECT`, and `EXCEPT` all require duplicate detection — typically a sort or hash-based pass over the combined result. `UNION ALL` skips this entirely and is materially cheaper at scale. On large tables, `EXISTS`/`NOT EXISTS`/`LEFT JOIN ... IS NULL` rewrites of `INTERSECT`/`EXCEPT` frequently outperform the native operators, because the optimizer can plan an index-seek anti-join instead of materializing and sorting both full sets. Module `06` benchmarks these rewrites directly — always confirm with `EXPLAIN` on real data volume rather than assuming either form is universally faster.

## Common Mistakes

- Defaulting to `UNION` out of habit and silently dropping real duplicate business events
- Running `EXCEPT`/`MINUS` in only one direction and declaring a migration "complete"
- Reaching for `UNION` when the actual requirement is a `JOIN` (more columns, not more rows)
- Using `NOT IN` instead of `NOT EXISTS` against a nullable column when simulating `EXCEPT`
- Comparing row counts alone as proof of reconciliation
- Forgetting a discriminator column when integrating multiple sources, losing row-level provenance

## Best Practices

- Default to `UNION ALL` in pipeline/ETL code; deduplicate explicitly and visibly when it's actually required
- Always reconcile `EXCEPT`/`MINUS` in both directions
- Add a discriminator column to every multi-source integration query
- Prefer `NOT EXISTS` over `NOT IN` when simulating `EXCEPT` on nullable columns
- Centralize integration logic behind a view or model rather than repeating it per report
- Automate reconciliation as a CI-gated or scheduled test asserting zero rows, not a manual check

## Interview Preparation

Each file ends with interview questions ranging from foundational to staff-level. Together they cover:

- The mechanical difference between `UNION` and `UNION ALL`, and why it matters for correctness, not just style
- Why `INTERSECT`/`EXCEPT` compare full rows, and how `NULL` behaves differently here than in a `WHERE` clause
- Designing a two-directional test that proves a migration moved every row with no gain or loss
- Diagnosing a dashboard or report that silently changed row counts after a set-operator edit
- Recognizing when a "combine two tables" instinct should have been a `JOIN`

## Practice Workflow

1. Read the `.md` file for the topic — concept, business context, and engineering considerations first.
2. Run the paired `.sql` file scenario by scenario, reading the engineering and optimization notes alongside each query.
3. Complete the practice problems at the end of each `.md` file before moving to the next topic.
4. After `06`, attempt to design your own reconciliation suite against two tables of your choosing before reading `07`'s case study.

## Module Checklist

- [ ] `01` — Introduction to Set Operators
- [ ] `02` — UNION and UNION ALL
- [ ] `03` — INTERSECT and EXCEPT
- [ ] `04` — Business Data Integration
- [ ] `05` — Data Reconciliation
- [ ] `06` — Performance and Optimization
- [ ] `07` — Real-World Case Study *(pending)*

## Previous Module

Module 12 — *link pending confirmation of the adjacent module's folder name in the live repository.*

## Next Module

Module 14 — *link pending confirmation of the adjacent module's folder name in the live repository.*

## Related Modules

- Joins — set operators combine rows of the *same* shape; joins combine *different* tables side by side. Understanding both, and when each applies, is the single most important distinction in this module (see `06`, Scenario 4).
- Subqueries and CTEs — `EXISTS`/`NOT EXISTS` simulations and recursive `UNION ALL` both depend on subquery and CTE fluency from earlier modules.
- Window Functions — often used alongside set-operator results for downstream ranking or deduplication of the combined set.

## Further Reading

- PostgreSQL Documentation — Combining Queries (`UNION`, `INTERSECT`, `EXCEPT`)
- Microsoft Learn — Set Operators (Transact-SQL)
- Oracle SQL Language Reference — `UNION`, `INTERSECT`, `MINUS`
- dbt Developer Hub — data testing and reconciliation patterns
- Snowflake Documentation — Query Syntax: Set Operators
