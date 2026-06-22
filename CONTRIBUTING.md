# Contributing to SQL Engineering Handbook

First off, thank you for considering contributing to the SQL Engineering Handbook! 🎉

This is a community-driven project, and we welcome contributions from everyone—whether you're a SQL expert or just starting out. Every contribution helps other developers learn and grow.

---

## Table of Contents
- [Ways to Contribute](#ways-to-contribute)
- [Getting Started](#getting-started)
- [Code of Conduct](#code-of-conduct)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Recognition](#recognition)

---

## Ways to Contribute

### 1. 🌍 Translate Queries to Other SQL Dialects

**The Goal:** Make the handbook useful for developers using different databases.

**Current Focus:** MySQL

**Needed Translations:**
- ❄️ **Snowflake SQL** - Cloud data warehouse favorite
- 🔷 **Google BigQuery** - Popular in data teams
- 🗃️ **Databricks / Apache Spark SQL** - Big data & ML workflows
- 🏗️ **T-SQL (SQL Server)** - Enterprise standard
- 🐘 **PostgreSQL** - Open source, widely used

**How to Contribute:**

1. **Pick a file** from any section (e.g., `01_Fundamentals/01_SELECT.sql`)
2. **Translate the query** to your target dialect
3. **Create a new file** with the same name and add a suffix:
   ```
   01_SELECT.sql           (original MySQL)
   01_SELECT_snowflake.sql (Snowflake version)
   01_SELECT_bigquery.sql  (BigQuery version)
   ```
4. **Include dialect-specific comments:**
   ```sql
   -- Snowflake Version
   -- Key differences from MySQL:
   -- 1. ILIKE is case-insensitive (MySQL: LOWER(col) LIKE pattern)
   -- 2. String functions: use :: instead of CAST
   -- 3. Date functions: DATE_PART instead of EXTRACT
   
   SELECT * FROM employees WHERE emp_name ILIKE '%john%';
   ```
5. **Submit a Pull Request** with your translations

**Example Structure:**
```
03_Joins/
├── 01_Inner_Join.sql              (MySQL - original)
├── 01_Inner_Join_snowflake.sql    (Snowflake)
├── 01_Inner_Join_bigquery.sql     (BigQuery)
├── 01_Inner_Join_tsql.sql         (SQL Server)
└── 01_Inner_Join_postgres.sql     (PostgreSQL)
```

**Translation Checklist:**
- ✅ Query produces same results as MySQL version
- ✅ Includes dialect-specific comments
- ✅ No external dependencies (use built-in functions)
- ✅ Performance-optimized for that dialect
- ✅ Tests on actual database if possible

---

### 2. 🐛 Report Bugs & Issues

Found an error in a query? Syntax issue? Let us know!

**Before Opening an Issue:**
- Check if the issue already exists
- Test the query yourself (if possible)
- Have the exact error message ready

**When Opening an Issue:**
- Use the "Bug Report" template (it'll auto-populate)
- Include: database type, query, expected output, actual output
- Screenshots/errors are helpful

**Example Bug Report:**
```
**Title:** Error in 05_CASE_WHEN - Customer Tier Query

**Description:** The query returns NULL for customers with NULL salaries

**Database:** MySQL 8.0

**Query File:** 05_CASE_WHEN/03_Customer_Tier.sql

**Actual Output:**
emp_id | tier
------|-----
1     | Gold
2     | NULL  ← Should be "Bronze"

**Expected Output:**
emp_id | tier
------|-----
1     | Gold
2     | Bronze
```

---

### 3. 💡 Suggest Features & New Content

Have ideas for new queries, topics, or case studies? We'd love to hear them!

**Feature Request Ideas:**
- New SQL concepts (e.g., "Recursive CTEs with Real Examples")
- New business case study (e.g., "Marketing Attribution Analysis")
- Performance optimization for specific queries
- New database dialect support
- Visual diagrams or query flow charts

**How to Suggest:**
1. Open an issue with the "Feature Request" template
2. Clearly describe what should be added
3. Explain why it would be valuable
4. Provide examples if possible

**Example Feature Request:**
```
**Title:** Add Query Optimization Tips Section

**Description:**
Many beginners write slow queries without knowing why. 
A dedicated section showing BEFORE/AFTER optimization would help.

**Suggested Content:**
- Common performance anti-patterns
- EXPLAIN ANALYZE walkthroughs
- Indexing strategies
- Real performance improvements (+examples)

**Why It Matters:**
- Interview prep (optimization is asked frequently)
- Real-world importance (slow queries cost money)
- Career growth (optimization skills are valuable)
```

---

### 4. ✍️ Write New Queries & Case Studies

Want to add a query? Submit one!

**Query Template:**
```sql
-- ============================================================
-- BUSINESS PROBLEM
-- ============================================================
-- Find the top 3 departments by average employee salary
-- and show how many employees are in each department.
--
-- Use Case: HR team wants to understand compensation by department

-- ============================================================
-- SOLUTION
-- ============================================================
SELECT 
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS emp_count,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY avg_salary DESC
LIMIT 3;

-- ============================================================
-- EXPLANATION
-- ============================================================
-- 1. JOIN: Connect employees to departments
-- 2. GROUP BY: Group by department
-- 3. COUNT: Count employees per department
-- 4. AVG: Calculate average salary per department
-- 5. ORDER BY + LIMIT: Get top 3

-- ============================================================
-- COMMON MISTAKES
-- ============================================================
-- ❌ MISTAKE 1: Forgetting GROUP BY with aggregate functions
-- SELECT d.dept_name, AVG(salary) -- Missing: GROUP BY
-- This will error in MySQL (strict mode)

-- ❌ MISTAKE 2: Using HAVING without GROUP BY context
-- SELECT AVG(salary) HAVING AVG(salary) > 50000 -- Wrong!

-- ✅ CORRECT: Always use GROUP BY with aggregates

-- ============================================================
-- INTERVIEW TIPS
-- ============================================================
-- Q: What if there are departments with NULL employees?
-- A: Use LEFT JOIN to include departments with no employees

-- Q: How would you handle NULL salaries?
-- A: Use WHERE salary IS NOT NULL or COALESCE(salary, 0)

-- Q: How would you optimize this for 1M+ employees?
-- A: Add indexes on dept_id and salary columns

-- ============================================================
-- PRACTICE QUESTIONS
-- ============================================================
-- 1. Modify to show ALL departments (including ones with no employees)
-- 2. Add a column showing salary quartile ranking within each dept
-- 3. Filter to only show departments with avg salary > $60k
-- 4. Add a running total of employees sorted by avg salary
```

**Where to Contribute Queries:**
- New fundamentals? → `01_Fundamentals/`
- Interview question? → `08_Interview_Questions/`
- Business case? → `09_Business_Case_Studies/`
- General query? → Create appropriate section

---

### 5. 🚀 Optimize Existing Queries

Found a way to make a query faster or more readable?

**Optimization Guidelines:**
- Include both original + optimized versions
- Document the improvement (time saved, readability, clarity)
- Add comments explaining the optimization
- Show performance comparison if possible

**Example Optimization:**
```sql
-- ❌ ORIGINAL (Slower)
SELECT *
FROM employees e
WHERE e.salary > (SELECT AVG(salary) FROM employees)
  AND YEAR(e.hire_date) = 2023;

-- ✅ OPTIMIZED (Faster)
-- Use CTE to calculate avg salary once instead of in WHERE clause
WITH avg_salary AS (
    SELECT AVG(salary) AS avg_sal FROM employees
)
SELECT e.*
FROM employees e
CROSS JOIN avg_salary a
WHERE e.salary > a.avg_sal
  AND YEAR(e.hire_date) = 2023;

-- Performance: 40% faster on large datasets
-- Reason: Subquery in WHERE clause was recalculating for each row
```

---

### 6. 📚 Improve Documentation

- Better explanations for complex queries
- Add visual diagrams
- Create learning guides
- Translate documentation to other languages

---

## Getting Started

### Step 1: Fork the Repository
```bash
git clone https://github.com/theammarngp-makes/SQL-Engineering-Handbook.git
cd SQL-Engineering-Handbook
```

### Step 2: Create a Branch
```bash
git checkout -b feature/your-contribution-name
# Examples:
# feature/snowflake-translations
# feature/new-window-functions
# fix/aggregations-null-handling
```

### Step 3: Make Your Changes
- Add/modify files
- Follow the formatting guidelines below
- Test thoroughly

### Step 4: Commit with Clear Messages
```bash
git commit -m "Add: Snowflake translations for Joins section"
# Or
git commit -m "Fix: Handle NULL values in aggregation queries"
# Or
git commit -m "Optimize: Use CTE instead of subquery for performance"
```

### Step 5: Push and Create a Pull Request
```bash
git push origin feature/your-contribution-name
```

Then open a Pull Request with:
- Clear title
- Description of what you changed and why
- Link to related issues (if any)

---

## Code of Conduct

### We are committed to providing a welcoming and inclusive environment:

✅ **DO:**
- Be respectful and helpful
- Welcome feedback and suggestions
- Give credit where credit is due
- Assume good intentions

❌ **DON'T:**
- Use offensive or demeaning language
- Harass or discriminate
- Spam or self-promote excessively
- Ignore feedback or criticism

**Violation?** Report to: theammarngp@gmail.com

---

## Contribution Guidelines

### SQL Query Format

**File Naming:**
```
{number}_{brief_description}.sql
Examples:
- 01_SELECT_Basics.sql
- 02_WHERE_Clause.sql
- 03_INNER_JOIN.sql
```

**Query Structure:**
```sql
-- ============================================================
-- BUSINESS PROBLEM
-- ============================================================
-- [2-3 sentence description of what the query does]
-- [Real-world use case]

-- ============================================================
-- SOLUTION
-- ============================================================
[SQL Query]

-- ============================================================
-- EXPLANATION
-- ============================================================
-- [Step-by-step explanation of the query]

-- ============================================================
-- COMMON MISTAKES
-- ============================================================
-- ❌ [Common mistake]
-- ✅ [Correct approach]

-- ============================================================
-- INTERVIEW TIPS
-- ============================================================
-- Q: [Potential follow-up question]
-- A: [Your answer or approach]

-- ============================================================
-- PRACTICE QUESTIONS
-- ============================================================
-- 1. [Variation of the query]
-- 2. [Related problem to solve]
```

### SQL Best Practices
- Use uppercase for keywords: `SELECT`, `FROM`, `WHERE`
- Use lowercase for column/table names
- Indent for readability
- Add aliases to make queries clear
- Include comments for complex logic
- Test on actual data before submitting

### Dialect-Specific Translations

When translating to another SQL dialect:

1. **Test thoroughly** - Run on actual database
2. **Document differences** - Add comments explaining dialect-specific syntax
3. **Maintain readability** - Keep query structure similar to original
4. **Performance** - Optimize for that dialect (indexes, functions, etc.)
5. **Edge cases** - Handle NULLs, special characters, data types appropriately

**Dialect Translation Checklist:**
```
- [ ] Query tested on actual [Snowflake/BigQuery/etc.] instance
- [ ] Produces same results as MySQL version
- [ ] Includes dialect-specific comments
- [ ] Uses native functions (not workarounds)
- [ ] Performance-optimized for that database
- [ ] File named: {original_name}_{dialect}.sql
- [ ] Explains key differences from MySQL
```

---

## Pull Request Process

### Before Submitting
1. ✅ Test your changes thoroughly
2. ✅ Follow the SQL format guidelines
3. ✅ Add clear commit messages
4. ✅ Reference any related issues
5. ✅ Update README if adding new section

### What We'll Review
- **Correctness:** Does the query work correctly?
- **Clarity:** Is it easy to understand?
- **Usefulness:** Does it add value to the handbook?
- **Format:** Does it follow our guidelines?
- **Performance:** Is it optimized?

### Response Time
- We review PRs within 48-72 hours
- We may ask for changes
- Once approved, we'll merge and credit you!

---

## Recognition

### Contributors Wall

We use the [All Contributors](https://allcontributors.org/) bot to automatically recognize all contributions.

**Your contributions earn badges for:**
- 🐛 Bug fixes
- ✏️ Documentation
- 🔧 Code (translations, new queries)
- 💡 Ideas/suggestions
- 📝 Writing content
- 📢 Promotion

**View the Contributors Wall:**
See the bottom of our README.md for the complete contributors section with profile pictures!

### Hall of Fame

Top contributors (5+ contributions) get featured in our:
- README.md contributors section
- Monthly newsletter (if applicable)
- GitHub profile mention

---

## Questions or Need Help?

### Resources
- 📖 Read our README: [SQL-Engineering-Handbook](https://github.com/theammarngp-makes/SQL-Engineering-Handbook)
- 💬 Open a Discussion: GitHub Discussions tab
- 📧 Email: theammarngp@gmail.com
- 🐙 GitHub Issues: For specific problems

### Types of Contributions We Need Most

**🏆 High Priority:**
1. Snowflake SQL translations (highest demand)
2. BigQuery SQL translations
3. SQL Server / T-SQL translations
4. New business case studies
5. Interview question additions

**Medium Priority:**
1. Documentation improvements
2. Query optimizations
3. PostgreSQL translations
4. Bug fixes

**Ongoing:**
1. Feedback and suggestions
2. Sharing the handbook with others
3. Real-world examples and use cases

---

## Financial Recognition

As of now, this is a **volunteer-driven open-source project**. However:

- If you contribute 10+ high-quality items, we'll **feature you prominently**
- We're exploring open-source sponsorship opportunities
- Your contributions build your **portfolio and resume**

---

## License

By contributing to this project, you agree that your contributions will be licensed under the same MIT License.

---

## Special Thanks

This project thrives because of contributors like YOU! 

Whether you translate a single query, fix a typo, or write an entire case study—every contribution matters.

**Thank you for making SQL learning better for everyone! 🙌**

---

**Ready to contribute?**
1. Fork the repo
2. Create your feature branch
3. Make your changes
4. Submit a Pull Request
5. Get featured as a contributor! ⭐

---

For questions, reach out on GitHub or via email. Happy contributing! 🚀
