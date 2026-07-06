# Module 08 — Window Function Applications

> **Bridging syntax and real-world analytics.**
> This module does not teach you *what* a window function is. Module 07 already did that. This module teaches you *where, why, and how* window functions are used inside real companies — in HR systems, sales pipelines, e-commerce platforms, banking cores, and finance departments.

---

## 1. Module Introduction

Every SQL engineer eventually learns the syntax of `ROW_NUMBER()`, `RANK()`, `LAG()`, and `SUM() OVER (...)`. Very few are taught **why an analytics team would reach for one over the other**, or **what business question each pattern actually answers**.

This gap is why candidates who can recite window function syntax in an interview still struggle to write a query that solves an actual leadership request like:

- "Show me the top 2 earners in every department."
- "What's our running revenue this quarter, and how does it compare to last year?"
- "Flag any account with unusually large transactions relative to its own history."

Window functions are the backbone of modern analytics engineering because they let you **compare a row to its peers, its past, and its group — without collapsing the dataset**. Unlike `GROUP BY`, which flattens data into summaries, window functions preserve row-level granularity while attaching aggregate, ranking, and offset context to each row. This is exactly the shape of data that feeds dashboards, leaderboards, cohort reports, and anomaly detection systems.

This module is organized around **five business domains** that, together, cover the vast majority of window function use cases you will encounter in industry: HR Analytics, Sales Analytics, E-Commerce, Banking, and Finance.

---

## 2. Learning Objectives

By the end of this module, you will be able to:

- Map a business requirement (e.g., "leaderboard," "running total," "cohort comparison") directly to the correct window function pattern.
- Choose correctly between `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` based on how ties should be handled in a business context.
- Build running totals, moving averages, and period-over-period growth metrics (MoM, QoQ, YoY) used in real dashboards.
- Use `LAG()` / `LEAD()` to build comparison reports (previous transaction, next event, sequential gap analysis).
- Apply window functions to detect anomalies and outliers (e.g., fraud signals in banking data).
- Reason about the **performance implications** of partitioning, ordering, and frame clauses at scale.
- Answer window-function interview questions with business framing, not just syntax recall.

---

## 3. Skills Gained

| Skill Category | What You Will Practice |
|---|---|
| Analytics Engineering | Translating KPIs into window function queries |
| Data Engineering | Writing performant, partition-aware SQL over large tables |
| Business Analysis | Understanding what each metric means to a stakeholder |
| SQL Architecture | Structuring multi-CTE, multi-scenario analytical queries |
| Interview Readiness | Explaining tradeoffs, not just producing correct output |

---

## 4. Prerequisites

Before starting this module, you should already be comfortable with (Module 07):

- Ranking functions: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`
- Offset functions: `LAG()`, `LEAD()`
- Aggregate window functions: `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()` used with `OVER (...)`
- The `PARTITION BY` and `ORDER BY` clauses inside a window specification
- Basic frame clauses: `ROWS BETWEEN ... AND ...`
- Joins, CTEs, and subqueries

If any of these feel unfamiliar, revisit Module 07 before continuing — this module assumes fluency, not familiarity.

---

## 5. Folder Structure

```
08_WINDOW_FUNCTION_APPLICATIONS/
│
├── README.md                     ← You are here
│
├── 01_HR_ANALYTICS.md
├── 01_HR_ANALYTICS.sql
│
├── 02_SALES_ANALYTICS.md
├── 02_SALES_ANALYTICS.sql
│
├── 03_ECOMMERCE.md
├── 03_ECOMMERCE.sql
│
├── 04_BANKING.md
├── 04_BANKING.sql
│
└── 05_FINANCE.md
    05_FINANCE.sql
```

Each business domain ships as a **paired Markdown + SQL file**:

- The `.md` file explains the business context, KPIs, dashboards, and reasoning.
- The `.sql` file contains the fully commented, production-quality query chapter for that domain.

---

## 6. Business Domains Covered

| # | Domain | Core Business Questions |
|---|---|---|
| 01 | HR Analytics | Who are our top performers? Who's eligible for promotion? How is compensation distributed by department? |
| 02 | Sales Analytics | Who is our top salesperson this month? What's our revenue trend? How does this quarter compare to last year? |
| 03 | E-Commerce | Who are our highest-LTV customers? What's our repeat purchase rate? Which products dominate each category? |
| 04 | Banking | What are our largest transactions? Is this account behaving abnormally? What's the running balance over time? |
| 05 | Finance | Are we over budget? What's our running profit? How volatile is our expense variance month to month? |

---

## 7. Window Functions Used Across This Module

| Function | Primary Use Case in This Module |
|---|---|
| `ROW_NUMBER()` | Unique sequencing, deduplication, "top N per group" |
| `RANK()` | Leaderboards where ties should share a rank and skip subsequent ranks |
| `DENSE_RANK()` | Leaderboards where ties should share a rank without skipping |
| `NTILE()` | Percentile buckets (e.g., performance quartiles, customer tiers) |
| `LAG()` / `LEAD()` | Period-over-period comparisons, transaction gap analysis, sequential trend detection |
| `SUM() OVER (...)` | Running totals, running balances, cumulative revenue |
| `AVG() OVER (...)` | Moving averages, smoothed trend lines |
| `COUNT() OVER (...)` | Group-level counts without collapsing row-level detail |
| `FIRST_VALUE()` / `LAST_VALUE()` | Baseline comparisons (e.g., first transaction vs. most recent) |

---

## 8. Learning Path

Work through the domains in order — each one reinforces the previous while introducing a new analytical pattern:

1. **HR Analytics** — Foundational ranking, leaderboard, and comparison patterns.
2. **Sales Analytics** — Time-based patterns: running totals, MoM/YoY growth, moving averages.
3. **E-Commerce** — Customer-centric patterns: lifetime value, repeat behavior, basket analysis.
4. **Banking** — Sequential and anomaly patterns: running balances, transaction gaps, fraud signals.
5. **Finance** — Variance and budget patterns: running profit, budget-to-actual tracking.

Each `.sql` file is organized into **scenarios**, and each scenario contains a business explanation followed by progressively more advanced queries.

---

## 9. Estimated Completion Time

| Domain | Estimated Time |
|---|---|
| HR Analytics | 60–75 minutes |
| Sales Analytics | 75–90 minutes |
| E-Commerce | 75–90 minutes |
| Banking | 60–75 minutes |
| Finance | 60–75 minutes |
| **Total Module** | **~6–7 hours** |

---

## 10. Difficulty

**Intermediate → Advanced.**

This module assumes syntax fluency and focuses entirely on **application, judgment, and performance reasoning**. Difficulty increases within each file as scenarios move from single-partition ranking to multi-metric, multi-window analytical reports.

---

## 11. Best Practices Reinforced in This Module

- Always define an explicit `ORDER BY` inside `OVER (...)` when using ranking or offset functions — undefined order produces non-deterministic results.
- Prefer `ROW_NUMBER()` over `RANK()`/`DENSE_RANK()` when you need exactly one row per group (e.g., "top 1 per department"), since ties in `RANK()` can return more rows than expected.
- Be explicit about frame clauses (`ROWS BETWEEN ...`) when computing running totals or moving averages — the default frame can silently produce incorrect results when `ORDER BY` is present.
- Filter the output of a window function using a CTE or subquery — window functions cannot be referenced directly in a `WHERE` clause.
- Partition only on columns that reflect the actual business grouping — over-partitioning fragments the window and under-partitioning produces misleading aggregates.
- Index the columns used in `PARTITION BY` and `ORDER BY` where possible; window functions still benefit heavily from sort-friendly access paths.

---

## 12. Real-World Applications

Window functions in this module map directly to systems you will build or maintain on the job:

- **HR dashboards** showing department leaderboards and promotion eligibility lists.
- **Sales performance dashboards** used in weekly and monthly business reviews.
- **Customer analytics platforms** computing lifetime value and cohort retention.
- **Fraud detection pipelines** flagging transactions that deviate from a customer's own history.
- **Financial reporting systems** tracking budget variance and running profit for leadership review.

---

## 13. How This Module Prepares You

**For Data Analytics:**
You will be able to independently translate a stakeholder's question into a correct, efficient window function query — the single most common analytics interview and on-the-job task.

**For Data Engineering:**
You will understand the performance cost of partitioning and ordering at scale, which directly informs how you design tables, indexes, and materialized views that feed these queries.

**For Analytics Engineering:**
You will be able to build reusable, well-documented SQL models (dbt-style) where window functions form the core transformation logic for metrics layers.

**For SQL Interviews:**
You will be ready for the most commonly asked interview pattern across FAANG and mid-size tech companies: *"Write a query to find the top N per group,"* along with its many variations (running totals, YoY growth, gap analysis).

---

## 14. Further Reading

- PostgreSQL Documentation — Window Functions
- Use The Index, Luke — Window Functions and Performance
- "SQL for Data Analysis" (O'Reilly) — Chapters on window functions and cohort analysis
- Your database vendor's official execution plan documentation (to study how window functions are physically executed — sort, partition, and window aggregate nodes)

---

**Next:** [`01_HR_ANALYTICS.md`](./01_HR_ANALYTICS.md) — HR Analytics business context, followed by [`01_HR_ANALYTICS.sql`](./01_HR_ANALYTICS.sql), the fully engineered SQL chapter.
