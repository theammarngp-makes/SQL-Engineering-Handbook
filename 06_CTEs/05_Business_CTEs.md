# Business CTE Applications

## Business Question

How can CTEs be used to support workforce planning and resource allocation decisions?

## SQL Solution

See 05_Business_CTEs.sql

## Explanation

Multiple CTEs were used to create reusable business views.

The resulting datasets were analyzed using joins,
aggregations and conditional logic.

## Finding

The analysis identified:

- High demand cities = ```Nagpur```
- Active departments = ``` Data Analytics,'Active'
                           Engineering,'Active'
                           Marketing,'Active'```
- Largest department = ```Data Analytics```
- Largest employee concentration by city = ``` Nagpur with 3 employes ```

These insights can support hiring and operational planning.

## Common Mistakes

- Incorrect aggregation logic
- Using INNER JOIN instead of LEFT JOIN
- Applying CASE statements before aggregation

## Interview Tips

Business-oriented CTE questions are common in Data Analyst interviews because they test both SQL and analytical thinking.

## Practice Questions

1. Find the second most populated city.
2. Find departments contributing more than 25% of employees.
3. Create a Medium Demand category.
