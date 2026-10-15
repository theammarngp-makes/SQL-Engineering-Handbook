[← Module Home](./README.md)

# Module 18 Final Validation Report

`Regenerated after the commit-readiness audit correction pass. Supersedes all prior versions of this file, including the earlier note that Module 17 did not yet exist in the live repository (Module 17, 17_TRANSACTIONS_AND_CONCURRENCY, has since been committed, and the numbering/placement conflict that note described no longer applies).`

## Status

**CONTENT: corrections applied — ready for the two remaining owner-side checks below.**
Two items cannot be completed from a standalone copy of this module and are
listed explicitly rather than claimed as done:

1. **Full-repository link validation** (see "Owner action required").
2. **Live MySQL execution of the SQL** (not performed).

## Question Statistics

| Metric | Result |
|---|---:|
| Total questions | 92 |
| Competency levels | 10 (numbered 0–9) |
| ID range | Q001–Q096 (4 gaps: Q082, Q083, Q084, Q087 — retired, never reused) |
| L0 Foundations | 10 |
| L1 Core SQL | 16 |
| L2 Analytical SQL | 17 |
| L3 Advanced SQL | 9 |
| L4 Database Engineering | 8 |
| L5 Real-World SQL | 8 |
| L6 Production Debugging | 6 |
| L7 Senior/Staff | 6 |
| L8 Interviewer/Hiring | 6 |
| L9 System Design | 6 |

## Corrections Made in This Pass

1. **Competency-level count (P0).** "9 levels" corrected to "10 levels,
   numbered 0–9" in `README.md`, `QUESTION_INDEX.md`, `FAQ.md`,
   `assets/diagrams/competency-pyramid.svg`, and `assets/images/hero.svg`
   (the last two also carried a stale "48 questions" figure, now 92).
   Folder names and numbering are unchanged. Per-file "Level N of 9"
   navigation headers now read "Level N (of 0–9)".
2. **Q094 explanation (P1).** Rewritten to separate logical processing
   order (`WHERE` runs before the `SELECT` alias exists) from MySQL's
   dialect-specific permission to reference a `SELECT`-list alias in
   `GROUP BY`/`HAVING`. The earlier wording implied `GROUP BY` runs after
   `SELECT`; that is removed.
3. **Q093 clarification.** The explanation now states that the
   `assignments` join is unnecessary for a department salary total, and
   shows the simplest fix (drop the join) alongside the pre-aggregation fix.
4. **Q096 boundary cases.** Added notes on single-employee departments,
   same-day hires (tie-breaker), NULL `hire_date`, and `DATEDIFF` argument
   order.
5. **Coverage claims made precise (P1).** README and
   `TAXONOMY_AND_FORMAT.md` no longer claim that every question has a
   full explanation and follow-up. Verified literal-heading counts across
   the 92 questions:

   | Field | Questions with the literal heading |
   |---|---:|
   | `### Explanation` | 59 |
   | `### Expected Answer` | 7 |
   | Either of the above | 66 |
   | `Interviewer Follow-Up` | 86 |
   | `Common Mistake` | 10 |
   | `Senior-Level Extension` | 12 |
   | `Related Modules` | 26 |

   Questions without a literal follow-up section: Q041–Q044, Q077, Q078.
   Questions using a different format instead of Explanation/Expected
   Answer (scenario-style Level 6, interviewer-facing Level 8, and some
   others) are intentional format variations, not padded to match.
6. **Validator improved.** `scripts/validate_questions.py` now separates
   links *within* the module (always checked, must pass) from links into
   other handbook modules (checked when sibling modules are present;
   otherwise reported as "not verifiable in a standalone copy" instead of
   as broken). This avoids false alarms without deleting legitimate
   cross-module links.
7. **Navigation fixes found while correcting headers.** Level 3 → Level 4
   → Level 5 → Level 6 previous/next links in the level files pointed to
   the wrong neighbours in several places; corrected.

## Validation Results (standalone copy)

| Check | Status | Basis |
|---|---|---|
| Duplicate IDs | PASS | 0 duplicates across 92 questions |
| Required metadata present | PASS | Validator: 92/92 complete |
| Retired IDs | PASS | Q082, Q083, Q084, Q087 intentionally absent |
| SVG well-formedness | PASS | All 3 SVG files parse as XML |
| Code-fence integrity | PASS | Even fence count in every question bank |
| Links within this module | PASS | No broken same-module links |
| Cross-module links | NOT VERIFIED HERE | 48 links point to other handbook modules (including `17_TRANSACTIONS_AND_CONCURRENCY`) that are absent from a standalone copy |
| Live MySQL execution | NOT PERFORMED | Structural validation only; no SQL in this bank has been executed against MySQL in this pass |

## Owner Action Required (not claimed as done)

Run from the **full handbook repository root**, where the sibling modules exist:

```
python3 18_SQL_INTERVIEW_QUESTIONS/scripts/validate_questions.py 18_SQL_INTERVIEW_QUESTIONS
```

Any reported cross-module link failure should be checked against the real
folder and file names (for example the Module 17 lesson filenames used in
Levels 4 and 6). Once that run is clean, this report may be updated to say
that cross-module links were verified against the full repository. Until
then, no such claim is made.

Optionally, run the SQL in Levels 0–3 (especially Q093–Q096) against a
MySQL 8 instance before declaring the bank SQL-execution-verified.

## Recommendation

Content and documentation are consistent at 92 questions across 10 levels.
Complete the full-repository link run above, then freeze Module 18.
