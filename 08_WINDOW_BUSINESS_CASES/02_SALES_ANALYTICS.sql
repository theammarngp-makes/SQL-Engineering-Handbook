-- ============================================================================
-- MODULE      : 08_WINDOW_FUNCTION_APPLICATIONS
-- CHAPTER     : 02_SALES_ANALYTICS
-- OBJECTIVE   : Apply window functions to revenue reporting - leaderboards,
--               running totals, moving averages, and period-over-period
--               growth (MoM / YoY).
--
-- ASSUMED SCHEMA
-- ----------------------------------------------------------------------------
-- sales        (sale_id PK, salesperson_id FK, region_id FK, sale_date, revenue)
-- salespeople  (salesperson_id PK, salesperson_name, region_id FK)
-- regions      (region_id PK, region_name)
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 : Sales Leaderboards
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Sales leadership wants to know the top-performing salesperson each
--   month, and a regional leaderboard for the current quarter.
-- ============================================================================

-- Q1. Top salesperson per month, reusable across any month in the table.
WITH monthly_revenue AS (
    SELECT
        s.salesperson_id,
        sp.salesperson_name,
        DATE_TRUNC('month', s.sale_date) AS sale_month,
        SUM(s.revenue)                   AS monthly_total
    FROM sales s
    JOIN salespeople sp
        ON s.salesperson_id = sp.salesperson_id
    GROUP BY s.salesperson_id, sp.salesperson_name, DATE_TRUNC('month', s.sale_date)
),
ranked_monthly AS (
    SELECT
        salesperson_id,
        salesperson_name,
        sale_month,
        monthly_total,
        ROW_NUMBER() OVER (
            PARTITION BY sale_month
            ORDER BY monthly_total DESC
        ) AS monthly_rank
    FROM monthly_revenue
)
SELECT
    salesperson_id,
    salesperson_name,
    sale_month,
    monthly_total
FROM ranked_monthly
WHERE monthly_rank = 1
ORDER BY sale_month;


-- Q2. Regional leaderboard for the current quarter, comparing RANK() and
--     DENSE_RANK() so a dashboard can toggle tie-handling behavior.
WITH regional_revenue AS (
    SELECT
        r.region_id,
        r.region_name,
        SUM(s.revenue) AS quarter_total
    FROM sales s
    JOIN regions r
        ON s.region_id = r.region_id
    WHERE s.sale_date >= DATE_TRUNC('quarter', CURRENT_DATE)
    GROUP BY r.region_id, r.region_name
)
SELECT
    region_id,
    region_name,
    quarter_total,
    RANK() OVER (ORDER BY quarter_total DESC)       AS region_rank,
    DENSE_RANK() OVER (ORDER BY quarter_total DESC) AS region_dense_rank
FROM regional_revenue
ORDER BY quarter_total DESC;


-- ============================================================================
-- SCENARIO 2 : Running Revenue Toward Target
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Leadership tracks running (cumulative) revenue per salesperson toward
--   a quarterly quota, updated with every new transaction.
-- ============================================================================

-- Q3. Running total revenue per salesperson, ordered chronologically.
--     Explicit frame clause used deliberately - do not rely on the
--     engine's implicit default frame.
SELECT
    s.salesperson_id,
    sp.salesperson_name,
    s.sale_date,
    s.revenue,
    SUM(s.revenue) OVER (
        PARTITION BY s.salesperson_id
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue
FROM sales s
JOIN salespeople sp
    ON s.salesperson_id = sp.salesperson_id
ORDER BY s.salesperson_id, s.sale_date;


-- Q4. Company-wide running revenue (no partition) with a fixed quarterly
--     target, to show progress toward a single company-wide number.
SELECT
    s.sale_date,
    s.revenue,
    SUM(s.revenue) OVER (
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS company_running_revenue,
    1000000 AS quarterly_target,                       -- example target value
    ROUND(
        100.0 * SUM(s.revenue) OVER (
            ORDER BY s.sale_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / 1000000.0,
        2
    ) AS pct_of_target
FROM sales s
ORDER BY s.sale_date;


-- ============================================================================
-- SCENARIO 3 : Period-over-Period Growth (MoM / YoY)
-- ----------------------------------------------------------------------------
-- Business explanation:
--   The board wants Month-over-Month and Year-over-Year revenue growth,
--   computed from a monthly revenue rollup.
-- ============================================================================

-- Q5. Month-over-Month (MoM) growth, company-wide.
WITH monthly_totals AS (
    SELECT
        DATE_TRUNC('month', sale_date) AS sale_month,
        SUM(revenue)                   AS monthly_total
    FROM sales
    GROUP BY DATE_TRUNC('month', sale_date)
)
SELECT
    sale_month,
    monthly_total,
    LAG(monthly_total) OVER (ORDER BY sale_month) AS prior_month_total,
    ROUND(
        100.0 * (monthly_total - LAG(monthly_total) OVER (ORDER BY sale_month))
        / NULLIF(LAG(monthly_total) OVER (ORDER BY sale_month), 0),
        2
    ) AS mom_growth_pct
FROM monthly_totals
ORDER BY sale_month;


-- Q6. Year-over-Year (YoY) growth, comparing each month to the same month
--     one year prior - offset of 12 rows on a monthly grain.
WITH monthly_totals AS (
    SELECT
        DATE_TRUNC('month', sale_date) AS sale_month,
        SUM(revenue)                   AS monthly_total
    FROM sales
    GROUP BY DATE_TRUNC('month', sale_date)
)
SELECT
    sale_month,
    monthly_total,
    LAG(monthly_total, 12) OVER (ORDER BY sale_month) AS same_month_last_year,
    ROUND(
        100.0 * (monthly_total - LAG(monthly_total, 12) OVER (ORDER BY sale_month))
        / NULLIF(LAG(monthly_total, 12) OVER (ORDER BY sale_month), 0),
        2
    ) AS yoy_growth_pct
FROM monthly_totals
ORDER BY sale_month;


-- ============================================================================
-- SCENARIO 4 : Trend Smoothing & Sales Velocity
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Daily revenue is noisy. Leadership wants a 7-day moving average for a
--   smoother trend line, and a way to flag sales reps who have gone
--   unusually long without closing a deal.
-- ============================================================================

-- Q7. 7-day moving average of daily company-wide revenue.
WITH daily_totals AS (
    SELECT
        sale_date,
        SUM(revenue) AS daily_total
    FROM sales
    GROUP BY sale_date
)
SELECT
    sale_date,
    daily_total,
    ROUND(
        AVG(daily_total) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7day
FROM daily_totals
ORDER BY sale_date;


-- Q8. Sales gap analysis: days between consecutive deals per salesperson,
--     used to flag reps who may be at risk of missing quota.
SELECT
    s.salesperson_id,
    sp.salesperson_name,
    s.sale_date,
    LAG(s.sale_date) OVER (
        PARTITION BY s.salesperson_id
        ORDER BY s.sale_date
    ) AS previous_sale_date,
    s.sale_date - LAG(s.sale_date) OVER (
        PARTITION BY s.salesperson_id
        ORDER BY s.sale_date
    ) AS days_since_last_sale
FROM sales s
JOIN salespeople sp
    ON s.salesperson_id = sp.salesperson_id
ORDER BY s.salesperson_id, s.sale_date;

-- ============================================================================
-- END OF CHAPTER 02 - SALES ANALYTICS
-- ============================================================================
