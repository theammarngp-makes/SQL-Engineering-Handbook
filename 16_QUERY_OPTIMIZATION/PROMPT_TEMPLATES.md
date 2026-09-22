# AI-Assisted Query Tuning — Prompt Templates

Five copy-paste templates from the main lesson
(`01_AI_ASSISTED_QUERY_TUNING_WORKFLOW.md`), collected here for direct use
in an IDE snippet library or team wiki. Each is designed to build a
validation step into the prompt itself rather than treating validation as
a separate, easily-skipped afterthought.

---

## 1. EXPLAIN plan analysis (grounded, not generic)

Use when you want diagnosis before any suggested fix.

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

---

## 2. Index suggestion with mandatory tradeoff disclosure

Use before creating any AI-suggested index.

```
Given this schema and query [PASTE], suggest an index that would help.
For your suggestion, explicitly state:
1. The exact column order and why that order matters for this query
2. Whether an existing index already partially covers this
3. The write-side cost (INSERT/UPDATE/DELETE overhead) of adding it
4. One scenario where this index would NOT be chosen by the planner
```

---

## 3. Rewrite with correctness-preservation proof

Use for any suggested query rewrite, before merging it.

```
Here is a query I want to optimize: [PASTE]

Propose a rewrite. Then, separately, write a verification query I can run
that proves the original and rewritten queries return identical result
sets (same rows, same order if order matters, same NULL handling) against
my actual data -- not just an argument for why they should be equivalent.
```

---

## 4. Adversarial self-check ("what would make this wrong")

Use as a mandatory follow-up to any suggestion before acting on it.

```
You suggested [PASTE THE MODEL'S PRIOR SUGGESTION].

Before I implement this: what assumption about my data distribution,
cardinality, or engine version would make this suggestion NOT help, or
actively make performance worse? Be specific, not generic.
```

---

## 5. Cross-check against a known smell catalog

Use with `PERFORMANCE_SMELLS.md` or Lesson 10's
`COST_SMELLS.md` open alongside the suggestion.

```
Here is a catalog of performance anti-patterns my team maintains:
[PASTE RELEVANT ENTRIES FROM PERFORMANCE_SMELLS.md / COST_SMELLS.md]

Here is a query and a proposed rewrite: [PASTE BOTH]

Does the rewrite eliminate any smell in this catalog? Does it introduce
any smell in this catalog that the original didn't have? Answer both
questions explicitly, referencing specific catalog entries.
```

---

## Usage note

None of these templates replace the mandatory human validation steps in
the main lesson. They structure the prompt so the model's response is
easier to verify — they do not make the response verified.
