# 🎯 Interview Resources

*Part of the [Resources Library](README.md) — [SQL Engineering Handbook](../README.md)*

This is the file [`README.md`](README.md#interview-preparation-roadmap) points to for interview prep. It's structured as a staged plan, not a flat link list — a SQL interview at each level tests something specific, and the plan below is built around that, not around "here are 40 links, good luck."

---

## Table of Contents

- [Interview Roadmap](#interview-roadmap)
- [Interviews by Level](#interviews-by-level)
- [System Design](#system-design)
- [Behavioral Preparation](#behavioral-preparation)
- [Platforms](#platforms)
- [SQL Cheat Sheets](#sql-cheat-sheets)
- [Business Case Studies](#business-case-studies)
- [Common Mistakes](#common-mistakes)
- [Practice Plans](#practice-plans)

---

## Interview Roadmap

Four stages, each building on the last:

1. **Syntax fluency** — write correct joins, aggregations, and subqueries without hesitation, on a shared screen, while talking.
2. **Pattern recognition** — recognize a "running total," "gaps and islands," or "top-N per group" problem within the first 30 seconds of reading it.
3. **Communication** — narrate your approach *before* writing the query, not after. Interviewers are grading the reasoning as much as the SQL.
4. **Business framing** — connect the query back to the business question it's answering, the way every module in this Handbook is written.

Pair this file with this repo's own [`17_SQL_INTERVIEW_QUESTIONS`](../17_SQL_INTERVIEW_QUESTIONS/) module and [`exercises/interview`](../exercises/interview/) directory — those give you Handbook-schema practice; this file gives you the platforms and plan to go wider.

## Interviews by Level

| Level | What Gets Tested | Prepare With |
|---|---|---|
| **Beginner** | `SELECT`, `WHERE`, basic joins, `GROUP BY`/`HAVING` — correctness and syntax fluency | `01_FUNDAMENTALS`–`03_JOINS`, Coding Platforms below |
| **Intermediate** | CTEs, window functions, subqueries, `CASE WHEN` logic, explaining your own query out loud | `04_CASE_WHEN`–`09_DATE_FUNCTIONS`, Practice Websites below |
| **Senior SQL** | Query optimization reasoning, index trade-offs, schema critique, defending design decisions | `15_INDEXES`, `16_QUERY_OPTIMIZATION`, `books.md` → Query Optimization |
| **Analytics Engineer** | Data modeling (star schema), metric definitions, testing philosophy, dbt-style thinking | `18_SQL_BUSINESS_CASE_STUDIES`, `books.md` → Data Warehousing, `documentation.md` → dbt |
| **Data Engineer** | Distributed query behavior, partitioning, pipeline-adjacent SQL, platform-specific dialects | `13_SET_OPERATORS`–`16_QUERY_OPTIMIZATION`, `documentation.md` → Cloud Data Warehouses |
| **FAANG-style** | All of the above, under tighter time pressure, often with an unfamiliar schema handed to you cold | Full roadmap, then timed practice on Mock Interview Platforms below |

## System Design

SQL interviews at the Senior and Data Engineer level increasingly fold in system-design questions — "how would you shard this table," "would you denormalize here." This isn't a separate skill from SQL; it's SQL judgment applied at a larger scale.

- Review `youtube.md` → **ByteByteGo** for how database choices fit into a larger system design answer.
- Review `books.md` → *Designing Data-Intensive Applications* for the reasoning behind partitioning and replication trade-offs you'll be asked to defend.
- Practice narrating trade-offs out loud — "I'd denormalize here because reads outnumber writes 100:1" is a stronger answer than a diagram alone.

## Behavioral Preparation

SQL interviews aren't purely technical — expect at least one "tell me about a time" question, usually about a data quality problem you found or a decision you had to defend.

- Prepare 2–3 stories using the STAR structure (Situation, Task, Action, Result), pulled from real project work — your own [`projects/`](../projects/) work in this repo is legitimate material to draw from.
- Practice the story that ends in "I was wrong, and here's what I did about it" — interviewers specifically listen for this one, and most candidates don't have it ready.

## Platforms

### Coding Platforms

| Field | Details |
|---|---|
| Title | LeetCode — Database category |
| Category | Coding Platforms |
| Difficulty | Beginner → Advanced (tiered) |
| Best For | Timed, graded SQL problems in the exact format many companies use for take-home or live-coding rounds |
| Why It Is Recommended | The most widely referenced platform for SQL interview practice — many companies' actual interview questions are directly inspired by problems here |
| Free or Paid | Free tier available; premium unlocks company-tagged questions |
| Who Should Read It | Anyone in active interview prep |
| Related SQL Handbook Modules | `17_SQL_INTERVIEW_QUESTIONS` |

| Field | Details |
|---|---|
| Title | HackerRank — SQL domain |
| Category | Coding Platforms |
| Difficulty | Beginner → Advanced |
| Best For | Structured, certificate-backed SQL practice tracks |
| Why It Is Recommended | Clear difficulty progression and official skill certificates that are recognized on LinkedIn and by some recruiters |
| Free or Paid | Free |
| Who Should Read It | Beginners wanting a structured track with a credential at the end |
| Related SQL Handbook Modules | `01_FUNDAMENTALS`–`09_DATE_FUNCTIONS` |

### Practice Websites

| Field | Details |
|---|---|
| Title | StrataScratch |
| Category | Practice Websites |
| Difficulty | Intermediate → Advanced |
| Best For | Real interview questions sourced from specific companies, with a data-science/analytics lean |
| Why It Is Recommended | Questions are tagged by the actual company that reportedly asked them, which is useful for targeted prep ahead of a specific interview |
| Free or Paid | Free tier available; premium unlocks full company-tagged question bank |
| Who Should Read It | Analytics/data science interview candidates |
| Related SQL Handbook Modules | `18_SQL_BUSINESS_CASE_STUDIES` |

| Field | Details |
|---|---|
| Title | DataLemur |
| Category | Practice Websites |
| Difficulty | Beginner → Advanced |
| Best For | SQL and product-analytics interview questions with a clean, distraction-free practice interface |
| Why It Is Recommended | Strong free tier with company-tagged questions and clear worked solutions, good for daily short practice sessions |
| Free or Paid | Free tier available; premium unlocks more questions |
| Who Should Read It | Anyone doing short, consistent daily practice sessions |
| Related SQL Handbook Modules | `17_SQL_INTERVIEW_QUESTIONS` |

### Mock Interview Platforms

| Field | Details |
|---|---|
| Title | Pramp |
| Category | Mock Interview Platforms |
| Difficulty | Intermediate → Advanced |
| Best For | Free, live, peer-to-peer mock interviews with real-time feedback |
| Why It Is Recommended | Practicing out loud, under time pressure, in front of another person is a different skill than solving a problem alone — this is the free way to get that specific rep in |
| Free or Paid | Free |
| Who Should Read It | Candidates within 2–4 weeks of a real interview |
| Related SQL Handbook Modules | `17_SQL_INTERVIEW_QUESTIONS` |

### Interview Question Collections

| Field | Details |
|---|---|
| Title | Interview Query |
| Category | Interview Question Collections |
| Difficulty | Intermediate → Advanced |
| Best For | Curated question banks combined with data-role-specific career content (not just SQL in isolation) |
| Why It Is Recommended | Covers the full interview loop context (SQL, product sense, statistics) rather than SQL as an isolated skill, useful once you're past pure syntax practice |
| Free or Paid | Free tier available; premium unlocks full content |
| Who Should Read It | Analytics/data science candidates preparing for a full interview loop, not just the SQL round |
| Related SQL Handbook Modules | `18_SQL_BUSINESS_CASE_STUDIES` |

## SQL Cheat Sheets

The primary cheat sheet is this repo's own [`20_SQL_CHEATSHEET`](../20_SQL_CHEATSHEET/) and the topic-specific quick references in [`cheatsheets/`](../cheatsheets/) (joins, CTEs, windows, dates, strings, aggregation) — built against the same schema you've already been practicing on, so nothing needs translating.

> [!TIP]
> Print or screenshot the cheat sheet the night before an interview. Don't try to memorize syntax you can otherwise look up in five seconds during actual work — memorize the *patterns* (see [Interviews by Level](#interviews-by-level)) instead.

## Business Case Studies

Interview questions increasingly wrap SQL inside a business scenario ("find customers at risk of churning") rather than asking for raw syntax. Practice with:

- This repo's [`18_SQL_BUSINESS_CASE_STUDIES`](../18_SQL_BUSINESS_CASE_STUDIES/) module
- The end-to-end portfolio projects in [`projects/`](../projects/) — particularly [`hr-analytics`](../projects/hr-analytics/) and [`ecommerce`](../projects/ecommerce/), which map closely to common interview scenario types
- `books.md` → *SQL Cookbook*, for pattern recognition across scenario types

## Common Mistakes

The same handful of mistakes account for most lost points at every level:

- **Confusing `WHERE` and `HAVING`** — filtering before aggregation vs. after it. Say out loud which one you're using and why.
- **Forgetting a `GROUP BY` column** — every non-aggregated column in the `SELECT` list needs to be in the `GROUP BY`, or the query is wrong even if it happens to run.
- **`NULL` comparison errors** — `= NULL` silently returns nothing; `IS NULL` is required. This trips up even experienced candidates under pressure.
- **Not narrating the approach first** — jumping straight to typing without stating the plan reads as guessing, even when the final query is correct.
- **Ignoring edge cases out loud** — a strong answer mentions duplicate rows, `NULL`s, or empty result sets even if the final query doesn't fully handle them; it signals awareness.
- **Overcomplicating with nested subqueries** when a CTE would be clearer — interviewers are also grading readability, not just correctness.

## Practice Plans

### Recommended Weekly Practice Plan

| Day | Focus |
|---|---|
| Mon–Wed | 1–2 problems/day from Coding Platforms, one level above comfortable |
| Thu | Review this repo's `18_SQL_BUSINESS_CASE_STUDIES` — one full case study |
| Fri | 1 mock interview (Pramp) or explain a solved problem out loud, recorded |
| Weekend | Rest, or light review of `20_SQL_CHEATSHEET` — no new material |

### 30-Day Interview Plan

**For:** candidates with solid fundamentals who need to sharpen interview-specific execution.

- **Week 1:** Beginner–Intermediate problems daily; drill `Common Mistakes` above until they stop happening.
- **Week 2:** Intermediate–Advanced problems; start narrating solutions out loud before typing.
- **Week 3:** Company-tagged questions on StrataScratch/DataLemur if a specific employer is known; 2 mock interviews.
- **Week 4:** Timed full-length practice sessions; behavioral story prep; final cheat-sheet review.

### 60-Day Interview Plan

**For:** candidates who need to build from Intermediate to Senior-level SQL judgment, not just execute faster.

- **Weeks 1–2:** Complete Intermediate Roadmap in [`README.md`](README.md#intermediate-roadmap) if not already solid.
- **Weeks 3–4:** `16_QUERY_OPTIMIZATION` + `books.md` → Query Optimization category; start explaining index trade-offs out loud.
- **Weeks 5–6:** Follow the 30-Day Interview Plan above, compressed slightly, now with optimization reasoning folded in.
- **Weeks 7–8 (overlap intentional):** Heavy mock-interview cadence — 2–3/week — plus behavioral prep.

### 90-Day Interview Plan

**For:** candidates starting from the Beginner Roadmap and targeting a Senior or Analytics Engineer role.

- **Weeks 1–4:** Beginner Roadmap in full — see [`README.md`](README.md#beginner-roadmap).
- **Weeks 5–8:** Intermediate Roadmap in full.
- **Weeks 9–11:** Advanced Roadmap, focused on `15_INDEXES` and `16_QUERY_OPTIMIZATION`.
- **Weeks 12–13:** Compressed 30-Day Interview Plan above, with 3+ mock interviews and full behavioral prep.

---

*This closes out the core six files. Second wave next: `newsletters.md`, `courses.md`, `datasets.md`, `playgrounds.md`, `certifications.md`, `communities.md`, `awesome-tools.md`. Back to [Resources Library](README.md).*
