# Module 15 — Asset Specifications & Status

This file is the accurate, current record of every visual asset in this
module: what exists, what it shows, and what was deliberately excluded.
Nothing below is aspirational — if an asset is listed as built, it's in
the repository at the path shown; if it's listed as excluded, the reason
is stated rather than left implicit.

## assets/diagrams/ — SVG (12 diagrams, all built)

| File | Referenced in | Content |
|---|---|---|
| `index-scan-vs-table-scan.svg` | File 01 | Full table scan vs. index seek, side by side, with relative cost annotations |
| `btree-structure.svg` | File 02 | 3-level B+Tree — root, internal nodes, linked leaf nodes |
| `composite-index-order.svg` | File 03 | Nested physical sort order of a 3-column composite index |
| `leftmost-prefix-rule.svg` | File 03 | ✓/✗ checklist of query shapes against `INDEX(a, b, c)` |
| `clustered-vs-nonclustered.svg` | File 04 | Clustered (leaf = row) vs. non-clustered (leaf = pointer) comparison |
| `covering-index.svg` | File 05 | Non-covering (2 I/O) vs. covering (1 I/O) lookup comparison |
| `write-vs-read-tradeoff.svg` | File 06 | Read speed vs. write throughput as index count grows |
| `indexing-workflow.svg` | File 06 | OLTP vs. OLAP indexing decision flowchart |
| `index-selectivity.svg` | File 07 | Selectivity comparison: `customer_id` vs. `status` |
| `query-optimizer.svg` | File 07 | Cost-based optimization decision flow |
| `execution-plan.svg` | File 08 | Join plan tree with estimated-vs-actual row annotations |
| `index-lifecycle.svg` | File 10 | Healthy → degraded → maintained index lifecycle |

## assets/diagrams/ — Mermaid (3 sources, all built)

Three diagrams are inherently decision flows rather than structural
comparisons, so each also has a Mermaid source, embedded directly as a
collapsible `<details>` block immediately after its SVG in the
corresponding `.md` file (GitHub renders Mermaid natively — no image
load required):

- `query-optimizer.mmd` → embedded in File 07
- `execution-plan.mmd` → embedded in File 08
- `indexing-workflow.mmd` → embedded in File 06

The remaining 9 diagrams are structural/comparative rather than
flow-shaped (B+Tree structure, side-by-side comparisons, bar-style
selectivity charts) and are intentionally SVG-only — a Mermaid
flowchart isn't a natural fit for that content, and forcing one would
produce a worse diagram, not a more complete asset set.

## assets/images/ — built

- `hero-banner.svg` — README hero banner (B+Tree silhouette + module title)
- `module-thumbnail.svg` — small square icon for the handbook root README's module table
- `social-preview.svg` — 1280×640 GitHub Open Graph social preview card

All three README-level assets specified for this module are complete.

## assets/images/ — deliberately excluded

Five PNG "screenshot-style" images were originally scoped
(`ecommerce-indexes.png`, `banking-example.png`, `healthcare-example.png`,
`warehouse-schema.png`, `explain-output.png`). These are **not** included,
and this is a deliberate decision, not an oversight: a generated image
styled to look like a real terminal/`EXPLAIN` capture would misrepresent
actual query output, which runs directly against this module's own
accuracy standard. The correct path to these, if wanted, is to run the
corresponding `.sql` file against `00_SETUP.sql` locally and capture a
real screenshot — every query that would appear in one of these images is
written and ready to run in Files 01, 06, 08, and 09.

## Design System Reference

All diagrams share one visual language, for anyone extending this set:
paper-white background with a faint grid (`#FAFAF7` / `#E8E4D9`),
ink-navy linework (`#1A1F2B`), teal for the index/fast path (`#147D7A`),
amber for the scan/slow path (`#C2410C`), monospace labels (`IBM Plex
Mono`), sans-serif titles (`IBM Plex Sans`), and a corner-tick-mark
"blueprint" frame on every canvas. The README hero/social/thumbnail
assets use an inverted dark variant of the same palette
(`#0B1420` background, `#2DD4C7` accent) to read correctly as a banner
image rather than an in-page diagram.
