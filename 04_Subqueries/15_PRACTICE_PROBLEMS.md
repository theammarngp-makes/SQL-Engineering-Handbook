# Multi-Level Enterprise Practice Problems: Subqueries

Test and solidify your subquery engineering expertise with 15 production-grade practice problems categorized into Easy, Medium, and Hard engineering tiers. All problems run against the standard handbook schema (`employes`, `departments`, `locations`).

---

## Tier 1: Fundamentals & Set Semantics (Easy)

### Problem 1: Department Aggregate Benchmark
Find all employees whose hire date is earlier than the earliest hire date in Department 2.

### Problem 2: Multi-City Location Filtering
Find all employees working in departments located in either 'Nagpur' or 'Pune' using an `IN` subquery.

### Problem 3: Basic Anti-Join Identification
Find all departments that currently have **no** assigned employees using `NOT EXISTS`.

### Problem 4: Scalar Projection Benchmark
Project every employee's `emp_name`, `dept_id`, and the overall count of employees in the company as `total_company_headcount`.

### Problem 5: Direct Manager Lookup
Find all employees who report to the same manager as 'Ammar' (excluding 'Ammar' himself).

---

## Tier 2: Correlation & Optimizations (Medium)

### Problem 6: Department-Relative Earliest Hire
Find the employee(s) who were hired earliest within *their own respective department* using a correlated subquery.

### Problem 7: Derived Table Pre-Aggregation Refactor
Refactor Problem 6 into an optimized `JOIN` against a pre-aggregated Derived Table to eliminate `SubPlan` row-by-row execution.

### Problem 8: Window Function Projection Refactor
Retrieve `emp_name`, `dept_id`, `hire_date`, and the minimum hire date of their department using a Window Function (`OVER (PARTITION BY ...)`).

### Problem 9: Quantified Comparison (`> ANY`)
Find all employees hired after at least one employee in Department 1 using `> ANY`.

### Problem 10: Defensive `NOT IN` Set Matching
Find all departments that have zero employees, safely utilizing `NOT IN` with an explicit `IS NOT NULL` guard predicate.

---

## Tier 3: Production Engineering & Complex Cases (Hard)

### Problem 11: Cross-Location Manager Relationship
Find all employees whose department is located in 'Nagpur' AND who report to a manager whose department is located in 'Mumbai'.

### Problem 12: Manager Span-of-Control Outliers
Find all managers who manage strictly **more** employees than the overall company average span-of-control (average direct reports per manager).

### Problem 13: Unassigned Locations Identification
Find all location records (`locations`) that have **no** departments assigned to them using `NOT EXISTS`.

### Problem 14: Above-Average Department Headcount
Retrieve departments whose headcount is strictly greater than the average headcount across all active departments.

### Problem 15: Department Seniority Ranking via Correlated Subquery
Calculate the seniority rank (1 = earliest hire date) of each employee within their department using a correlated subquery counting earlier hires.

---

## Solutions

Complete, production-tested SQL solutions for all 15 practice problems are available in [`16_SOLUTIONS.sql`](./16_SOLUTIONS.sql).
