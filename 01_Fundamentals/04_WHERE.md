# WHERE Clause

## Definition

The `WHERE` clause is used to filter rows based on a specified condition.

It helps retrieve only the records that satisfy a given requirement before any grouping or aggregation occurs.

---

## Syntax

```sql
SELECT column_name
FROM table_name
WHERE condition;
```

---

## Schema Used

### employes

| Column | Description |
|----------|-------------|
| emp_id | Employee ID |
| emp_name | Employee Name |
| dept_id | Department ID |
| manager_id | Reporting Manager |

---

## Sample Data

| emp_id | emp_name | dept_id | manager_id |
|---------|----------|----------|------------|
| 1 | Ammar | 1 | 3 |
| 2 | Riya | 2 | 3 |
| 3 | Sahil | 1 | NULL |
| 4 | Priya | 3 | 2 |
| 5 | Arjun | 2 | 1 |

---

## Examples

### Example 1: Find employees from Data Analytics department

```sql
SELECT *
FROM employes
WHERE dept_id = 1;
```

### Output

| emp_name |
|-----------|
| Ammar |
| Sahil |

---

### Example 2: Find employees who have a manager

```sql
SELECT *
FROM employes
WHERE manager_id IS NOT NULL;
```

---

### Example 3: Find top-level managers

```sql
SELECT *
FROM employes
WHERE manager_id IS NULL;
```

### Output

| emp_name |
|-----------|
| Sahil |

---

## Business Use Cases

- Find employees from a specific department
- Retrieve customers from a specific city
- Find completed orders
- Filter products above a specific price
- Generate department-specific reports

---

## Execution Order

SQL processes queries in the following order:

1. FROM
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY
7. LIMIT

Because `WHERE` runs before `GROUP BY`, it filters rows before aggregation occurs.

---

## Common Mistakes

### Wrong

```sql
SELECT *
FROM employes
WHERE manager_id = NULL;
```

### Correct

```sql
SELECT *
FROM employes
WHERE manager_id IS NULL;
```

---

### Wrong

```sql
SELECT dept_id, COUNT(*)
FROM employes
WHERE COUNT(*) > 1
GROUP BY dept_id;
```

### Correct

```sql
SELECT dept_id, COUNT(*)
FROM employes
GROUP BY dept_id
HAVING COUNT(*) > 1;
```

---

## Interview Tip

A very common SQL interview question:

### WHERE vs HAVING

| WHERE | HAVING |
|---------|---------|
| Filters rows | Filters groups |
| Executes before GROUP BY | Executes after GROUP BY |
| Cannot use aggregate functions | Can use aggregate functions |

Remember:

**WHERE → Rows**

**HAVING → Groups**

---

## Practice Questions

### Easy

1. Find employees from department 2.
2. Find employees with a manager.
3. Find employees without a manager.

### Intermediate

4. Find employees whose manager is Sahil.
5. Find employees not working in Engineering.

### Advanced

6. Find employees working in departments located in Nagpur.
7. Find employees whose department belongs to India.

---

## Related Topics

- SELECT
- GROUP BY
- HAVING
- INNER JOIN
- Subqueries
