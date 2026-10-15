# Interviewer Guide

How to run an interview using this bank — a methodology, not a question list.

## Before You Start
- Pick questions from `QUESTION_INDEX.md` matched to role and level — see `PRACTICE_TRACKS.md`.
- Read each question's full entry beforehand, including "Common Mistake" and "Interviewer Follow-Up" — the follow-up is where you learn the most.
- Decide time budget per question before starting.

## Running a Session
1. **State the scenario, then stop talking.** How a candidate clarifies an underspecified problem is itself signal.
2. **Let them ask clarifying questions.** Reward the instinct to check nullability/edge cases before writing SQL.
3. **Use the Interviewer Follow-Up when they finish.** This is where shallow-but-correct and deep understanding become distinguishable.
4. **For Debug/Optimize/Incident questions, watch the process, not just the answer.** Guessing "add an index" immediately, without asking for EXPLAIN first, is a weaker signal than asking for more information first.

## Probing Technique
- If they give the "Common Mistake" answer, ask them to predict what the query actually returns rather than just saying "that's wrong."
- If solved quickly, move to the Senior-Level Extension instead of a new question — depth on one topic tells you more than breadth across shallow ones.
- Silence after asking is normal; resist filling it.

## Scoring
Use `SCORING_RUBRIC.md`'s eight dimensions per question, not one pass/fail. A candidate can score well on correctness and poorly on performance awareness on the SAME question.

## Red Flags
- Cannot explain why their own query works, at any level
- Every performance question answered "add an index" regardless of what EXPLAIN shows
- No tradeoff articulated on any Level 4+ question
- Cannot continue after one wrong answer

## Strong Signals
- Clarifying question before writing SQL when genuinely ambiguous
- Proposes verifying a hypothesis before committing to a fix
- Articulates a real tradeoff unprompted on Level 4+ questions
- Recovers gracefully from an incorrect first attempt

## Avoiding Unfair Questions
- Don't require memorized exact syntax under time pressure — open reference material is fair; reasoning is what's tested
- Credit valid alternative approaches not listed in "Alternative Solution"
- Calibrate difficulty to the role — Level 0/1 is the appropriate bar for many roles, not "too easy to ask"

## Evaluating Reasoning, Not Memorization
The biggest failure mode: rewarding memorized LeetCode-style patterns without checking if the candidate can explain WHY they work. Every "Explanation" field exists so you can ask "why" as a follow-up to any correct answer.
