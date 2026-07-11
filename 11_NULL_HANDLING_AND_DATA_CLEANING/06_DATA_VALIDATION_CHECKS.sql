-- ============================================================
-- MODULE      : 11 - NULL Handling and Data Cleaning
-- TOPIC       : 06 - Data Validation Checks
-- OBJECTIVE   : Write proactive validation queries that catch
--               orphaned foreign keys, invalid dates, negative
--               values, and impossible ages before they reach
--               a reporting layer.
-- ENGINE      : MySQL 8.0 (PostgreSQL notes included where behavior differs)
-- ============================================================

DROP TABLE IF EXISTS validation_customers;
CREATE TABLE validation_customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100),
    date_of_birth DATE
);

INSERT INTO validation_customers (customer_id, customer_name, date_of_birth) VALUES
(1, 'Neha Joshi',     '1990-04-12'),
(2, 'Arjun Malhotra',  '1985-11-02'),
(3, 'Fatima Sheikh',   '2130-01-01'),   -- impossible: birth date in the future
(4, 'Leo Fontaine',    '1899-06-01');   -- implausible: would make customer 127+ years old

DROP TABLE IF EXISTS validation_orders;
CREATE TABLE validation_orders (
    order_id      INT PRIMARY KEY,
    customer_id   INT,               -- foreign key, may be orphaned
    order_date    DATE,
    quantity      INT,
    unit_price    DECIMAL(10,2)
);

INSERT INTO validation_orders (order_id, customer_id, order_date, quantity, unit_price) VALUES
(1, 1, '2026-06-01',  3,  25.00),
(2, 2, '2026-06-02',  2,  40.00),
(3, 99, '2026-06-03', 1,  15.00),   -- orphaned: customer_id 99 doesn't exist
(4, 3, '2026-07-15', -2,  30.00),   -- negative quantity
(5, 4, '2026-12-25',  5, -10.00),   -- negative unit price
(6, 1, '2099-01-01',  1,  20.00);   -- order_date far in the future

-- ------------------------------------------------------------
-- SCENARIO 1
-- Business Context:
--   Before the nightly revenue report runs, the pipeline needs
--   to confirm every order references a real customer.
-- Question: Find every order with an orphaned customer_id.
-- ------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id AS orphaned_customer_id,
    o.order_date
FROM
    validation_orders o
    LEFT JOIN validation_customers c ON o.customer_id = c.customer_id
WHERE
    c.customer_id IS NULL;

-- Engineering Notes:
--   LEFT JOIN preserves every order row regardless of whether a
--   matching customer exists; filtering on c.customer_id IS NULL
--   afterward isolates exactly the rows where no match was found.
--   A NOT IN (SELECT customer_id FROM validation_customers)
--   equivalent would work here since this customers table has no
--   NULL customer_id values, but LEFT JOIN is the safer default
--   habit regardless, since it doesn't silently break the moment
--   a NULL is introduced into the subquery later.
-- Expected Output:
--   1 row: order_id 3, orphaned_customer_id 99.

-- ------------------------------------------------------------
-- SCENARIO 2
-- Business Context:
--   Finance requires all invalid or future-dated orders flagged
--   before month-end close.
-- Question: Find every order with an order_date more than one
--           day in the future (allowing for time zone slack).
-- ------------------------------------------------------------

SELECT
    order_id,
    customer_id,
    order_date
FROM
    validation_orders
WHERE
    order_date > CURRENT_DATE + INTERVAL 1 DAY;

-- Engineering Notes:
--   Allowing a small buffer (1 day) instead of a strict
--   "> CURRENT_DATE" check avoids false positives from
--   legitimate time-zone edge cases where a transaction near
--   midnight might appear to be technically in the future.
--   In PostgreSQL, the equivalent is
--   order_date > CURRENT_DATE + INTERVAL '1 day'.
-- Expected Output:
--   1 row: order_id 6, order_date '2099-01-01'.

-- ------------------------------------------------------------
-- SCENARIO 3
-- Business Context:
--   Supply chain wants to catch any order line where quantity
--   or unit_price is negative, which should never happen and
--   indicates either a data entry error or a system bug.
-- Question: Find every order with negative quantity or price.
-- ------------------------------------------------------------

SELECT
    order_id,
    quantity,
    unit_price,
    CASE
        WHEN quantity < 0 AND unit_price < 0 THEN 'BOTH_NEGATIVE'
        WHEN quantity < 0 THEN 'NEGATIVE_QUANTITY'
        WHEN unit_price < 0 THEN 'NEGATIVE_PRICE'
    END AS validation_flag
FROM
    validation_orders
WHERE
    quantity < 0 OR unit_price < 0;

-- Engineering Notes:
--   Flagging WHICH field is invalid (rather than a generic
--   "invalid row" label) makes the downstream triage process
--   far faster — a negative quantity likely means a returns
--   process wrote to the wrong table, while a negative price
--   likely means a discount calculation bug, and these get
--   routed to different teams.
-- Expected Output:
--   2 rows: order_id 4 (NEGATIVE_QUANTITY),
--           order_id 5 (NEGATIVE_PRICE).

-- ------------------------------------------------------------
-- SCENARIO 4
-- Business Context:
--   Customer analytics wants to flag implausible birth dates
--   before computing an "average customer age" metric, which
--   would otherwise be badly skewed by a single bad row.
-- Question: Find customers with an impossible or implausible
--           date of birth (future date, or age over 110).
-- ------------------------------------------------------------

SELECT
    customer_id,
    customer_name,
    date_of_birth,
    TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE) AS computed_age,
    CASE
        WHEN date_of_birth > CURRENT_DATE THEN 'FUTURE_DATE'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE) > 110 THEN 'IMPLAUSIBLE_AGE'
    END AS validation_flag
FROM
    validation_customers
WHERE
    date_of_birth > CURRENT_DATE
    OR TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE) > 110;

-- Engineering Notes:
--   TIMESTAMPDIFF(YEAR, ...) is MySQL syntax; PostgreSQL would
--   use AGE(CURRENT_DATE, date_of_birth) or
--   DATE_PART('year', AGE(...)) instead. The 110-year threshold
--   is a placeholder business rule and should be confirmed with
--   the actual stakeholder — this file documents it explicitly
--   rather than burying it silently in a WHERE clause with no
--   explanation.
-- Expected Output:
--   2 rows: customer_id 3 (FUTURE_DATE),
--           customer_id 4 (IMPLAUSIBLE_AGE, ~127 years old).

-- ------------------------------------------------------------
-- SCENARIO 5
-- Business Context:
--   Leadership wants a single data completeness/validity summary
--   across the orders table before trusting any revenue report
--   built on top of it this month.
-- Question: Produce one summary row showing total orders and
--           counts for each validation category.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END)            AS orphaned_customer_count,
    SUM(CASE WHEN o.order_date > CURRENT_DATE + INTERVAL 1 DAY THEN 1 ELSE 0 END) AS future_dated_count,
    SUM(CASE WHEN o.quantity < 0 THEN 1 ELSE 0 END)                    AS negative_quantity_count,
    SUM(CASE WHEN o.unit_price < 0 THEN 1 ELSE 0 END)                  AS negative_price_count
FROM
    validation_orders o
    LEFT JOIN validation_customers c ON o.customer_id = c.customer_id;

-- Engineering Notes:
--   Consolidating every validation rule into a single summary
--   row is the pattern typically wired into a data quality
--   dashboard or an automated pipeline gate — a nonzero value in
--   any of these columns should block or flag the downstream
--   report rather than let it run silently against invalid data.
-- Expected Output:
--   1 row: total_orders = 6, orphaned_customer_count = 1,
--   future_dated_count = 1, negative_quantity_count = 1,
--   negative_price_count = 1.
