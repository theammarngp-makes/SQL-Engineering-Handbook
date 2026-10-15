[← Level 6](../07_PRODUCTION_DEBUGGING/QUESTION_BANK.md) · [Module Home](../README.md) · Level 7 (of 0–9)

# Level 7 — Senior / Staff SQL Engineering

Pilot set: 6 of ~40 target questions. These distinguish experienced
engineers from candidates who've only memorized syntax — no single
"correct query" exists for most of these; the answer is a tradeoff
analysis.

---

## Q037 — Schema Design Tradeoff: Wide Table vs. EAV

**Difficulty:** ⚫ Staff/Production
**Category:** Schema Design
**Type:** I — Design

### Scenario
Product wants to let customers store arbitrary custom fields on an
`employes` record (different companies using this HR system want
different custom attributes). Two proposals: add columns dynamically per
tenant, or an Entity-Attribute-Value (EAV) table
(`emp_id, attribute_name, attribute_value`).

### Candidate Task
Argue the tradeoffs; do not just pick one.

### Strong Answer Covers
- **Wide/dynamic-columns**: query performance stays normal (indexed
  columns, SARGable predicates), but schema migrations per tenant don't
  scale operationally, and cross-tenant queries become awkward
- **EAV**: schema flexibility is trivial (just insert new attribute rows),
  but queries needing multiple attributes together require multiple
  self-joins or pivots, indexing is far less effective (values stored as
  generic text/varchar, defeating typed comparisons and SARGability), and
  aggregate queries across attributes become significantly harder to
  write and optimize
- A senior answer names a **third option** as genuinely competitive: a
  JSON/JSONB column for custom attributes, which most modern engines
  (PostgreSQL, MySQL 8+) can index (partially) and query reasonably well
  — a middle ground between full rigidity and full EAV flexibility

### Weak Answer
Confidently recommending EAV or wide-columns as "the correct" approach
without acknowledging the real cost the other approach avoids.

### Interviewer Follow-Up
"Which would you actually recommend for THIS specific scenario (multi-
tenant custom fields), and what would make you reconsider that choice as
the product evolves?"

---

## Q038 — Query Review: Spotting an Unmaintainable Query

**Difficulty:** 🔴 Expert
**Category:** Query Architecture, Maintainability
**Type:** I — Design / Code Review

### Problem
You're reviewing a PR with this query embedded in application code:
```sql
SELECT * FROM employes e1, departments d1, locations l1, employes e2
WHERE e1.dept_id = d1.dept_id AND d1.location_id = l1.location_id
  AND e2.manager_id = e1.emp_id AND l1.country = 'India'
  AND e1.hire_date > '2020-01-01' OR e1.salary > 100000
ORDER BY 3, 1;
```

### Candidate Task
List every maintainability and correctness concern, not just style
nitpicks.

### Strong Answer Covers
- Implicit comma-joins instead of explicit `JOIN ... ON` — harder to
  verify join conditions are complete and correct, and easy to
  accidentally omit one (silent cartesian product risk, Module 16)
- `SELECT *` across a 4-table join — unclear what columns actually flow
  through, and any schema change silently changes output shape
- Ambiguous operator precedence: the un-parenthesized `AND ... OR`
  combination almost certainly doesn't mean what the author intended —
  `OR e1.salary > 100000` likely applies more broadly than intended due to
  `AND` binding tighter than `OR`
- `ORDER BY 3, 1` (positional ordering) — fragile against any column
  reordering in `SELECT *`, and unreadable without cross-referencing
  column position
- No table aliases readable as intent (e1/e2 for two different employee
  roles is fine, but combined with everything else, extremely hard to
  audit)

### Interviewer Follow-Up
"Rewrite this query to fix every issue you identified, preserving its
(most likely) intended logic."

---

## Q039 — Performance Tradeoff: Denormalization Decision

**Difficulty:** ⚫ Staff/Production
**Category:** Schema Design, Performance
**Type:** I — Design

### Scenario
A dashboard query joining `employes`, `departments`, and `locations`
three ways has become the single most expensive query in the system as
company headcount grew 50x. Someone proposes denormalizing: adding
`dept_name` and `location_city` directly onto `employes` to eliminate the
joins.

### Candidate Task
Evaluate this proposal.

### Strong Answer Covers
- Denormalization trades query-time join cost for write-time consistency
  maintenance cost — every department rename or location change now must
  update every affected `employes` row, or the denormalized copy silently
  drifts from the source of truth
- Whether this tradeoff is worth it depends on the actual read:write
  ratio for this data — a dashboard read heavily, department names
  changing rarely, likely favors denormalization; a system with frequent
  department restructuring would not
- A senior answer proposes verifying the ACTUAL bottleneck first (Module
  16's tuning workflow) — is this genuinely a join-cost problem, or a
  missing-index problem that denormalization would mask rather than fix?
  Jumping to denormalization without first confirming via `EXPLAIN` that
  the join itself (not a missing index) is the cost driver is a common,
  expensive mistake

### Weak Answer
Immediately agreeing to denormalize without questioning whether the
actual root cause has been diagnosed yet.

### Interviewer Follow-Up
"If you do decide to denormalize, how would you keep the denormalized
copy consistent with the source of truth over time?"

---

## Q040 — Data Contract: API Change Silently Breaks a Downstream Report

**Difficulty:** ⚫ Staff/Production
**Category:** Data Contracts, Technical Debt
**Type:** J — Production Incident

### Scenario
An upstream team changes an internal API's `employment_status` field from
a boolean (`active`/`inactive`) to a string enum (`active`, `on_leave`,
`terminated`) as part of a feature launch. A downstream headcount report
that filtered on `employment_status = TRUE` silently starts undercounting
active headcount (rows with the new enum values don't match the old
boolean-style filter).

### Candidate Task
Diagnose why this went undetected until finance flagged wrong numbers,
and propose both an immediate fix and a structural prevention.

### Strong Answer Covers
- **Immediate**: update the filter to match the new enum values
  correctly (`employment_status IN ('active', 'on_leave')` or similar,
  depending on the actual business definition of "active headcount" now
  that a third state exists)
- **Why it went undetected**: no data contract or schema validation
  existed between the upstream API and downstream consumers — a breaking
  change shipped without any automated signal to affected downstream
  queries
- **Structural prevention**: this is fundamentally an organizational/
  process gap, not a pure SQL problem — a senior answer names concrete
  mitigations: versioned data contracts with downstream consumer
  notification, automated data-quality checks that would have caught the
  metric suddenly changing shape, or the query defensively failing loudly
  on an unexpected enum value rather than silently excluding it

### Interviewer Follow-Up
"Design a lightweight automated check that would have caught this
specific class of bug before it reached finance's report."

---

## Q075 — Designing an Idempotent Batch Job

**Difficulty:** ⚫ Staff/Production
**Category:** Batch Processing, Idempotency
**Type:** I — Design

### Scenario
A nightly batch job inserts a `salary_history` snapshot row per
employee. If the job fails partway and is re-run, it must not produce
duplicate snapshot rows for employees already processed that run.

### Candidate Task
Design the job's SQL-level idempotency strategy, not just "add a retry".

### Strong Answer Covers
- A natural composite key (`emp_id`, `snapshot_date`) with a **unique
  constraint**, so a re-run's `INSERT` either upserts
  (`ON CONFLICT DO UPDATE` / `MERGE`) or safely no-ops
  (`ON CONFLICT DO NOTHING`) instead of duplicating
- Doing the whole batch's writes inside a single transaction where
  feasible, so a mid-run failure leaves zero partial rows rather than a
  half-completed snapshot needing manual cleanup
- If the batch must chunk (too large for one transaction), each chunk
  needs its own idempotency boundary — a checkpoint of "last completed
  chunk" so a re-run resumes rather than reprocessing from zero
- Explicitly distinguishing "safe to re-run in full" from "safe to
  resume from partial" — they require different design

### Weak Answer
"Just wrap it in try/catch and retry the whole job" — this doesn't
address duplicate rows if some inserts already succeeded before the
failure.

### Interviewer Follow-Up
"How does this design change if the snapshot needs to reflect a
computed aggregate over other tables that might themselves be updated
concurrently while the batch runs?"

---

## Q076 — Normalization vs. Denormalization for a Read-Heavy Service

**Difficulty:** ⚫ Staff/Production
**Category:** Schema Design
**Type:** I — Design

### Scenario
An HR dashboard reads employee name, department name, and city on
nearly every page load — currently a 3-table join every time. Someone
proposes denormalizing: storing `dept_name` and `city` directly on
`employes` to avoid the joins.

### Candidate Task
Evaluate the proposal; state under what conditions it's the right call.

### Strong Answer Covers
- Denormalization trades write-path complexity (every department rename
  or relocation now requires updating every affected `employes` row,
  or an explicit sync mechanism) for read-path simplicity and fewer
  joins
- Whether this tradeoff is worth it hinges on read:write ratio and
  actual measured join cost — a 3-table join on ~50 rows joined via
  indexed foreign keys is not inherently slow; denormalizing here
  without a measured bottleneck is solving a problem that may not exist
  yet
- A middle ground: a materialized view or a periodically-refreshed
  reporting table that's denormalized, while the transactional schema
  stays normalized — gets read simplicity without permanently coupling
  write-path integrity to keeping duplicated columns in sync
- Naming the actual failure mode of naive denormalization: department
  renamed, sync forgotten, dashboard now silently shows a stale name
  indefinitely

### Weak Answer
Denormalizing immediately because "joins are slow," without measuring
whether the join is actually the bottleneck at this data volume.

### Interviewer Follow-Up
"At what scale or access pattern would you actually recommend the
denormalized column, if not now?"

---

[← Level 6](../07_PRODUCTION_DEBUGGING/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 8 — Interviewer Questions](../09_INTERVIEWER_QUESTIONS/QUESTION_BANK.md)
