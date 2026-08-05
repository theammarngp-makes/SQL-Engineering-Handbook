<!-- Banner with gradient background and styling -->
<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; border-radius: 10px; text-align: center; margin-bottom: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
  <h1 style="color: white; margin: 0; font-size: 2.5em; font-weight: bold;">📊 Database Schema Foundation</h1>
  <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0; font-size: 1.1em;">The unified employee management database behind all SQL Engineering Handbook examples</p>
</div>

---

## 🎯 Overview

The **00_Schema** module contains the complete database schema, setup instructions, and documentation for the employee management database used throughout the SQL Engineering Handbook. 

Instead of using different toy tables for each lesson, **every query across all 65+ files** runs against this single, consistent schema. This approach mirrors real-world database work and allows concepts to build on each other—a JOIN technique you learn in Module 3 uses the exact same tables as Window Functions in Module 7.

---

## 📁 Contents

### Files in this directory:

| File | Purpose |
|------|---------|
| **01_CREATE_TABLES.sql** | Database table definitions (DDL) for creating the three core tables |
| **02_INSERT_DATA.sql** | Seed data with 50 employees, 10 departments, and 5 locations |
| **DATABASE_SCHEMA.md** | Comprehensive schema documentation with table definitions and relationships |
| **ERD.md** | Entity Relationship Diagram showing table structure and connections |
| **README.md** | This file |

---

## 🗂️ Schema Structure

The database consists of **three related tables**:

```
┌─────────────────────┐
│      employes       │ ◄── 50 employees
├─────────────────────┤
│ emp_id (PK)         │
│ emp_name            │
│ dept_id (FK) ──┐    │
│ manager_id (FK│    │
│ hire_date      │    │
└──────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │    departments      │ ◄── 10 departments
        ├─────────────────────┤
        │ dept_id (PK)        │
        │ dept_name           │
        │ location_id (FK)──┐ │
        └─────────────────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │      locations      │ ◄── 5 locations
                ├─────────────────────┤
                │ location_id (PK)    │
                │ city                │
                │ country             │
                └─────────────────────┘
```

### Key Relationships:

- **Employee → Department**: Many employees work in one department (many-to-one)
- **Department → Location**: Many departments operate from one location (many-to-one)
- **Employee → Employee**: Employees report to managers (self-referencing join)

---

## 📋 Table Details

### 👥 `employes` Table
Stores individual employee records with manager hierarchy.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `emp_id` | INT | PRIMARY KEY | Unique employee identifier |
| `emp_name` | VARCHAR(50) | nullable | Employee's full name |
| `dept_id` | INT | FOREIGN KEY | References departments |
| `manager_id` | INT | FOREIGN KEY (self) | Reports to (nullable for top managers) |
| `hire_date` | DATE | NOT NULL | Join date at company |

**Sample Data:**
- 50 employee records spanning 10 departments
- Hierarchical manager structure with multiple reporting levels
- Hire dates ranging from 2018 to 2025 for temporal analysis examples

---

### 🏢 `departments` Table
Stores department metadata.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `dept_id` | INT | PRIMARY KEY | Unique department identifier |
| `dept_name` | VARCHAR(50) | nullable | Department name |
| `location_id` | INT | FOREIGN KEY | References locations |

**Sample Departments:**
- Data Analytics, Engineering, Marketing, Finance
- Human Resources, Sales, Operations, Product
- Customer Support, IT Infrastructure

---

### 🌍 `locations` Table
Stores city and country information.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `location_id` | INT | PRIMARY KEY | Unique location identifier |
| `city` | VARCHAR(50) | nullable | City name |
| `country` | VARCHAR(50) | nullable | Country name |

**Locations:**
- 5 Indian cities: Nagpur, Pune, Mumbai, Hyderabad, Bengaluru

---

## 🚀 Quick Start

### 1. **Create the Schema**
Run the DDL to create all tables:
```bash
# Execute 01_CREATE_TABLES.sql in your SQL environment
```

### 2. **Load Sample Data**
Populate with 50 employees across 10 departments:
```bash
# Execute 02_INSERT_DATA.sql
```

### 3. **Verify Setup**
```sql
SELECT COUNT(*) FROM employes;      -- Should return 50
SELECT COUNT(*) FROM departments;   -- Should return 10
SELECT COUNT(*) FROM locations;     -- Should return 5
```

---

## 📚 Learning Objectives

This schema teaches and reinforces:

✅ **Primary Keys & Foreign Keys** — Understanding table uniqueness and referential integrity  
✅ **One-to-Many Relationships** — How data normalizes across related tables  
✅ **Self-Joins & Hierarchies** — Manager-to-employee reporting chains  
✅ **Multi-Table Joins** — Combining 3+ tables in a single query  
✅ **NULL Handling** — Optional foreign keys for top-level managers  

---

## 💼 Real-World Use Cases

This schema models common business scenarios:

- **Workforce Analytics** — Headcount by department, tenure analysis
- **Organizational Reporting** — Department structure and locations
- **Manager Span-of-Control** — How many direct reports per manager
- **Location-Based Reporting** — Staff distribution across cities
- **Hiring Trends** — Timeline of employee onboarding

---

## 🔗 Related Documentation

📖 **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** — Full schema documentation with detailed descriptions  
📊 **[ERD.md](./ERD.md)** — Visual entity-relationship diagram  
💾 **[01_CREATE_TABLES.sql](./01_CREATE_TABLES.sql)** — Table creation DDL  
📥 **[02_INSERT_DATA.sql](./02_INSERT_DATA.sql)** — Sample data insertion  

---

## 🎓 How This Schema Connects to Modules

| Module | Uses Tables | Key Concept |
|--------|-------------|-------------|
| **01_Fundamentals** | employes | SELECT, WHERE basics |
| **03_Joins** | employes, departments, locations | INNER/LEFT/RIGHT JOINs |
| **06_CTEs** | all tables | Hierarchical queries with WITH |
| **07_Window_Functions** | employes, departments | ROW_NUMBER over departments |
| **08_WINDOW_BUSINESS_CASES** | all tables | Real-world analytics |
| **12_ADVANCED_AGGREGATIONS** | all tables | GROUP BY with HAVING |
| **13_SET_OPERATORS** | employes | UNION, EXCEPT operations |

---

## 📊 Dataset Statistics

| Metric | Value |
|--------|-------|
| Total Employees | 50 |
| Total Departments | 10 |
| Total Locations | 5 |
| Manager-Employee Pairs | 40+ |
| Top-Level Managers (NULL manager_id) | 10 |
| Date Range (hire_date) | 2018–2025 |

---

## ⚠️ Important Notes

- **Database Consistency**: The schema across all modules is identical. If you update this schema, changes propagate to all 65+ files.
- **Normalized Design**: Tables are in 3rd Normal Form (3NF) to demonstrate proper database design.
- **Sample Data Scale**: With 50 employees, queries execute quickly while remaining realistic enough for meaningful analytics.
- **NULL Values**: `manager_id` is intentionally NULL for top-level managers to teach NULL handling.

---

## 📞 Support & Questions

For questions about:
- **Schema structure**: See [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)
- **How to use in queries**: Check modules [03_Joins](../03_Joins) and [07_Window_Functions](../07_Window_Functions)
- **Contributing changes**: Read [CONTRIBUTING.md](../CONTRIBUTING.md)

---

<div style="background-color: #f0f4ff; padding: 20px; border-left: 4px solid #667eea; border-radius: 5px; margin-top: 30px;">
  <p style="margin: 0;">
    <strong>💡 Tip:</strong> Bookmark this schema reference! You'll return to it often as you progress through the handbook. Understanding the relationships between these three tables unlocks mastery of JOINs, aggregations, and advanced SQL concepts.
  </p>
</div>

---

<p align="center">
  <i>Part of the <a href="https://github.com/theammarngp-makes/SQL-Engineering-Handbook">SQL Engineering Handbook</a></i><br/>
  <strong>Foundation module for all SQL learning examples</strong>
</p>
