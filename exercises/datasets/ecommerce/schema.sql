-- =============================================================================
-- E-commerce dataset — schema (MySQL 8.0+, InnoDB, utf8mb4)
-- Database : handbook_ecommerce
-- Load     : mysql < schema.sql && mysql < seed.sql
-- Currency : every monetary column is in one currency (documented as USD-like).
-- As-of    : the data ends 2025-06-30; exercises treat 2025-07-01 as "today".
-- Note     : email is intentionally NOT unique — see README "Known data-quality traps".
-- =============================================================================

DROP DATABASE IF EXISTS handbook_ecommerce;
CREATE DATABASE handbook_ecommerce CHARACTER SET utf8mb4;
USE handbook_ecommerce;

CREATE TABLE categories (
  category_id        INT           NOT NULL AUTO_INCREMENT,
  category_name      VARCHAR(60)   NOT NULL,
  parent_category_id INT           NULL,
  PRIMARY KEY (category_id),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) REFERENCES categories (category_id)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id INT          NOT NULL AUTO_INCREMENT,
  full_name   VARCHAR(80)  NOT NULL,
  email       VARCHAR(120) COLLATE utf8mb4_0900_as_cs NOT NULL,  -- case-sensitive on purpose: see README "email is not unique"
  city        VARCHAR(60)  NULL,
  country     VARCHAR(60)  NULL,
  signup_date DATE         NOT NULL,
  segment     VARCHAR(20)  NULL,               -- 'Retail' | 'Wholesale' | NULL (unclassified)
  PRIMARY KEY (customer_id),
  KEY idx_customers_email (email),
  CONSTRAINT chk_customers_segment CHECK (segment IN ('Retail','Wholesale'))
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id    INT           NOT NULL AUTO_INCREMENT,
  product_name  VARCHAR(80)   NOT NULL,
  category_id   INT           NOT NULL,
  unit_price    DECIMAL(10,2) NOT NULL,        -- CURRENT list price
  cost_price    DECIMAL(10,2) NULL,            -- NULL = cost not yet recorded
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  launched_on   DATE          NOT NULL,
  PRIMARY KEY (product_id),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories (category_id),
  CONSTRAINT chk_products_price CHECK (unit_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id      INT         NOT NULL AUTO_INCREMENT,
  customer_id   INT         NOT NULL,
  order_date    DATETIME    NOT NULL,
  status        VARCHAR(20) NOT NULL,          -- placed | shipped | delivered | cancelled | returned
  shipping_city VARCHAR(60) NULL,
  coupon_code   VARCHAR(20) NULL,
  PRIMARY KEY (order_id),
  KEY idx_orders_order_date (order_date),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT chk_orders_status CHECK (status IN ('placed','shipped','delivered','cancelled','returned'))
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id INT           NOT NULL AUTO_INCREMENT,
  order_id      INT           NOT NULL,
  product_id    INT           NOT NULL,
  quantity      INT           NOT NULL,
  unit_price    DECIMAL(10,2) NOT NULL,        -- price CHARGED at order time (may differ from products.unit_price)
  discount_pct  DECIMAL(5,2)  NOT NULL DEFAULT 0,
  PRIMARY KEY (order_item_id),
  CONSTRAINT fk_items_order   FOREIGN KEY (order_id)   REFERENCES orders (order_id),
  CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products (product_id),
  CONSTRAINT chk_items_qty  CHECK (quantity > 0),
  CONSTRAINT chk_items_disc CHECK (discount_pct BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE payments (
  payment_id     INT           NOT NULL AUTO_INCREMENT,
  order_id       INT           NOT NULL,
  payment_method VARCHAR(20)   NOT NULL,       -- card | upi | netbanking | wallet
  amount         DECIMAL(10,2) NOT NULL,
  payment_status VARCHAR(20)   NOT NULL,       -- captured | failed | pending
  paid_at        DATETIME      NULL,           -- NULL unless captured
  PRIMARY KEY (payment_id),
  KEY idx_payments_order (order_id),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
  CONSTRAINT chk_payments_status CHECK (payment_status IN ('captured','failed','pending'))
) ENGINE=InnoDB;

CREATE TABLE refunds (
  refund_id     INT           NOT NULL AUTO_INCREMENT,
  payment_id    INT           NOT NULL,
  order_item_id INT           NULL,            -- NULL = order-level refund, not tied to one line
  refund_amount DECIMAL(10,2) NOT NULL,
  refunded_at   DATETIME      NOT NULL,
  reason        VARCHAR(60)   NULL,
  PRIMARY KEY (refund_id),
  CONSTRAINT fk_refunds_payment FOREIGN KEY (payment_id)    REFERENCES payments (payment_id),
  CONSTRAINT fk_refunds_item    FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id)
) ENGINE=InnoDB;

CREATE TABLE shipments (
  shipment_id  INT         NOT NULL AUTO_INCREMENT,
  order_id     INT         NOT NULL,
  carrier      VARCHAR(30) NOT NULL,
  shipped_at   DATETIME    NOT NULL,
  delivered_at DATETIME    NULL,               -- NULL = still in transit
  PRIMARY KEY (shipment_id),
  CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
) ENGINE=InnoDB;

CREATE TABLE reviews (
  review_id   INT         NOT NULL AUTO_INCREMENT,
  customer_id INT         NOT NULL,
  product_id  INT         NOT NULL,
  rating      TINYINT     NOT NULL,
  review_date DATE        NOT NULL,
  comment     VARCHAR(200) NULL,
  PRIMARY KEY (review_id),
  CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT fk_reviews_product  FOREIGN KEY (product_id)  REFERENCES products (product_id),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;
