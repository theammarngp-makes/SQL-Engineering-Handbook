# Engineering Checklists & Troubleshooting Guide: Subqueries

This document provides database platform engineers, site reliability engineers (SREs), and senior SQL developers with a general-purpose diagnostic flowchart and 6 comprehensive engineering checklists to run **before** subquery code reaches production.

**How this differs from [Module 12 — Production Incidents](./12_PRODUCTION_INCIDENTS.md):** that document is a set of specific, narrative postmortems — what actually happened, in five real outages, root-caused after the fact. This document is the reusable, symptom-first decision tool you'd reach for *during* an active incident or a pre-release review, independent of any single case. Read Module 12 to see these failure modes play out in full detail; use this document's flowchart and checklists to catch or diagnose them faster next time.

---

## Diagnostic Troubleshooting Flowchart

```text
Query Slow or Timing Out?
 │
 ├─ Run EXPLAIN (ANALYZE, BUFFERS)
 │   │
 │   ├─ Contains "SubPlan" with loops > 1?
 │   │     └─► Correlated subquery re-executing per outer row (see Incident 1, Incident 3).
 │   │         FIX: Rewrite to Hash Semi-Join, Window Function, or add a covering index
 │   │         on the correlation key + any co-filtered column.
 │   │
 │   ├─ Contains "Seq Scan" on a large table inside a SubPlan?
 │   │     └─► Missing index on the correlation predicate (see Incident 3).
 │   │         FIX: CREATE INDEX CONCURRENTLY on the correlated join key(s).
 │   │
 │   ├─ Contains "Materialize" with high actual time?
 │   │     └─► CTE or derived table materialized instead of inlined, blocking pushdown.
 │   │         FIX: Check CTE MATERIALIZED/NOT MATERIALIZED hint (PG 12+), or restructure
 │   │         so filters can be pushed into the derived table.
 │   │
 │   ├─ Contains "Batches: N" where N > 1 on a Hash node?
 │   │     └─► Hash table spilled to disk — work_mem too small for the join's build side.
 │   │         FIX: Raise work_mem for the session/query, or reduce inner-side row count
 │   │         before the join.
 │   │
 │   └─ Row count changed sharply since last known-good run, with no code change?
 │         └─► Data volume growth crossed a performance cliff (see Incident 4).
 │             FIX: Re-run ANALYZE to refresh planner statistics; re-evaluate whether the
 │             existing plan shape is still appropriate at current scale.
 │
 └─ Query Returning Unexpected Row Count (Wrong, Not Slow)?
     │
     ├─ Uses "NOT IN" and returns 0 rows unexpectedly?
     │     └─► 3-Valued Logic NULL trap (see Incident 2).
     │         FIX: Replace with NOT EXISTS; audit whether the target column is nullable.
     │
     └─ Recently rewrote EXISTS/IN into an INNER JOIN, and row counts increased?
           └─► Semi-Join → Join rewrite duplicated rows via a many-to-one relationship
               (see Incident 5).
               FIX: Revert to EXISTS/IN, or add DISTINCT / pre-aggregate the inner side
               if a JOIN is truly required.
```

Each flowchart branch above links to the specific incident in Module 12 that produced it in production — use that postmortem for the full execution-plan and fix detail beyond what fits in this decision tree.

---

## 1. Before Production Checklist

- [ ] **1. `NOT IN` Nullability Audit**: Verified that zero `NOT IN` subqueries target nullable columns.
- [ ] **2. Anti-Join Compliance**: Confirmed `NOT EXISTS` is used for all unmatched set operations.
- [ ] **3. SubPlan Elimination**: Verified `EXPLAIN ANALYZE` contains zero `SubPlan` nodes with `loops > 1`.
- [ ] **4. Scalar Projection Guard**: Confirmed `SELECT` projection list does not contain correlated scalar subqueries.
- [ ] **5. Indexing Coverage**: B-Tree secondary indexes exist on all subquery correlation join keys.
- [ ] **6. Materialization Check**: Verified `work_mem` is sufficient to keep subquery hash tables in RAM (`Batches: 1`).

---

## 2. Before Code Merge (PR Review) Checklist

- [ ] **1. Mandatory Aliases**: All derived tables in `FROM` / `JOIN` clauses maintain explicit table aliases.
- [ ] **2. Duplicate Protection**: Verified `EXISTS` to `JOIN` rewrites do not introduce row duplication.
- [ ] **3. COALESCE Protection**: Projected scalar subqueries are wrapped in `COALESCE(..., 0)` to handle empty set NULL projections.
- [ ] **4. Parameterization**: Dynamic subqueries use parameterized arrays (`= ANY($1)`).

---

## 3. Before Deployment Checklist

- [ ] **1. Migration Lock Timeout**: Set `lock_timeout = '5s'` for DDL migrations adding indexes for subqueries.
- [ ] **2. Staging Load Verification**: Executed subquery against 10M+ row staging dataset.
- [ ] **3. Connection Pool Metric**: Confirmed no connection pool thread spikes under staging canary load.

---

## 4. Before Performance Testing Checklist

- [ ] **1. Cache Cold/Warm Split**: Measured baseline execution time on cold cache vs warm cache.
- [ ] **2. Shared Buffer Hit Ratio**: Verified shared buffer hits exceed $99\%$.
- [ ] **3. Temp Disk File Check**: Confirmed `pg_stat_database.temp_bytes` did not increment during test execution.

---

## 5. Before Benchmarking Checklist

- [ ] **1. Scale Range**: Tested against 100K, 1M, 10M, and 50M row scales.
- [ ] **2. Hardware Consistency**: Isolated benchmark environment to dedicated vCPU and RAM.
- [ ] **3. Statistics Refresh**: Ran `ANALYZE` prior to executing benchmark runs.

---

## 6. Before Technical Interview Checklist

- [ ] **1. Semi-Join Definition**: Can formally explain Semi-Join ($\ltimes$) and short-circuit evaluation.
- [ ] **2. 3-Valued Logic Matrix**: Can write out the truth table for `NOT IN` vs `NOT EXISTS` under `NULL`.
- [ ] **3. SubPlan vs InitPlan**: Can explain `InitPlan` ($\mathcal{O}(1)$) vs `SubPlan` ($\mathcal{O}(N)$) execution nodes.

---

## Related Modules

- [Module 10 — Execution Plans](./10_EXECUTION_PLANS.md)
- [Module 12 — Production Incidents](./12_PRODUCTION_INCIDENTS.md)
