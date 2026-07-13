<div align="center">

# Module 12 · Advanced Aggregations

### Engineering-grade GROUP BY, conditional aggregation, ROLLUP/CUBE, and executive-level SQL reporting

[![Module](https://img.shields.io/badge/Module-02-2563eb?style=flat-square)](.)
[![Level](https://img.shields.io/badge/Level-Intermediate-16a34a?style=flat-square)](.)
[![Dialects](https://img.shields.io/badge/Dialects-MySQL%208%2B%20%7C%20PostgreSQL-4f46e5?style=flat-square)](.)
[![Status](https://img.shields.io/badge/Status-Complete-22c55e?style=flat-square)](.)
[![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](../LICENSE)

*Part of the [SQL Engineering Handbook](../README.md) — a production-grade SQL curriculum built for data analysts, analytics engineers, and data engineers.*

</div>

---

## Table of Contents

- [Module Introduction](#module-introduction)
- [Why Advanced Aggregations Matter](#why-advanced-aggregations-matter)
- [Learning Objectives](#learning-objectives)
- [Skills You'll Gain](#skills-youll-gain)
- [Prerequisites](#prerequisites)
- [Folder Structure](#folder-structure)
- [Topics Covered](#topics-covered)
- [SQL Functions Covered](#sql-functions-covered)
- [Business Applications](#business-applications)
- [Analytics Engineering Perspective](#analytics-engineering-perspective)
- [Reporting Workflows](#reporting-workflows)
- [Dashboard Examples](#dashboard-examples)
- [Performance Considerations](#performance-considerations)
- [Best Practices](#best-practices)
- [Common Mistakes](#common-mistakes)
- [Interview Preparation](#interview-preparation)
- [Career Relevance](#career-relevance)
- [Learning Roadmap](#learning-roadmap)
- [Summary](#summary)
- [Further Reading](#further-reading)
- [Navigation](#navigation)

---

## Module Introduction

Every dashboard a stakeholder has ever looked at — revenue by region, active users by plan tier, on-time delivery rate by warehouse — is an aggregation. `SELECT`, `WHERE`, and a single-column `GROUP BY` get you a report. They do not get you a *system* a business can run on.

Module 02 picks up exactly where basic aggregation leaves off. Instead of asking "how do I get a total?", this module asks the questions a working analytics engineer actually gets asked:

- "Can you break that total down by region **and** month, but also show me the grand total?"
- "Can one query give me new customers, returning customers, and churned customers side by side?"
- "Can we get subtotals per department *and* a company-wide total, in a single result set, without five separate queries stitched together in Excel?"

Those questions are answered with the same handful of tools: multi-column `GROUP BY`, conditional aggregation with `CASE`, and the `ROLLUP` / `CUBE` / `GROUPING SETS` family. This module treats them not as syntax to memorize, but as the mechanism behind nearly every executive report, KPI table, and BI dashboard you will ever be asked to build.

By the end of this module, a multi-dimensional revenue-by-region-by-month report with subtotals and a grand total will look like a normal Tuesday, not a special occasion.

---

## Why Advanced Aggregations Matter

Basic `GROUP BY` answers "what is the total per group?" Real business reporting rarely stops at one grouping level, and it almost never stops at one metric.

**The reporting problem, concretely:**

A finance stakeholder asks for a quarterly revenue report. The naive approach is one query per slice — one for regional totals, one for monthly totals, one for the grand total — followed by manually stacking the results in a spreadsheet. This does not scale, it is error-prone (totals drift out of sync as the underlying data changes between query runs), and it makes the report impossible to automate into a dashboard or scheduled job.

**The engineering answer** is a single query that produces every level of the hierarchy in one aggregation pass, using `ROLLUP`, `CUBE`, or `GROUPING SETS`. The database computes subtotals and grand totals in one scan, guaranteeing the numbers are internally consistent, and the result set can be fed directly into a BI tool or materialized as a report table.

**The KPI problem, concretely:**

A product manager wants one table: new signups, upgraded accounts, downgraded accounts, and cancellations, all in the same row, broken out by month. Five separate `WHERE`-filtered queries produce five separate result sets that then have to be joined back together — slow, brittle, and hard to maintain. Conditional aggregation (`COUNT(CASE WHEN ...)`, `SUM(CASE WHEN ...)`) computes all four metrics in a single `GROUP BY` pass over the same rows.

This is the difference between SQL as a query language and SQL as a **reporting engine**. Companies with mature data teams do not build dashboards by running many small queries and reassembling them downstream — they push the aggregation logic into SQL itself, because the database is faster, more consistent, and easier to schedule than anything built on top of it.

---

## Learning Objectives

After completing this module, you will be able to:

1. Group data across multiple columns and reason correctly about how grouping granularity changes result cardinality.
2. Compute several independent aggregate metrics in a single `SELECT`, avoiding repeated table scans.
3. Build conditional metrics — "count of X where condition," "sum of Y where condition" — using `CASE` inside aggregate functions.
4. Turn a handful of conditional aggregates into a pivot-style report without a dedicated `PIVOT` operator.
5. Generate subtotals and grand totals in a single query using `ROLLUP`, `CUBE`, and `GROUPING SETS`.
6. Distinguish subtotal rows from data rows using `GROUPING()`, and format them correctly for downstream reporting tools.
7. Design executive KPI tables and dashboard-ready result sets that mirror what BI tools like Power BI, Looker, and Tableau expect as input.
8. Apply `HAVING` correctly to filter on aggregated values, and avoid the most common `WHERE`-versus-`HAVING` mistake.
9. Reason about the performance cost of multi-dimensional aggregation and know when to pre-aggregate versus aggregate on the fly.
10. Read and produce production-quality reporting SQL that a senior analytics engineer would approve in code review.

---

## Skills You'll Gain

| Skill | Description |
|---|---|
| Multi-dimensional grouping | Grouping by two, three, or more columns and interpreting the resulting grain correctly |
| Conditional aggregation | Building `COUNT`/`SUM`/`AVG` metrics gated by business conditions in a single pass |
| Pivot-style reporting | Producing wide, dashboard-ready tables from tall transactional data without a `PIVOT` clause |
| Subtotal/grand-total generation | Using `ROLLUP`, `CUBE`, and `GROUPING SETS` to generate hierarchical totals in one query |
| Grouping-row detection | Using `GROUPING()` to label subtotal and grand-total rows for presentation layers |
| KPI table design | Structuring a single query to answer "what does the business need to see" rather than "what can I technically compute" |
| Aggregation performance tuning | Recognizing when `GROUP BY` becomes a bottleneck and what indexing/pre-aggregation strategies address it |
| Report-oriented SQL review | Evaluating aggregation queries the way a data team lead would in a pull request |

---

## Prerequisites

Before starting this module, you should already be comfortable with:

- ✅ `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`
- ✅ Basic aggregate functions: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
- ✅ Single-column `GROUP BY` and `HAVING`
- ✅ Basic `JOIN` syntax (`INNER JOIN` at minimum)
- ✅ `CASE WHEN` as a scalar expression in a `SELECT` list

If any of these feel shaky, complete **Module 01** before starting here — this module assumes fluency with the fundamentals and moves directly into professional reporting patterns.

---

## Folder Structure

```
12_ADVANCED_AGGREGATIONS/
│
├── README.md                              → You are here
│
├── 01_ADVANCED_GROUP_BY.md                → Multi-column & nested grouping, theory + patterns
├── 01_ADVANCED_GROUP_BY.sql               → Scenario-driven queries: multi-level GROUP BY
│
├── 02_MULTIPLE_AGGREGATIONS.md            → Combining COUNT/SUM/AVG/MIN/MAX in one pass
├── 02_MULTIPLE_AGGREGATIONS.sql           → Scenario-driven queries: multi-metric reports
│
├── 03_CONDITIONAL_AGGREGATION.md          → CASE-driven metrics, conditional KPIs
├── 03_CONDITIONAL_AGGREGATION.sql         → Scenario-driven queries: conditional aggregation
│
├── 04_ROLLUP_CUBE_GROUPING_SETS.md        → Subtotals, grand totals, GROUPING()
├── 04_ROLLUP_CUBE_GROUPING_SETS.sql       → Scenario-driven queries: ROLLUP/CUBE/GROUPING SETS
│
├── 05_BUSINESS_KPI_REPORTS.md             → End-to-end KPI table design
├── 05_BUSINESS_KPI_REPORTS.sql            → Scenario-driven queries: KPI reporting
│
├── 06_EXECUTIVE_DASHBOARDS.md             → Dashboard-ready, BI-tool-ready result sets
├── 06_EXECUTIVE_DASHBOARDS.sql            → Scenario-driven queries: executive dashboards
│
├── 07_REAL_WORLD_ANALYTICS_PROJECT.md     → Capstone: a full reporting project, start to finish
└── 07_REAL_WORLD_ANALYTICS_PROJECT.sql    → Capstone SQL solution
```

Every `.md` file is the concept deep-dive. Every `.sql` file is the paired, runnable, scenario-driven companion — read them side by side.

---

## Topics Covered

<table>
<tr><th>Category</th><th>Topics</th></tr>
<tr>
<td><strong>Advanced GROUP BY</strong></td>
<td>Grouping by multiple columns · Nested grouping · Multi-level aggregation · Grain and cardinality reasoning</td>
</tr>
<tr>
<td><strong>Core Aggregates, Combined</strong></td>
<td><code>COUNT()</code> · <code>COUNT(DISTINCT)</code> · <code>SUM()</code> · <code>AVG()</code> · <code>MIN()</code> · <code>MAX()</code> used together in one report</td>
</tr>
<tr>
<td><strong>Conditional Aggregation</strong></td>
<td><code>COUNT</code> with <code>CASE</code> · <code>SUM</code> with <code>CASE</code> · <code>AVG</code> with <code>CASE</code> · conditional KPIs · pivot-style reports</td>
</tr>
<tr>
<td><strong>Business Reporting</strong></td>
<td>Revenue analysis · profit analysis · customer segmentation · regional reports · category performance · monthly business reports · department reports · sales performance · top/bottom performing products</td>
</tr>
<tr>
<td><strong>Hierarchical Totals</strong></td>
<td><code>ROLLUP</code> · <code>CUBE</code> · <code>GROUPING SETS</code> · <code>GROUPING()</code> · subtotals · grand totals</td>
</tr>
<tr>
<td><strong>Filtering &amp; Optimization</strong></td>
<td>Aggregation with <code>HAVING</code> · performance optimization · aggregation best practices</td>
</tr>
</table>

---

## SQL Functions Covered

| Function / Clause | Purpose |
|---|---|
| `GROUP BY (col1, col2, ...)` | Aggregate across multiple dimensions simultaneously |
| `COUNT()` / `COUNT(DISTINCT)` | Row counts and unique-value counts per group |
| `SUM()` | Additive totals per group |
| `AVG()` | Mean value per group |
| `MIN()` / `MAX()` | Boundary values per group |
| `CASE WHEN ... THEN ... END` (inside aggregates) | Conditional metrics within a single aggregation pass |
| `ROLLUP(col1, col2, ...)` | Hierarchical subtotals + grand total, one dimension order |
| `CUBE(col1, col2, ...)` | Every combination of subtotals across all listed dimensions |
| `GROUPING SETS (...)` | Explicit, hand-picked set of grouping combinations |
| `GROUPING(col)` | Returns `1` for subtotal/grand-total rows, `0` for detail rows |
| `HAVING` | Filters groups *after* aggregation, unlike `WHERE` |

---

## Business Applications

This module's techniques map directly onto reports that exist in nearly every company with a data team:

- **Revenue & finance** — revenue by region × quarter with subtotals, profit margin by product line, budget-vs-actual rollups
- **Retail & e-commerce** — top/bottom performing SKUs, category performance, order-value segmentation
- **Marketing** — campaign performance with conditional conversion metrics, channel attribution summaries
- **Human Resources** — headcount by department × location, attrition rates, tenure distribution reports
- **Banking & finance** — transaction volume by branch × product, fraud-flag rate by conditional aggregation
- **Healthcare** — patient visit counts by department × month, readmission-rate KPIs
- **Supply chain & logistics** — on-time delivery rate by warehouse, shipment volume by carrier × region
- **SaaS** — MRR movement (new, expansion, contraction, churn) as a single conditional-aggregation query

---

## Analytics Engineering Perspective

A data analyst writes a query to answer one question. An analytics engineer writes a query — or more often, a `dbt` model or a scheduled report table — that many people will query *against* for months or years. That distinction changes how you should think about everything in this module.

- **Grain discipline.** Before writing a single `GROUP BY`, know the intended grain of the output (one row per region-month? per customer-segment? per product-category-day?). Multi-column grouping makes it easy to accidentally produce a finer grain than intended, silently duplicating what looked like a total.
- **Idempotent aggregation.** Reporting queries are frequently re-run on a schedule. `ROLLUP`/`CUBE` output should be deterministic and stable — the same inputs must always produce the same subtotal and grand-total rows, in a predictable shape, so downstream dashboards don't break on refresh.
- **Reusable metric definitions.** Conditional aggregation logic (e.g., "what counts as a *returning* customer") tends to get copy-pasted across a dozen reports. In a mature analytics engineering setup, that `CASE` logic belongs in a single, tested definition (a `dbt` macro, a view, or a documented business-logic table) — not re-typed slightly differently in every query.
- **Separation of aggregation from presentation.** SQL should produce correctly aggregated numbers. Formatting, subtotal labeling, and layout belong in the BI layer. `GROUPING()` exists precisely so SQL can flag "this is a subtotal row" without hardcoding a label like `'All Regions'` into the data.

---

## Reporting Workflows

A typical production reporting workflow that uses this module's techniques looks like this:

```
┌─────────────────┐      ┌──────────────────────┐      ┌────────────────────┐
│  Raw / staged     │      │  Aggregation layer     │      │  Presentation layer   │
│  transactional     │ ──▶  │  (this module)          │ ──▶  │  (BI tool / export)     │
│  tables             │      │  GROUP BY, CASE,         │      │  Power BI / Looker /   │
│  (orders, sales,    │      │  ROLLUP / CUBE /          │      │  Tableau / scheduled   │
│  payments, ...)      │      │  GROUPING SETS            │      │  report / dashboard     │
└─────────────────┘      └──────────────────────┘      └────────────────────┘
```

1. **Extract the question.** "Regional revenue by month, with subtotals per region and a company grand total."
2. **Identify the grain and the dimensions.** Grain = region × month. Dimensions to roll up = region, month.
3. **Pick the aggregation tool.** A fixed hierarchy (region → month) suggests `ROLLUP`. If every combination of subtotals is needed, `CUBE`. If only specific combinations matter, `GROUPING SETS`.
4. **Add conditional metrics if the report needs more than one KPI per row** (e.g., total revenue *and* refunded revenue *and* net revenue) using `CASE`-driven aggregation.
5. **Filter groups, not rows,** with `HAVING` (e.g., "only show regions with more than $50,000 in monthly revenue").
6. **Hand off a stable, well-typed result set** to the BI layer or materialize it as a report table on a schedule.

---

## Dashboard Examples

Representative outputs you will be able to produce by the end of this module:

**Regional revenue with subtotals (ROLLUP):**

| region | order_month | total_revenue |
|---|---|---|
| East | 2026-01 | 182,400 |
| East | 2026-02 | 176,900 |
| East | *(subtotal)* | 359,300 |
| West | 2026-01 | 145,200 |
| West | 2026-02 | 151,050 |
| West | *(subtotal)* | 296,250 |
| *(grand total)* | | 655,550 |

**SaaS MRR movement (conditional aggregation):**

| billing_month | new_mrr | expansion_mrr | contraction_mrr | churned_mrr |
|---|---|---|---|---|
| 2026-05 | 42,000 | 11,300 | -3,200 | -8,900 |
| 2026-06 | 39,500 | 9,800 | -2,100 | -6,400 |

Both of these are single queries — no spreadsheet stitching, no five separate result sets joined by hand.

---

## Performance Considerations

- **`GROUP BY` cost scales with cardinality, not row count alone.** Grouping by a high-cardinality combination of columns (e.g., `customer_id` × `order_date`) can produce a result set nearly as large as the source table — know your dimension cardinality before running it against a production table.
- **`ROLLUP`/`CUBE` multiply output rows.** `CUBE` on *n* columns produces up to 2ⁿ grouping combinations. On more than 3–4 dimensions, this grows fast; prefer `GROUPING SETS` with an explicit, business-relevant list of combinations instead of a full `CUBE`.
- **Conditional aggregation avoids repeated scans.** Five `CASE`-driven metrics in one `GROUP BY` pass are far cheaper than five separate filtered queries unioned together, because the table is scanned once instead of five times.
- **Index the `GROUP BY` and filter columns**, not the aggregated columns. An index on `(region, order_date)` helps a `GROUP BY region, order_date` far more than an index on `revenue` ever will.
- **`HAVING` runs after aggregation** — it does not reduce the number of rows scanned. Push every filter you can into `WHERE` first, and reserve `HAVING` strictly for conditions on the aggregated value itself.
- **Pre-aggregate for dashboards with heavy read traffic.** If the same rollup is queried hundreds of times a day, materialize it into a summary table on a schedule rather than recomputing it live on every dashboard refresh.

---

## Best Practices

- Always know the intended output grain *before* writing the `GROUP BY` clause — write it down as a comment if the query is non-trivial.
- Alias every aggregate column with a business-meaningful name (`total_revenue`, not `sum_amt`).
- Use `COALESCE()` or `IFNULL()` to convert `NULL` subtotal labels from `ROLLUP`/`CUBE` into readable values like `'All Regions'` in the presentation layer — not by hardcoding a fake row into the source data.
- Prefer `GROUPING SETS` over `CUBE` once you only need specific combinations — it's more explicit about business intent and cheaper to compute.
- Filter with `WHERE` wherever possible; reserve `HAVING` for aggregate-level conditions only.
- Keep conditional-aggregation `CASE` logic consistent across the codebase — define "active customer" or "on-time delivery" once and reuse it, rather than re-deriving it slightly differently in every report.
- Test aggregation queries against a known subtotal manually (e.g., confirm regional subtotals sum to the grand total) before shipping a report.

---

## Common Mistakes

| Mistake | Why It's a Problem | Fix |
|---|---|---|
| Filtering on an aggregate with `WHERE` | `WHERE` runs before aggregation and cannot reference `SUM()`/`COUNT()` | Use `HAVING` for aggregate-level conditions |
| Forgetting a `GROUP BY` column that appears in `SELECT` | Causes an error (strict SQL modes) or silently wrong results (lenient modes) | Every non-aggregated `SELECT` column must appear in `GROUP BY` |
| Treating `ROLLUP`/`CUBE` `NULL`s as missing data | Those `NULL`s mean "this is a subtotal row," not "unknown value" | Use `GROUPING()` to distinguish real `NULL`s from subtotal rows |
| Using `CUBE` when only a few combinations are needed | Produces far more rows than the report requires, wasting compute | Use `GROUPING SETS` with the exact combinations needed |
| Double-counting with `COUNT()` instead of `COUNT(DISTINCT)` after a `JOIN` | A one-to-many join inflates row counts before aggregation | Use `COUNT(DISTINCT primary_key)` when joins can multiply rows |
| Copy-pasting slightly different `CASE` conditions across reports | Two reports quietly define "active user" differently, and numbers stop matching | Centralize business-logic definitions in one place |

---

## Interview Preparation

Advanced aggregation is one of the most heavily tested areas in SQL interviews for analyst, analytics engineer, and data engineer roles, because it directly measures reporting fluency. Be ready to:

- Explain the exact difference between `WHERE` and `HAVING`, including *why* `WHERE` cannot filter on an aggregate.
- Write a query that returns both detail rows and a grand total in a single result set.
- Explain what `ROLLUP(a, b)` produces versus `CUBE(a, b)` versus `GROUPING SETS ((a, b), (a), ())`.
- Convert a "five separate `WHERE`-filtered queries" description into one query using conditional aggregation.
- Explain what `GROUPING()` returns and why it matters for distinguishing real `NULL` values from subtotal rows.
- Reason out loud about the output cardinality of a multi-column `GROUP BY` before running it.
- Discuss when you would pre-aggregate into a summary table instead of aggregating on every query.

---

## Career Relevance

This is not academic SQL — it is the daily work product of a data analyst or analytics engineer. Nearly every recurring report, KPI dashboard, or scheduled data extract that a business runs on is built from exactly the techniques in this module: multi-dimensional `GROUP BY`, conditional metrics, and hierarchical rollups. Fluency here is what separates "can write a `SELECT` statement" from "can be handed a vague business question and return a report a VP will trust."

---

## Learning Roadmap

<details>
<summary><strong>🟢 Beginner path</strong> — build the mental model first</summary>

1. `01_ADVANCED_GROUP_BY` — get comfortable grouping by two or three columns
2. `02_MULTIPLE_AGGREGATIONS` — combine multiple metrics in one query
3. `03_CONDITIONAL_AGGREGATION` — introduce `CASE` inside aggregates
4. Practice challenges at the end of each `.md` file before moving on

</details>

<details>
<summary><strong>🟡 Intermediate path</strong> — production reporting patterns</summary>

1. `04_ROLLUP_CUBE_GROUPING_SETS` — subtotal and grand-total generation
2. `05_BUSINESS_KPI_REPORTS` — full KPI table design end to end
3. Revisit `03_CONDITIONAL_AGGREGATION` and rebuild each example from memory

</details>

<details>
<summary><strong>🔴 Advanced path</strong> — dashboard and capstone readiness</summary>

1. `06_EXECUTIVE_DASHBOARDS` — BI-tool-ready, presentation-grade result sets
2. `07_REAL_WORLD_ANALYTICS_PROJECT` — full capstone project, unaided
3. Rebuild the capstone using a different business domain than the one provided

</details>

---

## Summary

Basic aggregation answers one question about one group. This module builds the skill of answering many related questions about many groups, in a single, efficient query — which is what "reporting" actually means in a professional data team. Multi-column `GROUP BY` sets the grain. Conditional aggregation adds multiple business-defined metrics in one pass. `ROLLUP`, `CUBE`, and `GROUPING SETS` add the subtotal and grand-total structure every executive report expects. Together, these are the tools behind almost every dashboard, KPI table, and business report you will encounter in a data role.

---

## Further Reading

- [PostgreSQL Documentation — Aggregate Functions](https://www.postgresql.org/docs/current/functions-aggregate.html)
- [PostgreSQL Documentation — GROUPING SETS, CUBE, and ROLLUP](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-GROUPING-SETS)
- [MySQL 8.0 Reference Manual — GROUP BY Modifiers (ROLLUP)](https://dev.mysql.com/doc/refman/8.0/en/group-by-modifiers.html)
- [MySQL 8.0 Reference Manual — Aggregate Function Descriptions](https://dev.mysql.com/doc/refman/8.0/en/aggregate-functions.html)
- [Microsoft Learn — GROUP BY (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-group-by-transact-sql)

---

## Navigation

| | |
|---|---|
| ⬅️ **Previous Module** | [`11_NULL_HANDLING_AND_DATA_CLEANING`](/11_NULL_HANDLING_AND_DATA_CLEANING/README.md) |
| ⬆️ **Handbook Home** | [SQL Engineering Handbook](../README.md) |
| ➡️ **Next Module** | [`13_SET_OPERATORS`](/13_SET_OPERATORS/README.md) |

