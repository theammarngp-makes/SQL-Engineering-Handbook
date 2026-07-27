-- =============================================================================
-- TOPIC: SELF JOIN
-- DIFFICULTY: Intermediate
-- SCHEMA: schema/00_schema_setup.sql (run that file first)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q1. Show each employee and their direct manager's name, including
-- employees with no manager.
--
-- BUSINESS SCENARIO
-- The org-chart tool needs a flat employee-to-manager mapping to render
-- reporting lines. Employees at the top of the hierarchy must still appear
-- (as a root node), not be silently dropped.
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.emp_id
ORDER BY manager NULLS FIRST, employee;   -- MySQL: use ORDER BY (manager IS NOT NULL), manager

-- EXPECTED OUTPUT: 10 rows. Sahil Verma appears with manager = NULL.


-- -----------------------------------------------------------------------------
-- Q2. Count direct reports per manager (management span-of-control report).
--
-- BUSINESS SCENARIO
-- People Ops is auditing management overhead ahead of a reorg — flagging
-- both managers with unusually large teams and those with just one report.
-- -----------------------------------------------------------------------------

SELECT
    m.emp_name       AS manager,
    COUNT(e.emp_id)  AS direct_reports
FROM employees m
LEFT JOIN employees e
    ON e.manager_id = m.emp_id
WHERE m.emp_id IN (SELECT DISTINCT manager_id FROM employees WHERE manager_id IS NOT NULL)
GROUP BY m.emp_name
ORDER BY direct_reports DESC;

-- EXPECTED OUTPUT: 4 rows (Sahil Verma: 2, Neha Joshi: 1, Arjun Mehta: 1,
-- Ammar Khan: 1) — only employees who ARE managers appear, since the
-- WHERE clause filters m.emp_id down to actual managers.

-- ENGINEERING NOTES
-- The WHERE...IN subquery here filters WHICH employees are treated as
-- "managers" in the output — it does not affect the LEFT JOIN's NULL-
-- preserving behavior for direct_reports, since that filter runs on the
-- "m" role, not on the joined "e" role. Contrast with the ON-vs-WHERE trap
-- in 02_LEFT_JOIN.md, which is about filtering the JOINED side, not the
-- anchor side — this WHERE clause is safe for a different reason: it's
-- restricting rows in the anchor table itself, which behaves identically
-- to filtering a plain single-table query.


-- -----------------------------------------------------------------------------
-- Q3. Flag any employee whose manager was hired AFTER them (a plausible
-- data-quality / org-design flag, not necessarily an error).
--
-- BUSINESS SCENARIO
-- HR data governance runs a quarterly sanity check on organizational data;
-- a newer-hire-manages-longer-tenured-employee pattern is worth a manual
-- review, even though it can be entirely legitimate (e.g., an external hire
-- brought in specifically to manage an existing team).
-- -----------------------------------------------------------------------------

SELECT
    e.emp_name       AS employee,
    e.hire_date      AS employee_hire_date,
    m.emp_name       AS manager,
    m.hire_date      AS manager_hire_date
FROM employees e
INNER JOIN employees m
    ON e.manager_id = m.emp_id
WHERE m.hire_date > e.hire_date;

-- EXPECTED OUTPUT: 1 row (Meera Iyer, hired 2023-11-01, reports to Ammar
-- Khan, hired 2020-03-02 — wait, check this against your own run: with the
-- seed data as written, confirm whether any row actually satisfies this
-- condition, since it depends on exact hire_date values in
-- schema/00_schema_setup.sql. If zero rows return, that's the correct,
-- expected answer for this seed data, not a bug in the query.)

-- INTERVIEW INSIGHT
-- INNER JOIN, not LEFT JOIN, is deliberately correct here — an employee
-- with no manager (manager_id IS NULL) cannot be "managed by someone hired
-- after them" in any meaningful sense, so there is no reason to preserve
-- that row with NULLs. Recognizing when INNER JOIN is actually the right
-- choice for a self join (not just LEFT JOIN by default) is the deeper
-- point of this exercise.

-- FURTHER EXPERIMENTS
-- 1. Rewrite Q1 to show TWO levels of hierarchy (employee, direct manager,
--    and that manager's manager) using a second self join against the
--    same table with a third alias.
-- 2. Research STRING_AGG (Postgres) or GROUP_CONCAT (MySQL) and extend Q2
--    to list each manager's direct reports by name in a single comma-
--    separated column, instead of just counting them.
-- 3. Using the two-level query from experiment 1 as a starting point,
--    explain in a comment why this approach doesn't generalize to "find
--    the full chain to the top" for an org of unknown depth, and what
--    technique (named in the paired .md file's Further Reading) would.
