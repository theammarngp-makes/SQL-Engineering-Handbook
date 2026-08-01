# 11 — Interview Guide

## Introduction

50+ production-style interview questions on indexing, organized by
difficulty and type: conceptual, scenario-based, architecture, and
optimization. Every question maps back to a specific file in this
module — cross-references are included so you can review the underlying
concept, not just memorize an answer.

## How to Use This Guide

Attempt each question from memory first. Where you're unsure, follow the
file reference, re-read that section, then return and re-answer without
looking. This mirrors how the concept will actually be probed in an
interview — as a follow-up, not a one-shot question.

## Easy — Conceptual Fundamentals

1. What is an index, physically? (File 01)
2. Why is a full table scan O(n)? (File 01)
3. What's the difference between an index seek and an index scan? (File
   01)
4. What is a B-Tree, and why is it the default index structure? (File
   02)
5. What is the difference between a clustered and non-clustered index?
   (File 02, File 04)
6. What is a composite index? (File 03)
7. What is the leftmost prefix rule? (File 03)
8. What's the difference between a `PRIMARY KEY` and a `UNIQUE`
   constraint? (File 04)
9. Why do foreign keys usually need a supporting index? (File 04)
10. What is a covering index? (File 05)
11. What is an index-only scan? (File 05)
12. Name three situations where indexes hurt more than they help. (File
    06)
13. What is selectivity? (File 07)
14. What is cardinality, and how does it relate to selectivity? (File
    07)
15. What's the difference between `EXPLAIN` and `EXPLAIN ANALYZE`?
    (File 08)

## Medium — Applied Understanding

16. Given `INDEX(a, b, c)`, which of these can use the index:
    `WHERE b = 2`, `WHERE a = 1 AND c = 3`, `WHERE a = 1 AND b = 2`?
    (File 03)
17. Why should equality-filtered columns precede range-filtered columns
    in a composite index? (File 03)
18. You add an index and the query doesn't get faster. List three
    possible explanations. (Files 01, 07)
19. Why might the optimizer ignore an available index on a boolean
    column? (File 07)
20. Explain why `SELECT *` can silently defeat a covering index. (File
    05)
21. What does `Using filesort` mean in MySQL's `EXPLAIN` output, and
    what would you do about it? (File 08)
22. Why does InnoDB's clustered primary key structure matter for
    secondary index performance? (File 02, File 04)
23. What's the operational risk of leaving an optimizer hint (`FORCE
    INDEX`) in a query indefinitely? (File 07)
24. Why does PostgreSQL not auto-create an index for a foreign key,
    unlike MySQL InnoDB? What's the consequence if you forget? (File
    04)
25. Explain the trade-off a covering index makes. (File 05)
26. Why do OLTP and OLAP tables warrant different indexing budgets?
    (File 06)
27. What is a histogram, and what problem does it solve that plain
    cardinality doesn't? (File 07)
28. Design an index for: "find all orders for a customer placed in the
    last 30 days, sorted by date." (Files 02, 03)
29. Why can a random UUID primary key hurt InnoDB write performance
    compared to an auto-increment integer? (File 02)
30. What's the difference between a unique index and a unique
    constraint, implementation-wise? (File 04)

## Hard — Deep Mechanics

31. Walk through, step by step, how the optimizer decides between a full
    scan and an index seek for a given query. (File 01, File 07)
32. Explain why a B+Tree's linked leaf nodes matter specifically for
    range queries, and what would be lost with a plain B-Tree. (File 02)
33. You're designing a composite index to serve two different query
    shapes that filter on different column combinations. When is one
    composite index sufficient, and when do you need two separate
    indexes? (File 03)
34. Explain multi-column correlation and why it can mislead the
    optimizer's cost estimates. (File 07)
35. Why does `EXPLAIN ANALYZE` on a write statement carry real risk in
    production, beyond just being slow? (File 08)
36. Compare Nested Loop, Hash, and Merge join strategies and the
    indexing conditions that favor each. (File 08)
37. Explain why a foreign-key check without a supporting index can turn
    a parent-table `DELETE` into an effective full scan of the child
    table. (File 04)
38. What operational signal would tell you an index has gone stale (in
    terms of statistics, not structure), and how would you confirm it
    via `EXPLAIN`? (File 07, File 08)

## FAANG-Style / Scenario-Based

39. A dashboard query that joins two 50-million-row tables has gone from
    200ms to 40 seconds overnight with no code deploy. Walk through your
    diagnostic process. (Files 07, 08)
40. You're asked to design the indexing strategy for a new multi-tenant
    SaaS table from scratch. What questions do you ask before writing a
    single `CREATE INDEX`? (File 06)
41. A junior engineer proposes indexing every column in a hot,
    high-write `events` table "to be safe." How do you respond, and
    what would you propose instead? (File 06)
42. Given a table with 10 existing indexes and degrading write
    throughput, how would you decide which indexes are safe to drop?
    (File 06)
43. Design the indexing for an e-commerce order-search feature that
    needs to filter by customer, date range, and status simultaneously,
    sorted by date. (Files 03, 07)

## Architecture Questions

44. In a star-schema warehouse, how would you approach indexing fact
    vs. dimension tables differently? (File 06)
45. How does the choice of primary key affect physical storage in
    InnoDB, and what does that imply for schema design decisions made
    early in a project? (File 02, File 04)
46. When would you choose a spatial index over a composite B-Tree
    index, and why can't a B-Tree solve that problem? (File 09)

## Optimization Questions

47. A query filters on a low-selectivity column and the optimizer
    correctly avoids the available index in favor of a full scan. Is
    this a bug? How would you actually speed up this query? (File 07)
48. How would you use `EXPLAIN ANALYZE`'s estimated-vs-actual row
    comparison to diagnose a plan regression? (File 08)
49. A covering index exists but `EXPLAIN` shows the query isn't using
    it as an index-only scan. What would you check first? (File 05)
50. You're given a slow query with three candidate columns to index and
    a strict write-throughput budget that only allows one new index.
    How do you decide which column to index? (Files 06, 07)

## Execution Plan Questions

51. Interpret this MySQL `EXPLAIN` row: `type=ALL, key=NULL,
    rows=9800000, Extra=Using where`. What's happening, and what would
    you investigate first? (Files 01, 07, 08)
52. Interpret this MySQL `EXPLAIN` row: `type=ref,
    key=idx_orders_customer_id, rows=4, Extra=Using index`. What does
    this confirm? (Files 01, 05, 08)
53. In `EXPLAIN ANALYZE` output, estimated rows are 50 and actual rows
    are 500,000. What's the likely root cause, and what's your fix?
    (File 07)

## Maintenance, Redundancy & Myths Questions

54. Why does an index degrade over time even if the table's schema
    never changes? (File 10)
55. What's the difference between what `ANALYZE TABLE` fixes and what
    `OPTIMIZE TABLE` fixes in MySQL? (File 10)
56. Given `INDEX(a, b, c)`, is `INDEX(a, b)` redundant? Is `INDEX(a,
    c)`? Explain the difference using the leftmost prefix rule. (Files
    03, 10)
57. A teammate claims "more indexes can only help, never hurt." Give a
    concrete, quantifiable rebuttal. (Files 06, 10)
58. Why is `VACUUM` non-optional in PostgreSQL specifically, tied to how
    its MVCC model works? (File 10)
59. Explain why "the query plan shows it used an index" is not the same
    claim as "the query is fast." (Files 07, 08, 10)

## Summary

These 59 questions span every file in this module. If you can answer
all of them from memory, cross-referenced back to the reasoning (not
just the label), you're prepared for indexing questions at a production
engineering interview level, not just a syntax-recall level.

## Further Reading

See [resources/interview-resources.md](resources/interview-resources.md).
