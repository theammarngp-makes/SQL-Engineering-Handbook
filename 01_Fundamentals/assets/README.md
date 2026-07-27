# Module 01 Assets

Visual assets for the Fundamentals module — all hand-authored SVG, no build step, no external renderer. GitHub renders every file below natively inside Markdown.

## `diagrams/`

| File | Used in | Shows |
|---|---|---|
| [`hero-banner.svg`](./diagrams/hero-banner.svg) | README | Module hero banner — title, topic pills, dark background matching GitHub's dark theme |
| [`module-roadmap.svg`](./diagrams/module-roadmap.svg) | README | The 5-topic learning path (SELECT → WHERE → ORDER BY → LIMIT → ALIAS) |
| [`query-lifecycle.svg`](./diagrams/query-lifecycle.svg) | README, `01_SELECT.md` | How a written query becomes a result set: parser → optimizer → execution engine |
| [`execution-order-flow.svg`](./diagrams/execution-order-flow.svg) | README, all 5 topic files | The 7-stage logical execution order, with this module's 4 covered stages highlighted |
| [`select-projection.svg`](./diagrams/select-projection.svg) | `01_SELECT.md` | `SELECT` removes columns, not rows — shown side-by-side against the full table |
| [`predicate-truth-values.svg`](./diagrams/predicate-truth-values.svg) | `02_WHERE.md` | Three-valued logic (`TRUE` / `FALSE` / `UNKNOWN`) and why `= NULL` never matches |
| [`nulls-sort-order.svg`](./diagrams/nulls-sort-order.svg) | `03_ORDER_BY.md` | Default `NULL` sort position compared visually across all 4 engines |
| [`limit-dialect-comparison.svg`](./diagrams/limit-dialect-comparison.svg) | `04_LIMIT.md` | The same "first 3 rows" query written in 4 different, non-portable keywords |
| [`alias-scope-timeline.svg`](./diagrams/alias-scope-timeline.svg) | `05_ALIAS.md` | When an alias starts existing relative to `WHERE` / `SELECT` / `ORDER BY` |

All nine share one fixed color palette so they read as one system rather than nine unrelated images:

| Color | Hex | Meaning across diagrams |
|---|---|---|
| Blue | `#2f6feb` | `FROM` / `WHERE` / MySQL / PostgreSQL |
| Purple | `#6f42c1` | `GROUP BY` / `HAVING` / `ALIAS` / Oracle |
| Orange | `#e8622c` | `SELECT` / `LIMIT` / SQL Server |
| Green | `#22863a` | `ORDER BY` / kept rows / correct outcomes |
| Red | `#cf222e` | dropped rows / incorrect outcomes |

Fixed hex values (not `prefers-color-scheme` or CSS variables) were used deliberately so every diagram renders identically in GitHub's light and dark theme — no SVG `<style>` media queries, which GitHub's Markdown sanitizer strips anyway.

## Recommended (not included — see `SVG_SPECIFICATION.md`)

Photographic/raster assets (a terminal screenshot, a social preview PNG) are specified but not generated here — they need an actual terminal session or a design tool, not markup. See [`SVG_SPECIFICATION.md`](./SVG_SPECIFICATION.md).

## Regenerating a diagram

Each SVG is plain, hand-written markup — open it in any text editor or vector editor (Figma, Inkscape, VS Code) to adjust. There is no build pipeline; commit the `.svg` file directly.
