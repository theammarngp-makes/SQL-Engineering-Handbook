# Database Schema Documentation

## Overview

This handbook uses a custom employee management database designed for learning SQL concepts ranging from fundamentals to advanced analytics.

The schema contains three related tables:

```text
employes
    │
    ▼
departments
    │
    ▼
locations
```

---

## Table: employes

Stores employee information.

| Column | Data Type | Description |
|----------|----------|----------|
| emp_id | INT | Employee ID |
| emp_name | VARCHAR(50) | Employee Name |
| dept_id | INT | Department ID |
| manager_id | INT | Reporting Manager |

---

## Table: departments

Stores department information.

| Column | Data Type | Description |
|----------|----------|----------|
| dept_id | INT | Department ID |
| dept_name | VARCHAR(50) | Department Name |
| location_id | INT | Location ID |

---

## Table: locations

Stores location information.

| Column | Data Type | Description |
|----------|----------|----------|
| location_id | INT | Location ID |
| city | VARCHAR(50) | City Name |
| country | VARCHAR(50) | Country Name |

---

## Relationships

### Employee → Department

Many employees belong to one department.

```text
employes.dept_id
      ↓
departments.dept_id
```

### Department → Location

Many departments can belong to one location.

```text
departments.location_id
        ↓
locations.location_id
```

### Employee → Manager

Self-referencing relationship.

```text
employes.manager_id
      ↓
employes.emp_id
```

---

## Concepts Demonstrated

- Primary Keys
- Foreign Keys
- Self Join Relationships
- Multi-table Joins
- Hierarchical Data

---

## Business Use Cases

- Workforce Analytics
- Department Reporting
- Manager Analysis
- Location Analysis
- Organizational Structure Reporting
