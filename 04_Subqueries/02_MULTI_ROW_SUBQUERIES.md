# Multi-Row Subqueries: Set Matching & Quantified Operators

A **Multi-Row Subquery** is an inner query block that returns a relation of multiple rows and a single column ($N \ge 0, \text{degree} = 1$). Because scalar comparison operators (`=`, `>`, `<`) cannot evaluate multi-element sets, multi-row subqueries require set membership operators (`IN`, `NOT IN`) or quantified comparison operators (`ANY`, `SOME`, `ALL`).

---

## Learning Objectives

- Understand the set-theoretic mechanics of multi-row subqueries.
- Contrast `IN` against quantified operators (`> ANY`, `< ALL`).
- Analyze how cost-based optimizers rewrite multi-row subqueries into Hash Semi-Joins and Hash Anti-Joins.
- Uncover the dangerous performance and correctness traps of `NOT IN` with nullable columns.
- Compare memory usage (`work_mem`) and plan node performance across large set evaluations.

---

## Business Context

Multi-row subqueries drive key decision-making workflows in transactional systems:

- **Supply Chain Management**: Identifying suppliers who provide components for delayed assembly orders.
- **FinTech Operations**: Segmenting credit card accounts that executed transactions in flagged high-risk geographic regions.
- **Corporate Analytics**: Filtering employees belonging to any department situated in specific international tech hubs.

---

## Concept

In relational algebra, a multi-row `IN` predicate is defined as set membership ($\in$). Given an outer tuple key $r[A]$ and an inner subquery relation $S = \pi_{B}(T)$:

$$r \in \sigma_{A \in \pi_{B}(T)}(R) \iff \exists s \in T : r[A] = s[B]$$

Quantified operators extend scalar comparisons across sets:
- **`A > ANY (S)`**: True if $A$ is strictly greater than at least one element in $S$ ($\equiv A > \min(S)$).
- **`A > ALL (S)`**: True if $A$ is strictly greater than every element in $S$ ($\equiv A > \max(S)$).

---

## Syntax

```sql
-- ANSI SQL Multi-Row Subquery with IN Operator
SELECT 
    e.emp_id,
    e.emp_name,
    e.dept_id
FROM employes e
WHERE e.dept_id IN (
    SELECT d.dept_id
    FROM departments d
    WHERE d.location_id IN (1, 2)
);

-- Quantified ANY Comparison
SELECT 
    e.emp_id,
    e.emp_name,
    e.hire_date
FROM employes e
WHERE e.hire_date > ANY (
    SELECT e_sub.hire_date
    FROM employes e_sub
    WHERE e_sub.dept_id = 2
);
```

---

## Mental Model

Visualizing multi-row set membership:

```text
┌─────────────────────────────────────────────────────────┐
│ Step 1: Subquery Materialization / Hash Table Build    │
│ SELECT dept_id FROM departments WHERE location_id IN(1,2)│
│ Inner Set S = { 1, 2, 5 }                               │
└──────────────────────────┬──────────────────────────────┘
                           │ Hashed into Memory
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: Outer Table Scan & Hash Probe                   │
│ For each outer employee e:                              │
│ Check if e.dept_id ∈ Hash_Table(S)                     │
│ Row matched? -> Stream to Output                        │
└─────────────────────────────────────────────────────────┘
```

---

## Execution Order

1. **Subquery Execution & Hashing**: The inner query runs first (if uncorrelated). Its distinct output values are inserted into an in-memory hash table (if memory allows within `work_mem`).
2. **Outer Table Processing**: The outer relation is scanned.
3. **Hash Probing**: For each candidate outer tuple, the key is hashed and probed against the inner hash table. Evaluation completes in $O(1)$ constant time per row.

---

## Optimizer Behaviour

Modern optimizers unnest uncorrelated `IN` subqueries into **Hash Semi-Joins** ($\ltimes$). 

- **Duplicate Elimination**: If the inner subquery contains duplicate values (e.g. `{1, 1, 2, 2}`), the optimizer's semi-join engine ignores duplicates, preventing cardinality inflation on the outer query.
- **Unnesting Transformation**: The internal relational tree changes from a nested loop subplan into a flat two-table join tree.

---

## Execution Plan Discussion

Annotated PostgreSQL execution plan for an `IN` subquery:

```text
Hash Semi Join  (cost=1.15..3.45 rows=20 width=36) (actual time=0.035..0.078 rows=18 loops=1)
  Hash Cond: (e.dept_id = d.dept_id)
  Buffers: shared hit=3
  ->  Seq Scan on employes e  (cost=0.00..2.00 rows=50 width=36) (actual time=0.005..0.015 rows=50 loops=1)
  ->  Hash  (cost=1.10..1.10 rows=4 width=4) (actual time=0.018..0.019 rows=4 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Seq Scan on departments d  (cost=0.00..1.10 rows=4 width=4) (actual time=0.007..0.010 rows=4 loops=1)
              Filter: (location_id = ANY ('{1,2}'::integer[]))
```

### Key Plan Metrics:
- **`Hash Semi Join`**: Demonstrates subquery unnesting.
- **`Memory Usage: 9kB`**: Shows the small memory footprint of the materialized inner hash key set.

---

## Cross Database Notes

| Engine | `IN` Optimization | `NOT IN` Optimization | `ANY`/`ALL` Rewrite |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | Unnests to Hash/Merge Semi Join. | Rewrites to Anti Join if non-nullable; else SubPlan. | Rewrites `> ANY` to `> MIN()` or Semi Join. |
| **MySQL 8.0+** | Materializes via `Materialized_From_Subquery`. | Uses `Anti-Join` optimization. | Converts to Subquery Materialization. |
| **SQL Server 2022**| Left Semi Join operator in Showplan. | Left Anti Semi Join operator. | Rewritten to scalar aggregates. |
| **Oracle 23c** | Semi-join transformation (`SJ`). | Anti-join transformation (`AJ`). | Unnested to inline views. |

---

## Common Mistakes

### The Deadly `NOT IN` NULL Trap
If a `NOT IN` subquery returns even **one `NULL` value**, the entire predicate evaluates to `UNKNOWN` for all outer rows, causing the query to return **0 rows**.

```sql
-- ❌ DANGEROUS: Returns ZERO ROWS if any department has location_id IS NULL
SELECT emp_name 
FROM employes 
WHERE dept_id NOT IN (SELECT dept_id FROM departments);

-- ✅ SAFE REWRITE: Filter NULLs explicitly or use NOT EXISTS
SELECT emp_name 
FROM employes 
WHERE dept_id NOT IN (SELECT dept_id FROM departments WHERE dept_id IS NOT NULL);
```

---

## Performance Notes

When the inner subquery result set exceeds available `work_mem`, PostgreSQL spills the hash table to disk (Batches $> 1$), causing high temporary file I/O. Tune `work_mem` for sessions executing heavy set membership subqueries.

---

## Production Notes

- **Query Parametrization**: Avoid constructing raw dynamic `IN (1, 2, 3, ... 1000)` literal strings in application code. Use array parameters (`WHERE col = ANY($1)`) or parameterized subqueries to preserve prepared statement execution plan caches.

---

## Real Company Example

### Airbnb: Regional Property Category Filtering
Airbnb filters listings located within active promotional cities:

```sql
SELECT 
    l.listing_id,
    l.property_name,
    l.nightly_price
FROM listings l
WHERE l.city_id IN (
    SELECT c.city_id
    FROM market_cities c
    WHERE c.region = 'NORTH_AMERICA'
      AND c.is_active = TRUE
);
```

---

## Engineering Notes

Quantified operators like `> ANY` are equivalent to scalar comparisons against aggregates:
- `x > ANY (SELECT y FROM T)` $\equiv$ `x > (SELECT MIN(y) FROM T)`
- `x > ALL (SELECT y FROM T)` $\equiv$ `x > (SELECT MAX(y) FROM T)`

Rewriting `> ANY` to `MIN()` explicitly allows the optimizer to utilize index min/max scans ($O(\log N)$) rather than unnesting multi-row sets.

---

## Interview Questions

### Q1: Why is `NOT EXISTS` preferred over `NOT IN` in production SQL?
**Answer**: `NOT EXISTS` utilizes 2-valued boolean logic based on tuple count ($>0$ or $=0$) and is completely immune to `NULL` values in the inner table. `NOT IN` uses 3-valued logic and will silently evaluate to `UNKNOWN` (returning 0 rows) if the subquery returns any `NULL` value.

---

## Summary

| Operator | Evaluates To | Best For | NULL Safe? |
| :--- | :--- | :--- | :--- |
| **`IN`** | True if key in set | Positive set matching | Yes |
| **`NOT IN`** | True if key not in set | Negative set matching | ❌ NO (Fails on NULL) |
| **`ANY` / `SOME`** | True if matches $\ge 1$ item | Quantified comparisons | Partial |
| **`ALL`** | True if matches all items | Global set bounding | Partial |

---

## Further Reading

- [PostgreSQL Documentation: Set Membership Expressions](https://www.postgresql.org/docs/current/functions-subquery.html#FUNCTIONS-SUBQUERY-IN)
- [Database Subquery Unnesting Architectures (VLDB Paper)](https://www.vldb.org)

---

## Related Modules

- [Module 03 — Joins](../03_Joins/README.md)
- [Module 04 — Subqueries: Topic 04 EXISTS & NOT EXISTS](./04_EXISTS_AND_NOT_EXISTS.md)
