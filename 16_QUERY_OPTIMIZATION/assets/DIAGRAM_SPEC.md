# Diagram Spec — Module 16

Design specification for every diagram in `assets/diagrams/`.

## Global conventions

- **Background:** neutral slate (`#0f172a`).
- **Semantic color:** red = cost/waste/failure, green = optimized/passing/automate,
  amber = decision point or warning, slate = neutral state.
- **Text:** light foreground for contrast; monospace only for literal code.
- **Format:** raw SVG with a `viewBox`, no external font/image dependencies.

## Diagram entries

### 1. `sql-execution-pipeline.svg` -- Lesson 01
Parse → Bind → Optimize → Execute → Return, each stage annotated.

### 2. `execution-plan-tree.svg` -- Lesson 02
EXPLAIN plan as a tree, read bottom-up, with estimated-vs-actual callouts.

### 3. `sargable-vs-non-sargable.svg` -- Lesson 03
Side-by-side: function-wrapped predicate (red, full scan) vs. SARGable
rewrite (green, index seek).

### 4. `covering-index.svg` -- Lesson 03
Index structure showing all query-needed columns present, "no heap fetch
required" callout.

### 5. `nested-loop-vs-hash-vs-merge.svg` -- Lesson 04
Three panels, one per join algorithm, numbered step sequence.

### 6. `predicate-pushdown.svg` -- Lesson 04
Before/after plan-tree pair: filter above join (red) vs. pushed below (green).

### 7. `query-tuning-workflow.svg` -- Lesson 07
Looped flow: Measure → Read the Plan → Hypothesis → Change One Thing →
Verify, with a "didn't help" arrow back to Hypothesis.

### 8. `optimization-checklist.svg` -- Reference
Compact pre-merge checklist card.

### 9. `explain-to-cost-mapping.svg` -- Lesson 10
Four rows (BigQuery, Snowflake, Redshift, RDS/Aurora): EXPLAIN/metadata
signal → arrow → billed cost. Dimensions: 900x420px.

### 10. `automate-vs-manual-decision-tree.svg` -- Lesson 11
Three sequential decision diamonds (amber) with terminal outcomes -- green
"automate," slate "manual review" (neutral, not a failure state).
Dimensions: 920x520px.

### 11. `ai-tuning-validation-workflow.svg` -- Lesson 12
Dashed "AI suggestion" node (unverified) → solid validation-step nodes
(EXPLAIN re-run → result-set diff → smell-catalog cross-check → CI gate)
→ failure branch to outright rejection, not a retry loop. Dimensions: 960x260px.

## Adding a new diagram

1. Build the SVG using the global conventions above.
2. Add a numbered entry to this file.
3. Add a row to `README.md`'s Diagram Gallery table.
