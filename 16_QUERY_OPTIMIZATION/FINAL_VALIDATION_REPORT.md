# Final Validation Report

## Status

PASS — COMMIT READY

## Final Fixes

1. MySQL RANDOM() → RAND()
2. MySQL EXPLAIN terminology corrected/labeled
3. OR → UNION ALL NULL/duplicate semantics validated

## Validation

| Check | Status |
|---|---|
| MySQL syntax | PASS |
| EXPLAIN terminology | PASS |
| PostgreSQL labeling | PASS |
| RAND() audit | PASS |
| OR → UNION ALL semantics | PASS |
| NULL semantics | PASS |
| Duplicate semantics | PASS |
| CI | PASS |
| Performance Lab | PASS |
| README | PASS |
| Links | PASS |
| SVGs | PASS |

## Remaining Issues

None

---

## Detail: What Changed in This Pass

This pass started from `16_QUERY_OPTIMIZATION_COMMIT_READY.zip` and made
only the three surgical fixes below plus their required regression audit.
No lessons were added or removed, no architecture changed, and no existing
technical depth was removed.

### Fix 1 — MySQL RANDOM() → RAND()

A repo-wide search found exactly two files using `RANDOM()` as a MySQL
example:

- **`REWRITE_COOKBOOK.md`** (Rewrite #15) — the "Problem" example and its
  index-table row now show `ORDER BY RAND()` as the primary (MySQL) form,
  with `RANDOM()` kept and explicitly labeled as the PostgreSQL equivalent.
  The "Reason" prose and the benchmark note were updated to name both
  functions by engine.
- **`PERFORMANCE_SMELLS.md`** (Smell #33) — row updated to
  `ORDER BY RAND() (MySQL) / ORDER BY RANDOM() (PostgreSQL)`.

No other `RANDOM()` occurrences existed in the module (verified by a
final repo-wide grep after the fix — see Validation table above).

### Fix 2 — MySQL EXPLAIN Terminology

`02_EXPLAIN_AND_EXECUTION_PLANS.md` (the lesson this fix specifically
targets) previously presented PostgreSQL's `EXPLAIN` plan-tree output
(`Seq Scan`, `Index Scan`, `HashAggregate`, etc.) as if it were generic,
engine-neutral terminology, with no MySQL-specific EXPLAIN output shown
anywhere in the lesson. This has been corrected:

- The "Reading a Plan Tree" section now leads with **MySQL's actual
  `EXPLAIN` output** — the classic tabular format (`type`, `possible_keys`,
  `key`, `rows`, `Extra`) and the `EXPLAIN FORMAT=TREE` / `EXPLAIN ANALYZE`
  (MySQL 8.0.18+) tree format — using the same worked query as before.
  The original PostgreSQL plan tree is retained immediately after, now
  under an explicit "PostgreSQL-specific terminology (cross-database
  comparison)" heading, with a note that MySQL's `EXPLAIN` will not
  literally print `Seq Scan`.
- The "Access Methods You'll See" table was split the same way: a MySQL
  `type`-column reference table (`ALL`, `index`, `range`, `ref`, `eq_ref`,
  `const`, `Extra: Using index`) followed by an explicitly labeled
  PostgreSQL cross-reference table mapping each PostgreSQL node name to
  its rough MySQL equivalent.
- `02_EXPLAIN_AND_EXECUTION_PLANS.sql`'s comments (engineering notes,
  the post-index comparison guidance, and the performance-comparison
  template table) were rewritten to reference MySQL's `type`/`key`
  columns first, with the PostgreSQL plan-node name given in parentheses
  for readers cross-referencing the other engine.
- Every other unlabeled `Seq Scan` / `Index Scan` / `Index Only Scan` /
  `Bitmap Heap Scan` / `Bitmap Index Scan` mention found in the
  repo-wide audit was either labeled by engine or, where the reference
  was one line in a table/flowchart node, rewritten as "full table scan
  (`Seq Scan` in PostgreSQL, `type: ALL` in MySQL)" or the equivalent
  short form. This touched: `PERFORMANCE_CHECKLIST.md`, `CHEATSHEET.md`,
  `07_QUERY_TUNING_WORKFLOW.md`, `DECISION_TREE.md`,
  `TROUBLESHOOTING_GUIDE.md`, `OPTIMIZATION_PLAYBOOK.md`,
  `PRACTICE_PROBLEMS.md`, `SOLUTIONS.sql`, `PERFORMANCE_SMELLS.md`,
  `ENGINEERING_GLOSSARY.md`, and `03_SARGABILITY_AND_INDEX_USAGE.md`/`.sql`.
  Three diagram SVGs (`execution-plan-tree.svg`, `covering-index.svg`,
  `sargable-vs-non-sargable.svg`) that render PostgreSQL plan-node names
  as diagram labels received a one-line italic caption identifying the
  terminology as PostgreSQL's and pointing to Lesson 02 for the MySQL
  equivalent, rather than being redrawn.

**Classification of what was left unchanged** (per the regression-audit
instructions — acceptable because each is inside a clearly labeled
PostgreSQL-specific context):
- `PRODUCTION_INCIDENTS.md` — every incident declares its own `**Stack**`
  (e.g. "PostgreSQL 15") and labels each execution-plan block
  "*(illustrative — PostgreSQL EXPLAIN ANALYZE output)*". Left unchanged.
- `REAL_WORLD_CASEBOOK.md` — carries an explicit top-of-file "Engine
  labels" disclaimer naming `Seq Scan` as PostgreSQL-specific vendor
  terminology, and its one inline mention already spells out both
  engines' terms. Left unchanged.
- `CROSS_DATABASE_ENGINEERING.md` — is itself the engine-comparison
  reference table; each column is already headed by its engine. Left
  unchanged.
- `BENCHMARK_GUIDE.md`'s template — declares `**Engine**: PostgreSQL
  15.x` directly above the `Seq Scan`/`Index Scan` plan-node cells,
  which is the labeling context those terms sit inside. Left unchanged.

### Fix 3 — OR → UNION ALL NULL/Duplicate Semantics

Audited every `OR` → `UNION ALL` rewrite in the module (`REWRITE_COOKBOOK.md`
#2, `09_QUERY_REWRITE_PATTERNS.md`/`.sql` Pattern 1, and the equivalent
example in `PRODUCTION_INCIDENTS.md` Incident 6) against the six-point
checklist (NULL behavior, branch overlap, duplicate rows, equivalence).

**Bug found and fixed** in two of the four instances
(`REWRITE_COOKBOOK.md` and `09_QUERY_REWRITE_PATTERNS.md`/`.sql`): the
exclusion guard on the second `UNION ALL` branch was written as a bare
`dept_id <> 4`. Because SQL uses three-valued logic, a row with
`dept_id IS NULL` makes `dept_id <> 4` evaluate to `UNKNOWN` (treated as
false in `WHERE`), so that row is silently **excluded** from the
rewritten query even when the *original* `WHERE dept_id = 4 OR hire_date >
'2023-01-01'` predicate would have included it via the `hire_date` branch.
This is a genuine correctness regression, not just a style issue — the
rewrite as originally written could change query results whenever
`dept_id` (or the equivalent column) is nullable.

**Fix applied**: the exclusion guard in both files was changed to
`(dept_id <> 4 OR dept_id IS NULL)`, which correctly captures "every row
not already returned by branch 1," NULLs included. Verified equivalence:
branch 1 (`dept_id = 4`) and branch 2 (`dept_id <> 4 OR dept_id IS NULL`)
remain mutually exclusive (no row can satisfy both), so `UNION ALL`
introduces no duplicates, and their union is provably identical to the
original `OR` predicate's result set for all three cases of `dept_id`
(`= 4`, `<> 4`, `IS NULL`).

Both files' prose was also updated to remove the implication that "OR can
always be replaced by UNION ALL" — they now state explicitly that the
rewrite is only valid when the branches are made mutually exclusive with
a NULL-safe guard, and instruct the reader to validate NULL behavior and
duplicate rows before adopting it for their own query.

**Already correct, no change needed**: `PRODUCTION_INCIDENTS.md`
Incident 6 already carried an explicit note — "If `city` is nullable,
also add `OR city IS NULL`" — correctly flagging the same class of issue
for its own example. Left unchanged.

## Regression / Scope Confirmation

- No lessons, files, or features were added or removed.
- No architecture, numbering, folder structure, or CI configuration was
  changed.
- No unrelated documentation was edited — every change above maps
  directly to Fix 1, Fix 2, or Fix 3.
- The final repo-wide regression grep (see Validation table) confirms
  every remaining occurrence of `RANDOM()`, `Seq Scan`, `Index Scan`,
  `Index Only Scan`, `Bitmap Heap Scan`, and `Bitmap Index Scan` sits
  inside an explicitly labeled PostgreSQL-specific context.
