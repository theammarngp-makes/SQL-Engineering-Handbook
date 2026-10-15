[← Level 2](../03_ANALYTICAL_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Level 3 (of 0–9)

# Level 3 — Advanced SQL

Pilot set: 9 of ~70 target questions.

---

## Q026 — Recursive CTE: Org Chart Traversal

**Difficulty:** 🔴 Expert
**Category:** Recursive CTEs
**Type:** A — Write SQL
**Related Modules:** [`06_CTEs`](../../06_CTEs)

### Scenario
HR needs every employee's full management chain, arbitrarily deep.

### Schema
`employes(emp_id, emp_name, manager_id)` — self-referencing, `manager_id`
NULL for top-level managers.

### Problem
For a given `emp_id`, list every manager above them, from direct manager
up to the top of the chain, with their depth (1 = direct manager).

### Expected SQL
```sql
WITH RECURSIVE management_chain AS (
    -- anchor: the starting employee's direct manager
    SELECT e.emp_id AS original_emp_id, e.manager_id, 1 AS depth
    FROM employes e
    WHERE e.emp_id = 101

    UNION ALL

    -- recursive step: walk up one more level each time
    SELECT mc.original_emp_id, e.manager_id, mc.depth + 1
    FROM management_chain mc
    JOIN employes e ON e.emp_id = mc.manager_id
    WHERE mc.manager_id IS NOT NULL
)
SELECT mc.depth, e.emp_name AS manager_name
FROM management_chain mc
JOIN employes e ON e.emp_id = mc.manager_id
ORDER BY mc.depth;
```

### Explanation
The anchor member selects the starting point; the recursive member joins
back to the CTE itself, walking one level up the hierarchy per iteration,
until `manager_id IS NULL` (top of the chain) stops the recursion. The
`UNION ALL` (not `UNION`) is required syntax for a recursive CTE — the
engine needs to see new rows added each iteration, not deduplicated.

### Common Mistake
Forgetting a termination condition, or having a data cycle (an
employee accidentally set as their own indirect manager) — either
produces infinite recursion, which most engines guard against with a
recursion depth limit that then surfaces as an error rather than a
silent hang.

### Interviewer Follow-Up
"How would you defend this query against a data cycle in manager_id that
shouldn't exist but might, due to a data entry bug?"

### Senior-Level Extension
"Adapt this to compute total reports (direct + indirect) per manager,
company-wide, in one query."

### Performance Consideration
Recursive CTEs process row-by-row conceptually; on a very deep or wide
hierarchy, this can be materially more expensive than a single-level
query — for company-wide rollups run frequently, consider whether a
maintained closure table (precomputed ancestor/descendant pairs) is worth
the write-side maintenance cost, matching the general index tradeoff logic
from Module 16.

---

## Q027 — Relational Division: Employees with ALL Required Certifications

**Difficulty:** 🔴 Expert
**Category:** Relational Division
**Type:** A — Write SQL

### Scenario
A compliance system needs every employee who holds *every* certification
in a required set — not just one of them.

### Schema
`employes(emp_id, emp_name)`, `certifications(cert_id, cert_name)`,
`employee_certifications(emp_id, cert_id)`

### Problem
Find every employee who holds ALL certifications currently marked
required (`certifications.is_required = TRUE`).

### Expected SQL
```sql
SELECT e.emp_id, e.emp_name
FROM employes e
WHERE NOT EXISTS (
    -- any required cert this employee does NOT hold?
    SELECT 1 FROM certifications c
    WHERE c.is_required = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM employee_certifications ec
          WHERE ec.emp_id = e.emp_id AND ec.cert_id = c.cert_id
      )
);
```

### Explanation
This is the classic "relational division" pattern, expressed as a double
negative: find employees for whom there is NO required certification they
DON'T hold. It's logically equivalent to "holds all," but SQL has no
direct "for all" operator, so division is expressed via nested `NOT
EXISTS`.

### Alternative Solution
```sql
SELECT ec.emp_id
FROM employee_certifications ec
JOIN certifications c ON c.cert_id = ec.cert_id AND c.is_required = TRUE
GROUP BY ec.emp_id
HAVING COUNT(*) = (SELECT COUNT(*) FROM certifications WHERE is_required = TRUE);
```
A count-comparison approach — simpler to read, but subtly relies on there
being no duplicate `(emp_id, cert_id)` rows in `employee_certifications`;
the `NOT EXISTS` version doesn't share that fragility.

### Interviewer Follow-Up
"What breaks in the COUNT-based alternative if an employee has a
duplicate row for the same certification?"

### Senior-Level Extension
"Adapt this to find employees missing exactly ONE required certification
— useful for a 'almost compliant' report."

---

## Q028 — Correlated Subquery for Percent-of-Total

**Difficulty:** 🟠 Advanced
**Category:** Correlated Subqueries, Window Functions
**Type:** F — Compare Approaches

### Problem
Show each department's headcount as a percentage of total company
headcount. Solve it two ways: with a correlated subquery, and with a
window function. Which is preferable, and why?

### Correlated Subquery Version
```sql
SELECT dept_id, COUNT(*) AS headcount,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM employes) AS pct_of_total
FROM employes
GROUP BY dept_id;
```

### Window Function Version
```sql
SELECT dept_id, COUNT(*) AS headcount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct_of_total
FROM employes
GROUP BY dept_id;
```

### Explanation
Both are logically correct here — the subquery in the first version is
*uncorrelated* (it doesn't reference the outer query's grouped columns),
so it's computed once, not per group, meaning it isn't actually the
expensive "per-row re-evaluation" pattern Module 16 warns about for truly
*correlated* subqueries. The window version (`SUM(...) OVER ()` with an
empty `OVER()`, meaning "the whole result set") is generally considered
more idiomatic for this specific "percent of total" pattern and reads
more clearly as "this aggregate, divided by the grand total aggregate" in
one pass.

### Interviewer Follow-Up
"Is the subquery version here actually a case of the 'correlated subquery
= slow' pattern from Module 16? Why or why not?" (Tests whether the
candidate distinguishes correlated from uncorrelated subqueries
precisely, not just pattern-matching on syntax shape.)

---

## Q029 — Conditional Aggregation for a Pivot Report

**Difficulty:** 🟠 Advanced
**Category:** Conditional Aggregation
**Type:** A — Write SQL

### Problem
Produce one row per department with columns for headcount hired in each
of the last 3 calendar years (2023, 2024, 2025) — a pivoted report, no
pivoting extension assumed available.

### Expected SQL
```sql
SELECT
    dept_id,
    COUNT(CASE WHEN EXTRACT(YEAR FROM hire_date) = 2023 THEN 1 END) AS hired_2023,
    COUNT(CASE WHEN EXTRACT(YEAR FROM hire_date) = 2024 THEN 1 END) AS hired_2024,
    COUNT(CASE WHEN EXTRACT(YEAR FROM hire_date) = 2025 THEN 1 END) AS hired_2025
FROM employes
GROUP BY dept_id;
```

### Explanation
Conditional aggregation (Q010's pattern, extended) is the portable way to
pivot without engine-specific `PIVOT` syntax — each `CASE` isolates one
bucket's rows for its own `COUNT`, all computed in a single pass over the
grouped data.

### Common Mistake
Using `EXTRACT(YEAR FROM hire_date) = 2023` as a `WHERE` filter instead
of inside `CASE` — this would filter the whole query down to only 2023
rows, losing the other two columns' data entirely rather than showing all
three side by side.

### Interviewer Follow-Up
"How would you make this dynamic — supporting an arbitrary,
configurable list of years — without hardcoding each year as a separate
column expression?" (Tests awareness that true dynamic pivoting requires
either application-layer query generation or engine-specific dynamic SQL
— plain ANSI SQL can't parameterize column lists.)

---

## Q030 — Temporal Reconciliation: Detecting Overlapping Date Ranges

**Difficulty:** 🔴 Expert
**Category:** Temporal Analysis
**Type:** A — Write SQL

### Scenario
An HR system tracks employee assignments with start/end dates per
department. A bug allowed some employees to have overlapping assignment
periods (in two departments "at once," which shouldn't be possible).

### Schema
`assignments(emp_id, dept_id, start_date, end_date)`

### Problem
Find every pair of overlapping assignments for the same employee.

### Expected SQL
```sql
SELECT a1.emp_id, a1.dept_id AS dept_a, a2.dept_id AS dept_b,
    a1.start_date AS a_start, a1.end_date AS a_end,
    a2.start_date AS b_start, a2.end_date AS b_end
FROM assignments a1
JOIN assignments a2
    ON a1.emp_id = a2.emp_id
   AND a1.dept_id < a2.dept_id  -- avoid comparing a row to itself and
                                 -- avoid reporting each overlap twice
   AND a1.start_date <= a2.end_date
   AND a2.start_date <= a1.end_date;
```

### Explanation
Two date ranges overlap exactly when `range1.start <= range2.end AND
range2.start <= range1.end` — a standard interval-overlap test. The
`a1.dept_id < a2.dept_id` self-join guard both prevents comparing a row
to itself and ensures each overlapping pair is reported once, not twice
(A-vs-B and B-vs-A).

### Common Mistake
Using `a1.emp_id != a2.emp_id` — wrong entirely (this compares DIFFERENT
employees' assignments, not the same employee's overlapping ones) — the
join condition needs `a1.emp_id = a2.emp_id` since overlap detection is
about one employee's own conflicting assignments.

### Interviewer Follow-Up
"What if end_date can be NULL, meaning 'still ongoing'? How does that
change the overlap condition?"

### Senior-Level Extension
"Extend this to find overlaps across ALL employees at once, not just when
given a single emp_id — and consider the performance implications of the
self-join at production scale (see Module 16, Lesson 04)."

---

## Q031 — Data Quality: Finding Orphaned Foreign Keys Without a Constraint

**Difficulty:** 🟠 Advanced
**Category:** Data Quality, Reconciliation
**Type:** G — Data Reasoning

### Scenario
A legacy `employes` table has a `dept_id` column with no enforced foreign
key constraint. Some rows reference department IDs that no longer exist
in `departments`.

### Problem
Write a query to find every such orphaned row, and explain why this
matters even though no query is currently erroring.

### Expected SQL
```sql
SELECT e.emp_id, e.emp_name, e.dept_id
FROM employes e
WHERE NOT EXISTS (
    SELECT 1 FROM departments d WHERE d.dept_id = e.dept_id
);
```

### Explanation
Without a foreign key constraint, the database allows this
inconsistency silently — no error is raised on insert, and ordinary
`INNER JOIN` queries simply exclude these rows from results without
flagging that anything is wrong, which is often how the problem goes
unnoticed for a long time. `NOT EXISTS` finds exactly the rows an inner
join would silently drop.

### Interviewer Follow-Up
"Why might a team choose not to add a real foreign key constraint even
after finding this problem? What's the tradeoff?" (Tests awareness of
real constraints: constraint enforcement has write-path cost, and
retrofitting one onto a table with existing violations requires cleaning
the data first — not a purely technical decision.)

---

## Q064 — Recursive CTE: Downward Org Chart (All Reports)

**Difficulty:** 🔴 Expert
**Category:** Recursive CTEs
**Type:** A — Write SQL

### Problem
Given `manager_id` self-references in `employes`, list every employee
under a given top manager (all levels down), with their depth in the
hierarchy.

### Expected SQL
```sql
WITH RECURSIVE org_chart AS (
    SELECT emp_id, emp_name, manager_id, 0 AS depth
    FROM employes WHERE emp_id = :top_manager_id
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, oc.depth + 1
    FROM employes e
    JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT * FROM org_chart ORDER BY depth, emp_name;
```

### Explanation
The anchor member seeds the top manager's own row at `depth 0`; the
recursive member repeatedly joins `employes` back onto the
growing result set, pulling in the next level down each iteration,
until no new matching rows are found. Without a terminating condition
in real (non-tree) data, a cyclical `manager_id` relationship would
recurse forever — most engines cap recursion depth as a safety net.

### Interviewer Follow-Up
"How would you defend against a corrupted dataset where an employee's
`manager_id` chain accidentally cycles back on itself?"

---

## Q065 — Conditional Aggregation as a Manual Pivot

**Difficulty:** 🟠 Advanced
**Category:** Pivot, Conditional Aggregation
**Type:** A — Write SQL

### Problem
Without a database-specific `PIVOT` clause, produce one row per
department with columns for headcount hired in 2022, 2023, and 2024.

### Expected SQL
```sql
SELECT dept_id,
    COUNT(CASE WHEN EXTRACT(YEAR FROM hire_date) = 2022 THEN 1 END) AS hired_2022,
    COUNT(CASE WHEN EXTRACT(YEAR FROM hire_date) = 2023 THEN 1 END) AS hired_2023,
    COUNT(CASE WHEN EXTRACT(YEAR FROM hire_date) = 2024 THEN 1 END) AS hired_2024
FROM employes GROUP BY dept_id;
```

### Explanation
This is the portable version of a pivot: each `CASE` expression carves
out one target column's condition, and `COUNT` (ignoring the implicit
NULL from non-matching rows) turns each into an independent bucket
count within a single `GROUP BY`. It scales poorly to many categories
(one `CASE` per column, all hardcoded) — that's the tradeoff versus a
native `PIVOT`/`CROSSTAB` where the engine supports one.

### Interviewer Follow-Up
"What would you do differently if the set of years wasn't known in
advance and needed to be dynamic?"

---

## Q066 — Set-Based Thinking vs. Row-by-Row Procedural Logic

**Difficulty:** 🟠 Advanced
**Category:** Query Design Philosophy
**Type:** F — Compare Approaches

### Problem
A candidate proposes looping through employees in application code,
issuing one `UPDATE` per row to apply a department-specific raise
percentage. What's the SQL-native alternative, and why does it matter?

### Explanation
The set-based alternative is a single statement applying the logic to
every matching row at once:
```sql
UPDATE employes e SET salary = salary * 1.05
WHERE dept_id IN (SELECT dept_id FROM departments WHERE dept_name = 'Sales');
```
Row-by-row ("RBAR" — row by agonizing row) logic pays per-row round-trip
and transaction overhead multiplied by row count; a set-based statement
lets the engine's own optimizer plan the whole operation once. This
distinction — thinking in sets, not loops — is one of the most
fundamental mental shifts interviewers probe for in mid-to-senior SQL
candidates.

### Interviewer Follow-Up
"Is there a legitimate case where row-by-row processing is actually the
right call over a set-based statement?"

---

[← Level 2](../03_ANALYTICAL_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 4 — Database Engineering](../05_DATABASE_ENGINEERING/QUESTION_BANK.md)
