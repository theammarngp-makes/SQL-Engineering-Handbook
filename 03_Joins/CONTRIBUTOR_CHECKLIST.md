# Contributor Checklist — Module 03: Joins

Use this checklist for any PR that adds, edits, or removes a file in `03_Joins`. It exists to keep the module at the standard set in [`ENGINEERING_AUDIT_REPORT.md`](./ENGINEERING_AUDIT_REPORT.md) as more people contribute.

## Before you start

- [ ] Read the existing `.md`/`.sql` pair most similar to what you're adding — match its section structure rather than inventing a new shape.
- [ ] Confirm whether your change needs a schema update. If so, edit `schema/00_schema_setup.sql` — **never** hardcode a different schema inline in a topic file.

## Every `.sql` file

- [ ] Runs cleanly, top to bottom, against a freshly-seeded database (`schema/00_schema_setup.sql`), with no errors.
- [ ] Every query has an `EXPECTED OUTPUT` comment, and you've actually run the query to confirm the comment is accurate — not estimated.
- [ ] Every query has a `BUSINESS SCENARIO` comment framing *why* someone would ask this, not just what the query does.
- [ ] Table and column names are spelled correctly and match `schema/00_schema_setup.sql` exactly (this module previously shipped a repo-wide `employes`/`employees` typo — treat spelling as a real review item, not a nitpick).
- [ ] Every table reference uses an alias once more than one table is in scope.
- [ ] At least one query per file includes an `ALTERNATIVE SOLUTION` or `FURTHER EXPERIMENTS` section.

## Every `.md` file

- [ ] Includes, at minimum: Learning Objectives, Concept Overview, Business Context, Syntax + breakdown, Execution Flow, Edge Cases (NULL/duplicates/cardinality), Common Mistakes, Best Practices, Interview Questions, Summary, Practice Challenges.
- [ ] States explicitly which join type (INNER/LEFT/RIGHT/etc.) is the correct default for the scenario shown, and why — don't leave the reader to infer it.
- [ ] Any vendor-specific behavior (MySQL's missing `FULL OUTER JOIN`, Oracle's legacy `(+)` syntax, etc.) is called out in a dedicated `Vendor Notes` section, not buried in prose.
- [ ] Cross-links to related files use relative paths (`./02_LEFT_JOIN.md`), not absolute GitHub URLs.

## If you're adding a new topic file

- [ ] Update the numbering in `README.md`'s Topics Covered table and Folder Structure section.
- [ ] Update the Recommended Learning Order section if the new topic changes the intended sequence.
- [ ] Add the new file's Further Reading links pointing both forward and backward to adjacent topics.

## If you're adding or editing a diagram

- [ ] SVGs go in `assets/diagrams/`, named in `kebab-case.svg`.
- [ ] Use the existing color palette (blue `#3b6fd8` / orange `#d8763b` / green `#2e9e5b` for the three-way algorithm comparisons; green fill `#8fbf6b` for "matched/kept" regions in Venn diagrams) for visual consistency across the module.
- [ ] Reference the new diagram from the relevant `.md` file(s) **and** from the README if it illustrates a module-wide concept, not just a single topic.

## Before opening the PR

- [ ] Re-read your diff once as if you were a stranger to the repo — does every claim in your prose have a query in the paired file that actually demonstrates it? (The original `03_RIGHT_JOIN.sql` file failed this check — its query couldn't distinguish the behavior it claimed to show.)
- [ ] Run a spell-check pass on table/column names specifically — this is the single most common defect class this module has had historically.
