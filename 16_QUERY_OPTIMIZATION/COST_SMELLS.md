# Cost Smells Catalog

A companion to `PERFORMANCE_SMELLS.md`, scoped to patterns that
are cheap in latency and expensive in bytes-scanned, compute-credits, or
provisioned IOPS. A query can fail zero entries in the latency catalog and
still fail every entry here.

| # | Smell | Symptom | Fix | Cross-reference |
|---|---|---|---|---|
| C1 | `SELECT *` on a wide columnar table | Fast, small result set; large billed bytes on BigQuery/Snowflake/Redshift | Explicit column projection | Lesson 06 |
| C2 | Non-SARGable filter on a partition column | Fast on a small table; scans every partition at production scale | Rewrite to a direct range comparison (this lesson's SQL lab, Case 1) | Lesson 03 |
| C3 | Oversized always-on compute | Individually fast queries; high idle-time credit burn | Right-size warehouse; enable/lower auto-suspend | This lesson, "Budget Alerts and Guardrails" |
| C4 | Cache-busting via dynamic literals (timestamps, comments) in generated SQL | Every run pays full cost; looks identical to a cache hit in application logs | Strip non-semantic dynamic content before execution; use parameterized queries | This lesson, "Engineering Notes" |
| C5 | Cross-join or unfiltered join fan-out before aggregation | Correct result, low latency on small data; scans/joins far more rows than the final answer needs at production scale | Filter and pre-aggregate before joining | Lesson 04 |
| C6 | No cost-side alert on a query that only regressed on data volume, not query shape | Silent monthly bill growth with no corresponding code change | Recurring waste-detection query (this lesson, "Waste Detection Queries") + budget alerts tied to volume-relative baselines, not fixed thresholds | This lesson, "Budget Alerts and Guardrails" |
| C7 | Row-store index treated as "free" cost insurance | Every additional index adds write-side I/O cost on every insert/update, exactly as it adds write latency | Index only for queries that actually run in production, matching this handbook's covering-index tradeoff principle | Lesson 03 |
