# RANK()

## Overview

`RANK()` assigns a competition-style rank to each row. Rows with equal
`ORDER BY` values receive the **same rank**, and the next rank **skips**
the number of tied rows (like Olympic medal standings).

```
Ordered values: [10, 20, 20, 40]
RANK():         [1,  2,  2,  4]
```

## Learning Objectives

- Assign competition ranks with correctly handled ties.
- Understand the "gap after a tie" behavior that distinguishes `RANK()`
  from `DENSE_RANK()`.
- Filter ranked results using a CTE.

## Prerequisites

- `01_ROW_NUMBER`
- CTEs (`06_CTEs`)

## Syntax

```sql
SELECT
    column_a,
    RANK() OVER (ORDER BY sort_column) AS rank_value
FROM table_name;
```

## Dataset Used

`employes`, `departments`, `locations`

## Examples

See [`02_rank.sql`](./02_rank.sql).

## Real World Applications

- Leaderboards where tied scores should share a position.
- Sales rankings where multiple reps can tie for the same quota tier.

## Business Use Cases

| Domain | Scenario |
|---|---|
| Sales | Rank reps by revenue, allowing ties for shared bonuses |
| Education | Rank students by exam score with shared placements |
| Manufacturing | Rank suppliers by defect rate |

## Common Mistakes

- Confusing `RANK()`'s gap behavior with `DENSE_RANK()`'s no-gap behavior.
- Forgetting that ties are determined entirely by the `ORDER BY` column(s)
  inside `OVER()` -- not by any other column in the `SELECT` list.
- Filtering directly on the alias in `WHERE` (same restriction as
  `ROW_NUMBER()` -- use a CTE).

## Best Practices

- Choose `RANK()` deliberately when business rules require gaps after
  ties (e.g., "rank 1 and 2 both get gold, next place is rank 3 not 3rd
  overall position").
- Document in a comment *why* `RANK()` was chosen over `DENSE_RANK()` --
  future maintainers should not have to guess.

## Engineering Notes

`RANK()` and `DENSE_RANK()` share the same sorting cost as `ROW_NUMBER()`
but additionally require a tie-comparison against the previous row's
`ORDER BY` value, evaluated during the same single pass.

## Practice Questions

1. Assign rank to employees ordered by `emp_id`.
2. Show employee name and rank.
3. Show the employee with `rank = 1`.
4. Show the top 3 ranked employees.
5. Compare `ROW_NUMBER()` and `RANK()` side by side on `manager_id`.

## Difficulty

Beginner

## Estimated Time

20–25 minutes

## Learning Outcomes

- Correctly predict `RANK()` output on a dataset containing ties.
- Explain, in an interview, the difference between `RANK()` and
  `ROW_NUMBER()`.

## Related Topics

- `01_ROW_NUMBER`
- `03_DENSE_RANK`

## Next Topic

[`03_DENSE_RANK`](../03_DENSE_RANK/README.md)
