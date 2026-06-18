# LEFT JOIN

## Definition

LEFT JOIN returns all rows from the left table and matching rows from the right table.

If no match exists, NULL values are returned.

---

## Syntax

```sql
SELECT *
FROM table1
LEFT JOIN table2
ON table1.column = table2.column;
```

---

## Business Use Case

Find employees that may not belong to any department.

Useful for:

- Data quality checks
- Missing relationship detection
- HR audits

---

## Interview Tip

Remember:

LEFT table = always preserved.

---

## Common Mistakes

Confusing LEFT JOIN with INNER JOIN.

LEFT JOIN keeps unmatched left-side rows.

INNER JOIN removes them.

---

## Practice Questions

1. Show all employees and department names.
2. Find employees without departments.
3. Count unmatched records.
