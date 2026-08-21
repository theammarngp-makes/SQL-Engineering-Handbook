# Module 09 — Asset Specifications & Status

This file is the accurate, current record of every visual asset in this
module: what exists, what it shows, and what was deliberately excluded.
Nothing below is aspirational — if an asset is listed as built, it's in
the repository at the path shown.

## assets/diagrams/ — SVG (5 diagrams, all built)

| File | Referenced in | Content |
|---|---|---|
| `now-vs-sysdate.svg` | File 01 | Statement timeline showing `NOW()`/`CURDATE()` frozen at statement start vs. `SYSDATE()` re-evaluated per call |
| `date-part-extraction.svg` | File 02 | One date value with nine spokes to `YEAR()`, `QUARTER()`, `MONTH()`, `MONTHNAME()`, `WEEK()`, `DAY()`, `DAYNAME()`, `WEEKDAY()`, `DAYOFYEAR()`, `DAYOFWEEK()` |
| `date-arithmetic-timeline.svg` | File 03 | Timeline with `DATE_SUB`/`DATE_ADD` interval jumps and `DATEDIFF()`/`TIMESTAMPDIFF()` measurement brackets |
| `format-parse-cycle.svg` | File 04 | Two-way round trip between an internal `DATE` value and a display string via `DATE_FORMAT()` / `STR_TO_DATE()` |
| `mtd-qtd-ytd-windows.svg` | File 05 | 12-month calendar bar with MTD, QTD, YTD, and trailing-30-day windows plotted against one `CURRENT_DATE` anchor |

Each diagram is embedded directly in its corresponding `.md` file
(immediately above the plain-text ASCII fallback, which is kept for
anyone reading the raw file or a renderer without image support) and
referenced again from the module `README.md`.

## assets/images/ — built

- `hero-banner.svg` — README hero banner (calendar-grid motif + module title)

## assets/images/ — deliberately excluded

`module-thumbnail.svg` and `social-preview.svg` (present in some other
modules, e.g. 15_Indexes) were not built here — they're root-README /
Open-Graph assets that belong to the handbook's cross-module branding
pass, not to an individual module's content. Adding them here without
the corresponding entries in the handbook root would produce an
inconsistent asset set across modules.

## Design System Reference

All five in-content diagrams share the handbook's existing visual
language: paper-white background with a faint grid (`#FAFAF7` /
`#E8E4D9`), ink-navy linework (`#1A1F2B`), teal for the primary/
correct path (`#147D7A`), amber for the caution/anti-pattern path
(`#B45309`), monospace labels (`IBM Plex Mono`), sans-serif titles
(`IBM Plex Sans`), and the corner-tick-mark "blueprint" frame used on
every diagram canvas in this repository. The hero banner uses the
inverted dark variant of the same palette (`#0B1420` background,
`#2DD4C7` accent) to read correctly as a banner image rather than an
in-page diagram — consistent with every other module's hero banner.
