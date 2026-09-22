# Cross-Database Query Optimization Engineering

Comparative reference for query optimizers, execution plans, statistics, indexes, and performance features across eight engines. Use when porting queries, designing multi-engine architectures, or preparing for interviews.

---

## Engine Comparison Matrix

| Feature | PostgreSQL | MySQL (InnoDB) | SQL Server | Oracle | SQLite | DuckDB | Snowflake | BigQuery |
|---|---|---|---|---|---|---|---|---|
| Optimizer type | Cost-based | Cost-based (8.0+) | Cost-based | Cost-based | Rule + cost | Cost-based | Cost-based | Cost-based (Dremel) |
| EXPLAIN syntax | `EXPLAIN (ANALYZE, BUFFERS)` | `EXPLAIN ANALYZE` (8.0.18+) | Graph/text plan + `SET STATISTICS IO, TIME ON` | `EXPLAIN PLAN` + `DBMS_XPLAN` | `EXPLAIN QUERY PLAN` | `EXPLAIN ANALYZE` | `EXPLAIN` (limited) | Execution details in job history |
| Hash join | Yes | Yes (8.0.18+) | Yes | Yes | No | Yes | Yes | Yes (automatic) |
| Merge join | Yes | Limited | Yes | Yes | No | Yes | Yes | N/A |
| Nested loop | Yes | Yes (default historically) | Yes | Yes | Only join type | Yes | Yes | N/A |
| CTE inlining | Default (12+) | Yes (8.0+) | Yes | Yes | Yes | Yes (aggressive) | Yes | Yes |
| Partial indexes | Yes | No (functional only) | Filtered indexes | Function-based | Yes (3.8.0+) | No | N/A | Clustering |
| Index-only scan | Yes | Yes (covering) | Yes | Yes | Yes | Zone maps | Micro-partitions | Column pruning |
| Parallel query | Yes (9.6+) | Yes (8.0, limited) | Yes | Yes | No | Yes (default) | Always | Always |
| Partition pruning | Yes | Yes (5.7+) | Yes | Yes | No | No | Automatic | Automatic |
| Materialized views | Yes | No | Indexed views | Materialized views | No | No | Materialized views | Materialized views |
| Optimizer hints | Limited (`pg_hint_plan`) | `USE INDEX`, `FORCE INDEX` | Query hints | Extensive hints | None | None | None | None |
| Statistics refresh | `ANALYZE` | `ANALYZE TABLE` | `UPDATE STATISTICS` | `DBMS_STATS.GATHER_TABLE_STATS` | `ANALYZE` | Automatic | Automatic | Automatic |
| Plan cache | Per-connection + shared | Per-connection | Plan cache + Query Store | Library cache | None | Per-query | Result cache | Query cache |

---

## Optimizer Behavior

### PostgreSQL
- **Strengths**: Transparent EXPLAIN output, rich index types (GIN, GiST, BRIN), partial indexes, expression indexes
- **Watch out for**: CTE materialization changed in PG 12 (was always materialized before); `work_mem` spills visible as `Batches > 1`
- **Key settings**: `work_mem`, `random_page_cost`, `effective_cache_size`, `join_collapse_limit`

### MySQL (InnoDB)
- **Strengths**: Covering index optimization, index condition pushdown (ICP), hash joins (8.0.18+)
- **Watch out for**: Historically nested-loop-only before 8.0.18; `EXPLAIN ANALYZE` requires 8.0.18+
- **Key settings**: `optimizer_switch`, `join_buffer_size`, `sort_buffer_size`

### SQL Server
- **Strengths**: Query Store for plan regression detection, extensive hint system, columnstore indexes
- **Watch out for**: Parameter sniffing is common; plan cache can lock in suboptimal plans
- **Key settings**: `MAXDOP`, Query Store capture mode, `OPTIMIZE FOR UNKNOWN`

### Oracle
- **Strengths**: Mature cost model, adaptive plans, extensive hint vocabulary, SQL Plan Baselines
- **Watch out for**: Hint abuse can mask underlying issues; licensing complexity for diagnostic packs
- **Key settings**: `OPTIMIZER_MODE`, `CURSOR_SHARING`, adaptive cursor sharing

### SQLite
- **Strengths**: Zero-config, embedded, predictable for small datasets
- **Watch out for**: Nested loop only — no hash or merge join; simple planner; no persistent plan cache
- **Key settings**: `PRAGMA optimize`, `PRAGMA cache_size`

### DuckDB
- **Strengths**: Vectorized execution, automatic parallelization, excellent for analytical workloads
- **Watch out for**: Different cost model than row-store engines; zone maps instead of B-tree indexes
- **Key settings**: `threads`, `memory_limit`

### Snowflake
- **Strengths**: Automatic clustering, micro-partition pruning, result cache, always-parallel
- **Watch out for**: No traditional indexes — clustering keys and search optimization service instead; credit cost for large scans
- **Key settings**: Warehouse size, clustering keys, search optimization

### BigQuery
- **Strengths**: Serverless, automatic column pruning, partition/cluster pruning, slot-based scaling
- **Watch out for**: Full table scan cost if partitions/clusters not used; no indexes; query cost proportional to bytes scanned
- **Key settings**: Partitioning, clustering, maximum bytes billed

---

## Execution Plan Reading by Engine

| Concept | PostgreSQL | MySQL | SQL Server | Oracle |
|---|---|---|---|---|
| Full table scan | `Seq Scan` | `ALL` (type) | Table Scan | `TABLE ACCESS FULL` |
| Index lookup | `Index Scan` | `ref`, `range` | Index Seek | `INDEX RANGE SCAN` |
| Index-only | `Index Only Scan` | `Using index` | Index Seek (covering) | `INDEX FAST FULL SCAN` |
| Hash join | `Hash Join` | `Hash join` | Hash Match | `HASH JOIN` |
| Nested loop | `Nested Loop` | `Nested loop` | Nested Loops | `NESTED LOOPS` |
| Sort | `Sort` | `Using filesort` | Sort | `SORT ORDER BY` |
| Actual time | `EXPLAIN ANALYZE` | `EXPLAIN ANALYZE` | Actual Execution Plan | `DBMS_XPLAN.DISPLAY_CURSOR` |

---

## Statistics Management

| Engine | Command | Auto-refresh | Key catalog |
|---|---|---|---|
| PostgreSQL | `ANALYZE table_name;` | autovacuum autoanalyze | `pg_stats` |
| MySQL | `ANALYZE TABLE table_name;` | InnoDB auto-recalc | `mysql.innodb_index_stats` |
| SQL Server | `UPDATE STATISTICS table_name;` | Auto-update (with thresholds) | `sys.dm_db_stats_properties` |
| Oracle | `EXEC DBMS_STATS.GATHER_TABLE_STATS(...)` | Automatic (with preferences) | `USER_TAB_STATISTICS` |
| Snowflake | Automatic | Always automatic | `INFORMATION_SCHEMA` |
| BigQuery | Automatic | Always automatic | Query job statistics |

**Universal rule**: After any bulk load, schema change, or major DELETE, manually refresh statistics before trusting execution plans.

---

## Index Strategies by Engine

| Strategy | PostgreSQL | MySQL | SQL Server | Oracle |
|---|---|---|---|---|
| B-tree (default) | Yes | Yes | Yes | Yes |
| Partial/filtered | `CREATE INDEX ... WHERE` | No | `CREATE INDEX ... WHERE` | Function-based |
| Expression/functional | `CREATE INDEX ON t (expr(col))` | Functional (8.0.13+) | Computed column index | Function-based index |
| Covering/include | `INCLUDE (col)` | Include in index def | `INCLUDE (col)` | Index-only with all cols |
| Full-text | GIN/GiST + tsvector | FULLTEXT index | Full-text index | Oracle Text |
| Columnstore | cstore_fdw extension | No | Columnstore index | In-memory column store |

---

## Locking & Concurrency Impact on Performance

| Engine | Default isolation | Index creation lock | Read impact during DDL |
|---|---|---|---|
| PostgreSQL | Read Committed | `CREATE INDEX CONCURRENTLY` (no lock) | Minimal with CONCURRENTLY |
| MySQL | Repeatable Read | Online DDL (InnoDB) | Minimal with ALGORITHM=INPLACE |
| SQL Server | Read Committed | `WITH (ONLINE = ON)` | Minimal with ONLINE |
| Oracle | Read Committed | Online index rebuild | Minimal |

---

## When to Choose Which Engine

| Workload | Recommended | Why |
|---|---|---|
| OLTP, complex joins | PostgreSQL, SQL Server, Oracle | Mature optimizers, rich index types |
| High-write OLTP | PostgreSQL, MySQL | Tunable, proven at scale |
| Embedded / mobile | SQLite | Zero-config, single-file |
| Local analytics / ETL | DuckDB | Vectorized, parallel, columnar |
| Cloud data warehouse | Snowflake, BigQuery | Serverless scaling, auto-optimization |
| Mixed OLTP + analytics | PostgreSQL + DuckDB/Snowflake | Right tool per workload |

---

## Related Documents

- [ENGINEERING_GLOSSARY.md](./ENGINEERING_GLOSSARY.md) — term definitions
- [BENCHMARK_GUIDE.md](./BENCHMARK_GUIDE.md) — cross-engine benchmarking methodology
- Individual lesson dialect notes in each `.md` file
