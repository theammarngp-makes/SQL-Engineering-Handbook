# Interview Cheatsheet

Compact recall reference — full reasoning lives in the linked modules and questions.

## Logical Processing Order
```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
```
Window functions evaluate around SELECT — after WHERE/GROUP BY/HAVING.

## Common Traps
| Trap | The bug |
|---|---|
| `NOT IN` with nullable subquery | Silently returns zero rows if any NULL present (Q007) |
| `LEFT JOIN` + `COUNT(*)` | Reports 1, not 0, for unmatched rows — use `COUNT(joined_col)` (Q006) |
| Duplicate rows after JOIN | One-to-many fan-out — check cardinality before aggregating |
| Window ORDER BY misunderstood | Determines ranking AND the default frame for aggregate window functions |
| Integer division | `5/2 = 2` — cast explicitly |
| Timezone/date boundary | Filter shifts which "day" a row falls in without explicit handling |
| `COUNT(*)` vs `COUNT(col)` | Latter excludes NULLs (Q003) |
| `DISTINCT` hiding duplication | Masks a join fan-out instead of fixing it |
| Non-SARGable predicate | Function wrapping an indexed column defeats the index (Q017) |
| Implicit conversion | Mismatched types can defeat an index or produce wrong matches |

## Window Functions
| Function | Ties |
|---|---|
| `ROW_NUMBER()` | Never ties — arbitrary tiebreaker order |
| `RANK()` | Ties share rank; next rank skips ahead |
| `DENSE_RANK()` | Ties share rank; no skip |
| `LAG`/`LEAD` | Look back/forward n rows in partition order; NULL at edges |

## Joins
| Join | Behavior |
|---|---|
| INNER | Only matching rows both sides |
| LEFT | All left rows; unmatched right = NULL |
| FULL OUTER | All rows both sides; unmatched = NULL on missing side |
| CROSS | Every combination — deliberate cartesian product |

## NULL Logic
- `NULL = NULL` → UNKNOWN, not TRUE
- `NULL != X` → UNKNOWN — why `!=`/`NOT IN` silently break on NULLs
- Use `IS NULL`/`IS NOT NULL`, never `= NULL`

## Optimization
- SARGable = indexed column bare, nothing applied to it
- EXPLAIN cost is relative/unitless, not milliseconds
- Composite index: equality filters first, then range/sort columns

## Debugging Strategy
1. Reproduce with the smallest example
2. Check what actually changed before assuming query logic is wrong
3. Verify with EXPLAIN before proposing a fix

## Interview Strategy (For Candidates)
- State your understanding before writing SQL
- Narrate your approach as you write
- If stuck, state what you know and what's unclear — partial reasoning beats silence
