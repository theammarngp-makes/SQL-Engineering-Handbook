-- SaaS dataset seed (MySQL 8.x). Deterministic, static INSERTs. See README.md for grain, traps, and as-of date (2025-06-30).
USE handbook_saas;
SET NAMES utf8mb4;

INSERT INTO plans (plan_id, plan_name, monthly_price) VALUES
  (1, 'Starter',    29.00),
  (2, 'Pro',        79.00),
  (3, 'Business',  199.00),
  (4, 'Enterprise', 499.00);

INSERT INTO accounts (account_id, company_name, signup_date, country) VALUES
  (1,  'Acme Retail',        '2024-01-10', 'United States'),
  (2,  'Globex Logistics',   '2024-02-14', 'United States'),
  (3,  'Initech Labs',       '2024-03-01', 'India'),
  (4,  'Umbrella Analytics', '2024-04-18', 'United Kingdom'),
  (5,  'Soylent Foods',      '2024-05-05', 'Canada'),
  (6,  'Stark Robotics',     '2024-06-20', 'United States'),
  (7,  'Wayne Security',     '2024-07-02', 'United States'),
  (8,  'Wonka Sweets',       '2024-08-15', 'United Kingdom'),
  (9,  'Hooli Cloud',        '2024-09-01', 'United States'),
  (10, 'Piedmont Media',     '2024-10-10', 'India');

INSERT INTO subscriptions (subscription_id, account_id, plan_id, start_date, end_date, status, cancel_reason) VALUES
  (1,  1, 1, '2024-01-10', '2024-06-30', 'EXPIRED',  NULL),
  (2,  1, 2, '2024-07-01', NULL,         'ACTIVE',   NULL),
  (3,  2, 2, '2024-02-14', NULL,         'ACTIVE',   NULL),
  (4,  3, 1, '2024-03-01', '2024-09-30', 'CANCELED', 'Switched to a competitor'),
  (5,  4, 3, '2024-04-18', NULL,         'ACTIVE',   NULL),
  (6,  5, 2, '2024-05-05', '2025-01-31', 'CANCELED', 'Budget cuts'),
  (7,  5, 1, '2025-03-01', NULL,         'ACTIVE',   NULL),
  (8,  6, 4, '2024-06-20', NULL,         'ACTIVE',   NULL),
  (9,  7, 1, '2024-07-02', '2024-12-31', 'EXPIRED',  NULL),
  (10, 7, 2, '2025-01-01', '2025-04-30', 'EXPIRED',  NULL),
  (11, 7, 3, '2025-05-01', NULL,         'ACTIVE',   NULL),
  (12, 8, 2, '2024-08-15', NULL,         'ACTIVE',   NULL),
  (13, 9, 3, '2024-09-01', '2025-02-28', 'CANCELED', 'Company shut down'),
  (14, 10, 1, '2024-10-10', NULL,        'ACTIVE',   NULL);
