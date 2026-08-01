# 09 — Real-World Case Studies

## A Note on Format

This file intentionally departs from the 27-section template used in Files
01-08. A case-study file that repeated Learning Objectives, ANSI SQL Notes,
and Edge Cases nine times over would be almost entirely restated
boilerplate — the value of this file is in the business problem →
engineering decision reasoning itself, not in re-deriving concepts already
covered. Each case study below states the requirement, the query shape it
produces, the indexing decision, and — critically — **why this scenario
poses a genuinely different challenge**, not just a different table name,
than the others in this file. Every query below runs directly against the
schema created in [00_SETUP.sql](00_SETUP.sql).

## Introduction

Interviewers and real engineering reviews rarely ask "what is a B-Tree" in
isolation — they ask "design the indexing for this table given this access
pattern." This file is deliberately structured the way that conversation
actually happens, across ten industries, each contributing at least one
indexing lesson not already fully covered by an earlier, simpler case.

## Case Study: E-Commerce — Order History & Shipment Tracking

**Requirement**: customers view their own order history, sorted newest
first; support agents track a shipment by tracking number.

```sql
SELECT order_id, order_date, status, total_amount
FROM orders
WHERE customer_id = ?
ORDER BY order_date DESC;

SELECT * FROM shipments WHERE tracking_number = ?;
```

**Decision**: `INDEX(customer_id, order_date DESC)` on `orders` — equality
column leading, `ORDER BY` satisfied by index order directly (Files 02/03).
`UNIQUE INDEX` on `shipments.tracking_number` — globally unique, a
correctness constraint as much as a performance one (File 04).

**The distinct lesson here**: this is the "clean" baseline case — a
single-table equality filter with a sort. Every other case study in this
file introduces at least one complication this one doesn't have.

## Case Study: Banking — Fraud Velocity Checks & Settlement Reconciliation

**Requirement**: flag an account if it has more than 5 transactions in any
rolling 10-minute window (velocity check); reconcile a transfer by matching
it against its counterparty's mirrored transaction.

```sql
-- Velocity check: how many transactions has this account made recently?
SELECT COUNT(*) FROM transactions
WHERE account_id = ?
  AND occurred_at >= NOW() - INTERVAL 10 MINUTE;

-- Reconciliation: find the mirrored leg of a transfer on the other account
SELECT * FROM transactions
WHERE counterparty_account = ?
  AND amount = ?
  AND transaction_type = 'transfer'
  AND occurred_at BETWEEN ? AND ?;
```

**Decision**: `INDEX(account_id, occurred_at)` supports the velocity check
as a range seek within an equality-filtered account — this is the
composite equality-then-range pattern from File 03, applied to a
**sliding time window** rather than a fixed date range, which is the
dominant query shape in fraud/abuse detection generally.

The reconciliation query is the genuinely new lesson: it filters on
`counterparty_account`, not `account_id` — a **self-referencing lookup**
against the same table from "the other side" of the relationship. No
single composite index serves both directions of this table efficiently;
in practice this requires either a second index
`INDEX(counterparty_account, amount, occurred_at)` or an accepted trade-off
that reconciliation runs as a lower-frequency batch job against a
replica, not the hot path (File 06's OLTP index-budget reasoning applies
directly here — a bank ledger table cannot absorb unlimited indexes).

## Case Study: Healthcare — Patient Search, Appointment Conflicts & Insurance Status Polling

**Requirement**: front-desk staff search patients by MRN or by
last name + date of birth; scheduling needs to detect whether a provider
is already booked at a requested time; billing polls claims-adjacent
insurance verification status.

```sql
SELECT * FROM patients WHERE mrn = ?;
SELECT * FROM patients WHERE last_name = ? AND date_of_birth = ?;

-- Is this provider already booked in this slot?
SELECT * FROM appointments
WHERE provider_id = ?
  AND scheduled_at BETWEEN ? AND ?;

SELECT * FROM insurance_verifications WHERE status = 'pending';
```

**Decision**: unique index on `mrn`; composite `(last_name, date_of_birth)`
since neither column alone is selective (File 03/07's selectivity
reasoning, applied to names rather than order data).

The appointment conflict check is a distinct lesson: `INDEX(provider_id,
scheduled_at)` supports it as an equality-then-range seek — but unlike the
banking velocity check above, this range is typically only a few minutes
wide against a comparatively small provider schedule, so the win is
about correctness-critical low latency (double-booking prevention) more
than raw row-count reduction.

The insurance status poll is a direct, deliberate callback to File 07:
`status = 'pending'` is exactly the kind of low-cardinality filter the
optimizer will often correctly serve via a full scan rather than an
index — worth indexing only if `pending` is the rare state, not the
common one, which is something you check with real cardinality data, not
assumption.

## Case Study: Manufacturing — Inventory Lookup, Warehouse Scan Logging & Supplier Performance

**Requirement**: check stock for a SKU at a warehouse; log every physical
scan event as inventory moves; measure a supplier's on-time delivery rate.

```sql
SELECT quantity FROM inventory WHERE sku = ? AND warehouse_id = ?;

INSERT INTO inventory_movements (sku, warehouse_id, movement_type, quantity_delta, scanned_at)
VALUES (?, ?, ?, ?, NOW());

SELECT
    supplier_id,
    SUM(on_time) / COUNT(*) AS on_time_rate
FROM supplier_deliveries
WHERE warehouse_id = ?
  AND expected_at >= ?
GROUP BY supplier_id;
```

**Decision**: `(sku, warehouse_id)` as the table's composite primary key —
File 04's pattern of the natural key and the lookup path being the same
structure.

The distinct lesson is `inventory_movements`: this table takes an
`INSERT` on every physical scan — a genuinely high-write, append-only
table, the manufacturing-floor equivalent of the `sessions`/`audit_log`
tables discussed abstractly in File 06. It should carry the **minimum**
indexing (arguably none beyond the primary key, until a specific reporting
query justifies one) — this is the case study that makes File 06's
OLTP-budget argument concrete with a physical-world analog (a handheld
scanner firing inserts continuously on a warehouse floor) rather than an
abstract "high write table."

The supplier performance query introduces an aggregation
(`GROUP BY supplier_id`) over a range filter — `INDEX(warehouse_id,
expected_at)` narrows the scan before the aggregate runs, but the
`GROUP BY` itself still requires either a sort or a hash aggregation step
downstream of the index seek — a preview of File 08's `Using temporary`
plan flag.

## Case Study: HR — Payroll Runs

**Requirement**: generate a pay run for all active employees in a given
pay period.

```sql
SELECT * FROM employees
WHERE status = 'active'
  AND pay_period = ?;
```

**Decision**: `status` alone is low-selectivity (File 07) — most employees
are active most of the time — so `INDEX(pay_period, status)` outperforms
indexing `status` in isolation, since `pay_period` narrows first and
`status` only needs to filter within an already-small slice. This is a
batch-style, scheduled query — a candidate for a partial/filtered index
(`WHERE status = 'active'`, PostgreSQL) since only active employees are
ever queried this way, illustrating a partial-index use case not otherwise
covered.

## Case Study: Retail — Seasonal Promotion Filtering & Product Search

**Requirement**: find products in a category within a price range, sorted
by popularity; separately, find all promotions active for a category
*right now*.

```sql
SELECT * FROM products
WHERE category_id = ?
  AND price BETWEEN ? AND ?
ORDER BY popularity_score DESC;

-- Active promotion check: TWO independent range conditions
SELECT * FROM promotions
WHERE category_id = ?
  AND starts_at <= CURDATE()
  AND ends_at >= CURDATE();
```

**Decision**: `INDEX(category_id, price)` for product search — the
familiar equality-then-single-range pattern.

The promotion check is the genuinely new lesson: it has **two independent
range conditions** (`starts_at <= today` AND `ends_at >= today`) rather
than one. A composite B-Tree index can only use one range boundary per
seek to narrow the scan — `INDEX(category_id, starts_at)` narrows on
`starts_at` but still must post-filter every candidate row against
`ends_at`. This is a case where no single composite index fully resolves
the query the way File 03's single-range examples do, and it's worth
recognizing rather than assuming a bigger composite index would fix it —
the honest options are accepting the post-filter (fine, if the
`category_id`-narrowed candidate set is already small), or restructuring
the check as an interval-overlap query pattern, which is out of this
module's scope but worth knowing exists.

## Case Study: Insurance — Claim Validation & Fraud Investigation

**Requirement**: validate a claim by claim number; investigators pull all
flagged claims for a policy within a filing window.

```sql
SELECT * FROM claims WHERE claim_number = ?;

SELECT * FROM claims
WHERE policy_id = ?
  AND status = 'flagged'
  AND filed_at BETWEEN ? AND ?;
```

**Decision**: unique index on `claim_number`; composite
`(policy_id, status, filed_at)` for the investigation query.

The distinct lesson: `status = 'flagged'` is almost certainly a **rare**
value in the overall distribution of claim statuses (most claims are
`filed`, `under_review`, or `approved`) — this is the mirror image of the
HR case study above. Where HR's `status` column needed a *leading*
narrowing column because the filtered value was common, here `status`
being rare means a histogram (File 07) could let the optimizer use even a
single-column index on `status` alone effectively for this specific
value, despite the column's poor *overall* selectivity — a concrete,
business-grounded instance of File 07's Edge Cases section.

## Case Study: Ride-Sharing — Ride History & Proximity Search

**Requirement**: show a rider's past rides; find available drivers near a
requested pickup point.

```sql
SELECT * FROM rides
WHERE rider_id = ?
ORDER BY requested_at DESC;
```

**Decision**: `INDEX(rider_id, requested_at DESC)` — same pattern as
e-commerce order history.

**Proximity search** is fundamentally a spatial query, not a plain
equality/range filter — "within N km" isn't expressible as a single
B-Tree range condition the way a date range is. This calls for a
**spatial index** (MySQL's `SPATIAL INDEX` on the `drivers.location`
`POINT` column), the one case in this module where the correct answer is
a structurally different index type, not a different composite ordering
of a B-Tree.

## Case Study: Streaming — Recommendation Lookup

**Requirement**: fetch a user's top 20 precomputed recommendations.

```sql
SELECT content_id, score
FROM recommendations
WHERE user_id = ?
ORDER BY score DESC
LIMIT 20;
```

**Decision**: `INDEX(user_id, score DESC, content_id)`, designed as a
**covering** index (File 05) — this table is rewritten wholesale on a
batch schedule (an OLAP-adjacent write pattern per File 06), so a wider,
fully-covering index is cheap to maintain relative to its benefit at
massive read volume.

## Case Study: SaaS — Tenant Isolation & Audit Logging

**Requirement**: every query in the product must be scoped to exactly one
tenant; compliance requires querying a tenant's full audit history by
actor and event type, and retaining it for years.

```sql
SELECT * FROM audit_log
WHERE tenant_id = ?
  AND actor_user_id = ?
  AND event_type = ?
ORDER BY occurred_at DESC;
```

**Decision**: `INDEX(tenant_id, actor_user_id, event_type, occurred_at)` —
`tenant_id` leads every single index on every single table in a
multi-tenant schema, without exception.

This is the distinct lesson multi-tenant SaaS adds that no other case
study in this file has: `tenant_id`-first indexing is not just a
performance optimization, it's the physical enforcement mechanism behind
row-level tenant isolation — a query that accidentally omits the
`tenant_id` predicate is both a **performance bug** (full scan across
every tenant's data) and a **security bug** (a missing `WHERE tenant_id
= ?` is how cross-tenant data leaks happen). The two concerns point at
the same fix, which is unusually clean but shouldn't be mistaken for
performance indexing being a substitute for application-layer tenant
authorization checks.

`audit_log` also compounds File 06's write-heavy-table caution with a
retention constraint: you can't just delete old rows to control table
size the way you might for a `sessions` table, because compliance
requires keeping them — this is the direct real-world motivation for File
10's coverage of index maintenance and long-term bloat management.

## Case Study: Marketing — Multi-Touch Attribution

**Requirement**: reconstruct the sequence of marketing touches a customer
had before converting; separately, measure a campaign's conversion rate.

```sql
-- Reconstruct one customer's touch sequence
SELECT campaign_id, occurred_at, converted
FROM touchpoints
WHERE customer_id = ?
ORDER BY occurred_at;

-- Campaign conversion rate
SELECT
    campaign_id,
    SUM(converted) / COUNT(*) AS conversion_rate
FROM touchpoints
WHERE campaign_id = ?
GROUP BY campaign_id;
```

**Decision**: two different composite indexes for two genuinely different
dominant queries against the same table —
`INDEX(customer_id, occurred_at)` for touch-sequence reconstruction, and
`INDEX(campaign_id, converted)` for conversion-rate rollups.

The lesson: `converted` is a boolean, poor as a leading index column in
isolation (File 07) — but as a **trailing** column after `campaign_id`,
it lets the conversion-rate query narrow to one campaign's rows before
the aggregate has to touch them, which is a meaningfully different role
for the same low-cardinality column than the HR or Insurance case studies
gave `status`. There is no single "best" index here — the right design
depends entirely on which of the two query shapes runs more often, which
is a judgment call File 06 and File 07 both prepare you to make, but
can't make for you.

## Case Study: Supply Chain — Shipment Tracking by Warehouse and Delivery Window

**Requirement**: track shipments in transit, filtered by origin warehouse
and expected delivery window.

```sql
SELECT * FROM shipments
WHERE origin_warehouse_id = ?
  AND expected_delivery BETWEEN ? AND ?;
```

**Decision**: `INDEX(origin_warehouse_id, expected_delivery)`.

This is deliberately **not** presented as a distinct lesson: it's the
identical equality-then-range composite pattern as the e-commerce shipment
case and the manufacturing supplier-delivery case above. Supply chain
tracking, warehouse logistics, and e-commerce fulfillment are, from an
indexing standpoint, the same problem wearing different industry labels —
recognizing when two "different" business domains actually pose the same
engineering problem is as valuable a skill as knowing the index types
themselves.

## Summary

Ten industries, but not ten different lessons repeated with new nouns:
each case study above was chosen specifically because it introduces one
concept this file hadn't yet shown in a business-grounded way — sliding
time windows (banking), booking-conflict detection (healthcare),
append-only scan logs (manufacturing), dual-range queries with no clean
composite solution (retail), a rare value inside a low-selectivity column
(insurance), spatial queries (ride-sharing), tenant-scoped security-as-
performance (SaaS), and role-dependent column placement for the same
low-cardinality column (marketing) — while the final supply-chain case
study is included specifically to demonstrate recognizing a *repeated*
pattern rather than inventing a new one where none exists.

## Practice

See [12_PRACTICE_PROBLEMS.md](12_PRACTICE_PROBLEMS.md), Case Studies
section.

## Further Reading

See [resources/documentation.md](resources/documentation.md).
