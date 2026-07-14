/* ============================================================================
   MODULE 13 — SET OPERATORS
   Topic 05 — Data Reconciliation
   ============================================================================

   BUSINESS OBJECTIVE
   -------------------
   Build a complete, reusable reconciliation suite (row-count check,
   bidirectional EXCEPT, and value-level comparison) against a realistic
   shipment and inventory reconciliation scenario.

   DATASET
   -------
   expected_shipments(shipment_id, order_id, expected_qty, expected_date)
   received_shipments(shipment_id, order_id, received_qty, received_date)
   inventory_warehouse(sku, on_hand_qty)
   inventory_erp(sku, on_hand_qty)
   ============================================================================ */

CREATE TABLE expected_shipments (
    shipment_id   VARCHAR(20) PRIMARY KEY,
    order_id      INT NOT NULL,
    expected_qty  INT NOT NULL,
    expected_date DATE NOT NULL
);

CREATE TABLE received_shipments (
    shipment_id   VARCHAR(20) PRIMARY KEY,
    order_id      INT NOT NULL,
    received_qty  INT NOT NULL,
    received_date DATE NOT NULL
);

INSERT INTO expected_shipments (shipment_id, order_id, expected_qty, expected_date) VALUES
    ('SHIP-001', 9001, 40, '2026-05-10'),
    ('SHIP-002', 9002, 12, '2026-05-11'),
    ('SHIP-003', 9003, 25, '2026-05-12');

INSERT INTO received_shipments (shipment_id, order_id, received_qty, received_date) VALUES
    ('SHIP-001', 9001, 40, '2026-05-10'),   -- matches exactly
    ('SHIP-003', 9003, 20, '2026-05-13');   -- arrived, but short by 5 units,
                                              -- and a day late
    -- Note: SHIP-002 never arrived at all — intentional, to demonstrate a
    -- true missing-shipment reconciliation failure.

CREATE TABLE inventory_warehouse (
    sku         VARCHAR(20) PRIMARY KEY,
    on_hand_qty INT NOT NULL
);

CREATE TABLE inventory_erp (
    sku         VARCHAR(20) PRIMARY KEY,
    on_hand_qty INT NOT NULL
);

INSERT INTO inventory_warehouse (sku, on_hand_qty) VALUES
    ('SKU-100', 150),
    ('SKU-200', 40),
    ('SKU-300', 0);

INSERT INTO inventory_erp (sku, on_hand_qty) VALUES
    ('SKU-100', 150),
    ('SKU-200', 35);   -- Note: SKU-300 doesn't exist in ERP at all, and
                        -- SKU-200's quantity disagrees between systems —
                        -- both are intentional, realistic reconciliation
                        -- failures.


/* ----------------------------------------------------------------------------
   SCENARIO 1 — Row count check (necessary, but not sufficient)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   The fastest, cheapest first signal in any reconciliation: do the two
   tables even have the same number of rows?

   BUSINESS QUESTION
   How many shipments does each system report?
---------------------------------------------------------------------------- */

SELECT
    (SELECT COUNT(*) FROM expected_shipments) AS expected_count,
    (SELECT COUNT(*) FROM received_shipments) AS received_count;

/*
EXPECTED OUTPUT:
 expected_count | received_count
 ----------------|-----------------
 3              | 2

ENGINEERING NOTES
- A mismatch here (3 vs 2) is a clear signal something is wrong, but it does
  NOT tell you WHICH shipment is missing — that requires Scenario 2.
- Critically: if a shipment had been duplicated in `received_shipments` while
  a different one was truly missing, the counts could match by coincidence
  while still hiding a real problem — this is why row count is never used
  alone.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 2 — Bidirectional EXCEPT: find the exact missing/unexpected keys
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Operations needs to know exactly which shipment(s) never arrived, and
   whether anything arrived that wasn't expected at all.

   BUSINESS QUESTION
   Which shipment_ids are expected but never received? Which were received
   but never expected?
---------------------------------------------------------------------------- */

-- Direction 1: expected but never received — the real operational problem
SELECT shipment_id
FROM expected_shipments

EXCEPT                              -- Oracle: use MINUS

SELECT shipment_id
FROM received_shipments;

-- Direction 2: received but never expected — possible data entry error
-- or an unplanned/duplicate shipment
SELECT shipment_id
FROM received_shipments

EXCEPT

SELECT shipment_id
FROM expected_shipments;

/*
EXPECTED OUTPUT
Direction 1 (Expected − Received): SHIP-002   → truly missing, escalate
Direction 2 (Received − Expected): (0 rows)   → nothing unexpected arrived

ENGINEERING NOTES
- This pair of queries is the actual audit deliverable: Direction 1
  identifies exactly which shipment to chase with the carrier; Direction 2
  would flag any shipment that arrived without a corresponding expectation
  record — here, correctly, there is none.

OPTIMIZATION NOTES
- With shipment_id as the primary key on both tables, this EXCEPT executes
  as an efficient anti-join in every major engine's optimizer.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 3 — Value-level comparison on matched keys (JOIN, not a set op)
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Even for shipments that DID arrive, operations needs to know if the
   quantity or timing disagrees with what was expected — a partial or late
   shipment is still a problem worth flagging.

   BUSINESS QUESTION
   For shipments present in both systems, do quantity and date match?
---------------------------------------------------------------------------- */

SELECT
    e.shipment_id,
    e.expected_qty,
    r.received_qty,
    e.expected_date,
    r.received_date,
    CASE
        WHEN e.expected_qty <> r.received_qty THEN 'QUANTITY_MISMATCH'
        WHEN e.expected_date <> r.received_date THEN 'DATE_MISMATCH'
        ELSE 'MATCH'
    END AS reconciliation_status
FROM expected_shipments e
JOIN received_shipments r ON e.shipment_id = r.shipment_id
ORDER BY reconciliation_status, e.shipment_id;

/*
EXPECTED OUTPUT:
 shipment_id | expected_qty | received_qty | expected_date | received_date | reconciliation_status
 ------------|--------------|--------------|---------------|---------------|------------------------
 SHIP-001    | 40           | 40           | 2026-05-10    | 2026-05-10    | MATCH
 SHIP-003    | 25           | 20           | 2026-05-12    | 2026-05-13    | QUANTITY_MISMATCH

ENGINEERING NOTES
- This step is not a set operator at all — it's a plain JOIN — but it's the
  necessary third leg of any real reconciliation suite: matching keys don't
  guarantee matching values.
- SHIP-003's date mismatch is masked by the CASE statement's ordering
  (QUANTITY_MISMATCH is checked first); a production version would likely
  report both flags rather than just the first one triggered.

OPTIMIZATION NOTES
- An index on shipment_id (already the primary key on both sides) makes this
  join essentially free even at large volumes.
*/


/* ----------------------------------------------------------------------------
   SCENARIO 4 — Inventory reconciliation: existence AND value together
   ----------------------------------------------------------------------------
   BUSINESS CONTEXT
   Supply chain needs a single query that flags every SKU where the
   warehouse system and the ERP disagree — either because a SKU is missing
   from one side, or because the on-hand quantity itself doesn't match.

   BUSINESS QUESTION
   Which SKUs disagree between the warehouse system and the ERP, and how?
---------------------------------------------------------------------------- */

SELECT
    COALESCE(w.sku, e.sku)          AS sku,
    w.on_hand_qty                    AS warehouse_qty,
    e.on_hand_qty                    AS erp_qty,
    CASE
        WHEN w.sku IS NULL THEN 'MISSING_FROM_WAREHOUSE'
        WHEN e.sku IS NULL THEN 'MISSING_FROM_ERP'
        WHEN w.on_hand_qty <> e.on_hand_qty THEN 'QUANTITY_MISMATCH'
        ELSE 'MATCH'
    END AS reconciliation_status
FROM inventory_warehouse w
FULL OUTER JOIN inventory_erp e ON w.sku = e.sku
WHERE w.sku IS NULL
   OR e.sku IS NULL
   OR w.on_hand_qty <> e.on_hand_qty
ORDER BY reconciliation_status, sku;

/*
EXPECTED OUTPUT:
 sku      | warehouse_qty | erp_qty | reconciliation_status
 ---------|---------------|---------|------------------------
 SKU-300  | 0             | NULL    | MISSING_FROM_ERP
 SKU-200  | 40            | 35      | QUANTITY_MISMATCH

ENGINEERING NOTES
- A FULL OUTER JOIN plus a WHERE filter for disagreement is the natural
  generalization of the EXCEPT pattern once you need BOTH existence checks
  and value checks in a single result — this is the pattern most production
  inventory reconciliation jobs converge on.
- MySQL does not support FULL OUTER JOIN natively; simulate it with a UNION
  of a LEFT JOIN and a RIGHT JOIN (see Database Compatibility note below).

OPTIMIZATION NOTES
- On large inventory tables, ensure `sku` is indexed on both sides; the
  FULL OUTER JOIN plan otherwise degrades to a full hash join over both
  complete tables.

DATABASE COMPATIBILITY — MySQL FULL OUTER JOIN SIMULATION:
    SELECT w.sku, w.on_hand_qty, e.on_hand_qty
    FROM inventory_warehouse w LEFT JOIN inventory_erp e ON w.sku = e.sku
    UNION
    SELECT w.sku, w.on_hand_qty, e.on_hand_qty
    FROM inventory_warehouse w RIGHT JOIN inventory_erp e ON w.sku = e.sku;
*/
