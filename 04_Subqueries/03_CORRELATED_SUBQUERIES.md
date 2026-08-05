# Correlated Subqueries: Row-by-Row Evaluation & Decorrelation Mechanics

A **Correlated Subquery** is an inner query block that references outer query attributes (outer column variables). Unlike uncorrelated subqueries which can be evaluated once prior to outer scanning, a correlated subquery logically executes **once for every candidate row** evaluated by the outer query block.

---

## Learning Objectives

- Master outer column binding semantics and scope resolution in SQL ASTs.
- Evaluate the computational complexity of naive correlated loops vs decorrelated joins.
- Interpret PostgreSQL execution plans featuring `SubPlan` nodes.
- Apply subquery unnesting strategies to eliminate row-by-row bottlenecks.
- Measure memory overhead and cache hit rates in correlated scalar evaluation.

---

## Business Context

Correlated subqueries naturally express queries that require group-relative or historical boundary comparisons:

- **Financial Ledgering**: Isolating customer transactions whose dollar amount exceeds the 90-day moving average of *that specific customer's* transaction history.
- **Healthcare Telemetry**: Identifying patient vital readings that deviate from *that specific patient's* baseline history.
- **Human Resources**: Finding employees whose salary is higher than the average salary of *their own department*.

---

## Concept

In relational algebra, correlation introduces a parameter dependency $\theta(r)$ into the inner selection:

$$\sigma_{\text{Predicate}(r, S)}(R) = \bigcup_{r \in R} \{ r \mid \text{Predicate}(r, \sigma_{\theta(r)}(S)) \}$$

For an outer relation $R$ containing $|R| = N$ tuples and an inner relation $S$ containing $|S| = M$ tuples, naive evaluation requires scanning or indexing $S$ $N$ times. Without optimization, the time complexity scales as:

$$\mathcal{O}(N \times M) \quad \text{or} \quad \mathcal{O}(N \log M)$$

---

## Syntax

```sql
-- ANSI SQL Correlated Subquery: Departmental Salary Benchmark
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date
FROM employes e
WHERE e.hire_date = (
    -- Inner Correlated Subquery referencing outer e.dept_id
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = e.dept_id -- Correlation Predicate!
);
```

---

## Mental Model

Visualizing row-by-row correlation:

```text
Outer Loop: Scan 'employes' table row by row (N rows)
 ├─ Row 1: emp_id=1, dept_id=1
 │   └─ Execute Subquery: SELECT MIN(hire_date) WHERE dept_id = 1 -> '2023-01-15'
 │       └─ Evaluates: '2023-01-15' = '2023-01-15'? TRUE -> Keep Row 1
 ├─ Row 2: emp_id=3, dept_id=1
 │   └─ Execute Subquery: SELECT MIN(hire_date) WHERE dept_id = 1 -> '2023-01-15'
 │       └─ Evaluates: '2022-11-10' = '2023-01-15'? FALSE -> Filter Out
 └─ Row 3: emp_id=11, dept_id=2
     └─ Execute Subquery: SELECT MIN(hire_date) WHERE dept_id = 2 -> '2020-04-11'
         └─ Evaluates: '2020-04-11' = '2020-04-11'? TRUE -> Keep Row 3
```

---

## Execution Order

1. **Outer Row Fetch**: The engine fetches the first candidate tuple $r_1$ from the outer relation.
2. **Parameter Substitution**: Attributes of $r_1$ (e.g. `r1.dept_id`) are passed into the inner subquery execution state as constant parameters.
3. **Inner Query Execution**: The inner query executes using the bound parameter and evaluates its predicate.
4. **Outer Filter Evaluation**: The inner result is evaluated against the outer `WHERE` condition.
5. **Loop Iteration**: Steps 1–4 repeat for tuple $r_2, r_3, \dots, r_N$.

---

## Optimizer Behaviour

In modern cost-based optimizers, correlated subqueries are initially parsed as `SubPlan` nodes. The query rewriter attempts **Subquery Unnesting / Decorrelation**:

- **Unnesting Transformation**: The correlation predicate `d.dept_id = e.dept_id` is pulled up out of the subquery and converted into an explicit `JOIN` condition.
- **Aggregation Grouping**: The subquery aggregation is converted into a pre-aggregated derived table (`GROUP BY dept_id`), executed once, and joined via Hash Join ($\mathcal{O}(N + M)$).

---

## Execution Plan Discussion

PostgreSQL plan demonstrating a naive `SubPlan` (correlated nested loop):

```text
Seq Scan on employes e  (cost=0.00..62.50 rows=3 width=40) (actual time=0.045..0.215 rows=5 loops=1)
  Filter: (hire_date = (SubPlan 1))
  Buffers: shared hit=22
  SubPlan 1
    ->  Aggregate  (cost=1.22..1.23 rows=1 width=4) (actual time=0.003..0.003 rows=1 loops=50)
          Buffers: shared hit=20
          ->  Seq Scan on employes d_emp  (cost=0.00..1.22 rows=2 width=4) (actual time=0.001..0.002 rows=2 loops=50)
                Filter: (dept_id = e.dept_id)
```

### Critical Plan Warning Signals:
- **`SubPlan 1`**: Indicates row-by-row execution.
- **`loops=50`**: The subquery was physically re-evaluated **50 separate times**!
- **`Buffers: shared hit=22`**: Buffer hits scale linearly with the outer table row count.

---

## Cross Database Notes

| Engine | Decorrelation Engine | `SubPlan` Caching | Manual Rewrite Urgency |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | Unnests `EXISTS`/`IN` correlation; may retain `SubPlan` for scalar aggregates. | Caches recent correlation parameter values in memory. | High if plan shows `SubPlan` with high `loops`. |
| **MySQL 8.0+** | Subquery materialization engine decorrelates `IN` and `EXISTS`. | Limited scalar caching. | High for complex aggregate correlations. |
| **SQL Server 2022**| Advanced decorrelation engine (`Apply` to `Join` rewrites). | Maintains cached parameter tables. | Medium (Optimizer decorrelates most standard queries). |
| **Oracle 23c** | Automatic Complex View Merging & Decorrelation. | Scalar Subquery Caching (hash table of inner results).| Low (Engine decorrelates aggressively). |

---

## Common Mistakes

### 1. Unindexed Correlation Join Keys
Executing a correlated subquery where the inner table lacks an index on the correlated column forces a full table scan on the inner table for *every outer row* ($\mathcal{O}(N \times M)$ disk operations).

---

## Performance Notes

### The Rewrite Benchmark: Correlated Subquery vs Derived Table Join

```sql
-- ❌ NAIVE: Correlated Subquery (O(N * M))
SELECT e.emp_id, e.emp_name, e.dept_id
FROM employes e
WHERE e.hire_date = (
    SELECT MIN(sub.hire_date) 
    FROM employes sub 
    WHERE sub.dept_id = e.dept_id
);

-- ✅ OPTIMIZED: Pre-aggregated Derived Table Join (O(N + M))
SELECT e.emp_id, e.emp_name, e.dept_id
FROM employes e
JOIN (
    SELECT dept_id, MIN(hire_date) AS min_hire
    FROM employes
    GROUP BY dept_id
) d_min ON e.dept_id = d_min.dept_id AND e.hire_date = d_min.min_hire;
```

---

## Production Notes

- **Latent Scalability Vulnerability**: Correlated subqueries often pass staging QA tests with 1,000 rows in milliseconds, but cause massive CPU utilization outages in production when table size scales to 1,000,000 rows. Always inspect `loops` in `EXPLAIN ANALYZE`.

---

## Real Company Example

### Uber: Driver Dispatch Base Fare Verification
Uber calculates whether a driver's earnings on a trip exceeded the historical average earnings for *that driver's vehicle class* during peak hours:

```sql
SELECT 
    t.trip_id,
    t.driver_id,
    t.fare_amount
FROM completed_trips t
WHERE t.fare_amount > (
    SELECT AVG(sub.fare_amount)
    FROM completed_trips sub
    WHERE sub.vehicle_class = t.vehicle_class -- Correlation on Vehicle Class
      AND sub.trip_date >= CURRENT_DATE - INTERVAL '30 days'
);
```

---

## Engineering Notes

When an optimizer fails to decorrelate a query, it is usually because the subquery contains side-effect operators, non-deterministic functions (`RANDOM()`, `CLOCK_TIMESTAMP()`), or complex inequality correlation predicates. Converting the query into a CTE or Window Function explicitly forces decorrelation.

---

## Interview Questions

### Q1: How does a correlated subquery differ from an uncorrelated subquery in execution?
**Answer**: An uncorrelated subquery has zero dependencies on the outer query and is evaluated once as an `InitPlan`. A correlated subquery references outer table attributes and logically executes repeatedly (once per outer tuple) as a `SubPlan`, unless unnested by the optimizer into a Join operator.

---

## Summary

| Property | Uncorrelated Subquery | Correlated Subquery |
| :--- | :--- | :--- |
| **Outer Column Dependency** | None | Yes (`e.dept_id`) |
| **Execution Frequency** | 1 Time (`InitPlan`) | $N$ Times (`SubPlan` per outer row) |
| **Time Complexity** | $\mathcal{O}(N + M)$ | $\mathcal{O}(N \times M)$ (if unoptimized) |
| **Decorrelation Target** | Not Applicable | Essential for high-volume datasets |

---

## Further Reading

- [PostgreSQL Internals: Subquery Decorrelation Strategies](https://www.postgresql.org/docs/current/planner-optimizer.html)
- [Microsoft SQL Server: Understanding APPLIES and Correlated Subqueries](https://learn.microsoft.com/en-us/sql/t-sql/queries/from-transact-sql#using-apply)

---

## Related Modules

- [Module 03 — Joins](../03_Joins/README.md)
- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
