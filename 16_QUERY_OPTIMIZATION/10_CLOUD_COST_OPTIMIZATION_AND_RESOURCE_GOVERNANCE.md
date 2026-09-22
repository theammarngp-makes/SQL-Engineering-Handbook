# Cloud Cost Optimization & Resource Governance

## Introduction

Every lesson before this one optimized for one thing: time. This lesson
optimizes for a second, equally real production constraint: **money**. On a
self-hosted, fixed-capacity server, a bad query wastes CPU cycles you already
paid for. On a consumption-billed cloud engine, the exact same bad query
generates an invoice. Query optimization and cost optimization overlap
heavily, but they are not the same discipline — a query can be fast and
still expensive, and (less intuitively) a query can be cheap and still slow.
This lesson teaches you to read `EXPLAIN` output the way a finance team reads
a bill.

> **Schema note:** this lesson's SQL lab uses the handbook's shared
> `transactions` table (part of `00_Schema.sql`), the module's documented
> extension to the core `employes`/`departments`/`locations` schema.

## Learning Objectives

- Map `EXPLAIN` / query-profile metrics to the specific line item they
  generate on a cloud bill, for BigQuery, Snowflake, Redshift, and RDS/Aurora
- Distinguish the four dominant cloud SQL cost models: bytes scanned,
  compute-credits, provisioned IOPS, and storage
- Apply cost-aware indexing and partitioning strategies that reduce spend,
  not just latency
- Write waste-detection queries against each engine's own metadata to find
  the worst-offending queries before Finance does
- Design budget alerts and hard guardrails that stop a runaway query before
  it becomes a five-figure incident

## Why This Exists

A query that returns in 400ms can still scan 2 TB to get there. On a
bytes-scanned engine like BigQuery, that query is "fast" by every
latency-based metric this handbook has taught so far, and simultaneously a
cost incident. Teams that only tune for `EXPLAIN`'s time estimate
routinely ship queries that pass every performance review and then post a
five-figure line item on next month's cloud bill. Cost is a correctness
dimension that query optimization, as traditionally taught, ignores.

## Business Motivation

The Fraud Review team ships a new "high-value flagged transactions this month" dashboard
query. It runs in 1.2 seconds — well within the team's 3-second SLA — so it
ships without further review. Nobody checks what it scans. At 200 dashboard
loads a day against an unpartitioned, unclustered 40 TB events table, that
single query alone can generate thousands of dollars a month in a
bytes-scanned billing model, entirely invisible to a team that only
instruments for latency. See **Real-World Incident** below for a
production-scale version of exactly this failure mode.

## The Cost Surface: What You're Actually Paying For

Cloud SQL engines bill on one or more of four surfaces. Knowing which
surface an engine bills on tells you which `EXPLAIN` metric to watch:

| Cost surface | What it measures | Representative engines |
|---|---|---|
| Bytes scanned | Data read off storage to answer the query, regardless of rows returned | BigQuery (on-demand), Snowflake (indirectly, via compute time), Redshift Spectrum, Athena |
| Compute-credits / warehouse-time | Wall-clock time a provisioned compute cluster runs, independent of bytes | Snowflake (virtual warehouses), Databricks SQL warehouses, Redshift (provisioned) |
| Provisioned IOPS / I/O requests | Disk read/write operations against a fixed or pay-per-request storage tier | RDS (io1/io2/gp3 provisioned IOPS), Aurora I/O-Optimized, on-prem SAN-backed OLTP |
| Storage | Data at rest, independent of query activity | All of the above, but usually the smallest line item next to a poorly tuned query workload |

A query can be innocent on one surface and expensive on another — a tiny
`SELECT COUNT(*)` on a clustered/partitioned BigQuery table costs almost
nothing in bytes scanned, while the same query against a long-running,
oversized Snowflake warehouse burns credits for however long the warehouse
stays "warm" waiting for the next query, regardless of what that query scans.

## Mapping EXPLAIN Output to Dollars

BigQuery reports total bytes processed and total bytes billed directly in the query execution log, which is the single most direct EXPLAIN-to-cost mapping of any major engine — a dry run gives you the exact bill before you pay it.

| Engine | Where the cost signal lives | How to read it |
|---|---|---|
| **BigQuery** | `EXPLAIN`/dry run → `totalBytesProcessed`; `INFORMATION_SCHEMA.JOBS.total_bytes_billed` after the fact | Bytes billed × current on-demand rate per TiB (check the current [BigQuery pricing page](https://cloud.google.com/bigquery/pricing) — this rate has changed over time and should never be hardcoded into a query review checklist) |
| **Snowflake** | Query Profile → "Bytes scanned" and "Partitions scanned / total" panels; `WAREHOUSE_METERING_HISTORY` for actual credit burn | Credits consumed ≈ warehouse size × execution seconds; a query with poor partition pruning (scanned ≫ total available) runs longer and burns more credits at the same warehouse size |
| **Redshift** | `EXPLAIN` cost estimate + `SVL_QUERY_METRICS` / `STL_QUERY` for actual scan bytes and slices touched | Provisioned clusters bill by node-hours regardless of query efficiency, but an inefficient query still steals capacity from every other tenant workload on the same cluster — the "cost" surfaces as contention, not a separate line item |
| **RDS / Aurora (Postgres, MySQL)** | `EXPLAIN (ANALYZE, BUFFERS)` → `shared hit` (cache, free) vs. `shared read` (disk I/O, billed on IOPS-provisioned storage) | Every `shared read` block is a billed I/O operation on `io1`/`io2`/provisioned-IOPS `gp3`; a query that relies on a cold-cache full scan pays per-block, every time, until the working set fits in `shared_buffers` |
| **Aurora I/O-Optimized** | Same `BUFFERS` output, but I/O cost is folded into a flat instance rate instead of billed per-request | Removes per-query I/O billing risk entirely — the tradeoff is a higher flat instance cost, which only pays off past a specific I/O-heavy workload threshold |

## Cost-Aware Indexing Strategy

Traditional indexing (Lesson 03) optimizes for *avoiding a scan
entirely*. Cost-aware indexing on cloud warehouses optimizes for
*minimizing what a scan touches* even when a scan is unavoidable:

- **Partitioning by the column most queries filter on** (typically a date)
  turns "scan the whole table" into "scan one partition" — the single
  highest-leverage cost lever on BigQuery, Redshift, and Snowflake alike.
- **Clustering** (BigQuery clustering, Snowflake micro-partitions, Redshift
  `SORTKEY`) sorts data physically so a filter on the clustered column can
  skip whole blocks without a traditional B-tree index, since these engines
  are columnar and don't support conventional row-store indexes the way
  this handbook's schema does.
- **On IOPS-billed row stores (RDS/Aurora)**, a genuinely covering index
  (Lesson 03) is *also* a cost optimization: every avoided disk
  read is a billed I/O operation avoided, not just milliseconds saved.
- **Over-clustering is a real cost, not a free upgrade**: re-clustering a
  large table on ingest has its own compute cost, exactly as over-indexing
  has a write-side cost in a row store (Lesson 03's tradeoff
  principle applies here at the storage-layout level instead of the index
  level).

## Budget Alerts and Guardrails

Detection after the fact is not a strategy — it's a post-mortem. Production
cost governance needs both:

- **Soft guardrails (alerts)**: BigQuery custom cost controls and budget
  alerts at the project/user level; Snowflake `RESOURCE_MONITOR` objects
  that notify at a percentage-of-credit-quota threshold; RDS/Aurora
  CloudWatch alarms on `ReadIOPS`/`WriteIOPS` sustained thresholds.
- **Hard guardrails (kill switches)**: BigQuery
  `maximum_bytes_billed` set per-query or per-project, which fails the query
  outright instead of billing it; Snowflake `STATEMENT_TIMEOUT_IN_SECONDS`
  and resource monitors with a `SUSPEND` action that stops the warehouse
  entirely at quota; RDS `statement_timeout` to cap a runaway query's
  execution window before it monopolizes provisioned IOPS.
- **The guardrail should sit as close to the query as possible.** A
  project-wide monthly budget alert catches a problem weeks after a bad
  query shipped. A per-query `maximum_bytes_billed` catches it on the first
  execution.

## Waste Detection Queries

Run these against each engine's own metadata periodically — cost audits are
a recurring job, not a one-time cleanup:

```sql
-- BigQuery: top 10 most expensive queries in the last 7 days
SELECT
    user_email,
    query,
    total_bytes_billed,
    ROUND(total_bytes_billed / POWER(1024, 4), 4) AS tib_billed
FROM `region-us`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    AND job_type = 'QUERY'
ORDER BY total_bytes_billed DESC
LIMIT 10;
```

```sql
-- Snowflake: warehouses burning the most credits in the last 7 days
SELECT
    warehouse_name,
    SUM(credits_used) AS total_credits,
    COUNT(*) AS query_count
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;
```

```sql
-- Postgres/RDS: tables/indexes with the highest disk-read ratio
-- (a low hit ratio here means most reads are billed IOPS, not free cache hits)
SELECT
    relname,
    heap_blks_read,
    heap_blks_hit,
    ROUND(
        100.0 * heap_blks_hit / NULLIF(heap_blks_hit + heap_blks_read, 0), 2
    ) AS cache_hit_pct
FROM pg_statio_user_tables
ORDER BY heap_blks_read DESC
LIMIT 10;
```

See the accompanying `.sql` lab for these queries running against a fully
seeded dataset, alongside a poor-vs-optimized cost comparison.

## Real-World Incident: Shopify's $1M-a-Month BigQuery Query

Shopify's data team discovered a single BigQuery query that scanned roughly 75 GB per execution while building a marketing-data pipeline; at their projected launch volume of 60 queries a minute, that scan rate would have cost approximately $950,000 USD per month under BigQuery's on-demand pricing. The fix was clustering the table on the columns used in the query's WHERE clause, which let BigQuery stop scanning once it found matching rows instead of reading the entire table — after clustering, the same query billed roughly 508 MB, about 150 times less data scanned, bringing the projected monthly cost down to roughly $1,370.

The engineering lesson generalizes past BigQuery: **the query was never
"slow."** It ran in seconds either way. The problem was invisible on every
latency dashboard and only visible in the bytes-scanned metric — exactly
the metric most performance reviews skip. (Source:
[Shopify Engineering — "Reducing BigQuery Costs: How We Fixed A $1 Million Query"](https://shopify.engineering/reducing-bigquery-costs))

## Engineering Notes

- Cost and latency optimization sometimes conflict: a broadcast join that's
  fastest in wall-clock time on a Spark/Databricks-style engine may consume
  far more compute-credits than a slower shuffle join, because credits bill
  on cluster-time × cluster-size, not query latency alone.
- A `LIMIT` clause does not reduce bytes-scanned cost on any engine in this
  lesson — the engine must still read the data needed to compute the result
  before truncating the output. Never treat `LIMIT` as a cost control.
- Query result caching (BigQuery's automatic cache, Snowflake's result
  cache) means the *first* run of a query pays full cost and every
  byte-identical repeat run is free — cache-busting via dynamic
  timestamps or comments in generated SQL silently defeats this and is a
  common, invisible source of repeated full cost.

## MySQL / PostgreSQL / SQL Server Notes

- **PostgreSQL (RDS/Aurora)**: `EXPLAIN (ANALYZE, BUFFERS)` is the
  cost-governance equivalent of a cloud warehouse's bytes-scanned metric —
  `shared read` blocks are the billed unit on IOPS-provisioned storage.
  `pg_stat_statements` aggregated by `shared_blks_read` surfaces the same
  "top offenders" view as the BigQuery/Snowflake waste-detection queries
  above.
- **MySQL (RDS/Aurora)**: the Performance Schema's
  `sys.statements_with_runtimes_in_95th_percentile` view combined with
  `Innodb_data_reads` server status gives an equivalent I/O-cost signal;
  Aurora MySQL additionally exposes `AuroraVolumeBytesRead` as a direct
  CloudWatch billing-adjacent metric.
- **SQL Server (Azure SQL / Managed Instance)**: `SET STATISTICS IO ON`
  reports logical/physical reads per query — physical reads are the
  cost-relevant number on storage tiers with IOPS-based pricing; Azure SQL's
  DTU/vCore-based compute billing means query *duration*, not just I/O,
  also directly maps to cost, similar to Snowflake's credit model.

## Common Mistakes

- Reviewing a query's `EXPLAIN` time estimate and stopping there, without
  checking the bytes-scanned or I/O-cost equivalent on a cloud-billed engine
- Assuming a fast query is a cheap query — the two are correlated, not
  identical, on any consumption-billed engine
- Leaving a Snowflake virtual warehouse's auto-suspend timeout too high,
  burning credits during idle time between queries
- Treating a one-time cost audit as sufficient instead of scheduling the
  waste-detection queries above as a recurring job

## Anti-patterns

- `SELECT *` on a wide, columnar-stored table (BigQuery, Redshift,
  Snowflake) — every unnecessary column is billed bytes on a columnar
  engine in a way it isn't on the row-store engines the rest of this
  handbook centers on, because columnar storage means unselected columns
  are never even touched by a well-formed query, but a `SELECT *` forces
  every column to be read
- Querying an unpartitioned, unclustered fact table with a date filter that
  the engine can't use to prune, because the date column is stored as a
  string requiring a cast (a cost-domain SARGability failure — Lesson 03's rule applies to partition pruning exactly as it applies to
  index usage)
- Oversized, always-on provisioned compute (a Snowflake `X-LARGE` warehouse
  running queries that would complete acceptably on a `SMALL`) — bigger
  compute doesn't make an inefficient query cheap, it makes it expensive
  faster

## Edge Cases

- **Cached vs. uncached cost**: a query that appears free on a second run
  because of result caching can mislead a benchmark into believing a fix
  worked when the query was never re-executed against fresh data at all —
  always test cost claims with cache explicitly disabled or a
  cache-defeating change.
- **Provisioned vs. on-demand billing crossover**: a workload with
  consistently high query volume is often cheaper on provisioned/reserved
  capacity (BigQuery flat-rate slots, Snowflake's per-second billing with a
  sustained-use discount) than on-demand — cost optimization at scale
  eventually becomes a capacity-planning question, not just a query-tuning
  one.

## Troubleshooting Guidance

- Monthly cloud bill spikes with no corresponding user-growth or feature
  launch → run the waste-detection queries above first; a single new report
  or dashboard query is the most common root cause.
- A query looks cheap in local/dev testing but expensive in production →
  check whether dev is querying a small sample table while production
  queries the full, unpartitioned dataset; cost problems are almost always
  invisible below production data volume, identically to the performance
  anti-patterns in Lesson 06.

## Scalability Considerations

Cost problems are non-linear in the same way the anti-patterns in Lesson 06
are: a full scan against a 10 GB table is invisible in cost, and the exact
same query against the 40 TB the table grows into over two years is a
five-figure annual line item — with no code change in between. Budget for
cost review as a recurring practice tied to data growth, not a one-time
audit performed at launch.

## Additional Dialect Notes (Oracle, SQLite, DuckDB)

- **Oracle (OCI Autonomous Database)**: bills primarily on provisioned
  OCPU/ECPU compute and storage rather than per-query bytes scanned;
  `V$SQL` and Automatic Workload Repository (AWR) reports are the
  cost-governance equivalent of the waste-detection queries above.
- **SQLite**: has no cloud billing model — it's an embedded, file-based
  engine with no metered compute or storage. The concepts in this lesson
  don't apply; SQLite workloads are cost-relevant only through the compute
  resources of whatever process embeds them.
- **DuckDB**: similarly has no native billing model as an in-process
  analytical engine, but DuckDB workloads run on cloud compute (a
  serverless function, a container) frequently enough that the underlying
  compute-time cost of a DuckDB query is a real, if indirect, cost signal —
  measure wall-clock time as a proxy in the absence of a query-level cost
  metric.

## Interview Questions

- "A query is fast but the cloud bill went up. Walk me through how you'd
  investigate."
- "What's the difference between a bytes-scanned billing model and a
  compute-credit billing model, and how does that change what you optimize
  for?"
- "Why doesn't `LIMIT` reduce cost on a bytes-scanned engine like BigQuery?"

## Summary

On a cloud-billed engine, `EXPLAIN` isn't just a performance tool — it's a
pricing calculator, if you know which number to read. Bytes scanned,
compute-credits, and provisioned IOPS are three different cost surfaces
mapping to three different `EXPLAIN`/metadata signals, and a query can be
fast on the latency axis while being expensive on any of them. Treat cost
review as a standing discipline with the same rigor as `EXPLAIN ANALYZE`
review, not a one-time cleanup after a surprising invoice.

## Practice Challenges

1. Given a BigQuery table with no partitioning or clustering, write the
   `INFORMATION_SCHEMA.JOBS` query that would have caught the Shopify
   incident before it shipped to general availability.
2. Explain why a query with a 1.2-second latency SLA can still fail a cost
   review, using the concepts in "The Cost Surface" section above.

## Further Reading

- Google Cloud — "BigQuery: Optimize query computation" and "Clustered
  tables" documentation
- Snowflake Documentation — "Resource Monitors" and "Understanding Compute
  Cost"
- AWS Documentation — "Amazon Aurora I/O-Optimized" and "Monitoring Amazon
  RDS metrics with Amazon CloudWatch"
- Shopify Engineering — "Reducing BigQuery Costs: How We Fixed A $1 Million
  Query"
