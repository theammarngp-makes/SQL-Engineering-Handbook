/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 07 — Real-World Case Study: Retail Merger Data Consolidation
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Apply every operator and pattern from Topics 01-06 against one continuous
   scenario: GlobalMart's acquisition of UrbanCart. Deliver, in sequence,
   (1) a unified sales report, (2) a bidirectional customer migration audit,
   and (3) a deduplicated joint loyalty list — the same three deliverables
   a real post-merger data engineering team would be asked for.

   DATASET
   -------
   sales_globalmart(order_id, order_total, order_date)
   sales_urbancart(order_id, order_total, order_date)
   globalmart_customers(customer_id, customer_name, email)
   urbancart_customers(customer_id, customer_name, email)
   loyalty_globalmart(customer_id, customer_name)
   loyalty_urbancart(customer_id, customer_name)
   ============================================================================ */

CREATE TABLE sales_globalmart (
    order_id    INT PRIMARY KEY,
    order_total DECIMAL(10,2) NOT NULL,
    order_date  DATE NOT NULL
);

CREATE TABLE sales_urbancart (
    order_id    INT PRIMARY KEY,
    order_total DECIMAL(10,2) NOT NULL,
    order_date  DATE NOT NULL
);

INSERT INTO sales_globalmart (order_id, order_total, order_date) VALUES
    (30001, 210.00, '2026-06-01'),
    (30002,  64.50, '2026-06-02'),
    (30003, 512.75, '2026-06-03');

INSERT INTO sales_urbancart (order_id, order_total, order_date) VALUES
    (88001, 145.20, '2026-06-01'),
    (88002,  39.99, '2026-06-04');


CREATE TABLE globalmart_customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150)
);

CREATE TABLE urbancart_customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(150)
);

-- GlobalMart's CRM after the migration script has run
INSERT INTO globalmart_customers (customer_id, customer_name, email) VALUES
    (6001, 'Priya Nair',       'priya.nair@example.com'),
    (6002, 'Diego Alvarez',    'diego.a@example.com'),
    (6003, 'Hannah Kessler',   'hannah.k@example.com'),
    (6004, 'Tomasz Nowak',     'tomasz.n@example.com');

-- UrbanCart's original legacy CRM, prior to decommission
INSERT INTO urbancart_customers (customer_id, customer_name, email) VALUES
    (6001, 'Priya Nair',     'priya.nair@example.com'),
    (6002, 'Diego Alvarez',  'diego.a@example.com'),
    (6005, 'Sofia Marchetti','sofia.m@example.com');
    -- Note: 6003 and 6004 were created directly in GlobalMart's CRM after
    -- the merger (not migration failures). 6005 exists ONLY in UrbanCart's
    -- legacy system — this is the genuine migration gap this file must find.


CREATE TABLE loyalty_globalmart (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL
);

CREATE TABLE loyalty_urbancart (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL
);

INSERT INTO loyalty_globalmart (customer_id, customer_name) VALUES
    (6001, 'Priya Nair'),
    (6003, 'Hannah Kessler');

INSERT INTO loyalty_urbancart (customer_id, customer_name) VALUES
    (6001, 'Priya Nair'),      -- already a GlobalMart loyalty member too
    (6005, 'Sofia Marchetti');


/* ----------------------------------------------------------------------------
   STEP 1 — Unified sales report (UNION ALL, Topic 04 pattern)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Leadership wants one combined view of order activity across both brands
   immediately, before any customer-level cleanup work has happened.

   BUSINESS QUESTION
   Show every order from both companies in one report, tagged by the
   originating company.
---------------------------------------------------------------------------- */

SELECT
    order_id,
    order_total,
    order_date,
    'GlobalMart' AS source_company
FROM sales_globalmart

UNION ALL

SELECT
    order_id,
    order_total,
    order_date,
    'UrbanCart'  AS source_company
FROM sales_urbancart

ORDER BY order_date, source_company;

/*
EXPECTED OUTPUT (5 rows):
 order_id | order_total | order_date | source_company
 ---------|-------------|------------|------------------
 30001    | 210.00      | 2026-06-01 | GlobalMart
 88001    | 145.20      | 2026-06-01 | UrbanCart
 30002    | 64.50       | 2026-06-02 | GlobalMart
 30003    | 512.75      | 2026-06-03 | GlobalMart
 88002    | 39.99       | 2026-06-04 | UrbanCart

ENGINEERING NOTES
- UNION ALL is correct: order_id ranges don't overlap between the two
  companies, and even if they did, an order from two separate businesses is
  never a true duplicate. This is a direct application of Topic 04,
  Scenario 5.

OPTIMIZATION NOTES
- If this report is refreshed frequently on a dashboard, materialize it as
  a scheduled `unified_sales` table rather than recomputing the UNION ALL
  on every page load — see Topic 04's Performance Notes.
*/


/* ----------------------------------------------------------------------------
   STEP 2A — Customer migration audit, Direction 1 (EXCEPT, Topic 03/05 pattern)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Before UrbanCart's legacy CRM can be decommissioned, the migration team
   must prove every UrbanCart customer was carried over into GlobalMart's
   CRM.

   BUSINESS QUESTION
   Which UrbanCart customers are missing from GlobalMart's CRM?
---------------------------------------------------------------------------- */

SELECT customer_id
FROM urbancart_customers

EXCEPT                              -- Oracle: use MINUS

SELECT customer_id
FROM globalmart_customers

ORDER BY customer_id;

/*
EXPECTED OUTPUT:
 customer_id
 -----------
 6005

ENGINEERING NOTES
- This is the real finding: customer 6005 (Sofia Marchetti) never made it
  into GlobalMart's CRM. This is a genuine migration gap and must be routed
  to the migration team for investigation before UrbanCart's system is
  retired — see Topic 05's Production Workflow, step 4.

OPTIMIZATION NOTES
- With customer_id as the primary key on both tables, this runs as an
  efficient anti-join in every major engine's optimizer even before any
  manual tuning.
*/


/* ----------------------------------------------------------------------------
   STEP 2B — Same audit, EXISTS/NOT EXISTS rewrite (Topic 06 pattern)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The migration audit will be re-run nightly until UrbanCart's system is
   formally decommissioned. Before scheduling it, the engineer benchmarks
   the EXISTS-based rewrite against the native EXCEPT form from Step 2A.

   BUSINESS QUESTION
   Same as Step 2A, expressed as a NOT EXISTS anti-join.
---------------------------------------------------------------------------- */

SELECT u.customer_id
FROM urbancart_customers u
WHERE NOT EXISTS (
    SELECT 1
    FROM globalmart_customers g
    WHERE g.customer_id = u.customer_id
)
ORDER BY u.customer_id;

/*
EXPECTED OUTPUT: identical to Step 2A — 6005

ENGINEERING NOTES
- NOT EXISTS is chosen over NOT IN specifically because customer_id could,
  in a larger real dataset, contain a NULL from a bad legacy load — NOT IN
  would then silently return zero rows for the entire query. See Topic 03's
  NULL warning.

OPTIMIZATION NOTES
- At merger scale (often hundreds of thousands of customer rows), this form
  is the one to schedule as the recurring nightly check — it typically
  outperforms native EXCEPT once globalmart_customers(customer_id) is
  indexed, per Topic 06, Scenario 3.
*/


/* ----------------------------------------------------------------------------
   STEP 2C — Reverse direction: confirm nothing else needs investigation
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   A complete audit requires the reverse direction too — customers that
   exist in GlobalMart's CRM but not UrbanCart's are expected here (they
   were created after the merger), but must still be confirmed, not assumed.

   BUSINESS QUESTION
   Which GlobalMart customers do not exist in UrbanCart's legacy system?
---------------------------------------------------------------------------- */

SELECT customer_id
FROM globalmart_customers

EXCEPT

SELECT customer_id
FROM urbancart_customers

ORDER BY customer_id;

/*
EXPECTED OUTPUT:
 customer_id
 -----------
 6003
 6004

ENGINEERING NOTES
- This result is EXPECTED, not a defect: 6003 and 6004 were created
  directly in GlobalMart's CRM after the acquisition closed, so they were
  never supposed to exist in UrbanCart's system. This distinction — expected
  asymmetry vs. genuine gap — is exactly why Topic 03 and Topic 05 both
  insist that a non-empty EXCEPT result triggers investigation, not an
  automatic failure.

OPTIMIZATION NOTES
- Same anti-join shape as Step 2A; identical indexing guidance applies.
*/


/* ----------------------------------------------------------------------------
   STEP 3 — Deduplicated joint loyalty list (UNION, Topic 02 pattern)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   With the migration audit complete and the one genuine gap (6005) routed
   for investigation, marketing is ready to launch the first joint loyalty
   campaign and needs one clean, deduplicated recipient list.

   BUSINESS QUESTION
   Who should receive the joint loyalty campaign — every distinct customer
   across both loyalty programs, with no one emailed twice?
---------------------------------------------------------------------------- */

SELECT customer_id, customer_name
FROM loyalty_globalmart

UNION

SELECT customer_id, customer_name
FROM loyalty_urbancart

ORDER BY customer_id;

/*
EXPECTED OUTPUT (3 rows, not 4):
 customer_id | customer_name
 ------------|------------------
 6001        | Priya Nair
 6003        | Hannah Kessler
 6005        | Sofia Marchetti

ENGINEERING NOTES
- UNION (not UNION ALL) is deliberate and essential here: customer 6001
  (Priya Nair) is enrolled in both companies' loyalty programs, and UNION
  correctly collapses her into a single row so the campaign doesn't email
  her twice — the exact scenario Topic 02 identifies as UNION's correct
  use case, in contrast to Step 1's UNION ALL.
- Customer 6005 is deliberately included here even though Step 2A flagged
  her as a migration gap in the CRM — her loyalty enrollment is a separate,
  already-confirmed fact in UrbanCart's system, and excluding her from a
  marketing list is not an appropriate way to handle an unrelated CRM data
  issue. Flag the CRM gap; don't let it silently suppress an otherwise valid
  campaign recipient.

OPTIMIZATION NOTES
- Both branches are small and already primary-keyed on customer_id, so
  UNION's deduplication cost is negligible here; at real merger scale
  (potentially millions of loyalty members), confirm with EXPLAIN whether
  the dedup pass is still cheap relative to the rest of the campaign
  pipeline before treating this pattern as "free."
*/


/* ----------------------------------------------------------------------------
   STEP 4 — Migration sign-off assertion (automation-ready, Topic 05 pattern)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The migration team needs a single query that can be wired into a CI job
   or scheduled check, returning a clear pass/fail signal rather than a list
   to eyeball manually.

   BUSINESS QUESTION
   Has every UrbanCart customer been migrated into GlobalMart's CRM?
---------------------------------------------------------------------------- */

SELECT
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS — migration complete, safe to decommission UrbanCart CRM'
        ELSE 'FAIL — ' || CAST(COUNT(*) AS VARCHAR(10)) || ' customer(s) not yet migrated'
    END AS migration_status
FROM (
    SELECT customer_id
    FROM urbancart_customers
    EXCEPT
    SELECT customer_id
    FROM globalmart_customers
) AS missing_customers;

/*
EXPECTED OUTPUT:
 migration_status
 ------------------------------------------
 FAIL — 1 customer(s) not yet migrated

ENGINEERING NOTES
- This is the assertion form of Step 2A: instead of returning a list of
  IDs for a human to read, it returns a single, unambiguous status string
  suitable for a pipeline gate, a CI check, or an alert. This is the pattern
  recommended throughout Topic 05 — reconciliation as a testable assertion,
  not a manual inspection.
- || is ANSI/PostgreSQL/Oracle string concatenation; MySQL requires
  CONCAT('FAIL — ', CAST(COUNT(*) AS CHAR), ' customer(s) not yet migrated').

OPTIMIZATION NOTES
- In a real CI/scheduling context, this query's COUNT(*) = 0 check is what
  gets asserted directly (e.g., a dbt test expecting zero rows from the
  inner EXCEPT), rather than parsing the human-readable string — the string
  form here is for a status dashboard, not for machine-to-machine checks.
*/
