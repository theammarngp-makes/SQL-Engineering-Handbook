# 02 — SQL Aggregations
 
> *Module 2 of the SQL Engineering Handbook*
> Turn raw rows into summaries, totals, and KPIs — the bridge between retrieving data and reporting on it.
 
[![Level](https://img.shields.io/badge/Level-Beginner%20%E2%86%92%20Intermediate-yellow)]()
[![Estimated Time](https://img.shields.io/badge/Time-2--3%20hrs-blue)]()
[![Topics](https://img.shields.io/badge/Topics-6-orange)]()
[![Status](https://img.shields.io/badge/Status-Complete-success)]()
 
---
 
## 📑 Table of Contents
 
- [Overview](#-overview)
- [Learning Goals](#-learning-goals)
- [Topics Covered](#-topics-covered)
- [Folder Structure](#-folder-structure)
- [Recommended Learning Order](#-recommended-learning-order)
- [How Aggregation Actually Works](how-aggregation-actually-works)
- [Skills Developed](#-skills-developed)
- [Business Applications](#-business-applications)
- [Best Practices](#-best-practices)
- [Prerequisites](#-prerequisites)
- [How to Use This Module](how-to-use-this-module)
- [Next Section](#-next-section)
---
 
## 🔎 Overview
 
This module covers *SQL aggregate functions* — the tools used to summarize, analyze, and report on data rather than just list it.
 
Where Module 1 taught you to retrieve and filter individual rows, this module teaches you to *collapse many rows into one meaningful number*: a total, an average, a count, a min/max — and to do that separately for each group in your data using GROUP BY and HAVING.
 
This is the module where SQL stops feeling like a filter and starts feeling like an analytics tool.
 
---
 
## 🎯 Learning Goals
 
After completing this section, you should be able to:
 
- [ ] Count records with COUNT()
- [ ] Calculate totals with SUM()
- [ ] Calculate averages with AVG()
- [ ] Find minimum and maximum values with MIN() and MAX()
- [ ] Group records into categories using GROUP BY
- [ ] Filter grouped results using HAVING
- [ ] Understand the difference between filtering rows (WHERE) and filtering groups (HAVING)
---
 
## 📖 Topics Covered
 
| No. | Topic | Description | Files |
|----|-------|--------------|-------|
| 01 | *COUNT()* | Count the number of rows or non-null values | [01_COUNT.md](./01_COUNT.md) · [01_COUNT.sql](./01_COUNT.sql) |
| 02 | *SUM()* | Calculate the total of a numeric column | [02_SUM.md](./02_SUM.md) · [02_SUM.sql](./02_SUM.sql) |
| 03 | *AVG()* | Calculate the average of a numeric column | [03_AVG.md](./03_AVG.md) · [03_AVG.sql](./03_AVG.sql) |
| 04 | *MIN() & MAX()* | Find the smallest and largest values | [04_MIN_MAX.md](./04_MIN_MAX.md) · [04_MIN_MAX.sql](./04_MIN_MAX.sql) |
| 05 | *GROUP BY* | Group rows that share a common value | [05_GROUP_BY.md](./05_GROUP_BY.md) · [05_GROUP_BY.sql](./05_GROUP_BY.sql) |
| 06 | *HAVING* | Filter groups after aggregation | [06_HAVING.md](./06_HAVING.md) · [06_HAVING.sql](./06_HAVING.sql) |
 
Each .md file explains the *concept, syntax, and reasoning, while the paired .sql file contains **runnable, annotated examples*.
 
---
 
## 📂 Folder Structure
 
```
02_Aggregations/
│
├── README.md
├── 01_COUNT.md
├── 01_COUNT.sql
├── 02_SUM.md
├── 02_SUM.sql
├── 03_AVG.md
├── 03_AVG.sql
├── 04_MIN_MAX.md
├── 04_MIN_MAX.sql
├── 05_GROUP_BY.md
├── 05_GROUP_BY.sql
├── 06_HAVING.md
└── 06_HAVING.sql
```
 
---
 
## 📌 Recommended Learning Order
 
Work through the single-value aggregates first, then layer on grouping:
 
```
1. COUNT()      → how many rows are there?
2. SUM()        → what's the total?
3. AVG()        → what's the typical value?
4. MIN() / MAX() → what are the extremes?
5. GROUP BY     → how do these answers change per category?
6. HAVING       → which of those categories actually matter?
```
 
---
 
## ⚙️ How Aggregation Actually Works
 
A query with GROUP BY is logically executed in this order — understanding this sequence is what separates people who memorize syntax from people who actually get SQL:
 

FROM       → which table(s) are we reading from?
WHERE      → filter individual rows BEFORE grouping
GROUP BY   → collapse rows into groups
HAVING     → filter groups AFTER aggregation
SELECT     → choose which columns/aggregates to return
ORDER BY   → sort the final result

 
> 🔑 *The single most important distinction in this module:*
> WHERE filters *rows* before they're grouped. HAVING filters *groups* after they're aggregated. You cannot use an aggregate function inside WHERE — that's what HAVING is for.
 
---
 
## 🧠 Skills Developed
 
Working through this module strengthens your ability to:
 
- Summarize large datasets into meaningful totals and averages
- Break down metrics by category, region, customer, or time period
- Distinguish between row-level filtering and group-level filtering
- Spot outliers and extremes using MIN() / MAX()
- Build the aggregation logic that powers most BI dashboards and reports
---
 
## 💼 Business Applications
 
| Use Case | Example Question Answered |
|---|---|
| *Workforce reporting* | How many employees are in each department? |
| *Revenue analysis* | What's our total and average revenue by month? |
| *Customer segmentation* | Which customers spend above a certain threshold? |
| *Sales reporting* | Which region had the highest and lowest sales? |
| *KPI dashboards* | What's our running count, sum, and average for this metric? |
 
---
 
## 💡 Best Practices
 
- ✅ Always pair GROUP BY with a clear understanding of what one row in your result represents
- ✅ Use HAVING only for conditions on aggregated values — use WHERE for everything else
- ✅ Be explicit about NULL handling — COUNT(*) and COUNT(column) behave differently
- ✅ Alias your aggregate columns (AS total_revenue, not SUM(amount)) for readable output
- ✅ Double-check that every non-aggregated column in SELECT also appears in GROUP BY
---
 
## 🎯 Prerequisites
 
Completion of *[01_Fundamentals](../01_Fundamentals)* — specifically SELECT, WHERE, and ORDER BY. This module builds directly on top of those concepts.
 
---
 
## 🛠️ How to Use This Module
 
1. Read the .md file for a topic to understand the concept and syntax.
2. Run the matching .sql file against a database of your choice (PostgreSQL, MySQL, or SQLite all work).
3. Modify the GROUP BY and HAVING clauses — change the grouping column or the threshold — and observe how the result set changes.
4. Try answering one of the business questions above using your own sample dataset before moving on.
> ⏱️ *Estimated time:* 2–3 hours for the lessons and examples, plus additional time for hands-on practice.
 
---
 
## 🚀 Next Section
 
Once you've completed this module, continue to:
 
➡️ *[03_Joins](../03_Joins)* — learn to combine data across multiple tables using INNER JOIN, LEFT JOIN, RIGHT JOIN, and FULL OUTER JOIN.
 
---
 
<p align="center">
  <i>Part of the <a href="../">SQL Engineering Handbook</a></i>
</p>- Customer segmentation
- Sales reporting
- KPI dashboards

---

## Difficulty

Beginner → Intermediate
