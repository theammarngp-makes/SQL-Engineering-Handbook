-- =============================================================================
-- Banking dataset — schema (MySQL 8.0+, InnoDB, utf8mb4)
-- Database : handbook_banking
-- Load     : mysql < schema.sql && mysql < seed.sql
-- As-of    : the data ends 2025-06-30; exercises treat 2025-07-01 as "today".
-- =============================================================================

DROP DATABASE IF EXISTS handbook_banking;
CREATE DATABASE handbook_banking CHARACTER SET utf8mb4;
USE handbook_banking;

CREATE TABLE branches (
  branch_id   INT          NOT NULL AUTO_INCREMENT,
  branch_name VARCHAR(60)  NOT NULL,
  city        VARCHAR(60)  NOT NULL,
  opened_on   DATE         NOT NULL,
  PRIMARY KEY (branch_id)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id   INT          NOT NULL AUTO_INCREMENT,
  full_name     VARCHAR(80)  NOT NULL,
  branch_id     INT          NOT NULL,        -- home branch
  risk_rating   VARCHAR(10)  NULL,            -- 'LOW' | 'MEDIUM' | 'HIGH' | NULL (not yet assessed)
  joined_on     DATE         NOT NULL,
  PRIMARY KEY (customer_id),
  CONSTRAINT fk_cust_branch FOREIGN KEY (branch_id) REFERENCES branches (branch_id),
  CONSTRAINT chk_cust_risk CHECK (risk_rating IN ('LOW','MEDIUM','HIGH'))
) ENGINE=InnoDB;

CREATE TABLE accounts (
  account_id     INT           NOT NULL AUTO_INCREMENT,
  customer_id    INT           NOT NULL,
  account_type   VARCHAR(20)   NOT NULL,      -- 'CHECKING' | 'SAVINGS'
  opened_on      DATE          NOT NULL,
  closed_on      DATE          NULL,          -- NULL = still open
  interest_rate  DECIMAL(5,3)  NULL,          -- NULL for CHECKING (no interest)
  PRIMARY KEY (account_id),
  CONSTRAINT fk_acct_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT chk_acct_type CHECK (account_type IN ('CHECKING','SAVINGS'))
) ENGINE=InnoDB;

CREATE TABLE transactions (
  transaction_id   INT           NOT NULL AUTO_INCREMENT,
  account_id       INT           NOT NULL,
  txn_type         VARCHAR(20)   NOT NULL,    -- 'DEPOSIT' | 'WITHDRAWAL' | 'TRANSFER_IN' | 'TRANSFER_OUT' | 'FEE' | 'INTEREST' | 'REVERSAL'
  amount           DECIMAL(12,2) NOT NULL,    -- always stored positive; sign is implied by txn_type
  txn_at           DATETIME      NOT NULL,
  counterparty_account_id INT    NULL,        -- set only for TRANSFER_IN/TRANSFER_OUT; NULL for cash/external txns
  reversed_txn_id  INT           NULL,        -- set only on a REVERSAL row, points at the transaction it reverses
  PRIMARY KEY (transaction_id),
  KEY idx_txn_account (account_id, txn_at),
  CONSTRAINT fk_txn_account FOREIGN KEY (account_id) REFERENCES accounts (account_id),
  CONSTRAINT fk_txn_counterparty FOREIGN KEY (counterparty_account_id) REFERENCES accounts (account_id),
  CONSTRAINT fk_txn_reversed FOREIGN KEY (reversed_txn_id) REFERENCES transactions (transaction_id),
  CONSTRAINT chk_txn_amount CHECK (amount >= 0),
  CONSTRAINT chk_txn_type CHECK (txn_type IN ('DEPOSIT','WITHDRAWAL','TRANSFER_IN','TRANSFER_OUT','FEE','INTEREST','REVERSAL'))
) ENGINE=InnoDB;

CREATE TABLE loans (
  loan_id        INT           NOT NULL AUTO_INCREMENT,
  customer_id    INT           NOT NULL,
  principal      DECIMAL(12,2) NOT NULL,
  interest_rate  DECIMAL(5,3)  NOT NULL,
  status         VARCHAR(20)   NOT NULL,      -- 'ACTIVE' | 'PAID_OFF' | 'DEFAULTED'
  originated_on  DATE          NOT NULL,
  closed_on      DATE          NULL,          -- NULL unless PAID_OFF or DEFAULTED
  PRIMARY KEY (loan_id),
  CONSTRAINT fk_loan_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT chk_loan_status CHECK (status IN ('ACTIVE','PAID_OFF','DEFAULTED'))
) ENGINE=InnoDB;
