-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 07 - Production Data Cleaning Project (Capstone)
-- OBJECTIVE   : Build a full cleaning pipeline - validate,
--               standardize, deduplicate, resolve NULL semantics -
--               against a realistic SaaS accounts/subscriptions
--               dataset, ending in a trustworthy Monthly Active
--               Accounts (MAA) metric.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- ============================================================

-- ------------------------------------------------------------
-- RAW LAYER (untouched source data - two merged signup channels)
-- ------------------------------------------------------------

DROP TABLE IF EXISTS accounts_raw;
CREATE TABLE accounts_raw (
    account_id     INT PRIMARY KEY,
    company_name   VARCHAR(150),
    phone          VARCHAR(30),
    signup_channel VARCHAR(20)
);

INSERT INTO accounts_raw (account_id, company_name, phone, signup_channel) VALUES
(1, 'Northwind Traders',      '555-0101', 'self_serve'),
(2, 'northwind traders',      NULL,        'sales_assisted'),   -- duplicate of 1, less complete
(3, '  Contoso Retail  ',     '555-0202', 'self_serve'),
(4, 'Fabrikam   Inc',         '555-0303', 'sales_assisted'),
(5, 'fabrikam inc',           '555-0303', 'self_serve'),        -- duplicate of 4, same phone
(6, 'Adventure Works',        '555-0404', 'self_serve');

DROP TABLE IF EXISTS subscriptions_raw;
CREATE TABLE subscriptions_raw (
    subscription_id INT PRIMARY KEY,
    account_id       INT,
    started_at       DATE,
    cancelled_at     DATE,      -- NULL = still active; this is a MEANINGFUL null, not a gap
    monthly_value    DECIMAL(10,2)
);

INSERT INTO subscriptions_raw (subscription_id, account_id, started_at, cancelled_at, monthly_value) VALUES
(101, 1,  '2025-01-15', NULL,         499.00),   -- Northwind, active
(102, 2,  '2025-02-01', '2025-05-01', 499.00),   -- duplicate account's OWN subscription, now cancelled
(103, 3,  '2025-03-10', NULL,         299.00),   -- Contoso, active
(104, 4,  '2025-01-05', NULL,         899.00),   -- Fabrikam, active
(105, 6,  '2025-04-20', NULL,         199.00),   -- Adventure Works, active
(106, 99, '2025-05-01', NULL,         149.00);   -- ORPHANED - account_id 99 doesn't exist

-- ------------------------------------------------------------
-- STEP 1 - VALIDATE: catch orphaned foreign keys before anything
-- else runs against this data.
-- ------------------------------------------------------------

SELECT
    s.subscription_id,
    s.account_id AS orphaned_account_id
FROM
    subscriptions_raw s
    LEFT JOIN accounts_raw a ON s.account_id = a.account_id
WHERE
    a.account_id IS NULL;

-- Engineering Notes:
--   1 orphaned row found (subscription_id 106, account_id 99).
--   This subscription is quarantined - excluded from the
--   pipeline below - rather than silently included or silently
--   dropped without a record. In a real pipeline this would be
--   written to a quarantine table for investigation, not just
--   filtered out invisibly.
-- Expected Output:
--   1 row: subscription_id 106, orphaned_account_id 99.

-- ------------------------------------------------------------
-- STEP 2 - STANDARDIZE: clean company_name BEFORE deduplicating,
-- since deduplication depends on comparing standardized values.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS accounts_standardized;
CREATE TABLE accounts_standardized AS
SELECT
    account_id,
    TRIM(REPLACE(REPLACE(company_name, '   ', ' '), '  ', ' ')) AS company_name_display,
    LOWER(TRIM(REPLACE(REPLACE(company_name, '   ', ' '), '  ', ' '))) AS company_name_key,
    phone,
    signup_channel
FROM
    accounts_raw;

SELECT * FROM accounts_standardized ORDER BY account_id;

-- Engineering Notes:
--   company_name_key is the standardized comparison/grouping key
--   (lowercase, single-spaced); company_name_display preserves a
--   readable, trimmed version for actual reporting. This mirrors
--   the display-vs-comparison split introduced in Chapter 03.
-- Expected Output:
--   6 rows; e.g., account_id 4 "Fabrikam   Inc" becomes
--   company_name_display "Fabrikam Inc" and company_name_key
--   "fabrikam inc".

-- ------------------------------------------------------------
-- STEP 3 - DEDUPLICATE: using company_name_key as the natural
-- key, keep the account row with the MOST complete data (a
-- non-null phone number), not simply the earliest account_id.
-- ------------------------------------------------------------

SELECT
    account_id,
    company_name_key,
    phone,
    ROW_NUMBER() OVER (
        PARTITION BY company_name_key
        ORDER BY (phone IS NULL) ASC, account_id ASC   -- non-null phone ranks first
    ) AS keep_rank
FROM
    accounts_standardized;

-- Preview which accounts would be removed as duplicates:
SELECT account_id, company_name_key
FROM (
    SELECT
        account_id,
        company_name_key,
        ROW_NUMBER() OVER (
            PARTITION BY company_name_key
            ORDER BY (phone IS NULL) ASC, account_id ASC
        ) AS keep_rank
    FROM accounts_standardized
) ranked
WHERE keep_rank > 1;

-- Engineering Notes:
--   ORDER BY (phone IS NULL) ASC ranks rows with a non-null phone
--   first (FALSE = 0 sorts before TRUE = 1 in MySQL), so the more
--   complete record is kept even when it isn't the earliest
--   account_id. For account_id 1 vs 2 (Northwind), account_id 1
--   has a phone number and account_id 2 does not, so account_id 1
--   is correctly kept over the simpler "keep the lowest ID" rule
--   used in Chapter 04.
-- Expected Output:
--   Duplicates to remove: account_id 2 (northwind traders,
--   less complete) and account_id 5 (fabrikam inc, same phone
--   as account_id 4, later account_id so removed as the redundant
--   copy).

DROP TABLE IF EXISTS accounts_clean;
CREATE TABLE accounts_clean AS
SELECT
    account_id,
    company_name_display AS company_name,
    phone,
    signup_channel
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY company_name_key
            ORDER BY (phone IS NULL) ASC, account_id ASC
        ) AS keep_rank
    FROM accounts_standardized
) ranked
WHERE
    keep_rank = 1;

SELECT * FROM accounts_clean ORDER BY account_id;
-- Expected Output:
--   4 rows: account_id 1 (Northwind Traders), 3 (Contoso Retail),
--   4 (Fabrikam Inc), 6 (Adventure Works).

-- ------------------------------------------------------------
-- STEP 4 - RESOLVE NULL SEMANTICS: cancelled_at is intentionally
-- LEFT AS NULL where it means "still active" - it is NOT run
-- through COALESCE with a fallback, because that would destroy
-- the exact signal the business metric depends on.
-- ------------------------------------------------------------

SELECT
    s.subscription_id,
    s.account_id,
    s.started_at,
    s.cancelled_at,
    CASE
        WHEN s.cancelled_at IS NULL THEN 'ACTIVE'
        ELSE 'CANCELLED'
    END AS subscription_status
FROM
    subscriptions_raw s
WHERE
    s.account_id IN (SELECT account_id FROM accounts_clean)   -- exclude orphaned + deduped-away rows
    AND s.account_id <> 2;   -- the deduplicated-away account's subscription record

-- Engineering Notes:
--   Note the exclusion of account_id 2's subscription - once
--   account_id 2 was identified as a duplicate of account_id 1
--   in Step 3, its associated subscription needs the SAME
--   resolution applied (kept, remapped to the surviving
--   account_id, or excluded per business rule) rather than being
--   silently forgotten. In a full production pipeline this
--   remapping would be an explicit additional step; it is called
--   out here rather than glossed over.
-- Expected Output:
--   4 rows, all showing subscription_status = 'ACTIVE'
--   (subscription_id 102, tied to the removed duplicate
--   account_id 2, is intentionally excluded from this view -
--   see Engineering Notes).

-- ------------------------------------------------------------
-- STEP 5 - FINAL METRIC: Monthly Active Accounts (MAA), computed
-- only against the validated, standardized, deduplicated,
-- NULL-aware trusted layer.
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT s.account_id) AS monthly_active_accounts,
    SUM(s.monthly_value)         AS active_monthly_recurring_revenue
FROM
    subscriptions_raw s
    INNER JOIN accounts_clean a ON s.account_id = a.account_id
WHERE
    s.cancelled_at IS NULL;

-- Engineering Notes:
--   INNER JOIN to accounts_clean naturally excludes both the
--   orphaned subscription (account_id 99, no match) and any
--   subscription tied to a deduplicated-away account_id (2, no
--   longer present in accounts_clean) - a direct, practical
--   payoff of Steps 1-3 rather than needing a separate exclusion
--   filter here. cancelled_at IS NULL is deliberately preserved
--   as the correct "still active" check, per Step 4.
-- Expected Output:
--   1 row: monthly_active_accounts = 4,
--   active_monthly_recurring_revenue = 1896.00
--   (499.00 + 299.00 + 899.00 + 199.00).
