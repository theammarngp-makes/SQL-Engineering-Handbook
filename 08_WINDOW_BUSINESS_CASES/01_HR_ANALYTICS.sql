-- ============================================================================
-- MODULE      : 08_WINDOW_FUNCTION_APPLICATIONS
-- CHAPTER     : 01_HR_ANALYTICS
-- OBJECTIVE   : Apply window functions to solve real HR / People Analytics
--               problems - department leaderboards, promotion shortlists,
--               headcount reporting, and hiring-sequence comparisons.
--
-- ASSUMED SCHEMA
-- ----------------------------------------------------------------------------
-- employees   (emp_id PK, emp_name, dept_id FK, manager_id, salary, hire_date)
-- departments (dept_id PK, dept_name)
-- ============================================================================


-- ============================================================================
-- SCENARIO 1 : Department Leaderboards
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Leadership wants to identify the highest-paid employee(s) in every
--   department for a compensation review. This is the canonical
--   "top N per group" problem, and the choice of ranking function changes
--   the business meaning of the result.
-- ============================================================================

-- Q1. Identify the top-paid employee in every department.
--     ROW_NUMBER() guarantees exactly one winner per department, even if two
--     employees are tied on salary. Use this when the business needs a
--     single, deterministic winner (e.g., "who gets the spotlight award").
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.salary,
    ROW_NUMBER() OVER (
        PARTITION BY d.dept_id
        ORDER BY e.salary DESC, e.hire_date ASC   -- tiebreaker keeps result deterministic
    ) AS dept_rank
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id;


-- Q2. Shortlist the top 2 highest-paid employees in every department for a
--     compensation review committee.
--     Wrapped in a CTE because window function results cannot be filtered
--     directly in a WHERE clause of the same SELECT.
WITH ranked_employees AS (
    SELECT
        e.emp_id,
        e.emp_name,
        d.dept_name,
        e.salary,
        ROW_NUMBER() OVER (
            PARTITION BY d.dept_id
            ORDER BY e.salary DESC, e.hire_date ASC
        ) AS dept_rank
    FROM employees e
    JOIN departments d
        ON e.dept_id = d.dept_id
)
SELECT
    emp_id,
    emp_name,
    dept_name,
    salary,
    dept_rank
FROM ranked_employees
WHERE dept_rank <= 2
ORDER BY dept_name, dept_rank;


-- Q3. Department leaderboard comparing ROW_NUMBER(), RANK(), and DENSE_RANK()
--     side by side, ranked by salary (corrected from ranking by manager_id,
--     which has no business meaning for a compensation leaderboard).
--
--     Business takeaway:
--       - ROW_NUMBER(): always unique, ignores ties          -> 1,2,3,4
--       - RANK()      : ties share a rank, next rank skips    -> 1,1,3,4
--       - DENSE_RANK(): ties share a rank, no rank is skipped -> 1,1,2,3
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.salary,
    ROW_NUMBER() OVER (
        PARTITION BY d.dept_id
        ORDER BY e.salary DESC
    ) AS dept_seq,
    RANK() OVER (
        PARTITION BY d.dept_id
        ORDER BY e.salary DESC
    ) AS dept_rank,
    DENSE_RANK() OVER (
        PARTITION BY d.dept_id
        ORDER BY e.salary DESC
    ) AS dept_dense_rank
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY d.dept_name, dept_rank;


-- ============================================================================
-- SCENARIO 2 : Headcount & Departmental Context
-- ----------------------------------------------------------------------------
-- Business explanation:
--   An HR export needs the department headcount attached to every employee
--   row, so a single flat file can drive a dashboard - without a separate
--   GROUP BY query and join back to the employee list.
-- ============================================================================

-- Q4. Attach department headcount to every employee row.
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    COUNT(e.emp_id) OVER (
        PARTITION BY d.dept_id
    ) AS dept_headcount
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;


-- Q5. Extend Q4: also attach the department's average and total salary,
--     so a single row lets a stakeholder see an employee's pay alongside
--     full departmental context - a common "flat export" HR request.
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.salary,
    COUNT(e.emp_id) OVER (PARTITION BY d.dept_id)      AS dept_headcount,
    ROUND(AVG(e.salary) OVER (PARTITION BY d.dept_id), 2) AS dept_avg_salary,
    SUM(e.salary) OVER (PARTITION BY d.dept_id)        AS dept_total_salary
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;


-- ============================================================================
-- SCENARIO 3 : Hiring Sequence & Onboarding Cohort Analysis
-- ----------------------------------------------------------------------------
-- Business explanation:
--   The People team wants to understand onboarding cohorts - for any given
--   employee, who was hired immediately before and after them, company-wide
--   and within their own department. This supports buddy-system pairing and
--   onboarding cohort scheduling.
-- ============================================================================

-- Q6. Company-wide previous/next hire, ordered by hire date
--     (corrected from ordering by emp_id, which does not guarantee
--     chronological hiring order).
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.hire_date,
    LAG(e.emp_name) OVER (
        ORDER BY e.hire_date
    ) AS previous_hire,
    LEAD(e.emp_name) OVER (
        ORDER BY e.hire_date
    ) AS next_hire
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY e.hire_date;


-- Q7. Same comparison, scoped within each department - useful when
--     onboarding buddies must come from the same team.
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.hire_date,
    LAG(e.emp_name) OVER (
        PARTITION BY d.dept_id
        ORDER BY e.hire_date
    ) AS previous_dept_hire,
    LEAD(e.emp_name) OVER (
        PARTITION BY d.dept_id
        ORDER BY e.hire_date
    ) AS next_dept_hire,
    -- Days between this employee's hire date and the previous hire in the
    -- same department - flags unusually long or short onboarding gaps.
    e.hire_date - LAG(e.hire_date) OVER (
        PARTITION BY d.dept_id
        ORDER BY e.hire_date
    ) AS days_since_prev_dept_hire
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.hire_date;


-- ============================================================================
-- SCENARIO 4 : Promotion Eligibility & Pay Equity Screening
-- ----------------------------------------------------------------------------
-- Business explanation:
--   Leadership wants a data-driven promotion shortlist: employees who rank
--   in the top quartile of their department by salary AND have at least
--   two years of tenure. This combines NTILE() with a tenure filter.
-- ============================================================================

-- Q8. Bucket employees into salary quartiles within their department using
--     NTILE(4), then shortlist those in the top quartile with 2+ years
--     tenure as promotion-ready candidates.
WITH salary_quartiles AS (
    SELECT
        e.emp_id,
        e.emp_name,
        d.dept_name,
        e.salary,
        e.hire_date,
        NTILE(4) OVER (
            PARTITION BY d.dept_id
            ORDER BY e.salary DESC
        ) AS salary_quartile
    FROM employees e
    JOIN departments d
        ON e.dept_id = d.dept_id
)
SELECT
    emp_id,
    emp_name,
    dept_name,
    salary,
    hire_date,
    salary_quartile
FROM salary_quartiles
WHERE salary_quartile = 1                              -- top 25% by salary
  AND hire_date <= CURRENT_DATE - INTERVAL '2 years'    -- 2+ years tenure
ORDER BY dept_name, salary DESC;


-- Q9. Pay equity screen: flag employees whose salary falls more than one
--     standard deviation below their department's average salary - a
--     common first-pass signal for compensation review.
WITH dept_stats AS (
    SELECT
        e.emp_id,
        e.emp_name,
        d.dept_name,
        e.salary,
        AVG(e.salary) OVER (PARTITION BY d.dept_id)    AS dept_avg_salary,
        STDDEV(e.salary) OVER (PARTITION BY d.dept_id) AS dept_stddev_salary
    FROM employees e
    JOIN departments d
        ON e.dept_id = d.dept_id
)
SELECT
    emp_id,
    emp_name,
    dept_name,
    salary,
    ROUND(dept_avg_salary, 2)    AS dept_avg_salary,
    ROUND(dept_stddev_salary, 2) AS dept_stddev_salary
FROM dept_stats
WHERE salary < (dept_avg_salary - dept_stddev_salary)
ORDER BY dept_name, salary ASC;

-- ============================================================================
-- END OF CHAPTER 01 - HR ANALYTICS
-- ============================================================================
