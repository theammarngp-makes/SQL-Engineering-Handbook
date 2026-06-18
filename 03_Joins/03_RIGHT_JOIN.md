# RIGHT JOIN

## Definition

RIGHT JOIN returns all rows from the right table and matching rows from the left table.

If no match exists, NULL values are returned.

---

## Business Use Case

Identify departments that currently have no employees.

Useful for:

- Workforce planning
- Department audits
- Organizational reporting

---

## Interview Tip

RIGHT JOIN is simply a LEFT JOIN with table positions reversed.

Many analysts rarely use RIGHT JOIN in production.

---

## Practice Questions

1. Show all departments even if they have no employees.
2. Find departments without employees.
3. Count employees by department using RIGHT JOIN.
