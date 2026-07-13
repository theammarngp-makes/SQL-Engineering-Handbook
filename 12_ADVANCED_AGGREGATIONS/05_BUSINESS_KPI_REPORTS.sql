-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   05 · BUSINESS KPI REPORTS
-- ============================================================================
-- Business Objective:
--   Compute named, board-level SaaS metrics (MRR waterfall, churn rate,
--   ARPU) as precise, reusable monthly KPI reports.
--
-- Dataset Used (SaaS domain):
--   customers      (customer_id PK, customer_name, signup_date)
--   plans          (plan_id PK, plan_name, monthly_price)
--   subscriptions  (subscription_id PK, customer_id FK, plan_id FK, status)
--   billing_events (event_id PK, customer_id FK, event_date, event_type,
--                   amount)   -- event_type IN ('NEW','EXPANSION',
--                                                'CONTRACTION','CHURN')
--
-- Dialect notes:
--   DATE_TRUNC('month', col) is PostgreSQL syntax. The MySQL 8+ equivalent
--   used inline below is DATE_FORMAT(col, '%Y-%m-01'). Both are noted at
--   each usage.
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 — MRR Waterfall
-- Business Context:
--   Finance needs the standard SaaS MRR waterfall for the monthly board
--   deck: new, expansion, contraction, and churned MRR, per month.
--
-- Business Questions:
--   - How much new MRR was added each month?
--   - How much expansion and contraction MRR occurred?
--   - How much MRR was lost to churn?
--   - What is net new MRR overall?
-- ============================================================================

SELECT
    DATE_TRUNC('month', be.event_date)                              AS billing_month,
    -- MySQL 8+: DATE_FORMAT(be.event_date, '%Y-%m-01') AS billing_month,
    SUM(CASE WHEN be.event_type = 'NEW'
             THEN be.amount ELSE 0 END)                              AS new_mrr,
    SUM(CASE WHEN be.event_type = 'EXPANSION'
             THEN be.amount ELSE 0 END)                                AS expansion_mrr,
    SUM(CASE WHEN be.event_type = 'CONTRACTION'
             THEN be.amount ELSE 0 END)                                  AS contraction_mrr,
    SUM(CASE WHEN be.event_type = 'CHURN'
             THEN be.amount ELSE 0 END)                                   AS churned_mrr,
    SUM(be.amount)                                                        AS net_new_mrr
FROM billing_events AS be
GROUP BY DATE_TRUNC('month', be.event_date)
ORDER BY billing_month;

-- Explanation:
--   Each waterfall component is a conditional SUM keyed on event_type,
--   matching the exact taxonomy finance uses to describe MRR movement.
--   net_new_mrr sums ALL event amounts unconditionally, relying on the
--   source data convention that contraction and churn amounts are already
--   stored as negative values -- confirm this sign convention with the
--   billing system before reusing this pattern elsewhere.
--
-- Engineering Notes:
--   new_mrr + expansion_mrr + contraction_mrr + churned_mrr must always
--   equal net_new_mrr for every row -- a useful automated reconciliation
--   check for this report.
--
-- Optimization Notes:
--   Index billing_events(event_date, event_type) to support both the
--   time-bucketing and every conditional SUM from a single scan.
--
-- Expected Output (illustrative):
--   billing_month | new_mrr | expansion_mrr | contraction_mrr | churned_mrr | net_new_mrr
--   2026-05-01      | 42,000   | 11,300         | -3,200            | -8,900        | 41,200
--   2026-06-01      | 39,500   | 9,800           | -2,100            | -6,400        | 40,800


-- ============================================================================
-- SCENARIO 2 — Logo Churn Rate
-- Business Context:
--   The customer success team tracks "logo churn" -- the percentage of
--   distinct customers who churned in a month -- separately from revenue
--   churn, since a small number of large accounts churning can distort the
--   revenue figure without reflecting broad customer dissatisfaction.
--
-- Business Questions:
--   - How many distinct customers churned each month?
--   - What percentage of the active customer base did they represent?
-- ============================================================================

WITH monthly_active_base AS (
    SELECT
        DATE_TRUNC('month', be.event_date)                          AS billing_month,
        COUNT(DISTINCT CASE WHEN be.event_type != 'CHURN'
                            THEN be.customer_id END)                 AS active_customers,
        COUNT(DISTINCT CASE WHEN be.event_type = 'CHURN'
                            THEN be.customer_id END)                  AS churned_customers
    FROM billing_events AS be
    GROUP BY DATE_TRUNC('month', be.event_date)
)
SELECT
    billing_month,
    active_customers,
    churned_customers,
    ROUND(100.0 * churned_customers
          / NULLIF(active_customers + churned_customers, 0), 2)        AS logo_churn_rate_pct
FROM monthly_active_base
ORDER BY billing_month;

-- Explanation:
--   COUNT(DISTINCT CASE WHEN ...) combines conditional aggregation (Topic
--   03) with DISTINCT counting (Topic 02) to count unique customers per
--   condition, rather than counting events -- a customer with several
--   billing events in one month must still only count once.
--   The denominator (active_customers + churned_customers) represents the
--   customer base at the start of the month; this specific definition
--   should be confirmed against the company's official metrics glossary
--   before being reported externally.
--
-- Engineering Notes:
--   This is deliberately built as a CTE first, then a final SELECT, to
--   keep the conditional-aggregation logic and the ratio calculation
--   readable as two separate steps -- a common pattern once a KPI query
--   grows beyond two or three conditional metrics.
--
-- Optimization Notes:
--   COUNT(DISTINCT ...) is more expensive than COUNT(...) since the engine
--   must deduplicate customer_id values per condition; on a very large
--   billing_events table, consider pre-deduplicating in a staging table
--   refreshed nightly rather than computing DISTINCT counts on every
--   dashboard load.
--
-- Expected Output (illustrative):
--   billing_month | active_customers | churned_customers | logo_churn_rate_pct
--   2026-06-01      | 1,180              | 24                   | 1.99


-- ============================================================================
-- SCENARIO 3 — Average Revenue Per Account (ARPU)
-- Business Context:
--   Leadership wants monthly ARPU (average revenue per active account) to
--   track alongside MRR, since MRR growth driven purely by adding low-value
--   accounts looks different from ARPU-driven growth.
--
-- Business Questions:
--   - What is total recurring revenue per month?
--   - How many distinct active accounts generated it?
--   - What is the resulting average revenue per account?
-- ============================================================================

SELECT
    DATE_TRUNC('month', be.event_date)                              AS billing_month,
    SUM(CASE WHEN be.event_type != 'CHURN'
             THEN be.amount ELSE 0 END)                               AS total_recurring_revenue,
    COUNT(DISTINCT CASE WHEN be.event_type != 'CHURN'
                        THEN be.customer_id END)                        AS active_accounts,
    ROUND(SUM(CASE WHEN be.event_type != 'CHURN'
                   THEN be.amount ELSE 0 END)
          / NULLIF(COUNT(DISTINCT CASE WHEN be.event_type != 'CHURN'
                                       THEN be.customer_id END), 0), 2)   AS arpu
FROM billing_events AS be
GROUP BY DATE_TRUNC('month', be.event_date)
ORDER BY billing_month;

-- Explanation:
--   ARPU is composed directly from two conditional aggregates already
--   defined earlier in this file's pattern -- total recurring revenue and
--   active account count -- divided into a single ratio, guarded with
--   NULLIF for a hypothetical zero-account month.
--
-- Engineering Notes:
--   Both the numerator and denominator use the identical condition
--   (event_type != 'CHURN'); keeping that condition textually identical in
--   both places (rather than approximating it) is what makes the resulting
--   ratio numerically sound -- a subtle but important consistency check in
--   any ratio KPI.
--
-- Optimization Notes:
--   No new joins beyond Scenario 2 -- this report can share a materialized
--   monthly summary table with the other KPIs in this file if scheduled
--   together.
--
-- Expected Output (illustrative):
--   billing_month | total_recurring_revenue | active_accounts | arpu
--   2026-06-01      | 187,400.00                | 1,180             | 158.81
