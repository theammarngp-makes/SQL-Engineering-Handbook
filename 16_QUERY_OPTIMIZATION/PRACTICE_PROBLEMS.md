# Module 16 — Practice Problems

Work against the shared schema in [`00_Schema.sql`](./00_Schema.sql). Assume, for
every problem below, that `employes` holds several million rows in
production — small local sample data won't reproduce these effects, so
reason about *what the plan would show*, then verify against `EXPLAIN`
where you can.

---

### Problem 1 — Spot the non-SARGable predicate

```sql
SELECT emp_name FROM employes WHERE dept_id + 0 = 4;
```

Is this SARGable? If not, rewrite it.

---

### Problem 2 — Composite index design

You need to support this exact query efficiently, run thousands of times a
day:

```sql
SELECT emp_name FROM employes
WHERE dept_id = 4 AND hire_date > '2023-01-01'
ORDER BY hire_date;
```

Design the composite index (column list, in order) that best serves it, and
explain your column ordering choice.

---

### Problem 3 — NOT IN vs. NOT EXISTS

Explain, without running any SQL, why this query is dangerous if
`manager_id` can contain `NULL`, and rewrite it safely:

```sql
SELECT emp_name FROM employes
WHERE emp_id NOT IN (SELECT manager_id FROM employes);
```

---

### Problem 4 — Predict the join algorithm

Given: `locations` has 12 rows, `departments` has 40 rows, `employes` has 8
million rows. Both `departments.location_id` and `employes.dept_id` are
indexed. Predict the join algorithm the optimizer will likely choose for:

```sql
SELECT e.emp_name, l.city
FROM employes e
JOIN departments d ON e.dept_id = d.dept_id
JOIN locations l ON d.location_id = l.location_id
WHERE l.country = 'India';
```

---

### Problem 5 — Anti-pattern audit

Identify every anti-pattern (Lesson 06) present in this query, and rewrite
it cleanly:

```sql
SELECT DISTINCT *
FROM employes e, departments d
WHERE UPPER(d.dept_name) = 'ENGINEERING'
   OR e.hire_date > '2023-01-01'
ORDER BY e.emp_id
LIMIT 20 OFFSET 50000;
```

---

### Problem 6 — Correlated subquery to window function

Rewrite this correlated subquery as a window function:

```sql
SELECT e.emp_name, e.dept_id,
    (SELECT MAX(e2.hire_date) FROM employes e2 WHERE e2.dept_id = e.dept_id) AS latest_hire_in_dept
FROM employes e;
```

---

### Problem 7 — Diagnose from a plan description (no SQL given)

You're told: "`EXPLAIN ANALYZE` shows a full table scan on `employes`
(`Seq Scan` in PostgreSQL, `type: ALL` in MySQL) with estimated rows =
400,000 but actual rows = 3. Total actual time is dominated by this
single node." What's your hypothesis, and what two things would you check
next?

---

### Problem 8 — Full tuning workflow

Take any three-table JOIN query from Module 03, and write out all five
steps of the tuning workflow (Lesson 07) as if it had just been reported
slow in production — including what you'd check for in the plan and what
your first hypothesis would be, even though you don't have production-scale
data to run it against.



---

### Problem 9 -- Cost surface diagnosis (Lesson 10)

A BigQuery dashboard query returns in 1.2 seconds, well within its
3-second SLA, and ships without further review. Six months later Finance
flags it as a top-5 cost driver. Using Lesson 10's "The Cost Surface"
section, explain what latency-only review missed and which
`INFORMATION_SCHEMA.JOBS` field would have caught it before ship.

---

### Problem 10 -- Design a CI performance gate (Lesson 11)

Using Lesson 11's decision tree, walk through whether the `transactions`
lookup query in `11_AUTOMATED_PERFORMANCE_TESTING_AND_CICD_INTEGRATION.sql`
belongs behind an automated CI gate or a manual review cadence. Justify
each branch with a specific answer.

---

### Problem 11 -- Validate an AI-suggested rewrite (Lesson 12)

An AI assistant suggests rewriting this EXISTS query as a JOIN with
DISTINCT. Using Prompt Template 3 from `PROMPT_TEMPLATES.md`, write the
result-set diff query that proves (or disproves) equivalence, and
identify the one condition under which they would NOT be equivalent.

Solutions: see [`SOLUTIONS.sql`](./SOLUTIONS.sql).