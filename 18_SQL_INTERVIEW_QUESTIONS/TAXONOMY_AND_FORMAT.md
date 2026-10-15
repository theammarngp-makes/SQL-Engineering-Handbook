# Question Taxonomy & Format Specification

This document defines the structure every question follows. Read before QUESTION_BANK files — it's the schema, not a question set.

## Build Status

Built in stages: **Architecture → Taxonomy → Pilot batch → Audit → Expansion → Deduplication → SQL validation → Link validation → Visuals → Final audit.** Current stage: **Final audit — complete; FROZEN at 92 questions** (up from the original 48-question breadth pilot, with the latest expansion pass focused on Levels 1-2, followed by a semantic-duplicate audit). IDs run `Q001`–`Q096` with 4 gaps (`Q082`, `Q083`, `Q084`, `Q087`) — retired during that audit and never reused, per this file's own ID policy below; see `QUESTION_INDEX.md`'s Retired IDs ledger. Most questions include an explanation and an interviewer follow-up, with format variations for scenario-style and interviewer-facing question types (see README's "Current Coverage" for exact counts); an explicit Common Mistake callout appears on a subset, not all — see README's "Current Coverage" section for the honest breakdown. Overall count toward the ~490 target is a long-term capacity figure, not a release gate — see README's coverage table.

## Competency Levels

| Level | Name | Approx. target | Tests |
|---|---|---|---|
| 0 | Foundations | ~40 | SELECT, WHERE, ORDER BY, LIMIT, aliases, NULL basics |
| 1 | Core SQL | ~60 | Aggregation, GROUP BY/HAVING, CASE, joins, subqueries, CTEs, set operators |
| 2 | Analytical SQL | ~80 | Window functions ([`07_Window_Functions`](../07_Window_Functions), [`08_WINDOW_BUSINESS_CASES`](../08_WINDOW_BUSINESS_CASES)), ranking, running totals, gaps/islands |
| 3 | Advanced SQL | ~70 | Recursive CTEs, correlated subqueries, relational division, reconciliation |
| 4 | Database Engineering | ~70 | Indexes, EXPLAIN, cardinality, transactions, locking, isolation |
| 5 | Real-World SQL | ~70 | Multi-domain realistic business scenarios requiring reasoning |
| 6 | Production Debugging | ~40 | Diagnosis, not syntax recall |
| 7 | Senior/Staff Engineering | ~40 | Schema tradeoffs, architecture, correctness under scale |
| 8 | Interviewer/Hiring | ~30 | Meta-questions: how to run and score an interview |
| 9 | SQL System Design | ~30 | Design a reporting/analytics system end to end |

## Difficulty Criteria

| Symbol | Level | Objective criteria |
|---|---|---|
| 🟢 | Beginner | Single concept, one table or simple join, no requirement ambiguity |
| 🟡 | Intermediate | Multiple concepts combined, moderate schema navigation, one correct interpretation |
| 🟠 | Advanced | Requires a non-obvious technique chosen correctly among several plausible ones |
| 🔴 | Expert | Multi-step reasoning, performance tradeoffs matter, more than one valid approach |
| ⚫ | Staff/Production | No single "correct query" — diagnosing an ambiguous, architectural problem |

## Question Types

| Type | What the candidate does |
|---|---|
| A — Write SQL | Produce a query solving a stated problem |
| B — Predict Output | Given SQL + data, state the exact result |
| C — Debug SQL | Given broken/wrong SQL, identify and fix |
| D — Optimize SQL | Given slow SQL, improve and justify |
| E — Explain SQL | Explain what SQL does and how it executes |
| F — Compare Approaches | Contrast two techniques |
| G — Data Reasoning | Diagnose why a reported number is wrong |
| H — Execution Plan | Interpret EXPLAIN output |
| I — Design | Design a schema or query strategy |
| J — Production Incident | Diagnose a described incident from symptoms |

## Per-Question Format

```markdown
## Q### — Short Descriptive Title

**Difficulty:** 🟡 Intermediate
**Category:** Window Functions
**Type:** A — Write SQL
**Skills Tested:** aggregation, JOIN, window functions
**Related Modules:** [`07_Window_Functions`](../07_Window_Functions)

### Scenario / Schema / Problem / Candidate Task
### Expected SQL
### Explanation
### Alternative Solution (if meaningful)
### Common Mistake / Why It Fails
### Interviewer Follow-Up
### Senior-Level Extension
### Performance Consideration
```

Not every field is populated for every question — an omitted field beats a padded one.

## Level 8 Format Exception

Level 8 (Interviewer/Hiring) questions use a different template than the
standard per-question format above — they're written FOR interviewers,
not as candidate-facing difficulty-rated problems. No Difficulty,
Category, or Type field; instead: **What it tests**, **Expected
competency**, **Good answer**, **Weak answer**, **Red flags**,
**Follow-up**. `scripts/validate_questions.py` accounts for this
exception explicitly rather than flagging it as missing metadata.

## Dataset Policy

Questions reuse the handbook's shared `employes`/`departments`/`locations` schema wherever the scenario allows. Where a question genuinely needs a different domain, the schema is defined inline in that question rather than introducing a large parallel dataset.

## Question ID Convention

`Q###` — zero-padded, sequential, assigned once, never reused even if retired.

## Deduplication Policy

Before adding a question, check `QUESTION_INDEX.md` for the same SQL pattern with renamed tables, the same scenario at the same difficulty, or the same concept already tested. A near-duplicate is only added if it tests a genuinely different skill.
