# LIMIT

## Definition

LIMIT restricts the number of rows returned by a query.

---

## Syntax

```sql
SELECT *
FROM table_name
LIMIT 5;
```

---

## Business Use Cases

- Top 10 customers
- First 5 orders
- Dashboard previews

---

## Common Mistakes

LIMIT does not sort data.

Use ORDER BY before LIMIT when ranking results.
