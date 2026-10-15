# Module 18 — SQL Interview Questions

![Module 18 Banner](./assets/images/hero.svg)

`Status: 92 questions across 10 levels (0–9)` · `License: MIT`

## What This Module Is

A structured SQL assessment system — not a list of trivia. Built for two
audiences at once: people preparing for SQL interviews, and people running
them. Every question tests whether someone can *apply* SQL engineering
judgment, not whether they've memorized syntax.

This module does **not** re-teach SQL. It assumes and cross-links to the
handbook's core curriculum ([`01_Fundamentals`](../01_Fundamentals)
through [`17_TRANSACTIONS_AND_CONCURRENCY`](../17_TRANSACTIONS_AND_CONCURRENCY))
— if a question's underlying concept is unfamiliar, follow its "Related
Modules" link and learn it there.

## Current Coverage

**92 questions, built across all 10 competency levels (numbered 0–9).**
Most questions include an explanation (a literal `### Explanation` or
`### Expected Answer` section on 66 of 92) and an interviewer follow-up
(a literal `### Interviewer Follow-Up` section on 86 of 92). Format varies
by question type: scenario-style and interviewer-facing questions
(for example Levels 6 and 8) use their own section structure instead of
those exact headings, and Q041–Q044, Q077, and Q078 have no separate
follow-up section. Optional fields are omitted where they would add
little value, not padded in for uniformity. An explicit
`### Common Mistake` callout (or its Level-8 equivalent, `Weak Answer`)
appears on a minority of questions (about 10 of 92 carry the literal heading); on the rest, the common-mistake
framing is folded directly into the explanation prose rather than
broken out as its own section — retrofitting a dedicated section onto
every question is a real coverage gap, not yet done, tracked in
`AUDIT_REPORT.md` rather than silently claimed here. A named
"senior-level extension" is rare (a handful of questions), not the
majority — the Level 7–9 questions function as that extension by
design (harder variants of the same skills), rather than each L0–L6
question carrying its own bolt-on senior section. This is the third
expansion pass beyond the original 48-question breadth pilot, targeted
specifically at Levels 1-2 (the largest remaining gap to the ~490
target) — no new levels were added.

| Level | Built | Target |
|---|---|---|
| 0 — Foundations | 10 | ~40 |
| 1 — Core SQL | 16 | ~60 |
| 2 — Analytical SQL | 17 | ~80 |
| 3 — Advanced SQL | 9 | ~70 |
| 4 — Database Engineering | 8 | ~70 |
| 5 — Real-World SQL | 8 | ~70 |
| 6 — Production Debugging | 6 | ~40 |
| 7 — Senior/Staff Engineering | 6 | ~40 |
| 8 — Interviewer/Hiring | 6 | ~30 |
| 9 — SQL System Design | 6 | ~30 |
| **Total** | **92** | **~490** |

## Who Should Use This

- **Candidates** — work through `PRACTICE_TRACKS.md`'s pre-built tracks
- **Interviewers** — `INTERVIEWER_GUIDE.md` covers methodology, not just a question list
- **Hiring managers** — `SCORING_RUBRIC.md`'s eight-dimension model
- **Engineers** self-assessing — see `FAQ.md`'s guidance on honest self-scoring

## How the Question Bank Is Organized

See [`TAXONOMY_AND_FORMAT.md`](./TAXONOMY_AND_FORMAT.md) for the full
schema. In short: **10 competency levels, numbered 0–9** (each assuming the ones below
it), **5 difficulty ratings** (🟢🟡🟠🔴⚫) assigned by objective criteria,
and **10 question types** (Write SQL, Predict Output, Debug, Optimize,
Explain, Compare, Data Reasoning, Execution Plan, Design, Production
Incident).

## Navigation

| File | Purpose |
|---|---|
| [`TAXONOMY_AND_FORMAT.md`](./TAXONOMY_AND_FORMAT.md) | The schema — read this first |
| [`QUESTION_INDEX.md`](./QUESTION_INDEX.md) | Every question, filterable by level/difficulty/type |
| [`INTERVIEWER_GUIDE.md`](./INTERVIEWER_GUIDE.md) | How to actually run an interview with this bank |
| [`SCORING_RUBRIC.md`](./SCORING_RUBRIC.md) | Eight-dimension competency scoring model |
| [`INTERVIEW_CHEATSHEET.md`](./INTERVIEW_CHEATSHEET.md) | Compact recall reference |
| [`PRACTICE_TRACKS.md`](./PRACTICE_TRACKS.md) | Pre-built question sequences by role/length |
| [`GLOSSARY.md`](./GLOSSARY.md) | Terms used throughout, linked to full explanations |
| [`FAQ.md`](./FAQ.md) | Practical usage questions |
| [`scripts/validate_questions.py`](./scripts/validate_questions.py) | Structural validation |

Level folders (`01_FOUNDATIONS/` ... `10_SQL_SYSTEM_DESIGN/`) each contain
a `QUESTION_BANK.md` with that level's questions.

## Diagram Gallery

| Diagram | Shows |
|---|---|
| [`competency-pyramid.svg`](./assets/diagrams/competency-pyramid.svg) | All 10 levels (L0–L9), all built |
| [`interview-flow.svg`](./assets/diagrams/interview-flow.svg) | The assessment workflow, track selection to scoring |

## Dataset Approach

Questions reuse the handbook's shared `employes`/`departments`/
`locations` schema wherever the scenario allows. Level 5 (Real-World)
and Level 9 (System Design) questions define small inline schemas for
their specific domain (e-commerce, fintech, SaaS, healthcare, logistics)
rather than introducing a large parallel dataset.

## Related Modules

About a third of questions (26 of 92) carry an explicit `Related
Modules` link to the specific curriculum lesson they draw on — used
where one single lesson is genuinely the right target. The rest don't
lack a connection so much as lack one clean link: window-function
mechanics in Level 2 are mostly self-contained, and the scenario-driven
Level 5/8/9 questions typically span several lessons at once rather
than pointing at one. Level 4+ leans heavily on
[`16_QUERY_OPTIMIZATION`](../16_QUERY_OPTIMIZATION) and
[`17_TRANSACTIONS_AND_CONCURRENCY`](../17_TRANSACTIONS_AND_CONCURRENCY)
even where a question doesn't carry an explicit per-question link —
this module tests whether you can *apply* what those teach.

## Validation

Run `python3 scripts/validate_questions.py .` from this module's root.
Checks duplicate IDs, missing required fields, and broken relative links.
See the script's docstring for documented limitations.

## Contribution

Follow `TAXONOMY_AND_FORMAT.md`'s format and deduplication policy, assign
the next sequential `Q###` ID, and run the validation script before
submitting.
