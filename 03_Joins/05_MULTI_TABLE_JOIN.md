# Multi-Table Join

## Definition

A Multi-Table Join combines data from more than two tables.

This is one of the most important SQL skills because real-world databases are usually normalized into multiple related tables.

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

## Tables

### employes

| Column |
|----------|
| emp_id |
| emp_name |
| dept_id |
| manager_id |

### departments

| Column |
|----------|
| dept_id |
| dept_name |
| location_id |

### locations

| Column |
|----------|
| location_id |
| city |
| country |

---

## Concepts Practiced

- Multi-table JOIN
- Filtering with WHERE
- Aggregation with GROUP BY
- Counting records
- Foreign Key Relationships

---

## Business Applications

- Employee reporting
- Department analysis
- Location analytics
- Workforce planning
- Organizational reporting

---

## Interview Tip

Many SQL interview questions involve joining 3 or more tables.

A strong understanding of relationships between tables is essential for Data Analyst roles.

---

## Practice Questions

1. Show each employee with department and city.
2. Show employees working in Pune.
3. Count employees in each city.
4. Count employees in each department.
5. Show departments located in Nagpur.
