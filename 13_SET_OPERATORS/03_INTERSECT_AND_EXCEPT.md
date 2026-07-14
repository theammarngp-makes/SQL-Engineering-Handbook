# 03 — INTERSECT and EXCEPT

## Introduction

If `UNION` answers "what's the combined picture?", `INTERSECT` and `EXCEPT` answer the two questions that matter most in reconciliation work: **"what do these two sets have in common?"** and **"what's missing from one side?"** These are the operators behind every migration audit, every reconciliation report, and every "did we lose any data?" question.

## Concept Overview

- **`INTERSECT`** — returns only the rows that appear in **both** branches.
- **`EXCEPT`** (ANSI SQL / PostgreSQL / SQL Server) or **`MINUS`** (Oracle) — returns rows from the **first** branch that do **not** appear in the second. Order matters: `A EXCEPT B` is not the same as `B EXCEPT A`.

Both operators de-duplicate their output, just like `UNION`.

## Why This Exists

Comparing two datasets for overlap or difference is a constant need wherever the same kind of data lives in more than one place — which, in any real organization, is almost everywhere. `INTERSECT` and `EXCEPT` let you express "compare these two populations" as a single declarative statement instead of a manual `JOIN`-and-inspect process.

## Business Context

A company migrating from an old CRM to a new one needs to know: which customers exist in **both** systems (`INTERSECT` — successfully migrated), and which exist **only** in the old system (`EXCEPT` — migration gaps that need investigation).

## Real Company Examples

- A bank uses `EXCEPT` to find accounts present in the core ledger but absent from the fraud-monitoring replica — a potential replication failure.
- An e-commerce company uses `INTERSECT` to find customers who appear in both the loyalty-program table and the newsletter subscriber table, to avoid sending duplicate welcome emails from two different systems.
- A hospital network uses `EXCEPT` both directions to prove a patient-record migration between two EHR systems was complete.

## Production Use Cases

- Migration completeness checks (`EXCEPT` both directions should return zero rows).
- Cross-system reconciliation (ERP vs. CRM, production vs. staging).
- Finding overlap between two audiences for marketing, compliance, or fraud analysis.
- Detecting orphaned or missing foreign-key references across tables that should mirror each other.

## Visual Explanation

```
   A = {1, 2, 3}        B = {2, 3, 4}

   INTERSECT (A, B) → {2, 3}        (in both)
   EXCEPT (A - B)   → {1}           (in A only)
   EXCEPT (B - A)   → {4}           (in B only)

        A ┌────┬────┐ B
          │ 1  │2, 3│ 4
          └────┴────┘
             ↑
        intersection
```

## Syntax

```sql
-- INTERSECT (all four target databases; MySQL 8.0.31+)
SELECT column_list FROM table_a
INTERSECT
SELECT column_list FROM table_b;

-- EXCEPT (ANSI SQL / PostgreSQL / SQL Server / MySQL 8.0.31+)
SELECT column_list FROM table_a
EXCEPT
SELECT column_list FROM table_b;

-- Oracle uses MINUS instead of EXCEPT
SELECT column_list FROM table_a
MINUS
SELECT column_list FROM table_b;
```

## Detailed Explanation

`EXCEPT`/`MINUS` is directional and order-sensitive — this is the single most important thing to internalize. `A EXCEPT B` finds what A has that B lacks; reversing the order answers a completely different business question. A full reconciliation almost always requires running it **both directions**:

```sql
SELECT customer_id FROM crm_customers
EXCEPT
SELECT customer_id FROM erp_customers;   -- in CRM, missing from ERP

SELECT customer_id FROM erp_customers
EXCEPT
SELECT customer_id FROM crm_customers;   -- in ERP, missing from CRM
```

Both queries returning zero rows is the actual proof of a complete, matching migration — not a single query, and not a row count comparison (two tables can have the same row count and still contain entirely different rows).

## Simulating INTERSECT and EXCEPT Without Native Support

Older MySQL versions (before 8.0.31) don't support `INTERSECT` or `EXCEPT` natively. Both can be simulated using `JOIN`/`EXISTS` and `NOT EXISTS`:

```sql
-- INTERSECT simulation, using EXISTS
SELECT DISTINCT a.customer_id
FROM crm_customers a
WHERE EXISTS (
    SELECT 1 FROM erp_customers b
    WHERE b.customer_id = a.customer_id
);

-- EXCEPT / MINUS simulation, using NOT EXISTS
SELECT DISTINCT a.customer_id
FROM crm_customers a
WHERE NOT EXISTS (
    SELECT 1 FROM erp_customers b
    WHERE b.customer_id = a.customer_id
);
```

`NOT EXISTS` is preferred over `NOT IN` for this simulation because `NOT IN` behaves incorrectly — returning no rows at all — if the subquery's column contains even a single `NULL`. `NOT EXISTS` has no such trap.

## Business Examples

```sql
-- Customers who exist in both the loyalty program and the newsletter list
SELECT customer_id FROM loyalty_members
INTERSECT
SELECT customer_id FROM newsletter_subscribers;
```

```sql
-- Orders present in production but missing from the analytics staging copy
SELECT order_id FROM production.orders
EXCEPT
SELECT order_id FROM staging.orders;
```

## Production Workflow

1. Identify the two populations being compared and confirm they share a comparable key/column shape.
2. Decide whether the question is "what's shared?" (`INTERSECT`) or "what's missing?" (`EXCEPT`/`MINUS`).
3. For reconciliation, always run `EXCEPT` in both directions.
4. If the target database lacks native support, simulate with `EXISTS`/`NOT EXISTS`, never with `NOT IN` on a nullable column.
5. Zero rows returned from both directions of `EXCEPT` is the pass condition for a reconciliation check — treat it as a testable assertion, not just an inspection query.

## Engineering Considerations

- `INTERSECT`/`EXCEPT` compare entire rows (all selected columns together), not just a single column, unless you deliberately select only one column — be precise about which columns define "the same row" for your comparison.
- These operators are ideal candidates for automated data tests (e.g., a dbt test or a CI check that asserts an `EXCEPT` query returns zero rows).

## Performance Notes

Like `UNION`, both `INTERSECT` and `EXCEPT` require de-duplication and are typically implemented via sort or hash-based set comparison. On large tables, an equivalent `NOT EXISTS`/`EXISTS` rewrite with proper indexes on the join column often outperforms the native set operator, because the optimizer can use an index seek per row rather than materializing and sorting both full sets. Always compare execution plans on your actual data volume rather than assuming either form is universally faster.

## Database Compatibility

| Feature | MySQL | PostgreSQL | SQL Server | Oracle |
|---|---|---|---|---|
| `INTERSECT` | 8.0.31+ | ✅ | ✅ | ✅ |
| `EXCEPT` | 8.0.31+ | ✅ | ✅ | ❌ (use `MINUS`) |
| `MINUS` | ❌ | ❌ | ❌ | ✅ |
| `EXISTS`/`NOT EXISTS` simulation | ✅ (all versions) | ✅ | ✅ | ✅ |

## Best Practices

- Always reconcile in both directions with `EXCEPT`/`MINUS` — one direction alone proves nothing about the reverse.
- Prefer `NOT EXISTS` over `NOT IN` when simulating `EXCEPT`, especially against nullable columns.
- Wrap `EXCEPT` reconciliation queries as automated tests with an expected result of zero rows, not manual inspection.

## Common Mistakes

- Running `EXCEPT` only one direction and declaring a migration "complete."
- Using `NOT IN` instead of `NOT EXISTS`/`LEFT JOIN ... IS NULL` against a column that can contain `NULL`, silently returning zero rows regardless of the real answer.
- Assuming Oracle supports `EXCEPT` — it requires `MINUS`.
- Forgetting that `INTERSECT`/`EXCEPT` compare the **entire row** across all selected columns, not just the first one.

## Edge Cases

- If either branch is empty, `INTERSECT` always returns an empty set, and `EXCEPT` returns the first branch unchanged (deduplicated).
- `NULL` values are treated as equal to each other in `INTERSECT`/`EXCEPT` comparisons, consistent with their treatment in `UNION`.

## Interview Questions

1. **(Foundational)** What does `INTERSECT` return, and how is it different from a `JOIN`?
2. **(Intermediate)** Why is `A EXCEPT B` not the same as `B EXCEPT A`?
3. **(Intermediate)** How would you simulate `EXCEPT` in a MySQL version that doesn't support it?
4. **(Advanced)** Why is `NOT EXISTS` generally safer than `NOT IN` for this simulation?
5. **(Staff-level)** Design a two-query test that proves a table migration between two databases moved every row with no additions or losses.

## Summary

`INTERSECT` finds overlap; `EXCEPT`/`MINUS` finds one-directional difference. Both are the backbone of reconciliation and migration-validation work, and both can be simulated with `EXISTS`/`NOT EXISTS` where native support is missing.

## Practice Problems

1. Write an `INTERSECT` query to find employees who are also referenced as a `manager_id` elsewhere in the `employees` table (i.e., employees who manage someone).
2. Write the same query as Problem 1 using `EXISTS` instead of `INTERSECT`.
3. Write two `EXCEPT` queries (both directions) to compare `dept_id` values between `employees` and `departments`, and explain what a non-empty result in each direction would mean for data integrity.

## Further Reading

- PostgreSQL Docs — `INTERSECT`, `EXCEPT`
- Oracle SQL Language Reference — `MINUS`
- Microsoft Learn — `EXCEPT` and `INTERSECT` (Transact-SQL)

---
[← UNION and UNION ALL](02_UNION_AND_UNION_ALL.md) · [Next: Business Data Integration →](04_BUSINESS_DATA_INTEGRATION.md)
