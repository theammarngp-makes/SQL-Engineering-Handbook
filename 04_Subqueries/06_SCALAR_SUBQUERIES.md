# Scalar Subqueries in SELECT & Projection Caching Mechanics

A **Scalar Subquery in the SELECT Projection** is a subquery expression embedded directly within the column projection list of a `SELECT` statement. Because each scalar subquery returns a single scalar value per outer row, it executes conceptually as a user-defined function across the outer result stream.

---

## Learning Objectives

- Understand the execution cost model of scalar subqueries in `SELECT` lists.
- Analyze **Scalar Subquery Caching** mechanics across database engines.
- Evaluate memory consumption and CPU penalty of repeated scalar projections.
- Rewrite projected scalar subqueries into explicit `LEFT JOIN` aggregations or Window Functions.
- Prevent severe production thread blocking caused by un-cached scalar projections.

---

## Business Context

Scalar projections are frequently used in reporting dashboards to attach contextual benchmarks alongside detail records:

- **Executive HR Dashboards**: Projecting an employee's salary alongside the aggregate company-wide average salary and their specific department's average salary.
- **Financial Statements**: Displaying individual ledger transaction amounts alongside the daily opening account balance.
- **E-Commerce Order Summaries**: Presenting line-item prices alongside the lifetime total spend of the purchasing customer.

---

## Concept

In relational projection ($\pi$), a projected scalar subquery $f(r)$ evaluates an inner expression for each outer tuple $r \in R$:

$$\pi_{A_1, A_2, \dots, f(r)}(R)$$

If $f(r)$ is correlated with outer attribute $r[K]$, the database engine logically executes the scalar subquery $N$ times ($N = |R|$). If $f(r)$ returns $0$ rows, it projects `NULL`. If $f(r)$ returns $>1$ rows, execution aborts with a runtime cardinality exception.

---

## Syntax

```sql
-- ANSI SQL Projected Scalar Subquery
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    -- Projected Scalar Subquery 1 (Uncorrelated)
    (SELECT COUNT(*) FROM employes) AS company_total_employees,
    -- Projected Scalar Subquery 2 (Correlated)
    (SELECT d.dept_name FROM departments d WHERE d.dept_id = e.dept_id) AS dept_name
FROM employes e;
```

---

## Mental Model

Visualizing projection processing:

```text
Stream Outer Rows (employes):
 ├─ Row 1: emp_id=1, dept_id=1
 │   ├─ Compute Scalar 1: (SELECT COUNT(*) FROM employes) -> 50 (Cached!)
 │   └─ Compute Scalar 2: (SELECT dept_name WHERE dept_id=1) -> 'Data Analytics'
 ├─ Row 2: emp_id=2, dept_id=1
 │   ├─ Compute Scalar 1: Fetch from Cache -> 50
 │   └─ Compute Scalar 2: Fetch from Cache (Key=1) -> 'Data Analytics'
 └─ Row 3: emp_id=3, dept_id=2
     ├─ Compute Scalar 1: Fetch from Cache -> 50
     └─ Compute Scalar 2: Miss! Execute Subquery -> 'Engineering'
```

---

## Execution Order

1. **Outer Relation Scan**: The engine streams rows from table $R$.
2. **Scalar Projection Evaluation**: For each emitted row, projected scalar expressions are evaluated.
3. **Scalar Subquery Cache Lookup**: The engine hashes the input parameters (correlation keys) and checks the session **Scalar Subquery Cache**.
   - **Cache Hit**: Output value returned instantly without subquery re-execution.
   - **Cache Miss**: Subquery executes, populates cache, and returns value.

---

## Optimizer Behaviour

PostgreSQL and Oracle implement **Scalar Subquery Caching**. The engine maintains a small in-memory hash table of input parameter $\rightarrow$ result mappings.

- **Cache Capacity**: If the outer table contains low cardinality correlation keys (e.g. 5 departments across 1,000,000 employees), the cache hit rate exceeds 99.9%, mitigating execution cost.
- **Cache Thrashing**: If the correlation key is unique (e.g. `emp_id`), cache hits drop to 0%, forcing 1,000,000 subquery evaluations ($\mathcal{O}(N \times M)$ disaster!).

---

## Execution Plan Discussion

PostgreSQL plan showing a scalar projection SubPlan:

```text
Seq Scan on employes e  (cost=0.00..35.50 rows=50 width=40) (actual time=0.025..0.120 rows=50 loops=1)
  Buffers: shared hit=18
  SubPlan 1
    ->  Seq Scan on departments d  (cost=0.00..1.10 rows=1 width=32) (actual time=0.001..0.001 rows=1 loops=5)
          Filter: (dept_id = e.dept_id)
```

### Key Metrics:
- **`loops=5`**: Scalar cache reduced 50 row evaluations to 5 distinct subquery executions.

---

## Cross Database Notes

| Engine | Scalar Cache Support | Cache Strategy | Optimal Alternative |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | Supported in SELECT projections. | In-memory hash table of parameters. | `LEFT JOIN` or Window Function. |
| **Oracle 23c** | Advanced Scalar Subquery Caching. | Deterministic hash cache per cursor. | `LEFT JOIN` / Window Function. |
| **SQL Server 2022**| Limited (often evaluates SubPlan). | Plan dependent. | `OUTER APPLY` / `LEFT JOIN`. |
| **MySQL 8.0+** | Subquery Materialization in SELECT. | Materializes distinct inputs. | `LEFT JOIN`. |

---

## Common Mistakes

### 1. Projecting Multiple Correlated Scalar Subqueries on the Same Table
Writing 3 separate scalar subqueries against the same target table forces 3 separate subplan lookups per outer row instead of a single `LEFT JOIN`.

```sql
-- ❌ BAD: 3 separate scalar subqueries against 'departments'
SELECT 
    e.emp_name,
    (SELECT d.dept_name FROM departments d WHERE d.dept_id = e.dept_id) AS dept_name,
    (SELECT d.location_id FROM departments d WHERE d.dept_id = e.dept_id) AS loc_id
FROM employes e;

-- ✅ GOOD: Single LEFT JOIN
SELECT 
    e.emp_name,
    d.dept_name,
    d.location_id
FROM employes e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
```

---

## Performance Notes

### The Window Function Over Scalar Rewrite Benchmark

```sql
-- ❌ NAIVE: Projected Aggregate Subquery
SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    (SELECT AVG(d.salary) FROM employes d WHERE d.dept_id = e.dept_id) AS dept_avg_salary
FROM employes e;

-- ✅ PRODUCTION GRADE: Window Function Rewrite
SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    AVG(e.salary) OVER (PARTITION BY e.dept_id) AS dept_avg_salary
FROM employes e;
```

---

## Production Notes

- **API Performance Degradation**: Embedded scalar subqueries in ORM projections (e.g. Hibernate/Entity Framework mapping calculated properties) are a leading cause of $N+1$ database performance degradation in microservices.

---

## Real Company Example

### Shopify: Merchant Store Order Summary
Shopify projects customer stats alongside order export rows:

```sql
SELECT 
    o.order_id,
    o.created_at,
    o.total_amount,
    -- Scalar projection of customer order rank
    (
        SELECT COUNT(*)
        FROM orders prev
        WHERE prev.customer_id = o.customer_id
          AND prev.created_at <= o.created_at
    ) AS customer_order_sequence_number
FROM orders o
WHERE o.shop_id = 49201;
```

---

## Engineering Notes

When a scalar subquery in the `SELECT` list returns `NULL` (because zero rows matched), SQL handles it gracefully. However, if outer joins or calculations depend on non-nullability, wrap the projected subquery in `COALESCE((SELECT ...), 0)`.

---

## Interview Questions

### Q1: Why should projected scalar subqueries be converted to Window Functions or LEFT JOINs?
**Answer**: Projected scalar subqueries execute as `SubPlan` nodes. If the correlation key has high cardinality, scalar subquery caching fails, resulting in $\mathcal{O}(N \times M)$ execution complexity. Window Functions and `LEFT JOIN`s evaluate set aggregations in a single pass ($\mathcal{O}(N \log N)$), drastically reducing CPU and shared buffer hits.

---

## Summary

| Property | Projected Scalar Subquery | Window Function |
| :--- | :--- | :--- |
| **Execution Node** | `SubPlan` | `WindowAgg` |
| **Caching Dependent** | Yes | No |
| **Complexity (Unique Key)**| $\mathcal{O}(N \times M)$ | $\mathcal{O}(N \log N)$ |
| **Production Recommendation**| Avoid on large tables | Preferred Standard |

---

## Further Reading

- [PostgreSQL Documentation: Scalar Subqueries](https://www.postgresql.org/docs/current/sql-expressions.html#SQL-SYNTAX-SCALAR-SUBQUERIES)

---

## Related Modules

- [Module 07 — Window Functions](../07_Window_Functions/README.md)
- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
