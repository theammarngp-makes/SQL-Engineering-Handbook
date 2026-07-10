-- ============================================================
-- Module      : 10_STRING_FUNCTIONS
-- Topic       : 03_STRING_TRANSFORMATION
-- Objective   : Reshape and reformat string content using
--               replacement, padding, repetition, and positional
--               insertion for fixed-width and masked output.
-- Dialect     : ANSI SQL, verified against PostgreSQL and MySQL 8+
-- Dataset     : accounts, transactions
-- ============================================================

-- ------------------------------------------------------------
-- Reference schema (for context only)
-- ------------------------------------------------------------
-- accounts     (account_id INT PK, account_number VARCHAR(20), customer_name VARCHAR(100))
-- transactions (txn_id INT PK, account_id INT FK, transaction_ref VARCHAR(30), raw_phone VARCHAR(30))


-- ============================================================
-- SCENARIO 1 — Masking account numbers for support tooling
-- ============================================================
-- Business Context:
--   The support desk application displays account numbers to
--   agents while a call is in progress. Compliance requires that
--   only the last 4 digits be visible on-screen, regardless of
--   the account number's total length.

-- Question: Mask each account number, showing only the last 4
--           digits with the remainder replaced by asterisks.
SELECT
    account_number,
    CONCAT(
        REPEAT('*', CHAR_LENGTH(account_number) - 4),
        RIGHT(account_number, 4)
    ) AS masked_account_number
FROM accounts;

-- Engineering Notes:
--   REPEAT() is combined with CHAR_LENGTH() rather than hard-
--   coding a fixed number of asterisks, because account_number
--   length is not guaranteed uniform across all accounts (legacy
--   accounts use 8 digits, current accounts use 12). This
--   dynamically produces the correct number of mask characters
--   for any length, which a REPLACE()-based approach could not
--   do reliably.
--
-- Performance Notes:
--   Cheap per row; this is a display-layer transformation and
--   should never be used as a filter or join predicate — masked
--   values are not guaranteed unique.
--
-- Expected Output (sample):
--   account_number | masked_account_number
--   482134429871    | ********9871
--   00481223        | ****1223


-- ============================================================
-- SCENARIO 2 — Zero-padding account numbers for a regulatory export
-- ============================================================
-- Business Context:
--   A quarterly regulatory file requires every account number to
--   be exactly 12 digits, zero-padded on the left. Some legacy
--   accounts are currently stored as shorter numeric strings.

-- Question: Produce each account number formatted to a fixed
--           12-character width, zero-padded on the left.
SELECT
    account_number,
    LPAD(account_number, 12, '0') AS export_account_number
FROM accounts;

-- Engineering Notes:
--   Before running this in production, a pre-check should confirm
--   no account_number already exceeds 12 characters — LPAD()
--   truncates rather than errors in that case, which would
--   silently corrupt an oversized account number in a regulatory
--   file. See the guard query below.

-- Question: Identify any account number that would be truncated
--           (i.e., already 12+ characters) before running the
--           export above.
SELECT
    account_number
FROM accounts
WHERE CHAR_LENGTH(account_number) >= 12;

-- Performance Notes:
--   Both queries are O(row count) full scans; acceptable for a
--   quarterly batch export, not intended for high-frequency
--   execution.
--
-- Expected Output (sample):
--   account_number | export_account_number
--   482134          | 000000482134
--   00481223         | 000000481223


-- ============================================================
-- SCENARIO 3 — Formatting transaction references for a legacy
--              fixed-width interchange file
-- ============================================================
-- Business Context:
--   A mainframe-based settlement partner requires transaction
--   reference numbers as a fixed 15-character, right-padded
--   (space-padded) field in its daily batch file format.

-- Question: Format each transaction_ref to a fixed 15-character
--           width, right-padded with spaces.
SELECT
    transaction_ref,
    RPAD(transaction_ref, 15, ' ') AS fixed_width_ref
FROM transactions;

-- Engineering Notes:
--   RPAD() (not LPAD()) is used because this is a left-aligned
--   text field per the settlement partner's file specification —
--   the padding direction is a contract detail, not a stylistic
--   choice, and should be documented with a reference to the
--   spec version whenever the two are easy to confuse.
--
-- Performance Notes:
--   Negligible; this transformation is applied at export time
--   only, never as part of a filter or join.
--
-- Expected Output (sample):
--   transaction_ref | fixed_width_ref
--   TXN-88213         | "TXN-88213     " (15 chars total)


-- ============================================================
-- SCENARIO 4 — Normalizing inconsistent phone number separators
-- ============================================================
-- Business Context:
--   Customer phone numbers were imported from two legacy systems
--   with different formatting conventions — one used periods as
--   separators, the other used dashes. Before validation (Topic
--   04), both need to be normalized to a single dash-separated
--   convention.

-- Question: Replace any period separators in raw_phone with
--           dashes, standardizing the format.
SELECT
    raw_phone,
    REPLACE(raw_phone, '.', '-') AS normalized_phone
FROM transactions;

-- Engineering Notes:
--   REPLACE() replaces every occurrence of '.' in the string, not
--   just the first — which is exactly the desired behavior here,
--   since a phone number like "555.123.4567" has two separators
--   that both need converting. This is the one scenario in this
--   topic where REPLACE()'s "replace-all" behavior is a feature
--   rather than a risk.
--
-- Performance Notes:
--   Cheap per row; if this normalization is applied repeatedly
--   across many downstream queries, it should be pushed upstream
--   into an ETL step or a generated column rather than
--   recalculated on every read.
--
-- Expected Output (sample):
--   raw_phone      | normalized_phone
--   555.123.4567    | 555-123-4567
--   555-123-4567     | 555-123-4567  (unchanged, no '.' present)


-- ============================================================
-- SCENARIO 5 — Building a formatted report separator line
-- ============================================================
-- Business Context:
--   A plain-text daily settlement summary, generated directly
--   from SQL for email distribution, requires a visual separator
--   line between account sections.

-- Question: Generate a 40-character dash separator line, one per
--           account, preceding each account's summary row.
SELECT
    account_number,
    REPEAT('-', 40) AS separator_line
FROM accounts;

-- Engineering Notes:
--   REPEAT() with a literal count is appropriate here since the
--   separator width is a fixed formatting constant tied to the
--   plain-text report's column width, not derived from any data
--   value.
--
-- Performance Notes:
--   Trivial; included primarily to demonstrate REPEAT() used for
--   pure formatting rather than data-derived output, distinct
--   from Scenario 1's data-driven use.
--
-- Expected Output (sample):
--   account_number | separator_line
--   482134429871    | ----------------------------------------
-- ============================================================
