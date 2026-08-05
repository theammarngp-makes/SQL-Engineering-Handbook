# EXISTS & NOT EXISTS: Semi-Joins, Anti-Joins & Short-Circuit Evaluation

The **`EXISTS`** and **`NOT EXISTS`** predicates evaluate the existence of tuples in a subquery expression. Unlike scalar or set-comparison operators that inspect column values, `EXISTS` tests whether the inner subquery returns **at least one row** ($|S| \ge 1$). This binary boolean check ($\text{TRUE}/\text{FALSE}$) enables database query engines to perform powerful **short-circuit evaluation**, stopping inner scans immediately upon finding the first matching tuple.

---

## Learning Objectives

- Master the relational semantics of Semi-Joins ($\ltimes$) and Anti-Joins ($\dashv$).
- Understand early-exit short-circuit processing mechanics in execution engines.
- Analyze why `SELECT 1`, `SELECT *`, or `SELECT NULL` inside `EXISTS` produce identical physical execution plans.
- Leverage `NOT EXISTS` as the bulletproof replacement for `NOT IN` in the presence of nullable columns.
- Optimize multi-table existence checks using composite B-Tree indexes.

---

## Business Context

Existence predicates underpin core transactional and analytical database operations:

- **E-Commerce Conversion Tracking**: Identifying registered users who have *never placed an order* (Anti-Join / Churn Analysis).
- **Compliance & Auditing**: Locating financial accounts that executed transactions *without an associated KYC verification record*.
- **Inventory Management**: Selecting warehouse locations containing active stock for backordered items.

---

## Concept

In relational algebra:
- **Semi-Join ($\ltimes$)**: Returns rows from outer relation $R$ for which there is at least one matching tuple in $S$:
  $$R \ltimes_{\theta} S = \{ r \in R \mid \exists s \in S : \theta(r, s) \}$$
- **Anti-Join ($\dashv$)**: Returns rows from outer relation $R$ for which there are **no** matching tuples in $S$:
  $$R \dashv_{\theta} S = \{ r \in R \mid \neg \exists s \in S : \theta(r, s) \}$$

Key Property: Neither Semi-Join nor Anti-Join will ever duplicate outer rows from $R$, regardless of how many matching tuples exist in $S$.

---

## Syntax

```sql
-- ANSI SQL EXISTS (Semi-Join)
SELECT 
    e.emp_id,
    e.emp_name
FROM employes e
WHERE EXISTS (
    SELECT 1 
    FROM departments d
    WHERE d.dept_id = e.dept_id
      AND d.location_id = 1
);

-- ANSI SQL NOT EXISTS (Anti-Join)
SELECT 
    d.dept_id,
    d.dept_name
FROM departments d
WHERE NOT EXISTS (
    SELECT 1 
    FROM employes e
    WHERE e.dept_id = d.dept_id
);
```

---

## Mental Model

Visualizing short-circuit execution:

```text
Outer Table Probe: Scan row e (dept_id = 1)
 └─ Inner Table Probe: Scan departments d WHERE d.dept_id = 1
     ├─ Tuple 1: dept_id=1, location_id=1 -> MATCH FOUND!
     └─ SHORT-CIRCUIT! Stop scanning 'departments' immediately. Return TRUE.

Outer Table Probe: Scan row d (dept_id = 5) [NOT EXISTS]
 └─ Inner Table Probe: Scan employes e WHERE e.dept_id = 5
     ├─ Tuple 1: e.dept_id=2 (no)
     ├─ Tuple 2: e.dept_id=3 (no)
     └─ End of Table. 0 matches found -> Return TRUE for NOT EXISTS.
```

---

## Execution Order

1. **Outer Row Fetch**: Outer table $R$ streams candidate tuple $r$.
2. **Inner Probe Initialization**: Inner table $S$ is probed using index lookup on the join key (`s.dept_id = r.dept_id`).
3. **First-Match Short Circuit**:
   - For `EXISTS`: As soon as 1 tuple matching predicate $\theta(r, s)$ is found, inner execution halts immediately, returning `TRUE`.
   - For `NOT EXISTS`: If 1 tuple matching predicate is found, inner execution halts immediately, returning `FALSE`.
4. **Tuple Emission**: Candidate tuple $r$ is emitted (or discarded) based on the boolean result.

---

## Optimizer Behaviour

Modern cost-based optimizers rewrite `EXISTS` and `NOT EXISTS` subqueries into physical **Hash Semi-Join**, **Nested Loop Semi-Join**, **Hash Anti-Join**, or **Nested Loop Anti-Join** operators.

- **Projection Agnosticism**: The optimizer completely ignores the SELECT list of the inner `EXISTS` subquery. Writing `SELECT 1`, `SELECT *`, or `SELECT 1/0` compiles into the exact same Abstract Syntax Tree (AST).

---

## Execution Plan Discussion

Annotated PostgreSQL plan showing `Hash Anti Join`:

```text
Hash Anti Join  (cost=1.15..3.40 rows=2 width=36) (actual time=0.040..0.065 rows=2 loops=1)
  Hash Cond: (d.dept_id = e.dept_id)
  Buffers: shared hit=3
  ->  Seq Scan on departments d  (cost=0.00..1.10 rows=10 width=36) (actual time=0.006..0.009 rows=10 loops=1)
  ->  Hash  (cost=1.00..1.00 rows=10 width=4) (actual time=0.020..0.021 rows=10 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Seq Scan on employes e  (cost=0.00..1.00 rows=50 width=4) (actual time=0.005..0.010 rows=50 loops=1)
```

---

## Cross Database Notes

| Engine | `EXISTS` Unnesting | `NOT EXISTS` Optimization | `SELECT` List Optimization |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | Hash Semi Join / Merge Semi Join. | Hash Anti Join. | Completely ignored (`SELECT *` $\equiv$ `SELECT 1`). |
| **MySQL 8.0+** | Converts to Semi-Join strategy. | FirstMatch / Materialization. | Rewritten to constant during parse. |
| **SQL Server 2022**| Left Semi Join. | Left Anti Semi Join. | Stripped out in query tree. |
| **Oracle 23c** | `SEMIJOIN` transformation. | `ANTIJOIN` transformation. | Replaced with `NULL` projection. |

---

## Common Mistakes

### 1. The `NOT IN` vs `NOT EXISTS` NULL Misunderstanding
`NOT IN` fails silently if the subquery contains a single `NULL`. `NOT EXISTS` is **completely immune** to `NULL` values in the inner subquery target column because `EXISTS` evaluates tuple counts ($>0$), not scalar boolean equality!

---

## Performance Notes

When searching for unmatched records between large tables ($N = 10,000,000$, $M = 10,000,000$), `NOT EXISTS` utilizing a **Hash Anti-Join** outperforms a `LEFT JOIN ... WHERE inner.id IS NULL` because `NOT EXISTS` does not require allocating memory for joined outer/inner record tuples.

---

## Production Notes

- **Primary Key Safety**: Always use `NOT EXISTS` for enterprise data auditing, record diffing, and ETL reconciliation scripts to guarantee zero false-negative empty outputs caused by unexpected `NULL` keys.

---

## Real Company Example

### Netflix: Unwatched Content Recommendations
Netflix identifies active user profiles that have *never watched* a newly released original series:

```sql
SELECT 
    p.profile_id,
    p.user_id
FROM user_profiles p
WHERE p.is_active = TRUE
  AND NOT EXISTS (
      SELECT 1
      FROM viewing_history v
      WHERE v.profile_id = p.profile_id
        AND v.title_id = 80192018 -- Target Movie Title ID
  );
```

---

## Engineering Notes

In relational algebra, `EXISTS` implements bounded existential quantification ($\exists$). Database engines utilize index range scans on the correlation key (`v.profile_id = p.profile_id`) to perform $O(\log M)$ index probes. When an index exists, Nested Loop Semi Join achieves sub-millisecond execution even on billion-row tables.

---

## Interview Questions

### Q1: Does writing `SELECT *` inside `EXISTS(...)` perform worse than `SELECT 1`?
**Answer**: No. Database parsers ignore the `SELECT` projection list inside `EXISTS` entirely. The optimizer evaluates existence based purely on table predicates and row counts ($>0$). `SELECT *`, `SELECT 1`, and `SELECT NULL` generate identical physical execution plans in all major SQL engines.

---

## Summary

| Feature | `EXISTS` | `NOT EXISTS` |
| :--- | :--- | :--- |
| **Relational Algebra** | Semi-Join ($\ltimes$) | Anti-Join ($\dashv$) |
| **Execution Mechanics**| Early exit on 1st match | Early exit on 1st match |
| **Outer Duplicates** | Never introduces duplicates | Never introduces duplicates |
| **NULL Handling** | 100% Safe | 100% Safe |

---

## Further Reading

- [PostgreSQL Documentation: EXISTS Subquery Expressions](https://www.postgresql.org/docs/current/functions-subquery.html#FUNCTIONS-SUBQUERY-EXISTS)
- [Use The Index, Luke: Semi-Joins & Anti-Joins](https://use-the-index-luke.com)

---

## Related Modules

- [Module 03 — Joins](../03_Joins/README.md)
- [Module 04 — Subqueries: Topic 05 IN & ANY/ALL](./05_IN_AND_ANY_ALL.md)
