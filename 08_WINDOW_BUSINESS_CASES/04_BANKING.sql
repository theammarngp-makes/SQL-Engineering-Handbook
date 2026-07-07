-- ============================================================================
-- MODULE      : 08_WINDOW_FUNCTION_APPLICATIONS
-- CHAPTER     : 04_BANKING
-- OBJECTIVE   : Apply window functions to transaction and risk analytics -
--               running balances, large-transaction monitoring, fraud
--               signal detection, and account activity gap analysis.
--
-- ASSUMED SCHEMA
-- ----------------------------------------------------------------------------
-- accounts     (account_id PK, customer_id FK, account_type, opened_date)
-- transactions (transaction_id PK, account_id FK, transaction_date, amount,
--               transaction_type)   -- amount is signed: + credit, - debit
-- customers    (customer_id PK, customer_name)
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 : Running Balance Reconstruction
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Operations teams need to reconstruct a running balance per account from
--   the raw, signed transaction ledger - the foundation for every other
--   balance-related report in this chapter.
-- ============================================================================

-- Q1. Running balance per account, ordered by transaction date and
--     transaction_id as a deterministic tiebreaker for same-day transactions.
SELECT
    t.account_id,
    t.transaction_id,
    t.transaction_date,
    t.amount,
    SUM(t.amount) OVER (
        PARTITION BY t.account_id
        ORDER BY t.transaction_date, t.transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance
FROM transactions t
ORDER BY t.account_id, t.transaction_date, t.transaction_id;


-- Q2. Opening balance for each account for the current month, using
--     FIRST_VALUE() to retrieve the first running-balance value in the
--     period without a separate query.
WITH running_balances AS (
    SELECT
        t.account_id,
        t.transaction_id,
        t.transaction_date,
        t.amount,
        SUM(t.amount) OVER (
            PARTITION BY t.account_id
            ORDER BY t.transaction_date, t.transaction_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM transactions t
    WHERE t.transaction_date >= DATE_TRUNC('month', CURRENT_DATE)
)
SELECT
    account_id,
    transaction_id,
    transaction_date,
    amount,
    running_balance,
    FIRST_VALUE(running_balance) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date, transaction_id
    ) AS month_opening_balance
FROM running_balances
ORDER BY account_id, transaction_date, transaction_id;


-- ============================================================================
-- SCENARIO 2 : Large Transaction Monitoring
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Compliance and operations teams review a ranked list of the largest
--   transactions bank-wide, typically restricted to a recent rolling window
--   to keep the review queue actionable.
-- ============================================================================

-- Q3. Top 20 largest transactions in the last 24 hours, bank-wide.
--     Filter to a rolling window BEFORE ranking to avoid scanning and
--     sorting the entire historical ledger.
WITH recent_transactions AS (
    SELECT
        t.transaction_id,
        t.account_id,
        c.customer_name,
        t.transaction_date,
        t.amount
    FROM transactions t
    JOIN accounts a
        ON t.account_id = a.account_id
    JOIN customers c
        ON a.customer_id = c.customer_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '1 day'
),
ranked_transactions AS (
    SELECT
        transaction_id,
        account_id,
        customer_name,
        transaction_date,
        amount,
        RANK() OVER (ORDER BY ABS(amount) DESC) AS size_rank
    FROM recent_transactions
)
SELECT
    transaction_id,
    account_id,
    customer_name,
    transaction_date,
    amount,
    size_rank
FROM ranked_transactions
WHERE size_rank <= 20
ORDER BY size_rank;


-- Q4. Rank customers by total transaction volume (sum of absolute
--     transaction amounts) over the trailing 90 days, for a
--     relationship-banking outreach list.
WITH customer_volume AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(ABS(t.amount)) AS total_volume_90d
    FROM transactions t
    JOIN accounts a
        ON t.account_id = a.account_id
    JOIN customers c
        ON a.customer_id = c.customer_id
    WHERE t.transaction_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_volume_90d,
    DENSE_RANK() OVER (ORDER BY total_volume_90d DESC) AS volume_rank
FROM customer_volume
ORDER BY volume_rank;


-- ============================================================================
-- SCENARIO 3 : Fraud Signal Detection
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Flag transactions that are unusually large relative to that specific
--   account's own transaction history - a common, low-cost first-pass
--   signal that feeds a broader fraud detection pipeline.
-- ============================================================================

-- Q5. Flag transactions more than 3 standard deviations above an account's
--     own historical average transaction size.
WITH account_stats AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.transaction_date,
        t.amount,
        AVG(ABS(t.amount)) OVER (PARTITION BY t.account_id)    AS account_avg_amount,
        STDDEV(ABS(t.amount)) OVER (PARTITION BY t.account_id) AS account_stddev_amount
    FROM transactions t
)
SELECT
    transaction_id,
    account_id,
    transaction_date,
    amount,
    ROUND(account_avg_amount, 2)    AS account_avg_amount,
    ROUND(account_stddev_amount, 2) AS account_stddev_amount
FROM account_stats
WHERE ABS(amount) > (account_avg_amount + 3 * account_stddev_amount)
ORDER BY account_id, transaction_date;


-- ============================================================================
-- SCENARIO 4 : Account Activity & Gap Analysis
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Flag accounts that go dormant for an extended period and then suddenly
--   become active again - a pattern frequently associated with account
--   takeover or synthetic identity fraud.
-- ============================================================================

-- Q6. Time gap between consecutive transactions per account.
SELECT
    t.account_id,
    t.transaction_id,
    t.transaction_date,
    t.amount,
    LAG(t.transaction_date) OVER (
        PARTITION BY t.account_id
        ORDER BY t.transaction_date, t.transaction_id
    ) AS previous_transaction_date,
    t.transaction_date - LAG(t.transaction_date) OVER (
        PARTITION BY t.account_id
        ORDER BY t.transaction_date, t.transaction_id
    ) AS days_since_previous_transaction
FROM transactions t
ORDER BY t.account_id, t.transaction_date;


-- Q7. Dormancy-then-spike detector: flag transactions that occur more than
--     90 days after the account's previous transaction AND are more than
--     3 standard deviations above that account's own historical average -
--     a combined signal from Scenarios 3 and 4.
WITH account_activity AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.transaction_date,
        t.amount,
        LAG(t.transaction_date) OVER (
            PARTITION BY t.account_id
            ORDER BY t.transaction_date, t.transaction_id
        ) AS previous_transaction_date,
        AVG(ABS(t.amount)) OVER (PARTITION BY t.account_id)    AS account_avg_amount,
        STDDEV(ABS(t.amount)) OVER (PARTITION BY t.account_id) AS account_stddev_amount
    FROM transactions t
)
SELECT
    transaction_id,
    account_id,
    transaction_date,
    amount,
    previous_transaction_date,
    transaction_date - previous_transaction_date AS dormancy_days,
    ROUND(account_avg_amount, 2)    AS account_avg_amount,
    ROUND(account_stddev_amount, 2) AS account_stddev_amount
FROM account_activity
WHERE previous_transaction_date IS NOT NULL
  AND (transaction_date - previous_transaction_date) > 90
  AND ABS(amount) > (account_avg_amount + 3 * account_stddev_amount)
ORDER BY account_id, transaction_date;

-- ============================================================================
-- END OF CHAPTER 04 - BANKING
-- ============================================================================
