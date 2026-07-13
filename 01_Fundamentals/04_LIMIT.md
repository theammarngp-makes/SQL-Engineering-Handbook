# LIMIT

## Definition

`LIMIT` restricts the number of rows a query returns. It's applied after every other clause — `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, and `ORDER BY` all run first, and `LIMIT` simply truncates the final result set.

---

## Syntax

```sql
SELECT *
FROM table_name
LIMIT 5;
```

Pagination with `OFFSET` — skip the first N rows, then return the next M:

```sql
SELECT *
FROM table_name
LIMIT 5 OFFSET 10;
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

### Example 1: Return only the first 3 rows

```sql
SELECT *
FROM employes
LIMIT 3;
```

Without `ORDER BY`, which 3 rows come back is not guaranteed — see [Common Mistakes](#common-mistakes).

---

### Example 2: Top-N — highest employee IDs first

```sql
SELECT *
FROM employes
ORDER BY emp_id DESC
LIMIT 3;
```

---

### Example 3: Pagination — page 2, 2 rows per page

```sql
SELECT *
FROM employes
ORDER BY emp_id
LIMIT 2 OFFSET 2;
```

Page 1 is `LIMIT 2 OFFSET 0`, page 2 is `LIMIT 2 OFFSET 2`, page 3 is `LIMIT 2 OFFSET 4`, and so on.

---

## Business Use Cases

- Top 10 highest-spending customers
- First 5 most recent orders on a dashboard
- Paginated results for an API or admin panel
- Sampling a large table during data exploration

---

## Execution Order

SQL executes queries in this order:

1. FROM
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY
7. **LIMIT**

`LIMIT` runs last — it truncates whatever the fully sorted, filtered result set looks like at that point.

---

## Common Mistakes

### Mistake 1: LIMIT does not sort data

`LIMIT` only cuts off rows — it has no opinion on *which* rows come first unless you tell it via `ORDER BY`.

❌ Wrong — "first 3" is undefined without a sort

```sql
SELECT *
FROM employes
LIMIT 3;
```

✅ Correct — deterministic "top 3"

```sql
SELECT *
FROM employes
ORDER BY emp_id
LIMIT 3;
```

---

### Mistake 2: Writing LIMIT before ORDER BY

❌ Wrong — syntax error in MySQL

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

## Interview Tip

Interviewers often ask: *"Write a query to find the 2nd highest salary."* The naive answer reaches for `LIMIT 1 OFFSET 1` after sorting descending — which works, but breaks silently on duplicate values (two employees tied for highest salary push the "2nd highest" down incorrectly). Knowing when `LIMIT`/`OFFSET` is the right tool versus when you need `DENSE_RANK()` (covered in the window functions module) is what separates a syntax-level answer from an engineering-level one.

---

## Practice Questions

### Easy

1. Return the first 3 employees (by `emp_id`, ascending).
2. Return the 2 employees with the highest `emp_id`.
3. Return the first 2 departments.

### Intermediate

4. Return employees 3 and 4 when sorted alphabetically by name (i.e. skip the first 2).
5. Design a pagination query returning page 3 of a 2-row-per-page employee listing.

### Advanced

6. Explain why `LIMIT` without `ORDER BY` is considered non-deterministic, and what could cause the same query to return different rows on different runs.

---

## Related Topics

- SELECT
- ORDER BY
- WHERE
- OFFSET
