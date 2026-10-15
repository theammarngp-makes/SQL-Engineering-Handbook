[← Level 8](../09_INTERVIEWER_QUESTIONS/QUESTION_BANK.md) · [Module Home](../README.md) · Level 9 (of 0–9)

# Level 9 — SQL System Design

Pilot set: 6 of ~30 target questions. No single query is the deliverable
here — the candidate designs schema, indexes, and query strategy for an
end-to-end need, then defends the tradeoffs.

---

## Q045 — Design a Reporting Database for a Growing Company

**Difficulty:** ⚫ Staff/Production
**Category:** System Design
**Type:** I — Design

### Scenario
A company's HR system (`employes`/`departments`/`locations`, this
handbook's shared schema) currently serves both transactional writes
(HR staff editing records) AND analytical reporting (headcount
dashboards, compliance reports) directly against the same tables. As
company size grows, dashboard queries are starting to compete with and
slow down transactional writes.

### Candidate Task
Design an approach. Cover schema, indexing, and query strategy — not just
"add a read replica" as a one-line answer.

### What a Strong Answer Covers
- **Read replica** as the first, simplest lever — offload reporting reads
  to a replica, isolating transactional write performance from reporting
  read load, with an explicit discussion of replication lag tradeoffs
  (reports may be seconds/minutes stale)
- **Separate reporting schema/warehouse** as the next step if replica
  read load alone doesn't solve it — a denormalized, purpose-built
  reporting schema (star schema: `fact_headcount_snapshot` with
  `dimension_department`, `dimension_location`) that's populated via a
  scheduled ETL/ELT job rather than queried live against the
  transactional schema at all
- **Indexing strategy differs by workload**: the transactional schema
  needs indexes supporting point lookups and small updates; the reporting
  schema needs indexes (or columnar storage) supporting large aggregate
  scans — conflating these into one schema with one indexing strategy is
  itself part of the original problem
- Explicitly naming the tradeoff: a separate reporting store trades query
  performance and write-path isolation for **data freshness** (reports
  are as stale as the last ETL run) and **operational complexity** (a new
  pipeline to build and maintain)

### Weak Answer
"Just add more indexes to the existing tables" — this doesn't address the
fundamental read/write workload conflict and can make transactional
writes *slower* (more indexes to maintain per write, Module 16).

### Interviewer Follow-Up
"How would you decide between a read replica alone vs. a full separate
reporting schema? What signal would tell you which is sufficient?"

---

## Q046 — Design a Subscription Revenue Model

**Difficulty:** ⚫ Staff/Production
**Category:** System Design, SaaS
**Type:** I — Design

### Scenario
Design the schema for a subscription billing system that needs to
support: prorated upgrades/downgrades mid-cycle, accurate MRR reporting
(Q034), and historical "what did this customer's plan look like on any
given past date" queries for support/audit purposes.

### Candidate Task
Propose a schema and explain your key modeling decisions.

### What a Strong Answer Covers
- **Event-sourced subscription history**, not a single mutable
  "current plan" row: a `subscription_events` table (customer_id,
  event_type, effective_date, plan_id, mrr_delta) where every plan
  change is a new row, never an update — this is what makes "what did
  their plan look like on date X" answerable at all, and is exactly the
  model Q034 assumed
- A separate, **current-state materialized view or table** derived from
  the event log for fast "what is this customer's plan right now"
  lookups — since replaying the full event history for every such
  lookup would be needlessly expensive at scale
- **Explicit handling of proration**: a mid-cycle upgrade needs its own
  event with a correctly computed partial-period `mrr_delta` — a design
  that only stores start-of-cycle plan values can't represent this
  accurately
- A senior answer flags the tension between event-sourcing's audit/
  historical benefits and its query complexity for "current state"
  questions, and proposes the derived current-state table specifically to
  resolve that tension rather than picking one modeling style and living
  with its downside everywhere

### Interviewer Follow-Up
"How would you keep the derived 'current state' table consistent with
the event log as changes happen — synchronously in the same transaction,
or asynchronously?" (Tests awareness that this is itself a real
consistency-vs-complexity tradeoff, connecting back to Module 17's
transaction design content.)

---

## Q047 — Design a Fraud Analytics Query System

**Difficulty:** ⚫ Staff/Production
**Category:** System Design, Fintech
**Type:** I — Design

### Scenario
Design the data access pattern for a fraud detection system that needs
to answer "has this account shown suspicious velocity in the last 5
minutes" on every transaction, in under 50ms, against a transaction table
growing by millions of rows per day.

### Candidate Task
Propose an approach — a single query against the full transaction table
is very unlikely to meet this latency target at this scale; explain why,
and what you'd do instead.

### What a Strong Answer Covers
- Recognizes that querying the full historical `transactions` table for
  "last 5 minutes of activity" per request, even with a good index, adds
  unnecessary risk at this latency budget and scale — a **hot, narrow,
  purpose-built store** (a small rolling window table, or a cache/
  in-memory store keyed by account_id with a short TTL) is the
  appropriate design, not a bigger index on the main table
- The full `transactions` table remains the system of record for
  historical/audit queries and offline model training — this hot-path
  velocity check is a deliberately separate, narrower data path,
  not a replacement for it
- Discusses the consistency tradeoff explicitly: a slightly stale or
  eventually-consistent view of "recent activity" (if the hot store lags
  the transactional write even briefly) is very likely an acceptable
  tradeoff for this specific use case, given the latency requirement —
  this is a case where strict consistency (Module 17) is not the top
  priority

### Weak Answer
Proposing to just add an index on `(account_id, txn_timestamp)` to the
main table and calling the design complete, without addressing whether
that alone can realistically hit a 50ms target as the table grows to
billions of rows.

### Interviewer Follow-Up
"What happens to this design if the fraud check needs to also consider
patterns across MULTIPLE accounts (e.g., many small transactions from
different accounts to the same destination in a short window)? Does your
hot-store design still work?"

---

## Q048 — Design a High-Volume Event Analytics System

**Difficulty:** ⚫ Staff/Production
**Category:** System Design, Data Warehousing
**Type:** I — Design

### Scenario
Design a schema and query strategy for tracking and analyzing user
events (page views, clicks) at a volume of ~50 million events/day, with
requirements to support both real-time-ish dashboards (data within a few
minutes) and deep historical analysis (cohort retention over years).

### Candidate Task
Propose an approach covering ingestion, storage, and the two very
different query patterns.

### What a Strong Answer Covers
- Recognizes these are **two different workloads with different
  latency/depth tradeoffs**, not one query pattern: a real-time-ish path
  (streaming aggregation into pre-computed rollups, or a fast, narrower
  recent-events store) versus a historical analytical path (a columnar
  data warehouse table, partitioned by date, optimized for large scans
  and aggregation, not point lookups)
- **Partitioning by date** as a first-class design decision for the
  historical table — both for query performance (partition pruning,
  Module 16 concepts extended to date-range partitions) and for
  operational manageability (dropping/archiving old partitions instead of
  deleting rows from a monolithic table)
- Explicitly avoiding a design where every dashboard query scans the full
  raw event table — proposes pre-aggregated rollup tables (hourly/daily
  summaries) that dashboards query instead, with raw events retained
  separately for the deep historical/cohort use case
- Names the real cost: maintaining rollup tables is additional
  ETL/pipeline complexity, and rollups by definition lose some
  granularity — a senior answer states what's traded away, not just what's
  gained

### Weak Answer
"Just put it all in one big table and add indexes" — doesn't address the
volume (50M/day compounds fast) or the fundamentally different access
patterns between the two stated requirements.

### Interviewer Follow-Up
"A stakeholder wants a NEW cohort analysis dimension added six months
after this system launches. How well does your design accommodate that
without a full re-architecture — what did you build in intentionally to
allow for this?"

---

## Q079 — Design an Append-Only Audit Log for Compliance

**Difficulty:** ⚫ Staff/Production
**Category:** System Design, Compliance
**Type:** I — Design

### Scenario
HR needs a tamper-evident audit trail of every change to `employes`
(who changed what, when, old and new value) for compliance review,
without slowing down normal transactional writes.

### Candidate Task
Propose a schema and capture mechanism, and explain the tradeoffs.

### What a Strong Answer Covers
- An **append-only `employes_audit`** table
  (`audit_id, emp_id, changed_by, changed_at, column_name, old_value,
  new_value`) — rows are only ever inserted, never updated or deleted,
  which is itself part of what makes the trail trustworthy
- **Capture mechanism tradeoff**: a database trigger on `employes`
  guarantees every write is captured regardless of which application
  path made it (safer, but adds per-write overhead and couples audit
  logic to the database layer), versus application-level logging
  (faster, more flexible, but misses any write that bypasses the
  application — a direct DB console edit, for instance)
- **Tamper-evidence**, not just logging: for genuine compliance use, an
  append-only table alone doesn't prevent a privileged user from
  deleting audit rows — a stronger design adds a cryptographic hash
  chain (each row's hash includes the prior row's hash) so any deletion
  or edit breaks the chain and is detectable
- Explicit note that the audit table's write volume can exceed the
  base table's, since one `employes` update can produce multiple
  per-column audit rows — retention/archival policy needs its own plan

### Weak Answer
"Just add an `updated_at` timestamp column to `employes`" — this shows
only the most recent change, not who changed what, and provides no
historical trail at all.

### Interviewer Follow-Up
"A regulator asks for proof that a specific salary change on a specific
date wasn't altered after the fact. Does your design actually provide
that proof, or just a claim of one?"

---

## Q080 — Design Tenant Isolation for a Multi-Tenant SaaS Schema

**Difficulty:** ⚫ Staff/Production
**Category:** System Design, Multi-Tenancy
**Type:** I — Design

### Scenario
This HR system is being sold to multiple companies as SaaS. Each
tenant's `employes`/`departments`/`locations` data must never leak into
another tenant's queries, even under an application bug.

### Candidate Task
Compare at least two isolation strategies and recommend one with
justification.

### What a Strong Answer Covers
- **Shared schema with a `tenant_id` column** on every table, enforced
  at the database level via row-level security policies (not just
  "the application always adds `WHERE tenant_id = ?`") — cheapest to
  operate at scale, but a missed `tenant_id` filter anywhere, without
  RLS as a backstop, is a real cross-tenant leak risk
- **Schema-per-tenant** (same tables, one Postgres schema or MySQL
  database per tenant) — strong isolation with near-zero risk of a
  forgotten filter, at the cost of migrations needing to run N times
  and cross-tenant reporting becoming genuinely harder
- **Database-per-tenant** — strongest isolation and easiest
  data-residency/compliance story, but the most expensive to operate
  past a certain tenant count (connection overhead, migration
  orchestration, cost)
- The actual recommendation should be tied to stated constraints
  (tenant count, compliance requirements, team's operational maturity)
  rather than asserted as a universal best practice — there isn't one

### Weak Answer
Recommending shared-schema-with-`tenant_id` as strictly superior without
ever mentioning row-level security or acknowledging the leak risk of an
enforcement-only-in-application-code approach.

### Interviewer Follow-Up
"A large enterprise tenant now requires their data physically isolated
for a compliance certification. Does your original design accommodate
that for one tenant without re-architecting for all of them?"

---

[← Level 8](../09_INTERVIEWER_QUESTIONS/QUESTION_BANK.md) · [Module Home](../README.md)
