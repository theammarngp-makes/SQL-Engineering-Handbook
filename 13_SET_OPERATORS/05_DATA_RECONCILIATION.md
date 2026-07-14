# 05 — Data Reconciliation

## Introduction

Reconciliation is the discipline of proving two datasets agree — or precisely locating where they don't. It is one of the highest-value, most recurring tasks in analytics and data engineering, and set operators are its primary tool. This topic assembles everything from Topics 01–04 into repeatable reconciliation patterns.

## Concept Overview

A reconciliation query compares two datasets that are supposed to represent the same underlying reality — two systems tracking the same customers, two extracts of the same table taken at different pipeline stages, two independently computed financial totals — and answers: do they match, and if not, exactly where do they diverge?

## Why This Exists

Systems drift. Replication lags. ETL jobs fail partway through. Two teams build "the same" report from different source tables and get different numbers. Reconciliation exists because trusting that two systems agree, without checking, is how silent data quality incidents happen — the kind that surface months later as "wait, why don't these numbers match finance's report?"

## Business Context

A bank's fraud-detection system and its core ledger should, in theory, always agree on which accounts exist. A staging table in a data warehouse should always match the production extract it was built from. When these assumptions are wrong, reconciliation queries are how the gap gets found — before an auditor, a regulator, or a customer finds it first.

## Real Company Examples

- A bank reconciles `core_ledger_accounts` against `fraud_platform_accounts` nightly, alerting if `EXCEPT` in either direction returns rows.
- An insurance company reconciles `claims_production` against `claims_staging` after every ETL run, gating the warehouse load on zero-row reconciliation results.
- A retailer reconciles `inventory_warehouse_a` against `inventory_erp_system` weekly to catch sync failures between physical inventory and the enterprise system of record.

## Production Use Cases

- ERP vs. CRM customer reconciliation.
- Production vs. staging table validation after every ETL run.
- Financial statement reconciliation across independently built reports.
- Inventory reconciliation between a warehouse management system and an ERP.
- Missing-shipment detection between an "expected" and "received" manifest.

## Visual Explanation

```
   Expected Shipments          Received Shipments
 ┌───────────────────┐       ┌───────────────────┐
 │ SHIP-001          │       │ SHIP-001          │
 │ SHIP-002          │       │ SHIP-003 (unexp.) │
 │ SHIP-003          │       └───────────────────┘
 └───────────────────┘

 EXCEPT (Expected − Received) → SHIP-002   (never arrived — investigate)
 EXCEPT (Received − Expected) → { }        (nothing unexpected arrived here)
```

## Syntax

```sql
-- The reconciliation "gate": both directions must return zero rows to pass
SELECT key_column FROM system_a
EXCEPT
SELECT key_column FROM system_b;

SELECT key_column FROM system_b
EXCEPT
SELECT key_column FROM system_a;
```

## Detailed Explanation

A robust reconciliation isn't a single query — it's a small suite:

1. **Row count comparison** — a cheap first signal, but insufficient alone (two tables can match in count and still contain entirely different rows).
2. **`EXCEPT`, both directions** — the actual proof of a matching key set.
3. **Value-level comparison on matched keys** — even when keys match, the non-key columns (e.g., `order_total`) might not; this requires a `JOIN` plus a column-by-column comparison, which is where reconciliation and joins meet.

```sql
-- Step 3 example: keys match, but do the totals agree?
SELECT a.order_id, a.order_total AS production_total, b.order_total AS staging_total
FROM production.orders a
JOIN staging.orders b ON a.order_id = b.order_id
WHERE a.order_total <> b.order_total;
```

## Business Examples

```sql
-- Financial reconciliation: does the finance team's manual ledger match
-- the automated GL export, transaction for transaction?
SELECT transaction_id FROM finance_manual_ledger
EXCEPT
SELECT transaction_id FROM gl_automated_export;
```

```sql
-- Missing shipment detection
SELECT shipment_id FROM expected_shipments
EXCEPT
SELECT shipment_id FROM received_shipments;
```

## Production Workflow

1. Identify the shared business key between the two systems (customer ID, order ID, shipment ID).
2. Run `EXCEPT` both directions on that key.
3. If both return zero rows, proceed to value-level comparison via `JOIN` on matched keys.
4. If either returns rows, route them to an investigation queue — don't silently drop or ignore them.
5. Automate the whole suite as a scheduled data quality check with alerting on any non-zero result.

## Engineering Considerations

- Reconciliation queries should run on the **narrowest possible key set** — comparing full rows invites false mismatches from formatting differences (trailing whitespace, case sensitivity, timezone offsets) that aren't real business discrepancies.
- Timezone and precision mismatches between systems (e.g., `DATETIME` vs `DATE`, or floating-point vs `DECIMAL`) are a leading cause of false-positive reconciliation failures — normalize types before comparing.
- Reconciliation logic belongs in version-controlled, testable SQL (a dbt test, a CI-gated query), not in a one-off analyst notebook.

## Performance Notes

On very large tables, native `EXCEPT` can be more expensive than a `LEFT JOIN ... WHERE b.key IS NULL` or a `NOT EXISTS`, because the optimizer may materialize and sort both full sets rather than using an index-driven anti-join. Always benchmark the native operator against the join-based equivalent on production-scale data before committing to one pattern for a recurring job.

## Database Compatibility

| Pattern | MySQL | PostgreSQL | SQL Server | Oracle |
|---|---|---|---|---|
| `EXCEPT` reconciliation | 8.0.31+ | ✅ | ✅ | use `MINUS` |
| `LEFT JOIN ... IS NULL` equivalent | ✅ | ✅ | ✅ | ✅ |
| `NOT EXISTS` equivalent | ✅ | ✅ | ✅ | ✅ |

## Best Practices

- Always reconcile keys before values — mismatched keys make value comparison meaningless.
- Run `EXCEPT` in both directions; treat "zero rows both ways" as the pass condition.
- Normalize types and formatting (trim whitespace, cast to consistent precision) before comparing across systems.
- Automate reconciliation as a recurring, alerting job — not a manual one-time check.

## Common Mistakes

- Comparing row counts alone and declaring success.
- Reconciling only one direction of `EXCEPT`.
- Comparing full rows instead of business keys, generating false mismatches from formatting noise.
- Treating a non-empty reconciliation result as "the query is broken" instead of investigating the underlying data.

## Edge Cases

- Soft-deleted or logically-deleted rows in one system but not the other will always appear as a mismatch unless explicitly filtered — decide up front whether soft-deletes count as "present."
- Late-arriving data (a row that exists in system B but hasn't synced to system A yet) can produce a transient, expected mismatch — reconciliation timing needs to account for expected sync latency.

## Interview Questions

1. **(Foundational)** Why is a matching row count between two tables not sufficient proof they're reconciled?
2. **(Intermediate)** Design a reconciliation check between a production `orders` table and its staging copy. What would you compare, and in what order?
3. **(Advanced)** What's a common cause of false-positive reconciliation failures between two systems that store "the same" data?
4. **(Staff-level)** A nightly reconciliation job between ERP and CRM customer tables has started failing intermittently, always showing 3–5 mismatched rows that clear up by the next run. Propose a hypothesis and how you'd confirm it.

## Summary

Reconciliation combines row-count checks, bidirectional `EXCEPT` on business keys, and value-level `JOIN` comparisons into a repeatable suite that proves — rather than assumes — that two systems agree. It is where set operators do some of their most important production work.

## Practice Problems

1. Design a full reconciliation suite (row count, bidirectional `EXCEPT`, value comparison) between two hypothetical tables `orders_production` and `orders_staging`.
2. Write the `LEFT JOIN`-based equivalent of a bidirectional `EXCEPT` check and explain when you'd prefer it.
3. Describe, in comments, how you'd handle a reconciliation check where one system stores `DATETIME` and the other stores `DATE` for the same logical field.

## Further Reading

- PostgreSQL Docs — `EXCEPT` and anti-join patterns
- Microsoft Learn — data validation patterns using `EXCEPT`
- dbt Developer Hub — data testing and reconciliation patterns

---
[← Business Data Integration](04_BUSINESS_DATA_INTEGRATION.md) · [Next: Performance and Optimization →](06_PERFORMANCE_AND_OPTIMIZATION.md)
