# Topic 09: Subquery Optimization & Benchmark Lab

Database optimizers do not execute SQL queries literally as written. Instead, the Cost-Based Optimizer (CBO) parses the input SQL into a logical operator tree, applies transformation rules to simplify subquery expressions, and selects a physical execution plan based on statistical cost estimates. This document explores subquery decorrelation, unnesting heuristics, predicate pushdown, and illustrative performance benchmarks across datasets scaling from **100,000 to 50,000,000 rows**.

> **A note on the numbers below**: the timings, buffer counts, and memory figures in this lab are **modeled estimates**, not measurements captured from an actual provisioned run — they're derived from the cost-model math in the Theory section, scaled realistically, to illustrate the *shape* of the O(N × M) vs O(N + M) divergence. The relative pattern (roughly two-orders-of-magnitude gap, widening with scale, ending in timeout/OOM for the correlated form) reflects real, well-documented optimizer behavior. The specific millisecond values do not. If you need numbers to justify a production decision, run this lab's methodology (below) against your own hardware, data distribution, and PostgreSQL version — do not cite these figures directly.

---

## Learning Objectives

- Master Cost-Based Optimizer (CBO) subquery transformation rules.
- Analyze empirical benchmark statistics across 100K, 1M, 10M, and 50M row scales.
- Compare Cold Cache vs Warm Cache performance profiles.
- Evaluate shared buffer hit rates, CPU cycles, and memory allocation (`work_mem`).
- Tune database GUC session parameters for subquery optimization.

---

## Engineering Context

Database engines optimize queries by estimating cardinalities and disk page I/O costs using table statistics (`pg_statistic` in PostgreSQL). Understanding cost calculation algorithms allows engineers to predict when an optimizer will unnest a subquery into a Hash Semi-Join versus falling back to a `SubPlan`.

---

## Business Context

In hyper-scale applications (e.g. PayPal, Amazon, Uber), query execution profiles directly determine infrastructure server costs and user latencies. Choosing optimized set-based subqueries prevents unexpected database lock contention during traffic spikes.

---

## Mental Model

```text
Query Scale (Rows)    Correlated SubPlan (~ms)   Unnested Hash Semi Join (~ms)
──────────────────    ───────────────────────    ────────────────────────────
 100,000               ~1,250 ms                  ~12 ms
 1,000,000             ~18,400 ms                 ~95 ms
 10,000,000            Times out (>300s)          ~840 ms
 50,000,000            Outage risk (OOM)           ~4,120 ms
```
*Modeled, not measured — see the disclosure under "Benchmark Lab" below.*

---

## Theory

The optimizer cost model calculates total query execution cost as:
$$\text{Cost} = (\text{Page Fetches} \times \text{seq\_page\_cost}) + (\text{Row Scans} \times \text{cpu\_tuple\_cost}) + (\text{Operator Evaluations} \times \text{cpu\_operator\_cost})$$

Unnesting a subquery eliminates the multiplicative tuple cost factor ($\text{Outer Rows} \times \text{Inner Rows}$).

---

## Benchmark Lab (100K to 50M Rows)

### Experimental Setup

**This is a reference configuration for you to reproduce the lab yourself, not the setup that produced the numbers below** (see the disclosure above — those are modeled, not measured).

- **Database Engine**: PostgreSQL 16.2 running on 16 vCPU, 64 GB RAM, NVMe SSD Storage.
- **Dataset**: `employes` relation scaled from $10^5$ to $5 \times 10^7$ rows with uniform department distribution.
- **Workload**: Correlated Subquery vs Unnested Hash Semi-Join.
- **Methodology if you run this yourself**: generate the scaled dataset with `generate_series`, run `ANALYZE`, capture cold-cache timing after `RESTART`/OS cache drop, then capture warm-cache timing on an immediate re-run, using `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` for both.

---

### Scenario A: 100,000 Rows Benchmark (Modeled)

| Metric | Correlated SubPlan (Unoptimized) | Unnested Hash Semi Join (Optimized) |
| :--- | :--- | :--- |
| **Execution Time (Cold Cache)** | $1,420\text{ ms}$ | $28\text{ ms}$ |
| **Execution Time (Warm Cache)** | $1,180\text{ ms}$ | $11\text{ ms}$ |
| **Planning Time** | $0.18\text{ ms}$ | $0.24\text{ ms}$ |
| **CPU Utilization** | $98\%\text{ (Single Core)}$ | $12\%\text{ (Single Core)}$ |
| **Shared Buffer Hits** | $42,100\text{ pages}$ | $850\text{ pages}$ |
| **Memory Usage (`work_mem`)** | $32\text{ KB}$ | $1.2\text{ MB}$ |
| **Optimizer Estimated Cost** | `cost=0.00..125400.00` | `cost=1.15..1850.00` |

---

### Scenario B: 1,000,000 Rows Benchmark (Modeled)

| Metric | Correlated SubPlan (Unoptimized) | Unnested Hash Semi Join (Optimized) |
| :--- | :--- | :--- |
| **Execution Time (Cold Cache)** | $22,400\text{ ms}$ | $185\text{ ms}$ |
| **Execution Time (Warm Cache)** | $17,800\text{ ms}$ | $88\text{ ms}$ |
| **Planning Time** | $0.21\text{ ms}$ | $0.29\text{ ms}$ |
| **CPU Utilization** | $100\%\text{ (Starving Worker)}$ | $18\%$ |
| **Shared Buffer Hits** | $418,000\text{ pages}$ | $8,450\text{ pages}$ |
| **Memory Usage (`work_mem`)** | $32\text{ KB}$ | $12.4\text{ MB}$ |
| **Optimizer Estimated Cost** | `cost=0.00..1254000.00` | `cost=1.15..18500.00` |

---

### Scenario C: 10,000,000 Rows Benchmark (Modeled)

| Metric | Correlated SubPlan (Unoptimized) | Unnested Hash Semi Join (Optimized) |
| :--- | :--- | :--- |
| **Execution Time (Cold Cache)** | 🚨 **TIMED OUT (> 300s)** | $1,850\text{ ms}$ |
| **Execution Time (Warm Cache)** | 🚨 **TIMED OUT (> 300s)** | $790\text{ ms}$ |
| **Planning Time** | $0.25\text{ ms}$ | $0.35\text{ ms}$ |
| **CPU Utilization** | $100\%\text{ (Core Lockup)}$ | $42\%$ |
| **Shared Buffer Hits** | $> 4,000,000\text{ pages}$ | $84,200\text{ pages}$ |
| **Memory Usage (`work_mem`)** | N/A | $124\text{ MB}$ |
| **Optimizer Estimated Cost** | `cost=0.00..12540000.00` | `cost=1.15..185000.00` |

---

### Scenario D: 50,000,000 Rows Benchmark (Modeled)

| Metric | Correlated SubPlan (Unoptimized) | Unnested Hash Semi Join (Optimized) |
| :--- | :--- | :--- |
| **Execution Time (Cold Cache)** | 💥 **CRASH / OUTAGE** | $8,450\text{ ms}$ |
| **Execution Time (Warm Cache)** | 💥 **CRASH / OUTAGE** | $3,920\text{ ms}$ |
| **Planning Time** | $0.32\text{ ms}$ | $0.42\text{ ms}$ |
| **CPU Utilization** | $100\%\text{ (Pool Exhaustion)}$| $65\%$ |
| **Shared Buffer Hits** | N/A | $421,000\text{ pages}$ |
| **Memory Usage (`work_mem`)** | N/A | $620\text{ MB (Parallel Hash)}$ |
| **Optimizer Estimated Cost** | `cost=0.00..62700000.00` | `cost=1.15..925000.00` |

---

## Execution Order

1. **Inner Hash Build**: Building hash table of inner key attributes ($M$ rows).
2. **Outer Probe Stream**: Streaming $N$ outer tuples through memory hash buckets.

---

## Optimizer Behaviour

- **`enable_hashjoin = on`**: Allows optimizer to select Hash Semi Join.
- **`work_mem` Allocation**: If inner hash table size exceeds `work_mem`, PostgreSQL partitions execution into multiple disk batches (`Batches > 1`).

---

## Execution Plan

Inspect `EXPLAIN (ANALYZE, BUFFERS)` output for `Hash Semi Join` to verify `Batches: 1` and memory consumption.

---

## Performance Notes

For 50M+ row tables, ensure `work_mem` is configured to at least `256MB` for analytical batch sessions to keep hash tables in RAM.

---

## Cross Database Notes

| Engine | 50M Parallel Hash Join | Max Hash Memory Config |
| :--- | :--- | :--- |
| **PostgreSQL 16+** | Parallel Hash Join supported. | `work_mem` per node. |
| **MySQL 8.0+** | Block Nested Loop / Hash Join. | `join_buffer_size`. |
| **SQL Server 2022**| Parallel Hash Spills to TempDB. | `max grant %`. |
| **Oracle 23c** | Parallel Execution (`PX`). | `PGA_AGGREGATE_TARGET`. |

---

## Edge Cases

- **Memory Spills**: When `work_mem` is insufficient, the planner spills hash batches to temporary disk files, increasing execution time by 5x–10x.

---

## Failure Cases

- **Out of Memory (OOM) Killer**: Setting `work_mem` too high under high concurrency can trigger OS OOM process termination.

---

## Common Mistakes

- Ignoring temporary file spills in `EXPLAIN ANALYZE` (`Buffers: temp read=...`).

---

## Production Notes

- Set `work_mem = '128MB'` selectively at the session level for heavy analytics reports (`SET LOCAL work_mem = '128MB';`).

---

## Real Company Example

### Snowflake & Databricks: Dynamic Pruning
Data warehouse engines dynamically push down subquery filter min/max values to prune micro-partitions before scanning 50M+ row tables.

---

## Engineering Tips

- Monitor `pg_stat_database.temp_bytes` to detect disk-spilling subquery hash joins in production.

---

## Interview Questions

### Q1: What causes a Hash Semi Join to spill to disk during subquery evaluation?
**Difficulty**: Staff Engineer  
**Expected Answer**: When the memory size of the inner table's unique hash keys exceeds `work_mem`, PostgreSQL splits the hash table into multiple batches (`Batches > 1`) and writes overflow tuples to temporary disk files.  
**Reasoning**: Spilling to disk prevents RAM exhaustion but increases disk I/O latency.  
**Follow-up Questions**: How do you tune `work_mem` safely without triggering OOM errors under 500 concurrent connections?

---

## Practice

See [`15_PRACTICE_PROBLEMS.md`](./15_PRACTICE_PROBLEMS.md).

---

## Summary

| Scale | SubPlan Execution | Hash Semi Join | Performance Delta |
| :--- | :--- | :--- | :--- |
| **100K Rows** | $1,180\text{ ms}$ | $11\text{ ms}$ | **107x Faster** |
| **1M Rows** | $17,800\text{ ms}$ | $88\text{ ms}$ | **202x Faster** |
| **10M Rows** | Timeout ($>300\text{s}$) | $790\text{ ms}$ | **> 380x Faster** |
| **50M Rows** | Outage | $3,920\text{ ms}$ | **Production Resilient** |

---

## Related Modules & Further Reading

- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
- [Module 10 — Execution Plans](./10_EXECUTION_PLANS.md)
