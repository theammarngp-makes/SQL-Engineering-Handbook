# Basic CTEs

## Business Question

How can we create a temporary reusable dataset
without creating a physical table?

## SQL Solution

See 01_Basic_CTE.sql

## Explanation

A CTE acts as a temporary table that exists only
during query execution.

It improves readability and allows complex logic
to be broken into smaller parts.

## Finding

The employee_cte returned all employee records
while keeping the original table unchanged.

This demonstrates how CTEs can simplify query design.

## Common Mistakes

- Forgetting the WITH keyword
- Missing CTE alias
- Trying to use a CTE outside its query scope

## Interview Tips

CTEs improve readability but do not permanently store data.

## Practice Questions

1. Create a CTE for managers only.
2. Create a CTE containing employees from one department.
