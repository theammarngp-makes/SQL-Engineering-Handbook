# SELF JOIN

## Definition

A SELF JOIN joins a table to itself.

Useful when rows have relationships with other rows in the same table.

---

## Schema Example

employees

| emp_id | emp_name | manager_id |
|---------|-----------|-----------|
| 1 | Ammar | 3 |
| 2 | Riya | 3 |
| 3 | Sahil | NULL |

---

## Business Use Case

Show employees and their managers.

Useful for:

- Organization hierarchy
- Reporting structure
- Team management

---

## Example

```sql
SELECT
e.emp_name AS employee,
m.emp_name AS manager
FROM employes e
LEFT JOIN employes m
ON e.manager_id = m.emp_id;
```

---

## Interview Tip

SELF JOIN is one of the most commonly asked join questions.

Especially in hierarchy-based datasets.

---

## Practice Questions

1. Show employees and managers.
2. Show employees without managers.
3. Count employees under each manager.
