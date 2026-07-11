-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 04 - Data Cleaning Techniques
-- OBJECTIVE   : Detect blank/whitespace-only values and find,
--               then safely remove, duplicate records.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- DATASET     : orders_raw (created below - simulates a webhook
--               retry producing duplicate order rows)
-- ============================================================

DROP TABLE IF EXISTS orders_raw;
CREATE TABLE orders_raw (
    row_id         INT PRIMARY KEY AUTO_INCREMENT,
    order_ref      VARCHAR(20),
    customer_id    INT,
    order_date     DATE,
    amount         DECIMAL(10,2),
    notes          VARCHAR(200)
);

INSERT INTO orders_raw (order_ref, customer_id, order_date, amount, notes) VALUES
('ORD-1001', 101, '2026-01-05', 49.99, 'Gift wrap requested'),
('ORD-1001', 101, '2026-01-05', 49.99, 'Gift wrap requested'),   -- exact duplicate (webhook retry)
('ORD-1002', 102, '2026-01-06', 19.99, ''),                       -- empty string, not NULL
('ORD-1003', 103, '2026-01-06', 89.50, '   '),                    -- whitespace-only
('ORD-1004', 104, '2026-01-07', 32.00, NULL),                     -- true NULL
('ORD-1005', 101, '2026-01-09', 49.99, 'Second, unrelated order'); -- same customer/amount, different date, NOT a duplicate

-- ------------------------------------------------------------
-- SCENARIO 1
-- Business Context:
--   A completeness audit needs to distinguish orders with a
--   genuinely missing notes field (NULL) from orders where an
--   empty or whitespace-only string was submitted instead.
-- Question: Categorize each row's notes field as NULL, EMPTY,
--           WHITESPACE_ONLY, or FILLED.
-- ------------------------------------------------------------

SELECT
    row_id,
    order_ref,
    notes,
    CASE
        WHEN notes IS NULL THEN 'NULL'
        WHEN notes = '' THEN 'EMPTY'
        WHEN TRIM(notes) = '' THEN 'WHITESPACE_ONLY'
        ELSE 'FILLED'
    END AS notes_status
FROM
    orders_raw;

-- Engineering Notes:
--   The CASE branches must be ordered from most specific to
--   least specific check that still resolves correctly: NULL is
--   checked first since none of the other conditions can safely
--   evaluate a NULL string as true positively. TRIM(notes) = ''
--   catches whitespace-only AFTER the exact empty-string check,
--   though technically TRIM('') = '' also holds — the ordering
--   here is for readability/intent, not correctness.
-- Expected Output:
--   6 rows; row_id 5 -> NULL, row_id 3 -> EMPTY,
--   row_id 4 -> WHITESPACE_ONLY, others -> FILLED (or NULL for
--   duplicated 'Gift wrap requested' rows).

-- ------------------------------------------------------------
-- SCENARIO 2
-- Business Context:
--   Finance suspects a webhook retry duplicated an order and
--   wants a detection query before anyone deletes anything.
-- Question: Find order_ref values that appear more than once.
-- ------------------------------------------------------------

SELECT
    order_ref,
    COUNT(*) AS occurrence_count
FROM
    orders_raw
GROUP BY
    order_ref
HAVING
    COUNT(*) > 1;

-- Engineering Notes:
--   This is a detection-only query — it identifies which
--   order_ref values are duplicated without touching any data,
--   which is the correct first step before any DELETE.
-- Expected Output:
--   1 row: order_ref = 'ORD-1001', occurrence_count = 2.

-- ------------------------------------------------------------
-- SCENARIO 3
-- Business Context:
--   Before deleting, the team wants to see the FULL duplicate
--   rows themselves, not just the order_ref and count, to
--   confirm the rows really are redundant and not two
--   legitimately separate orders that happen to share a
--   reference number.
-- Question: Show the full duplicate rows for review.
-- ------------------------------------------------------------

SELECT
    o.*
FROM
    orders_raw o
    INNER JOIN (
        SELECT order_ref
        FROM orders_raw
        GROUP BY order_ref
        HAVING COUNT(*) > 1
    ) dup ON o.order_ref = dup.order_ref
ORDER BY
    o.order_ref, o.row_id;

-- Engineering Notes:
--   Joining back to the base table (rather than only grouping)
--   surfaces every column for human review — critical for
--   confirming these are truly redundant rows and not, for
--   example, two different orders that were assigned the same
--   reference number by mistake (a different, more serious bug).
-- Expected Output:
--   2 rows: both row_id 1 and 2, identical in every column
--   except row_id itself.

-- ------------------------------------------------------------
-- SCENARIO 4
-- Business Context:
--   Confirmed duplicates: the team wants to remove the redundant
--   copy while keeping the earliest inserted row (lowest row_id)
--   as the canonical record.
-- Question: Preview, then remove, the duplicate row(s), keeping
--           the lowest row_id per order_ref.
-- ------------------------------------------------------------

-- PREVIEW — always run this first, never delete blind
SELECT
    row_id, order_ref
FROM (
    SELECT
        row_id,
        order_ref,
        ROW_NUMBER() OVER (PARTITION BY order_ref ORDER BY row_id) AS rn
    FROM orders_raw
) ranked
WHERE
    rn > 1;

-- ACTUAL DELETE — run only after confirming the preview above
-- DELETE FROM orders_raw
-- WHERE row_id IN (
--     SELECT row_id FROM (
--         SELECT
--             row_id,
--             ROW_NUMBER() OVER (PARTITION BY order_ref ORDER BY row_id) AS rn
--         FROM orders_raw
--     ) ranked
--     WHERE rn > 1
-- );

-- Engineering Notes:
--   ROW_NUMBER() partitions the table by the natural key
--   (order_ref) and numbers rows within each partition starting
--   at 1, ordered by row_id ascending — so rn = 1 is always the
--   earliest inserted row per group. Deleting everything where
--   rn > 1 removes every duplicate except the first occurrence.
--   The DELETE statement is commented out deliberately in this
--   teaching file — in production, this would run as a reviewed,
--   transactional operation, never uncommented and run blind.
-- Optimization Notes:
--   MySQL does not allow a DELETE to directly reference the same
--   table it's selecting from without a derived-table wrapper
--   (as shown), due to the "you can't specify target table for
--   update in FROM clause" restriction — this pattern works
--   around that limitation.
-- Expected Output:
--   Preview: 1 row (row_id = 2, order_ref = 'ORD-1001').

-- ------------------------------------------------------------
-- SCENARIO 5
-- Business Context:
--   A junior analyst assumed any two orders from the same
--   customer for the same amount must be duplicates, and nearly
--   deleted a legitimate second purchase. This scenario shows
--   why order_date must be part of the natural key.
-- Question: Compare a naive (wrong) duplicate definition against
--           the correct one that includes order_date.
-- ------------------------------------------------------------

-- NAIVE (WRONG) — matches on customer_id + amount only,
-- would incorrectly flag row_id 1 and row_id 6 as duplicates
-- even though they're 4 days apart and clearly separate orders.
SELECT
    customer_id, amount, COUNT(*) AS naive_match_count
FROM
    orders_raw
WHERE
    order_ref <> 'ORD-1001'   -- excluding the already-confirmed exact duplicate for clarity
GROUP BY
    customer_id, amount
HAVING
    COUNT(*) > 1;

-- CORRECTED — natural key includes order_date, so genuinely
-- separate orders are not flagged.
SELECT
    customer_id, order_date, amount, COUNT(*) AS correct_match_count
FROM
    orders_raw
GROUP BY
    customer_id, order_date, amount
HAVING
    COUNT(*) > 1;

-- Engineering Notes:
--   This scenario exists specifically to demonstrate that
--   duplicate detection is only as correct as the natural key
--   chosen — a key that's too loose (customer + amount) produces
--   false positives; the fix is including enough columns
--   (order_date here) to uniquely identify a real-world event.
-- Expected Output:
--   Naive query: 1 row (customer_id 101, amount 49.99, count 2)
--   — a FALSE POSITIVE, since row_id 1 and row_id 6 are genuinely
--   different orders four days apart.
--   Corrected query: 0 rows — no true duplicates remain once
--   order_date is included in the key (assuming the exact
--   ORD-1001 duplicate was already resolved in Scenario 4).
