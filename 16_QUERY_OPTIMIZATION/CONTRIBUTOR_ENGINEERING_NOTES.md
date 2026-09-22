# Contributor Engineering Notes

Extended guidance for contributors extending Module 16. For basic conventions, see [CONTRIBUTING.md](./CONTRIBUTING.md).

---

## Module Architecture

This module follows a three-layer documentation architecture:

```text
Layer 1: Lessons (01–07)          — Conceptual teaching, one topic per file
Layer 2: Engineering Documents      — Reference, checklists, cookbooks, incidents
Layer 3: Labs & Practice            — Performance_lab/, PRACTICE_PROBLEMS.md
```

When adding content, place it in the correct layer. Don't put reference material in lessons or teaching content in engineering docs.

---

## Content Quality Standards

Every paragraph must teach something an experienced SQL engineer doesn't already know, or explain something they know in a way that connects to production decision-making. Avoid:

- Restating SQL syntax covered in earlier modules
- Generic advice without engine-specific or scale-specific context
- "Best practice" claims without explaining *why*
- Duplicate explanations across files (cross-link instead)

---

## Adding a New Lesson

1. Choose the next number (`08_`, `09_`, etc.)
2. Create matching `.md` and `.sql` files
3. Follow section order from [CONTRIBUTING.md](./CONTRIBUTING.md)
4. Add mermaid diagram for execution flow or architecture
5. Include: Business Context, Real Company Usage, Interview Questions, Practice Challenges
6. Update README Learning Flow table and Diagram Gallery
7. Cross-link from relevant engineering documents

---

## Adding to Engineering Documents

| Document | Add when... |
|---|---|
| PERFORMANCE_SMELLS.md | New recurring code smell identified |
| REWRITE_COOKBOOK.md | New canonical rewrite pattern validated with benchmark |
| PRODUCTION_INCIDENTS.md | New realistic incident case study |
| CROSS_DATABASE_ENGINEERING.md | New engine support or behavior change |
| ENGINEERING_GLOSSARY.md | New term introduced in a lesson |

---

## SQL Lab Standards

Every `.sql` file must include:

```sql
-- BUSINESS OBJECTIVE: [one line]
-- PRODUCTION SCENARIO: [scale and context]
-- DATASET: [tables used]
-- PROBLEM STATEMENT: [business question]
-- PRODUCTION SQL: [the query]
-- ALTERNATIVE SQL: [rewrite or anti-pattern]
-- PERFORMANCE ANALYSIS: [what to look for in EXPLAIN]
-- INTERVIEW INSIGHT: [one Q&A]
-- FURTHER EXPERIMENTS: [2-3 suggestions]
```

---

## Diagram Standards

- SVG only, stored in `assets/diagrams/`
- Follow palette from [assets/DIAGRAM_SPEC.md](./assets/DIAGRAM_SPEC.md)
- Add specification to DIAGRAM_SPEC.md before creating SVG
- Include mermaid equivalent in the lesson `.md` file
- Update README Diagram Gallery table

---

## Review Checklist for PRs

- [ ] SQL runs against shared schema (or marked illustrative)
- [ ] Performance claims state assumed data volume
- [ ] No duplicate content — cross-links used instead
- [ ] Mermaid diagram included for complex flows
- [ ] Interview questions included
- [ ] Cross-references to related modules use relative links
- [ ] Engineering documents updated if new patterns introduced
- [ ] README updated if structure changed

---

## Related Documents

- [CONTRIBUTING.md](./CONTRIBUTING.md) — basic conventions
- [ENGINEERING_GUIDE.md](./ENGINEERING_GUIDE.md) — module architecture
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) — content quality standards
