-- ============================================================================
-- MODULE      : 08_WINDOW_FUNCTION_APPLICATIONS
-- CHAPTER     : 05_FINANCE
-- OBJECTIVE   : Apply window functions to budgeting and profitability
--               analysis - profit/expense leaderboards, running year-to-date
--               profit, budget variance, and expense volatility detection.
--
-- ASSUMED SCHEMA
-- ----------------------------------------------------------------------------
-- financial_transactions (transaction_id PK, department_id FK, transaction_date,
--                          amount, transaction_type)  -- 'revenue' | 'expense'
-- departments             (department_id PK, department_name)
-- budgets                 (budget_id PK, department_id FK, budget_month,
--                          budgeted_amount, budget_type) -- 'revenue' | 'expense'
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 : Profit & Expense Leaderboards
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Leadership wants to know which departments contribute the most profit,
--   and which are the largest cost centers, for the current quarter.
-- ============================================================================

-- Q1. Rank departments by profit contribution (revenue - expense) for the
--     current quarter.
WITH quarterly_profit AS (
    SELECT
        d.department_id,
        d.department_name,
        SUM(CASE WHEN ft.transaction_type = 'revenue' THEN ft.amount ELSE 0 END)
            - SUM(CASE WHEN ft.transaction_type = 'expense' THEN ft.amount ELSE 0 END)
            AS quarter_profit
    FROM financial_transactions ft
    JOIN departments d
        ON ft.department_id = d.department_id
    WHERE ft.transaction_date >= DATE_TRUNC('quarter', CURRENT_DATE)
    GROUP BY d.department_id, d.department_name
)
SELECT
    department_id,
    department_name,
    quarter_profit,
    RANK() OVER (ORDER BY quarter_profit DESC) AS profit_rank
FROM quarterly_profit
ORDER BY profit_rank;


-- Q2. Rank departments by total expense - identifying the largest cost
--     centers for the current quarter.
WITH quarterly_expense AS (
    SELECT
        d.department_id,
        d.department_name,
        SUM(ft.amount) AS quarter_expense
    FROM financial_transactions ft
    JOIN departments d
        ON ft.department_id = d.department_id
    WHERE ft.transaction_type = 'expense'
      AND ft.transaction_date >= DATE_TRUNC('quarter', CURRENT_DATE)
    GROUP BY d.department_id, d.department_name
)
SELECT
    department_id,
    department_name,
    quarter_expense,
    DENSE_RANK() OVER (ORDER BY quarter_expense DESC) AS expense_rank
FROM quarterly_expense
ORDER BY expense_rank;


-- ============================================================================
-- SCENARIO 2 : Running Year-to-Date Profit
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Leadership tracks cumulative profit through the fiscal year, per
--   department and company-wide, resetting correctly at each fiscal
--   year boundary.
-- ============================================================================

-- Q3. Running year-to-date profit per department, partitioned by both
--     department AND fiscal year so the running total resets each January.
WITH monthly_profit AS (
    SELECT
        d.department_id,
        d.department_name,
        DATE_TRUNC('month', ft.transaction_date)  AS profit_month,
        EXTRACT(YEAR FROM ft.transaction_date)    AS fiscal_year,
        SUM(CASE WHEN ft.transaction_type = 'revenue' THEN ft.amount ELSE 0 END)
            - SUM(CASE WHEN ft.transaction_type = 'expense' THEN ft.amount ELSE 0 END)
            AS monthly_profit
    FROM financial_transactions ft
    JOIN departments d
        ON ft.department_id = d.department_id
    GROUP BY d.department_id, d.department_name,
             DATE_TRUNC('month', ft.transaction_date),
             EXTRACT(YEAR FROM ft.transaction_date)
)
SELECT
    department_id,
    department_name,
    profit_month,
    monthly_profit,
    SUM(monthly_profit) OVER (
        PARTITION BY department_id, fiscal_year
        ORDER BY profit_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ytd_profit
FROM monthly_profit
ORDER BY department_name, profit_month;


-- Q4. Company-wide running year-to-date profit (no department partition),
--     for a top-level executive summary.
WITH monthly_profit_company AS (
    SELECT
        DATE_TRUNC('month', ft.transaction_date) AS profit_month,
        EXTRACT(YEAR FROM ft.transaction_date)   AS fiscal_year,
        SUM(CASE WHEN ft.transaction_type = 'revenue' THEN ft.amount ELSE 0 END)
            - SUM(CASE WHEN ft.transaction_type = 'expense' THEN ft.amount ELSE 0 END)
            AS monthly_profit
    FROM financial_transactions ft
    GROUP BY DATE_TRUNC('month', ft.transaction_date), EXTRACT(YEAR FROM ft.transaction_date)
)
SELECT
    profit_month,
    monthly_profit,
    SUM(monthly_profit) OVER (
        PARTITION BY fiscal_year
        ORDER BY profit_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS company_ytd_profit
FROM monthly_profit_company
ORDER BY profit_month;


-- ============================================================================
-- SCENARIO 3 : Budget vs. Actual Variance
-- ----------------------------------------------------------------------------
-- Business explanation:
--   FP&A needs to compare actual monthly expense to budgeted expense, by
--   department, both in absolute and percentage terms.
-- ============================================================================

-- Q5. Monthly actual-vs-budget expense variance per department.
--     Variance convention: actual - budget (positive = over budget).
WITH monthly_actual_expense AS (
    SELECT
        d.department_id,
        d.department_name,
        DATE_TRUNC('month', ft.transaction_date) AS budget_month,
        SUM(ft.amount) AS actual_expense
    FROM financial_transactions ft
    JOIN departments d
        ON ft.department_id = d.department_id
    WHERE ft.transaction_type = 'expense'
    GROUP BY d.department_id, d.department_name, DATE_TRUNC('month', ft.transaction_date)
)
SELECT
    a.department_id,
    a.department_name,
    a.budget_month,
    a.actual_expense,
    b.budgeted_amount,
    a.actual_expense - b.budgeted_amount AS variance_amount,
    ROUND(
        100.0 * (a.actual_expense - b.budgeted_amount) / NULLIF(b.budgeted_amount, 0),
        2
    ) AS variance_pct
FROM monthly_actual_expense a
JOIN budgets b
    ON a.department_id = b.department_id
   AND a.budget_month = b.budget_month
   AND b.budget_type = 'expense'
ORDER BY a.department_name, a.budget_month;


-- Q6. Rank departments by budget variance percentage (largest overspend
--     first) for the most recently closed month - surfaces departments
--     proportionally furthest off plan, regardless of department size.
WITH monthly_actual_expense AS (
    SELECT
        d.department_id,
        d.department_name,
        DATE_TRUNC('month', ft.transaction_date) AS budget_month,
        SUM(ft.amount) AS actual_expense
    FROM financial_transactions ft
    JOIN departments d
        ON ft.department_id = d.department_id
    WHERE ft.transaction_type = 'expense'
    GROUP BY d.department_id, d.department_name, DATE_TRUNC('month', ft.transaction_date)
),
variance AS (
    SELECT
        a.department_id,
        a.department_name,
        a.budget_month,
        a.actual_expense,
        b.budgeted_amount,
        ROUND(
            100.0 * (a.actual_expense - b.budgeted_amount) / NULLIF(b.budgeted_amount, 0),
            2
        ) AS variance_pct
    FROM monthly_actual_expense a
    JOIN budgets b
        ON a.department_id = b.department_id
       AND a.budget_month = b.budget_month
       AND b.budget_type = 'expense'
    WHERE a.budget_month = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
)
SELECT
    department_id,
    department_name,
    actual_expense,
    budgeted_amount,
    variance_pct,
    RANK() OVER (ORDER BY variance_pct DESC) AS overspend_rank
FROM variance
ORDER BY overspend_rank;


-- ============================================================================
-- SCENARIO 4 : Expense Volatility Detection
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Finance wants to flag departments whose expenses swing significantly
--   from one month to the next, beyond a fixed materiality threshold.
-- ============================================================================

-- Q7. Month-over-month expense change per department, flagged when the
--     swing exceeds a 20% materiality threshold in either direction.
WITH monthly_expense AS (
    SELECT
        d.department_id,
        d.department_name,
        DATE_TRUNC('month', ft.transaction_date) AS expense_month,
        SUM(ft.amount) AS monthly_expense
    FROM financial_transactions ft
    JOIN departments d
        ON ft.department_id = d.department_id
    WHERE ft.transaction_type = 'expense'
    GROUP BY d.department_id, d.department_name, DATE_TRUNC('month', ft.transaction_date)
),
expense_with_prior AS (
    SELECT
        department_id,
        department_name,
        expense_month,
        monthly_expense,
        LAG(monthly_expense) OVER (
            PARTITION BY department_id
            ORDER BY expense_month
        ) AS prior_month_expense
    FROM monthly_expense
)
SELECT
    department_id,
    department_name,
    expense_month,
    monthly_expense,
    prior_month_expense,
    ROUND(
        100.0 * (monthly_expense - prior_month_expense) / NULLIF(prior_month_expense, 0),
        2
    ) AS mom_change_pct
FROM expense_with_prior
WHERE prior_month_expense IS NOT NULL
  AND ABS(
        100.0 * (monthly_expense - prior_month_expense) / NULLIF(prior_month_expense, 0)
      ) > 20
ORDER BY department_name, expense_month;

-- ============================================================================
-- END OF CHAPTER 05 - FINANCE
-- END OF MODULE 08 - WINDOW FUNCTION APPLICATIONS
-- ============================================================================
