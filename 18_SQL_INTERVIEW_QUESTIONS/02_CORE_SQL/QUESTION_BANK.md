[← Level 0](../01_FOUNDATIONS/QUESTION_BANK.md) · [Module Home](../README.md) · Level 1 (of 0–9)

# Level 1 — Core SQL

Pilot set: 16 of ~60 target questions.

---

## Q006 — Department Headcount with Zero-Count Departments

**Difficulty:** 🟡 Intermediate
**Category:** Joins, Aggregation
**Type:** A — Write SQL
**Related Modules:** [`02_Aggregations`](../../02_Aggregations), [`03_Joins`](../../03_Joins)

### Problem
List every department and its headcount, including departments with no employees (headcount 0).

### Expected SQL
```sql
SELECT d.dept_name, COUNT(e.emp_id) AS headcount
FROM departments d
LEFT JOIN employes e ON e.dept_id = d.dept_id
GROUP BY d.dept_name;
```

### Explanation
`LEFT JOIN` preserves every `departments` row even with no match; `COUNT(e.emp_id)` (not `COUNT(*)`) correctly returns 0 for unmatched departments because the joined `emp_id` is NULL, and `COUNT` ignores NULLs.

### Common Mistake
Using `COUNT(*)` instead — a LEFT JOIN with no match still produces one row (NULLs in right-hand columns), so `COUNT(*)` reports headcount 1, not 0, for every empty department. One of the most common real production bugs in staffing dashboards.

### Interviewer Follow-Up
"How would this query behave with INNER JOIN instead? What silently disappears?"

### Senior-Level Extension
"Add a filter for 'departments with fewer than 3 employees' — requires HAVING, not WHERE."

---

## Q007 — IN vs. EXISTS with NULLs

**Difficulty:** 🟠 Advanced
**Category:** Subqueries
**Type:** F — Compare Approaches
**Related Modules:** [`04_Subqueries`](../../04_Subqueries), [`16_QUERY_OPTIMIZATION`](../../16_QUERY_OPTIMIZATION)

### Problem
```sql
SELECT emp_name FROM employes
WHERE emp_id NOT IN (SELECT manager_id FROM employes);
```
Reported to return zero rows. Diagnose it.

### Explanation
`manager_id` is NULL for top-level managers. If the subquery result contains any NULL, `NOT IN` evaluates to UNKNOWN for every row — `NOT UNKNOWN` is still UNKNOWN, never TRUE. The whole WHERE clause returns nothing.

### Fix
```sql
SELECT emp_name FROM employes e
WHERE NOT EXISTS (SELECT 1 FROM employes m WHERE m.manager_id = e.emp_id);
```

### Interviewer Follow-Up
"Does the same trap apply to plain IN (not NOT IN)?" (No — only the negated form breaks entirely.)

### Senior-Level Extension
"How would you find every place in a legacy codebase where this bug might already exist?"

---

## Q008 — UNION vs. UNION ALL Correctness

**Difficulty:** 🟡 Intermediate
**Category:** Set Operators
**Type:** F — Compare Approaches
**Related Modules:** [`13_SET_OPERATORS`](../../13_SET_OPERATORS)

### Problem
A report combining recent hires and department-change lists (overlap possible) uses `UNION ALL`. Total headcount is inflated. Why, and what's the fix?

### Explanation
`UNION ALL` doesn't deduplicate — an employee in both source sets is counted twice. `UNION` removes exact duplicate rows, at the cost of a sort/hash dedup pass.

### Interviewer Follow-Up
"If overlap is expected and intentional, when is UNION ALL actually the CORRECT choice, not just the faster one?"

---

## Q009 — CTE Readability vs. Correctness

**Difficulty:** 🟡 Intermediate
**Category:** CTEs
**Type:** C — Debug SQL
**Related Modules:** [`06_CTEs`](../../06_CTEs)

### Problem
```sql
WITH high_earners AS (SELECT emp_id, salary FROM employes WHERE salary > 80000),
     high_earners AS (SELECT emp_id FROM high_earners WHERE salary > 100000)
SELECT * FROM high_earners;
```

### Explanation
Two CTEs share the same name — a naming collision, not a logic error. Most engines raise a syntax error or silently shadow the first definition. Rename the second (e.g. `very_high_earners`).

### Interviewer Follow-Up
"Why is this bug more likely in a large, refactored query originally written by different people?"

---

## Q010 — CASE Expression in Aggregation

**Difficulty:** 🟡 Intermediate
**Category:** CASE, Conditional Aggregation
**Type:** A — Write SQL
**Related Modules:** [`05_CASE_WHEN`](../../05_CASE_WHEN)

### Problem
Report per department: employees hired before 2023 and hired 2023+, as two columns in one row.

### Expected SQL
```sql
SELECT dept_id,
    COUNT(CASE WHEN hire_date < '2023-01-01' THEN 1 END) AS hired_before_2023,
    COUNT(CASE WHEN hire_date >= '2023-01-01' THEN 1 END) AS hired_2023_or_later
FROM employes GROUP BY dept_id;
```

### Explanation
`CASE` inside `COUNT()` returns NULL for non-matching rows (implicit ELSE NULL); `COUNT` ignores NULLs — so each `COUNT(CASE...)` counts only its own bucket, letting one GROUP BY produce multiple conditional counts (a pivot pattern).

### Interviewer Follow-Up
"How would this change for a SUM of salaries instead of a COUNT, for the same two buckets?"

---

## Q054 — Self-Join to Find a Manager's Name

**Difficulty:** 🟡 Intermediate
**Category:** Self-Join
**Type:** A — Write SQL

### Problem
List each employee's name alongside their manager's name (not just
`manager_id`), including employees who have no manager.

### Expected SQL
```sql
SELECT e.emp_name, m.emp_name AS manager_name
FROM employes e
LEFT JOIN employes m ON e.manager_id = m.emp_id;
```

### Explanation
A self-join treats the same table as two logical roles via aliases —
`e` for the employee row, `m` for the manager row. `LEFT JOIN` (not
`INNER JOIN`) is required so employees with `manager_id IS NULL`
(top-level staff) still appear, with `manager_name` as NULL rather than
being dropped from the result entirely.

### Interviewer Follow-Up
"How would this query need to change to show the manager's manager as
well — a second level up?"

---

## Q055 — HAVING vs. WHERE on the Same Query

**Difficulty:** 🟡 Intermediate
**Category:** HAVING, WHERE
**Type:** C — Debug SQL

### Problem
```sql
SELECT dept_id, AVG(salary) AS avg_sal
FROM employes
WHERE AVG(salary) > 60000
GROUP BY dept_id;
```
This fails. Fix it and explain why the original was invalid.

### Explanation
`WHERE` filters individual rows before grouping/aggregation happens, so
it cannot reference an aggregate result that doesn't exist yet at that
stage of logical processing. The aggregate condition belongs in
`HAVING`, which filters groups after aggregation:
```sql
SELECT dept_id, AVG(salary) AS avg_sal
FROM employes GROUP BY dept_id HAVING AVG(salary) > 60000;
```

### Interviewer Follow-Up
"Could you also filter individual employee salaries before grouping, in
the same query? Where would that condition go?"

---

## Q056 — Three-Table Join with Aggregation

**Difficulty:** 🟠 Advanced
**Category:** Joins, Aggregation
**Type:** A — Write SQL

### Problem
For each city, report the average salary of employees working in
departments located there, ordered highest average first.

### Expected SQL
```sql
SELECT l.city, AVG(e.salary) AS avg_salary
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
GROUP BY l.city
ORDER BY avg_salary DESC;
```

### Explanation
The join must resolve the full chain before grouping can happen at the
`city` grain, since `city` doesn't live on `employes` directly. A common
mistake is grouping by `location_id` while selecting `city` without it
being functionally dependent in the engine's eyes — some engines
(strict PostgreSQL) will reject that; grouping by the actual selected
non-aggregated column avoids the ambiguity.

### Interviewer Follow-Up
"What happens to this result if a location has departments with no
employees at all?"

---

## Q057 — Correlated Subquery in the SELECT List

**Difficulty:** 🟠 Advanced
**Category:** Correlated Subquery
**Type:** F — Compare Approaches
**Related Modules:** [`04_Subqueries`](../../04_Subqueries)

### Problem
```sql
SELECT emp_name, dept_id,
    (SELECT COUNT(*) FROM employes e2 WHERE e2.dept_id = e1.dept_id) AS dept_size
FROM employes e1;
```
This works but performs poorly at scale. What's happening, and what's
the better pattern?

### Explanation
The subquery re-executes once per outer row — for 50 employees that's
50 scans of `employes`, and it grows non-linearly as the table grows.
A window function computes the same result in a single pass:
```sql
SELECT emp_name, dept_id,
    COUNT(*) OVER (PARTITION BY dept_id) AS dept_size
FROM employes;
```

### Interviewer Follow-Up
"Are there cases where a correlated subquery genuinely can't be
rewritten as a window function? Name one."

---

## Q058 — COALESCE Inside an Aggregate

**Difficulty:** 🟡 Intermediate
**Category:** NULL Handling, Aggregation
**Type:** A — Write SQL
**Related Modules:** [`11_NULL_HANDLING_AND_DATA_CLEANING`](../../11_NULL_HANDLING_AND_DATA_CLEANING)

### Problem
Report the total salary per department, treating any NULL `salary`
values as `0` rather than having them silently excluded from the sum's
row count context.

### Expected SQL
```sql
SELECT dept_id, SUM(COALESCE(salary, 0)) AS total_salary
FROM employes GROUP BY dept_id;
```

### Explanation
`SUM()` already ignores NULLs internally, so for a pure total the
`COALESCE` is often redundant — but it becomes essential the moment the
NULL needs to participate in a larger expression (e.g.
`SUM(COALESCE(salary,0) * bonus_multiplier)`), where an untreated NULL
would poison the whole row's calculation via NULL propagation.

### Interviewer Follow-Up
"Why doesn't `AVG(salary)` need the same `COALESCE` to get a correct
average of the non-NULL salaries?"

---

## Q081 — INNER JOIN vs. LEFT JOIN with a Filter

**Difficulty:** 🟡 Intermediate
**Category:** Joins, WHERE
**Type:** C — Debug SQL

### Problem
```sql
SELECT e.emp_name, d.dept_name
FROM employes e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Sales';
```
The intent was "show all employees, and their department name if it's
Sales, otherwise NULL." Instead, employees not in Sales disappear
entirely. Fix it.

### Explanation
Putting the join-dependent filter in `WHERE` runs it *after* the
`LEFT JOIN`, so it discards every row where `d.dept_name` isn't
`'Sales'` — including the NULLs the `LEFT JOIN` was specifically there
to preserve. This silently turns the `LEFT JOIN` back into an
`INNER JOIN`, one of the most common join bugs in production code.
Fix by moving the condition into the join itself:
```sql
SELECT e.emp_name, d.dept_name
FROM employes e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.dept_name = 'Sales';
```

### Interviewer Follow-Up
"How would you write this if you specifically wanted only employees in
the Sales department — would you still use `LEFT JOIN`?"

---

## Q085 — Subquery in FROM (Derived Table) vs. CTE


**Difficulty:** 🟡 Intermediate
**Category:** CTEs, Derived Tables
**Type:** F — Compare Approaches

### Problem
```sql
SELECT * FROM (
    SELECT dept_id, AVG(salary) AS avg_sal FROM employes GROUP BY dept_id
) dept_avg WHERE avg_sal > 60000;
```
versus the same logic written as a CTE. Functionally identical here —
so why would a candidate prefer one over the other?

### Explanation
A derived table and a CTE are logically equivalent for a single
reference like this — the difference is almost entirely readability and
reuse. A CTE named clearly (`WITH dept_avg AS (...)`) reads top-to-bottom
and can be referenced multiple times in the outer query without
repeating the subquery; a derived table nested inline gets harder to
read as queries grow, especially when nested several levels deep.
Historically some engines materialized CTEs differently from derived
tables, but modern optimizers (MySQL 8+, PostgreSQL) generally treat
them the same for planning purposes — verify with `EXPLAIN` rather than
assuming either is inherently faster.

### Interviewer Follow-Up
"If you needed the same `dept_avg` result referenced three times in one
query, which form would you pick, and why?"

---

## Q086 — GROUP BY with an Expression, Not Just a Column

**Difficulty:** 🟡 Intermediate
**Category:** GROUP BY, Date Functions
**Type:** A — Write SQL

### Problem
Report the number of employees hired in each calendar year.

### Expected SQL
```sql
SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS hires
FROM employes GROUP BY YEAR(hire_date)
ORDER BY hire_year;
```
*(`YEAR(hire_date)` is the more idiomatic MySQL form here;
`EXTRACT(YEAR FROM hire_date)` is also valid MySQL and behaves
identically.)*

### Explanation
`GROUP BY` isn't limited to bare column names — it groups by the result
of any expression, as long as the same expression appears in the
`SELECT` list (or the engine can otherwise resolve the dependency). Each
distinct `hire_year` value becomes its own group, exactly as a raw
column would. Worth noting for this specific form: since every row's
`YEAR(hire_date)` must be computed before grouping can happen, an
ordinary index on plain `hire_date` doesn't automatically turn this
particular aggregate into an indexed lookup — verify the actual access
plan with `EXPLAIN` rather than assuming either way, since a
functional/expression index on `YEAR(hire_date)` (MySQL 8.0.13+) could
change that.

### Interviewer Follow-Up
"Could you get the same result using `YEAR(hire_date)` in a WHERE
clause on an indexed `hire_date` column, and would that be SARGable?"

---

## Q093 — Join Fan-Out Silently Inflates a SUM

**Difficulty:** 🟠 Advanced
**Category:** Joins, Grain
**Type:** C — Debug SQL

### Scenario
An `assignments(assignment_id, emp_id, dept_id, start_date, end_date)`
table records that an employee can be assigned to a department more
than once over time (see Q029). An employee currently has 3 historical
assignment rows to the same department.

### Problem
```sql
SELECT d.dept_name, SUM(e.salary) AS total_salary
FROM departments d
JOIN employes e ON d.dept_id = e.dept_id
JOIN assignments a ON a.emp_id = e.emp_id AND a.dept_id = d.dept_id
GROUP BY d.dept_name;
```
Finance says this department's total is roughly 3x too high. Diagnose
it and fix the query.

### Explanation
Joining `employes` to `assignments` on `emp_id` matches **each** of that
employee's 3 assignment rows, producing 3 duplicate `employes` rows in
the joined result before `SUM` ever runs — the aggregate then sums the
same salary 3 times without any error, because nothing about
duplicated rows looks structurally wrong to the engine. The fix is to
never aggregate `employes.salary` across a join that can multiply
`employes` rows. For this request — total salary per department — the
`assignments` join is not needed at all, so the simplest fix is to drop
it. If `assignments` is genuinely needed for some other column,
pre-aggregate `employes` by department first (a subquery/CTE with no
`assignments` join in it), then bring `assignments` in afterward only
for whatever it's actually needed for.
```sql
SELECT d.dept_name, dept_totals.total_salary
FROM departments d
JOIN (SELECT dept_id, SUM(salary) AS total_salary FROM employes GROUP BY dept_id) dept_totals
  ON dept_totals.dept_id = d.dept_id;
```
(Equivalent and simpler when `assignments` isn't needed:
`SELECT d.dept_name, SUM(e.salary) FROM departments d JOIN employes e
ON e.dept_id = d.dept_id GROUP BY d.dept_name;`)

### Interviewer Follow-Up
"Before you had Finance's tip-off, what would you check first to
confirm the row count coming out of the join is inflated, rather than
guessing at the fix directly?"

---

## Q094 — GROUP BY Alias vs. WHERE Alias

**Difficulty:** 🟡 Intermediate
**Category:** Logical Processing Order, Aliases
**Type:** C — Debug SQL

### Problem
```sql
SELECT dept_id, salary * 1.1 AS adjusted_salary
FROM employes
WHERE adjusted_salary > 60000
GROUP BY dept_id, adjusted_salary;
```
The `GROUP BY` reference to `adjusted_salary` works in MySQL; the
`WHERE` reference to the same alias fails. Why the asymmetry?

### Explanation
In logical processing order, `WHERE` filters rows *before* the `SELECT`
list is evaluated, so the alias `adjusted_salary` is not available there
and the reference fails (standard SQL rejects it). That order is the same
in every engine and is not changed by the `GROUP BY` behavior below.

The asymmetry comes from *alias-resolution rules*, not from a different
execution order: MySQL permits a `SELECT`-list alias to be referenced in
`GROUP BY` (and `HAVING`) as a dialect-specific extension to standard
SQL. It does **not** mean `GROUP BY` logically executes after `SELECT`;
it means the parser resolves the alias name for you. Because this is an
extension, don't rely on it for portable SQL — other engines may reject
it or resolve it differently. The fix for `WHERE` is to repeat the
expression itself: `WHERE salary * 1.1 > 60000`.

### Interviewer Follow-Up
"Would `HAVING adjusted_salary > 60000` work here instead of repeating
the expression? Why does `HAVING` behave differently from `WHERE`?"

---

## Q095 — NOT and the Law of Excluded Middle

**Difficulty:** 🟠 Advanced
**Category:** NULL Handling, Boolean Logic
**Type:** B — Predict Output
**Related Modules:** [`11_NULL_HANDLING_AND_DATA_CLEANING`](../../11_NULL_HANDLING_AND_DATA_CLEANING)

### Problem
```sql
SELECT emp_name FROM employes
WHERE manager_id > 5 OR NOT (manager_id > 5);
```
In classical logic, `x OR NOT x` is always true — one of the two must
hold. For an employee with `manager_id IS NULL` (a top-level manager),
does this row appear in the result?

### Explanation
No — and this is exactly the three-valued-logic trap the "always true"
intuition misses. `manager_id > 5` on a NULL value evaluates to
UNKNOWN, not FALSE. Negating UNKNOWN gives UNKNOWN back
(`NOT UNKNOWN = UNKNOWN` — this part of three-valued logic is internally
consistent: negating twice still returns you to UNKNOWN, so double
negation isn't what breaks here). What breaks is the **law of excluded
middle**: `UNKNOWN OR UNKNOWN` evaluates to UNKNOWN, not TRUE, because
`OR` only becomes TRUE when at least one side is *known* to be true —
two UNKNOWNs don't combine into a certainty. So a condition and its own
negation can simultaneously fail to match the same row, something that
is structurally impossible in classical two-valued logic. Relying on
"one of these two mutually exclusive-looking branches must catch every
row" is unsafe the moment a compared column can be NULL.

### Interviewer Follow-Up
"How would you rewrite the `WHERE` clause so a NULL `manager_id` row is
guaranteed to be included, without changing what happens to the
non-NULL rows?"

---

[← Level 0](../01_FOUNDATIONS/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 2 — Analytical SQL](../03_ANALYTICAL_SQL/QUESTION_BANK.md)
