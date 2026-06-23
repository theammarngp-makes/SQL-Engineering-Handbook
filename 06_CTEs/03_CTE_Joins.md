# CTEs With Joins

## Business Question

How can employee, department, and location data
be combined using reusable query blocks?

## SQL Solution

See 03_CTE_Joins.sql

## Explanation

Separate CTEs are created for each table.

The final query joins the temporary datasets.

## Finding

The query successfully produced a complete workforce
view containing employee names, departments and cities.

This approach is easier to understand than a large
single query.

## Common Mistakes

- Joining on incorrect keys
- Missing location joins
- Ambiguous column names

## Interview Tips

CTEs are often used before complex joins to improve readability.

## Practice Questions

1. Show employees from Pune only.
2. Count employees per city.
