# Single-Row Subqueries: Scalar Comparisons & Execution Mechanics

A **Single-Row Subquery** is an inner query block bounded within parentheses that evaluates to a scalar tuple containing exactly one row and one column (cardinality $= 1, \text{degree} = 1$). Because its result is structurally identical to a literal constant, single-row subqueries interact directly with scalar relational comparison operators (`=`, `>`, `<`, `>=`, `<=`, `<>`).

---

## Learning Objectives

- Master the relational theory and type algebra of single-row scalar subqueries.
- Differentiate between single-row subqueries and multi-row/multi-column query blocks.
- Analyze PostgreSQL `InitPlan` execution nodes and cost mechanics.
- Implement defensive SQL patterns to prevent runtime `CardinalityError` exceptions in production.
- Benchmark scalar subquery performance against alternative windowing and join constructs.

---

## Business Context

In enterprise database applications, business metrics frequently require comparing individual transaction rows against global or domain-segmented benchmarks. Examples include:

- **E-Commerce Analytics**: Identifying orders whose total transaction value exceeds the platform's rolling 30-day average order value (AOV).
- **FinTech Fraud Detection**: Isolating accounts making single transfers greater than the historical 99th percentile wire transfer amount.
- **Human Capital Management**: Identifying employees whose tenure or salary exceeds the company-wide aggregate mean.

---

## Concept

Mathematically, a single-row subquery acts as a parameter generator for an outer relational expression. Given an outer relation $R$ and an inner relation $S$, a scalar subquery in the `WHERE` clause evaluates an aggregate function $f(S)$ or a constrained projection:

$$\sigma_{A > f(S)}(R)$$

Where $f(S)$ returns a single element $v \in \mathbb{D}$. If the evaluation of $S$ produces zero rows, $f(S)$ evaluates to `NULL`, causing the scalar comparison $(A > \text{NULL})$ to yield `UNKNOWN` under three-valued logic. Conversely, if $S$ returns two or more rows ($|S| > 1$), ANSI SQL compliance requires the database engine to abort execution and throw a cardinality violation.

---

## Syntax

```sql
-- Standard ANSI SQL Single-Row Subquery Syntax
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id,
    e.hire_date
FROM employes e
WHERE e.hire_date < (
    -- Inner Scalar Subquery: Guaranteed 1 Row x 1 Column
    SELECT MIN(d_emp.hire_date)
    FROM employes d_emp
    WHERE d_emp.dept_id = 1
);
```

---

## Mental Model

Visualizing single-row subquery processing:

```text
┌─────────────────────────────────────────────────────────┐
│ Step 1: Execute InitPlan (Inner Scalar Subquery)       │
│ SELECT MIN(hire_date) FROM employes WHERE dept_id = 1   │
│ Result: '2020-04-11' (Single Scalar Constant)          │
└──────────────────────────┬──────────────────────────────┘
                           │ Substituted as Literal Constant
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: Outer Query Table Scan / Index Scan             │
│ SELECT emp_id, emp_name FROM employes                   │
│ WHERE hire_date < '2020-04-11'                          │
└─────────────────────────────────────────────────────────┘
```

---

## Execution Order

1. **Phase 1: InitPlan Pre-Evaluation**: The query engine identifies that the inner subquery does not depend on outer query attributes (it is uncorrelated). The subquery is scheduled for execution *prior* to scanning the outer table.
2. **Phase 2: Result Caching**: The single scalar value output from the inner subquery is cached in process memory for the duration of the query statement.
3. **Phase 3: Outer Table Evaluation**: The engine streams tuples from the outer relation (`employes`), evaluating the predicate against the cached constant.

---

## Optimizer Behaviour

In cost-based optimizers (PostgreSQL, Oracle, SQL Server), an uncorrelated single-row subquery is assigned an `InitPlan` node in the execution AST. 

- **Subquery Materialization**: The engine evaluates the `InitPlan` exactly **once**, regardless of whether the outer table contains 10 rows or 10,000,000 rows.
- **Cost Allocation**: The total estimated cost of the query is calculated as:

$$\text{Cost}_{\text{total}} = \text{Cost}_{\text{InitPlan}} + \text{Cost}_{\text{OuterScan}}$$

---

## Execution Plan Discussion

Below is an annotated `EXPLAIN (ANALYZE, BUFFERS)` output for a single-row aggregate subquery against PostgreSQL:

```text
Seq Scan on employes e  (cost=1.25..15.50 rows=17 width=40) (actual time=0.042..0.088 rows=12 loops=1)
  Filter: (hire_date < $0)
  Rows Removed by Filter: 38
  Buffers: shared hit=4
  InitPlan 1 (returns $0)
    ->  Aggregate  (cost=1.25..1.26 rows=1 width=4) (actual time=0.018..0.019 rows=1 loops=1)
          Buffers: shared hit=2
          ->  Seq Scan on employes d_emp  (cost=0.00..1.22 rows=10 width=4) (actual time=0.008..0.012 rows=10 loops=1)
                Filter: (dept_id = 1)
```

### Key Plan Metrics:
- **`InitPlan 1 (returns $0)`**: Identifies the single-row subquery. Output parameter `$0` holds the computed scalar.
- **`loops=1`**: Confirms the inner subquery ran only once.
- **`Filter: (hire_date < $0)`**: Shows the outer sequential scan utilizing the pre-computed `$0` scalar.

---

## Cross Database Notes

| Engine | Scalar Behavior | Multiple Rows Returned Error | Optimization Strategy |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | Supported in `SELECT`, `WHERE`, `HAVING`. | `ERROR: more than one row returned by a subquery used as an expression` | Assigned `InitPlan` node; cached per query context. |
| **MySQL 8.0+** | Supported across all standard clauses. | `ERROR 1242 (21000): Subquery returns more than 1 row` | Evaluates as `SUBQUERY` item; materializes to internal cache. |
| **SQL Server 2022**| Fully compliant with T-SQL semantics. | `Msg 512, Level 16: Subquery returned more than 1 value.` | Resolved during parameterization phase; cached in execution plan. |
| **Oracle 23c** | Standard ANSI scalar subquery support. | `ORA-01427: single-row subquery returns more than one row` | Rewritten to scalar expression node; optimized via scalar subquery caching. |

---

## Common Mistakes

### 1. The Non-Unique Scalar Trap
Using a comparison operator (`=`, `>`, `<`) with a subquery that isn't guaranteed unique via aggregate functions (`MIN`, `MAX`, `AVG`) or a primary key equality constraint.

```sql
-- ❌ DANGEROUS: Fails in production if multiple departments match location_id = 1
SELECT emp_name 
FROM employes 
WHERE dept_id = (SELECT dept_id FROM departments WHERE location_id = 1);

-- ✅ SAFE: Explicitly enforce single-row constraint or use LIMIT 1 / aggregation
SELECT emp_name 
FROM employes 
WHERE dept_id = (SELECT MIN(dept_id) FROM departments WHERE location_id = 1);
```

---

## Performance Notes

Single-row subqueries backed by `InitPlan` execution are generally very fast ($O(1)$ subquery evaluations). However, if an index is missing on the subquery filter column, the one-time scan of the inner table can become expensive on multi-gigabyte relations. Ensure all filtering columns inside the subquery maintain secondary B-Tree indexes.

---

## Production Notes

- **Concurrency & Locking**: Single-row subqueries execute under read-committed or repeatable read isolation levels without holding locks on the subquery table beyond read completion.
- **Defensive Guardrails**: When writing dynamic queries or microservice endpoints, wrap scalar subquery projections in `LIMIT 1` or synthetic aggregate wrappers (`MAX()`) to prevent unexpected runtime application crashes due to duplicate rows in upstream databases.

---

## Real Company Example

### Stripe: Early Account Fraud Limit Enforcement
Stripe evaluates merchant transaction volumes against platform tier benchmarks. To check if a newly onboarded merchant's daily transaction total exceeds the overall system median, engineers use single-row aggregate subqueries:

```sql
SELECT 
    m.merchant_id,
    m.daily_volume
FROM merchant_metrics m
WHERE m.account_status = 'PROBATION'
  AND m.daily_volume > (
      SELECT PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY daily_volume)
      FROM merchant_metrics
      WHERE account_status = 'VERIFIED'
  );
```

---

## Engineering Notes

When an uncorrelated single-row subquery is used in a `WHERE` predicate, the cost-based optimizer treats the output as a literal constant. However, unlike literal parameters passed from client applications, the optimizer cannot utilize histogram distribution statistics of the subquery result *before* planning the outer query. This can lead to cardinality estimation errors on the outer table scan if the subquery returns an outlier value.

---

## Interview Questions

### Q1: What happens if a single-row subquery returns 0 rows?
**Answer**: If a single-row subquery returns zero rows, the expression evaluates to `NULL`. Any scalar comparison against `NULL` (such as `hire_date > NULL`) yields `UNKNOWN` under three-valued logic, causing the outer `WHERE` clause to filter out all candidate rows.

---

## Summary

| Feature | Single-Row Subquery |
| :--- | :--- |
| **Expected Cardinality** | Exactly 1 Row $\times$ 1 Column |
| **Operators** | `=`, `>`, `<`, `>=`, `<=`, `<>` |
| **Execution Node** | `InitPlan` (Evaluated once) |
| **Failure Mode** | Runtime Exception (`Cardinality Error` if $>1$ row) |

---

## Further Reading

- [PostgreSQL Documentation: Subquery Expressions](https://www.postgresql.org/docs/current/functions-subquery.html)
- [Microsoft Learn: Subqueries (SQL Server)](https://learn.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/subqueries-in-sql-server)
- [Use The Index, Luke: Subquery Performance](https://use-the-index-luke.com)

---

## Related Modules

- [Module 03 — Joins](../03_Joins/README.md)
- [Module 06 — CTEs](../06_CTEs/README.md)
- [Module 07 — Window Functions](../07_Window_Functions/README.md)
