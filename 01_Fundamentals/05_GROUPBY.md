# GROUP BY

## Definition

The GROUP BY clause is used to group rows that have the same values into summary rows.

It is commonly used with aggregate functions such as:

- COUNT()
- SUM()
- AVG()
- MIN()
- MAX()

---

## Syntax

```sql
SELECT column_name,
       aggregate_function(column_name)
FROM table_name
GROUP BY column_name;
```

---

## Schema Used

### employes

| Column | Description |
|----------|-------------|
| emp_id | Employee ID |
| emp_name | Employee Name |
| dept_id | Department ID |
| manager_id | Manager ID |

### departments

| Column | Description |
|----------|-------------|
| dept_id | Department ID |
| dept_name | Department Name |
| location_id | Location ID |

---

## Example

Count employees in each department.

```sql
SELECT
    dept_id,
    COUNT(*) AS employee_count
FROM employes
GROUP BY dept_id;
```

---

## Output

| dept_id | employee_count |
|----------|---------------|
| 1 | 2 |
| 2 | 2 |
| 3 | 1 |

---

## Business Use Cases

- Workforce planning
- Department size analysis
- Team distribution reports
- HR analytics

---

## Common Mistakes

### Wrong

```sql
SELECT emp_name, COUNT(*)
FROM employes
GROUP BY dept_id;
```

### Correct

```sql
SELECT dept_id, COUNT(*)
FROM employes
GROUP BY dept_id;
```

---

## Interview Tip

Every column in SELECT must either:

- Appear in GROUP BY
- Or be wrapped inside an aggregate function

---

## Related Topics

- COUNT()
- HAVING
- SUM()
- AVG()
