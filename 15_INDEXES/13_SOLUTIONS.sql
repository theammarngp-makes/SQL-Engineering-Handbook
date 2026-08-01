-- ============================================================
-- Module 15, File 13 — Solutions to 12_PRACTICE_PROBLEMS.md
-- Engine: MySQL 8.0+
-- Each section header matches the corresponding section in File 12.
-- Conceptual problems include a written answer as a SQL comment;
-- hands-on problems include runnable SQL.
--
-- RUN CONTEXT: this file is a standalone reference, not a
-- continuation of Files 01-10 in one unbroken session — several
-- solutions intentionally recreate index names already used
-- earlier in the module (e.g., idx_orders_customer_id) to keep
-- each solution self-contained and readable on its own. Run this
-- file against a fresh copy of the 00_SETUP.sql schema, or drop
-- the relevant earlier-file indexes first, to avoid a
-- duplicate-key-name error.
-- ============================================================

-- ============================================================
-- BEGINNER (File 01 — Fundamentals)
-- ============================================================

-- Problem 1
EXPLAIN SELECT * FROM orders WHERE customer_id = 5;
-- Expect type=ALL before any index exists.
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
EXPLAIN SELECT * FROM orders WHERE customer_id = 5;
-- Expect type=ref after the index is created.

-- Problem 2
-- A 100-row table's full scan is already trivially cheap; the
-- optimizer's cost model will estimate a full scan as equal to or
-- cheaper than an index seek at this scale, so EXPLAIN's chosen
-- access type is unlikely to change regardless of indexing.

-- Problem 3
-- Full scan cost ≈ O(n) = ~40,000,000 row reads.
-- Index seek cost ≈ O(log n) + 5 matches ≈ a few dozen page reads.
-- This estimate only holds if the filtered column is HIGH
-- selectivity — i.e., the 5 matching rows are genuinely rare
-- relative to the table, not the common case.

-- Problem 4
EXPLAIN SELECT * FROM orders WHERE customer_id = 5;
-- Confirm the `key` column names the expected index and `type`
-- is better than ALL (e.g., ref, range, eq_ref, const).


-- ============================================================
-- INTERMEDIATE (Files 02-04)
-- ============================================================

-- Problem 1
-- A B+Tree's leaf nodes are linked in sorted order, so once the
-- starting point for ORDER BY is located, results stream out in
-- order directly from the leaf chain — no separate sort step
-- (filesort) is required. A plain B-Tree has no such leaf linkage.

-- Problem 2
-- Random UUID values insert in random key order, so each insert
-- is likely to land on a different, possibly already-full leaf
-- page, triggering frequent page splits and scattered disk writes.
-- An auto-increment key always inserts at the rightmost leaf,
-- which is cheap to append to and rarely triggers a split.

-- Problem 3
CREATE INDEX idx_orders_order_date ON orders (order_date);
-- Yes — a single B-Tree index on order_date serves both an
-- equality lookup and a range scan, since both access patterns
-- start from the same sorted structure.

-- Problem 4
-- INDEX(tenant_id, created_at)
-- (a) WHERE tenant_id = 1                          -> uses col 1 only
-- (b) WHERE created_at > '2026-01-01'               -> CANNOT use index
--     (skips leftmost column)
-- (c) WHERE tenant_id = 1 AND created_at > '...'    -> uses both columns

-- Problem 5
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date);
-- Reordered to (customer_id, order_date): customer_id is the
-- equality filter and belongs first; order_date is the range
-- filter and belongs second, per the equality-before-range rule.

-- Problem 6
-- Uses all three columns:
--   SELECT * FROM t WHERE a = 1 AND b = 2 AND c = 3;
-- Uses none of the index despite referencing b and c:
--   SELECT * FROM t WHERE b = 2 AND c = 3;   -- skips leftmost column a

-- Problem 7
-- Once a range predicate is applied, the index can no longer use
-- any column after it to further narrow the seek — everything
-- after a range column in the index degrades to a post-filter.
-- Placing the range column early forfeits any narrowing benefit
-- from equality columns that follow it.

-- Problem 8
-- Both PRIMARY KEY and a separate UNIQUE column use B+Tree index
-- structures in InnoDB. The difference: PRIMARY KEY is the
-- CLUSTERED index (leaf nodes store the full row); a UNIQUE
-- column is a SECONDARY index (leaf nodes store the primary key
-- value, requiring a second lookup to fetch the full row).

-- Problem 9 (PostgreSQL)
-- DELETE FROM customers WHERE id = 1;
-- Without an index on orders.customer_id, PostgreSQL must
-- sequentially scan the entire orders table on every DELETE from
-- customers to verify no orphaned rows would remain — because
-- MySQL InnoDB auto-creates this index but PostgreSQL does not.


-- ============================================================
-- ADVANCED (Files 05-07)
-- ============================================================

-- Problem 1
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);
EXPLAIN
SELECT order_id, status FROM orders WHERE customer_id = 88291;
-- order_id is covered "for free" because InnoDB secondary index
-- leaf entries always store the primary key value alongside the
-- indexed columns, regardless of whether it's declared explicitly.

-- Problem 2
-- Changing `SELECT order_id, status` to `SELECT *` breaks the
-- index-only scan, since total_amount/order_date/etc. aren't
-- present in the covering index and must be fetched from the
-- table.

-- Problem 3
-- sessions (OLTP, high write): minimal indexing — likely just a
-- primary key and one purpose-built index (e.g., user_id) backing
-- an actual, frequent query.
-- dim_product (OLAP dimension, low write): broader indexing is
-- acceptable — index the surrogate key, natural key, and any
-- commonly filtered attribute columns, since batch writes
-- tolerate the added maintenance cost.

-- Problem 4
-- MySQL: performance_schema.table_io_waits_summary_by_index_usage
--   (count_star = 0 indicates no observed usage)
-- PostgreSQL: pg_stat_user_indexes (idx_scan = 0)
-- (SQL Server: sys.dm_db_index_usage_stats; Oracle: v$object_usage)

-- Problem 5
-- Option A: run the reporting query against a read replica instead
-- of the primary OLTP table.
-- Option B: batch-copy the relevant data into a separate
-- OLAP/warehouse table on a schedule, and index that copy freely.

-- Problem 6
-- selectivity = distinct_values / total_rows = 4 / 20,000,000
--             = 0.0000002  (extremely low)
-- Not a good indexing candidate in isolation — a matching value
-- still returns roughly 5,000,000 rows, which a full scan will
-- generally outperform. Consider it only as a leading/trailing
-- column within a composite index alongside a more selective
-- column.

-- Problem 7
ANALYZE TABLE orders;
-- Stale statistics after a large batch load are the most common
-- cause of a sudden, code-free plan regression — refreshing
-- statistics is the first diagnostic (and often the fix).

-- Problem 8
-- A column like `country` might be low-selectivity overall (a
-- few countries dominate), but a rare value (a country with only
-- 12 rows) is highly selective for that specific query. A
-- HISTOGRAM captures this per-value distribution, letting the
-- optimizer choose the index for rare values even while
-- correctly avoiding it for common ones.
ANALYZE TABLE orders UPDATE HISTOGRAM ON status WITH 8 BUCKETS;


-- ============================================================
-- CASE STUDIES (File 09)
-- ============================================================

-- Problem 1
CREATE UNIQUE INDEX uq_patients_mrn ON patients (mrn);
CREATE INDEX idx_patients_lastname_dob ON patients (last_name, date_of_birth);
-- mrn is globally unique per patient -> UNIQUE index.
-- (last_name, date_of_birth) is a composite lookup key since
-- neither column alone is selective enough on its own.

-- Problem 2
-- A composite B-Tree on (latitude, longitude) can only narrow
-- efficiently on the leftmost column (latitude) as a range, then
-- must post-filter longitude — it cannot express true 2D
-- proximity ("within N km") as a single sorted-order seek. A
-- SPATIAL INDEX (R-Tree/GiST family) is designed specifically for
-- multi-dimensional proximity queries.

-- Problem 3
CREATE INDEX idx_products_category_price ON products (category_id, price);
-- category_id (equality) and price (range) are fully satisfied by
-- this composite index seek. popularity_score sorting is NOT
-- satisfiable by this same index seek (it isn't part of the
-- leftmost-prefix path used) and requires a separate sort step,
-- or a dedicated covering index if this exact query dominates
-- traffic.


-- ============================================================
-- PRODUCTION DEBUGGING (File 08)
-- ============================================================

-- Problem 1
-- Possible causes for type=ALL despite an index existing:
--   1) The predicate doesn't match the index's leftmost column
--      (leftmost prefix rule violated).
--   2) The column is low-selectivity and the optimizer correctly
--      prefers a full scan.
--   3) Statistics are stale, causing a misestimate either way.

-- Problem 2
ANALYZE TABLE orders;
-- Immediate next action: refresh statistics and re-run
-- EXPLAIN ANALYZE — a large estimate/actual gap is the strongest
-- signal of a statistics problem, not necessarily an indexing one.

-- Problem 3
-- "Using temporary": the engine needed an in-memory/on-disk temp
-- table, often from GROUP BY/DISTINCT on unindexed columns —
-- consider indexing the grouped/distinct columns.
-- "Using filesort": an extra sort step was required because index
-- order didn't satisfy ORDER BY — consider a composite index whose
-- trailing columns match the ORDER BY clause.

-- Problem 4
-- A nested loop join re-executes its inner side once per outer
-- row. If the outer side unexpectedly returns millions of rows,
-- the inner lookup — even if individually cheap — is now
-- multiplied millions of times over. A hash join instead builds
-- one hash table up front, so a larger-than-expected input grows
-- the build/probe cost roughly linearly rather than multiplying a
-- per-row cost by an inflated loop count.


-- ============================================================
-- OPTIMIZATION
-- ============================================================

-- Problem 1
-- Decision process: measure current selectivity for each
-- candidate column via SHOW INDEX / cardinality estimates, check
-- actual query frequency/cost via EXPLAIN ANALYZE, and pick the
-- column whose index yields the largest reduction in estimated
-- rows examined for the highest-frequency query — not just the
-- column that "feels" most relevant.

-- Problem 2
-- 1) Confirm zero usage over a full representative traffic cycle
--    (not just a quiet period) using
--    performance_schema.table_io_waits_summary_by_index_usage.
-- 2) Disable (don't drop) the index first if the engine supports
--    invisible indexes (MySQL 8.0+: ALTER TABLE t ALTER INDEX
--    idx_name INVISIBLE) and monitor for regressions.
-- 3) Only DROP the index after a full monitoring cycle confirms
--    no regression.
-- ALTER TABLE orders ALTER INDEX idx_orders_status INVISIBLE;
-- -- monitor, then:
-- DROP INDEX idx_orders_status ON orders;


-- ============================================================
-- MAINTENANCE & MYTHS (File 10)
-- ============================================================

-- Problem 1
-- data_free at 35% of data_length indicates significant
-- fragmentation/reclaimable space (InnoDB deleted-row/page
-- overhead accumulated from UPDATE/DELETE churn). Fix:
OPTIMIZE TABLE transactions;

-- Problem 2
-- INDEX(a, b) IS redundant if INDEX(a, b, c) exists — any query
-- servable by the (a, b) prefix is equally servable by the first
-- two columns of (a, b, c).
-- INDEX(b, c) is NOT redundant — it doesn't share a leftmost
-- prefix with (a, b, c) at all (b is not the leftmost column of
-- the existing index), so a query filtering on b first cannot
-- use (a, b, c) to seek on b.

-- Problem 3
-- "Using an index" only confirms the WHERE clause had a usable
-- access path — it says nothing about whether that path was
-- actually selective, whether statistics were current, or
-- whether a downstream step (filesort, temporary table, a huge
-- loop count in a join) dominates total cost. Concrete scenario:
-- a query on a low-selectivity column can show `key` populated in
-- EXPLAIN while still examining a third of the table (File 07's
-- selectivity example) — "used" and "fast" are different claims.

-- Problem 4
-- PostgreSQL's MVCC model means every UPDATE/DELETE writes a new
-- row version and marks the old one dead, rather than modifying
-- in place — VACUUM is the only mechanism that reclaims that dead
-- space and prevents transaction ID wraparound. SQL Server's
-- rebuild/reorganize model updates pages more directly and
-- doesn't carry the same structural MVCC cleanup requirement, so
-- its maintenance is more purely about fragmentation, not also
-- about storage-model correctness.

-- Problem 5
-- promotions (small, rarely updated): keep fillfactor near 100%
-- (default) — little future in-page modification to reserve space
-- for, and rebuilds are cheap enough to run infrequently/reactively.
-- audit_log (large, insert-heavy, append-mostly): fillfactor is
-- less relevant than for update-heavy tables since it's insert-
-- dominated, not update-dominated, but the RETENTION constraint
-- means bloat management must be scheduled proactively (regular
-- monitored VACUUM/OPTIMIZE on a fixed cadence), since the table
-- can never be pruned down to shrink the problem the way a
-- sessions-style table could be.
