# The Cost-Based Optimizer

## Introduction

Every earlier lesson referenced "the optimizer" as a black box that picks
plans based on cost. This lesson opens that box: what statistics it uses,
how it estimates cardinality, why estimates go wrong, and what you can
actually do about it. This is the chapter that separates "I can read
EXPLAIN" from "I understand why the optimizer chose this plan."

## Learning Objectives

- Explain what table/column statistics the optimizer maintains and how
  they're gathered
- Understand histograms and why they exist beyond simple row counts
- Define cardinality estimation and selectivity, and connect them to plan
  choice
- Recognize the symptoms of stale statistics and bad estimates in
  `EXPLAIN ANALYZE` output
- Understand parameter sniffing and why it produces "it's fast for me,
  slow for them" bug reports
- Know when optimizer hints are an appropriate tool and when they're a
  code smell

## Why This Exists

Every technique in Lessons 01–07 assumes the optimizer's cost estimates
are roughly accurate. When they aren't, none of those techniques behave as
predicted — an index that should obviously help gets ignored, a join order
that should obviously be cheap gets flipped. This lesson is about the
layer underneath all of that: where the optimizer's numbers actually come
from.

## Business Motivation

A logistics company's warehouse-fulfillment query runs fine for months,
then suddenly runs 40x slower overnight — no deploy, no schema change. The
cause, eventually found: a bulk import doubled the `inventory` table's row
count, but statistics hadn't been refreshed, so the optimizer was still
costing plans as if the table were half its actual size. This is one of
the most common "nothing changed but it broke" production stories in SQL
engineering, and it's invisible without understanding this chapter.

## Statistics: What the Optimizer Actually Knows

Before planning any query, the optimizer consults stored **statistics**
about each table and column — not the live data itself:

- Approximate row count per table
- Distinct value count per column (used for selectivity)
- Most common values and their frequencies
- Data distribution (via histograms, below)
- Correlation between physical row order and column value order

These are gathered by an explicit or automatic maintenance process
(`ANALYZE` in PostgreSQL/MySQL, `UPDATE STATISTICS` in SQL Server) — **not**
continuously, and **not** for free. A table that changes heavily between
statistics refreshes is planning against an increasingly wrong picture of
itself.

```sql
-- MySQL 8.0+: refresh statistics for one table
ANALYZE TABLE employes;

-- MySQL 8.0+: create histograms for better selectivity estimates
ANALYZE TABLE employes UPDATE HISTOGRAM ON dept_id WITH 100 BUCKETS;

-- MySQL 8.0+: inspect histogram metadata
SELECT COLUMN_NAME, HISTOGRAM->>'$."histogram-type"' AS type
FROM information_schema.COLUMN_STATISTICS
WHERE SCHEMA_NAME = DATABASE() AND TABLE_NAME = 'employes';
```

```sql
-- PostgreSQL equivalent:
-- ANALYZE employes;
-- SELECT attname, n_distinct, most_common_vals
-- FROM pg_stats
-- WHERE tablename = 'employes' AND attname = 'dept_id';
```

## Histograms

A row count and a distinct-value count alone can't tell the optimizer
whether a column's values are evenly distributed or heavily skewed. A
**histogram** buckets a column's values so the optimizer can estimate
selectivity for a *specific* filter value, not just an average across all
values.

Example: `dept_id` has 40 distinct values, but department 4 (Engineering)
holds 60% of all employees while the other 39 departments split the
remaining 40%. Without a histogram, the optimizer might assume every
department holds roughly 1/40th of rows — wildly wrong for department 4,
and it would underestimate the cost of `WHERE dept_id = 4` accordingly.

## Cardinality Estimation and Selectivity

**Cardinality estimation** is the optimizer's prediction of how many rows
a step in the plan will produce. **Selectivity** is the fraction of rows a
predicate is expected to keep (`selectivity = estimated matching rows /
total rows`). Every cost calculation the optimizer performs — which join
algorithm, which index, which join order — is built on top of cardinality
estimates propagated up through the plan tree. A wrong estimate early in
the tree compounds: the optimizer costs everything above it based on a
number that was already wrong.

## When Estimates Go Bad

| Symptom | Likely cause |
|---|---|
| `EXPLAIN ANALYZE` shows estimated rows wildly different from actual rows | Stale statistics, or a correlated/complex predicate the optimizer can't model accurately |
| A previously-fast query gets suddenly slow after a bulk load/delete | Statistics weren't refreshed after a large data volume change |
| A query is fast with one parameter value and slow with another, same plan structure | Data skew the optimizer's histogram didn't capture finely enough, or **parameter sniffing** (below) |
| Multi-column filter (`WHERE a = 1 AND b = 2`) estimated far too low/high | Optimizer assumes columns are independent by default; correlated columns need extended/multi-column statistics |

## Parameter Sniffing

Many engines cache a query plan the first time a parameterized query runs,
using that first call's parameter value to estimate cardinality — then
reuse the *same* cached plan for every subsequent call, even with very
different parameter values. This behavior is most pronounced in **SQL
Server** stored procedures. PostgreSQL re-evaluates custom vs. generic
plans (see `plan_cache_mode`). MySQL prepared statements do not cache
execution plans globally across connections, but application-level caching
or ORM query plan reuse can produce similar symptoms.

```sql
-- SQL Server example (T-SQL):
-- First call: dept_id = 4 (Engineering, 60% of all rows)
-- Optimizer picks a plan appropriate for "this predicate matches most of the table"
-- EXEC GetEmployeesByDept @dept_id = 4;

-- Later call: dept_id = 27 (Facilities, 0.1% of rows)
-- The CACHED plan from the first call gets reused — wrong for this parameter
-- EXEC GetEmployeesByDept @dept_id = 27;
```

This produces the classic "it's fast when I test it, slow for the
customer" bug report — the plan cached from a developer's typical test
value doesn't match a production caller's actual value.

## Optimizer Hints

Hints (`FORCE INDEX`, `USE HASH`, query hints in SQL Server, `pg_hint_plan`
extension in PostgreSQL) let you override the optimizer's choice directly.

**Use them when:**
- You've confirmed via `EXPLAIN` that the optimizer's estimate is wrong for
  a specific, well-understood reason (e.g. known data skew statistics
  can't capture) and a statistics fix isn't available or sufficient
- A specific, business-critical query has a hard latency SLA and you need
  guaranteed plan stability more than you need the optimizer's flexibility

**Avoid them when:**
- You haven't looked at `EXPLAIN` yet — a hint is a targeted override, not
  a first response to "this feels slow"
- The real fix is a missing index or stale statistics — a hint masks the
  root cause instead of fixing it, and will silently stop helping (or
  start hurting) as data changes

A hint is a maintenance liability: it pins a decision the optimizer would
otherwise keep re-evaluating as data changes, which means someone has to
remember to revisit it.

## Engineering Notes

- Statistics refresh is itself a cost — on very large tables, a full
  `ANALYZE` can be expensive, which is why most engines support sampling
  (approximate statistics from a subset of rows) rather than scanning
  every row.
- Extended statistics (`CREATE STATISTICS` in PostgreSQL, multi-column
  statistics in SQL Server) exist specifically to fix the "optimizer
  assumes column independence" problem for columns that are known to be
  correlated in your actual data.

## MySQL / PostgreSQL / SQL Server Notes

- **PostgreSQL**: statistics detail is controlled by
  `default_statistics_target` (higher = more histogram buckets, more
  accurate but more expensive to gather); `pg_stats` exposes everything the
  planner knows per column.
- **MySQL**: histogram statistics were added in 8.0 (`ANALYZE TABLE ...
  UPDATE HISTOGRAM`); earlier versions relied on simpler index
  cardinality estimates only.
- **SQL Server**: auto-updates statistics by default based on a
  change-threshold, and is well known for "parameter sniffing" issues on
  stored procedures — `OPTION (RECOMPILE)` or `OPTIMIZE FOR` hints are
  common mitigations.

## Additional Dialect Notes

- **Oracle**: `DBMS_STATS` package manages statistics gathering explicitly,
  including histogram creation (`METHOD_OPT` parameter) and adaptive
  cursor sharing to mitigate parameter sniffing.
- **SQLite**: maintains much simpler statistics (`ANALYZE` populates
  `sqlite_stat1`), consistent with its lightweight embedded design.
- **DuckDB**: as an analytical/columnar engine, leans on automatic,
  lightweight statistics (zone maps, min/max per data chunk) gathered
  during data loading rather than a separate manual statistics step.

## Common Mistakes

- Assuming statistics are always current without checking last-refresh
  time on a table that changed significantly
- Reaching for an optimizer hint before checking `EXPLAIN` for the actual
  cause
- Assuming multi-column predicates are estimated accurately by default
  when the columns are correlated

## Interview Questions

- "What's the difference between cardinality estimation and selectivity?"
- "Explain parameter sniffing and how you'd diagnose it in production."
- "When is an optimizer hint the right tool, and when is it a red flag?"

## Summary

The optimizer's every decision — join algorithm, index usage, join order —
rests on cardinality estimates built from statistics. When those
statistics are stale, coarse, or can't capture correlation between
columns, every downstream decision inherits the error. Understanding
*this* layer is what turns "the optimizer picked a bad plan" from a
mystery into a diagnosis.

## Practice Challenges

1. Explain, in your own words, why a bulk data load can make a previously
   fast query slow with zero code changes.
2. Design a scenario (like the parameter-sniffing example above) using the
   handbook's `employes`/`departments` schema, and explain what plan
   caching behavior would cause it.

## Further Reading

- PostgreSQL documentation: "Row Estimation Examples" and "Planner Cost
  Constants"
- SQL Server documentation: "Parameter Sniffing" troubleshooting guide
- Oracle documentation: `DBMS_STATS` package reference
