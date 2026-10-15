[← Level 1](../02_CORE_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Level 2 (of 0–9)

# Level 2 — Analytical SQL

Pilot set: 17 of ~80 target questions.

---

## Q011 — Rank Employees by Salary Within Department

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions, Ranking
**Type:** A — Write SQL
**Related Modules:** [`07_Window_Functions`](../../07_Window_Functions)

### Problem
For each department, rank employees by salary, highest first.

### Expected SQL
```sql
SELECT emp_name, dept_id, salary,
    RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS salary_rank
FROM employes;
```

### Explanation
`PARTITION BY dept_id` resets ranking per department; `RANK()` gives tied salaries the same rank and skips the next rank number accordingly.

### Interviewer Follow-Up
"What changes with DENSE_RANK() instead? Walk through a tie example."

### Senior-Level Extension
"Get only the single highest earner per department, ties broken by earliest hire_date."

---

## Q012 — RANK vs. DENSE_RANK vs. ROW_NUMBER

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** F — Compare Approaches

### Problem
Explain the difference for tied salary values `100k, 100k, 90k`.

### Expected Answer
`ROW_NUMBER()`: `1, 2, 3` — ties broken arbitrarily, never repeats. `RANK()`: `1, 1, 3` — ties share a rank, next rank skips ahead. `DENSE_RANK()`: `1, 1, 2` — ties share a rank, no skip.

### Common Mistake
Using ROW_NUMBER() when ties should be visibly equal (e.g. a leaderboard) — silently breaks ties that should be shown as equal.

### Interviewer Follow-Up
"Which would you use for 'top 3 salaries per department including all ties for 3rd'? Why?" (RANK — lets WHERE salary_rank <= 3 naturally include tied boundary values.)

---

## Q013 — Running Total

**Difficulty:** 🟠 Advanced
**Category:** Window Functions
**Type:** A — Write SQL

### Problem
Compute a running total of cumulative headcount by hire date, company-wide.

### Expected SQL
```sql
SELECT emp_name, hire_date,
    COUNT(*) OVER (ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_headcount
FROM employes;
```

### Explanation
The explicit frame makes the running-total behavior unambiguous rather than relying on an implicit default that can vary across engines/versions.

### Interviewer Follow-Up
"What happens if two employees share the exact same hire_date? Is the running count for those rows well-defined?"

---

## Q014 — Gaps and Islands

**Difficulty:** 🔴 Expert
**Category:** Window Functions, Advanced Pattern
**Type:** A — Write SQL

### Schema
`attendance(emp_id, work_date)` — one row per employee per day present.

### Problem
For each employee, find start/end date of every consecutive run ("streak") of work_dates.

### Expected SQL
```sql
WITH numbered AS (
    SELECT emp_id, work_date,
        ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY work_date) AS rn
    FROM attendance
),
grouped AS (
    SELECT emp_id, work_date, DATE_SUB(work_date, INTERVAL rn DAY) AS island_group
    FROM numbered
)
SELECT emp_id, MIN(work_date) AS streak_start, MAX(work_date) AS streak_end, COUNT(*) AS streak_length
FROM grouped GROUP BY emp_id, island_group ORDER BY emp_id, streak_start;
```
*(MySQL: `DATE_SUB(date, INTERVAL rn DAY)`. PostgreSQL equivalent:
`work_date - (rn * INTERVAL '1 day')`.)*

### Explanation
Subtracting a sequential row number (in days) from the actual date produces a constant value for every date in an unbroken run, since both increase by 1 per day within a run. A gap breaks the constant, letting GROUP BY isolate each island.

### Interviewer Follow-Up
"Why does subtracting row number from date work mathematically? Walk through 3 dates, one with a gap."

### Senior-Level Extension
"Adapt this to find the LONGEST streak per employee only, one row per employee."

---

## Q015 — LAG for Period-over-Period Comparison

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** A — Write SQL

### Problem
For each department, show current headcount and change since the prior month (`dept_headcount_snapshot(dept_id, snapshot_month, headcount)`).

### Expected SQL
```sql
SELECT dept_id, snapshot_month, headcount,
    headcount - LAG(headcount) OVER (PARTITION BY dept_id ORDER BY snapshot_month) AS change_from_prior_month
FROM dept_headcount_snapshot;
```

### Explanation
`LAG()` looks back one row within the partition's ordering — the prior month's headcount for the same department — enabling a direct delta without a self-join.

### Interviewer Follow-Up
"What does change_from_prior_month show for each department's very FIRST snapshot row, and why?"

---

## Q016 — Deduplication with ROW_NUMBER

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions, Data Cleaning
**Type:** A — Write SQL
**Related Modules:** [`11_NULL_HANDLING_AND_DATA_CLEANING`](../../11_NULL_HANDLING_AND_DATA_CLEANING)

### Problem
A data import created duplicate `employes` rows per `emp_id` (differing only in hire_date). Keep only the most recent per emp_id.

### Expected Pattern
```sql
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY hire_date DESC) AS rn
    FROM employes
)
SELECT * FROM ranked WHERE rn = 1;
-- converting SELECT rn=1 into a DELETE of rn>1 is the standard dedup pattern;
-- exact DELETE syntax is engine-specific (CTID join on PostgreSQL, self-join
-- on MySQL, ROW_NUMBER CTE DELETE on SQL Server).
```

### Interviewer Follow-Up
"Before running any DELETE, how would you verify your ROW_NUMBER logic is correct without risking data loss?" (Run the SELECT first, review, only then convert to DELETE inside a rollback-able transaction.)

---

## Q059 — NTILE for Salary Quartiles

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** A — Write SQL

### Problem
Split all employees into 4 salary quartiles (1 = lowest-paid quarter,
4 = highest).

### Expected SQL
```sql
SELECT emp_name, salary,
    NTILE(4) OVER (ORDER BY salary) AS salary_quartile
FROM employes;
```

### Explanation
`NTILE(n)` divides the ordered result set into `n` groups as evenly as
possible, assigning each row a bucket number. When the row count isn't
evenly divisible by `n`, the earlier buckets absorb the extra rows — the
distribution is as-even-as-possible, not guaranteed identical.

### Interviewer Follow-Up
"With 50 employees and `NTILE(4)`, how many rows land in each quartile,
and which quartiles get the extras?"

---

## Q060 — FIRST_VALUE with an Explicit Frame

**Difficulty:** 🟠 Advanced
**Category:** Window Functions, Frames
**Type:** C — Debug SQL

### Problem
```sql
SELECT emp_name, dept_id, salary,
    FIRST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY hire_date) AS first_hire_salary,
    LAST_VALUE(salary) OVER (PARTITION BY dept_id ORDER BY hire_date) AS last_hire_salary
FROM employes;
```
`first_hire_salary` looks correct but `last_hire_salary` repeats the
current row's own salary instead of the department's most recent hire.
Why?

### Explanation
The default window frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND
CURRENT ROW` — so `LAST_VALUE` only ever sees up through the current
row, never the true final row of the partition. Fixing it requires an
explicit frame: `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING`. This
default-frame trap is one of the most common `LAST_VALUE` bugs in
production analytics code.

### Interviewer Follow-Up
"Would `MAX(hire_date) OVER (PARTITION BY dept_id)` be a simpler way to
get at the same underlying information here?"

---

## Q061 — PERCENT_RANK vs. CUME_DIST

**Difficulty:** 🟠 Advanced
**Category:** Window Functions
**Type:** F — Compare Approaches

### Problem
Both `PERCENT_RANK()` and `CUME_DIST()` describe an employee's relative
salary standing. What's the actual difference in what they compute?

### Explanation
`PERCENT_RANK()` returns `(rank - 1) / (total_rows - 1)`, always `0` for
the lowest row and `1` for the highest — it measures relative *rank*
position. `CUME_DIST()` returns the fraction of rows with a value
`<= `the current row's, so it measures relative *standing within the
distribution*, and ties all get the same (higher) cumulative fraction
rather than starting at exactly 0.

### Interviewer Follow-Up
"For a dataset with heavy ties in salary, which of the two would you
pick to answer 'what percentile is this employee in', and why?"

---

## Q062 — Multi-Column PARTITION BY

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** A — Write SQL

### Problem
Rank employees by salary within each department AND location
combination (i.e., resetting the rank whenever either changes).

### Expected SQL
```sql
SELECT e.emp_name, d.dept_id, l.location_id, e.salary,
    RANK() OVER (PARTITION BY d.dept_id, l.location_id ORDER BY e.salary DESC) AS salary_rank
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id;
```

### Explanation
`PARTITION BY` accepts multiple columns, treating each unique
combination as its own independent window — the rank resets for every
new `(dept_id, location_id)` pair encountered in the ordered result, not
just for a single column change.

### Interviewer Follow-Up
"Since every department maps to exactly one location here, does
partitioning by both columns actually change the result versus
partitioning by `dept_id` alone?"

---

## Q063 — Moving Average with a ROWS Frame

**Difficulty:** 🟠 Advanced
**Category:** Window Functions, Frames
**Type:** A — Write SQL

### Problem
Compute a 3-hire trailing moving average of salary within each
department, ordered by `hire_date` (current hire plus the 2 before it).

### Expected SQL
```sql
SELECT emp_name, dept_id, hire_date, salary,
    AVG(salary) OVER (
        PARTITION BY dept_id ORDER BY hire_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS trailing_3_avg
FROM employes;
```

### Explanation
`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` defines a physical
row-count frame — exactly 3 rows wide once enough prior rows exist,
narrower at the start of each partition (the first row only averages
itself). This is distinct from a `RANGE` frame, which would group by
value ties on `hire_date` rather than a fixed row count.

### Interviewer Follow-Up
"For the first two hires in a department, how many rows actually go
into their moving average, and is that a bug or expected behavior?"

---

## Q088 — Running Total Reset Per Group

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions, Running Totals
**Type:** C — Debug SQL

### Problem
```sql
SELECT emp_name, dept_id, salary,
    SUM(salary) OVER (ORDER BY emp_id) AS running_total
FROM employes;
```
The intent was a running salary total *within each department*, but
this accumulates across the entire table. Fix it.

### Explanation
Without `PARTITION BY`, the window spans the whole result set, so the
running sum never resets between departments — it just keeps
accumulating row by row regardless of `dept_id`. Adding
`PARTITION BY dept_id` scopes the frame to each department
independently:
```sql
SUM(salary) OVER (PARTITION BY dept_id ORDER BY emp_id) AS running_total
```
Missing `PARTITION BY` is one of the most common window-function bugs —
the query runs without error and looks plausible, which is exactly what
makes it dangerous.

### Interviewer Follow-Up
"How would you verify this bug just by eyeballing the output, without
knowing the expected values in advance?"

---

## Q089 — Top-N Per Group

**Difficulty:** 🟠 Advanced
**Category:** Window Functions, Top-N
**Type:** A — Write SQL

### Problem
Return the top 2 highest-paid employees in each department.

### Expected SQL
```sql
SELECT emp_name, dept_id, salary FROM (
    SELECT emp_name, dept_id, salary,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
    FROM employes
) ranked
WHERE rn <= 2;
```

### Explanation
`ROW_NUMBER()` must be wrapped in an outer query (or a CTE) before
filtering, because window functions are computed at the same logical
stage as `SELECT` — a bare `WHERE rn <= 2` in the same query the window
function is defined in isn't legal, since `WHERE` runs before window
functions are evaluated. `RANK()` is the wrong choice here if the
requirement is genuinely "exactly 2 rows" — `RANK()` would return 3+
rows on a tie for 2nd place.

### Interviewer Follow-Up
"If two employees tie for the department's 2nd-highest salary, should
this query return 2 rows or 3? Does the current query already match
that answer?"

---

## Q090 — Percent of Department Total

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** A — Write SQL

### Problem
For each employee, show what percentage of their department's total
salary budget their own salary represents.

### Expected SQL
```sql
SELECT emp_name, dept_id, salary,
    ROUND(100.0 * salary / SUM(salary) OVER (PARTITION BY dept_id), 1) AS pct_of_dept
FROM employes;
```

### Explanation
`SUM(salary) OVER (PARTITION BY dept_id)` computes each department's
total once per partition without collapsing the result to one row per
department — every employee row still shows individually, alongside the
partition-wide total needed for the percentage. This is the pattern
that replaces "compute the total in a subquery, then join it back,"
condensing two logical steps into one window function call.

### Interviewer Follow-Up
"Would this query need to change if you wanted the percentage of the
*company-wide* total instead of the department's?"

---

## Q091 — Detecting Consecutive Salary Increases

**Difficulty:** 🟠 Advanced
**Category:** Window Functions, Gaps and Islands
**Type:** A — Write SQL
**Related Modules:** [`07_Window_Functions`](../../07_Window_Functions)

### Problem
Given a `salary_history(emp_id, effective_date, salary)` table (one row
per raise), find employees who received at least 3 consecutive raises
(each strictly higher than the last, with no decrease in between).

### Expected SQL
```sql
WITH changes AS (
    SELECT emp_id, effective_date, salary,
        CASE WHEN salary > LAG(salary) OVER (PARTITION BY emp_id ORDER BY effective_date)
             THEN 1 ELSE 0 END AS is_increase
    FROM salary_history
),
grouped AS (
    SELECT emp_id, effective_date, is_increase,
        ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY effective_date)
        - ROW_NUMBER() OVER (PARTITION BY emp_id, is_increase ORDER BY effective_date) AS streak_id
    FROM changes
)
SELECT emp_id, MIN(effective_date) AS streak_start, COUNT(*) AS streak_length
FROM grouped WHERE is_increase = 1
GROUP BY emp_id, streak_id HAVING COUNT(*) >= 3;
```

### Explanation
This is the classic gaps-and-islands technique applied to a boolean
flag instead of a date sequence: the difference between two row-number
sequences — one over the whole partition, one over just the matching
rows — stays constant for as long as consecutive matching rows continue,
and jumps the moment a non-increase breaks the streak. That constant
value becomes the island's grouping key.

**Explicit assumptions, verified against a hand-traced 7-row dataset**
(salaries 50k→55k→60k→60k→65k→70k→75k across 7 dates):
- The **first row per employee is always treated as a non-increase**
  (`LAG` returns NULL, and `salary > NULL` is UNKNOWN, which `CASE WHEN`
  treats as false) — there's no prior value to have increased from, by
  definition.
- **An equal salary breaks the streak without counting as a decrease** —
  `60000 > 60000` is false, so that row is `is_increase = 0` and starts
  a new potential streak, exactly as "no decrease in between" requires.
- **"3 consecutive raises" means 3 consecutive `is_increase = 1` rows**,
  which corresponds to 4 consecutive salary snapshots forming a strictly
  increasing chain — verified: the traced dataset's 60k→65k→70k→75k
  stretch (3 raise events) is returned, while the earlier 50k→55k→60k
  stretch (only 2 raise events) is correctly excluded by
  `HAVING COUNT(*) >= 3`.
- **Not handled by this query**: multiple `salary_history` rows sharing
  the identical `effective_date` for one employee. Both `LAG` and
  `ROW_NUMBER` need a deterministic tie-breaker in that case (e.g.
  `ORDER BY effective_date, history_id`) — without one, which row counts
  as "before" the other is undefined and the streak calculation isn't
  reliable.

### Interviewer Follow-Up
"How would this query change if a raise equal to the previous salary
(no change) should break the streak, but shouldn't itself be reported
as a decrease?"

---

## Q092 — CUME_DIST: Proportion of Employees at or Below This Salary

**Difficulty:** 🟠 Advanced
**Category:** Window Functions, Percentiles
**Type:** A — Write SQL

### Problem
For each employee, compute what percentage of all employees have a
salary less than or equal to theirs.

### Expected SQL
```sql
SELECT emp_name, salary,
    ROUND(100 * CUME_DIST() OVER (ORDER BY salary), 1) AS pct_at_or_below
FROM employes;
```

### Explanation
`CUME_DIST()` returns, for each row, the fraction of rows in the
partition with an `ORDER BY` value less than or equal to the current
row's — precisely the "proportion at or below" this question asks for,
inclusive of ties. It's worth being deliberate about calling this
"percentage of employees at or below" rather than reaching for the
looser word "percentile": several different statistical definitions of
percentile exist, and `CUME_DIST()` matches exactly one of them (the
inclusive cumulative-distribution definition) — treating the two as
interchangeable in a business report can produce a number a stakeholder
reads as "top 10%" that doesn't match what a different percentile
formula (or spreadsheet function) would report for the same data. The
highest-paid employee(s) land at `100`, and tied salaries receive the
same shared value, not individually distinct ranks — see Q061 for the
direct comparison against `PERCENT_RANK()`, which does NOT share values
across ties the same way.

### Interviewer Follow-Up
"Two employees are tied for the highest salary in the company. What
value does `CUME_DIST` give them, and is that the number a business
stakeholder would expect if they asked 'what percentile is our
highest earner in'?"

---

## Q096 — LEAD to Find Days Until the Next Hire in a Department

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** A — Write SQL

### Problem
For each department, ordered by `hire_date`, show how many days passed
until that department's *next* hire (NULL for the most recent hire in
each department, since there is no next one yet).

### Expected SQL
```sql
SELECT emp_name, dept_id, hire_date,
    DATEDIFF(
        LEAD(hire_date) OVER (PARTITION BY dept_id ORDER BY hire_date),
        hire_date
    ) AS days_until_next_hire
FROM employes;
```

### Explanation
`LEAD()` is `LAG()`'s mirror image — it looks *forward* to a later row
in the ordered partition rather than backward, which is exactly what
"time until the next event" questions need instead of "time since the
last one." Reaching for `LAG` by habit here would require re-ordering
the whole partition backward and relabeling everything, which is more
error-prone than just using the function built for looking ahead. The
most recent hire in each department has no later row to look forward
to, so `LEAD` correctly returns NULL there rather than 0 or an error.

Boundary cases: a department with a single employee returns NULL for
that row; two hires on the same `hire_date` produce `0` days for the
earlier-listed row, and their relative order is arbitrary unless you add
a tie-breaker such as `ORDER BY hire_date, emp_id` inside the `OVER`
clause. A NULL `hire_date` makes `DATEDIFF` return NULL. In MySQL,
`DATEDIFF(a, b)` returns `a - b`, so passing the later date first (as
above) gives a positive number of days.

### Interviewer Follow-Up
"How would this same technique answer 'how many days does each
customer typically wait between orders' if `hire_date` were replaced
with an `order_date` column?"

---

[← Level 1](../02_CORE_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 3 — Advanced SQL](../04_ADVANCED_SQL/QUESTION_BANK.md)
