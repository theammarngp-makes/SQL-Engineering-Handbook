SQL Interview Preparation Guide

Most Important Topics

High Priority

* Joins
* GROUP BY
* HAVING
* Subqueries
* CASE WHEN
* CTEs
* Window Functions

These topics appear frequently in Data Analyst interviews.

-----------------------------------------------------------------

Frequently Asked Questions

What is the difference between WHERE and HAVING?

Answer:

WHERE filters rows before aggregation.

HAVING filters groups after aggregation.
-----------------------------------------------------------------
What is the difference between INNER JOIN and LEFT JOIN?

INNER JOIN returns only matching rows.

LEFT JOIN returns all rows from the left table and matching rows from the right table.

-----------------------------------------------------------------

What is a Self Join?

A Self Join is a join where a table is joined with itself.

Common use case:
Employee → Manager hierarchy.

-----------------------------------------------------------------

What is a CTE?

A Common Table Expression (CTE) is a temporary result set that improves query readability and organization.

-----------------------------------------------------------------

What is the difference between RANK() and DENSE_RANK()?

RANK():

1, 2, 2, 4

DENSE_RANK():

1, 2, 2, 3

-----------------------------------------------------------------
SQL Interview Checklist

Before applying for internships, ensure you can:

* Write INNER JOIN queries
* Write LEFT JOIN queries
* Use GROUP BY and HAVING
* Solve Subquery problems
* Use CASE WHEN
* Create CTEs
* Use ROW_NUMBER()
* Use RANK()
* Use DENSE_RANK()
* Use LEAD()
* Use LAG()

-----------------------------------------------------------------

Common Mistakes

Mistake:

WHERE COUNT(*) > 2

Correct:

HAVING COUNT(*) > 2

-----------------------------------------------------------------

Mistake:

manager_id = NULL

Correct:

manager_id IS NULL

-----------------------------------------------------------------

Final Advice

For Data Analyst interviews:

1. Understand concepts.
2. Practice business questions.
3. Explain your logic clearly.
4. Focus on Joins, CTEs, and Window Functions.
5. Build projects that demonstrate SQL in real-world scenarios.

Strong SQL + Business Thinking > Memorizing Syntax.
