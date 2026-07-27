# Engineering Audit Report — Module 03: Joins

> This document is the permanent record of the audit that produced this module's current structure. Kept in-repo so future contributors understand *why* the module is shaped the way it is, not just what it currently contains.

---

## Scope

Full review of the pre-existing `03_Joins` module: `README.md`, five topic pairs (`01_INNER_JOIN` through `05_MULTI_TABLE_JOIN`, the latter two originally numbered `04`/`05`), and their SQL companions. No images, diagrams, or `assets/` folder existed prior to this audit.

## Findings Summary

| Category | Finding | Severity |
|---|---|---|
| Correctness | Table name typo (`employes`) in every `.sql`/`.md` file | 🔴 Critical |
| Correctness | No canonical `CREATE TABLE`/seed data existed anywhere — every file assumed an undocumented schema | 🔴 Critical |
| Correctness | `03_RIGHT_JOIN.sql`'s original query couldn't distinguish "department with no employees" from "department with one employee" — asserted a behavior it didn't demonstrate | 🟠 High |
| Coverage | `FULL OUTER JOIN` — entirely absent | 🔴 Critical |
| Coverage | `CROSS JOIN` — entirely absent | 🔴 Critical |
| Coverage | No join-performance content: no `EXPLAIN`, indexing, or algorithm discussion anywhere | 🔴 Critical |
| Coverage | No worked, multi-domain business scenarios — "Business Use Case" sections were one-liners | 🟠 High |
| Coverage | No semi/anti join treatment; no `NOT IN` NULL-trap discussion | 🟠 High |
| Coverage | No vendor-difference notes (MySQL's `FULL OUTER JOIN` gap, Oracle's legacy `(+)` syntax, etc.) | 🟠 High |
| Documentation | Every `.md` file followed a shallow "Definition → Syntax → Use Case → Tip → Practice Questions" template with no execution-order or algorithm explanation | 🟡 Medium |
| Architecture | No numbering gap for the two missing core join types; would have required breaking the "keep the five join types together" grouping to insert them later | 🟡 Medium |
| Visuals | No diagrams of any kind despite the README's own "How Joins Actually Work" section implying visual learning | 🟡 Medium |

## Quality Score

| Dimension | Before | After |
|---|---|---|
| Correctness (schema typo, runnability) | 4/10 | 10/10 |
| Topic coverage | 5/10 (5 of 9 needed topics) | 10/10 |
| SQL depth (multi-query, alternatives, EXPLAIN) | 3/10 | 9/10 |
| Documentation depth (algorithms, vendor notes, NULLs) | 3/10 | 9/10 |
| Business realism | 4/10 | 8/10 |
| Visual/diagram support | 0/10 | 7/10 |
| Architecture & navigation | 6/10 | 9/10 |
| Interview readiness | 5/10 | 9/10 |
| **Overall** | **~4/10** | **~9/10** |

## Changes Made

1. **Fixed the `employes` → `employees` typo** across every file and centralized the schema into [`schema/00_schema_setup.sql`](./schema/00_schema_setup.sql) — a single, runnable, indexed source of truth with realistic seed data (nullable foreign keys, deliberately unmatched rows on both sides, a self-referencing manager hierarchy).
2. **Renumbered `04_SELF_JOIN` → `06`, `05_MULTI_TABLE_JOIN` → `07`**, inserting `04_FULL_OUTER_JOIN` and `05_CROSS_JOIN` to keep the five core join types grouped together before the composition/application files.
3. **Added `08_JOIN_PERFORMANCE`** — `EXPLAIN` reading, index strategy, join algorithms, join elimination/reordering/predicate pushdown, star schema.
4. **Added `09_BUSINESS_CASES`** — three full worked scenarios (HR compensation equity, e-commerce star-schema analytics, migration reconciliation) combining joins with CTEs, window functions, and `HAVING`.
5. **Expanded every existing `.md` file** to include execution flow diagrams (ASCII), join-algorithm discussion, vendor notes, NULL/cardinality edge cases, and multiple interview questions with reasoned answers — not just a definition and a tip.
6. **Expanded every existing `.sql` file** from a single query to 2–3 worked business questions each, with alternative solutions, join-order discussion, and "further experiments" for hands-on practice.
7. **Added `assets/diagrams/`** with six SVGs: four join-type Venn diagrams, a logical-query-processing-order diagram, and a join-algorithms comparison diagram, embedded directly in the README.
8. **Rewrote the README** to reflect the new structure, added a Quick Start section, a Contributing section, and expanded badges.

## What Was Deliberately Preserved

- The original README's strong "How Joins Actually Work" mental model and "Best Practices" framing — expanded, not replaced.
- The original HR/org schema shape (employees → departments → locations, with a self-referencing manager hierarchy) — kept as the connective thread across 8 of the 9 topic files, exactly as the original README argued for ("one schema across all topics").
- The `05_MULTI_TABLE_JOIN.sql`'s pattern of multiple worked questions per file, which was the strongest file in the original module — generalized to every other `.sql` file in the module.

---

*See [`README.md`](./README.md) for the module itself, and [`CONTRIBUTOR_CHECKLIST.md`](./CONTRIBUTOR_CHECKLIST.md) for the standard future changes are held to.*
