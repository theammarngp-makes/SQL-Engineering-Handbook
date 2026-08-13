# Changelog

All notable changes to the SQL Engineering Handbook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- Expanded Window Business Cases module with additional chapters and diagrams (HR Analytics chapter and visual assets). (e015ecc — 2026-08-12)
- Expanded NULL Handling & Data Cleaning module with visual explanation of three-valued logic and validation guidance. (aed8596 — 2026-08-11)
- Substantially expanded the CTEs module with engineering patterns, diagrams, runnable examples and interview tips. (ffe7ff2 — 2026-08-06)
- Added CASE_WHEN sample schema and seed data (shared schema used across lessons). (4de05c6 — 2026-08-07)
- Added/expanded Aggregations content and assets (new banner image, analytics patterns and examples). (5c11c6a, 88a9ef — 2026-08-07–08)
- Expanded Window Functions lessons (ROW_NUMBER, navigation improvements, diagrams). (24b8a9e — 2026-08-08)
- Resource library: improved Resources/README table and links to curated files (books, certifications, communities, tools). (6ef3561, f346550 — 2026-08-06)
- Added several module assets and diagrams to support lessons (CTE flow, row-number diagrams, HR leaderboard visuals). (ffe7ff2, 24b8a9e, e015ecc — Aug 6–12, 2026)

### Changed

- Multiple README updates across the repo: added live GH Pages link, adjusted banners, badges, and navigation for improved presentation and module discoverability. (fcd6556, 259918a, fd0ca21, f346550 — 2026-08-06–11)
- Replaced SVG banner for Aggregations with PNG and updated module README references. (c9ab3ca, 1fc3d69 — 2026-08-07–08)
- Standardized some module README headings and corrected internal links/navigation (various README edits to align module naming and paths). (7679a2d, 9436e62, 56dc371 — 2026-08-06–10)
- Updated .gitignore to include common macOS artifacts (.DS_Store) and minor housekeeping changes. (5c11c6a — 2026-08-07)

### Removed

- Removed or simplified some decorative badges and redundant README snippets to reduce clutter and improve readability. (4a3f4a0, fd0ca21 — 2026-08-06)
- Clean-up of temporary/legacy file references in Resources and module READMEs (small pruning across commits). (f346550, 6ef3561 — 2026-08-06)

### Fixed

- README formatting and avatar/style adjustments (rounding/corrected attributes) and other small presentation fixes. (c83ff6b, c99c601, fb92943 — 2026-08-07–08)
- Corrected module file references and naming inconsistencies introduced during expansion (e.g., module link paths, consistent module folder names). (7679a2d, 4de05c6 — 2026-08-07–10)
- Incorporated minor query / example corrections that surfaced while expanding lessons (small fixes within lesson files). (multiple commits Aug 6–12, 2026)

### Documentation

- Added 00_Sample_Schema.sql (shared sample schema + seed data) to support hands-on lessons and reproducible examples. (4de05c6 — 2026-08-07)
- Added diagrams and assets referenced by new lessons (CTE flow diagrams, ROW_NUMBER visuals, HR leaderboard). (ffe7ff2, 24b8a9e, e015ecc — Aug 6–12, 2026)
- Updated Resources/README to include a structured table of resource files (books, certifications, communities, tools). (6ef3561, f346550 — 2026-08-06)
- Continued README and handbook navigation refinements to make module progression clearer for learners and contributors. (fcd6556, 259918a — 2026-08-06–11)

---

## [1.1.0] - 2026-07-26

### Added

- Advanced Aggregations module with business-case examples and expanded Aggregations content. (Jul 20, 2026)
- Views module. (Jul 15, 2026)
- Set Operators module. (Jul 14, 2026)
- String Functions module and status updated to "Complete". (Jul 10, 2026)
- NULL Handling and Data Cleaning module. (Jul 11, 2026)
- Complete Date Functions module and module README. (Jul 08, 2026)
- Window Functions materials and business cases:
  - Comprehensive Window Functions README and learning objectives. (Jul 03, 2026)
  - ROW_NUMBER, RANK, and DENSE_RANK examples and SQL files. (Jul 03–07, 2026)
  - PARTITION BY documentation and advanced window-function lessons. (Jul 04, 2026)
  - Banking & finance business-case studies for window functions. (Jul 06–07, 2026)
- GitHub Actions workflows and repository infrastructure files (linting, templates). (Jul 08, 2026)

### Changed

- Revised README across multiple commits for improved presentation, banners, images, badges, and navigation. (Jun 30 – Jul 23, 2026)
- Reorganized repository structure and module numbering for clarity; renamed files where necessary. (Jul 10–13, 2026)
- DATABASE_SCHEMA.md revised for clarity and improved table descriptions. (Jul 05, 2026)
- ROADMAP.md refined with clearer examples and release planning. (Jul 03, 2026)

### Removed

- Deleted obsolete directories and files: Resources (multiple files like Resources/x.md), X-Schema directory, and 09_Business_Case_Studies. (Jul 10–26, 2026)
- Cleaned up branding/assets: removed .DS_Store files and adjusted assets as needed. (Jun 30 – Jul 12, 2026)

### Fixed

- Fixed typos and link references (e.g., PARTITON → PARTITION; Module 05 link fix). (Jul 04, Jul 20, 2026)

### Documentation

- Added ARCHITECTURE.md and STYLE_GUIDE.md to document repo architecture and standards. (Jul 08, 2026)
- Created SUPPORT.md and FAQ.md to help contributors and users. (Jul 03, 2026)
- Created CHANGELOG.md (initial) and updated it with recent additions. (Jul 03, 2026)
- Added CODEOWNERS, markdownlint config, PR/issue templates, and contributor guidance. (Jul 08, 2026)

---

## [1.0.0] - 2026-07-03

### Added

#### Initial Public Release

##### Module 1 — Fundamentals

- Core SQL querying fundamentals
- Documentation and SQL examples

##### Module 2 — Aggregations

- Aggregate functions
- GROUP BY and HAVING
- Practice examples

##### Module 3 — Joins

- INNER, LEFT, RIGHT, FULL OUTER and CROSS JOIN
- Real-world join scenarios

##### Module 4 — Subqueries

- Scalar subqueries
- Correlated subqueries

##### Module 5 — CASE WHEN Statements

- Simple CASE
- Searched CASE
- Business logic implementations
- Conditional aggregations

##### Module 6 — Common Table Expressions (CTEs)

- Basic CTEs
- Multiple CTEs
- Recursive CTEs
- Advanced CTE patterns

##### Module 7 — Window Functions

- ROW_NUMBER()
- RANK()
- DENSE_RANK()
- LAG()
- LEAD()
- Running totals
- PARTITION BY
- Window frame specifications

### Documentation

- Project README
- Module documentation
- Custom SQL schema
- Learning resources
- Repository navigation
- MIT License

### Repository Features

- Engineering-first learning structure
- Production-inspired SQL examples
- Progressive learning roadmap
- Business-oriented practice problems
- Common mistakes and best practices
- Interview-focused explanations
- Modular repository organization
- Consistent documentation standards

---

## Types of Changes

- **Added** — New features or documentation
- **Changed** — Improvements to existing content
- **Deprecated** — Features scheduled for removal
- **Removed** — Removed functionality
- **Fixed** — Bug fixes and corrections
- **Security** — Security-related changes

---

## Contributing

To contribute to this changelog:
1. Follow the format above
2. Group changes by type (Added, Changed, etc.)
3. Link to relevant issues or pull requests when applicable
4. Ensure accuracy of dates and version numbers

For more information, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Support

If you find any errors in the changelog or have suggestions:
- Open an issue on GitHub
- Submit a pull request with corrections
- Reach out via the discussions tab

Your feedback helps us maintain accurate documentation.

---

<p align="center">
  <i>Part of the <a href="./">SQL Engineering Handbook</a></i>
</p>
