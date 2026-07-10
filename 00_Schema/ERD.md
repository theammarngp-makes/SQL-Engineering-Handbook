# Entity Relationship Diagram

```text
┌─────────────────────┐
│      employes       │
├─────────────────────┤
│ emp_id (PK)         │
│ emp_name            │
│ dept_id (FK)        │
│ manager_id (FK)     │
└──────────┬──────────┘
           │
           ▼

┌─────────────────────┐
│    departments      │
├─────────────────────┤
│ dept_id (PK)        │
│ dept_name           │
│ location_id (FK)    │
└──────────┬──────────┘
           │
           ▼

┌─────────────────────┐
│      locations      │
├─────────────────────┤
│ location_id (PK)    │
│ city                │
│ country             │
└─────────────────────┘
```

---

## Relationship Summary

- One Department → Many Employees
- One Location → Many Departments
- One Manager → Many Employees

This schema is intentionally simple so that core SQL concepts can be learned without unnecessary complexity.
