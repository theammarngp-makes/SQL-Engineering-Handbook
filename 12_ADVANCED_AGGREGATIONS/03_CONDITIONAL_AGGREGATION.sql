-- ============================================================================
-- MODULE 02 · ADVANCED AGGREGATIONS
-- TOPIC   03 · CONDITIONAL AGGREGATION
-- ============================================================================
-- Business Objective:
--   Build side-by-side, pivot-style branch and transaction reports using
--   COUNT/SUM/AVG combined with CASE, so operational and risk metrics can be
--   read from a single query instead of several separately filtered ones.
--
-- Dataset Used (Banking / Finance domain):
--   branches     (branch_id PK, branch_name, city)
--   accounts     (account_id PK, customer_id, branch_id FK, account_type, status)
--   transactions (transaction_id PK, account_id FK, transaction_date,
--                 transaction_type, amount, is_flagged)
--
-- Dialect notes: MySQL 8+ / PostgreSQL compatible. CASE WHEN behavior shown
-- here is ANSI-standard and portable across both dialects without changes.
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 — COUNT with CASE
-- Business Context:
--   Branch operations wants deposit and withdrawal transaction counts side
--   by side, per branch, for the daily teller activity report.
--
-- Business Questions:
--   - How many deposit transactions occurred at each branch?
--   - How many withdrawal transactions occurred at each branch?
-- ============================================================================

SELECT
    br.branch_name,
    COUNT(CASE WHEN t.transaction_type = 'DEPOSIT'
               THEN 1 END)                                     AS deposit_count,
    COUNT(CASE WHEN t.transaction_type = 'WITHDRAWAL'
               THEN 1 END)                                      AS withdrawal_count,
    COUNT(*)                                                    AS total_transactions
FROM transactions AS t
JOIN accounts      AS a  ON t.account_id = a.account_id
JOIN branches       AS br ON a.branch_id  = br.branch_id
GROUP BY br.branch_name
ORDER BY total_transactions DESC;

-- Explanation:
--   Each COUNT(CASE WHEN ... THEN 1 END) deliberately has no ELSE clause, so
--   non-matching rows evaluate to NULL and are correctly excluded from that
--   specific count -- adding ELSE 0 here would count every row regardless of
--   transaction_type and silently break the report (see the companion .md
--   file's Common Mistakes section).
--
-- Engineering Notes:
--   deposit_count + withdrawal_count should be <= total_transactions; if the
--   schema allows other transaction_type values (e.g., 'TRANSFER', 'FEE'),
--   the gap between the two sums is expected, not a bug.
--
-- Optimization Notes:
--   Index transactions(account_id, transaction_type) so the engine can
--   satisfy both the join and the conditional counts from a single scan
--   without a separate lookup per condition.
--
-- Expected Output (illustrative):
--   branch_name    | deposit_count | withdrawal_count | total_transactions
--   Nagpur Central  | 1,204          | 860                | 2,140
--   Pune East        | 980            | 705                | 1,760


-- ============================================================================
-- SCENARIO 2 — SUM with CASE
-- Business Context:
--   Treasury wants net cash flow per branch: total deposit amount versus
--   total withdrawal amount, to monitor branch-level liquidity.
--
-- Business Questions:
--   - What is the total deposit amount per branch?
--   - What is the total withdrawal amount per branch?
--   - What is the net flow (deposits minus withdrawals)?
-- ============================================================================

SELECT
    br.branch_name,
    SUM(CASE WHEN t.transaction_type = 'DEPOSIT'
             THEN t.amount ELSE 0 END)                          AS deposit_total,
    SUM(CASE WHEN t.transaction_type = 'WITHDRAWAL'
             THEN t.amount ELSE 0 END)                            AS withdrawal_total,
    SUM(CASE WHEN t.transaction_type = 'DEPOSIT' THEN t.amount
             WHEN t.transaction_type = 'WITHDRAWAL' THEN -t.amount
             ELSE 0 END)                                          AS net_cash_flow
FROM transactions AS t
JOIN accounts      AS a  ON t.account_id = a.account_id
JOIN branches       AS br ON a.branch_id  = br.branch_id
GROUP BY br.branch_name
ORDER BY net_cash_flow DESC;

-- Explanation:
--   deposit_total and withdrawal_total use the explicit ELSE 0 house-style
--   convention (mathematically identical to omitting ELSE for SUM, since
--   SUM also ignores NULL). net_cash_flow demonstrates a three-branch CASE
--   inside a single SUM -- deposits contribute positively, withdrawals
--   contribute negatively, everything else contributes zero, all in one
--   pass.
--
-- Engineering Notes:
--   net_cash_flow is a genuinely different aggregation than simply
--   subtracting deposit_total - withdrawal_total in the SELECT list --
--   both approaches are valid and produce the same result, but the inline
--   CASE version demonstrates the pattern extending beyond two branches.
--
-- Optimization Notes:
--   No additional joins or subqueries are needed beyond Scenario 1 -- this
--   report reuses the identical join shape, which should share a query
--   plan cache entry with Scenario 1 in most engines.
--
-- Expected Output (illustrative):
--   branch_name    | deposit_total | withdrawal_total | net_cash_flow
--   Nagpur Central  | 4,820,000.00   | 3,110,000.00       | 1,710,000.00


-- ============================================================================
-- SCENARIO 3 — AVG with CASE
-- Business Context:
--   Risk and compliance want to compare the average transaction size of
--   flagged (potentially suspicious) transactions against normal
--   transactions, per branch, to calibrate fraud-detection thresholds.
--
-- Business Questions:
--   - What is the average amount of flagged transactions per branch?
--   - What is the average amount of normal (unflagged) transactions per branch?
-- ============================================================================

SELECT
    br.branch_name,
    ROUND(AVG(CASE WHEN t.is_flagged = TRUE
                   THEN t.amount END), 2)                        AS avg_flagged_amount,
    ROUND(AVG(CASE WHEN t.is_flagged = FALSE
                   THEN t.amount END), 2)                         AS avg_normal_amount,
    COUNT(CASE WHEN t.is_flagged = TRUE THEN 1 END)                AS flagged_count
FROM transactions AS t
JOIN accounts      AS a  ON t.account_id = a.account_id
JOIN branches       AS br ON a.branch_id  = br.branch_id
GROUP BY br.branch_name
ORDER BY avg_flagged_amount DESC;

-- Explanation:
--   Both AVG(CASE ...) expressions intentionally have no ELSE clause. If
--   ELSE 0 were added, non-matching rows would be pulled into the average
--   as zero-value transactions, dragging both averages toward zero and
--   producing a materially wrong risk signal -- this is precisely the
--   Common Mistake called out in the companion .md file.
--
-- Engineering Notes:
--   flagged_count is included alongside the averages so risk analysts can
--   judge how statistically reliable avg_flagged_amount is per branch --
--   an average over 3 flagged transactions is far less trustworthy than
--   one over 300.
--
-- Optimization Notes:
--   is_flagged should be indexed if this report runs frequently against a
--   large transactions table, since it is the primary conditional column
--   driving both aggregates.
--
-- Expected Output (illustrative):
--   branch_name    | avg_flagged_amount | avg_normal_amount | flagged_count
--   Nagpur Central  | 48,210.55            | 6,340.20            | 14


-- ============================================================================
-- SCENARIO 4 — Conditional KPI / Pivot-Style Report
-- Business Context:
--   Branch leadership wants one summary table: account status breakdown
--   (active, dormant, closed) per branch, formatted as a wide, pivot-style
--   table suitable for direct display on a management dashboard.
--
-- Business Questions:
--   - How many active, dormant, and closed accounts does each branch have?
--   - What percentage of each branch's accounts are active?
-- ============================================================================

SELECT
    br.branch_name,
    COUNT(CASE WHEN a.status = 'ACTIVE'  THEN 1 END)                AS active_accounts,
    COUNT(CASE WHEN a.status = 'DORMANT' THEN 1 END)                 AS dormant_accounts,
    COUNT(CASE WHEN a.status = 'CLOSED'  THEN 1 END)                  AS closed_accounts,
    COUNT(*)                                                          AS total_accounts,
    ROUND(100.0 * COUNT(CASE WHEN a.status = 'ACTIVE' THEN 1 END)
          / NULLIF(COUNT(*), 0), 1)                                    AS active_rate_pct
FROM accounts  AS a
JOIN branches   AS br ON a.branch_id = br.branch_id
GROUP BY br.branch_name
ORDER BY active_rate_pct DESC;

-- Explanation:
--   This is the canonical "pivot without PIVOT" pattern: one CASE-wrapped
--   COUNT per status value turns a tall status column into a wide report,
--   with a derived conditional KPI (active_rate_pct) computed from two of
--   the same conditional aggregates in a single expression.
--
-- Engineering Notes:
--   NULLIF(COUNT(*), 0) guards against division by zero for a branch with
--   no accounts at all, returning NULL for active_rate_pct instead of
--   erroring the whole report.
--
-- Optimization Notes:
--   Index accounts(branch_id, status) -- this single composite index
--   supports the join, the GROUP BY, and every conditional COUNT() in this
--   query simultaneously.
--
-- Expected Output (illustrative):
--   branch_name    | active_accounts | dormant_accounts | closed_accounts | total_accounts | active_rate_pct
--   Nagpur Central  | 3,140             | 210                | 90                 | 3,440           | 91.3
