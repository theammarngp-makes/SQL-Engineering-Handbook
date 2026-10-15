[← Level 7](../08_SENIOR_ENGINEERING/QUESTION_BANK.md) · [Module Home](../README.md) · Level 8 (of 0–9)

# Level 8 — Interviewer / Hiring Questions

Pilot set: 6 of ~30 target questions. These are written FOR interviewers
— each one states what it tests, what a good vs. weak answer looks like,
red flags, and a follow-up, rather than following the standard candidate
question format.

---

## Q041 — How to Select Questions for a Given Role

**What it tests:** whether an interviewer understands that difficulty
calibration is a design decision, not a fixed script.

**Expected competency:** ability to match question level to role
seniority and function (analyst vs. engineer vs. staff).

**Good answer:** starts from `PRACTICE_TRACKS.md`'s pre-built tracks,
then deliberately swaps in domain-relevant Level 5 questions matching the
company's actual industry, and adjusts difficulty based on how the
candidate performs on the first 2-3 questions rather than running a rigid
fixed script regardless of signal.

**Weak answer:** "I ask the same 5 questions to everyone regardless of
role" — this produces miscalibrated signal for both under- and
over-qualified candidates.

**Red flags:** an interviewer who can't articulate why a specific
question is included for a specific role, or who treats question
difficulty as interchangeable with question obscurity (picking the
question with the most unusual syntax rather than the one testing the
most relevant competency).

**Follow-up:** "A candidate is clearly underqualified for the role after
question 2 of a 5-question track. What do you do — finish the script
anyway, or adapt?"

---

## Q042 — Evaluating Reasoning vs. Memorization

**What it tests:** whether an interviewer can distinguish a candidate who
understands a pattern from one who has memorized it.

**Expected competency:** using follow-up questions to probe past a
correct-looking initial answer.

**Good answer:** for any correct answer, ask the candidate to explain the
underlying mechanism (not just restate the pattern), or introduce a
small variation to the problem and see if they can adapt their reasoning
rather than just reproducing memorized code.

**Weak answer:** accepting a syntactically correct query as sufficient
evidence of competency without any follow-up probing.

**Red flags:** an interviewer who can't tell the difference between "the
candidate solved this because they've seen this exact LeetCode problem
before" and "the candidate reasoned through this from first principles" —
both produce the same visible output, but only one predicts future job
performance on novel problems.

**Follow-up:** "A candidate solves a gaps-and-islands problem
(Q014-style) instantly, with no hesitation. How would you find out
whether they understand WHY the technique works, versus have memorized
the specific pattern?"

---

## Q043 — Scoring a Candidate Who Uses a Different-But-Valid Approach

**What it tests:** whether an interviewer's scoring is rigid (matching a
specific expected answer) or genuinely competency-based.

**Expected competency:** recognizing a correct, differently-shaped
solution and crediting it appropriately, per `SCORING_RUBRIC.md`.

**Good answer:** checks whether the alternative approach is logically
equivalent and correctly reasoned, and scores it on its own merits —
including asking the candidate to compare it to the "expected" approach
as a bonus follow-up, which itself tests deeper understanding (Type F
questions, `TAXONOMY_AND_FORMAT.md`).

**Weak answer:** marking a candidate down purely for not producing the
exact expected SQL, even when their version is correct and reasonably
performant.

**Red flags:** an interviewer who treats the "Expected SQL" field in a
question as the only acceptable answer, rather than as one reference
solution among possibly several valid ones.

**Follow-up:** "A candidate solves Q006 (department headcount) using a
correlated subquery with COUNT instead of the expected LEFT JOIN
approach, and it's correct. How do you score this, and what would you ask
next?"

---

## Q044 — Running a Fair 30-Minute Screen Under Time Pressure

**What it tests:** an interviewer's ability to extract maximum signal
under a tight, realistic time constraint without being unfair to the
candidate.

**Expected competency:** pacing, knowing when to move on vs. dig deeper,
and avoiding the common trap of spending 20 of 30 minutes on question 1.

**Good answer:** allocates rough time budgets per question in advance
(per `INTERVIEWER_GUIDE.md`), and is willing to move on from a
question the candidate is visibly stuck on rather than let it consume
the whole session — a stuck candidate on question 2 of 5 shouldn't cost
them the chance to show competency on questions 3-5.

**Weak answer:** no time budgeting at all, resulting in an interview that
either rushes through everything shallowly or gets stuck entirely on one
early question.

**Red flags:** an interviewer who treats "the candidate didn't finish
question 1" as equivalent to "the candidate failed the interview,"
without considering whether later questions might have shown stronger
signal.

**Follow-up:** "You're 15 minutes into a 30-minute screen and the
candidate is still working through question 1 of 3. What do you do?"

---

## Q077 — Calibrating Hints When a Candidate Is Stuck

**What it tests:** whether an interviewer can keep signal flowing
without accidentally solving the problem for the candidate.

**Expected competency:** giving graduated hints — smallest nudge first,
larger only if that doesn't unstick them — rather than jumping straight
to the answer or leaving them stuck too long to observe anything useful.

**Good answer:** starts with a clarifying question that redirects
attention ("what does this query return for a NULL manager_id row?"),
escalates to naming the relevant concept without giving the syntax
("think about what happens when you compare against NULL"), and only
gives the direct answer if the candidate is fully stuck and time is
running out — while noting internally that a hint was needed, since
that's real signal for the scorecard.

**Weak answer:** either staying silent through visible flailing (wastes
interview time without generating useful signal) or giving the full
answer immediately at the first sign of hesitation (destroys the
signal entirely — you learn nothing about their actual reasoning).

**Red flags:** an interviewer who treats "needed one hint" and "solved
it independently" as equivalent on the scorecard — the distinction is
exactly the point of giving graduated hints in the first place.

**Follow-up:** "How do you fairly compare two candidates when one
needed a hint to reach the same correct answer the other reached
independently?"

---

## Q078 — Evaluating Whiteboard SQL Without Running It

**What it tests:** whether an interviewer can assess correctness by
reading, not just by executing.

**Expected competency:** mentally tracing logical query-processing order
(FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY) against the
candidate's written SQL to catch bugs a real engine would also catch —
without needing to actually run it.

**Good answer:** reads the query in processing order rather than
left-to-right as written, checking join conditions for cardinality
issues (fan-out), aggregate/non-aggregate column mismatches, and NULL
handling at each stage — the same checklist used to build every
question in this bank's `Common Mistake` sections.

**Weak answer:** only checking that the SQL "looks plausible" or matches
a memorized correct-answer template, missing a subtle bug (e.g. a join
that silently duplicates rows before an aggregate) because the overall
shape looked right.

**Red flags:** an interviewer who can't explain *why* a piece of
whiteboard SQL is wrong beyond "that's not what I expected" — vague
rejection without a specific, teachable reason is a coaching failure,
not just an evaluation one.

**Follow-up:** "A candidate's query is syntactically correct but returns
subtly wrong results due to a join fan-out. Walk through how you'd
explain that to them afterward."

---

[← Level 7](../08_SENIOR_ENGINEERING/QUESTION_BANK.md) · [Module Home](../README.md) · Next: [Level 9 — SQL System Design](../10_SQL_SYSTEM_DESIGN/QUESTION_BANK.md)
