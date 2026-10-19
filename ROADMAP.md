# 🗺️ SQL Engineering Handbook Roadmap

This document outlines the current status and future direction of the SQL Engineering Handbook project. It is a living roadmap: module READMEs contain the most up-to-date verification notes for each module.

---

## 📊 Project overview

The SQL Engineering Handbook is an evolving curriculum and documentation project that provides structured SQL learning material, worked examples, and a question bank for interview preparation. Some modules and resources are published in this repository; others are under active development.

This roadmap groups work into three pragmatic categories:

- Published & available in the repo — modules and resources you can open and use immediately (see module READMEs for verification details).
- Current maintenance & quality work — link validation, validator improvements, documentation synchronization, and targeted verification runs.
- Future enhancements — features that remain planned but are not yet implemented in the repository (video content, interactive sandboxes, broader engine-specific variants).

---

## ✅ Published / available

The following modules and documentation are present in this repository. For per-module verification details (what has been executed, what was reproduced, and what remains to be checked) consult each module's README.

- Core foundation modules (00–09): sample schema and fundamentals through date functions — published and stable.
- Mid-level modules (10–16): ongoing work; many lessons present in the repo but under active expansion.
- Transactions & Concurrency Control (Module 17): published at `17_TRANSACTIONS_AND_CONCURRENCY/` — ACID, isolation levels, locking, MVCC, deadlocks, anti-patterns, and runnable demos. See `17_TRANSACTIONS_AND_CONCURRENCY/README.md` for verification notes about which demo steps were reproduced and which steps require an owner-run validation.
- SQL Interview Questions (Module 18): published at `18_SQL_INTERVIEW_QUESTIONS/` — a 92-question bank with taxonomy, index, and a structural validator. See `18_SQL_INTERVIEW_QUESTIONS/FINAL_VALIDATION_REPORT.md` for the module's validation summary and owner-required verification steps.

---

## 🔧 Current maintenance and quality improvements

These are the repository-level, non-content tasks that are being tracked and updated as needed:

- Link validation: run module-level validators and repository-wide link checks to ensure cross-module references resolve.
- Validator improvements: refine the Module 18 structural validator so it distinguishes same-module links (checked) from cross-module links (checked when sibling modules exist) to avoid false positives for standalone copies.
- Documentation synchronization: keep top-level README, ROADMAP and CHANGELOG consistent with the files that actually exist in the repo.
- Module verification work (owner action): run the Module 18 validator from the repository root to verify cross-module links; optionally run targeted SQL demos in Module 17 on a MySQL 8.x instance to reproduce two-session concurrency behaviors.

---

## 🔮 Future enhancements (aspirational)

These items remain useful goals for the project; they are not presented here as committed release dates.

- Expand interview question coverage and answer rationales.
- Add optional MySQL/Postgres variants where engine differences materially affect examples.
- Improve performance and query-optimization content with additional worked examples and benchmarking guidance.
- Explore optional interactive practice sandboxes and video walkthroughs.

---

## 📌 Current priorities (example short list — no fixed dates)

| Priority | Task |
|----------|------|
| High | Finish link-validation across the repository (owner: maintainer) |
| High | Improve Module 18 validator messaging for cross-module link checks |
| Medium | Continue expanding Query Optimization material |
| Low | Add engine-specific examples (Postgres) as community contributions |

---

## 🤝 How to help

- Propose content via issues and label them `roadmap`.
- Volunteer for module work by commenting on roadmap issues.
- Run the module-level validators and report failures with the full command output.

---

## 📞 Questions or Suggestions?

- Open a discussion in the GitHub repo
- Report issues on the issues tab
- Contact the maintainer [@theammarngp-makes](https://github.com/theammarngp-makes)

---

<p align="center">
  <strong>Last Updated:</strong> 2026-10-19
</p>

<p align="center">
  <i>Part of the <a href="./">SQL Engineering Handbook</a></i>
</p>
