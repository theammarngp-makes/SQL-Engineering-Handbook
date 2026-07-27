# Asset Specification Sheet — Module 01

Specs for assets referenced in the audit that are **not** hand-written SVG markup (banners, screenshots, social preview) and therefore aren't generated in this pass. Each spec is detailed enough for a contributor to produce the asset consistently with the rest of the handbook.

---

## `banners/fundamentals-banner.png`

- **Dimensions:** 1280×320px (GitHub README banner ratio)
- **Layout:** Left-aligned title block, right-aligned decorative SQL-keyword pattern (faded `SELECT` / `WHERE` / `ORDER BY` in monospace, low opacity, non-legible at a glance — decoration, not content)
- **Typography:** Title "Module 01 · Fundamentals" in a bold sans-serif (Segoe UI / Inter), 40px; subtitle "SELECT · WHERE · ORDER BY · LIMIT · ALIAS" in 18px, regular weight
- **Colors:** Background `#0d1117` (GitHub dark), title text `#ffffff`, subtitle `#8b949e`, accent bar `#2f6feb` (matches the blue used in `execution-order-flow.svg` for FROM/WHERE, keeping brand consistency across the module's diagrams and its banner)
- **Icon:** A simple database-cylinder glyph, top-right, `#2f6feb`, 48×48px

## `social/social-preview.png`

- **Dimensions:** 1280×640px (GitHub social preview requirement)
- **Layout:** Centered, same palette as the banner; large module number "01" watermarked at 15% opacity behind the title for visual hierarchy across all module social previews
- **Content:** Repository name (small, top), module title (large, center), topic list (small, bottom)

## `images/sql-terminal.png`

- **Content:** An actual terminal screenshot (not a mockup) running one of this module's queries — recommend `01_SELECT.sql` Example 3 (`SELECT * FROM employes;`) against `psql` or the MySQL CLI, since it's short enough to fit without truncation
- **Requirement:** Must be a real screenshot for authenticity — do not fabricate terminal output as an image; a fabricated screenshot risks showing incorrect output formatting for the claimed engine

## `images/relational-database-example.png`, `images/table-example.png`, `images/query-example.png`

- **Recommendation:** these three are largely superseded by the new `diagrams/` SVGs (`execution-order-flow.svg` and `query-lifecycle.svg` already cover "what does a query's journey look like" and "what does a table look like" is already covered by the Markdown tables in each topic file). Recommend **not** duplicating this content as separate raster images — keeping the module's visual explanation in one SVG-based system (versionable, diffable, theme-consistent) rather than mixing in static screenshots is more maintainable long-term. Flagged here for maintainer decision rather than unilaterally dropped.

---

## Why these aren't generated in this pass

SVG diagrams are markup — they can be authored directly and are included in `diagrams/`. Banners, social previews, and terminal screenshots are raster/photographic assets that need a design tool or an actual terminal session; fabricating them here would mean either a low-fidelity placeholder or an invented "screenshot" that misrepresents real tool output. Both are worse than a clear spec a contributor can execute against.
