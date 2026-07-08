# Style Guide

This document defines the standards for every SQL file, markdown document, and code block in the SQL Engineering Handbook. All contributors must follow these standards. These rules exist to maintain consistency, readability, and professionalism across the entire repository.

---

## Table of Contents

- [Purpose](#purpose)
- [Repository Principles](#repository-principles)
- [SQL Formatting Standards](#sql-formatting-standards)
- [Markdown Standards](#markdown-standards)
- [Module Structure Standards](#module-structure-standards)
- [README Standards](#readme-standards)
- [SQL File Standards](#sql-file-standards)
- [Business Example Standards](#business-example-standards)
- [Naming Conventions](#naming-conventions)
- [Commenting Standards](#commenting-standards)
- [Documentation Writing Style](#documentation-writing-style)
- [Pull Request Checklist](#pull-request-checklist)
- [Contributor Checklist](#contributor-checklist)
- [Review Checklist](#review-checklist)

---

## Purpose

Standards exist to:

1. **Scale consistency**: 21 modules feel like one resource, not 21 separate projects
2. **Reduce friction**: New contributors don't ask "what's the right way?" — the guide answers it
3. **Enable maintenance**: Maintainers review PRs faster when standards are clear
4. **Build trust**: Production-quality formatting signals professionalism
5. **Respect time**: Reviewers spend time on substance, not formatting

This guide is the single source of truth. Do not invent new standards; follow this guide.

---

## Repository Principles

Every style choice reflects these core principles:

### Teach Reasoning

- Explain the *why* before the *what*
- Never ask learners to memorize; teach understanding
- Comments explain business logic, not syntax

### Teach Business

- Every SQL query answers a real business question
- Before code, state the problem
- Show how SQL is used in real companies

### Teach Production SQL

- Production SQL prioritizes clarity and maintainability over brevity
- Variable names are descriptive, not abbreviated
- Code is formatted for a team, not for a individual
- Edge cases (NULLs, duplicates) are considered

### Consistency Over Creativity

- A predictable style is more valuable than individual flair
- Follow the standard even when you prefer a different approach
- Consistency makes the repository more usable

### Documentation First

- Write explanation before code
- If a concept cannot be explained clearly, understand it better before writing SQL
- Comments are for the reader, not the author

---

## SQL Formatting Standards

### Keywords: Uppercase

All SQL keywords are uppercase. This provides visual distinction from table/column names.

✅ **Correct**
```sql
SELECT employee_id, employee_name
FROM employees
WHERE hire_date > '2020-01-01'
ORDER BY salary DESC;
```

❌ **Incorrect**
```sql
select employee_id, employee_name
from employees
where hire_date > '2020-01-01'
order by salary desc;
```

### Indentation: 4 Spaces

Use 4 spaces for indentation. Never use tabs.

✅ **Correct**
```sql
SELECT
    e.employee_id,
    e.employee_name,
    d.department_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.hire_date > '2020-01-01'
ORDER BY e.salary DESC;
```

❌ **Incorrect**
```sql
SELECT e.employee_id, e.employee_name, d.department_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.hire_date > '2020-01-01'
ORDER BY e.salary DESC;
```

### Line Breaks: One Clause Per Line

Each major clause (SELECT, FROM, WHERE, JOIN, GROUP BY, ORDER BY) starts on a new line.

✅ **Correct**
```sql
SELECT
    employee_id,
    employee_name,
    salary
FROM employees
WHERE department_id = 3
ORDER BY salary DESC;
```

❌ **Incorrect**
```sql
SELECT employee_id, employee_name, salary FROM employees WHERE department_id = 3 ORDER BY salary DESC;
```

### Aliases: Meaningful and Consistent

Table aliases are abbreviated but recognizable. Never use single letters like `a`, `b`, `t1`.

✅ **Correct**
```sql
SELECT
    emp.employee_id,
    emp.employee_name,
    dept.department_name
FROM employees emp
JOIN departments dept ON emp.dept_id = dept.dept_id;
```

❌ **Incorrect**
```sql
SELECT
    e.employee_id,
    e.employee_name,
    d.department_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

Column aliases should be descriptive and use `AS`.

✅ **Correct**
```sql
SELECT
    employee_id,
    salary * 12 AS annual_salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;
```

❌ **Incorrect**
```sql
SELECT
    employee_id,
    salary * 12 total_sal,
    RANK() OVER (ORDER BY salary DESC) rank
FROM employees;
```

### Comments: Business Logic First

Comments explain *why*, not *what*. The code shows the *what*.

✅ **Correct**
```sql
-- Calculate monthly sales commission (5% of sales above $10k threshold)
SELECT
    sales_rep_id,
    SUM(CASE
        WHEN amount > 10000 THEN amount * 0.05
        ELSE 0
    END) AS commission
FROM sales
WHERE sales_date >= '2024-01-01'
GROUP BY sales_rep_id;
```

❌ **Incorrect**
```sql
-- Sum the amount if it's greater than 10000, multiply by 0.05
SELECT
    sales_rep_id,
    SUM(CASE
        WHEN amount > 10000 THEN amount * 0.05
        ELSE 0
    END) AS commission
FROM sales
WHERE sales_date >= '2024-01-01'
GROUP BY sales_rep_id;
```

### CTEs: Named Clearly

Common Table Expressions use descriptive names that explain their purpose.

✅ **Correct**
```sql
WITH active_employees AS (
    SELECT
        employee_id,
        employee_name,
        department_id
    FROM employees
    WHERE termination_date IS NULL
),
employee_salaries AS (
    SELECT
        employee_id,
        SUM(salary) AS total_compensation
    FROM active_employees
    GROUP BY employee_id
)
SELECT
    ae.employee_name,
    es.total_compensation
FROM active_employees ae
JOIN employee_salaries es ON ae.employee_id = es.employee_id
ORDER BY es.total_compensation DESC;
```

❌ **Incorrect**
```sql
WITH cte1 AS (
    SELECT * FROM employees WHERE termination_date IS NULL
),
cte2 AS (
    SELECT employee_id, SUM(salary) AS total_comp FROM cte1 GROUP BY employee_id
)
SELECT * FROM cte1 JOIN cte2 ON cte1.employee_id = cte2.employee_id;
```

### JOINs: Explicit and Clear

Specify the join type explicitly (INNER, LEFT, RIGHT, FULL). Use the ON clause clearly.

✅ **Correct**
```sql
SELECT
    emp.employee_id,
    emp.employee_name,
    dept.department_name
FROM employees emp
INNER JOIN departments dept ON emp.dept_id = dept.dept_id
WHERE emp.hire_date > '2020-01-01';
```

❌ **Incorrect**
```sql
SELECT e.employee_id, e.employee_name, d.department_name
FROM employees e, departments d
WHERE e.dept_id = d.dept_id AND e.hire_date > '2020-01-01';
```

### Window Functions: Formatted for Clarity

Window functions are indented to show their structure.

✅ **Correct**
```sql
SELECT
    employee_id,
    employee_name,
    salary,
    RANK() OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
    ) AS salary_rank_in_dept,
    LAG(salary) OVER (
        PARTITION BY department_id
        ORDER BY hire_date
    ) AS previous_salary
FROM employees
ORDER BY department_id, salary DESC;
```

❌ **Incorrect**
```sql
SELECT
    employee_id,
    employee_name,
    salary,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank,
    LAG(salary) OVER (PARTITION BY department_id ORDER BY hire_date) AS prev_sal
FROM employees;
```

### CASE Statements: Indented Clearly

CASE statements show the structure with consistent indentation.

✅ **Correct**
```sql
SELECT
    employee_id,
    employee_name,
    CASE
        WHEN salary >= 100000 THEN 'Senior'
        WHEN salary >= 75000 THEN 'Mid-level'
        WHEN salary >= 50000 THEN 'Junior'
        ELSE 'Entry-level'
    END AS salary_band
FROM employees;
```

❌ **Incorrect**
```sql
SELECT employee_id, employee_name, CASE WHEN salary >= 100000 THEN 'Senior' WHEN salary >= 75000 THEN 'Mid-level' ELSE 'Entry-level' END AS salary_band FROM employees;
```

### ORDER BY: Always Explicit

Specify ASC or DESC explicitly. Never rely on defaults.

✅ **Correct**
```sql
SELECT
    employee_id,
    employee_name,
    salary
FROM employees
ORDER BY salary DESC, employee_name ASC;
```

❌ **Incorrect**
```sql
SELECT employee_id, employee_name, salary
FROM employees
ORDER BY salary DESC, employee_name;
```

### GROUP BY: All Grouped Columns Specified

Every non-aggregated column in SELECT must appear in GROUP BY. List columns in the same order as SELECT.

✅ **Correct**
```sql
SELECT
    department_id,
    employee_name,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id, employee_name
ORDER BY avg_salary DESC;
```

❌ **Incorrect**
```sql
SELECT
    department_id,
    employee_name,
    COUNT(*),
    AVG(salary)
FROM employees
GROUP BY department_id;
```

### Database Compatibility

Queries should be ANSI-standard SQL where possible. When using database-specific syntax, add a comment.

✅ **Correct**
```sql
-- MySQL SUBSTRING function
SELECT
    employee_id,
    employee_name,
    SUBSTRING(email, 1, POSITION('@' IN email) - 1) AS email_prefix
FROM employees;

-- NOTE: In PostgreSQL, use SUBSTR instead of SUBSTRING
```

---

## Markdown Standards

### Heading Hierarchy

Use a single H1 (#) per file. Use H2 (##) for major sections. Use H3 (###) for subsections.

✅ **Correct**
```markdown
# SQL Fundamentals

## Overview
...

## Learning Objectives
...

### Prerequisites
...
```

❌ **Incorrect**
```markdown
# SQL Fundamentals
### Overview
# Learning Objectives
```

### Spacing

- Blank line before and after headings
- Blank line before and after code blocks
- Blank line before and after lists
- No extra blank lines within sections

✅ **Correct**
```markdown
## Overview

This module covers the SELECT statement.

## Examples

Here are some examples:

```sql
SELECT * FROM employees;
```

## Tips

- Always use specific column names
- Avoid SELECT *
```

### Code Blocks

Always specify the language. Use triple backticks.

✅ **Correct**
````markdown
```sql
SELECT employee_id, employee_name
FROM employees;
```
````

❌ **Incorrect**
````markdown
```
SELECT employee_id, employee_name FROM employees;
```
````

### Tables

Use pipes and dashes for tables. Align columns for readability.

✅ **Correct**
```markdown
| Clause | Purpose | Example |
|--------|---------|---------|
| SELECT | Choose columns | SELECT employee_id, name |
| WHERE | Filter rows | WHERE salary > 50000 |
| ORDER BY | Sort results | ORDER BY salary DESC |
```

❌ **Incorrect**
```markdown
| Clause | Purpose |
| SELECT | Choose columns |
| WHERE | Filter rows |
```

### Lists

Use hyphens for unordered lists, numbers for ordered lists.

✅ **Correct**
```markdown
**Best practices:**

- Always use meaningful column aliases
- Format SQL for readability
- Add comments explaining business logic

**Steps to complete:**

1. Read the concept explanation
2. Run the example queries
3. Modify and experiment
```

### Links

Include context in the link text. Never use "click here."

✅ **Correct**
```markdown
For more information, see [CONTRIBUTING.md](CONTRIBUTING.md) for the process.
```

❌ **Incorrect**
```markdown
For more information, [click here](CONTRIBUTING.md).
```

### Images

Include descriptive alt text.

✅ **Correct**
```markdown
![SQL execution order diagram showing SELECT after WHERE and GROUP BY](assets/diagrams/execution-order.png)
```

❌ **Incorrect**
```markdown
![diagram](assets/diagrams/execution-order.png)
```

### Blockquotes

Use blockquotes for important notes, warnings, or key insights.

✅ **Correct**
```markdown
> **Key concept:** WHERE filters rows *before* aggregation. HAVING filters groups *after*.
```

### Badges

Use shields.io badges for module metadata at the top of module READMEs.

✅ **Correct**
```markdown
[![Level](https://img.shields.io/badge/Level-Beginner-brightgreen)]()
[![Status](https://img.shields.io/badge/Status-Complete-success)]()
```

---

## Module Structure Standards

Every numbered module (00–20) must contain:

### Required Files

1. **README.md** — Overview, objectives, topics, next steps
2. **NN_TOPIC_NAME.md** — Concept explanation (one per concept)
3. **NN_TOPIC_NAME.sql** — Runnable examples (paired with .md)
4. **PRACTICE.md** — Practice problems and solutions (optional if fewer than 3 concepts)

### File Naming

- Module directory: `NN_MODULE_NAME` (e.g., `01_FUNDAMENTALS`)
- Concept files: `NN_TOPIC_NAME.md` and `NN_TOPIC_NAME.sql`
- All filenames: snake_case, zero-padded numbers

✅ **Correct**
```
01_FUNDAMENTALS/
├── README.md
├── 01_SELECT.md
├── 01_SELECT.sql
├── 02_WHERE.md
├── 02_WHERE.sql
├── 03_ORDER_BY.md
├── 03_ORDER_BY.sql
└── PRACTICE.md
```

❌ **Incorrect**
```
01-Fundamentals/
├── readme.md
├── SELECT.md
├── select.sql
├── WhereClause.md
├── where.sql
```

---

## README Standards

Every module README must include these sections in order:

### 1. Module Title and Badge Block

```markdown
# NN — Module Name

> Description of what this module teaches

[![Level](https://img.shields.io/badge/Level-Beginner-brightgreen)]()
[![Estimated Time](https://img.shields.io/badge/Time-2--3%20hrs-blue)]()
[![Topics](https://img.shields.io/badge/Topics-5-orange)]()
[![Status](https://img.shields.io/badge/Status-Complete-success)]()
```

### 2. Table of Contents

Use markdown links to section anchors.

```markdown
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
```

### 3. Overview Section

One paragraph explaining what the module teaches and why it matters.

```markdown
## 🔎 Overview

This module covers [broad concept]. Students will learn [specific skills]. This is important because [business/career relevance].
```

### 4. Learning Objectives

Use checkbox format so learners can track progress.

```markdown
## 🎯 Learning Objectives

By the end of this module, you will be able to:

- [ ] Objective one
- [ ] Objective two
- [ ] Objective three
```

### 5. Topics Covered

Table with topic number, name, description, and file links.

```markdown
## 📖 Topics Covered

| No. | Topic | Description | Files |
|----|-------|--------------|-------|
| 01 | **Topic One** | Description | [`01_TOPIC_ONE.md`](./01_TOPIC_ONE.md) · [`01_TOPIC_ONE.sql`](./01_TOPIC_ONE.sql) |
```

### 6. Folder Structure

Show the actual directory layout.

```markdown
## 📂 Folder Structure

```
NN_MODULE_NAME/
│
├── README.md
├── 01_TOPIC.md
├── 01_TOPIC.sql
└── ...
```
```

### 7. Recommended Learning Order

Explain why topics are in this sequence.

```markdown
## 📌 Recommended Learning Order

Each topic builds on the previous one:

```
1. Topic One → foundation
2. Topic Two → builds on one
3. Topic Three → combines one and two
```
```

### 8. Skills Developed

List the practical capabilities gained.

```markdown
## 🧠 Skills Developed

Working through this module strengthens your ability to:

- Skill one
- Skill two
- Skill three
```

### 9. Real-World Applications

Show who uses these skills and how.

```markdown
## 💼 Real-World Applications

These skills are used daily by:

`Data Analysts` · `Analytics Engineers` · `Backend Developers`

**Typical use cases:**
- Use case one
- Use case two
```

### 10. Best Practices

Common approaches and anti-patterns.

```markdown
## 💡 Best Practices

- ✅ Do this because...
- ❌ Don't do this because...
```

### 11. Prerequisites

What must be completed first.

```markdown
## 🎯 Prerequisites

Completion of [Module Name](../NN_MODULE/) or equivalent knowledge.
```

### 12. How to Use This Module

Step-by-step instructions.

```markdown
## 🛠 How to Use This Module

1. Read the `.md` file for a topic
2. Run the matching `.sql` file
3. Modify and experiment
4. Attempt the practice problems
```

### 13. Next Section

Link to the following module.

```markdown
## 🚀 Next Section

Once you've completed this module, continue to:

➡️ **[Module Name](../NN_MODULE/)** — description
```

---

## SQL File Standards

Every SQL file must have:

### 1. File Header Comment

```sql
-- =============================================================================
-- MODULE: NN - Module Name
-- CONCEPT: Concept Name
-- BUSINESS CONTEXT: What real problem does this solve?
-- =============================================================================
```

### 2. Database Context

```sql
-- DATASET: Assumed to be loaded in the current database
-- TABLES USED: employees, departments, locations
```

### 3. Scenario and Business Objective

```sql
-- SCENARIO: Find employees earning above the company average
-- BUSINESS OBJECTIVE: Identify high-earner retention risks
```

### 4. Question(s) to Answer

```sql
-- QUESTIONS:
-- 1. How many employees earn above the company average salary?
-- 2. What is the average salary by department for these high earners?
```

### 5. Annotated Query

```sql
SELECT
    dep.department_name,
    COUNT(emp.employee_id) AS high_earner_count,
    AVG(emp.salary) AS avg_high_earner_salary
FROM employees emp
INNER JOIN departments dep ON emp.dept_id = dep.dept_id
WHERE emp.salary > (
    -- Subquery: Calculate company-wide average
    SELECT AVG(salary) FROM employees
)
GROUP BY dep.department_name
ORDER BY avg_high_earner_salary DESC;
```

### 6. Expected Output

```sql
-- EXPECTED OUTPUT:
-- department_name  | high_earner_count | avg_high_earner_salary
-- Sales            | 5                 | 95000.00
-- Engineering      | 8                 | 105000.00
-- Management       | 3                 | 120000.00
```

### 7. Performance Notes (if applicable)

```sql
-- PERFORMANCE NOTES:
-- - Ensure salary column is indexed for subquery performance
-- - This query scans the entire employees table once; acceptable for <1M rows
-- - For larger tables, materialize the average in a CTE
```

### 8. Interview Discussion Points

```sql
-- INTERVIEW FOLLOW-UPS:
-- Q: What if we wanted employees earning above their department average?
--    A: Move the subquery into a window function (see Module 07)
-- Q: How would you handle NULL salaries?
--    A: Add WHERE emp.salary IS NOT NULL
-- Q: What's the performance impact of the subquery?
--    A: One full table scan; consider materializing if running repeatedly
```

### 9. Practice Variations

```sql
-- PRACTICE VARIATIONS:
-- 1. Find employees below the company average salary
-- 2. Find employees above their department's average salary
-- 3. Show the difference between each employee's salary and the average
```

---

## Business Example Standards

### Avoid Toy Datasets

Never use artificial examples like:
- `users` table with 5 rows
- `products` table with generic "Product A", "Product B"
- Nonsensical business logic

### Use Realistic Industries

Each example should represent a real business domain:

| Industry | Example Scenario | Tables |
|----------|-----------------|--------|
| **HR** | Employee hiring, retention, compensation | employees, departments, salaries |
| **E-commerce** | Customer orders, repeat purchases | customers, orders, order_items, products |
| **Sales** | Sales reps, territories, quotas | sales_reps, territories, deals |
| **Finance** | Budget planning, expense tracking | budgets, expenses, cost_centers |
| **Healthcare** | Patient treatments, provider networks | patients, providers, treatments |

### Business Context Before Code

Every query should start with a business question, not syntax.

✅ **Correct**
```markdown
## Scenario

You work for a mid-market e-commerce company. The VP of Sales wants to identify
customers who have purchased in the last 6 months but are at risk of churning
(no purchases in the last 30 days). Marketing needs to run a retention campaign.

## Question

Which customers purchased in the last 6 months but have not purchased in the
last 30 days? Show their customer ID, total spend, and most recent purchase date.

## Solution

```sql
SELECT
    cust.customer_id,
    cust.customer_name,
    SUM(ord.order_total) AS total_spend_6m,
    MAX(ord.order_date) AS most_recent_purchase
FROM customers cust
INNER JOIN orders ord ON cust.customer_id = ord.customer_id
WHERE ord.order_date >= DATEADD(month, -6, GETDATE())
GROUP BY cust.customer_id, cust.customer_name
HAVING MAX(ord.order_date) < DATEADD(day, -30, GETDATE())
ORDER BY total_spend_6m DESC;
```
```

❌ **Incorrect**
```markdown
## SELECT with WHERE and GROUP BY

```sql
SELECT customer_id, SUM(amount) FROM orders WHERE date > '2024-01-01' GROUP BY customer_id;
```
```

---

## Naming Conventions

### Folders

- **Numbered modules**: `NN_MODULE_NAME` (zero-padded, uppercase after number)
  - ✅ `00_SAMPLE_DATABASE`, `01_FUNDAMENTALS`, `17_SQL_INTERVIEW_QUESTIONS`
  - ❌ `0_fundamentals`, `001_Fundamentals`, `01_fundamentals`

- **Support directories**: lowercase with underscores
  - ✅ `datasets`, `resources`, `cheatsheets`, `exercises`, `projects`
  - ❌ `DataSets`, `Resources`, `Cheat-sheets`

### Files

- **Module concept files**: `NN_TOPIC_NAME.md` and `NN_TOPIC_NAME.sql`
  - ✅ `01_SELECT.md`, `02_WHERE.sql`, `17_INTERVIEW_QUESTIONS.md`
  - ❌ `01_select.md`, `Select.md`, `module_select.sql`

- **Dataset files**: `schema.sql`, `seed_data.sql`, `README.md`
- **Workflow files**: kebab-case (`.github/workflows/validate-sql.yml`)

### SQL Identifiers

#### Tables

- **Names**: Plural, lowercase, underscores
  - ✅ `employees`, `order_items`, `customer_payments`
  - ❌ `employee`, `order items`, `Customer_Payments`

#### Columns

- **Names**: Singular, lowercase, underscores, descriptive
  - ✅ `employee_id`, `order_date`, `customer_name`, `total_amount`
  - ❌ `empid`, `odate`, `cname`, `amt`

- **Special types**:
  - IDs: suffix with `_id` (`employee_id`, `customer_id`)
  - Dates: prefix with verb or suffix with `_date` (`hire_date`, `start_date`, `created_at`)
  - Flags/booleans: prefix with `is_` or `has_` (`is_active`, `has_license`)
  - Money: suffix with `_amount` (`salary_amount`, `total_amount`)

#### Table Aliases

- **Format**: 2–3 letter abbreviation, not single letters
  - ✅ `emp` for `employees`, `cust` for `customers`, `ord` for `orders`
  - ❌ `e`, `c`, `o`
  - ❌ `employee_alias`, `t1`, `a`

#### CTEs and Subqueries

- **Names**: Descriptive noun or action, lowercase with underscores
  - ✅ `active_employees`, `monthly_totals`, `high_value_customers`
  - ❌ `cte1`, `sub_query`, `tmp`

### Comments and Annotations

- Use full sentences, not fragments
- Start with a capital letter
- Explain the *why*, not the *what*

✅ **Correct**
```sql
-- Calculate 5% commission only for orders exceeding $10k threshold
SELECT employee_id, amount * 0.05 AS commission
FROM sales
WHERE amount > 10000;
```

❌ **Incorrect**
```sql
-- multiply by 0.05
SELECT employee_id, amount * 0.05 AS commission
FROM sales
WHERE amount > 10000;
```

---

## Commenting Standards

### Header Comments

File-level comments explain the module, concept, and business context.

```sql
-- =============================================================================
-- MODULE: 07 - Window Functions
-- CONCEPT: ROW_NUMBER() and Ranking
-- BUSINESS CONTEXT: Employee salary ranking and salary band analysis
-- =============================================================================
```

### Purpose Comments

Before each query, explain what it does.

```sql
-- Identify the highest-paid employee in each department
SELECT
    department_id,
    employee_id,
    employee_name,
    salary,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank
FROM employees;
```

### Performance Comments

Note performance implications for scalability.

```sql
-- WARNING: This subquery scans the entire employees table.
-- For tables > 1M rows, consider materializing this in a CTE.
SELECT
    employee_id,
    salary,
    (SELECT AVG(salary) FROM employees) AS avg_salary
FROM employees;
```

### Edge Case Comments

Explain how NULLs, duplicates, or special values are handled.

```sql
-- NOTE: Uses IS NULL instead of = NULL
-- NULL comparisons require IS NULL; = NULL always returns unknown
SELECT
    employee_id,
    employee_name,
    commission_rate
FROM employees
WHERE commission_rate IS NULL;
```

### Database-Specific Comments

Note when syntax is database-specific.

```sql
-- MySQL SUBSTRING function
-- In PostgreSQL, use SUBSTR(email, 1, POSITION('@' IN email) - 1)
SELECT
    employee_id,
    SUBSTRING(email, 1, POSITION('@' IN email) - 1) AS email_prefix
FROM employees;
```

---

## Documentation Writing Style

### Tone and Voice

- **Professional**: Use complete sentences, correct grammar
- **Objective**: Avoid marketing language and hype
- **Clear**: Explain technical concepts without jargon when possible
- **Respectful**: Assume readers are intelligent but may be new to SQL

✅ **Correct**
> The WHERE clause filters individual rows before aggregation. If you need to filter groups *after* aggregation, use HAVING instead.

❌ **Incorrect**
> WHERE is awesome for filtering! HAVING is for grouping (sort of). They're kinda similar but different lol.

### Active Voice

Use active voice. State the subject performing the action.

✅ **Correct**
> The query returns employees hired in 2024.

❌ **Incorrect**
> Employees hired in 2024 are returned by the query.

### Present Tense

Use present tense for explanations.

✅ **Correct**
> SELECT retrieves columns from a table. WHERE filters rows based on conditions.

❌ **Incorrect**
> SELECT will retrieve columns from a table. WHERE would filter rows.

### Avoid Unnecessary Marketing

- No emojis outside of badges and section headers
- No exclamation points for emphasis
- No "amazing," "powerful," "incredible"
- Be direct and honest

✅ **Correct**
> This approach is more efficient because it avoids a full table scan.

❌ **Incorrect**
> This amazing approach is INCREDIBLY efficient because it avoids a full table scan!!!

### Consistent Terminology

Use the same term for the same concept throughout.

- Not "join" and "link" — pick one
- Not "filter" and "select" for the same action — pick one
- Not "tables" and "relations" in the same context

### Avoid Assumed Knowledge

Assume readers know SQL syntax after Module 01, but do not assume understanding of concepts.

✅ **Correct**
> Window functions apply an aggregate function to a subset of rows (the "window") while keeping individual row results, unlike GROUP BY which collapses rows.

❌ **Incorrect**
> Window functions are like GROUP BY but they don't collapse rows.

---

## Pull Request Checklist

Before opening a pull request, verify:

### Content Quality

- [ ] Concept is explained clearly before code
- [ ] SQL answers a real business question
- [ ] All queries run without error on the target dataset
- [ ] Examples are based on realistic data, not toy examples
- [ ] Edge cases (NULLs, duplicates) are considered or noted

### Formatting

- [ ] SQL is formatted according to standards (uppercase keywords, 4-space indents)
- [ ] Markdown heading hierarchy is correct
- [ ] Code blocks specify the language (sql, bash, etc.)
- [ ] No unnecessary spacing or alignment issues
- [ ] Tables use proper markdown format

### Documentation

- [ ] README includes all required sections
- [ ] Comments explain *why*, not *what*
- [ ] Links are correct and point to valid resources
- [ ] No broken cross-references to other modules
- [ ] Database-specific syntax has noted alternatives

### Naming and Standards

- [ ] Files follow naming conventions (NN_TOPIC_NAME.sql)
- [ ] Variables and aliases follow standards (descriptive, not single letters)
- [ ] Column names match the actual schema
- [ ] Module README links to concept files are correct

### No Duplication

- [ ] Concept is not explained in another module
- [ ] SQL pattern is not repeated elsewhere
- [ ] Links reference the original explanation, not duplicates

### Maintainability

- [ ] README updated to reflect new content
- [ ] ROADMAP.md status updated
- [ ] CHANGELOG.md updated with the change
- [ ] No breaking changes to existing modules

---

## Contributor Checklist

Before starting work on a module or contribution:

### New Module Checklist

- [ ] Module number is available in ROADMAP.md
- [ ] Module logically fits in the sequence (check ROADMAP.md)
- [ ] Read a similar completed module (e.g., 01_FUNDAMENTALS) as a template
- [ ] Read STYLE_GUIDE.md (this file) in full
- [ ] Identified the target dataset(s)

### Adding to an Existing Module

- [ ] Read the existing module's README to understand scope
- [ ] Reviewed existing concept files for tone and format
- [ ] Verified the new concept does not duplicate existing content
- [ ] Identified where in the module this concept logically fits
- [ ] Prepared examples using the same dataset as the module

### Fixing or Improving Content

- [ ] Identified the specific issue (broken link, unclear explanation, incorrect SQL)
- [ ] Verified the fix does not introduce new issues
- [ ] Tested SQL changes against the actual database
- [ ] Updated cross-references if applicable

---

## Review Checklist

Maintainers use this checklist when reviewing PRs:

### Consistency

- [ ] Format matches STYLE_GUIDE.md
- [ ] Tone and voice match existing modules
- [ ] Naming conventions are followed
- [ ] No deviations from established patterns

### Correctness

- [ ] SQL executes without error on the target dataset
- [ ] Results are accurate for the stated business question
- [ ] Edge cases are handled or noted
- [ ] Comments are accurate

### Completeness

- [ ] All required sections present (README, concept files, SQL files)
- [ ] Links are valid and point to correct locations
- [ ] Module README updated if this is a new module
- [ ] ROADMAP.md updated if this is a new module
- [ ] CHANGELOG.md updated

### Quality

- [ ] Explanation is clear and at appropriate level for target audience
- [ ] Examples are realistic, not toy data
- [ ] Best practices are followed
- [ ] Performance implications are noted
- [ ] No unnecessary duplication

### Maintainability

- [ ] Future contributors can easily understand and extend
- [ ] Standards are consistent with the rest of the repository
- [ ] Opportunities to link related concepts are captured

---

## Summary

Following this style guide ensures:

1. **Consistency**: Every module and query feels part of one resource
2. **Clarity**: Readers know exactly what to expect
3. **Quality**: Production-ready code and documentation from the start
4. **Scalability**: New contributors can follow the guide without guessing
5. **Maintenance**: Future maintainers understand the repository structure and standards

When in doubt, review similar completed modules or ask in the PR.

---

<p align="center">
  <i>This guide is the single source of truth for standards. For questions or proposed changes, open an <a href="https://github.com/theammarngp-makes/SQL-Engineering-Handbook/issues">issue</a> or start a <a href="https://github.com/theammarngp-makes/SQL-Engineering-Handbook/discussions">discussion</a>.</i>
</p>
