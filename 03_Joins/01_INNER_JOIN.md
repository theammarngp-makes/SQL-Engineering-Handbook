# INNER JOIN

## Definition

INNER JOIN returns only the matching rows from both tables.

If there is no match, the row is excluded from the result.

---

## Syntax

```sql
SELECT *
FROM table1
INNER JOIN table2
ON table1.column = table2.column;
```

---

## Tables Used

- employes
- departments

---

## Business Use Case

Show each employee along with their department.

Used in:

- Employee reporting
- Workforce analysis
- Department tracking

---

## Common Mistakes

### Wrong

Forgetting the join condition.

```sql
SELECT *
FROM employes
JOIN departments;
```

### Correct

```sql
SELECT *
FROM employes e
JOIN departments d
ON e.dept_id = d.dept_id;
```

---

## Interview Tip

INNER JOIN only returns matching records.

Think:

"Give me only the rows that exist in both tables."

---

## Practice Questions

1. Show employees with department names.
2. Show employee IDs and department names.
3. Count employees in each department.
