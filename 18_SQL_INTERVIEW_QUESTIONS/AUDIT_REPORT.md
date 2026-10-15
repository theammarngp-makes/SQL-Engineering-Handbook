[← Module Home](./README.md)

# Module 18 — Audit Report & Depth Overview

`Regenerated for the 92-question state, after the semantic-duplicate fix round. Supersedes the earlier version of this file, which was written against the intermediate 80-question state and understated the true count.`

---

## 1. Structural Integrity — ✅ Clean

`scripts/validate_questions.py` run against all 10 `QUESTION_BANK.md` files:

- **92 questions scanned, 0 duplicate IDs.**
- **All questions have required metadata** (Difficulty + Category + Type
  for Levels 0–7 and 9; Category + Type only for Level 8, by design).
- Code fences independently verified balanced (even count) in every
  file after every edit — this doesn't trip the ID/metadata checks but
  silently breaks rendering if missed.
- Link checker still flags the same ~45 sibling-module links
  (`00_Schema`, `16_QUERY_OPTIMIZATION`, `17_TRANSACTIONS_AND_CONCURRENCY`,
  etc.) as broken — expected, since this is a standalone module zip
  that doesn't contain the rest of the repo. Not a real defect.

## 2. Coverage vs. Target

| Level | Built | Target | % of target |
|---|---|---|---|
| 0 — Foundations | 10 | ~40 | 25% |
| 1 — Core SQL | 16 | ~60 | 27% |
| 2 — Analytical SQL | 17 | ~80 | 21% |
| 3 — Advanced SQL | 9 | ~70 | 13% |
| 4 — Database Engineering | 8 | ~70 | 11% |
| 5 — Real-World SQL | 8 | ~70 | 11% |
| 6 — Production Debugging | 6 | ~40 | 15% |
| 7 — Senior/Staff | 6 | ~40 | 15% |
| 8 — Interviewer/Hiring | 6 | ~30 | 20% |
| 9 — System Design | 6 | ~30 | 20% |
| **Total** | **92** | **~490** | **19%** |

Per standing project guidance: the ~490 figure is a long-term capacity
target, not a release gate. This bank is not being grown further toward
that number right now — see §5.

## 3. Semantic-Duplicate Audit (this round's main finding)

An external review compared the Q081–Q092 expansion against the
pre-existing question set and found **4 genuine near-duplicates**,
confirmed by direct inspection of both sides of each pair:

| Retired ID (was) | Overlapped with | Replacement (new ID) |
|---|---|---|
| Q082 ("UNION vs. UNION ALL") | Q008 "UNION vs. UNION ALL Correctness" | **Q093 — "Join Fan-Out Silently Inflates a SUM"** (grain/multiplication bug, verified against a hand-traced dataset) |
| Q083 ("EXISTS vs. IN with a Subquery") | Q007 "IN vs. EXISTS with NULLs" | **Q094 — "GROUP BY Alias vs. WHERE Alias"** (logical processing order, MySQL's alias-in-GROUP-BY extension) |
| Q084 ("CASE Inside an Aggregate for Conditional Counting") | Q010 "CASE Expression in Aggregation" | **Q095 — "NOT and the Law of Excluded Middle"** (`x OR NOT x` fails to be a tautology once `x` can be UNKNOWN — this question's own explanation was itself found and corrected for a factual error on a later pass; see §6) |
| Q087 ("LAG to Compute a Period-over-Period Change") | Q015 "LAG for Period-over-Period Comparison" | **Q096 — "LEAD to Find Days Until the Next Hire"** (a genuinely uncovered function — only `LAG` had been tested before) |

**Correction to this report's own history:** the fix originally applied
here kept the four replacements under their original Q-numbers (content
swapped in place), reasoning that same-session, never-externally-cited
IDs were low-risk to reuse. A subsequent review caught that this
directly contradicts `TAXONOMY_AND_FORMAT.md`'s own stated ID policy —
"assigned once, never reused even if retired" — with no stated
exception for same-session or pre-release content. Rather than weaken
the policy to match what had been done, the four questions were
properly retired (`Q082`, `Q083`, `Q084`, `Q087` — removed outright, not
left as stubs) and their replacement content was reassigned genuinely
new IDs: `Q093`, `Q094`, `Q095`, `Q096`. Net question count is
unaffected (still 92); only the ID range changed (now `Q001`–`Q096`
with 4 intentional gaps). `QUESTION_INDEX.md`'s "Retired IDs" section is
the authoritative record of this.

Two further items were reviewed and **kept, with wording fixes**:

- **Q086** ("GROUP BY with an Expression") stated flatly that "the whole
  table still needs scanning" for a `YEAR(hire_date)` grouped aggregate —
  an absolute claim inconsistent with the handbook's own optimizer-claim
  policy, since a functional index on `YEAR(hire_date)` (MySQL 8.0.13+)
  could change that. Reworded to state the general case correctly and
  point at `EXPLAIN` rather than asserting an absolute. Also switched
  the primary form from `EXTRACT(YEAR FROM ...)` to the more idiomatic
  MySQL `YEAR(...)`.
- **Q092** ("CUME_DIST...") used the word "percentile" loosely — several
  distinct statistical percentile definitions exist, and `CUME_DIST()`
  matches only one of them. Retitled and reworded to describe exactly
  what the function computes ("proportion of employees at or below")
  and to call out the terminology risk explicitly, rather than teaching
  a conflation.

One item was reviewed and **kept, with its logic independently
verified**: **Q091** ("Detecting Consecutive Salary Increases") was
hand-executed against a 7-row traced dataset (salaries
50k→55k→60k→60k→65k→70k→75k) to confirm the gaps-and-islands query
correctly identifies the 3-raise streak and correctly excludes the
earlier 2-raise streak. An explicit assumptions block was added to the
question covering: how the first row per employee is handled, how an
equal (non-increasing) salary breaks a streak without counting as a
decrease, and an unhandled edge case (multiple rows sharing one
`effective_date` needs an explicit tie-breaker in `ORDER BY`, which this
version doesn't provide).

Five items (Q081, Q085, Q088, Q089, Q090) were reviewed and kept
unchanged — each tests a distinct skill from anything else in the bank.

## 4. Dialect and Optimizer-Claim Audit (carried forward, still clean)

The MySQL-primary dialect audit and absolute-optimizer-claim audit from
the previous round remain valid — no new PostgreSQL-only syntax or
unlabeled absolute claims were introduced by this round's replacements
(all new SQL was checked for `EXTRACT(EPOCH`, `INTERVAL '...'`,
`DATE_TRUNC`, `Seq Scan`, and absolute-claim language before being
committed to the files).

## 5. Q095 (formerly Q084) Correctness Fix

A subsequent review found that this question's *own explanation*
contained a genuine logic error, not just a wording nit — the kind of
defect this audit exists to catch even in content that had already
passed a prior round. The original explanation claimed three-valued
logic "breaks the classical logic rule that `NOT (NOT x) = x`." That
claim is false: negation is self-consistent in SQL's three-valued
(Kleene) logic — `NOT (NOT UNKNOWN) = UNKNOWN`, which does equal the
original UNKNOWN, so double-negation elimination does not break. What
actually breaks is the **law of excluded middle**: `x OR NOT x` is not
guaranteed true once `x` can be UNKNOWN, because
`UNKNOWN OR UNKNOWN = UNKNOWN`, not TRUE. The question was rewritten
around this corrected, verified lesson and independently checked by
executing the specific example (`WHERE manager_id > 5 OR NOT
(manager_id > 5)` against a NULL `manager_id` row) — confirmed the row
is excluded, exactly as the corrected explanation states. The original
explanation's follow-up question, which asked whether De Morgan's law
would "predict" a certain behavior, was also removed: De Morgan's laws
do hold in three-valued logic, so that follow-up was built on the same
mistaken premise.

## 6. Net Assessment

**Module 18 is not broken and does not need a rebuild.** The 92-question
state is internally consistent: no duplicate IDs, no remaining semantic
duplicates identified by two independent review passes, no unlabeled
dialect leakage, one previously-absolute optimizer claim now correctly
qualified, one previously-loose statistical term now precisely worded,
one genuine logic error in a question's own explanation found and
corrected, and the ID-reuse policy violation from the first duplicate-fix
pass itself resolved (§3). `README.md`, `TAXONOMY_AND_FORMAT.md`, and
`QUESTION_INDEX.md` all agree on the count (92) and ID range
(`Q001`–`Q096`, 4 gaps) and this file now agrees with them too.

**Recommendation: freeze this module at 92 questions.** Per standing
project guidance, further growth toward ~490 should be driven by
learner feedback and identified coverage gaps once the exercise system
surfaces them — not by a schedule of "expand every session." The next
session's default should be Module 17 (Transactions & Concurrency),
not another Module 18 expansion pass.


## Addendum — Commit-Readiness Correction Pass

Applied after an external commit-readiness audit: competency count corrected
to 10 levels (0–9) everywhere; Q094 explanation corrected (alias resolution
vs. logical processing order); Q093/Q096 clarified; README/taxonomy coverage
claims made precise; validator now distinguishes in-module from cross-module
links; `FINAL_VALIDATION_REPORT.md` regenerated. Full-repository link
validation and live MySQL execution remain owner-side steps — see that report.
