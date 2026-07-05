# FIRST_VALUE(), LAST_VALUE(), and NTILE()

## Overview

`FIRST_VALUE()` and `LAST_VALUE()` retrieve the value at the **start**
and **end** of a window's frame. `NTILE(n)` divides the rows in a
window into `n` roughly equal-sized buckets and labels each row with
its bucket number.

## Learning Objectives

- Retrieve the first and last value in an ordered window.
- Understand why `LAST_VALUE()` requires an explicit frame clause to
  behave as expected.
- Split a result set into equal groups using `NTILE()`.

## Prerequisites

- `01_ROW_NUMBER`
- `04_PARTITION_BY`

## Syntax

```sql
FIRST_VALUE(column) OVER (ORDER BY sort_column) AS first_value

LAST_VALUE(column) OVER (
    ORDER BY sort_column
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
) AS last_value

NTILE(n) OVER (ORDER BY sort_column) AS bucket_number
```

## Dataset Used

`employes` joined to `departments`

## Examples

See [`06_first_last_ntile.sql`](./06_first_last_ntile.sql).

## Real World Applications

- Showing the "first" and "last" transaction in a customer's history.
- Splitting customers into quartiles/deciles for marketing segmentation.
- Identifying the earliest and latest event in a partitioned timeline.

## Business Use Cases

| Domain | Scenario |
|---|---|
| Marketing | Split customers into quartiles by spend (`NTILE(4)`) |
| Banking | First and last transaction per account statement |
| HR | First and last hire in each department |

## Common Mistakes

- Using `LAST_VALUE()` **without** the frame clause
  `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`. By
  default, SQL's window frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND
  CURRENT ROW`, so `LAST_VALUE()` silently returns the **current row**
  instead of the true last row in the partition -- a very common,
  hard-to-spot bug.
- Assuming `NTILE()` produces perfectly equal-sized groups -- when the
  row count is not evenly divisible by `n`, the earlier buckets absorb
  the extra rows.

## Best Practices

- Always pair `LAST_VALUE()` with an explicit frame clause.
- Document the intended bucket count for `NTILE()` and why that number
  was chosen (quartiles = 4, deciles = 10, etc.).

## Engineering Notes

`FIRST_VALUE()` works correctly with the default frame because
"first" and "current position" align naturally as the window grows;
`LAST_VALUE()` does not share that property, which is why it is the
single most-cited source of window-function bugs in production code
reviews.

## Practice Questions

1. Show the first employee using `FIRST_VALUE()`.
2. Show the last employee using `LAST_VALUE()` (with the correct
   frame clause).
3. Divide employees into buckets using `NTILE()`.

## Difficulty

Intermediate

## Estimated Time

25 minutes

## Learning Outcomes

- Correctly apply the frame clause required for `LAST_VALUE()`.
- Explain why `NTILE()` bucket sizes can differ by one row.

## Related Topics

- `04_PARTITION_BY`
- `07_RUNNING_TOTALS`

## Next Topic

[`07_RUNNING_TOTALS`](../07_RUNNING_TOTALS/README.md)
