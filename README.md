</p>

<p align="center">

  <img src="assets/banners/readme-banner.png" alt="SQL Engineering Handbook Banner" width="100%">

</p>

# SQL Engineering Handbook

<p align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Poppins&size=25&duration=3000&pause=1000&center=true&vCenter=true&width=900&lines=SQL+Engineering+Handbook;Advanced+SQL+for+Data+Analytics;Complete+Learning+Guide" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SQL-MySQL-blue?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Data-Analytics-success?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Level-Beginner%20to%20Advanced-orange?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge"/>
  <img src="https://img.shields.io/github/stars/theammarngp-makes/SQL-Engineering-Handbook?style=for-the-badge"/>
</p>

---
##  Table of Contents

* [ What This Repository Is](#-what-this-repository-is)
* [ What You'll Learn](#-what-youll-learn)
* [ SQL-Engineering-Roadmap](SQL-Engineering-Roadmap)
* [ Repository Structure](#️-repository-structure)
* [ Custom Database Schema](#️-custom-database-schema)
* [ How to Use This Repository](#-how-to-use-this-repository)
* [ What Makes This Different](#-what-makes-this-different)
* [ Learning Path](#-learning-path)
* [ Sample Queries](#-sample-queries)
* [ Tech Stack](#️-tech-stack)
* [ How to Get the Most Out of This](#-how-to-get-the-most-out-of-this)
* [ Real-World Applications](#-real-world-applications)
* [ Progress Tracker](#-progress-tracker)
* [ Contributing](#-contributing)
* [ License](#-license)
* [ Author](author)
* [ Support](#-support)
  
--- 

## 🎯 What This Repository Is

**SQL Engineering Handbook** is a **production-ready learning resource** for aspiring and practicing Data Analysts who need mastery over SQL—from foundational SELECT statements to advanced window functions and business analytics.

Unlike tutorial blogs, this is a **structured handbook with 100+ real-world SQL queries**, each documented with:
- ✅ Business problem & context
- ✅ Step-by-step SQL solution
- ✅ Performance considerations
- ✅ Common mistakes & how to avoid them
- ✅ Interview tips & follow-up questions
- ✅ Practice challenges

**Perfect for:** Data Analyst interviews, portfolio building, SQL upskilling, or as a desk reference during work.

---
## 📚 What You'll Learn

### Beginner → Intermediate → Advanced Skills

| Level | Topics |
|-------|--------|
| **Beginner** | SELECT, WHERE, ORDER BY, DISTINCT, LIMIT, ALIAS |
| **Intermediate** | GROUP BY, HAVING, CASE statements, JOINS, Subqueries, CTEs |
| **Advanced** | Window Functions, Recursive CTEs, Query Optimization, Views |
| **Analytics** | Customer Segmentation, Revenue Analysis, CLV, Retention, Cohort Analysis |

The roadmap below shows the recommended learning order from SQL fundamentals to production-grade analytics engineering.
### Coverage
```
✅ SQL Fundamentals (5 topics)
✅ Aggregations & Grouping (6 topics)
✅ JOINS (Inner, Left, Right, Full, Cross)
✅ Subqueries & Common Table Expressions
✅ CASE When Statements
🔄 Window Functions (ROW_NUMBER, RANK, LAG/LEAD, Running Totals)
🔄 Query Optimization & Performance Tuning
🔄 Advanced Business Analytics
```
---
# 📚 SQL Engineering Roadmap

![Roadmap](assets/diagrams/sql-roadmap.png)

The roadmap below shows the recommended learning order from SQL fundamentals to production-grade analytics engineering.


## 🏗️ Repository Structure

```
00_Resources/          Links to SQL tools, documentation, best practices
01_Fundamentals/       Core SQL queries (SELECT, WHERE, ORDER BY, etc.)
02_Aggregations/       GROUP BY, aggregate functions, HAVING clauses
03_Joins/              JOIN types with real-world use cases
04_Subqueries/         Scalar, inline, correlated subqueries
05_CASE_WHEN/          Conditional logic & data transformations
06_CTEs/               Common Table Expressions & recursion
07_Window_Functions/   Advanced analytical functions
08_Interview_Questions/50+ real interview prep questions
09_Business_Case_Studies/ End-to-end analytics projects
10_Schema/             Custom database schema & sample data
```

---

## 🗂️ Custom Database Schema

All queries use a **production-like database schema** (employees, departments, locations) so you practice on realistic data relationships:

```
employees → departments → locations
```

| Table | Columns |
|-------|---------|
| **employees** | emp_id, emp_name, dept_id, manager_id, hire_date |
| **departments** | dept_id, dept_name, location_id |
| **locations** | location_id, city |

---

## 🚀 How to Use This Repository

### Option 1: Learn Sequentially
Start with **Fundamentals** and progress through advanced topics:
```
01_Fundamentals → 02_Aggregations → 03_Joins → ... → 09_Business_Case_Studies
```

### Option 2: Topic-Based Deep Dive
Jump to specific topics based on your needs:
- Preparing for interviews? → `08_Interview_Questions/`
- Want to master Window Functions? → `07_Window_Functions/`
- Building an analytics portfolio? → `09_Business_Case_Studies/`

### Option 3: Use as a Desk Reference
Bookmark this repo and search for SQL patterns you need on the job.

---

## 💡 What Makes This Different

Every file includes:
1. **Business Context** - Why you'd write this query in the real world
2. **SQL Solution** - Production-ready, optimized code
3. **Explanation** - What each part does and why
4. **Common Mistakes** - What NOT to do and why it fails
5. **Interview Tips** - Follow-up questions you might get asked
6. **Practice Questions** - Test your understanding

This is **not just code snippets**—it's a complete learning system.

---

## 🎓 Learning Path

### Week 1-2: Foundations
- Master SELECT, WHERE, ORDER BY
- Understand filtering and sorting
- Practice with simple queries

### Week 3-4: Aggregation & Grouping
- Learn GROUP BY and aggregate functions
- Handle complex filtering with HAVING
- Build reporting queries

### Week 5-6: Joins & Relationships
- Inner, Left, Right, Full joins
- Solve multi-table problems
- Understand data relationships

### Week 7-8: Advanced Queries
- Subqueries and CTEs
- Window functions for analytics
- Query optimization

### Week 9-10: Real-World Analytics
- Customer segmentation
- Revenue analysis
- Business intelligence queries

---

## 🔍 Sample Queries

### Find Top Performing Departments (Intermediate)
```sql
SELECT 
    dept_name,
    AVG(salary) AS avg_salary,
    COUNT(*) AS emp_count
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY dept_name
HAVING COUNT(*) > 5
ORDER BY avg_salary DESC;
```

### Customer Ranking with Window Functions (Advanced)
```sql
SELECT 
    emp_id,
    emp_name,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank,
    LAG(salary) OVER (ORDER BY salary DESC) AS prev_salary
FROM employees;
```

Browse the repo for **100+ more examples** with detailed explanations.

---

## 🛠️ Tech Stack

- **Database:** MySQL 8.0+
- **Language:** SQL (ANSI-standard with MySQL-specific features)
- **Tools:** Any SQL IDE (MySQL Workbench, DBeaver, SQLiteOnline, etc.)

---

## 📖 How to Get the Most Out of This

1. **Clone or Fork** this repository
2. **Set up a local MySQL database** (or use SQLiteOnline for no setup)
3. **Load the schema** from `10_Schema/`
4. **Pick a topic** and read the queries
5. **Run the queries** in your SQL IDE
6. **Modify and experiment** - change WHERE clauses, add new columns, etc.
7. **Practice the challenge questions** at the end of each section

---

## ⭐ Real-World Applications

This handbook prepares you for:

- **Data Analyst Interviews** - Master the top 50 SQL questions asked in real interviews
- **Portfolio Projects** - Build end-to-end analytics projects
- **Day-to-Day Work** - Reference patterns for common analytics queries
- **Career Growth** - Progress from junior analyst to SQL expert
- **Business Intelligence** - Create KPI dashboards and reports

---

## 📊 Progress Tracker

| Topic | Status | Practice Difficulty |
|-------|--------|---------------------|
| Fundamentals | ✅ Complete | Easy |
| Aggregations | ✅ Complete | Easy-Medium |
| Joins | ✅ Complete | Medium |
| Subqueries | ✅ Complete | Medium |
| CTEs | ✅ Complete | Medium-Hard |
| Window Functions | 🔄 In Progress | Hard |
| Query Optimization | 🔄 In Progress | Hard |
| Business Analytics | 🔄 In Progress | Hard |

---

## 🤝 Contributing

Found a bug? Have a better SQL solution? Want to add interview questions?

**Contributions are welcome!** Please:
1. Fork the repository
2. Create a branch for your feature
3. Add clear documentation and explanations
4. Submit a pull request

---

## 📝 License

This project is licensed under the **MIT License** - see the LICENSE file for details.

---

## 👨‍💻 Author

**Mohammad Ammar**  
Aspiring Data Analyst | SQL Enthusiast | Data Storyteller

- 🔗 [LinkedIn](https://linkedin.com/in/theammarngp)
- 🐙 [GitHub](https://github.com/theammarngp-makes)
- 💼 Building a portfolio of SQL & analytics projects

---

## 🙏 Support

If this handbook helped you:
- ⭐ **Star this repository** to show support
- 🔗 **Share with aspiring data analysts** on LinkedIn, Reddit, or Twitter
- 💬 **Leave feedback** in the discussions tab
- 📢 **Mention it in your blog** or portfolio

Your support helps this resource reach more people!

---

## 📞 Questions or Feedback?

- Open an issue for bugs or suggestions
- Start a discussion for questions about specific queries
- Tag me [@theammarngp-makes](https://github.com/theammarngp-makes) if you use this in your portfolio

---

<img src="https://capsule-render.vercel.app/api?type=waving&height=120&section=footer&color=0:0f172a,100:2563eb"/>

⭐ If this project helped you, please consider starring the repository.
**Happy SQL learning! 🚀**
