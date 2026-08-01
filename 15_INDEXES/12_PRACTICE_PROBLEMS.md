# 12 — Practice Problems

## Introduction

Hands-on exercises corresponding to Files 01-09. Attempt each problem
against a local MySQL 8.0+ instance before checking
[13_SOLUTIONS.sql](13_SOLUTIONS.sql). Problems escalate from single-index
fundamentals to full production debugging scenarios.

## Beginner (File 01 — Fundamentals)

**Problem 1.** Given `orders(order_id PK, customer_id, order_date,
status, total_amount)` with no secondary indexes, predict the `EXPLAIN`
`type` for `WHERE customer_id = 5`. Then create the appropriate index
and predict how the `type` changes.

**Problem 2.** Explain, without running anything, why indexing a
`boolean is_deleted` column on a 100-row table is unlikely to change its
`EXPLAIN` plan at all.

**Problem 3.** A table has 40 million rows. Estimate, conceptually, the
relative cost difference between a full scan and an index seek matching
5 rows. What property of the filtered column determines whether that
estimate holds?

**Problem 4.** What SQL command would you run immediately after
creating an index to confirm it's actually usable for a specific query?

## Intermediate (Files 02–04 — Structure, Composite, Constraints)

**Problem 1.** Explain why a B+Tree, not a plain B-Tree, is the correct
structure to reach for when a query needs `ORDER BY` on the indexed
column.

**Problem 2.** You're inserting rows with a randomly generated UUID
primary key at high volume into an InnoDB table. Explain the mechanism
by which this hurts write throughput compared to an auto-increment
integer key.

**Problem 3.** Design a B-Tree index to support both
`WHERE order_date = ?` and `WHERE order_date BETWEEN ? AND ?` on the
same table. Does one index serve both?

**Problem 4.** Given `INDEX(tenant_id, created_at)`, which of these
queries can use it, and how much of it: (a) `WHERE tenant_id = 1`, (b)
`WHERE created_at > '2026-01-01'`, (c) `WHERE tenant_id = 1 AND
created_at > '2026-01-01'`?

**Problem 5.** Redesign the column order of
`INDEX(order_date, customer_id)` to better support
`WHERE customer_id = ? AND order_date > ?`. Justify the new order.

**Problem 6.** A composite index `(a, b, c)` exists. Write a query that
uses all three columns of the index, and one that uses none of it despite
referencing `b` and `c`.

**Problem 7.** Explain why placing a range-filtered column before an
equality-filtered column in a composite index is usually a mistake.

**Problem 8.** A `PRIMARY KEY` column and a separately declared `UNIQUE`
column both exist on a table. Are they stored using the same kind of
index structure in InnoDB? What differs?

**Problem 9.** You add a foreign key on PostgreSQL from `orders.
customer_id` to `customers.id` without creating any additional index.
What specific operation becomes expensive as a result, and why?

## Advanced (Files 05–07 — Covering, Strategy, Optimization)

**Problem 1.** Design a covering index for:
`SELECT order_id, status FROM orders WHERE customer_id = ?`. Verify
your design covers `order_id` even though it isn't explicitly listed as
an index column, and explain why.

**Problem 2.** Given a covering index that works correctly, what single
change to the query (not the index) would break the index-only scan?

**Problem 3.** You're indexing a high-write `sessions` table (thousands
of inserts/second) and a low-write `dim_product` warehouse dimension
table. Propose different indexing budgets for each and justify the
difference.

**Problem 4.** List two DMV/system-view mechanisms (from any two
engines covered in this module) for detecting unused indexes in
production.

**Problem 5.** A reporting query is degrading a high-write OLTP table's
insert throughput because of a new index. Propose two alternatives to
adding that index directly to the OLTP table.

**Problem 6.** Compute the approximate selectivity of a `status` column
with 4 distinct values on a 20-million-row table. Would you index it in
isolation? Why or why not?

**Problem 7.** After a large overnight batch load, a previously fast
query becomes slow with no code changes. What's your first diagnostic
command, and why?

**Problem 8.** Explain a scenario where a column has poor overall
selectivity but a specific query against one of its rare values would
still benefit significantly from an index — and what optimizer feature
makes the engine aware of that.

## Case Studies (File 09)

**Problem 1.** Design the index(es) for a healthcare `patients` table
supporting lookup by `mrn` and by `(last_name, date_of_birth)`. State
which is unique and which is composite, and why.

**Problem 2.** A ride-sharing platform needs to find drivers within 5km
of a rider. Explain why a standard composite B-Tree index on
`(latitude, longitude)` is insufficient, and what structure should be
used instead.

**Problem 3.** Design indexing for a retail `products` table supporting
`WHERE category_id = ? AND price BETWEEN ? AND ? ORDER BY
popularity_score DESC`. Identify which part of the query the index can
and cannot fully satisfy.

## Production Debugging (File 08)

**Problem 1.** Given `EXPLAIN` output showing `type=ALL` on a table
with an existing, seemingly relevant index, list three possible root
causes.

**Problem 2.** `EXPLAIN ANALYZE` shows an estimated 100 rows and an
actual 800,000 rows for a filter step. What's your immediate next
action?

**Problem 3.** A query plan shows `Using temporary; Using filesort` in
MySQL. What do each of these indicate, and what design change would you
consider for each?

**Problem 4.** A nested loop join's outer side unexpectedly returns
millions of rows instead of the expected few hundred. Explain why this
is disproportionately expensive compared to the same misestimate on a
hash join.

## Optimization

**Problem 1.** A slow query has three plausible columns to index but a
write-throughput budget that allows only one new index. Describe your
decision process.

**Problem 2.** Propose a plan to safely remove five indexes suspected to
be unused from a production OLTP table without risking a query
regression.

## Maintenance & Myths (File 10)

**Problem 1.** A table's write pattern has been stable for a year, but
`information_schema.tables` shows `data_free` at 35% of `data_length`.
What does this indicate, and what MySQL command addresses it directly?

**Problem 2.** Given `INDEX(a, b, c)` already exists on a table, is
`INDEX(a, b)` redundant? Is `INDEX(b, c)`? Justify both answers using the
leftmost prefix rule.

**Problem 3.** A colleague says "I added an index and `EXPLAIN` shows
it's being used, so the query is as fast as it can be." Identify what's
wrong with this reasoning and describe a concrete scenario where it's
false.

**Problem 4.** Why is `VACUUM` a structurally required operation in
PostgreSQL specifically, in a way that has no exact equivalent
requirement in SQL Server?

**Problem 5.** A `promotions`-style table (few rows, updated rarely) and
an `audit_log`-style table (millions of rows, insert-only, compliance
retention) both need index maintenance decisions. Propose a different
fillfactor and rebuild-schedule strategy for each, and justify the
difference.

## Further Reading

Solutions for every problem above are in
[13_SOLUTIONS.sql](13_SOLUTIONS.sql), organized under matching section
headers.
