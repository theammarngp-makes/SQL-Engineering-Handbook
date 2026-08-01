-- ============================================================
-- Module 15, File 04 — Unique, Primary & Foreign Key Indexes
-- Engine: MySQL 8.0+
-- ============================================================

-- ------------------------------------------------------------
-- 1. Confirm the primary key is InnoDB's clustered index
-- ------------------------------------------------------------
SHOW INDEX FROM customers WHERE Key_name = 'PRIMARY';

-- ------------------------------------------------------------
-- 2. Add a unique constraint and observe the duplicate-key error
-- ------------------------------------------------------------
ALTER TABLE customers
    ADD CONSTRAINT uq_customers_email UNIQUE (email);

-- This will fail with a duplicate-key error if 'dupe@example.com'
-- already exists:
-- INSERT INTO customers (email) VALUES ('dupe@example.com');
-- INSERT INTO customers (email) VALUES ('dupe@example.com');

-- ------------------------------------------------------------
-- 3. Foreign key WITHOUT a pre-existing index — MySQL auto-creates one
-- ------------------------------------------------------------
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers (id);

SHOW INDEX FROM orders WHERE Column_name = 'customer_id';
-- Expect an index to exist here even if you never created one
-- explicitly — InnoDB requires it to support the constraint.

-- ------------------------------------------------------------
-- 4. Demonstrate the cost of a missing FK-supporting index
--    (conceptual — PostgreSQL does NOT auto-create this index)
-- ------------------------------------------------------------
-- On PostgreSQL:
--   ALTER TABLE orders
--       ADD CONSTRAINT fk_orders_customer
--       FOREIGN KEY (customer_id) REFERENCES customers (id);
--   -- no index is created automatically; without one, deleting a
--   -- row from customers forces a sequential scan of orders to
--   -- verify no orphaned rows remain.
--   EXPLAIN ANALYZE DELETE FROM customers WHERE id = 1;
--   CREATE INDEX idx_orders_customer_id ON orders (customer_id);
--   -- re-run EXPLAIN ANALYZE and compare plan cost

-- ------------------------------------------------------------
-- 5. NULLs and uniqueness — multiple NULLs are permitted
-- ------------------------------------------------------------
ALTER TABLE customers ADD COLUMN referral_code VARCHAR(20) NULL;
ALTER TABLE customers ADD CONSTRAINT uq_customers_referral UNIQUE (referral_code);

-- Both succeed despite the UNIQUE constraint:
-- INSERT INTO customers (email, referral_code) VALUES ('c1@x.com', NULL);
-- INSERT INTO customers (email, referral_code) VALUES ('c2@x.com', NULL);

-- ------------------------------------------------------------
-- 6. Cleanup
-- ------------------------------------------------------------
-- ALTER TABLE orders DROP FOREIGN KEY fk_orders_customer;
-- ALTER TABLE customers DROP CONSTRAINT uq_customers_email;
-- ALTER TABLE customers DROP CONSTRAINT uq_customers_referral;
-- ALTER TABLE customers DROP COLUMN referral_code;
