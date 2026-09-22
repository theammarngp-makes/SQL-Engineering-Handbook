# Benchmark Guide — Query Optimization

Methodology for measuring query performance before and after optimization changes. Use with the [Performance_lab/](./Performance_lab/) exercises.

---

## Why Benchmark?

Optimization without measurement is guessing. A benchmark provides:

- **Baseline** — actual time before any change
- **Evidence** — proof that a change helped (or didn't)
- **Regression detection** — catching when a fix stops working after data growth

---

## Benchmark Methodology

### 1. Environment Setup

| Requirement | Detail |
|---|---|
| Data volume | Production-representative (not sample data) |
| Engine version | Same as production |
| Configuration | Same `work_mem`, buffer pool, etc. |
| Isolation | No concurrent queries during benchmark |
| Cache state | Test both cold and warm cache |

### 2. Measurement Commands

```sql
-- PostgreSQL: full diagnostic
EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT ... ;

-- MySQL
EXPLAIN ANALYZE
SELECT ... ;

-- SQL Server
SET STATISTICS IO, TIME ON;
-- run query, inspect plan
```

### 3. Metrics to Record

| Metric | Source | Why |
|---|---|---|
| Total actual time | EXPLAIN ANALYZE | Primary success metric |
| Most expensive node time | Plan tree | Identifies bottleneck |
| Estimated vs. actual rows | Plan nodes | Statistics health |
| Buffer hits vs. reads | BUFFERS (PG) | Cache vs. disk I/O |
| Rows returned | Query result | Correctness check |

### 4. Run Protocol

1. **Warm up**: Run query once to populate buffer cache (discard this result)
2. **Baseline**: Run 5 times, record median actual time
3. **Apply one change** (index, rewrite, or ANALYZE)
4. **Re-measure**: Run 5 times, record median actual time
5. **Compare**: Calculate improvement percentage
6. **Verify correctness**: Compare row counts and sample results

### 5. Statistical Reporting

Report these values from your 5 runs:

| Statistic | Use |
|---|---|
| **Median** | Primary reported value (resistant to outliers) |
| **Average** | Secondary reference |
| **P95** | Worst-case performance |
| **Min** | Best-case (warm cache, optimal plan) |

---

## Cold vs. Warm Cache

| Cache State | How to Achieve | When to Test |
|---|---|---|
| Cold | Restart engine or `DISCARD ALL` + read unrelated data | First query after deployment |
| Warm | Run query once before measuring | Steady-state production |

A query that's fast warm but slow cold is I/O-bound — the plan shape is fine, but data isn't cached.

---

## Benchmark Template

```markdown
## Benchmark: [Query Name]

**Date**: YYYY-MM-DD
**Engine**: PostgreSQL 15.x
**Data volume**: employes = 5M rows
**Configuration**: work_mem = 64MB

| Version | Median (ms) | P95 (ms) | Plan Node | Rows |
|---|---|---|---|---|
| Baseline (v0) | | | Seq Scan | |
| After index (v1) | | | Index Scan | |
| After rewrite (v2) | | | Hash Join | |

**Change applied**: [describe single change]
**Improvement**: [percentage]
**Correctness verified**: [yes/no, row count match]
```

---

## Common Benchmark Mistakes

1. **Benchmarking on sample data** — 50 rows hides every optimization technique
2. **Changing multiple things at once** — can't attribute improvement
3. **Using EXPLAIN estimates instead of ANALYZE actuals** — estimates lie
4. **Single run** — one run is noise; use median of 5+ runs
5. **Ignoring cache state** — cold vs. warm can differ 10×
6. **Not verifying correctness** — faster wrong answer is worse than slow correct one

---

## Performance Lab

Hands-on benchmark exercises with baseline queries and progressive optimizations:

→ [Performance_lab/README.md](./Performance_lab/README.md)

---

## Related Documents

- [07 — Query Tuning Workflow](./07_QUERY_TUNING_WORKFLOW.md)
- [OPTIMIZATION_PLAYBOOK.md](./OPTIMIZATION_PLAYBOOK.md)
- [Performance_lab/](./Performance_lab/)
