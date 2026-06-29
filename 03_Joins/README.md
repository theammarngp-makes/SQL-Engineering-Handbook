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
