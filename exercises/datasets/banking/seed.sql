-- Banking dataset seed (MySQL 8.x). Deterministic, static INSERTs. See README.md for grain, traps, and as-of date (2025-06-30).
USE handbook_banking;
SET NAMES utf8mb4;

INSERT INTO branches (branch_id, branch_name, city, opened_on) VALUES
  (1, 'Pune Main',       'Pune',    '2018-04-01'),
  (2, 'Nagpur Central',  'Nagpur',  '2019-06-15'),
  (3, 'Mumbai South',    'Mumbai',  '2020-01-10');

INSERT INTO customers (customer_id, full_name, branch_id, risk_rating, joined_on) VALUES
  (1,  'Aarav Sharma',    1, 'LOW',    '2023-01-10'),
  (2,  'Meera Iyer',      1, 'MEDIUM', '2023-03-15'),
  (3,  'Rohan Deshmukh',  2, 'HIGH',   '2023-05-20'),
  (4,  'Emily Carter',    3, 'LOW',    '2023-07-01'),
  (5,  'Liam O''Brien',   2, NULL,     '2023-09-12'),
  (6,  'Sofia Rossi',     1, 'MEDIUM', '2023-11-05'),
  (7,  'Priya Nair',      3, 'LOW',    '2024-01-18'),
  (8,  'Daniel Kim',      2, 'HIGH',   '2024-03-22'),
  (9,  'Fatima Khan',     1, NULL,     '2024-05-30'),
  (10, 'Noah Williams',   3, 'LOW',    '2024-08-14');

INSERT INTO accounts (account_id, customer_id, account_type, opened_on, closed_on, interest_rate) VALUES
  (1,  1, 'CHECKING', '2023-01-10', NULL,         NULL),
  (2,  1, 'SAVINGS',  '2023-01-15', NULL,         3.500),
  (3,  2, 'CHECKING', '2023-03-15', NULL,         NULL),
  (4,  3, 'CHECKING', '2023-05-20', NULL,         NULL),
  (5,  3, 'SAVINGS',  '2023-06-01', '2024-12-01', 3.000),
  (6,  4, 'CHECKING', '2023-07-01', NULL,         NULL),
  (7,  5, 'SAVINGS',  '2023-09-12', NULL,         2.750),
  (8,  6, 'CHECKING', '2023-11-05', NULL,         NULL),
  (9,  7, 'CHECKING', '2024-01-18', NULL,         NULL),
  (10, 7, 'SAVINGS',  '2024-02-01', NULL,         3.250),
  (11, 8, 'CHECKING', '2024-03-22', NULL,         NULL),
  (12, 9, 'CHECKING', '2024-05-30', NULL,         NULL);
  -- customer 10 (Noah Williams) intentionally has NO account.

INSERT INTO transactions (transaction_id, account_id, txn_type, amount, txn_at, counterparty_account_id, reversed_txn_id) VALUES
  (1,  1,  'DEPOSIT',      1000.00, '2025-01-05 10:00:00', NULL, NULL),
  (2,  1,  'WITHDRAWAL',    200.00, '2025-01-10 09:00:00', NULL, NULL),
  (3,  1,  'WITHDRAWAL',    150.00, '2025-01-12 14:00:00', NULL, NULL),
  (4,  1,  'REVERSAL',      150.00, '2025-01-12 14:05:00', NULL, 3),
  (5,  1,  'FEE',             5.00, '2025-02-01 00:00:00', NULL, NULL),
  (6,  1,  'DEPOSIT',       500.00, '2025-03-01 11:00:00', NULL, NULL),
  (7,  1,  'TRANSFER_OUT',  300.00, '2025-03-05 12:00:00', 3,    NULL),
  (8,  3,  'TRANSFER_IN',   300.00, '2025-03-05 12:00:00', 1,    NULL),
  (9,  2,  'DEPOSIT',      5000.00, '2025-01-20 10:00:00', NULL, NULL),
  (10, 2,  'INTEREST',       14.58, '2025-02-28 00:00:00', NULL, NULL),
  (11, 3,  'DEPOSIT',       800.00, '2025-01-08 09:00:00', NULL, NULL),
  (12, 3,  'WITHDRAWAL',    100.00, '2025-02-15 16:00:00', NULL, NULL),
  (13, 4,  'DEPOSIT',      2000.00, '2025-01-03 10:00:00', NULL, NULL),
  (14, 4,  'WITHDRAWAL',   2500.00, '2025-04-10 10:00:00', NULL, NULL),
  (15, 5,  'DEPOSIT',      1000.00, '2024-06-01 10:00:00', NULL, NULL),
  (16, 5,  'WITHDRAWAL',   1000.00, '2024-11-25 10:00:00', NULL, NULL),
  (17, 6,  'DEPOSIT',      3000.00, '2025-02-10 10:00:00', NULL, NULL),
  (18, 7,  'DEPOSIT',      1500.00, '2025-01-15 10:00:00', NULL, NULL),
  (19, 7,  'INTEREST',       10.31, '2025-02-28 00:00:00', NULL, NULL),
  (20, 8,  'DEPOSIT',       700.00, '2025-03-20 10:00:00', NULL, NULL),
  (21, 8,  'WITHDRAWAL',    700.00, '2025-03-25 10:00:00', NULL, NULL),
  (22, 9,  'DEPOSIT',      1200.00, '2025-04-01 10:00:00', NULL, NULL),
  (23, 10, 'DEPOSIT',      4000.00, '2025-04-05 10:00:00', NULL, NULL),
  (24, 10, 'INTEREST',       27.50, '2025-05-31 00:00:00', NULL, NULL),
  (25, 11, 'DEPOSIT',       900.00, '2025-05-10 10:00:00', NULL, NULL),
  (26, 11, 'WITHDRAWAL',    400.00, '2025-06-01 10:00:00', NULL, NULL),
  (27, 12, 'DEPOSIT',       250.00, '2025-06-15 10:00:00', NULL, NULL);

INSERT INTO loans (loan_id, customer_id, principal, interest_rate, status, originated_on, closed_on) VALUES
  (1, 1, 15000.00, 8.500, 'ACTIVE',   '2024-02-01', NULL),
  (2, 3, 40000.00, 9.750, 'DEFAULTED','2023-08-15', '2025-01-10'),
  (3, 4, 8000.00,  7.250, 'PAID_OFF', '2023-09-01', '2024-09-01'),
  (4, 7, 20000.00, 8.000, 'ACTIVE',   '2024-06-01', NULL),
  (5, 8, 12000.00, 9.000, 'ACTIVE',   '2024-10-15', NULL);
