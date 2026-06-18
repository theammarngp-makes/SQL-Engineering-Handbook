# Multi-Table Join

## Definition

A Multi-Table Join combines data from more than two tables.

This is extremely common in analytics projects.

---

## Schema Used

employees
    │
    ▼
departments
    │
    ▼
locations

---

## Business Question

Show each employee, their department, and their city.

---

## Example

```sql
SELECT
e.emp_name,
d.dept_name,
l.city
FROM employes e
JOIN departments d
ON e.dept_id = d.dept_id
JOIN locations l
ON d.location_id = l.location_id;
```

---

## Business Applications

- Employee location reporting
- Workforce distribution
- City-wise analytics
- Department performance analysis

---

## Interview Tip

Most real-world SQL work involves joining 3–6 tables, not just two.

Learning multi-table joins is critical for Data Analyst roles.

---

## Practice Questions

1. Show employee, department, and city.
2. Count employees by city.
3. Count employees by department and city.
4. Find departments located in Nagpur.
5. Find employees working in Pune.
