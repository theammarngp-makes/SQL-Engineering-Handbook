# Contributing to Module 16 — Query Optimization

This document exists so contributions to this module stay consistent with
its existing lessons and with the rest of the SQL Engineering Handbook. If
you're proposing a new lesson, expanding an existing one, or fixing a query,
start here.

## Naming Conventions

- Lesson files: `NN_TOPIC_NAME.md` + matching `NN_TOPIC_NAME.sql`, numbered
  in the order they should be read (see `README.md`'s Learning Flow table).
- Diagrams: lowercase, hyphen-separated, descriptive (`hash-join.svg`, not
  `diagram3.svg`), stored under `assets/diagrams/`.
- The module banner lives at `assets/images/hero.svg` — don't add
  additional top-level hero images; update this one if the module's scope
  changes.

## Documentation Conventions

Every lesson `.md` file follows this section order — match it exactly for
new lessons, and don't remove sections when editing existing ones without a
good reason stated in your PR description:

```text
Introduction
Learning Objectives
Why This Exists
Business Motivation
[topic-specific conceptual sections]
Engineering Notes
MySQL / PostgreSQL / SQL Server Notes
Common Mistakes
[Anti-patterns, where relevant]
Edge Cases
Troubleshooting Guidance
Scalability Considerations
Additional Dialect Notes (Oracle, SQLite, DuckDB)
Interview Questions / Interview Insight
Summary
Practice Challenges
Further Reading
```

- Every code example must run against the handbook's shared
  `employes` / `departments` / `locations` schema (`00_Schema`) unless
  explicitly marked as illustrative/pseudocode for a scenario the shared
  schema can't represent (e.g. a transactions table) — mark those clearly
  as commented-out or hypothetical.
- State the assumed production data volume explicitly wherever a
  performance claim depends on scale — "at 8 million rows" not just
  "at scale."

## SQL Formatting Rules

- Uppercase SQL keywords (`SELECT`, `WHERE`, `JOIN`)
- Meaningful table aliases (`e` for `employes`, `d` for `departments`, `l`
  for `locations`) — stay consistent with existing lessons rather than
  inventing new aliases per file
- One clause per line for anything beyond a trivial single-line query
- Comment every "poor performing" vs. "optimized" pair explaining *why*,
  not just labeling which is which

## Diagram Conventions

Match the existing style in `assets/diagrams/`:

- Neutral base palette (slate grays), reserving color for meaning: red
  (`#b91c1c` / `#fee2e2`) for "expensive/warning," green (`#15803d` /
  `#dcfce7`) for "good/fast outcome," amber (`#b45309` / `#fef3c7`) for
  "in-progress/neutral-attention"
- Every node must have a visible label — no unlabeled shapes
- Every relationship must be an explicit arrow — no implied connections via
  proximity alone
- SVG only, no raster images, no clipart

## Review Checklist

Before submitting a PR against this module, confirm:

- [ ] New/edited SQL runs against the shared schema without modification
      (or is clearly marked illustrative)
- [ ] Every performance claim states an assumed data volume or is backed by
      an `EXPLAIN`/`EXPLAIN ANALYZE` reference
- [ ] Section order matches the Documentation Conventions above
- [ ] Any new diagram follows the Diagram Conventions above and is added to
      the README's Diagram Gallery table
- [ ] Cross-references to other handbook modules use the existing relative
      link style (`[`03_Joins`](../03_Joins)`)
- [ ] No claims about a specific engine's internals without a named engine
      and, ideally, version — avoid unqualified "databases do X"

## Questions

Open an issue against the main repository, or start a discussion thread —
see the handbook's root [`CONTRIBUTING.md`](../CONTRIBUTING.md) for
repository-wide contribution norms this module also follows.
