-- =============================================================================
-- SaaS dataset — schema (MySQL 8.0+, InnoDB, utf8mb4)
-- Database : handbook_saas
-- Load     : mysql < schema.sql && mysql < seed.sql
-- As-of    : the data ends 2025-06-30; exercises treat 2025-07-01 as "today".
-- Scope    : plans, accounts, subscriptions only for this release (deliberately
--            not adding invoices/events/payments yet — see README "Recommended
--            exercises" and the handbook's "do not create giant datasets initially" rule).
-- =============================================================================

DROP DATABASE IF EXISTS handbook_saas;
CREATE DATABASE handbook_saas CHARACTER SET utf8mb4;
USE handbook_saas;

CREATE TABLE plans (
  plan_id       INT           NOT NULL AUTO_INCREMENT,
  plan_name     VARCHAR(30)   NOT NULL,
  monthly_price DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (plan_id)
) ENGINE=InnoDB;

CREATE TABLE accounts (
  account_id   INT          NOT NULL AUTO_INCREMENT,
  company_name VARCHAR(80)  NOT NULL,
  signup_date  DATE         NOT NULL,
  country      VARCHAR(60)  NOT NULL,
  PRIMARY KEY (account_id)
) ENGINE=InnoDB;

CREATE TABLE subscriptions (
  subscription_id INT           NOT NULL AUTO_INCREMENT,
  account_id      INT           NOT NULL,
  plan_id         INT           NOT NULL,
  start_date      DATE          NOT NULL,
  end_date        DATE          NULL,       -- NULL = still in effect (only valid when status = 'ACTIVE')
  status          VARCHAR(10)   NOT NULL,   -- 'ACTIVE' | 'EXPIRED' (superseded by an upgrade/downgrade) | 'CANCELED' (customer churned)
  cancel_reason   VARCHAR(100)  NULL,       -- set only when status = 'CANCELED'
  PRIMARY KEY (subscription_id),
  KEY idx_sub_account (account_id, start_date),
  CONSTRAINT fk_sub_account FOREIGN KEY (account_id) REFERENCES accounts (account_id),
  CONSTRAINT fk_sub_plan    FOREIGN KEY (plan_id)    REFERENCES plans (plan_id),
  CONSTRAINT chk_sub_status CHECK (status IN ('ACTIVE','EXPIRED','CANCELED'))
) ENGINE=InnoDB;
