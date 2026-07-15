# 08 — Real-World Case Studies

**Module:** 14 — Views
**Previous:** [07 — View Performance](07_VIEW_PERFORMANCE.md) · **Next:** [09 — Interview Guide](09_INTERVIEW_GUIDE.md)

---

## Learning Objectives

- Design a multi-View architecture for a realistic reporting problem end to end
- Compare MySQL Views conceptually against Materialized Views in Postgres/Snowflake/BigQuery
- Understand how Views map onto the Analytics Engineering semantic-layer pattern used by dbt and BI tools
- Recognize enterprise reporting architecture patterns Views sit inside

## Concept Overview

This file steps back from single-View examples to full architecture: how a real analytics team lays out a View hierarchy across raw, staging, and reporting layers, and where MySQL's lack of native materialized Views changes the design compared to a warehouse-native platform.

## Why This Exists

Interviews for Analytics Engineering roles rarely ask "write a View" in isolation — they ask "design the reporting layer for X," expecting a candidate to reach for layered Views, discuss materialization tradeoffs, and reason about ownership and performance simultaneously. This file is deliberately architecture-first.

## Business Context — Case Study: SaaS Subscription Reporting

A SaaS company needs Finance to see MRR (Monthly Recurring Revenue) and Product to see churn — both derived from the same `saas_subscriptions` table, with materially different business rules (Finance excludes trialing accounts from MRR; Product includes them in churn cohort analysis).

## Where Companies Use It — Architecture Pattern

```
Layer 1 — Raw (base tables, never queried directly by BI):
    saas_subscriptions, saas_customers, saas_plans

Layer 2 — Staging Views (clean, standardize, no business rules yet):
    vw_stg_subscriptions   (NULL handling, type casting, status normalization)

Layer 3 — Reporting Views (business rules, one per governed metric):
    vw_mrr_by_month        (Finance definition: excludes TRIALING)
    vw_churn_cohort        (Product definition: includes TRIALING)

Layer 4 — BI Tool
    points at Layer 3 exclusively, never Layer 1 or 2
```

This is structurally identical to dbt's `staging/` → `intermediate/` → `marts/` convention — dbt materializes some of these as Views and some as physical tables depending on cost/freshness tradeoffs, but the layering discipline is the same regardless of tooling.

## Real Business Example

```sql
CREATE OR REPLACE VIEW vw_stg_subscriptions AS
SELECT
    subscription_id,
    customer_id,
    UPPER(TRIM(status)) AS status,          -- normalize inconsistent casing/whitespace
    COALESCE(mrr_amount, 0) AS mrr_amount,
    plan_started_at,
    plan_ended_at
FROM saas_subscriptions;

CREATE OR REPLACE VIEW vw_mrr_by_month AS
SELECT
    DATE_FORMAT(plan_started_at, '%Y-%m') AS revenue_month,
    SUM(mrr_amount) AS total_mrr
FROM vw_stg_subscriptions
WHERE status NOT IN ('TRIALING', 'CANCELLED')
GROUP BY DATE_FORMAT(plan_started_at, '%Y-%m');
```

## Syntax

No new syntax in this file — this is a composition and architecture exercise using everything from Modules 01–07.

## Visual Explanation

![View Dependencies](assets/view-dependencies.svg)

## Step-by-Step Walkthrough — Designing a Layered View Architecture

1. Identify raw tables and forbid BI tools from querying them directly.
2. Build one staging View per raw table, handling NULLs, type normalization, and naming consistency — no business logic yet.
3. Build one reporting View per governed metric, each with an explicit, documented business rule, reading only from staging Views.
4. Grant BI tool service accounts `SELECT` only on Layer 3.
5. Audit dependency chains (Module 06) before any Layer 1/2 schema change.

## Engineering Notes — Materialized Views: MySQL vs. the Rest

MySQL 8.0 has **no native materialized View**. Postgres (`CREATE MATERIALIZED VIEW`), Snowflake, and BigQuery all support a View variant that physically stores its result set and must be explicitly (or automatically, on some platforms) refreshed. The MySQL-native workarounds are:

- A physical **summary table**, refreshed on a schedule via `EVENT` or an external ETL/orchestration job (shown in Module 07).
- Application- or pipeline-level caching in front of a regular View.

The conceptual tradeoff is identical everywhere: a regular View trades storage cost for always-current data and re-computation cost on every read; a materialized View (or MySQL's manual summary-table equivalent) trades storage and staleness for read speed.

## Production Considerations

Enterprise reporting architectures typically version-control every View definition as a `.sql` file (exactly as this repository does), deploy them through CI/CD alongside schema migrations, and enforce the layering convention (raw → staging → reporting → BI) as a code-review policy, not just a suggestion.

## Performance Notes

Layered View architectures compound `TEMPTABLE` costs the same way discussed in Module 07 — production teams frequently promote the staging layer to physical tables (via ETL) once query volume justifies it, keeping only the reporting layer as true Views.

## Edge Cases

- Two reporting Views built on the same staging View but with contradictory business rules (Finance vs. Product MRR definitions above) are not a bug — they're the correct design, as long as both are explicitly documented and neither claims to be "the" MRR.
- A staging View that silently coalesces NULLs to 0 can mask upstream data quality issues from ever surfacing — pair with a data-quality monitoring layer, not blind trust.

## Best Practices

- Never let a BI tool query Layer 1 (raw tables) directly, ever.
- One reporting View per governed metric, explicitly named for the business question it answers, not the tables it touches.
- Document each reporting View's business rule divergence explicitly when two Views compute a "similar" metric differently.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| BI tool granted direct access to raw tables "just this once" | Layering discipline erodes; inconsistent metrics return |
| No staging layer, business rules mixed with cleaning logic | Reporting Views become unreadable and hard to test independently |
| Assuming MySQL has materialized Views | Design breaks when ported from Postgres/Snowflake documentation examples |

## Interview Questions

1. "Design a reporting layer for a company with Finance and Product needing different revenue definitions from the same raw data." — layered Views, shared staging, divergent reporting Views, documented rules.
2. "Does MySQL support materialized Views?" — No; the practical equivalent is a scheduled-refresh physical summary table.
3. "Why separate staging Views from reporting Views instead of one big View?" — separates data-quality/normalization concerns from business-rule concerns, improving testability and reuse.

## Summary

Production View architecture is layered: raw tables are never exposed directly, staging Views normalize data, and reporting Views encode governed, documented business rules for BI consumption. MySQL's lack of native materialized Views means the read-speed/staleness tradeoff is handled manually via summary tables rather than a built-in refresh mechanism.

## Practice Challenges

1. Design the full View layer (staging + 2 divergent reporting Views) for the SaaS MRR/churn case study above, including explicit `WITH CHECK OPTION` where applicable.
2. Write the summary-table refresh pattern (an `EVENT`) that would keep a MySQL "materialized view equivalent" of `vw_mrr_by_month` updated hourly.

## Further Reading

- PostgreSQL Documentation — [Materialized Views](https://www.postgresql.org/docs/current/rules-materializedviews.html)
- dbt Documentation — [Materializations](https://docs.getdbt.com/docs/build/materializations)
- MySQL 8.0 Reference Manual — [Using the Event Scheduler](https://dev.mysql.com/doc/refman/8.0/en/event-scheduler.html)
