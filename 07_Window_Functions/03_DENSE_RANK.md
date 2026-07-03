# DENSE_RANK()

## Overview

`DENSE_RANK()` behaves like `RANK()` except it **never leaves a gap** in
the ranking sequence after a tie.

```
Ordered values: [10, 20, 20, 40]
RANK():         [1,  2,  2,  4]
DENSE_RANK():   [1,  2,  2,  3]
```

## Learning Objectives

- Assign gap-free competition ranks.
- Correctly choose between `RANK()` and `DENSE_RANK()` based on business
  requirements.
- Compare all three ranking functions side by side.

## Prerequisites

- `01_ROW_NUMBER`
- `02_RANK`

## Syntax

```sql
SELECT
    column_a,
    DENSE_RANK() OVER (ORDER BY sort_column) AS dense_rank_value
FROM table_name;
```

## Dataset Used

`employes`

## Examples

See [`03_dense_rank.sql`](./03_dense_rank.sql).

## Real World Applications

- Salary bands / pay-grade tiers where consecutive tier numbers matter.
- Product pricing tiers where no tier number should ever be "skipped".

## Business Use Cases

| Domain | Scenario |
|---|---|
| Finance | Assign consecutive risk tiers to loan applicants |
| Retail | Assign consecutive pricing tiers to products |
| HR | Assign consecutive seniority bands per manager group |

## Common Mistakes

- Using `DENSE_RANK()` when the business actually wants gap-aware
  standings (use `RANK()` instead).
- Assuming `DENSE_RANK()` and `ROW_NUMBER()` are interchangeable when
  there are no ties in the sample data -- they diverge as soon as a tie
  appears.

## Best Practices

- Always test ranking functions against a dataset that **contains ties**
  before shipping to production; behavior on unique data hides real bugs.
- Comment the choice of ranking function inline so the next engineer
  does not have to reverse-engineer the intent.

## Engineering Notes

`DENSE_RANK()` maintains an internal counter that increments only when
the `ORDER BY` value changes from the previous row -- this is the single
mechanical difference from `RANK()`, which instead increments by the
number of rows seen so far.

## Practice Questions

1. Assign dense rank to employees ordered by `manager_id`.
2. Show employee name and dense rank (ordered by `emp_id`).
3. Show employees with dense rank ≤ 3.
4. Compare `RANK()` and `DENSE_RANK()` side by side.
5. Show the employee(s) with dense rank = 1.

## Difficulty

Beginner

## Estimated Time

20 minutes

## Learning Outcomes

- Predict `DENSE_RANK()` output on tied data without running the query.
- Justify, in an interview, when to use `DENSE_RANK()` over `RANK()`.

## Related Topics

- `02_RANK`
- `04_PARTITION_BY`

## Next Topic

[`04_PARTITION_BY`](../04_PARTITION_BY/README.md)
