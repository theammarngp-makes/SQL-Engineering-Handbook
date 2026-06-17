# ORDER BY

## Definition

The `ORDER BY` clause is used to sort query results in ascending (`ASC`) or descending (`DESC`) order.

By default, SQL sorts data in ascending order.

---

## Why Use ORDER BY?

Without `ORDER BY`, SQL does not guarantee the order of returned rows.

Sorting is important for:

- Reports
- Dashboards
- Ranking employees
- Revenue analysis
- Top-N analysis

---

## Syntax

```sql
SELECT column_name
FROM table_name
ORDER BY column_name;
```

Ascending Order:

```sql
SELECT *
FROM employes
ORDER BY emp_name ASC;
```

Descending Order:

```sql
SELECT *
FROM employes
ORDER BY emp_name DESC;
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

---

## Sample Data

| emp_id | emp_name | dept_id |
|---------|----------|----------|
| 1 | Ammar | 1 |
| 2 | Riya | 2 |
| 3 | Sahil | 1 |
| 4 | Priya | 3 |
| 5 | Arjun | 2 |

---

## Example 1: Sort Employees Alphabetically

```sql
SELECT *
FROM employes
ORDER BY emp_name;
```

### Output

```text
Ammar
Arjun
Priya
Riya
Sahil
```

---

## Example 2: Sort Employees by ID Descending

```sql
SELECT *
FROM employes
ORDER BY emp_id DESC;
```

### Output

```text
5 Arjun
4 Priya
3 Sahil
2 Riya
1 Ammar
```

---

## Example 3: Sort by Department

```sql
SELECT *
FROM employes
ORDER BY dept_id;
```

---

## Example 4: Multiple Column Sorting

```sql
SELECT *
FROM employes
ORDER BY dept_id, emp_name;
```

SQL first sorts by department and then alphabetically within each department.

---

## Business Use Cases

### HR Analytics

Show newest employees first.

```sql
ORDER BY joining_date DESC
```

### Sales Dashboard

Show highest revenue first.

```sql
ORDER BY revenue DESC
```

### Customer Analytics

Show top spending customers.

```sql
ORDER BY total_spent DESC
```

### Management Reporting

Show departments by employee count.

```sql
ORDER BY employee_count DESC
```

---

## Common Mistakes

### Mistake 1

Assuming SQL automatically returns sorted data.

❌ Wrong Thinking

```sql
SELECT *
FROM employes;
```

Result order is not guaranteed.

✅ Correct

```sql
SELECT *
FROM employes
ORDER BY emp_name;
```

---

### Mistake 2

Using LIMIT before ORDER BY.

❌ Wrong

```sql
SELECT *
FROM employes
LIMIT 3
ORDER BY emp_name;
```

✅ Correct

```sql
SELECT *
FROM employes
ORDER BY emp_name
LIMIT 3;
```

---

## Execution Order

SQL executes queries in this order:

1. FROM
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY
7. LIMIT

---

## Interview Tip

### Difference Between ORDER BY ASC and DESC

ASC = Small → Large

```sql
ORDER BY emp_id ASC;
```

DESC = Large → Small

```sql
ORDER BY emp_id DESC;
```

---

## Practice Questions

### Easy

1. Sort employees by name.
2. Sort employees by department ID.
3. Sort employees by employee ID descending.

### Intermediate

4. Sort employees by department and then employee name.
5. Show departments alphabetically.

### Advanced

6. Show departments with employee counts sorted from highest to lowest.
7. Show cities sorted alphabetically.

---

## Related Topics

- SELECT
- WHERE
- LIMIT
- GROUP BY
- HAVING
