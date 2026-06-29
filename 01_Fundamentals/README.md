# 01 — SQL Fundamentals

> **Module 1 of the SQL Engineering Handbook**
> The foundation every advanced SQL concept — aggregations, joins, subqueries, window functions, and CTEs — is built on top of.

[![Level](https://img.shields.io/badge/Level-Beginner-brightgreen)]()
[![Estimated Time](https://img.shields.io/badge/Time-2--3%20hrs-blue)]()
[![Topics](https://img.shields.io/badge/Topics-5-orange)]()
[![Status](https://img.shields.io/badge/Status-Complete-success)]()

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Learning Objectives](#-learning-objectives)
- [Topics Covered](#-topics-covered)
- [Folder Structure](#-folder-structure)
- [Recommended Learning Order](#-recommended-learning-order)
- [Skills Developed](#-skills-developed)
- [Real-World Applications](#-real-world-applications)
- [Best Practices](#-best-practices)
- [Prerequisites](#-prerequisites)
- [How to Use This Module](#-how-to-use-this-module)
- [Next Section](#-next-section)

---

## 🔎 Overview

This module introduces the **core SQL statements** used to retrieve, filter, sort, and organize data — the four operations that underpin nearly every query you will ever write:

```
SELECT → WHERE → ORDER BY → LIMIT
```

Every advanced topic in this handbook — aggregations, joins, subqueries, window functions, and CTEs — is a layer built on top of these fundamentals. Mastering this module first means every subsequent module will click faster.

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

- [ ] Retrieve data from one or more tables using `SELECT`
- [ ] Filter records efficiently using `WHERE`
- [ ] Sort query results with `ORDER BY`
- [ ] Limit returned rows using `LIMIT`
- [ ] Improve query readability with column and table aliases (`AS`)
- [ ] Understand how a SQL query is logically executed step by step
- [ ] Write clean, readable, and maintainable SQL

---

## 📖 Topics Covered

| No. | Topic | Description | Files |
|----|-------|--------------|-------|
| 01 | **SELECT** | Retrieve columns and records from a table | [`01_SELECT.md`](./01_SELECT.md) · [`01_SELECT.sql`](./01_SELECT.sql) |
| 02 | **WHERE** | Filter rows using logical conditions | [`02_WHERE.md`](./02_WHERE.md) · [`02_WHERE.sql`](./02_WHERE.sql) |
| 03 | **ORDER BY** | Sort results in ascending or descending order | [`03_ORDER_BY.md`](./03_ORDER_BY.md) · [`03_ORDER_BY.sql`](./03_ORDER_BY.sql) |
| 04 | **LIMIT** | Return only the required number of rows | [`04_LIMIT.md`](./04_LIMIT.md) · [`04_LIMIT.sql`](./04_LIMIT.sql) |
| 05 | **ALIAS** | Improve query readability using temporary names | [`05_ALIAS.md`](./05_ALIAS.md) · [`05_ALIAS.sql`](./05_ALIAS.sql) |

Each `.md` file explains the **concept, syntax, and reasoning**, while the paired `.sql` file contains **runnable, annotated examples**.

---

## 📂 Folder Structure

```
01_Fundamentals/
│
├── README.md
├── 01_SELECT.md
├── 01_SELECT.sql
├── 02_WHERE.md
├── 02_WHERE.sql
├── 03_ORDER_BY.md
├── 03_ORDER_BY.sql
├── 04_LIMIT.md
├── 04_LIMIT.sql
├── 05_ALIAS.md
└── 05_ALIAS.sql
```

---

## 📌 Recommended Learning Order

Each topic builds on the one before it — work through them in sequence rather than jumping around:

```
1. SELECT     → what data can I see?
2. WHERE      → which rows matter?
3. ORDER BY   → in what order should I see them?
4. LIMIT      → how many do I actually need?
5. ALIAS      → how do I make this readable?
```

---

## 🧠 Skills Developed

Working through this module strengthens your ability to:

- Read and understand relational datasets
- Write syntactically correct, logically sound SQL queries
- Improve query readability through consistent formatting and aliasing
- Apply filtering and sorting techniques to answer real business questions
- Build a solid foundation for joins, aggregations, and advanced querying

---

## 💼 Real-World Applications

These fundamentals are used daily by:

`Data Analysts` · `Business Analysts` · `Analytics Engineers` · `Data Engineers` · `Backend Developers` · `Database Administrators`

**Typical use cases:**
- Retrieving customer records
- Filtering sales transactions
- Finding top-performing products
- Exploring and profiling new datasets
- Powering reports and dashboards

---

## 💡 Best Practices

> A query that *works* isn't the same as a query that's *good*. As you go through this module, hold yourself to these standards:

- ✅ Always format SQL for readability (consistent casing, indentation, line breaks)
- ✅ Use meaningful, descriptive aliases — not `a`, `b`, `t1`
- ✅ Avoid `SELECT *` in production queries — select only what you need
- ✅ Write queries that answer a **business question**, not just demonstrate syntax
- ✅ Understand *why* a query works — not just *that* it returns a result

---

## 🎯 Prerequisites

**None.** This module is designed for complete beginners and serves as the entry point to the SQL Engineering Handbook.

---

## 🛠 How to Use This Module

1. Read the `.md` file for a topic to understand the concept and syntax.
2. Open the matching `.sql` file and run the examples against a database of your choice (PostgreSQL, MySQL, or SQLite all work).
3. Modify the queries — change conditions, columns, and sort orders — to see how behavior changes.
4. Move to the next topic only once you're comfortable explaining the current one out loud.

> ⏱ **Estimated time:** 2–3 hours for the lessons and examples, plus additional time for hands-on practice.

---

## 🚀 Next Section

Once you've completed this module, continue to:

➡️ **[`02_Aggregations`](../02_Aggregations)** — learn to summarize, group, and analyze data using `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`, `GROUP BY`, and `HAVING`.

---

<p align="center">
  <i>Part of the <a href="../">SQL Engineering Handbook</a></i>
</p>
