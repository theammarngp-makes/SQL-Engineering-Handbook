[← Level 5](../06_REAL_WORLD_SQL/QUESTION_BANK.md) · [Module Home](../README.md) · Level 6 (of 0–9)

# Level 6 — Production Debugging

Pilot set: 6 of ~40 target questions. Every question is Type J (Production Incident) or Type G (Data Reasoning) — diagnosis, not syntax recall.

---

## Q022 — "Revenue Numbers Disagree Between Two Reports"

**Difficulty:** 🔴 Expert
**Category:** Data Reasoning
**Type:** G — Data Reasoning

### Scenario
Finance's monthly revenue report and the product dashboard show different totals for the same month, same underlying `orders` table.

### Strong Answer Covers
1. Do both filter `order_status` identically (refunded/cancelled handling)?
2. Same date field? (`order_date` vs `payment_date` vs `fulfilled_date` diverge near month boundaries)
3. Timezone handling near midnight on the 1st/last day
4. Join fan-out inflating one side (line items vs orders, unhandled DISTINCT)
5. Is either report pointed at a stale materialized view / cache?

### Weak Answer
Jumping to "must be a bug" without a structured list of where these specifically diverge in real systems.

### Interviewer Follow-Up
"Which would you check FIRST, and why — highest probability, not just easiest?"

---

## Q023 — "Daily Pipeline Started Producing Duplicate Records"

**Difficulty:** ⚫ Staff/Production
**Category:** Data Quality
**Type:** J — Production Incident

### Scenario
A nightly ETL job ran cleanly for a year. Three days ago, downstream reports show duplicate employee rows.

### Strong Answer Covers
- What changed 3 days ago specifically (deploy, schema, upstream source) before touching pipeline code
- Is the load INSERT-only with no upsert/dedup logic, and did the SOURCE start containing genuine duplicates
- Was a retry mechanism added/changed — a non-idempotent retry re-inserts already-loaded rows
- Are "duplicate" rows byte-identical or differ in one field (points to a different cause)

### Weak Answer
Proposing a DISTINCT fix downstream without investigating why duplicates are produced upstream.

### Interviewer Follow-Up
"Your fix stops NEW duplicates. What about the ones already in the table for 3 days?"

---

## Q024 — "Query Became 20x Slower After Deployment"

**Difficulty:** 🔴 Expert
**Category:** Performance Regression
**Type:** J — Production Incident
**Related Modules:** [`16_QUERY_OPTIMIZATION`](../../16_QUERY_OPTIMIZATION)

### Scenario
A 200ms dashboard query takes 4+ seconds right after a deploy that only touched application code — no schema/query changes.

### Strong Answer Covers
1. Did the deploy change HOW the query is called (ORM version, parameter pattern triggering parameter sniffing) even with identical query text
2. Did the deploy coincide with, but not cause, a data volume change (e.g. a backfill)
3. Compare EXPLAIN ANALYZE before/after if a replica/rollback is available — confirm whether the PLAN changed, not just timing
4. Did connection pool settings change, causing queueing delay that looks like query slowness

### Interviewer Follow-Up
"The app code change turns out unrelated to this query entirely. What's your new leading hypothesis?"

---

## Q025 — "Index Exists but Isn't Being Used"

**Difficulty:** 🟠 Advanced
**Category:** Indexing
**Type:** H — Execution Plan
**Related Modules:** [`16_QUERY_OPTIMIZATION` Lesson 03](../../16_QUERY_OPTIMIZATION/03_SARGABILITY_AND_INDEX_USAGE.md)

### Scenario
An index on `employes(dept_id)` is confirmed to exist. EXPLAIN still shows a sequential scan for `WHERE dept_id = 4`.

### Strong Answer Covers
- Low selectivity: if dept 4 holds a large fraction of rows, a scan may genuinely be cheaper — not a bug
- Stale statistics mis-estimating selectivity either direction
- Type mismatch forcing implicit conversion
- Verify the exact index definition, not just that "an index" exists
- Table might be small enough that a scan is trivially cheap regardless

### Interviewer Follow-Up
"Which can you rule out fastest, and which needs EXPLAIN ANALYZE with real data to distinguish?"

---

## Q073 — "This Query Was Fast Last Month, Now It's Slow"

**Difficulty:** 🔴 Expert
**Category:** Data Reasoning
**Type:** G — Data Reasoning
**Related Modules:** [`16_QUERY_OPTIMIZATION`](../../16_QUERY_OPTIMIZATION)

### Scenario
A query against `employes` filtered on `dept_id` used an index seek and
ran in milliseconds for months. No code or index changed, but it now
runs a full table scan and takes seconds.

### Strong Answer Covers
1. Data growth/skew: the filtered value's row count may have crossed the
   optimizer's selectivity threshold for "index worth using" (see Q068)
2. Stale statistics: if the engine's stats haven't been refreshed after
   significant data change, the optimizer is planning against an
   outdated row-count estimate
3. Parameter sniffing: a cached plan built for one parameter value
   (highly selective) is being reused for a different, less-selective
   value
4. Index fragmentation or an index silently dropped/rebuilt differently
5. A concurrent long-running transaction holding locks, making the plan
   look slow when it's actually blocked, not scanning inefficiently

### Weak Answer
Immediately assuming "the index is broken" and rebuilding it without
first pulling the actual execution plan to see what changed.

### Interviewer Follow-Up
"What's the very first diagnostic command you'd run, before touching
anything?"

---

## Q074 — Reproducing an Intermittent Deadlock

**Difficulty:** 🔴 Expert
**Category:** Concurrency, Data Reasoning
**Type:** G — Data Reasoning
**Related Modules:** [`17_TRANSACTIONS_AND_CONCURRENCY` Lesson 04](../../17_TRANSACTIONS_AND_CONCURRENCY/04_DEADLOCKS.md)

### Scenario
Production logs show occasional deadlock errors on `employes` updates,
but the on-call engineer can't reproduce it by running the suspected
queries manually one after another.

### Strong Answer Covers
1. Deadlocks require genuine concurrency and opposite lock-acquisition
   order — running queries sequentially by hand can never trigger one;
   two sessions must actually interleave
2. Pull the deadlock graph from the engine's own logging (most engines
   log which two statements and lock resources were involved) rather
   than guessing from application code alone
3. Check whether two code paths acquire locks on the same tables in
   different orders (e.g. one updates `employes` then `departments`,
   another does `departments` then `employes`) — this ordering mismatch
   is the single most common root cause
4. Reproduce with two concurrent sessions deliberately synchronized
   (transaction A pauses mid-transaction while B runs, then A resumes)
   rather than hoping for a race

### Weak Answer
Adding a blanket retry-on-error wrapper without ever identifying the
actual lock-order conflict — this hides the symptom and leaves the
underlying design flaw in place for the next incident.

### Interviewer Follow-Up
"Once you've identified the two code paths with mismatched lock order,
what's the fix — and what's the tradeoff of a blanket retry-on-deadlock
approach versus actually fixing the ordering?"

---

[← Level 5](../06_REAL_WORLD_SQL/QUESTION_BANK.md) · [Module Home](../README.md)
