-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 05 - Business Data Quality Case Studies
-- OBJECTIVE   : Diagnose and fix realistic multi-step data
--               quality problems across retail, finance, and
--               healthcare-style datasets.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- ============================================================

-- ------------------------------------------------------------
-- CASE STUDY 1 - RETAIL: "Our unique customer count looks too high"
-- ------------------------------------------------------------
-- Business Context:
--   Marketing reports 5 unique customers this quarter for a
--   segment that should realistically have 3. Suspected cause:
--   the same person recorded under slightly different name/email
--   formatting from two different sign-up channels.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS retail_customers;
CREATE TABLE retail_customers (
    customer_id   INT PRIMARY KEY,
    full_name     VARCHAR(100),
    email         VARCHAR(150)
);

INSERT INTO retail_customers (customer_id, full_name, email) VALUES
(1, 'Ravi Shah',        'ravi.shah@mail.com'),
(2, 'ravi shah',        'RAVI.SHAH@mail.com'),   -- same person, in-store entry
(3, 'Divya Kapoor',     'divya.k@mail.com'),
(4, 'Karan Bose',       'karan.bose@mail.com'),
(5, 'karan  bose',      'karan.bose@mail.com');  -- same person, duplicate web signup

-- STEP 1 - Reproduce the reported (flawed) number
SELECT COUNT(DISTINCT full_name) AS reported_unique_customers
FROM retail_customers;
-- Returns 5 - full_name differs by casing/spacing, so DISTINCT
-- treats each variant as a separate customer.

-- STEP 2 - Diagnostic query: standardize and re-check
SELECT
    LOWER(TRIM(email)) AS standardized_email,
    COUNT(*) AS row_count
FROM
    retail_customers
GROUP BY
    LOWER(TRIM(email))
HAVING
    COUNT(*) > 1;
-- Reveals that ravi.shah@mail.com and karan.bose@mail.com each
-- appear twice under different name formatting.

-- STEP 3 - Corrected unique customer count
SELECT
    COUNT(DISTINCT LOWER(TRIM(email))) AS corrected_unique_customers
FROM
    retail_customers;
-- Engineering Notes:
--   Email, once standardized, is a more reliable uniqueness key
--   than full_name for this business, since names are entered
--   inconsistently across channels while emails are less prone
--   to casual formatting variance. Root cause: the original
--   metric used full_name instead of a standardized identity key.
-- Expected Output: corrected_unique_customers = 3.

-- ------------------------------------------------------------
-- CASE STUDY 2 - FINANCE: "Quarterly revenue total looks understated"
-- ------------------------------------------------------------
-- Business Context:
--   A partial sync failure left some transaction amounts NULL
--   instead of correctly populated. SUM() silently ignores NULLs,
--   so the reported total looks plausible but is actually short.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS finance_transactions;
CREATE TABLE finance_transactions (
    txn_id      INT PRIMARY KEY,
    txn_date    DATE,
    amount      DECIMAL(10,2)
);

INSERT INTO finance_transactions (txn_id, txn_date, amount) VALUES
(1, '2026-04-01', 1250.00),
(2, '2026-04-03', NULL),      -- failed sync row
(3, '2026-04-05',  875.50),
(4, '2026-04-08', NULL),      -- failed sync row
(5, '2026-04-12', 2100.00);

-- STEP 1 - Reproduce the reported (silently incomplete) number
SELECT SUM(amount) AS reported_q2_revenue
FROM finance_transactions;
-- Returns 4225.50 - looks like a real number, gives no signal
-- that 2 of 5 rows contributed nothing to the total.

-- STEP 2 - Diagnostic query: completeness check
SELECT
    COUNT(*)                                  AS total_rows,
    COUNT(amount)                             AS rows_with_amount,
    COUNT(*) - COUNT(amount)                  AS rows_missing_amount,
    ROUND(100.0 * (COUNT(*) - COUNT(amount)) / COUNT(*), 1) AS pct_missing
FROM
    finance_transactions;
-- Reveals 2 of 5 rows (40%) have a NULL amount - a completeness
-- problem serious enough to flag before trusting the total.

-- STEP 3 - Correct, transparent reporting: surface the gap
-- rather than silently reporting a partial sum as if it were complete.
SELECT
    SUM(amount)                                          AS confirmed_revenue,
    COUNT(*) - COUNT(amount)                              AS unresolved_transactions,
    CASE
        WHEN COUNT(*) - COUNT(amount) > 0
        THEN 'INCOMPLETE - revenue total excludes unresolved transactions'
        ELSE 'COMPLETE'
    END AS data_quality_flag
FROM
    finance_transactions;
-- Engineering Notes:
--   The fix here isn't a clever function call - it's refusing to
--   report SUM(amount) as a finished number without also
--   surfacing how many rows didn't contribute to it. A finance
--   stakeholder needs "4225.50, with 2 transactions unresolved,"
--   not a falsely precise "4225.50" alone. The real fix belongs
--   further upstream: resolving why the sync failed for those
--   two rows.
-- Expected Output:
--   confirmed_revenue = 4225.50, unresolved_transactions = 2,
--   data_quality_flag = 'INCOMPLETE - revenue total excludes
--   unresolved transactions'.

-- ------------------------------------------------------------
-- CASE STUDY 3 - HEALTHCARE: "Compliance audit flagged incomplete intake records"
-- ------------------------------------------------------------
-- Business Context:
--   A compliance audit requires every patient intake record to
--   have insurance_provider populated OR explicitly marked as
--   self-pay. Records that are simply blank (not one or the
--   other) are compliance violations.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS patient_intake;
CREATE TABLE patient_intake (
    patient_id          INT PRIMARY KEY,
    intake_date         DATE,
    insurance_provider  VARCHAR(100)
);

INSERT INTO patient_intake (patient_id, intake_date, insurance_provider) VALUES
(1, '2026-05-01', 'Star Health'),
(2, '2026-05-02', 'Self-Pay'),
(3, '2026-05-02', NULL),          -- true gap - not captured at all
(4, '2026-05-03', ''),            -- gap - empty string, not captured
(5, '2026-05-04', '   '),         -- gap - whitespace only, not captured
(6, '2026-05-05', 'HDFC Ergo');

-- STEP 1 - Diagnostic query: find every record that fails the
-- compliance rule (missing insurance_provider AND not explicitly
-- self-pay), catching NULL, empty, and whitespace-only together.
SELECT
    patient_id,
    intake_date,
    insurance_provider
FROM
    patient_intake
WHERE
    (insurance_provider IS NULL OR TRIM(insurance_provider) = '')
    AND insurance_provider IS DISTINCT FROM 'Self-Pay';  -- PostgreSQL NULL-safe comparison

-- MySQL 8 equivalent (no IS DISTINCT FROM support):
SELECT
    patient_id,
    intake_date,
    insurance_provider
FROM
    patient_intake
WHERE
    (insurance_provider IS NULL OR TRIM(insurance_provider) = '');
-- Engineering Notes:
--   All three "missing" representations (NULL, empty string,
--   whitespace) must be checked together, per Chapter 04 - a
--   query checking only IS NULL would miss patient_id 4 and 5,
--   understating the compliance problem by two-thirds.
-- Expected Output:
--   3 rows: patient_id 3, 4, and 5.

-- STEP 2 - Corrected compliance summary for the audit report
SELECT
    COUNT(*)                                                          AS total_intakes,
    SUM(CASE
            WHEN insurance_provider IS NULL OR TRIM(insurance_provider) = ''
            THEN 1 ELSE 0
        END)                                                          AS compliance_gaps,
    ROUND(100.0 * SUM(CASE
            WHEN insurance_provider IS NULL OR TRIM(insurance_provider) = ''
            THEN 1 ELSE 0
        END) / COUNT(*), 1)                                           AS pct_gap
FROM
    patient_intake;
-- Engineering Notes:
--   SUM(CASE WHEN ... THEN 1 ELSE 0 END) is a standard, portable
--   pattern for conditional counting across all major SQL
--   engines, and reads clearly for a non-technical audit
--   reviewer alongside the raw compliance_gaps count.
-- Expected Output:
--   total_intakes = 6, compliance_gaps = 3, pct_gap = 50.0.
