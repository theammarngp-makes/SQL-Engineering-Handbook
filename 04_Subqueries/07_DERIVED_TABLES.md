# Derived Tables: Inline Views & Materialization Mechanics

A **Derived Table** (also referred to as an **Inline View** or **Subquery in the FROM Clause**) is an inner subquery block placed within the `FROM` or `JOIN` clauses of a SQL statement. In relational algebra, a derived table creates a transient, virtual relation $V = \sigma(T)$ that can be queried, joined, aggregated, and filtered like a base disk table for the scope of the parent query execution context.

---

## Learning Objectives

- Master the relational theory and scoping semantics of inline views.
- Understand optimizer **Derived Table Flattening** (Subquery Pull-up).
- Differentiate between in-memory streaming inline views vs materialized temporary tables.
- Analyze predicate pushdown mechanics across derived table boundaries.
- Compare Derived Tables against Common Table Expressions (CTEs) in modern SQL engines.

---

## Business Context

Derived tables are fundamental building blocks for complex analytical SQL pipelines:

- **ETL Data Aggregation**: Pre-aggregating raw transactional detail rows to a daily or monthly granularity before joining against dimension tables.
- **Financial Reporting**: Calculating multi-tier tax or commission rollups before applying executive filters.
- **Customer Cohort Analysis**: Computing per-customer first-purchase timestamps in a derived layer to segment cohort retention metrics.

---

## Concept

In relational algebra, a derived table replaces a base relation name with an inline expression:

$$\sigma_{\text{outer}}\left( R \bowtie \left( \gamma_{\text{grouping}, f(\text{col})}(S) \right) \right)$$

Derived tables require mandatory table alias assignment in ANSI SQL (`FROM (...) AS derived_alias`). This enforces explicit scope boundaries for column projections.

---

## Syntax

```sql
-- ANSI SQL Derived Table Syntax
SELECT 
    d.dept_name,
    agg.total_employees,
    agg.earliest_hire_date
FROM departments d
JOIN (
    -- Inline Derived Table (Pre-Aggregation)
    SELECT 
        e.dept_id,
        COUNT(e.emp_id) AS total_employees,
        MIN(e.hire_date) AS earliest_hire_date
    FROM employes e
    WHERE e.dept_id IS NOT NULL
    GROUP BY e.dept_id
) AS agg ON d.dept_id = agg.dept_id
WHERE agg.total_employees > 2;
```

---

## Mental Model

Visualizing inline derived table execution:

```text
┌─────────────────────────────────────────────────────────┐
│ Step 1: Execute Inline View (Pre-Aggregation)           │
│ SELECT dept_id, COUNT(*) FROM employes GROUP BY dept_id │
│ Virtual Relation 'agg':                                 │
│  dept_id = 1 | total_employees = 3                      │
│  dept_id = 2 | total_employees = 5                      │
└──────────────────────────┬──────────────────────────────┘
                           │ Joined into Pipeline
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: Parent Query Hash Join                          │
│ SELECT d.dept_name, agg.total_employees                 │
│ FROM departments d JOIN agg ON d.dept_id = agg.dept_id  │
└─────────────────────────────────────────────────────────┘
```

---

## Execution Order

1. **Inline Evaluation / Optimization**: The database planner inspects the inner derived table.
   - If simple: Optimizers collapse/flatten the derived table into the main query tree (Subquery Pull-up).
   - If aggregated (`GROUP BY`, `DISTINCT`, `LIMIT`): The engine plans the inner query as an isolated execution phase.
2. **Materialization or Streaming**: The inner query streams rows directly into the parent join pipeline or materializes a temporary hash table in `work_mem`.
3. **Parent Processing**: The parent query joins and filters the virtual relation output.

---

## Optimizer Behaviour

Modern optimizers (PostgreSQL 16+, Oracle, SQL Server) execute **Derived Table Flattening**:

- **Subquery Pull-up**: If a derived table contains no aggregates, set operations, or `LIMIT` clauses, the optimizer completely removes the derived table boundary, pulling the inner tables and join conditions directly into the outer query block.
- **Predicate Pushdown**: Outer `WHERE` predicates targeting derived table columns are pushed down *inside* the derived table block *before* aggregation occurs, reducing intermediate data volume.

---

## Execution Plan Discussion

Annotated PostgreSQL plan for an aggregated derived table join:

```text
Hash Join  (cost=2.45..5.80 rows=4 width=40) (actual time=0.048..0.095 rows=4 loops=1)
  Hash Cond: (d.dept_id = agg.dept_id)
  Buffers: shared hit=4
  ->  Seq Scan on departments d  (cost=0.00..1.10 rows=10 width=36) (actual time=0.005..0.008 rows=10 loops=1)
  ->  Hash  (cost=2.40..2.40 rows=4 width=12) (actual time=0.032..0.033 rows=4 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Subquery Scan on agg  (cost=2.25..2.40 rows=4 width=12) (actual time=0.022..0.027 rows=4 loops=1)
              ->  HashAggregate  (cost=2.25..2.36 rows=4 width=12) (actual time=0.021..0.025 rows=4 loops=1)
                    Group Key: e.dept_id
                    ->  Seq Scan on employes e  (cost=0.00..2.00 rows=50 width=4) (actual time=0.005..0.010 rows=50 loops=1)
```

---

## Cross Database Notes

| Engine | Flattening Support | Mandatory Alias | CTE Parity |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | Automatic Subquery Pull-up. | Mandatory (`AS alias`). | Identical plan to inline CTEs (`WITH ... AS (...)`). |
| **MySQL 8.0+** | Derived table merging (`derived_merge=on`). | Mandatory (`AS alias`). | Equivalent to non-recursive CTEs. |
| **SQL Server 2022**| Advanced Query Plan Flattening.| Mandatory (`AS alias`). | Identical optimizer treatment as inline CTEs. |
| **Oracle 23c** | View Merging & Complex View Merging. | Optional in Oracle syntax.| Equivalent to inline `WITH` clauses. |

---

## Common Mistakes

### 1. Omitting the Derived Table Alias
ANSI SQL syntax strictly requires all derived tables in the `FROM` clause to have an explicit table alias. Omitting the alias triggers a syntax error.

```sql
-- ❌ SYNTAX ERROR in PostgreSQL/MySQL
SELECT * FROM (SELECT dept_id, COUNT(*) FROM employes GROUP BY dept_id);

-- ✅ SAFE & VALID
SELECT * FROM (SELECT dept_id, COUNT(*) FROM employes GROUP BY dept_id) AS dept_counts;
```

---

## Performance Notes

Derived tables containing `GROUP BY` or `DISTINCT` materialize intermediate result sets in memory. If the intermediate row count is large, tune `work_mem` to prevent temporary disk spills during the `HashAggregate` phase.

---

## Production Notes

- **Modularity vs Readability**: Derived tables nested 4+ levels deep become extremely unreadable for production maintenance. Replace deep derived table nesting with modular Common Table Expressions (`WITH` blocks) for enhanced code readability without performance penalties.

---

## Real Company Example

### Uber Freight: Carrier Fleet Capacity Aggregation
Uber Freight aggregates available truck capacity per carrier prior to matching shipper loads:

```sql
SELECT 
    c.carrier_name,
    capacity.available_trucks,
    capacity.primary_hub_location
FROM carriers c
JOIN (
    SELECT 
        t.carrier_id,
        COUNT(t.truck_id) AS available_trucks,
        MODE() WITHIN GROUP (ORDER BY t.current_location_id) AS primary_hub_location
    FROM fleet_trucks t
    WHERE t.status = 'IDLE_AVAILABLE'
    GROUP BY t.carrier_id
) AS capacity ON c.carrier_id = capacity.carrier_id
WHERE capacity.available_trucks >= 5;
```

---

## Engineering Notes

In modern SQL engines (PostgreSQL 12+, MySQL 8.0+), non-recursive CTEs (`WITH cte AS (...)`) and inline Derived Tables (`FROM (...) AS cte`) share the **exact same physical optimizer rewriter engine**. They generate identical execution plans.

---

## Interview Questions

### Q1: Is there a performance difference between a Derived Table and a non-recursive CTE in PostgreSQL 16?
**Answer**: No. Beginning in PostgreSQL 12, non-recursive CTEs are inlined by default unless explicitly specified with `AS MATERIALIZED`. Consequently, Derived Tables and non-recursive CTEs generate identical physical execution plans and performance.

---

## Summary

| Feature | Derived Table |
| :--- | :--- |
| **Location** | `FROM` or `JOIN` Clause |
| **Relational Representation**| Virtual Relation / Inline View |
| **Alias Requirement** | Mandatory in ANSI SQL |
| **Optimizer Optimization** | Subquery Pull-up & Predicate Pushdown |

---

## Further Reading

- [PostgreSQL Documentation: Queries in the FROM Clause](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-SUBQUERIES)

---

## Related Modules

- [Module 06 — CTEs](../06_CTEs/README.md)
- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
