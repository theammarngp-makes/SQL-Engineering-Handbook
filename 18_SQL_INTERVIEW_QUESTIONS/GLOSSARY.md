# Glossary

**Cardinality** — number of rows a plan step produces or estimates. See [`16_QUERY_OPTIMIZATION` Lesson 08](../16_QUERY_OPTIMIZATION/08_COST_BASED_OPTIMIZER.md).

**Selectivity** — fraction of rows a predicate keeps (matching / total). Low selectivity = doesn't narrow much.

**SARGability** — whether a predicate lets the engine seek via an index rather than evaluate per row. See [`16_QUERY_OPTIMIZATION` Lesson 03](../16_QUERY_OPTIMIZATION/03_SARGABILITY_AND_INDEX_USAGE.md).

**Execution plan** — the physical operation sequence an engine chooses, visible via EXPLAIN.

**Predicate** — a WHERE/JOIN/HAVING condition evaluating to TRUE, FALSE, or UNKNOWN.

**Window** — the row set a window function considers for a given row, via PARTITION BY and an optional frame.

**Partition (window context)** — the group a row belongs to for window function purposes — distinct from table partitioning.

**Transaction** — a unit the database guarantees executes atomically. See [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 01](../17_TRANSACTIONS_AND_CONCURRENCY/01_ACID_AND_TRANSACTION_FUNDAMENTALS.md).

**Isolation** — the ACID property governing visibility of uncommitted concurrent work. See [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 02](../17_TRANSACTIONS_AND_CONCURRENCY/02_ISOLATION_LEVELS_AND_READ_PHENOMENA.md).

**Deadlock** — a cycle of transactions waiting on each other, resolved by force-rollback of one. See [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 04](../17_TRANSACTIONS_AND_CONCURRENCY/04_DEADLOCKS.md).

**Index** — an ordered structure letting the engine find rows without a full scan, at write-overhead cost.

**Covering index** — an index containing every column a query needs, avoiding a table lookup.

**Composite index** — multi-column index; column order determines what it can efficiently serve (leftmost-prefix rule).

**CTE** — a named `WITH`-defined subquery, optionally inlined or materialized depending on engine.

**Correlated subquery** — references a column from its enclosing query, conceptually re-evaluated per outer row unless rewritten.

**Lost update** — two transactions read-then-write the same row; the second write silently overwrites the first. See [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 02](../17_TRANSACTIONS_AND_CONCURRENCY/02_ISOLATION_LEVELS_AND_READ_PHENOMENA.md).

**MVCC** — readers see a consistent snapshot without blocking writers, via multiple row versions. See [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 05](../17_TRANSACTIONS_AND_CONCURRENCY/05_MVCC.md).

**Gaps and islands** — identifying consecutive runs/breaks in sequential data, typically via row-number-minus-date (Q014).

**Parameter sniffing** — a cached plan compiled for one parameter value's selectivity gets reused for a very different value. See [`16_QUERY_OPTIMIZATION` Lesson 08](../16_QUERY_OPTIMIZATION/08_COST_BASED_OPTIMIZER.md).

**Relational division** — finding entities that satisfy ALL of a required set, typically via nested NOT EXISTS (Q027).
