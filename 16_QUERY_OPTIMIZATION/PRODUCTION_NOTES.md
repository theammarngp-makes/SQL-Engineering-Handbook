# Production Notes — Query Optimization

Operational guidance for running query optimization in production environments. Complements the tuning workflow in [Lesson 07](./07_QUERY_TUNING_WORKFLOW.md).

---

## Pre-Production Checklist

Before deploying any query optimization change:

- [ ] Change tested on production-representative data volume
- [ ] EXPLAIN ANALYZE before and after documented
- [ ] Correctness verified (row counts and sample results match)
- [ ] Write impact assessed for new indexes
- [ ] Rollback plan documented
- [ ] Change applied during low-traffic window (for indexes)
- [ ] Team notified of deployment

---

## Index Deployment in Production

### PostgreSQL
```sql
-- Prefer CONCURRENTLY on production tables to avoid a blocking ACCESS EXCLUSIVE lock.
-- Tradeoffs: cannot run inside a transaction block, takes longer, and can leave an
-- INVALID index behind on failure (drop and retry in that case).
CREATE INDEX CONCURRENTLY idx_name ON table_name (column);

-- Monitor progress
SELECT * FROM pg_stat_progress_create_index;

-- Drop unused index safely
DROP INDEX CONCURRENTLY idx_name;
```

### MySQL
```sql
-- Online DDL (InnoDB)
ALTER TABLE table_name ADD INDEX idx_name (column), ALGORITHM=INPLACE, LOCK=NONE;
```

### SQL Server
```sql
CREATE INDEX idx_name ON table_name (column) WITH (ONLINE = ON);
```

---

## Statistics Maintenance Schedule

| Event | Action | Priority |
|---|---|---|
| After bulk load (> 10% table growth) | `ANALYZE` immediately | Critical |
| After major DELETE | `ANALYZE` within 1 hour | High |
| After schema change (new column/index) | `ANALYZE` before traffic | High |
| Weekly (high-churn tables) | Scheduled `ANALYZE` | Medium |
| Monthly (stable tables) | Review auto-analyze settings | Low |

---

## Slow Query Monitoring Setup

### PostgreSQL
```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Log queries > 1 second
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();

-- Top 10 by total time
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 10;
```

### MySQL
```sql
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 1;
SET GLOBAL log_queries_not_using_indexes = ON;
```

---

## Incident Response for Query Performance

| Severity | Response Time | Actions |
|---|---|---|
| SEV-1 (outage) | Immediate | Kill long-running queries, check locks, failover to replica |
| SEV-2 (degraded) | 15 minutes | EXPLAIN ANALYZE, identify bottleneck, apply targeted fix |
| SEV-3 (slow trend) | Next business day | Review pg_stat_statements, plan regression check |

---

## Connection Pool Sizing

Query optimization reduces per-query time, but connection pool exhaustion looks identical to slow queries:

- Monitor active connections vs. pool max
- Set `statement_timeout` to prevent runaway queries from holding connections
- Use connection pooler (PgBouncer) for high-concurrency workloads

---

## Related Documents

- [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md)
- [PRODUCTION_INCIDENTS.md](./PRODUCTION_INCIDENTS.md)
- [PERFORMANCE_CHECKLIST.md](./PERFORMANCE_CHECKLIST.md)
