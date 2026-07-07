# Module 09 — Date Functions

> **Time is a first-class dimension in analytics.** Every report a company runs — revenue this month, tenure of an employee, SLA breaches on a shipment — is a question about *when*, not just *what*. This module teaches you to answer those questions the way production data teams do.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Why Dates Matter](#why-dates-matter)
3. [Learning Objectives](#learning-objectives)
4. [Skills You Will Build](#skills-you-will-build)
5. [Prerequisites](#prerequisites)
6. [Folder Structure](#folder-structure)
7. [Topics Covered](#topics-covered)
8. [Functions Covered](#functions-covered)
9. [Learning Roadmap](#learning-roadmap)
10. [Business Domains](#business-domains)
11. [Difficulty & Estimated Time](#difficulty--estimated-time)
12. [Business Applications](#business-applications)
13. [Real Dashboards This Module Powers](#real-dashboards-this-module-powers)
14. [Performance Tips](#performance-tips)
15. [Best Practices](#best-practices)
16. [Common Mistakes](#common-mistakes)
17. [Module Workflow](#module-workflow)
18. [Interview Preparation](#interview-preparation)
19. [Career Relevance](#career-relevance)
20. [Further Reading](#further-reading)
21. [Module Navigation](#module-navigation)

---

## Introduction

Every mature analytics organization runs on a calendar. Finance closes the books monthly. Sales reports quarterly. HR tracks tenure in days. Marketing measures campaign lift over a 7-day or 30-day window. None of this is possible without a working, production-grade command of SQL date and time functions.

This module — **09_Date_Functions** — is the point in the handbook where you stop writing queries that merely *filter* data and start writing queries that *reason about time*. You will learn not just the syntax of `DATEDIFF()` or `DATE_FORMAT()`, but the engineering judgment behind when to compute a date in SQL versus in the application layer, why storing derived date columns is sometimes the correct architectural choice, and how naive date logic silently corrupts dashboards in production.

By the end of this module, date logic will stop being something you look up and start being something you reason through.

---

## Why Dates Matter

Consider what breaks if date logic is wrong:

- A **"Last 30 Days"** dashboard filter that uses `> CURDATE() - 30` instead of `>= CURDATE() - INTERVAL 30 DAY` silently drops or includes an extra day, and nobody notices until finance reconciliation fails.
- An **employee tenure** calculation that ignores time zones reports employees as "hired tomorrow" in some regions.
- A **cohort retention** query that groups by `hire_date` instead of `DATE_TRUNC('month', hire_date)` produces one row per calendar day instead of one row per cohort month, making the report unusable.
- An **SLA breach** report using `DATEDIFF()` (which only counts whole days) instead of `TIMESTAMPDIFF(HOUR, ...)` masks late deliveries that occurred within the same calendar day.

Dates are deceptively simple and operationally dangerous. This module exists to close that gap before it costs you in production — or in an interview.

---

## Learning Objectives

By the end of this module, you will be able to:

- Retrieve and reason about the current date/time in a session-safe, timezone-aware way.
- Extract any component of a date (year, month, quarter, week, weekday) for grouping and filtering.
- Perform date arithmetic — additions, subtractions, and differences — using calendar-correct interval logic rather than fixed day-count approximations.
- Format dates for human-readable reporting and parse human-entered strings back into proper date types.
- Build the business-critical rolling and periodic windows (MTD, QTD, YTD, trailing 7/30/90 days) that power real dashboards.
- Calculate tenure, age, subscription duration, and delivery SLAs correctly, including edge cases like leap years and month-end overflow.
- Recognize and avoid the date-handling mistakes that most commonly break production reports and fail candidates in technical interviews.

---

## Skills You Will Build

| Skill | Description |
|---|---|
| Temporal filtering | Writing sargable, index-friendly `WHERE` clauses on date columns |
| Calendar arithmetic | Adding/subtracting intervals correctly across month and year boundaries |
| Period bucketing | Grouping transactional data into day/week/month/quarter/year buckets |
| Rolling window analysis | Trailing N-day and N-month metrics for trend reporting |
| Fiscal calendar handling | Adapting calendar-quarter logic to non-January fiscal years |
| Duration and tenure math | Computing precise, edge-case-safe durations between two timestamps |
| Cross-dialect fluency | Recognizing MySQL, PostgreSQL, and SQL Server equivalents for the same operation |

---

## Prerequisites

Before starting this module, you should be comfortable with:

- `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY` (Module 01–02)
- Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` (Module 03)
- `JOIN` types and multi-table queries (Module 04)
- `CASE` expressions (Module 05)
- Subqueries (Module 06)
- Common Table Expressions — `WITH` (Module 07)
- Window functions — `ROW_NUMBER()`, `RANK()`, `OVER()` (Module 08)

If any of these feel shaky, revisit the relevant module first. Date functions are frequently combined with window functions and CTEs in this module's later scenarios.

---

## Folder Structure

```
09_Date_Functions/
│
├── README.md                          ← You are here
│
├── 01_CURRENT_DATE_FUNCTIONS.md        Concept: retrieving "now" safely
├── 01_CURRENT_DATE_FUNCTIONS.sql       Practice: CURRENT_DATE, NOW(), session context
│
├── 02_DATE_EXTRACTION.md               Concept: decomposing a date into parts
├── 02_DATE_EXTRACTION.sql              Practice: YEAR, MONTH, QUARTER, WEEKDAY, etc.
│
├── 03_DATE_CALCULATIONS.md             Concept: arithmetic and differences
├── 03_DATE_CALCULATIONS.sql            Practice: DATE_ADD, DATE_SUB, DATEDIFF, TIMESTAMPDIFF
│
├── 04_DATE_FORMATTING.md               Concept: presentation and parsing
├── 04_DATE_FORMATTING.sql              Practice: DATE_FORMAT, STR_TO_DATE, CAST, CONVERT
│
├── 05_BUSINESS_DATE_ANALYTICS.md       Concept: real reporting patterns
└── 05_BUSINESS_DATE_ANALYTICS.sql      Practice: MTD/QTD/YTD, tenure, SLA, cohorts
```

Each numbered pair (`.md` + `.sql`) is self-contained: read the concept file first, then work through the paired SQL file scenario by scenario.

---

## Topics Covered

1. **Current Date & Time** — session-safe retrieval of "now," and the difference between date-only and timestamp values.
2. **Date Extraction** — pulling structured components (year, quarter, month, week, weekday, day-of-year) out of a date for grouping and segmentation.
3. **Date Calculations** — interval-based addition, subtraction, and differencing, including day-count vs. calendar-unit differences.
4. **Date Formatting** — converting between internal date types and human-facing or system-facing string representations.
5. **Business Date Analytics** — the composite patterns real companies build on top of the above: rolling windows, fiscal periods, tenure, SLA monitoring, and cohort foundations.

---

## Functions Covered

### Current Date / Time
`CURRENT_DATE` · `CURRENT_TIME` · `CURRENT_TIMESTAMP` · `NOW()` · `SYSDATE()` · `CURDATE()`

### Extraction
`YEAR()` · `MONTH()` · `DAY()` · `DAYNAME()` · `MONTHNAME()` · `QUARTER()` · `WEEK()` · `WEEKDAY()` · `DAYOFYEAR()` · `DAYOFWEEK()`

### Arithmetic
`DATE_ADD()` · `DATE_SUB()` · `DATEDIFF()` · `TIMESTAMPDIFF()` · `ADDDATE()` · `SUBDATE()`

### Formatting & Conversion
`DATE_FORMAT()` · `STR_TO_DATE()` · `CAST()` · `CONVERT()`

### Business & Composite Patterns
Rolling windows (trailing 7/30/90 days) · MTD · QTD · YTD · fiscal-period calculations · tenure/age/duration math · SLA delay measurement

> **Cross-dialect note:** This handbook is written and tested against **MySQL 8**. Wherever a function is MySQL-specific, the corresponding Markdown file includes a callout with the **PostgreSQL** and **SQL Server (T-SQL)** equivalent, since production teams rarely work in a single dialect for their entire career.

---

## Learning Roadmap

```
 01_CURRENT_DATE_FUNCTIONS
        │   "What is right now, and how do I ask for it safely?"
        ▼
 02_DATE_EXTRACTION
        │   "How do I break a date into reportable parts?"
        ▼
 03_DATE_CALCULATIONS
        │   "How do I move forward/backward in time and measure gaps?"
        ▼
 04_DATE_FORMATTING
        │   "How do I present dates to humans and parse dates from them?"
        ▼
 05_BUSINESS_DATE_ANALYTICS
        │   "How do real companies combine all of the above into reports?"
        ▼
   Module 10 →
```

Each file builds on the last. Extraction depends on knowing what "current date" even means in a session; calculations depend on extraction; formatting depends on calculations; and business analytics is the synthesis of all four.

---

## Business Domains

| Domain | Representative Problems in This Module |
|---|---|
| **HR** | Tenure calculation, promotion eligibility windows, attrition timing, hiring trend analysis, payroll period boundaries |
| **Sales** | Daily/weekly/monthly/quarterly revenue, moving averages, period-over-period growth |
| **Finance** | Budget periods, fiscal quarters, invoice due dates, accounting cycle boundaries |
| **E-commerce** | Delivery delay tracking, customer lifetime, repeat-purchase windows, order aging |
| **Banking** | Transaction aging, statement generation periods, interest accrual windows |
| **Healthcare** | Length of stay, appointment scheduling gaps, admission trend analysis |
| **Manufacturing** | Production schedule adherence, downtime duration, quality-check intervals |
| **Marketing** | Campaign window analysis, attribution lookback periods |

---

## Difficulty & Estimated Time

| File | Difficulty | Estimated Time |
|---|---|---|
| 01_CURRENT_DATE_FUNCTIONS | Beginner | 30–40 min |
| 02_DATE_EXTRACTION | Beginner–Intermediate | 45–60 min |
| 03_DATE_CALCULATIONS | Intermediate | 60–75 min |
| 04_DATE_FORMATTING | Intermediate | 45–60 min |
| 05_BUSINESS_DATE_ANALYTICS | Intermediate–Advanced | 90–120 min |
| **Module Total** | **Intermediate** | **~4.5–6 hours** |

---

## Business Applications

This module is the backbone of nearly every recurring business report:

- **Executive dashboards** — "Revenue this month vs. last month," "YTD performance vs. target"
- **HR systems** — "Who is eligible for their 1-year review this quarter?"
- **Operations** — "Which shipments breached their 48-hour SLA?"
- **Finance** — "What was collected this fiscal quarter vs. the prior fiscal quarter?"
- **Marketing** — "What was the 7-day rolling conversion rate during the campaign?"
- **Customer success** — "Which subscriptions renew in the next 30 days?"

---

## Real Dashboards This Module Powers

- A **monthly revenue trend chart** driven by `DATE_FORMAT(order_date, '%Y-%m')` grouping.
- An **employee tenure and attrition board** driven by `TIMESTAMPDIFF(MONTH, hire_date, COALESCE(termination_date, CURDATE()))`.
- An **SLA compliance panel** driven by `TIMESTAMPDIFF(HOUR, order_date, delivered_date)` against a threshold.
- A **rolling 30-day active users** widget driven by a trailing-window filter with a stable, sargable date boundary.
- A **cohort retention grid**, whose foundation (bucketing users by signup month) is introduced here and formalized in the Window Functions and Cohort Analysis modules.

---

## Performance Tips

- **Never wrap an indexed date column in a function inside `WHERE`.** `WHERE YEAR(order_date) = 2024` prevents index usage; prefer a sargable range: `WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'`.
- **Prefer half-open interval ranges** (`>= start AND < end`) over `BETWEEN` for date ranges — `BETWEEN` is inclusive on both ends and silently mishandles timestamp precision (e.g., excludes `23:59:59.500` on the end date).
- **Materialize a calendar/date dimension table** for high-volume reporting instead of computing fiscal periods or holiday flags inline on every query.
- **Avoid computing the same derived date expression multiple times** in one query — compute it once in a CTE and reference it downstream.
- **Be deliberate about `DATEDIFF()` vs. `TIMESTAMPDIFF()`.** `DATEDIFF()` truncates to whole calendar days and ignores time-of-day, which is usually wrong for SLA or duration reporting on timestamp columns.

---

## Best Practices

- Store dates and timestamps in proper native types (`DATE`, `DATETIME`, `TIMESTAMP`) — never as strings.
- Be explicit about time zones for any `TIMESTAMP` column in a distributed or multi-region system.
- Use `INTERVAL` arithmetic (`DATE_ADD(d, INTERVAL 1 MONTH)`) instead of naive day-count approximations (`d + 30`) — months are not a fixed number of days.
- Name derived date columns clearly: `order_month`, `fiscal_quarter`, `days_since_signup` — not `d1`, `x`, `tmp`.
- Document any assumption about fiscal year start, business-day-only logic, or timezone handling directly in the query as a comment.
- When a report will run daily against production, prefer computing the "as of" boundary once (e.g., in a CTE) so all downstream logic is consistent within a single execution.

---

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---|---|---|
| `WHERE order_date = '2024-05-01'` on a `DATETIME` column | Matches only exact midnight; silently drops same-day rows with a time component | Use a half-open range: `>= '2024-05-01' AND < '2024-05-02'` |
| `hire_date + 30` for "30 days later" | Works only if the dialect supports implicit day arithmetic; unclear and non-portable | `DATE_ADD(hire_date, INTERVAL 30 DAY)` |
| Using `DATEDIFF()` for hour-level SLA checks | `DATEDIFF()` only counts whole days, hiding same-day delays | `TIMESTAMPDIFF(HOUR, start, end)` |
| `YEAR(col) = 2024` in `WHERE` | Non-sargable — disables index usage on `col` | Range filter on the raw column |
| Assuming every month has 30 days | Breaks at month boundaries (28/29/30/31-day months) | Let `INTERVAL ... MONTH` arithmetic handle it |
| Ignoring time zones on `TIMESTAMP` columns | Produces off-by-one-day errors across regions | Normalize to UTC in storage; convert at the presentation layer |
| Confusing calendar quarter with fiscal quarter | Produces incorrect quarter labels for non-January fiscal years | Compute fiscal quarter explicitly relative to the fiscal year start |

---

## Module Workflow

1. Read `01_CURRENT_DATE_FUNCTIONS.md`, then work through `01_CURRENT_DATE_FUNCTIONS.sql` scenario by scenario.
2. Repeat for files `02` through `05`, in order — each file assumes mastery of the previous one.
3. For each SQL file, do not just read the solution — attempt the stated business question yourself before revealing it.
4. Complete the **Practice Challenges** at the end of every Markdown file before moving to the next numbered file.
5. After finishing `05_BUSINESS_DATE_ANALYTICS`, attempt to build one dashboard-style query from scratch using only the business scenario, without referencing the solutions.

---

## Interview Preparation

Date-function questions are a favorite in SQL technical screens because they reveal whether a candidate understands *edge cases*, not just syntax. Expect questions such as:

- "Find the number of active days for each user in the last 30 days."
- "Calculate each employee's tenure in full years and months."
- "Write a query to find the last day of the previous month."
- "Identify orders that breached a 48-hour delivery SLA."
- "Compute month-to-date revenue as of yesterday, correctly handling the first day of the month."
- "Explain why `WHERE YEAR(created_at) = 2023` is a performance anti-pattern."

Each Markdown file in this module includes a dedicated **Interview Questions** section addressing patterns like these in depth.

---

## Career Relevance

Date logic appears in essentially every analytics, data engineering, and backend engineering role:

- **Data Analysts** use it daily for recurring reporting cadences.
- **Data Engineers** use it to build calendar dimension tables and partition pipelines by date.
- **Backend Engineers** use it for SLA enforcement, subscription billing cycles, and session expiry logic.
- **Product Analysts** use it for retention, cohort, and engagement analysis.

Fluency here is one of the fastest ways to distinguish a candidate who has "learned SQL syntax" from one who has "engineered with SQL in production."

---

## Further Reading

- [MySQL 8.0 Reference Manual — Date and Time Functions](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html)
- [PostgreSQL Documentation — Date/Time Functions and Operators](https://www.postgresql.org/docs/current/functions-datetime.html)
- [Microsoft Learn — Date and Time Data Types and Functions (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql)
- [MySQL 8.0 Reference Manual — Date and Time Type Storage Requirements](https://dev.mysql.com/doc/refman/8.0/en/storage-requirements.html)

---

## Module Navigation

| Previous | Current | Next |
|---|---|---|
| [← Module 08:Window_Business_Cases](../08_Window_Business_Cases/README.md) | **Module 09: Date Functions** | [Module 10:String_Functions →](../10_String_Functions/README.md) |

---

*Part of the [SQL Engineering Handbook](../README.md) — a production-grade curriculum for engineering SQL the way real companies use it.*
