# Module 11 — NULL Handling and Data Cleaning

## Module Introduction

Every analytics pipeline eventually collides with the same problem: the data is not clean. Customers leave fields blank. Systems migrate and drop values. Integrations write empty strings instead of nulls. Sales reps skip optional form fields. By the time data reaches an analyst, it is never as tidy as the schema diagram suggests.

This module teaches you how to reason about missing, inconsistent, and invalid data the way a production analytics engineer does — not as an annoyance to work around, but as a first-class part of the job. You will learn how SQL represents "unknown," how that representation propagates silently through calculations, and how to build queries and pipelines that catch data quality problems before they reach a dashboard or an executive report.

By the end of this module, NULL will stop being a mysterious edge case and start being a tool you control deliberately.

## Why Data Quality Matters

A query can be syntactically perfect and still produce a wrong answer if the underlying data is dirty. A `SUM()` that silently ignores NULLs, a `COUNT(*)` that overstates completeness, a customer name stored three different ways (`"john smith"`, `"John Smith "`, `"JOHN  SMITH"`) that fragments a single customer into three rows in a GROUP BY — these are not rare occurrences. They are the default state of real-world data.

Companies do not lose money because their SQL syntax is wrong. They lose money because a report built on unvalidated data told leadership something that wasn't true. Data quality is not a QA afterthought — it is a prerequisite for trustworthy analytics, and it is one of the most common things analytics engineers are actually hired to fix.

## Learning Objectives

By completing this module, you will be able to:

- Explain what NULL represents in SQL and why it behaves differently from zero, empty string, or "unknown" as a literal value
- Use `IS NULL` / `IS NOT NULL` correctly, and explain why `= NULL` never works
- Apply `COALESCE()`, `IFNULL()`, and `NULLIF()` to handle missing and invalid values with correct business logic
- Predict how NULLs affect `COUNT()`, `SUM()`, `AVG()`, and other aggregates
- Standardize inconsistent text data using `TRIM()`, `REPLACE()`, `UPPER()`, `LOWER()`, and related functions
- Detect and handle duplicate records
- Write validation queries that catch incomplete records, invalid dates, negative values, and other data quality violations before they reach downstream reporting
- Design a repeatable data cleaning workflow suitable for an ETL/ELT pipeline

## Skills You'll Gain

- NULL-safe query design
- Data validation and profiling
- Text standardization for customer-facing data
- Duplicate detection strategies
- Building data quality checks as a first step in any analytics workflow
- Communicating data quality issues in business terms

## Prerequisites

This module assumes you are already comfortable with:

- `SELECT`, filtering, and sorting
- Aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`)
- Joins
- `CASE` expressions
- Subqueries and CTEs
- Window functions
- Date and string functions

If any of those feel shaky, revisit the earlier modules before continuing — NULL handling assumes fluency with the fundamentals, since it touches nearly every clause in SQL.

## Folder Structure

```
11_NULL_HANDLING_AND_DATA_CLEANING/
│
├── README.md
│
├── 01_INTRODUCTION_TO_NULLS.md
├── 01_INTRODUCTION_TO_NULLS.sql
│
├── 02_NULL_HANDLING_FUNCTIONS.md
├── 02_NULL_HANDLING_FUNCTIONS.sql
│
├── 03_DATA_STANDARDIZATION.md
├── 03_DATA_STANDARDIZATION.sql
│
├── 04_DATA_CLEANING_TECHNIQUES.md
├── 04_DATA_CLEANING_TECHNIQUES.sql
│
├── 05_BUSINESS_DATA_QUALITY_CASE_STUDIES.md
├── 05_BUSINESS_DATA_QUALITY_CASE_STUDIES.sql
│
├── 06_DATA_VALIDATION_CHECKS.md
├── 06_DATA_VALIDATION_CHECKS.sql
│
├── 07_PRODUCTION_DATA_CLEANING_PROJECT.md
└── 07_PRODUCTION_DATA_CLEANING_PROJECT.sql
```

## Topics Covered

- NULL semantics and three-valued logic
- `IS NULL` / `IS NOT NULL`
- `COALESCE()`, `IFNULL()`, `NULLIF()`
- `CASE` expressions involving NULL
- NULL behavior inside `COUNT()`, `SUM()`, `AVG()`
- Blank string vs. NULL vs. whitespace-only string
- Text standardization: names, cities, emails
- Duplicate detection and removal
- Data validation: missing foreign keys, invalid dates, negative values, impossible ages
- Building a full data cleaning pipeline

## SQL Functions Covered

| Category | Functions |
|---|---|
| Null checks | `IS NULL`, `IS NOT NULL` |
| Null substitution | `COALESCE()`, `IFNULL()`, `NULLIF()` |
| Text cleaning | `TRIM()`, `LTRIM()`, `RTRIM()`, `REPLACE()` |
| Text casing | `UPPER()`, `LOWER()`, `INITCAP()` (Postgres) |
| Conditional logic | `CASE WHEN` |
| Aggregation | `COUNT()`, `SUM()`, `AVG()` (NULL-aware behavior) |

## Learning Roadmap

1. **Start with concepts** — read `01_INTRODUCTION_TO_NULLS.md` to build a correct mental model before writing any query.
2. **Practice the core toolkit** — `02_NULL_HANDLING_FUNCTIONS` covers COALESCE, IFNULL, and NULLIF in depth, including where each one is the *wrong* choice.
3. **Move to text data** — `03_DATA_STANDARDIZATION` applies these ideas to the messiest data type: free-text customer input.
4. **Combine techniques** — `04_DATA_CLEANING_TECHNIQUES` and `05_BUSINESS_DATA_QUALITY_CASE_STUDIES` put everything together against realistic business scenarios.
5. **Think like a data quality engineer** — `06_DATA_VALIDATION_CHECKS` teaches you to write queries whose entire purpose is finding problems, not answering business questions.
6. **Ship a pipeline** — `07_PRODUCTION_DATA_CLEANING_PROJECT` is a capstone: a realistic, end-to-end cleaning workflow on a multi-table dataset.

## Business Applications

- **Retail/E-commerce**: reconciling customer records across online and in-store systems where fields are optional
- **Finance**: ensuring transaction amounts are never silently excluded from totals due to NULL
- **HR**: validating employee records for missing managers, invalid hire dates, or duplicate employee IDs
- **Healthcare**: flagging incomplete patient records before they reach compliance reporting
- **SaaS**: standardizing customer emails and company names for accurate account-level rollups
- **Marketing**: deduplicating leads captured from multiple campaign sources

## Production Use Cases

- Pre-load validation checks in an ETL/ELT pipeline (reject or quarantine bad rows before they hit the warehouse)
- Data quality dashboards that track completeness and validity over time
- Master data management: deciding a single canonical representation of a customer, product, or account
- Incremental load reconciliation: detecting duplicate inserts after a failed pipeline retry

## Analytics Engineering Perspective

In a modern analytics stack, data cleaning is not a one-time cleanup script — it is a layer. Raw data lands in a `staging` layer untouched; standardization and validation happen in an intermediate layer; only clean, tested data reaches the layer business users query. The patterns in this module are the SQL-level building blocks of that intermediate layer, regardless of whether your stack uses dbt, stored procedures, or plain scheduled SQL.

## Common Data Quality Problems

- Missing values represented three different ways: `NULL`, `''`, and `'N/A'` — often in the same column
- Leading/trailing whitespace that breaks joins and GROUP BY
- Inconsistent casing fragmenting what should be one group
- Duplicate records from repeated imports or failed idempotency checks
- Foreign keys pointing to deleted or never-created parent records
- Dates stored as strings with inconsistent formats
- Negative values in columns that should never be negative (quantities, prices, ages)

## Best Practices

- Never assume a NULL check with `=` will work — always use `IS NULL` / `IS NOT NULL`
- Choose COALESCE over IFNULL when portability across database engines matters
- Validate data quality assumptions before aggregating — check completeness first, then compute
- Standardize text at the earliest layer possible so it doesn't need to be repeated in every downstream query
- Treat data validation queries as part of the codebase, not a one-off task — version and re-run them

## Common Mistakes

- Using `column = NULL` instead of `column IS NULL`
- Assuming `COUNT(*)` and `COUNT(column)` return the same result
- Forgetting that `AVG()` and `SUM()` ignore NULLs rather than treating them as zero
- Using `TRIM()` and assuming it removes internal whitespace (it only removes leading/trailing)
- Deduplicating with `DISTINCT` across the wrong column set, silently keeping unwanted duplicates

## Performance Notes

- `IS NULL` / `IS NOT NULL` can use indexes in most modern engines, but behavior varies (MySQL indexes NULLs; some engines don't) — always verify with `EXPLAIN`
- Wrapping an indexed column in `COALESCE()` in a `WHERE` clause typically prevents index usage — filter on the raw column when possible
- Validation queries that scan full tables should be scheduled thoughtfully in production, not run ad hoc against large fact tables during peak load

## Interview Preparation

Expect questions like:

- "What's the difference between COALESCE and IFNULL?"
- "Why does `COUNT(*)` differ from `COUNT(column_name)`?"
- "How would you find duplicate customer records with slightly different formatting?"
- "Write a query to flag orders with missing or invalid data before they're loaded into the warehouse."

This module is designed so that after completing it, these questions become straightforward rather than something to memorize answers for.

## Career Relevance

Data quality work is unglamorous and extremely in-demand. Analytics Engineer and Data Analyst job postings routinely list "data validation," "data cleaning," and "ensuring data quality" as core responsibilities — not nice-to-haves. Demonstrating fluency here, especially in a portfolio project, signals production readiness in a way that a polished dashboard alone does not.

## Summary

NULL handling and data cleaning sit at the intersection of SQL syntax and engineering judgment. The functions themselves — COALESCE, IFNULL, NULLIF, TRIM, REPLACE — are simple. The skill is knowing which one applies to which business situation, and building the habit of validating data before trusting it.

## Further Reading

- [PostgreSQL: The Nature of NULL Values](https://www.postgresql.org/docs/current/functions-comparison.html)
- [MySQL: Working with NULL Values](https://dev.mysql.com/doc/refman/8.0/en/working-with-null.html)
- [MySQL String Functions Reference](https://dev.mysql.com/doc/refman/8.0/en/string-functions.html)

## Previous Module

[Module 10 — Date and String Functions](../10_DATE_AND_STRING_FUNCTIONS/README.md)

## Next Module

[Module 12 — Data Aggregation and Reporting Patterns](../12_DATA_AGGREGATION_AND_REPORTING_PATTERNS/README.md)
