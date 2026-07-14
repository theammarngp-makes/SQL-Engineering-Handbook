# 02 — UNION and UNION ALL

## Introduction

`UNION` and `UNION ALL` look nearly identical in syntax and are opposites in behavior and cost. Choosing between them incorrectly is one of the most common — and most consequential — mistakes in production SQL: it can silently delete real business data (duplicate transactions treated as errors) or silently degrade performance (paying for a sort you never needed).

## Concept Overview

- **`UNION`** — stacks the results of two or more `SELECT` statements and **removes duplicate rows** from the combined set.
- **`UNION ALL`** — stacks the results of two or more `SELECT` statements and **keeps every row**, duplicates included.

The only difference is de-duplication. Everything else — column rules, naming, `ORDER BY` placement — is identical between them.

## Why This Exists

Not every "combine these two result sets" problem has the same duplicate-handling requirement. Sometimes duplicates across the two sources are noise (the same city listed twice because two teams both maintain an office list) — `UNION` is correct. Sometimes duplicates are the entire point (two identical $50 transactions on the same card on the same day are two real events, not one) — `UNION ALL` is correct. SQL gives you both because business reality demands both.

## Business Context

A finance team merging Q1 and Q2 transaction logs wants **every** transaction, including two identical-looking ones — `UNION ALL`. A marketing team merging two mailing lists wants **one deduplicated** list of contacts to email — `UNION`. Choosing the wrong one either fabricates data loss or fabricates duplicate outreach.

## Real Company Examples

- A bank uses `UNION ALL` to combine `transactions_checking` and `transactions_savings` into one customer statement — every transaction must appear.
- A retailer uses `UNION` to build a single, deduplicated `all_store_cities` list — the same city should not be listed twice just because two regional teams both entered it.

## Production Use Cases

- Merging partitioned fact tables (`sales_2023`, `sales_2024`) — always `UNION ALL`.
- Building a deduplicated contact or reference list — `UNION`.
- Quantifying duplicate rows before a cleanup project by comparing `UNION` and `UNION ALL` row counts.

## Visual Explanation

```
 Branch A: [10, 20, 20, 30]      Branch B: [20, 40]

 UNION ALL → [10, 20, 20, 30, 20, 40]     (6 rows — nothing removed)
 UNION     → [10, 20, 30, 40]             (4 rows — all duplicates collapsed,
                                            including the internal duplicate
                                            20 that already existed in A)
```

## Syntax

```sql
SELECT col1, col2 FROM table_a
UNION ALL              -- or UNION
SELECT col1, col2 FROM table_b
ORDER BY col1;
```

## Detailed Explanation

A critical, frequently-missed detail: `UNION` doesn't just remove duplicates **between** the branches — it removes duplicates **within the entire combined result**, including duplicates that already existed inside a single branch before combination. If branch A alone contains the same row twice, `UNION` collapses those too, even if branch B is empty.

`UNION ALL` never inspects row content for duplication. It is a pure concatenation, which is why it's inexpensive: no sort, no hash table, no comparison — just append.

## Business Examples

```sql
-- Correct: every transaction matters, duplicates are real events
SELECT transaction_id, amount, transaction_date FROM transactions_q1
UNION ALL
SELECT transaction_id, amount, transaction_date FROM transactions_q2;
```

```sql
-- Correct: a reference list should never have duplicate entries
SELECT DISTINCT region_name FROM sales_us
UNION
SELECT DISTINCT region_name FROM sales_emea;
```

## Production Workflow

1. Ask: "Is a duplicate row here a data error, or a real, separate business event?"
2. If it's a real event (transactions, orders, log entries) → `UNION ALL`.
3. If it's a reference/lookup/reporting list where duplicates are noise → `UNION`.
4. When unsure, default to `UNION ALL` and de-duplicate explicitly downstream with `GROUP BY` or `DISTINCT` — this keeps the decision visible and intentional rather than silently baked into the operator.

## Engineering Considerations

- `UNION ALL` is the correct default inside ETL/ELT pipelines building fact tables — losing a legitimate duplicate transaction is a data integrity incident.
- `UNION` is appropriate for dimension/reference-style outputs where identity, not event count, matters.
- Row-count differences between `UNION` and `UNION ALL` on the *same two branches* is a fast, reliable way to measure exactly how much duplication exists between two sources.

## Performance Notes

`UNION` requires the engine to detect and remove duplicates across the full combined result, which typically costs a **sort or hash-based deduplication pass**. On a combined result of millions of rows, that pass can dominate the query's total cost. `UNION ALL` has none of this cost — it is a simple append operation. When you know duplicates are impossible or irrelevant, using `UNION` anyway is pure wasted cost.

## Database Compatibility

| Behavior | MySQL | PostgreSQL | SQL Server | Oracle |
|---|---|---|---|---|
| `UNION` de-duplicates | ✅ | ✅ | ✅ | ✅ |
| `UNION ALL` keeps all rows | ✅ | ✅ | ✅ | ✅ |
| `UNION DISTINCT` as explicit synonym for `UNION` | ✅ | ✅ | ❌ | ❌ |

## Best Practices

- Default to `UNION ALL` in pipeline/ETL code; make deduplication an explicit, visible step if needed.
- Use `UNION` only when duplicates are genuinely meaningless to the business question.
- Never choose between them based on "which one runs" — both almost always run; the difference is correctness and cost, not validity.

## Common Mistakes

- Using `UNION` out of habit, silently dropping real duplicate business events (classic financial reporting bug).
- Using `UNION ALL` when a report requires a clean, deduplicated reference list, producing visibly repeated rows in a customer-facing report.
- Believing `UNION ALL` is "wrong" or "sloppy" — it is simply a different, and often more correct, tool.

## Edge Cases

- `UNION` treats two `NULL` values as duplicates of each other and collapses them, even though `NULL = NULL` evaluates to unknown everywhere else in SQL.
- A `UNION` of a branch against itself (`SELECT x FROM t UNION SELECT x FROM t`) is a fast, idiomatic way to deduplicate a single table — equivalent to `SELECT DISTINCT x FROM t`.

## Interview Questions

1. **(Foundational)** What exactly does `UNION` remove duplicates from — each branch individually, or the combined result?
2. **(Intermediate)** Why is `UNION ALL` almost always preferred inside ETL pipelines building fact tables?
3. **(Intermediate)** How would you use `UNION` and `UNION ALL` together to count how many duplicate rows exist between two tables?
4. **(Advanced)** `SELECT x FROM t UNION SELECT x FROM t` — what does this accomplish, and what simpler statement is it equivalent to?
5. **(Staff-level)** A nightly report suddenly shows fewer transactions than the source system. The only recent change was swapping `UNION ALL` for `UNION` in the report's SQL. Explain the likely root cause.

## Summary

`UNION` and `UNION ALL` differ only in de-duplication, but that single difference changes both the correctness and the performance profile of a query. Choose based on whether a duplicate row represents a real business event or noise — never by default.

## Practice Problems

1. Using `departments` and `locations`, write a query that would demonstrate — with row counts — how many duplicate values exist between `dept_name` and `city` if any did.
2. Rewrite a `UNION` query as a `UNION ALL` and explain, in a comment, exactly which rows would newly appear.
3. Write a query using `UNION ALL` twice on the same table to intentionally double a result set, and explain a legitimate business scenario where this is useful (hint: weighting or sampling).

## Further Reading

- PostgreSQL Docs — `UNION`, `UNION ALL`, `UNION DISTINCT`
- Microsoft Learn — `UNION` (Transact-SQL)
- Oracle SQL Language Reference — `UNION [ALL]`

---
[← Introduction to Set Operators](01_INTRODUCTION_TO_SET_OPERATORS.md) · [Next: INTERSECT and EXCEPT →](03_INTERSECT_AND_EXCEPT.md)
