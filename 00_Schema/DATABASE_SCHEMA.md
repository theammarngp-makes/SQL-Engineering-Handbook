# Database Schema Documentation

## Overview

Every query in the SQL Engineering Handbook runs against a single, consistent
employee management database. Using one schema across all 65+ files — instead
of a different toy table per lesson — mirrors how you'd actually work against
a real company database, and lets concepts compound: a JOIN you learn in
Module 3 uses the exact same tables a Window Function uses in Module 7.

The schema contains three related tables:

```text
locations
    ▲
    │
departments
    ▲
    │
employes
```

Read the diagram bottom-up: many **employes** roll up into a **department**,
and many **departments** roll up into a **location**.

---

## Table: `employes`

Stores individual employee records, including a self-referencing manager
relationship.

| Column       | Data Type    | Nullable | Description                              |
|--------------|--------------|----------|-------------------------------------------|
| `emp_id`     | `INT`        | No (PK)  | Unique employee identifier                |
| `emp_name`   | `VARCHAR(50)`| Yes      | Employee's full name                      |
| `dept_id`    | `INT`        | Yes (FK) | References `departments.dept_id`          |
| `manager_id` | `INT`        | Yes (FK) | References `employes.emp_id` (self-join)  |
| `hire_date`  | `DATE`       | **No**   | Date the employee joined the company      |

> `manager_id` is `NULL` for top-level managers who report to no one in this
> dataset (e.g. `emp_id = 3`, `Sahil`).

**Sample rows:**

| emp_id | emp_name | dept_id | manager_id | hire_date  |
|--------|----------|---------|------------|------------|
| 1      | Ammar    | 1       | 11         | 2023-01-15 |
| 3      | Sahil    | 1       | NULL       | 2022-11-10 |
| 11     | Rohit    | 1       | NULL       | 2020-04-11 |

---

## Table: `departments`

Stores department metadata.

| Column        | Data Type    | Nullable | Description                        |
|---------------|--------------|----------|-------------------------------------|
| `dept_id`     | `INT`        | No (PK)  | Unique department identifier        |
| `dept_name`   | `VARCHAR(50)`| Yes      | Department name                     |
| `location_id` | `INT`        | Yes (FK) | References `locations.location_id`  |

**Sample rows:**

| dept_id | dept_name        | location_id |
|---------|------------------|-------------|
| 1       | Data Analytics   | 1           |
| 2       | Engineering      | 2           |

---

## Table: `locations`

Stores city/country metadata for each department's base of operations.

| Column         | Data Type    | Nullable | Description       |
|----------------|--------------|----------|--------------------|
| `location_id`  | `INT`        | No (PK)  | Unique location ID |
| `city`         | `VARCHAR(50)`| Yes      | City name          |
| `country`      | `VARCHAR(50)`| Yes      | Country name       |

**Sample rows:**

| location_id | city      | country |
|-------------|-----------|---------|
| 1           | Nagpur    | India   |
| 3           | Mumbai    | India   |

---

## Relationships

### `employes` → `departments` (many-to-one)

```text
employes.dept_id  →  departments.dept_id
```

Many employees belong to one department.

### `departments` → `locations` (many-to-one)

```text
departments.location_id  →  locations.location_id
```

Many departments can be based in one city.

### `employes` → `employes` (self-referencing, many-to-one)

```text
employes.manager_id  →  employes.emp_id
```

An employee reports to at most one manager, who is themself a row in the
same `employes` table. This relationship is what makes `03_Joins/04_SELF_JOIN.md`
and hierarchical query examples possible.

---

## Dataset Size

| Table         | Row Count |
|---------------|-----------|
| `locations`   | 5         |
| `departments` | 10        |
| `employes`    | 50        |

Source of truth for both structure and data:
- Structure: [`01_CREATE_TABLES.sql`](./01_CREATE_TABLES.sql)
- Data: [`02_INSERT_DATA.sql`](./02_INSERT_DATA.sql)

---

## Concepts This Schema Is Designed to Teach

- Primary keys and foreign keys
- One-to-many relationships
- Self-joins and hierarchical (manager → report) data
- Multi-table joins (3+ tables)
- NULL handling on optional foreign keys

---

## Business Use Cases Modeled by This Schema

- Workforce and headcount analytics
- Department-level performance reporting
- Manager span-of-control analysis
- Location-based organizational reporting
- Tenure and hiring trend analysis (via `hire_date`)

---

## Related Documentation

- [ERD.md](./ERD.md) — visual entity-relationship diagram
- [01_CREATE_TABLES.sql](./01_CREATE_TABLES.sql) — DDL
- [02_INSERT_DATA.sql](./02_INSERT_DATA.sql) — seed data

---

<p align="center">
  <i>Part of the <a href="../">SQL Engineering Handbook</a></i>
</p>
