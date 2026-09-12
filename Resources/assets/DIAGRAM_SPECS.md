# Resources Library — Asset Specifications & Status

This file is the accurate, current record of every visual asset in the
Resources library: what exists, what it shows, and where it's used.
Nothing below is aspirational — if an asset is listed as built, it's
in this folder.

## assets/ — SVG (12 topic diagrams + 1 banner, all built)

| # | File | Embedded In | Shows |
|---|---|---|---|
| 01 | `01_books.svg` | [books.md](../books.md) | The 13 categories as a reading-order ladder, not an alphabetical shelf |
| 02 | `02_blogs.svg` | [blogs.md](../blogs.md) | The two authority tiers — vendor blogs vs. real-scale engineering postmortems |
| 03 | `03_documentation.svg` | [documentation.md](../documentation.md) | One hub, four platform families (relational, cloud warehouse, analytical/embedded, tooling) |
| 04 | `04_youtube.svg` | [youtube.md](../youtube.md) | A six-stage playlist from fundamentals to interview prep |
| 05 | `05_interview_resources.svg` | [interview-resources.md](../interview-resources.md) | The four-stage funnel: syntax → pattern recognition → communication → business framing |
| 06 | `06_newsletters.svg` | [newsletters.md](../newsletters.md) | Daily-pulse vs. weekly-digest cadence across the five listed newsletters |
| 07 | `07_courses.svg` | [courses.md](../courses.md) | Five courses staircased by depth, annotated free vs. paid |
| 08 | `08_datasets.svg` | [datasets.md](../datasets.md) | Five public dataset sources radiating from a "≥ 3 related tables" filter |
| 09 | `09_playgrounds.svg` | [playgrounds.md](../playgrounds.md) | The zero-setup, sub-30-second path from idea to running query |
| 10 | `10_certifications.svg` | [certifications.md](../certifications.md) | Five certifications ranked by cost-to-credibility, with the "signal, not substitute" caveat |
| 11 | `11_communities.svg` | [communities.md](../communities.md) | Four community platforms radiating from "a question search can't answer" |
| 12 | `12_awesome_tools.svg` | [awesome-tools.md](../awesome-tools.md) | Tools grouped by category — client, IDE, ERD tool, formatter |
| — | `banner.svg` | [README.md](../README.md) | Library hero banner — bookshelf motif on the handbook's dark navy/teal palette |

Each topic diagram is embedded directly beneath the intro paragraph of
its corresponding file, before the first `---` divider, so it reads as
context-setting rather than decoration.

## Design System Reference

All 12 topic diagrams share the same house style used across this
handbook's other modules: paper-white background with a faint grid
(`#FAFAF7` / `#E8E4D9`), ink-navy linework (`#1A1F2B`), teal for the
primary/recommended path (`#147D7A`), amber for the caution/paid/
secondary path (`#B45309`), monospace labels (`IBM Plex Mono`),
sans-serif titles (`IBM Plex Sans`), and the corner-tick "blueprint"
frame used on every diagram canvas in this repository.

`banner.svg` uses the inverted dark variant of the same palette
(`#0B1420` background, `#2DD4C7` accent) to read correctly as a
banner image rather than an in-page diagram — consistent with every
other module's hero banner in this handbook.

## What Was Deliberately Excluded

No per-entry thumbnails (e.g., a mini-icon per book or blog) were
built. With ~13 files and well over a hundred individual resource
cards across them, per-entry imagery would multiply asset count far
beyond what a resource *index* needs — the 12 diagrams above each
summarize the shape and philosophy of their file, which is the level
this library actually reasons at (see `README.md` → *How Resources
Were Selected*). If a specific file later needs a deeper visual (e.g.
a full 13-book reading map), that's an additive PR, not a gap in this
pass.
