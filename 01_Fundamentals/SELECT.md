# SELECT

## Definition

The SELECT statement is used to retrieve data from one or more columns in a table.

---

## Syntax

```sql
SELECT column_name
FROM table_name;
```

---

## Example

```sql
SELECT emp_name
FROM sqlemployees;
```

---

## Business Use Cases

- View employee names
- Retrieve customer information
- Generate reports

---

## Common Mistakes

❌ Missing FROM clause

```sql
SELECT emp_name;
```

✅ Correct

```sql
SELECT emp_name
FROM sqlemployees;
```

---

## Interview Tip

SELECT determines which columns will appear in the final output.
