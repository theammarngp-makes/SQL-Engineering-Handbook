[← Module Home](../README.md) · Level 0 (of 0–9)

# Level 0 — SQL Foundations

Pilot set: 10 of ~40 target questions. See [`TAXONOMY_AND_FORMAT.md`](../TAXONOMY_AND_FORMAT.md) for the question schema and [`../00_Schema`](../../00_Schema) for the shared dataset used below.

---

## Q001 — Filter and Sort Department Staff

**Difficulty:** 🟢 Beginner
**Category:** WHERE, ORDER BY
**Type:** A — Write SQL
**Skills Tested:** filtering, sorting, aliasing
**Related Modules:** [`01_Fundamentals`](../../01_Fundamentals)

### Problem
List every employee in department 4, most recently hired first.

### Expected SQL
```sql
SELECT emp_name, hire_date FROM employes
WHERE dept_id = 4 ORDER BY hire_date DESC;
```

### Explanation
`WHERE` filters before sorting; `ORDER BY ... DESC` puts the most recent `hire_date` first — standard logical processing order.

### Common Mistake
Writing `ORDER BY` before `WHERE` — a syntax error, and one of the most common typos under interview time pressure.

### Interviewer Follow-Up
"What would change if you wanted the 5 most recent hires only?"

---

## Q002 — NULL in a Comparison

**Difficulty:** 🟢 Beginner
**Category:** NULL basics
**Type:** B — Predict Output
**Related Modules:** [`11_NULL_HANDLING_AND_DATA_CLEANING`](../../11_NULL_HANDLING_AND_DATA_CLEANING)

### Problem
```sql
SELECT emp_name FROM employes WHERE manager_id != 7;
```
Given a top-level manager (`manager_id IS NULL`) exists, will their row appear?

### Explanation
No — `NULL != 7` evaluates to `UNKNOWN`, not `TRUE`. Rows with NULL in a compared column are excluded by `!=`/`=` entirely, not included as a "doesn't equal" match. This is exactly the misunderstanding behind the `NOT IN` + NULL production bug (see Q007).

### Interviewer Follow-Up
"How would you explicitly include the NULL rows too?"

---

## Q003 — COUNT(*) vs. COUNT(column)

**Difficulty:** 🟢 Beginner
**Category:** Aggregation basics
**Type:** F — Compare Approaches

### Problem
Explain the difference between `COUNT(*)` and `COUNT(manager_id)`.

### Expected Answer
`COUNT(*)` counts every row regardless of NULLs. `COUNT(manager_id)` excludes rows where `manager_id IS NULL` — top-level managers are excluded. `COUNT(*) - COUNT(manager_id)` is a fast NULL audit.

### Interviewer Follow-Up
"Write a single query reporting both counts and the NULL count side by side."

---

## Q004 — Aliasing and Reserved Words

**Difficulty:** 🟢 Beginner
**Category:** Aliases, data types
**Type:** C — Debug SQL

### Problem
```sql
SELECT emp_name, hire_date AS year FROM employes;
```
fails in several engines. Why?

### Explanation
`YEAR` is a reserved word/built-in function name in MySQL and SQL Server. Fix by quoting appropriately for the engine, or better, choosing a non-reserved alias like `hire_year`.

### Interviewer Follow-Up
"Why is picking a non-reserved alias generally the better fix over quoting?"

---

## Q005 — Logical Processing Order

**Difficulty:** 🟡 Intermediate
**Category:** Logical processing order
**Type:** E — Explain SQL

### Problem
```sql
SELECT dept_id, COUNT(*) AS staff_count FROM employes
WHERE hire_date > '2023-01-01' GROUP BY dept_id
HAVING COUNT(*) > 5 ORDER BY staff_count DESC;
```
Why can `HAVING` reference `COUNT(*)` while `WHERE` could not?

### Expected Answer
Logical order: `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`. `WHERE` filters rows before grouping, so it has no aggregate yet. `HAVING` runs after `GROUP BY`, once `COUNT(*)` per group exists.

### Interviewer Follow-Up
"Where does a window function fit into this order?" (After WHERE/GROUP BY/HAVING, alongside SELECT — why you can't reference it directly in the same query's WHERE.)

---

## Q049 — DISTINCT vs. GROUP BY

**Difficulty:** 🟢 Beginner
**Category:** DISTINCT, GROUP BY
**Type:** F — Compare Approaches

### Problem
`SELECT DISTINCT dept_id FROM employes;` and
`SELECT dept_id FROM employes GROUP BY dept_id;` return the same rows here.
When would they stop being equivalent?

### Explanation
They diverge the moment aggregation enters the query. `GROUP BY` can carry
aggregate columns (`COUNT(*)`, `AVG(salary)`) alongside the grouping key;
plain `DISTINCT` cannot express "one row per group, plus a computed
summary" — it only deduplicates the exact row shape selected. Some
engines also optimize them differently (`GROUP BY` may use a hash or
sort-based aggregate plan `DISTINCT` doesn't need), so they aren't
interchangeable performance-wise even in the equivalent case.

### Interviewer Follow-Up
"Rewrite the query to also show each department's headcount — does
`DISTINCT` still work?"

---

## Q050 — Multi-Column ORDER BY Direction

**Difficulty:** 🟢 Beginner
**Category:** ORDER BY
**Type:** B — Predict Output

### Problem
```sql
SELECT emp_name, dept_id, salary FROM employes
ORDER BY dept_id ASC, salary DESC;
```
Describe the exact ordering this produces.

### Explanation
Rows are grouped by ascending `dept_id` first; within each department,
rows are then sorted by descending `salary`. Direction keywords apply
per-column, not to the whole clause — a common misreading is assuming
`DESC` at the end reverses the entire sort rather than just the last key.

### Interviewer Follow-Up
"How would you get the highest earner in each department using only
this ordering, without a window function?"

---

## Q051 — LIKE Wildcards and Index Usage

**Difficulty:** 🟢 Beginner
**Category:** LIKE, Pattern Matching
**Type:** F — Compare Approaches
**Related Modules:** [`15_INDEXES`](../../15_INDEXES)

### Problem
`WHERE emp_name LIKE 'A%'` versus `WHERE emp_name LIKE '%a%'` — both
filter names, but one is SARGable on a standard B-tree index on
`emp_name` and one isn't. Which, and why?

### Explanation
`'A%'` (leading literal) lets the engine seek directly to the `A` range
of a sorted index — SARGable. `'%a%'` (leading wildcard) means a match
could start anywhere in the string, so there's no sorted prefix to seek
on; the engine falls back to scanning every row. This is one of the most
common accidental full-table-scan patterns in production filters.

### Interviewer Follow-Up
"A search feature needs 'contains' matching on names. What's a better
approach than a leading-wildcard `LIKE` at scale?"

---

## Q052 — Three-Table Join Direction

**Difficulty:** 🟢 Beginner
**Category:** JOIN
**Type:** A — Write SQL

### Problem
List each employee's name alongside their department's name and that
department's city, for employees in departments located in `'Nagpur'`.

### Expected SQL
```sql
SELECT e.emp_name, d.dept_name, l.city
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
WHERE l.city = 'Nagpur';
```

### Explanation
The join chain must follow the actual foreign-key path —
`employes → departments → locations` — because `employes` has no direct
reference to `locations`. Joining `employes` straight to `locations`
without the bridging `departments` join isn't possible from the schema
and is a common early mistake when a candidate hasn't traced the
relationships first.

### Interviewer Follow-Up
"How would this query change if some departments had no assigned
location yet?"

---

## Q053 — BETWEEN and Date Range Inclusivity

**Difficulty:** 🟡 Intermediate
**Category:** BETWEEN, Dates
**Type:** C — Debug SQL

### Problem
```sql
SELECT emp_name FROM employes
WHERE hire_date BETWEEN '2023-01-01' AND '2023-12-31';
```
A hire on `2023-12-31 00:00:00` shows up; one at `2023-12-31 14:00:00`
(stored as a `DATETIME`) does not. Why, and how do you fix it?

### Explanation
`BETWEEN` is inclusive on both bounds, but `'2023-12-31'` as a datetime
literal means midnight (`00:00:00`) — anything later that same day is
already past the upper bound. Fix by using a half-open range instead:
`hire_date >= '2023-01-01' AND hire_date < '2024-01-01'`, which is also
safer against precision differences across engines.

### Interviewer Follow-Up
"Why is the half-open pattern generally preferred over `BETWEEN` for
date ranges in production code?"

---

[← Module Home](../README.md) · Next: [Level 1 — Core SQL](../02_CORE_SQL/QUESTION_BANK.md)
