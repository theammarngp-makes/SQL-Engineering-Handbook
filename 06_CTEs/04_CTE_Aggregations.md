# CTEs With Aggregations

## Business Question

Which departments and cities have the highest workforce concentration?

## SQL Solution

See 04_CTE_Aggregations.sql

## Explanation

CTEs prepare employee, department and location data.

Aggregations are then applied using COUNT and GROUP BY.

## Finding

The analysis identified employee counts per department
and city, making workforce distribution visible.

Departments with more than one employee were highlighted.

## Common Mistakes

- Missing GROUP BY columns
- Using COUNT(*) incorrectly
- Filtering aggregates with WHERE instead of HAVING

## Interview Tips

HAVING is evaluated after aggregation while WHERE is evaluated before aggregation.

## Practice Questions

1. Find departments with more than 2 employees.
2. Find the city with the lowest employee count.
