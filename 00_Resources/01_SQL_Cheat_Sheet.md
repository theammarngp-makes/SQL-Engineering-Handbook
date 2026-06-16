SQL Cheat Sheet

SQL Execution Order

1. FROM
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY
7. LIMIT

----------------

WHERE vs HAVING

WHERE

Filters rows before grouping.

SELECT *
FROM employees
WHERE dept_id = 1;

HAVING

Filters groups after aggregation.

SELECT dept_id, COUNT(*)
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 1;

----------------

INNER JOIN

Returns matching records from both tables.

SELECT *
FROM employees e
INNER JOIN departments d
ON e.dept_id = d.dept_id;

----------------

LEFT JOIN

Returns all rows from left table.

SELECT *
FROM employees e
LEFT JOIN departments d
ON e.dept_id = d.dept_id;

----------------

Subquery Rules

Single Value:

WHERE dept_id =
(
 SELECT dept_id
 FROM departments
 WHERE dept_name = 'Engineering'
)

Multiple Values:

WHERE dept_id IN
(
 SELECT dept_id
 FROM departments
)

----------------
NULL Rules

Wrong:

WHERE manager_id = NULL

Correct:

WHERE manager_id IS NULL

----------------

CASE WHEN

CASE
 WHEN dept_id = 1 THEN 'Analytics'
 WHEN dept_id = 2 THEN 'Engineering'
 ELSE 'Marketing'
END
----------------

CTE Template

WITH department_count AS
(
 SELECT dept_id,
        COUNT(*) AS employee_count
 FROM employees
 GROUP BY dept_id
)
SELECT *
FROM department_count;

⸻

Window Function Template

SELECT
 emp_name,
 ROW_NUMBER()
 OVER(ORDER BY emp_id)
FROM employees;

⸻

Interview Golden Rules

WHERE → Rows

HAVING → Groups

INNER JOIN → Matching Records

LEFT JOIN → Keep Left Table

RIGHT JOIN → Keep Right Table

SELF JOIN → Same Table

CTE → Temporary Named Result

ROW_NUMBER → Unique Ranking

RANK → Ranking With Gaps

DENSE_RANK → Ranking Without Gaps
