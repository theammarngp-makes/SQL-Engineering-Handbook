-- ============================================================================
-- MODULE 16, LESSON 12 : AI-ASSISTED QUERY TUNING WORKFLOW (SAFE COPILOT USAGE)
-- ============================================================================
-- SETUP: Run 00_Schema.sql first. Inserts deliberate same-day duplicate
-- CLEARED transactions to exercise the rewrite's edge case below.
-- ============================================================================

INSERT INTO transactions (processed_by_emp_id, transaction_amount, transaction_date, transaction_status)
SELECT processed_by_emp_id, transaction_amount, transaction_date, 'CLEARED'
FROM transactions
WHERE transaction_status = 'CLEARED'
LIMIT 500;

-- ORIGINAL QUERY (correct): how many distinct days did each reviewer
-- process a CLEARED transaction on?
SELECT processed_by_emp_id, COUNT(DISTINCT transaction_date) AS distinct_cleared_processing_days
FROM transactions
WHERE transaction_status = 'CLEARED'
GROUP BY processed_by_emp_id
ORDER BY processed_by_emp_id
LIMIT 10;

EXPLAIN
SELECT processed_by_emp_id, COUNT(DISTINCT transaction_date) AS distinct_cleared_processing_days
FROM transactions
WHERE transaction_status = 'CLEARED'
GROUP BY processed_by_emp_id;

-- "AI-SUGGESTED" REWRITE -- a real, generally-valid DISTINCT-avoidance
-- technique, applied where equivalence needs proving, not assuming.
SELECT processed_by_emp_id, COUNT(*) AS distinct_cleared_processing_days
FROM (
    SELECT DISTINCT processed_by_emp_id, transaction_date
    FROM transactions
    WHERE transaction_status = 'CLEARED'
) AS deduped
GROUP BY processed_by_emp_id
ORDER BY processed_by_emp_id
LIMIT 10;

-- MANDATORY VALIDATION STEP: result-set diff (Prompt Template 3)
SELECT 'original_only' AS diff_source, o.*
FROM (
    SELECT processed_by_emp_id, COUNT(DISTINCT transaction_date) AS distinct_cleared_processing_days
    FROM transactions WHERE transaction_status = 'CLEARED' GROUP BY processed_by_emp_id
) o
LEFT JOIN (
    SELECT processed_by_emp_id, COUNT(*) AS distinct_cleared_processing_days
    FROM (SELECT DISTINCT processed_by_emp_id, transaction_date FROM transactions WHERE transaction_status = 'CLEARED') d
    GROUP BY processed_by_emp_id
) r ON r.processed_by_emp_id = o.processed_by_emp_id
    AND r.distinct_cleared_processing_days = o.distinct_cleared_processing_days
WHERE r.processed_by_emp_id IS NULL
UNION ALL
SELECT 'rewrite_only' AS diff_source, r.*
FROM (
    SELECT processed_by_emp_id, COUNT(*) AS distinct_cleared_processing_days
    FROM (SELECT DISTINCT processed_by_emp_id, transaction_date FROM transactions WHERE transaction_status = 'CLEARED') d
    GROUP BY processed_by_emp_id
) r
LEFT JOIN (
    SELECT processed_by_emp_id, COUNT(DISTINCT transaction_date) AS distinct_cleared_processing_days
    FROM transactions WHERE transaction_status = 'CLEARED' GROUP BY processed_by_emp_id
) o ON o.processed_by_emp_id = r.processed_by_emp_id
    AND o.distinct_cleared_processing_days = r.distinct_cleared_processing_days
WHERE o.processed_by_emp_id IS NULL;

-- EXPLAIN / RESULT-SET DISCUSSION
-- Zero rows returned = provably equivalent on this dataset. Any rows
-- returned name the exact processed_by_emp_id where they disagree. For
-- THIS specific rewrite, equivalence holds regardless of duplicates --
-- run the diff anyway. An AI's confident equivalence claim is exactly as
-- trustworthy as a human's until checked against real data, even when --
-- especially when -- it turns out correct.

-- INTERVIEW INSIGHT
-- Q: "An AI assistant says a rewrite 'returns the same results but runs
--     faster.' What's your process before merging?"
-- A: Treat the claim as unverified regardless of confidence -- diff the
--    result sets directly, then validate the performance claim itself
--    with an actual EXPLAIN/benchmark run (Lesson 11).

-- FURTHER EXPERIMENTS
-- 1. Change to COUNT(transaction_date) without dedup, re-run the diff --
--    confirm it now returns non-empty rows (a real AI-introduced bug).
-- 2. Cross-check both versions against PERFORMANCE_SMELLS.md using
--    Prompt Template 5.
