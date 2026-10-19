<p align="center">
  <img src="assets/banners/readme-banner.png" alt="SQL Engineering Handbook Banner" width="100%">
</p>

<h1 align="center">SQL Engineering Handbook</h1>

<p align="center">
  <b>A production-style curriculum in structure and examples — progressive modules from fundamentals to analytics engineering, interview prep, and real-world scenarios. See each module README for current verification status and execution notes.</b>
</p>

<p align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Poppins&size=22&duration=3000&pause=1000&center=true&vCenter=true&width=850&lines=21+Structured+SQL+Modules;Real+Datasets+%2B+Projects+%2B+[...]">
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/theammarngp-makes/SQL-Engineering-Handbook?style=for-the-badge&color=2563eb" />
  <img src="https://img.shields.io/github/forks/theammarngp-makes/SQL-Engineering-Handbook?style=for-the-badge&color=2563eb" />
  <img src="https://img.shields.io/github/last-commit/theammarngp-makes/SQL-Engineering-Handbook?style=for-the-badge&color=0f172a" />
  <img src="https://img.shields.io/badge/status-actively--building-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

<p align="center">
  <a href="#who-this-is-for">Who It's For</a> ·
  <a href="#what-makes-it-different">Why Different</a> ·
  <a href="#learning-roadmap">Roadmap</a> ·
  <a href="#repository-structure">Structure</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#documentation-hub">Docs</a> ·
  <a href="#contributing">Contributing</a> ·
  <a href="#faq">FAQ</a>
</p>

---

## 🌐 Live Link : https://theammarngp-makes.github.io/SQL-Engineering-Handbook

---
## Who This Is For

If you're an aspiring or practicing **Data Analyst** or **Analytics Engineer** who wants a structured path from SQL fundamentals to real business analytics — not another disconnected list of `.s[...]`

---
## 🗂️ Module Guide

This is the part most handbooks . Every module below links straight to its folder and tells you exactly what's inside before you click.

| # | Module | Contents | Status |
|---|--------|----------|--------|
|    | [Resources](Resources/) | All Learning resources including Certifications and hands-on-experience | ✅ |
| 00 | [Schema](00_Schema/) | Practice database DDL, seed data, and ERD used by every later module | ✅ |
| 01 | [Fundamentals](01_Fundamentals/) | `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`, aliasing | ✅ |
| 02 | [Aggregations](02_Aggregations/) | `COUNT`, `SUM`, `AVG`, `MIN`/`MAX`, `GROUP BY`, `HAVING` | ✅ |
| 03 | [Joins](03_Joins/) | Inner, left, right, full, cross, self joins + performance audit | ✅ |
| 04 | [Subqueries](04_Subqueries/) | Scalar, correlated, `EXISTS`, derived tables, subquery-to-join rewrites | ✅ |
| 05 | [CASE WHEN](05_CASE_WHEN/) | Conditional logic and business-rule encoding | ✅ |
| 06 | [CTEs](06_CTEs/) | Common Table Expressions, recursive CTEs | ✅ |
| 07 | [Window Functions](07_Window_Functions/) | `ROW_NUMBER`, `RANK`, `LAG`/`LEAD`, `PARTITION BY` | ✅ |
| 08 | [Window Business Cases](08_WINDOW_BUSINESS_CASES/) | Applied window-function scenarios (running totals, cohorts, rankings) | ✅ |
| 09 | [Date Functions](09_Date_Functions/) | Date arithmetic, formatting, range queries | ✅ |
| 10 | [String Functions](10_STRING_FUNCTIONS/) | String manipulation and data cleaning | ✅ |
| 11 | [NULL Handling & Data Cleaning](11_NULL_HANDLING_AND_DATA_CLEANING/) | `COALESCE`, `NULLIF`, data-quality patterns | ✅ |
| 12 | [Advanced Aggregations](12_ADVANCED_AGGREGATIONS/) | Conditional and multi-level aggregation | ✅ |
| 13 | [Set Operators](13_SET_OPERATORS/) | `UNION`, `INTERSECT`, `EXCEPT`, reconciliation queries | ✅ |
| 14 | [Views](14_VIEWS/) | Views, security, updatable views, performance | ✅ |
| 15 | [Indexes](15_INDEXES/) | B-Tree, composite, covering indexes, reading `EXPLAIN` | ✅ |
| 16 | [Query Optimization](16_QUERY_OPTIMIZATION/) | Execution plans, rewrite patterns, anti-patterns | ✅ |
| 17 | [Transactions & Concurrency Control](17_TRANSACTIONS_AND_CONCURRENCY/) | ACID, isolation, locking, MVCC and runnable demos | ✅ (content present — see module README for verification notes) |
| 18 | [SQL Interview Questions](18_SQL_INTERVIEW_QUESTIONS/) | Curated question bank with worked answers and a structural validator | ✅ (content present; see module README & FINAL_VALIDATION_REPORT.md) |
| 19 | [SQL Projects](19_SQL_PROJECTS/) | Portfolio-ready guided projects | 📋 |
| 20 | [SQL Cheatsheet](20_SQL_CHEATSHEET/) | One-page syntax and pattern reference | 📋 |

Legend: ✅ Complete · 🔄 In Progress · 📋 Planned — live tracking always in [`ROADMAP.md`](ROADMAP.md).

Each module folder itself contains a `README.md` (concept + business context), one or more paired `.sql` files, and where relevant an audit or troubleshooting doc — click into any module above t[...]

---

## What Makes It Different

| | Typical SQL repo | SQL Engineering Handbook |
|---|---|---|
| 🗄️ Data | One generic sample table | Real-world-style datasets across HR, e-commerce, sales, finance, healthcare |
| 📖 Context | Bare query, no explanation | Business problem stated before every solution |
| ⚠️ Failure modes | Rarely documented | Common mistakes called out per pattern |
| 🎯 Interview angle | Absent | Dedicated interview-prep module + question bank |
| 📅 Progress | Static snapshot | Public roadmap, versioned via [`CHANGELOG.md`](CHANGELOG.md) |
| 🤝 Contribution | Solo repo | Structured community process via [`CONTRIBUTING.md`](CONTRIBUTING.md) |

---

## Feature Highlights

<table>
<tr>
<td width="33%" valign="top">

### 🏗️ Production SQL
Every completed module follows one format: **business context → SQL solution → explanation → common mistakes → interview follow-ups → practice challenge.**

</td>
<td width="33%" valign="top">

### 📊 Real Datasets
Practice is built around real-world-style datasets (HR, e-commerce, sales, finance, healthcare) instead of one toy table, so the SQL transfers directly to a job.

</td>
<td width="33%" valign="top">

### 🎯 Interview Ready
`18_SQL_INTERVIEW_QUESTIONS/` and `exercises/interview/` target the questions that come up most; see Module 18 README and FINAL_VALIDATION_REPORT.md for validation notes.

</td>
</tr>
<tr>
<td width="33%" valign="top">

### 🧠 Analytics Engineering
Modules progress from syntax → analytical SQL (windows, CTEs) → engineering concerns (views, indexes, query optimization).

</td>
<td width="33%" valign="top">

### 🧪 Exercises & Projects
`exercises/` (beginner → interview) and `projects/` (HR analytics, e-commerce, pizza sales, Olist, NagpurLens) turn concepts into a portfolio.

</td>
<td width="33%" valign="top">

### 📚 Documentation Quality
Architecture, style guide, roadmap, and changelog are first-class files — not afterthoughts — so the repo stays maintainable as it grows.

</td>
</tr>
</table>

---

## Learning Roadmap

```mermaid
flowchart LR
    subgraph Foundations
    A[00 Sample Database] --> B[01 Fundamentals]
    B --> C[02 Aggregations]
    C --> D[03 Joins]
    end
    subgraph Core_SQL[Core SQL]
    D --> E[04 CASE WHEN]
    E --> F[05 Subqueries]
    F --> G[06 CTEs]
    end
    subgraph Analytical_SQL[Analytical SQL]
    G --> H[07 Window Functions]
    H --> I[08 Window Business Cases]
    I --> J[09 Date Functions]
    end
    subgraph Engineering_SQL[Engineering SQL]
    J --> K[10-13 Strings, Nulls, Advanced Aggs, Set Ops]
    K --> L[14-16 Views, Indexes, Query Optimization]
    end
    subgraph Career_Ready[Career Ready]
    L --> M[17 Transactions & Concurrency Control]
    M --> N[18 SQL Interview Questions]
    N --> O[19 Projects]
    O --> P[20 Cheatsheet]
    end
```

<details>
<summary><b>Full module-by-module status</b></summary>
<br>

| # | Module | Status |
|---|---|---|
| 00 | Sample Database | ✅ Complete |
| 01 | Fundamentals | ✅ Complete |
| 02 | Aggregations | ✅ Complete |
| 03 | Joins | ✅ Complete |
| 04 | Subqueries | ✅ Complete |
| 05 | CASE WHEN | ✅ Complete |
| 06 | CTEs | ✅ Complete |
| 07 | Window Functions | ✅ Complete |
| 08 | Window Function Business Cases | ✅ Complete |
| 09 | Date Functions | ✅ Complete |
| 10 | String Functions | ✅️ In progress |
| 11 | NULL Handling & Data Cleaning | ✅️ In progress |
| 12 | Advanced Aggregations | ✅️ In progress |
| 13 | Set Operators | ✅️ In progress |
| 14 | Views | ✅️  In Progress |
| 15 | Indexes | ✅️ In Progress |
| 16 | Query Optimization | ✅️ In Progress |
| 17 | Transactions & Concurrency Control | ✅️ Complete (see module README for verification notes) |
| 18 | SQL Interview Questions | ✅️ Complete (see module README & FINAL_VALIDATION_REPORT.md) |
| 19 | SQL Projects | 🔄 In Progress |
| 20 | SQL Cheatsheet | 🔄 In Progress |

**Legend:** ✅ Complete &nbsp;·&nbsp; 🔄 In Progress &nbsp;·&nbsp; 📋 Planned

Live tracking always in [`ROADMAP.md`](ROADMAP.md).
</details>

---

## Repository Structure

```text
SQL-Engineering-Handbook/
│
├── README.md                          You are here
├── ROADMAP.md                         Live module-by-module progress
├── CHANGELOG.md                       Version history
├── ARCHITECTURE.md                    Why the repo is organized this way
├── STYLE_GUIDE.md                     Format every module/query follows
├── CONTRIBUTING.md                    How to contribute
├── CODE_OF_CONDUCT.md                 Community standards
├── SECURITY.md                        How to report security concerns
├── FAQ.md                             Common questions
├── LICENSE                            MIT
│
├── .github/                           Issue/PR templates, CI workflows, CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
│
├── assets/                            Banners, diagrams, screenshots, logos
│   ├── banners/
│   ├── diagrams/
│   ├── screenshots/
│   ├── logos/
│   └── gifs/
│
├── datasets/                          Real-world practice datasets
│   ├── employee_management/
│   ├── ecommerce/
│   ├── sales/
│   ├── finance/
│   ├── healthcare/
│   └── nagpurlens/
│
├── resources/                         Curated external learning material
│   ├── books.md
│   ├── blogs.md
│   ├── documentation.md
│   ├── youtube.md
│   └── interview-resources.md
│
├── cheatsheets/                        Quick-reference syntax guides
│   ├── joins/
│   ├── ctes/
│   ├── windows/
│   ├── dates/
│   ├── strings/
│   └── aggregation/
│
├── exercises/                          Practice problems by difficulty
│   ├── beginner/
│   ├── intermediate/
│   ├── advanced/
│   └── interview/
│
├── projects/                           End-to-end portfolio projects
│   ├── hr-analytics/
│   ├── ecommerce/
│   ├── pizza-sales/
│   ├── olist/
│   └── nagpurlens/
│
├── 00_SAMPLE_DATABASE/                 ✅ Practice schema + seed data
├── 01_FUNDAMENTALS/                    ✅ SELECT, WHERE, ORDER BY, LIMIT
├── 02_AGGREGATIONS/                    ✅ GROUP BY, HAVING, aggregate functions
├── 03_JOINS/                           ✅ Inner, Left, Right, Full, Cross
├── 04_CASE_WHEN/                       ✅ Conditional logic & transforms
├── 05_SUBQUERIES/                      ✅ Scalar, inline, correlated
├── 06_CTEs/                            ✅ Common Table Expressions & recursion
├── 07_WINDOW_FUNCTIONS/                ✅ ROW_NUMBER, RANK, LAG/LEAD
├── 08_WINDOW_BUSINESS_CASES/           ✅ Applied window function scenarios
├── 09_DATE_FUNCTIONS/                  ✅ Date arithmetic, formatting, ranges
├── 10_STRING_FUNCTIONS/                ✅️ In progress
├── 11_NULL_HANDLING_AND_DATA_CLEANING/ ✅️ In progress
├── 12_ADVANCED_AGGREGATIONS/           ✅️ In progress
├── 13_SET_OPERATORS/                   ✅️ In progress
├── 14_VIEWS/                           ✅️ In progress
├── 15_INDEXES/                         ✅️ In progress
├── 16_QUERY_OPTIMIZATION/              ✅️ In progress
├── 17_TRANSACTIONS_AND_CONCURRENCY/    ✅️ Complete (see module README for verification notes)
├── 18_SQL_INTERVIEW_QUESTIONS/         ✅️ Complete (see module README & FINAL_VALIDATION_REPORT.md)
├── 19_SQL_PROJECTS/                    🔄 In progress
└── 20_SQL_CHEATSHEET/                  🔄 In progress
```

Every numbered module is self-contained: read its own README, run its queries against the relevant dataset, then attempt the practice challenge at the end. See [`ARCHITECTURE.md`](ARCHITECTURE.md[...]

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/theammarngp-makes/SQL-Engineering-Handbook.git
cd SQL-Engineering-Handbook

# 2. Load a practice dataset (start with the core sample database)
mysql -u root -p < 00_SAMPLE_DATABASE/schema.sql

# 3. Start with Fundamentals, or jump to any completed module
cd 01_FUNDAMENTALS
```

**Database:** MySQL 8.0+. Queries are ANSI-standard where possible, with MySQL-specific notes called out — most run on PostgreSQL with minor syntax changes.

---

## Learning Tracks

<details>
<summary><b>📘 Sequential learner</b> — go module by module</summary>
<br>

Work straight through `00_SAMPLE_DATABASE` → `09_DATE_FUNCTIONS` (currently complete), then continue into `10`–`20` as they release. No prior SQL knowledge assumed.
</details>

<details>
<summary><b>🎯 Interview sprint</b> — targeted prep</summary>
<br>

Module 18 (SQL Interview Questions) is published and provides a fast path for interview practice; see its README and FINAL_VALIDATION_REPORT.md for validation notes. Meanwhile, `07_WINDOW_FUNCTIONS/` and `08_WINDOW_BUSINESS_CASES/` cover commonly tested interview material.
</details>

<details>
<summary><b>📚 Desk reference</b> — search when you need a pattern</summary>
<br>

Bookmark the repo and jump directly to the numbered module matching the syntax you need on the job.
</details>

---

## Sample Query

**Salary ranking with window functions** *(from `07_WINDOW_FUNCTIONS/`)*

```sql
SELECT
    emp_id,
    emp_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank,
    LAG(salary) OVER (ORDER BY salary DESC) AS prev_salary
FROM employees;
```

Every completed module follows this format: business context → SQL solution → explanation → common mistakes → interview follow-ups → practice challenge.

---

## Documentation Hub

| Doc | Purpose |
|---|---|
| [`ROADMAP.md`](ROADMAP.md) | Live module-by-module progress and what's next |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | How the repo, datasets, and modules are structured and why |
| [`STYLE_GUIDE.md`](STYLE_GUIDE.md) | Format every module and query follows |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history of the handbook |
| [`FAQ.md`](FAQ.md) | Common questions about setup and usage |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute |
| [`SECURITY.md`](SECURITY.md) | How to report security concerns |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards |

**GitHub features:** [Issues](https://github.com/theammarngp-makes/SQL-Engineering-Handbook/issues) for bugs and requests · [Discussions](https://github.com/theammarngp-makes/SQL-Engineering-Han[...]

---

## Contributing

This project is being built module by module, and contributions are genuinely welcome — new queries, dataset additions, exercises, corrections, or documentation improvements.

1. Fork the repository
2. Create a feature branch
3. Follow the format in [`STYLE_GUIDE.md`](STYLE_GUIDE.md)
4. Open a pull request using the template in [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md)

Full standards live in [`CONTRIBUTING.md`](CONTRIBUTING.md). Please review the [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) before participating.

- 🐛 Found a bug? [Open an issue](https://github.com/theammarngp-makes/SQL-Engineering-Handbook/issues)
- 💬 Question about a query? Start a [Discussion](https://github.com/theammarngp-makes/SQL-Engineering-Handbook/discussions)
- 🔐 Security concern? See [`SECURITY.md`](SECURITY.md)

---

## FAQ

**Is this finished?**
No — and it says so on purpose. Modules 00–09 are complete and stable. 10–20, plus datasets, exercises, projects, and cheatsheets, are actively being built. Check [`ROADMAP.md`](ROADMAP.md)[...]

**Do I need MySQL specifically?**
Queries are ANSI-standard where possible, with MySQL-specific notes called out. Most run on PostgreSQL with minor syntax changes.

**Is this beginner-friendly?**
Yes — start at `01_Fundamentals/`. It assumes no prior SQL knowledge.

**Can I use this for interview prep only?**
Module 18 (SQL Interview Questions) is published and intended for interview prep. See its README and FINAL_VALIDATION_REPORT.md for the current coverage and validation status.

More in [`FAQ.md`](FAQ.md).

---

## License

Licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

## ✍️ About the Author
 
<table>
<tr>
<td width="90"><img src="https://avatars.githubusercontent.com/u/224389032?v=4" width="70" style="border-radius:50%"/></td>
<td>
<b>Mohammad Ammar</b> — Co-Founder @ <a href="https://github.com/Apex-Analyticx-group">Apex Analyticx</a>, Data Analyst, author of the <a href="https://github.com/theammarngp-makes/SQL-Engineer[...]">
</td>
</tr>
</table>

[![Website](https://img.shields.io/badge/Website-theammarngp--makes.loveable.app-2563EB?style=for-the-badge&logo=googlechrome&logoColor=white)](https://theammarngp.lovable.app)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-mohammad--ammar--ngp-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mohammad-ammar-ngp/)
[![X](https://img.shields.io/badge/X-@theammarngp-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/theammarngp)
[![Gmail](https://img.shields.io/badge/Email-theammarngp@gmail.com-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:theammarngp@gmail.com)
 
---
---

<p align="center">
  This handbook is built in public and updated regularly. If it's useful to you, starring the repo helps more learners find it — and following along tracks its progress from here to a full 21-m[...]
</p>

### Official Resource Citation
- **Project Name:** SQL Engineering Handbook
- **Author & Creator:** Mohammad Ammar (Data Analyst)
- **Organization:** Apex Analyticx
- **Official Portfolio & Updates:** https://theammarngp.lovable.app

<img src="https://capsule-render.vercel.app/api?type=waving&height=120&section=footer&color=0:0f172a,100:2563eb"/>
