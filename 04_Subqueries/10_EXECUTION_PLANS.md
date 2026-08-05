# Reading Subquery Execution Plans: EXPLAIN ANALYZE Deep-Dive

Reading and interpreting database execution plans is a mandatory skill for senior database engineers. Execution plans reveal the physical operators selected by the Cost-Based Optimizer (CBO), including row estimates, actual elapsed execution time, memory usage, and shared buffer I/O hits. This guide details how to identify, analyze, and optimize every subquery-related node in PostgreSQL and standard relational database engines.

---

## Learning Objectives

- Read and interpret `EXPLAIN (ANALYZE, BUFFERS)` trees for subqueries.
- Identify `InitPlan` vs `SubPlan` execution nodes.
- Recognize physical join operators: `Hash Semi Join`, `Nested Loop Anti Join`, `Merge Semi Join`.
- Analyze shared buffer hit rates, disk spills (`work_mem`), and iteration loops.
- Diagnose estimation skew (`rows=X` vs `actual rows=Y`).

---

## Key Subquery Execution Plan Nodes

| Node Type | Execution Behavior | Performance Profile |
| :--- | :--- | :--- |
| **`InitPlan N`** | Evaluated **ONCE** before main query starts. Output cached as variable `$0`. | Excellent ($\mathcal{O}(1)$ execution). |
| **`SubPlan N`** | Evaluated **REPEATEDLY** (once per outer row). Listed with `loops=N`. | Severe Bottleneck ($\mathcal{O}(N)$ loops). |
| **`Hash Semi Join`** | Unnested `IN`/`EXISTS` subquery. Inner table hashed into RAM. | Fast Linear ($\mathcal{O}(N + M)$). |
| **`Hash Anti Join`** | Unnested `NOT EXISTS`/`NOT IN` subquery. Filters matching keys. | Fast Linear ($\mathcal{O}(N + M)$). |
| **`Materialize`** | Caches inner subquery tuple stream in memory or temp file. | Moderate ($\mathcal{O}(M)$ setup). |

---

## Annotated Plan Breakdown: InitPlan (Scalar Subquery)

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

### Analysis Checklist:
1. **`InitPlan 1 (returns $0)`**: Evaluates inner subquery once. Stores output in `$0`.
2. **`Filter: (hire_date < $0)`**: Main scan applies the cached scalar `$0` without re-running the inner subquery.
3. **Total Shared Hit Buffers**: $4 + 2 = 6$ buffer page hits ($48\text{ KB}$).

---

## Annotated Plan Breakdown: SubPlan Danger (Correlated Loop)

```text
Seq Scan on employes e  (cost=0.00..62.50 rows=3 width=40) (actual time=0.045..0.215 rows=5 loops=1)
  Filter: (hire_date = (SubPlan 1))
  SubPlan 1
    ->  Aggregate  (cost=1.22..1.23 rows=1 width=4) (actual time=0.003..0.003 rows=1 loops=50)
          Buffers: shared hit=200
          ->  Seq Scan on employes d_emp  (cost=0.00..1.22 rows=2 width=4) (actual time=0.001..0.002 rows=2 loops=50)
                Filter: (dept_id = e.dept_id)
```

### Red Flag Warning Signals:
- 🚨 **`SubPlan 1`**: Correlated subquery failed to decorrelate.
- 🚨 **`loops=50`**: Subquery was re-executed 50 times!
- 🚨 **`Buffers: shared hit=200`**: High I/O overhead. Must be rewritten to a Join or Window Function!

---

## Summary

When analyzing execution plans, always search for the keyword **`SubPlan`**. If `SubPlan` appears with a high `loops` count, the query is suffering from row-by-row correlation and should be refactored immediately.

---

## Related Modules

- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
- [Module 09 — Subquery Optimization](./09_SUBQUERY_OPTIMIZATION.md)
