# 03 — SQL Joins

> **Module 3 of the SQL Engineering Handbook**
> Real-world data never lives in one table. This module teaches you to connect it.

[![Level](https://img.shields.io/badge/Level-Beginner%20%E2%86%92%20Intermediate-yellow)]()
[![Estimated Time](https://img.shields.io/badge/Time-3--4%20hrs-blue)]()
[![Topics](https://img.shields.io/badge/Topics-5-orange)]()
[![Interview Critical](https://img.shields.io/badge/Interview-Critical-red)]()
[![Status](https://img.shields.io/badge/Status-Complete-success)]()

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Topics Covered](#-topics-covered)
- [Folder Structure](#-folder-structure)
- [Recommended Learning Order](#-recommended-learning-order)
- [Schema Used](#-schema-used)
- [How Joins Actually Work](how-joins-actually-work)
- [Skills Developed](#-skills-developed)
- [Business Applications](#-business-applications)
- [Interview Importance](#-interview-importance)
- [Best Practices](#-best-practices)
- [Prerequisites](#-prerequisites)
- [How to Use This Module](#-how-to-use-this-module)
- [Next Section](#-next-section)

---

## 🔎 Overview

SQL **joins** are used to combine data from multiple tables using a related column.

In real-world systems, data is normalized and spread across many tables — employees in one table, departments in another, locations in a third. Joins are what let you reconnect that data and ask questions that span across it, like *"which employees work in which locations, under which managers?"*

This is the module where SQL stops being about *one table* and starts being about *your entire database*.

---

## 📖 Topics Covered

### Beginner

| No. | Topic | Description | Files |
|----|-------|--------------|-------|
| 01 | **INNER JOIN** | Return only matching rows from both tables | [`01_INNER_JOIN.md`](./01_INNER_JOIN.md) · [`01_INNER_JOIN.sql`](./01_INNER_JOIN.sql) |
| 02 | **LEFT JOIN** | Return all rows from the left table, matched or not | [`02_LEFT_JOIN.md`](./02_LEFT_JOIN.md) · [`02_LEFT_JOIN.sql`](./02_LEFT_JOIN.sql) |
| 03 | **RIGHT JOIN** | Return all rows from the right table, matched or not | [`03_RIGHT_JOIN.md`](./03_RIGHT_JOIN.md) · [`03_RIGHT_JOIN.sql`](./03_RIGHT_JOIN.sql) |

### Intermediate

| No. | Topic | Description | Files |
|----|-------|--------------|-------|
| 04 | **SELF JOIN** | Join a table to itself — used for hierarchies | [`04_SELF_JOIN.md`](./04_SELF_JOIN.md) · [`04_SELF_JOIN.sql`](./04_SELF_JOIN.sql) |
| 05 | **MULTI-TABLE JOIN** ⭐ | Chain multiple joins across 3+ tables in one query | [`05_MULTI_TABLE_JOIN.md`](./05_MULTI_TABLE_JOIN.md) · [`05_MULTI_TABLE_JOIN.sql`](./05_MULTI_TABLE_JOIN.sql) |

Each `.md` file explains the **concept, syntax, and reasoning**, while the paired `.sql` file contains **runnable, annotated examples**.

---

## 📂 Folder Structure

```
03_Joins/
│
├── README.md
├── 01_INNER_JOIN.md
├── 01_INNER_JOIN.sql
├── 02_LEFT_JOIN.md
├── 02_LEFT_JOIN.sql
├── 03_RIGHT_JOIN.md
├── 03_RIGHT_JOIN.sql
├── 04_SELF_JOIN.md
├── 04_SELF_JOIN.sql
├── 05_MULTI_TABLE_JOIN.md
└── 05_MULTI_TABLE_JOIN.sql
```

---

## 📌 Recommended Learning Order

```
1. INNER JOIN        → only the rows that match in both tables
2. LEFT JOIN          → everything on the left, matched or not
3. RIGHT JOIN         → everything on the right, matched or not
4. SELF JOIN          → a table joined to itself (hierarchies)
5. MULTI-TABLE JOIN   → chaining everything above across 3+ tables
```

> 💡 `FULL OUTER JOIN` is intentionally introduced *after* you're comfortable with `LEFT` and `RIGHT` — it's easiest to understand as "both of those, combined."

---

## 🗂 Schema Used

This module uses a single connected schema throughout, so every join example builds on the same data:

```
employees
    │
    ▼  (department_id)
departments
    │
    ▼  (location_id)
locations
```

- `employees` → linked to `departments` via `department_id`
- `departments` → linked to `locations` via `location_id`
- `employees.manager_id` → links back to `employees.employee_id` (used in `04_SELF_JOIN`)

Keeping one schema across all five topics means you're learning *join logic*, not re-learning a new dataset every lesson.

---

## ⚙️ How Joins Actually Work

Every join answers the same underlying question: **for each row in table A, what row(s) in table B share a matching value?**

| Join Type | Keeps unmatched rows from... |
|---|---|
| `INNER JOIN` | Neither table — only matches survive |
| `LEFT JOIN` | The left table |
| `RIGHT JOIN` | The right table |
| `SELF JOIN` | N/A — same table joined to itself, typically as a `LEFT JOIN` |
| Multi-table | Depends on which join type chains each pair |

> 🔑 **Key mental model:** unmatched rows from the "kept" side appear with `NULL` in every column that comes from the other table. This is the #1 source of confusion when debugging join results — always check what `NULL` is telling you.

---

## 🧠 Skills Developed

Working through this module strengthens your ability to:

- Combine tables based on relationships, not just structure
- Understand foreign keys and how they connect normalized tables
- Reason about matched vs. unmatched rows in a result set
- Query across 3+ tables in a single, readable statement
- Analyze hierarchical data (e.g. employee → manager) using self joins

---

## 💼 Business Applications

| Use Case | Example Question Answered |
|---|---|
| **Employee reporting** | Which department and location does each employee belong to? |
| **Department analysis** | How many employees and what total budget per department? |
| **Workforce planning** | Where are our people concentrated geographically? |
| **Location-based analytics** | Which locations are understaffed or overstaffed? |
| **Manager hierarchy analysis** | Who reports to whom, and how deep does the chain go? |

---

## 🎤 Interview Importance

> Joins are among the **most frequently asked SQL interview topics** — and one of the easiest places to lose credibility if your fundamentals are shaky.

A strong, intuitive grasp of joins (especially the `INNER` vs `LEFT` distinction and writing clean multi-table queries) is considered essential for:

- Data Analyst roles
- Data Scientist roles
- Analytics Engineer roles
- Any technical SQL screening round

Interviewers frequently test this by asking you to **predict row counts** before and after a join, or to spot what's wrong with a query that's silently dropping rows.

---

## 💡 Best Practices

- ✅ Always know *which table* you expect to lose rows from before writing `LEFT`/`RIGHT` — don't guess
- ✅ Use table aliases for every join (`e.employee_id`, not just `employee_id`) to avoid ambiguity
- ✅ Join on indexed, well-typed foreign keys — never join on unindexed text columns if you can avoid it
- ✅ When chaining multiple joins, build and test them one join at a time, not all five at once
- ✅ Watch row counts after each join — an unexpected increase usually means a one-to-many relationship you didn't account for

---

## 🎯 Prerequisites

Completion of **[`01_Fundamentals`](../01_Fundamentals)** and **[`02_Aggregations`](../02_Aggregations)**. You'll frequently combine joins with `GROUP BY` and aggregate functions in this module's examples.

---

## 🛠 How to Use This Module

1. Read the `.md` file for a topic to understand the concept, the schema relationship, and the syntax.
2. Run the matching `.sql` file and note the row count of the result.
3. Change `INNER JOIN` to `LEFT JOIN` (or vice versa) in the same query and compare row counts — this is the fastest way to internalize the difference.
4. For `05_MULTI_TABLE_JOIN`, build the query incrementally: join two tables, confirm the result, then add the third.

> ⏱ **Estimated time:** 3–4 hours for the lessons and examples, plus additional time for hands-on practice.

---

## 🚀 Next Section

Once you've completed this module, continue to:

➡️ **[`04_Subqueries`](../04_Subqueries)** — learn to nest queries inside other queries to answer multi-step business questions.

---

<p align="center">
  <i>Part of the <a href="../">SQL Engineering Handbook</a></i>
</p>
