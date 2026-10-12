[← Module Home](./README.md)

# Contributing to Module 17 — Transactions & Concurrency Control

## Scope

This module covers ACID, isolation levels, locking, deadlocks, MVCC,
transaction anti-patterns, and transaction design — against this
handbook's shared `employes` / `departments` / `locations` schema
(`00_Schema`). Contributions should stay within this scope; new
theory modules belong in a separate PR with separate justification,
not folded into this one.

## Dialect Policy

MySQL 8.x / 8.4 (InnoDB) is this handbook's baseline. Any PostgreSQL,
SQL Server, Oracle, SQLite, or DuckDB example must be explicitly
labeled as such — never presented as if it were universal or as if it
were MySQL syntax. See each lesson's "MySQL / PostgreSQL / SQL Server
Notes" and "Additional Dialect Notes" sections for the established
pattern to follow.

## Required Lesson Structure

Every lesson `.md` file follows this fixed section order (see any
existing lesson for the exact pattern): Introduction → Learning
Objectives → Why This Exists → Business Motivation → [topic-specific
sections] → Engineering Notes → MySQL/PostgreSQL/SQL Server Notes →
Common Mistakes → Edge Cases → Troubleshooting Guidance → Scalability
Considerations → Additional Dialect Notes → Interview Questions →
Summary → Practice Challenges → Further Reading.

Do not deviate from this order. If a section genuinely doesn't apply
to a given lesson, state that explicitly rather than omitting the
section silently (Lessons 06 and 07 do this for sections that don't
introduce new dialect-specific material).

## SQL Companion Files

Every `.sql` file must be runnable top-to-bottom against `00_Schema`
without manual edits, with the exception of explicitly marked
two-session demos (which must be clearly commented as requiring a
second connection) and explicitly commented-out anti-pattern examples
(which must never be left runnable, since they demonstrate incorrect
code). Every demo that modifies data must restore the original state by
capturing the original value first (a session variable for one row, a
temporary table for many rows) and restoring from it — never by
hardcoding a guessed "original" value. Each file must leave no
transaction open at the end, and must state any precondition it depends
on (rows that must exist, constraints that must be declared).

## Claims About Performance or Scale

Never state an absolute performance claim ("this is always faster,"
"this always causes contention"). Any performance-adjacent statement
must be qualified as illustrative/conceptual unless it's citing an
actual, reproducible benchmark — and this module contains no
benchmarks; all performance discussion here is reasoning about
mechanism, not measured numbers. This matches the standard established
in Module 16.

## Diagrams

Hand-coded SVG only, no external libraries. Use the established
palette: neutral slate for structure, red (`#b91c1c`/`#fee2e2`) for
blocking/expensive/warning states, green (`#15803d`/`#dcfce7`) for
good/prevented/fast states, amber (`#b45309`/`#fef3c7`) for
neutral-attention states. Validate every new SVG parses as well-formed
XML before committing.

## Submitting Changes

1. Open an issue describing the specific gap or defect (not "make
   this module more comprehensive" — a concrete, scoped problem).
2. Run any modified `.sql` file against a local copy of `00_Schema`
   before submitting.
3. If adding a new lesson section type not covered by this guide,
   explain the reasoning in the PR description.

## Cross-Module Links

Modules 15 (Indexes) and 16 (Query Optimization) exist in the handbook and
may be linked using their actual repository folder names (`15_INDEXES`,
`16_QUERY_OPTIMIZATION`). Module folders use `ALL_CAPS_WITH_UNDERSCORES`
names — verify exact paths and capitalization against the live repository
before merging, because links to sibling modules cannot be validated from
this module's folder alone. Never link to a lesson file that does not
exist.
