<p align="center">
  <img src="assets/banner.svg" alt="SQL Engineering Handbook — Resources Library" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-complete-2DD4C7?style=flat-square" alt="status: complete">
  <img src="https://img.shields.io/badge/files-12%20libraries%20%2B%20README-1A1F2B?style=flat-square" alt="13 files">
  <img src="https://img.shields.io/badge/diagrams-12%20SVG%20%2B%20banner-2DD4C7?style=flat-square" alt="13 diagrams">
  <img src="https://img.shields.io/badge/resource%20cards-100%2B-C2410C?style=flat-square" alt="100+ resource cards">
  <img src="https://img.shields.io/badge/cost-mostly%20free-6B7280?style=flat-square" alt="mostly free">
  <img src="https://img.shields.io/badge/license-MIT-6B7280?style=flat-square" alt="license: MIT">
</p>

<p align="center"><i>Part of the <a href="../README.md">SQL Engineering Handbook</a> — the curated external learning collection that picks up where the Handbook's own modules leave off.</i></p>

> [!NOTE]
> All 13 files in this library are now in place. Root documentation and platform links were checked against current sources where it mattered most (official docs, vendor rebrands); well-established books, blogs, and communities relied on strong existing knowledge rather than an individual fetch per entry — see the note at the end of [Summary](#summary) for what that means in practice.

---

## Table of Contents

- [Introduction](#introduction)
- [Purpose of the Resources Library](#purpose-of-the-resources-library)
- [What's In This Library](#whats-in-this-library)
- [The Diagrams](#the-diagrams)
- [How to Use These Resources](#how-to-use-these-resources)
- [Learning Philosophy](#learning-philosophy)
- [Recommended Learning Path](#recommended-learning-path)
- [Who This Collection Is For](#who-this-collection-is-for)
- [Role-Based Roadmaps](#role-based-roadmaps)
  - [Beginner Roadmap](#beginner-roadmap)
  - [Intermediate Roadmap](#intermediate-roadmap)
  - [Advanced Roadmap](#advanced-roadmap)
  - [Analytics Engineer Roadmap](#analytics-engineer-roadmap)
  - [Data Engineer Roadmap](#data-engineer-roadmap)
  - [Backend Developer Roadmap](#backend-developer-roadmap)
  - [Interview Preparation Roadmap](#interview-preparation-roadmap)
- [How Resources Were Selected](#how-resources-were-selected)
  - [Resource Card Template](#resource-card-template)
- [Quality Standards](#quality-standards)
- [Build Status](#build-status)
- [Module Checklist](#module-checklist)
- [Contribution Guidelines](#contribution-guidelines)
- [Folder Structure](#folder-structure)
- [Summary](#summary)

---

## What's In This Library

| Resource Library File | Description | Size | Diagram |
| :--- | :--- | ---: | :--- |
| 📖 [`books.md`](./books.md) | Curated list of essential SQL & database architecture books | 23.7 KB · 426 lines | [ladder](assets/01_books.svg) |
| ✍️ [`blogs.md`](./blogs.md) | Official vendor blogs and real-world engineering postmortems | 15.5 KB · 298 lines | [two tiers](assets/02_blogs.svg) |
| 📑 [`documentation.md`](./documentation.md) | Primary dialect docs for Postgres, MySQL, Snowflake, BigQuery, etc. | 14.7 KB · 260 lines | [hub & spoke](assets/03_documentation.svg) |
| 🎥 [`youtube.md`](./youtube.md) | Curated playlists and video tutorials for all skill levels | 11.9 KB · 270 lines | [playlist](assets/04_youtube.svg) |
| 🎯 [`interview-resources.md`](./interview-resources.md) | Staged 30/60/90-day interview roadmaps & technical prep | 12.2 KB · 204 lines | [funnel](assets/05_interview_resources.svg) |
| 📰 [`newsletters.md`](./newsletters.md) | Weekly digests, dbt updates, and Postgres Weekly | 1.8 KB · 24 lines | [cadence](assets/06_newsletters.svg) |
| 🎓 [`courses.md`](./courses.md) | Free and paid structured SQL learning paths | 1.6 KB · 24 lines | [staircase](assets/07_courses.svg) |
| 📊 [`datasets.md`](./datasets.md) | Real-world public datasets for query practice | 1.7 KB · 24 lines | [sources](assets/08_datasets.svg) |
| 🛠️ [`playgrounds.md`](./playgrounds.md) | Browser-based SQL execution sandboxes and DB clients | 1.4 KB · 23 lines | [zero-setup](assets/09_playgrounds.svg) |
| 📜 [`certifications.md`](./certifications.md) | Industry-recognized database and cloud certifications | 1.5 KB · 24 lines | [badge ladder](assets/10_certifications.svg) |
| 🌐 [`communities.md`](./communities.md) | Slack groups, Discord servers, Reddit, and developer forums | 1.2 KB · 24 lines | [four rooms](assets/11_communities.svg) |
| 🧰 [`awesome-tools.md`](./awesome-tools.md) | DB clients, ERD diagram tools, formatters, and query editors | 1.8 KB · 26 lines | [toolbox](assets/12_awesome_tools.svg) |
| — | **README.md** (this file) | Library map, philosophy, and role-based roadmaps | 21 KB+ | [banner](assets/banner.svg) |

Sizes above are read directly off disk, not estimated — see
[Build Status](#build-status). The six files from `books.md` through
`interview-resources.md` use the full 13-field
[Resource Card Template](#resource-card-template); the seven from
`newsletters.md` through `awesome-tools.md` use a lighter table
format proportional to their original one-line specs (see
[Folder Structure](#folder-structure) for why).

## Introduction

The 00–20 modules in this repository teach SQL by having you run real queries against real schemas and defend real business decisions. That's the "how." This folder is the "then what" — where to go once a module is finished and you want the official word on a feature, a book-length treatment of a topic a module `README` can't fully cover, or a mock interview to prove you actually learned it.

Nothing here duplicates the Handbook's own content. Think of it as what a senior engineer on your team would send you in a DM if you asked, "where did you actually learn this."

## Purpose of the Resources Library

The modules answer *"how do I write this query."* This folder answers three questions a repo of exercises can't fully answer on its own:

- **"Is this really how the database works, or just how this repo teaches it?"** — answered by pointing at the official documentation for the dialect in question, not a paraphrase of it.
- **"I finished the module — where's the deeper, book-length version of this topic?"** — answered by a curated reading list, organized so you're not guessing which of fifty SQL books is worth your time.
- **"How do I prove I can do this under interview pressure?"** — answered by a dedicated, staged interview-prep path.

If a topic is already taught end-to-end in a module, this library points *past* it — toward primary sources, alternate explanations, and the parts of the job (interviews, performance tuning, warehouse design) that go beyond what any single repository can hold.

## The Diagrams

Every one of the 12 resource files carries its own diagram (13 SVGs
total including the banner above), rendered in
[`assets/`](assets/) and embedded directly beneath that file's intro
paragraph — no external image hosting, so they render correctly on
GitHub, cloned locally, or on the handbook's GitHub Pages site. Each
one summarizes the *shape* of its file — not a random illustration,
but the actual filtering logic or reading order behind the list.

<p align="center">
  <img src="assets/01_books.svg" alt="books.md — thirteen shelves, one ladder" width="48%">
  <img src="assets/02_blogs.svg" alt="blogs.md — two tiers of authority" width="48%">
</p>
<p align="center">
  <img src="assets/03_documentation.svg" alt="documentation.md — one hub, four platform families" width="48%">
  <img src="assets/05_interview_resources.svg" alt="interview-resources.md — a funnel, not a link dump" width="48%">
</p>
<p align="center">
  <img src="assets/08_datasets.svg" alt="datasets.md — real data, not curated data" width="48%">
  <img src="assets/10_certifications.svg" alt="certifications.md — a signal, not a substitute" width="48%">
</p>

The remaining diagrams (`youtube.md`, `newsletters.md`, `courses.md`,
`playgrounds.md`, `communities.md`, `awesome-tools.md`) are embedded
in their own files rather than repeated here.
[`assets/DIAGRAM_SPECS.md`](assets/DIAGRAM_SPECS.md) is the complete,
accurate ledger of what exists, what each diagram shows, and what was
deliberately left out — kept honest against the actual asset folder,
not aspirational.

## How to Use These Resources

- **Don't start here.** Start with [`00_SAMPLE_DATABASE`](../00_SAMPLE_DATABASE/) and work through the modules in order. Come back to this folder when a module raises a question it doesn't fully answer itself.
- **Match the roadmap to your actual goal**, not to how impressive the full list looks. A backend developer and an analytics engineer need depth in different places — see [Role-Based Roadmaps](#role-based-roadmaps).
- **Check Difficulty and Estimated Time before committing.** Every resource card in the other files states both, specifically so a resource fits into a real week instead of an idealized one.
- **Treat "Free or Paid" as a real filter.** A paid resource is only listed when nothing free covers the same ground as well — no roadmap here requires spending money.
- **Use the `Related SQL Handbook Modules` field** on each card to jump back into this repo's own exercises once the theory makes sense.

## Learning Philosophy

This library is curated under the same rule the Handbook's modules follow: **a business question first, the syntax second.** A resource that teaches `RANK()` by ranking an arbitrary list of numbers is worth less than one that teaches it by finding each region's top-3 salespeople — even if the SQL on the page is identical.

Three things follow from that:

1. **Primary sources over paraphrase.** Official documentation is preferred over a tutorial that repeats the documentation with extra ads around it.
2. **Depth over breadth, sequenced.** The roadmaps below are ordered on purpose — advanced material assumes the intermediate material is comfortable, not just "read once."
3. **Evergreen over trending.** A resource earns its spot because the ideas hold up, not because it's new. Where recency genuinely matters (a cloud platform's current feature set, say), that's called out explicitly on the card.

## Recommended Learning Path

```mermaid
flowchart TD
    A[Modules 00-03: Fundamentals, Aggregations, Joins] --> B[Beginner Roadmap]
    B --> C[Modules 04-09: CASE WHEN to Date Functions]
    C --> D[Intermediate Roadmap]
    D --> E[Modules 10-16: Strings to Query Optimization]
    E --> F[Advanced Roadmap]
    F --> G{Pick a specialization}
    G --> H[Analytics Engineer Roadmap]
    G --> I[Data Engineer Roadmap]
    G --> J[Backend Developer Roadmap]
    H --> K[Interview Preparation Roadmap]
    I --> K
    J --> K
```

The path is linear through **Beginner → Intermediate → Advanced**, then branches by role. You don't need all three specializations — pick the one that matches where you're headed, and only detour into the others if a specific job description asks for it.

## Who This Collection Is For

| Reader | What You'll Get Here |
|---|---|
| Learners who've finished modules 00–03 and want to keep momentum | A structured next step instead of a random search |
| Career switchers targeting a Data Analyst / Data Scientist role | A path that lines up with what that interview loop actually tests |
| Analytics engineers | Warehouse, dbt, and modeling depth past what one repo's schema can show |
| Data engineers | Distributed-SQL and platform documentation (Spark, BigQuery, Redshift) |
| Backend / software engineers who touch SQL occasionally | Transactions, indexing, and schema-design material scoped to "enough to be dangerous safely" |
| Anyone with a SQL interview in the next 30–90 days | A staged plan in [`interview-resources.md`](interview-resources.md), not just a question bank |
| Contributors | A documented [Resource Card Template](#resource-card-template) and [Contribution Guidelines](#contribution-guidelines) so additions stay consistent |

## Role-Based Roadmaps

Each roadmap assumes the previous one is solid — Intermediate assumes Beginner is comfortable, and so on. The three specializations assume Advanced is done; pick one rather than doing all three back to back.

### Beginner Roadmap

**Goal:** read and write correct, simple SQL against a real schema.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`00_SAMPLE_DATABASE`](../00_SAMPLE_DATABASE/), [`01_FUNDAMENTALS`](../01_FUNDAMENTALS/), [`02_AGGREGATIONS`](../02_AGGREGATIONS/), [`03_JOINS`](../03_JOINS/) (inner/left) | [`documentation.md`](documentation.md) → your chosen dialect's official docs · [`books.md`](books.md) → *Essential Beginner Books* · [`youtube.md`](youtube.md) → *SQL Fundamentals* | 3–4 weeks |

**Exit criteria:** you can independently answer a business question with a `SELECT`, aggregate it, and join two tables without checking a syntax reference.

### Intermediate Roadmap

**Goal:** comfortable with multi-table logic, conditional transforms, and reusable query building blocks.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`03_JOINS`](../03_JOINS/) (right/full/cross), [`04_CASE_WHEN`](../04_CASE_WHEN/), [`05_SUBQUERIES`](../05_SUBQUERIES/), [`06_CTEs`](../06_CTEs/), [`07_WINDOW_FUNCTIONS`](../07_WINDOW_FUNCTIONS/), [`08_WINDOW_BUSINESS_CASES`](../08_WINDOW_BUSINESS_CASES/), [`09_DATE_FUNCTIONS`](../09_DATE_FUNCTIONS/) | [`books.md`](books.md) → *Intermediate Books* · [`blogs.md`](blogs.md) → analytics-engineering posts · [`documentation.md`](documentation.md) → window function references | 5–6 weeks |

**Exit criteria:** you can write a CTE-based query using window functions to answer a layered business question, the way it's actually done on a data team.

### Advanced Roadmap

**Goal:** understand what the database is doing under the query, not just what the query returns.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`10_STRING_FUNCTIONS`](../10_STRING_FUNCTIONS/) through [`16_QUERY_OPTIMIZATION`](../16_QUERY_OPTIMIZATION/) *(in progress — see [`ROADMAP.md`](../ROADMAP.md))* | [`books.md`](books.md) → *Database Internals, Query Optimization, Performance Tuning* · [`documentation.md`](documentation.md) → `EXPLAIN` / `EXPLAIN ANALYZE` sections · [`blogs.md`](blogs.md) → engineering blogs' performance postmortems | 6–8 weeks |

**Exit criteria:** you can read an execution plan, explain why a query is slow, and fix it with an index or a rewrite.

### Analytics Engineer Roadmap

**Goal:** turn raw tables into trusted, tested, documented models.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`06_CTEs`](../06_CTEs/), [`08_WINDOW_BUSINESS_CASES`](../08_WINDOW_BUSINESS_CASES/), [`12_ADVANCED_AGGREGATIONS`](../12_ADVANCED_AGGREGATIONS/), [`18_SQL_BUSINESS_CASE_STUDIES`](../18_SQL_BUSINESS_CASE_STUDIES/), plus [`projects/nagpurlens`](../projects/nagpurlens/) and [`projects/olist`](../projects/olist/) | [`blogs.md`](blogs.md) → dbt Blog, Snowflake Blog · [`documentation.md`](documentation.md) → dbt Documentation · [`books.md`](books.md) → *Analytics Engineering, Data Warehousing, Data Modeling* | 4–5 weeks on top of Intermediate |

**Exit criteria:** you can design a star schema, write a dbt-style modeled query, and defend a metric definition in a review.

### Data Engineer Roadmap

**Goal:** SQL that runs well at scale, across distributed engines, inside a pipeline.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`13_SET_OPERATORS`](../13_SET_OPERATORS/), [`14_VIEWS`](../14_VIEWS/), [`15_INDEXES`](../15_INDEXES/), [`16_QUERY_OPTIMIZATION`](../16_QUERY_OPTIMIZATION/), [`19_SQL_PROJECTS`](../19_SQL_PROJECTS/) | [`documentation.md`](documentation.md) → Apache Spark SQL, BigQuery, Redshift docs · [`books.md`](books.md) → *Database Internals, Data Warehousing* · [`blogs.md`](blogs.md) → Netflix / Uber / Airbnb engineering blogs | 5–6 weeks on top of Intermediate |

**Exit criteria:** you can reason about partitioning and distributed joins, and explain why the same query behaves differently on a 10-row table versus a 10-billion-row table.

### Backend Developer Roadmap

**Goal:** use SQL safely inside an application — transactions, integrity, concurrency.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`11_NULL_HANDLING_AND_DATA_CLEANING`](../11_NULL_HANDLING_AND_DATA_CLEANING/), [`14_VIEWS`](../14_VIEWS/), [`15_INDEXES`](../15_INDEXES/), schema-design practice in [`datasets/employee_management`](../datasets/employee_management/) | [`documentation.md`](documentation.md) → your dialect's transactions/locking docs · [`books.md`](books.md) → *Database Design, Reference Books* · [`blogs.md`](blogs.md) → PostgreSQL/MySQL official blogs | 4 weeks on top of Intermediate |

**Exit criteria:** you can design a normalized schema, wrap a multi-step write in a transaction, and explain an isolation level out loud.

### Interview Preparation Roadmap

**Goal:** perform, under time pressure, everything above.

| Handbook Modules (this repo) | Go Deeper in This Library | Est. Time |
|---|---|---|
| [`17_SQL_INTERVIEW_QUESTIONS`](../17_SQL_INTERVIEW_QUESTIONS/), [`exercises/interview`](../exercises/interview/), [`20_SQL_CHEATSHEET`](../20_SQL_CHEATSHEET/) | [`interview-resources.md`](interview-resources.md) — full roadmap with 30/60/90-day plans | 2–4 weeks, intensive |

**Exit criteria:** you can solve a fresh SQL question on a shared screen, out loud, in under 15 minutes.

## How Resources Were Selected

Selection followed a strict pecking order:

1. **Official documentation** for the technology in question — PostgreSQL, MySQL, Snowflake, BigQuery, dbt, and so on — because it's the only source guaranteed to stay correct as the product changes.
2. **Books from technical publishers** (O'Reilly, No Starch Press, Manning, Apress, Pragmatic Bookshelf) or self-published authors with a verifiable engineering track record, over generic "Learn SQL in 30 Days" titles.
3. **Engineering blogs from companies that run these databases at the scale being discussed** — a company's own post on a real performance incident carries more weight than a marketing blog's listicle.
4. **YouTube channels and creators with an actual teaching track record**, not just view counts.
5. **Everything else is excluded, not just deprioritized.** If a resource can't clear the first four tiers, it doesn't appear here, even if it's popular.

### Resource Card Template

Every entry in [`books.md`](books.md), [`blogs.md`](blogs.md), [`documentation.md`](documentation.md), [`youtube.md`](youtube.md), and [`interview-resources.md`](interview-resources.md) follows the same thirteen-field card, so you can compare resources at a glance instead of reading five different formats:

| Field | What It Tells You |
|---|---|
| Title | The resource's actual name |
| Author / Organization | Who wrote or maintains it |
| Category | Which shelf it belongs on (e.g. Query Optimization, Data Warehousing) |
| Difficulty | Beginner / Intermediate / Advanced |
| Best For | The one situation this resource is the right answer to |
| Why It Is Recommended | The specific reason it beat the alternatives |
| Key Topics Covered | What you'll actually learn |
| Estimated Time | Sized honestly — hours, days, or weeks |
| Official Website | Verified, current link (if applicable) |
| Free or Paid | No surprises |
| Prerequisites | What to finish first |
| Who Should Read It | The reader profile it's built for |
| Related SQL Handbook Modules | Which `0X_MODULE` folders in this repo pair with it |

## Quality Standards

Every resource that makes it into this library has to survive this checklist. If the honest answer to any of these is "no," it doesn't get added, or it gets fixed first.

- **Official or primary source first** — vendor documentation and primary technical writing outrank tutorials and course marketplaces.
- **Still maintained, or a deliberate classic** — either actively updated, or old enough that the ideas are timeless and that's stated explicitly.
- **Earns its slot over what's already listed** — no two resources cover the same ground without a stated reason both are worth keeping.
- **Comes with the full [Resource Card Template](#resource-card-template)**, not just a name and a link.
- **Free/Paid is disclosed up front**, and a paid resource is only listed if nothing free covers the same ground as well.
- **Would survive a link check today** — no archived pages, no dead redirects, no "used to be free" surprises.

## Build Status

✅ **Complete and diagram-reviewed.** All 12 resource files plus this
README are published, every file carries its own embedded diagram,
and the sizes/line counts in [What's In This Library](#whats-in-this-library)
are read directly off disk rather than estimated. The asset ledger in
[`assets/DIAGRAM_SPECS.md`](assets/DIAGRAM_SPECS.md) is kept in sync
with the actual contents of `assets/`.

## Module Checklist

- [x] All 12 resource files + README in place (13/13)
- [x] Every resource file carries one embedded, topic-specific diagram
- [x] `assets/DIAGRAM_SPECS.md` kept accurate against the actual asset folder
- [x] Six full-template files (`books.md` → `interview-resources.md`) use all 13 [Resource Card Template](#resource-card-template) fields
- [x] Seven lighter-format files (`newsletters.md` → `awesome-tools.md`) use a consistent scannable table
- [x] File sizes and line counts in the library table are read off disk, not estimated
- [x] Every roadmap links back to real, existing module folders in this repo

## Contribution Guidelines

This library accepts contributions the same way the rest of the Handbook does — see [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the full process. On top of that, a resource PR specifically needs:

- All 13 fields from the [Resource Card Template](#resource-card-template) filled in — not left as `TBD`
- A one-sentence answer to *"why this, and why now"* — what gap it fills that nothing else here fills
- A live link, checked the day of submission
- Placement in the correct file and category — see [Folder Structure](#folder-structure)
- Disclosure if you're the author or maintainer of the resource being added

> [!TIP]
> Found a broken link in an already-merged file? That's a faster PR than adding a new resource — fix the URL, or if the resource is genuinely gone, swap in the closest current equivalent and say so in the PR description.

## Folder Structure

```
Resources/
│
├── README.md                          ✅  You are here — navigation, philosophy, roadmaps
├── books.md                           ✅  Books with full annotations, by category
├── blogs.md                           ✅  Official + engineering blogs worth following
├── documentation.md                   ✅  Official documentation index, per dialect/platform
├── youtube.md                         ✅  Curated channels and playlists
├── interview-resources.md             ✅  Interview roadmap + 30/60/90-day plans
├── newsletters.md                     ✅  Curated newsletters (dbt, Postgres Weekly, etc.)
├── courses.md                         ✅  Free and paid SQL courses
├── datasets.md                        ✅  Public datasets for practice
├── playgrounds.md                     ✅  Online SQL playgrounds and sandboxes
├── certifications.md                  ✅  Recognized SQL / database certifications
├── communities.md                     ✅  Discord, Slack, Reddit, forums, mailing lists
├── awesome-tools.md                   ✅  SQL editors, ERD tools, database clients, formatters
└── assets/                            ✅  13 SVGs — one per file above, plus the README banner
    ├── banner.svg
    ├── 01_books.svg
    ├── 02_blogs.svg
    ├── 03_documentation.svg
    ├── 04_youtube.svg
    ├── 05_interview_resources.svg
    ├── 06_newsletters.svg
    ├── 07_courses.svg
    ├── 08_datasets.svg
    ├── 09_playgrounds.svg
    ├── 10_certifications.svg
    ├── 11_communities.svg
    ├── 12_awesome_tools.svg
    └── DIAGRAM_SPECS.md               ✅  Accurate asset ledger — what exists and what it shows
```

**Legend:** ✅ Available — all 13 content files and all 13 diagram assets are built. The core six ([`books.md`](books.md) → [`interview-resources.md`](interview-resources.md)) use the full [Resource Card Template](#resource-card-template); the second wave ([`newsletters.md`](newsletters.md) → [`awesome-tools.md`](awesome-tools.md)) uses a lighter table format proportional to their original one-line specs.

> [!IMPORTANT]
> The original folder listing had [`newsletters.md`](newsletters.md) twice, with two slightly different descriptions ("curated newsletters" and "weekly learning resources"). Merged into a single entry above. If a second, distinct file was actually intended — e.g. a reading-newsletters list separate from a weekly-digest tracker — flag it and it'll get split back out.

## Summary

This file is the map, not the territory. The resource cards themselves live in the twelve files listed in [Folder Structure](#folder-structure) above — six built to the full [Resource Card Template](#resource-card-template), seven built to a lighter table format proportional to their original one-line specs. Every one of those twelve now also carries its own diagram, and the map itself (this README) carries the library's banner.

Pair this library with the Handbook's own [`00_SAMPLE_DATABASE`](../00_SAMPLE_DATABASE/) onward, and you've got both the practice reps and the depth to back them up. Changes to this library are tracked in [`../CHANGELOG.md`](../CHANGELOG.md) alongside the rest of the Handbook.

**On verification, honestly:** root domains for official documentation, and any resource whose current status was genuinely uncertain (e.g. Mode Analytics' SQL tutorial migrating under the ThoughtSpot brand), were checked directly. The remaining few hundred entries — well-established published books, long-standing vendor and engineering blogs, well-known platforms and communities — were written from strong existing knowledge rather than an individual fetch per entry, since checking all of them individually wasn't practical in one pass. That's a reasonable bar for a first draft, not a substitute for the normal open-source cycle: if something's stale or a detail's off, it's a fast PR — see [Contribution Guidelines](#contribution-guidelines).

---

*Questions, or a resource to suggest? Open an issue using the templates in [`.github/ISSUE_TEMPLATE`](../.github/ISSUE_TEMPLATE/), or check [`../FAQ.md`](../FAQ.md).*
