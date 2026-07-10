# Module 10 — String Functions

## Introduction

Text is the least structured data type SQL routinely has to work with, and the most error-prone. Names arrive mixed-case, addresses arrive with inconsistent whitespace, phone numbers arrive in a dozen formats, and product codes arrive concatenated when they should be split. This module is about writing SQL that turns that mess into something a report, a dashboard, or a downstream system can trust.

This module does not teach string function syntax as a list of definitions to memorize. It teaches the engineering judgment behind *when* a given transformation belongs in the query layer versus the application layer, what it costs in performance, and how it fails silently if you're not careful.

## Why String Functions Matter

Almost every production database has text columns that were never validated at the point of entry — free-text form fields, third-party imports, legacy migrations, manual data entry. String functions are the primary tool for:

- Making inconsistent data comparable (`UPPER`, `TRIM`, `REPLACE`)
- Deriving structured fields from unstructured ones (`SUBSTRING`, `LEFT`, `RIGHT`, `LOCATE`)
- Building human-readable output for reports and exports (`CONCAT`, `CONCAT_WS`, `LPAD`)
- Enforcing data quality rules before data reaches analytics or downstream systems

Get this wrong and you get double-counted customers, broken joins on "the same" value stored two different ways, and reports that silently drop rows because a `WHERE` clause assumed clean data that never existed.

## Learning Objectives

By the end of this module, you will be able to:

1. Select the correct string function for a given cleaning, extraction, or formatting task
2. Reason about the performance cost of string operations in `WHERE`, `JOIN`, and `GROUP BY` clauses
3. Identify when string logic belongs in SQL versus the application/ETL layer
4. Write string transformations that are correct on edge cases (NULLs, empty strings, multi-byte characters, leading/trailing whitespace)
5. Recognize and avoid the most common string-handling mistakes seen in code review

## Skills Gained

- Text cleaning and standardization for analytics-ready data
- Parsing and extracting structured values from unstructured text
- Building derived identifiers (usernames, SKUs, reference codes) from source columns
- Writing string-safe `WHERE` clauses that don't silently break on dirty data
- Diagnosing why a string comparison or join "should match but doesn't"

## Prerequisites

This module assumes completion of:

- `01-07` — SELECT, filtering, sorting, aggregation, joins, CASE, subqueries/CTEs
- `08_WINDOW_BUSINESS_CASES` — window functions applied to business problems
- `09_Date_Functions` — temporal data handling

String functions are typically combined with all of the above in production queries, so this module leans on that foundation rather than re-explaining it.

## Folder Structure

```
10_STRING_FUNCTIONS/
├── README.md
├── 01_BASIC_STRING_FUNCTIONS.md
├── 01_BASIC_STRING_FUNCTIONS.sql
├── 02_STRING_SEARCH_AND_EXTRACTION.md
├── 02_STRING_SEARCH_AND_EXTRACTION.sql
├── 03_STRING_TRANSFORMATION.md
├── 03_STRING_TRANSFORMATION.sql
├── 04_STRING_CLEANING_AND_VALIDATION.md
├── 04_STRING_CLEANING_AND_VALIDATION.sql
├── 05_BUSINESS_STRING_ANALYTICS.md
└── 05_BUSINESS_STRING_ANALYTICS.sql
```

## Topics Covered

| # | Topic | Focus |
|---|-------|-------|
| 01 | Basic String Functions | Case conversion, length, concatenation, slicing, trimming, positional search |
| 02 | String Search & Extraction | `LOCATE`, `POSITION`, `INSTR`, `LIKE`, `REGEXP`, `SUBSTRING_INDEX` |
| 03 | String Transformation | `REPLACE`, `REVERSE`, `REPEAT`, `LPAD`/`RPAD`, `INSERT` |
| 04 | String Cleaning & Validation | Whitespace handling, email/phone validation patterns, standardization rules |
| 05 | Business String Analytics | Applying 01–04 to end-to-end reporting and data-quality problems |

## String Functions Covered

`LENGTH()` · `CHAR_LENGTH()` · `LOWER()` · `UPPER()` · `TRIM()` · `LTRIM()` · `RTRIM()` · `CONCAT()` · `CONCAT_WS()` · `LEFT()` · `RIGHT()` · `SUBSTRING()` · `MID()` · `REPLACE()` · `REVERSE()` · `REPEAT()` · `SPACE()` · `INSERT()` · `LOCATE()` · `POSITION()` · `INSTR()` · `LIKE` · `REGEXP` · `SUBSTRING_INDEX()` · `LPAD()` · `RPAD()`

## Learning Workflow

1. Read the topic's Markdown file in full before opening the `.sql` file — the business context explains *why* the query is written the way it is.
2. Run each scenario's query against the sample schema and compare your output to the documented **Expected Output**.
3. Read the **Engineering Notes** and **Performance Notes** even if your query already produced the right result — correctness and production-readiness are different bars.
4. Attempt the **Practice Challenges** at the end of each Markdown file before moving to the next topic.

## Business Domains

This module draws examples from HR, Sales, Finance, E-Commerce, Banking, Healthcare, Manufacturing, and Logistics — reflecting that string cleaning is a horizontal skill, not one tied to a single industry vertical.

## Difficulty Level

Intermediate. Assumes comfort with joins and CTEs; introduces no new relational concepts, only a new function family and the judgment to apply it correctly.

## Estimated Completion Time

6–9 hours across all five sub-modules, including practice challenges.

## Production Applications

- ETL pipelines standardizing incoming data before it lands in a warehouse
- Customer Data Platforms deduplicating records with inconsistent formatting
- Reporting layers producing human-readable labels from normalized source data
- Data quality monitors flagging malformed emails, phone numbers, or codes

## Data Cleaning Pipeline

A typical production cleaning sequence, in order:

1. **Trim** — remove leading/trailing whitespace introduced by manual entry or CSV imports
2. **Case-normalize** — apply `UPPER`/`LOWER` consistently before comparison or joining
3. **Standardize** — collapse known formatting variants (e.g., phone separators) via `REPLACE`
4. **Validate** — apply pattern checks (`LIKE`/`REGEXP`) to flag records that fail business rules
5. **Extract/derive** — build downstream fields (usernames, initials, codes) only after the above steps guarantee clean input

Skipping step 1 or 2 is the single most common cause of "duplicate" customers or failed joins in production systems.

## Performance Tips

- Applying a function to a column in a `WHERE` clause (`WHERE UPPER(email) = 'X'`) typically prevents the query planner from using a standard index on that column. Prefer storing normalized data or using a functional/expression index if your database supports one.
- `LIKE '%value%'` (leading wildcard) cannot use a standard B-tree index and forces a full scan on large tables. Trailing-wildcard patterns (`'value%'`) can.
- String concatenation inside a `JOIN` condition should be avoided where possible — join on raw keys and format for display afterward.
- `REGEXP` is powerful but generally more expensive than `LIKE` or `LOCATE` for simple pattern checks; reserve it for genuinely variable patterns.

## Best Practices

- Normalize once, upstream, rather than repeating the same `TRIM(UPPER(...))` in every query that touches a column.
- Always account for `NULL` in string logic — most string functions return `NULL` if any input is `NULL`, which silently drops rows from concatenated output.
- Prefer `CONCAT_WS()` over `CONCAT()` with manual separators — it skips `NULL` values gracefully and reduces separator bugs.
- Document any business rule embedded in a string transformation (e.g., "usernames are first 3 letters + employee ID") directly in the query as a comment — these rules are rarely obvious from the SQL alone.

## Common Mistakes

- Assuming `LENGTH()` and `CHAR_LENGTH()` are interchangeable — they diverge on multi-byte (e.g., UTF-8) characters.
- Forgetting that `CONCAT('a', NULL, 'b')` returns `NULL` in most engines, not `'ab'`.
- Using `SUBSTRING`/`LEFT`/`RIGHT` with hard-coded positions on data whose format isn't guaranteed to be fixed-width.
- Comparing strings without normalizing case or whitespace, then blaming the join or filter logic instead of the data.

## Interview Preparation

Interviewers commonly test string functions through data-cleaning scenarios rather than syntax recall: parsing a full name into first/last, extracting a domain from an email, formatting a phone number, or identifying malformed records with `LIKE`/`REGEXP`. Each topic file in this module ends with an **Interview Questions** section modeled on exactly these patterns.

## Career Relevance

String cleaning is one of the most frequently performed tasks by Data Analysts, Analytics Engineers, and BI Engineers — often described informally as "the 80% of the job that isn't modeling." Fluency here signals production readiness to interviewers far more reliably than advanced window function tricks.

## Module Summary

String functions convert unreliable text into analyzable, joinable, reportable data. This module builds that skill through five progressively layered topics, each grounded in realistic business scenarios rather than isolated syntax demonstrations.

## Further Reading

- [PostgreSQL String Functions and Operators](https://www.postgresql.org/docs/current/functions-string.html)
- [MySQL String Functions Reference](https://dev.mysql.com/doc/refman/8.0/en/string-functions.html)
- [Microsoft Learn — String Functions (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-functions-transact-sql)

## Previous Module

[`09_Date_Functions`](../09_Date_Functions/README.md)

## Next Module

Module 11 — planned (pattern matching and regular expressions deep-dive)
