# AI-Assisted Query Tuning Workflow (Safe Copilot Usage)

## Introduction

An LLM can read an `EXPLAIN` plan, suggest an index, and rewrite a query in
seconds — and it can also confidently suggest an index that doesn't help,
invent an `EXPLAIN` line that doesn't exist in your engine's output, or
"optimize" a query into one that returns different results. This lesson is
not about whether to use AI assistance for query tuning — it's about the
specific, mandatory validation workflow that makes AI assistance safe to
use in a codebase this handbook expects to run in production. Every
technique here treats the model's output the way this handbook treats a junior
engineer's first draft: a starting hypothesis to verify, not a conclusion
to trust.

> **Schema note:** this lesson's SQL lab uses the handbook's shared
> `transactions` table (part of `00_Schema.sql`), the module's documented
> extension to the core `employes`/`departments`/`locations` schema.

## Learning Objectives

- Write prompts that get useful, engine-specific `EXPLAIN` analysis instead
  of generic, hallucination-prone advice
- Validate an AI-suggested index against this handbook's own SARGability
  and covering-index principles (Lesson 03) before creating it
- Verify an AI-suggested rewrite preserves result-set correctness, not just
  plan-shape improvement
- Recognize the specific, recurring red flags that indicate a hallucinated
  optimization
- Apply five ready-to-use prompt templates that build the validation step
  into the prompt itself

## Why This Exists

The failure mode this lesson addresses isn't "the AI gave a bad answer" —
it's "the AI gave a *plausible-sounding, syntactically valid, wrong*
answer, and it shipped because nobody validated it the way they'd validate
a human's suggestion." An LLM has no execution environment by default; it
is pattern-completing what a correct-looking answer resembles, not running
your query against your data. Every technique in this lesson exists to
close that specific gap.

## Safe Prompting Patterns for EXPLAIN Analysis

The single highest-leverage habit: **paste the actual `EXPLAIN` output**,
not a description of the problem. "My query is slow" produces generic
advice. A pasted plan with row-count estimates, join types, and index names
produces analysis the model can ground in specifics instead of guessing.

- **Always specify the engine and version.** "Optimize this query" invites
  generic ANSI SQL advice; "This is PostgreSQL 16, here is the `EXPLAIN
  (ANALYZE, BUFFERS)` output" scopes the model to syntax and planner
  behavior that actually exists in your environment.
- **Include the schema (`CREATE TABLE` + existing indexes), not just the
  query.** A model without the schema will invent plausible-sounding column
  names or suggest an index that duplicates one that already exists.
- **Ask for the model's reasoning before the fix**, not just the fix. A
  model asked to explain *why* a plan is slow, using the actual `EXPLAIN`
  numbers, produces output you can check against this handbook's own
  vocabulary (SARGability, cardinality misestimate, etc.) line by line. A
  model asked only for the fix skips the step where you could have caught
  a wrong premise.
- **Ask what could make the suggestion wrong.** Explicitly prompting for
  "what would make this index suggestion NOT help" or "what assumption are
  you making about data distribution" surfaces the model's own uncertainty
  instead of presenting a guess with false confidence — see Prompt Template
  4 below.

## Index Suggestion Validation

Never create an AI-suggested index directly. Run it through the same
checklist you'd apply to a human's suggestion, using Lesson 03
as the ground truth:

1. **Does the suggested index actually match the query's filter and sort
   columns, in the right order?** A model can suggest column order that
   looks reasonable but doesn't match the leftmost-prefix rule an engine
   actually uses.
2. **Does an index that already (partially) covers this already exist?**
   Ask the model directly, but verify yourself against the real schema — a
   model without full visibility into every existing index will not
   reliably catch a near-duplicate.
3. **What's the write-side cost?** A model asked only "will this index
   speed up my query" has no incentive to volunteer the insert/update
   penalty Lesson 03 treats as a mandatory tradeoff
   consideration — ask for it explicitly.
4. **Validate with `EXPLAIN` after creating the index in a non-production
   environment**, exactly as you would for a human-suggested index. The AI
   suggested it; the query planner decides whether it's used.

## Rewrite Verification Against the Performance Smells Catalog

Cross-check every AI-suggested rewrite against
`PERFORMANCE_SMELLS.md` (and this handbook's `COST_SMELLS.md`, Lesson 10) in
both directions:

- **Does the rewrite eliminate a smell** the original query had? Confirm
  it's the specific smell the model claims to have fixed, not a
  coincidentally different query shape that happens to look faster.
- **Does the rewrite introduce a new smell** the original didn't have? A
  model optimizing narrowly for the stated goal (e.g., "make this faster")
  can introduce a correctness or cost regression that wasn't in scope of
  what it was asked to check — a rewrite that eliminates a non-SARGable
  predicate by adding an uncorrelated subquery, for instance, can
  reintroduce this handbook's N+1-style anti-pattern at the SQL level.
- **Always diff the actual result set**, not just the plan. Run both the
  original and rewritten query against the same data and confirm identical
  output (row-for-row, including `NULL` handling and ordering where the
  query depends on it) before considering plan-shape improvement relevant
  at all. A faster query that returns different rows is not an
  optimization — it's a bug the model introduced with high confidence.

## Red Flags for Hallucinated Optimizations

| Red flag | Why it happens | What to do |
|---|---|---|
| A cited `EXPLAIN` field or plan-node name that doesn't exist in your engine/version | Models blend syntax and output formats across Postgres, MySQL, SQL Server, and older engine versions | Cross-check every cited field name against your actual `EXPLAIN` output before trusting the analysis built on it |
| A suggested index that the model claims will be used, stated with certainty | The model cannot run your query planner; it is predicting, not observing | Never treat a model's plan-usage claim as verified — only your own `EXPLAIN` run against the real schema and data volume confirms it |
| Specific performance numbers ("this will be 10x faster") with no measurement behind them | Precise-sounding numbers are a known confidence-inflation pattern separate from actual accuracy | Treat any unmeasured numeric claim as illustrative at best; benchmark it yourself (Lesson 11) before repeating the number anywhere |
| A rewrite that changes aggregation, `JOIN` type, or `NULL`-handling semantics while claiming "identical results" | Semantic-preservation is exactly the kind of subtle correctness property a model can get wrong while sounding confident | Always diff the actual result sets — see "Rewrite Verification" above; never accept a semantic-equivalence claim without checking it |
| Confident engine-specific syntax for a feature that doesn't exist in your engine or version | Training data blends across engines and versions without a reliable boundary | Check the suggested syntax against your engine's actual current documentation before running it anywhere near production |

## Five Copy-Paste Prompt Templates

**1. EXPLAIN plan analysis (grounded, not generic)**
```
I'm running [ENGINE + VERSION, e.g. "PostgreSQL 16"]. Here is my schema:
[PASTE CREATE TABLE + existing indexes]

Here is my query and its EXPLAIN (ANALYZE, BUFFERS) output:
[PASTE QUERY]
[PASTE EXPLAIN OUTPUT]

Walk through the plan node by node. For each node, tell me what it's doing
and whether the estimated vs. actual row counts suggest a cardinality
misestimate. Do not suggest a fix yet -- I want your diagnosis first.
```

**2. Index suggestion with mandatory tradeoff disclosure**
```
Given this schema and query [PASTE], suggest an index that would help.
For your suggestion, explicitly state:
1. The exact column order and why that order matters for this query
2. Whether an existing index already partially covers this
3. The write-side cost (INSERT/UPDATE/DELETE overhead) of adding it
4. One scenario where this index would NOT be chosen by the planner
```

**3. Rewrite with correctness-preservation proof**
```
Here is a query I want to optimize: [PASTE]

Propose a rewrite. Then, separately, write a verification query I can run
that proves the original and rewritten queries return identical result
sets (same rows, same order if order matters, same NULL handling) against
my actual data -- not just an argument for why they should be equivalent.
```

**4. Adversarial self-check ("what would make this wrong")**
```
You suggested [PASTE THE MODEL'S PRIOR SUGGESTION].

Before I implement this: what assumption about my data distribution,
cardinality, or engine version would make this suggestion NOT help, or
actively make performance worse? Be specific, not generic.
```

**5. Cross-check against a known smell catalog**
```
Here is a catalog of performance anti-patterns my team maintains:
[PASTE RELEVANT ENTRIES FROM PERFORMANCE_SMELLS.md / COST_SMELLS.md]

Here is a query and a proposed rewrite: [PASTE BOTH]

Does the rewrite eliminate any smell in this catalog? Does it introduce
any smell in this catalog that the original didn't have? Answer both
questions explicitly, referencing specific catalog entries.
```

## Mandatory Human Validation Steps

No AI-assisted tuning output reaches production without all of the
following, regardless of how confident the model's response sounded:

1. `EXPLAIN` re-run against the real schema, on a non-production
   environment, by a human — not accepted from the model's claim
2. Result-set diff confirming correctness preservation, for any rewrite
3. Cross-check against `PERFORMANCE_SMELLS.md` / `COST_SMELLS.md` in both
   directions (smell eliminated, no new smell introduced)
4. A benchmark run through Lesson 11's CI gate, or an equivalent manual
   benchmark, before merging — an AI-suggested fix is a hypothesis, and
   Lesson 11's entire premise is that hypotheses about performance get
   tested, not trusted
5. Sign-off from a human who understands *why* the change works, not just
   that the model said it would — this handbook's interview-insight
   pattern throughout every module exists precisely so an engineer can
   explain their own tuning decisions, and that standard doesn't relax
   because a model made the initial suggestion

## LLM Limitations Specific to Query Tuning

- **No access to your actual data distribution or statistics** unless you
  paste them. A model's index or rewrite suggestion is only as good as
  what you gave it — it cannot see skew, correlation between columns, or
  actual cardinality unless you provide `EXPLAIN ANALYZE` output or
  summary statistics directly.
- **No persistent memory of your schema across a long session** unless the
  full schema is in context for every relevant prompt — a model can
  contradict an earlier suggestion once the schema falls out of its
  effective context window, without flagging the contradiction.
- **Training data mixes engines, versions, and eras of best practice.** A
  suggestion that was correct for MySQL 5.7 may be actively wrong for
  MySQL 8.0's cost-based optimizer improvements, and the model may not
  reliably disambiguate unless the version is explicit in every prompt.
- **Confidence is not a correctness signal.** A model expresses the same
  fluent, certain tone whether it's citing a real, verified optimizer
  behavior or fabricating one — this is the single most important
  limitation to internalize, because it's the one that most directly
  defeats a reviewer's instinct to trust confident-sounding output.

## Engineering Notes

- Treat AI-assisted tuning as accelerating the *hypothesis generation*
  stage of Lesson 07's tuning workflow, not replacing the
  *measurement* stage. The workflow's discipline doesn't change; only the
  speed of generating the first draft does.
- Keep a short internal log of AI-suggested optimizations that turned out
  wrong on validation — this is genuinely useful team-level data for
  calibrating how much unverified trust to extend to future suggestions
  from the same tool, and it directly informs how tightly to scope future
  prompts using Template 4 above.

## MySQL / PostgreSQL / SQL Server Notes

- **PostgreSQL**: models are generally strongest on Postgres `EXPLAIN`
  terminology given its prevalence in training data, but still verify any
  cited planner behavior (e.g., specific costing constants) against your
  actual `postgresql.conf` settings, which vary by deployment.
- **MySQL/MariaDB**: watch specifically for suggestions that assume
  InnoDB's cost-based optimizer behavior from a MySQL 8.0+ context being
  applied to an actual 5.7 deployment, or vice versa — the two have
  meaningfully different optimizer capabilities.
- **SQL Server**: verify any suggested hint syntax (`OPTION`, query hints,
  index hints) against your actual SQL Server / Azure SQL version — hint
  availability and behavior has changed across versions, and a
  hallucinated hint can fail silently rather than erroring.

## Common Mistakes

- Pasting only the query, not the schema or `EXPLAIN` output, then trusting
  a suggestion that was necessarily generic given what it was given
- Creating an AI-suggested index directly in production without an
  `EXPLAIN` check confirming the planner actually uses it
- Accepting "this should be faster" as sufficient validation instead of an
  actual benchmark (Lesson 11)
- Treating a confident tone as a correctness signal, especially for
  specific numeric performance claims

## Anti-patterns

- Copy-pasting an AI-suggested rewrite directly into a PR without running
  it against real data first
- Using a single prompt-response pair as the entire validation process,
  with no adversarial follow-up (Prompt Template 4)
- Asking an AI tool to "just fix" a slow query with no schema or
  `EXPLAIN` context, then being surprised the fix doesn't work

## Edge Cases

- **A correct suggestion for the wrong reason**: a model can suggest an
  index that genuinely helps while citing an incorrect mechanism for why —
  validate the *outcome* (via `EXPLAIN`) independently of whether you find
  the model's stated reasoning convincing.
- **Iterative prompting drift**: across a long back-and-forth, a model can
  gradually lose track of an earlier constraint (e.g., "don't add new
  indexes, only rewrite the query") without flagging that it's no longer
  honoring it — re-state hard constraints explicitly in later prompts
  rather than assuming they persist.

## Troubleshooting Guidance

- An AI-suggested index doesn't get used by the planner after creation →
  don't re-prompt for a "better" index yet; first check `EXPLAIN` for the
  planner's actual cost comparison between the new index and its existing
  choice — the suggestion may be technically valid but genuinely not
  selective enough at your real data's cardinality.
- A rewrite "works" in testing but returns different results in production
  → check `NULL` handling and join-type changes first; this is the most
  common category of AI-introduced correctness regression per this
  module's "Red Flags" table.

## Scalability Considerations

AI-assisted tuning suggestions are generated without knowledge of how your
data will grow. A suggestion validated as correct and beneficial against
today's data volume still needs the same re-validation-over-time treatment
Lesson 11 applies to every other performance-relevant change — an
AI-suggested index that helped at 100K rows is not guaranteed to still be
the right index at 100M rows, and nothing about the AI-assisted origin of
that index makes it exempt from Lesson 11's CI gate or this handbook's ongoing
tuning workflow.

## Additional Dialect Notes (Oracle, SQLite, DuckDB)

- **Oracle**: model suggestions involving optimizer hints (`/*+ ... */`)
  are a particularly high-risk category to accept unverified — Oracle hint
  syntax is extensive, version-specific, and a subtly wrong hint can
  silently fail to apply rather than erroring, exactly the "hallucinated
  hint" failure mode described above generalized to Oracle's specific
  hint dialect.
- **SQLite**: models trained predominantly on server-engine `EXPLAIN`
  output can suggest analysis techniques (buffer cache hit ratios,
  concurrent-session locking behavior) that don't apply to SQLite's
  embedded, single-writer model — verify any suggestion is actually
  meaningful for an embedded engine before applying it.
- **DuckDB**: as a newer, less heavily-represented engine in most models'
  training data, treat DuckDB-specific suggestions with extra skepticism
  and verify directly against DuckDB's own `EXPLAIN ANALYZE` output rather
  than assuming general SQL-engine advice transfers cleanly.

## Interview Questions

- "Walk me through how you'd validate an AI-suggested index before putting
  it in production."
- "What's the difference between a model's confidence and a model's
  correctness, and how does that change your review process?"
- "An AI tool suggests a query rewrite that passes `EXPLAIN` review but
  changes the result set. How would your validation process have caught
  this before merge?"

## Summary

AI assistance genuinely accelerates the hypothesis-generation stage of
query tuning — it does not accelerate, and should never replace, the
verification stage this handbook has taught as mandatory from the start.
Treat every AI-suggested index, rewrite, or diagnosis as an unverified
claim from a fluent, occasionally wrong source, and route it through the
same `EXPLAIN`-and-benchmark discipline you'd apply to a suggestion from
any other engineer — confident tone included.

## Practice Challenges

1. Take a query from Lesson 04 (Joins), intentionally ask an AI
   assistant for a "faster" rewrite without providing the schema, and
   document every unstated assumption in its answer using this lesson's
   "Red Flags" table.
2. Using Prompt Template 3, get an AI-suggested rewrite for one of Module
   18's cost-focused queries, then write the result-set diff query that
   proves (or disproves) correctness preservation yourself.

## Further Reading

- Lesson 07 — Tuning Workflow
- `PERFORMANCE_SMELLS.md`
- `COST_SMELLS.md`
- Lesson 11 — Automated Performance Testing & CI/CD Integration (the
  benchmark gate every AI-suggested change should pass through before merge)
