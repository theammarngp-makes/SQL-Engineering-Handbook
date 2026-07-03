# Changelog

All notable changes to the SQL Engineering Handbook will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Foundation structure for SQL Engineering Handbook
- Core documentation and learning materials

---

## [1.0.0] - 2026-07-03

### Added

#### Module 1: Fundamentals
- **01_SELECT.md** - Retrieve columns and records from a table
- **02_WHERE.md** - Filter rows using logical conditions
- **03_ORDER_BY.md** - Sort results in ascending or descending order
- **04_LIMIT.md** - Return only the required number of rows
- **05_ALIAS.md** - Improve query readability using temporary names
- Complete SQL examples (.sql files) for all fundamental topics
- Module README with learning objectives and best practices

#### Module 2: Aggregations
- **01_COUNT.md** - Count the number of rows or non-null values
- **02_SUM.md** - Calculate the total of a numeric column
- **03_AVG.md** - Calculate the average of a numeric column
- **04_MIN_MAX.md** - Find the smallest and largest values
- **05_GROUP_BY.md** - Group rows that share a common value
- **06_HAVING.md** - Filter groups after aggregation
- Complete SQL examples (.sql files) for all aggregation topics
- Module README with business applications and best practices

#### Module 3: Joins
- **01_INNER_JOIN.md** - Combine rows from two tables based on common criteria
- **02_LEFT_JOIN.md** - Include all rows from left table with matching rows from right
- **03_RIGHT_JOIN.md** - Include all rows from right table with matching rows from left
- **04_FULL_OUTER_JOIN.md** - Include all rows from both tables
- **05_CROSS_JOIN.md** - Create Cartesian product of two tables
- Complete SQL examples (.sql files) for all join types
- Module README with join diagrams and real-world use cases

#### Module 4: Subqueries
- **01_SCALAR_SUBQUERIES.md** - Subqueries that return a single value
- **02_INLINE_VIEWS.md** - Subqueries that return multiple rows/columns
- **03_CORRELATED_SUBQUERIES.md** - Subqueries that reference outer query
- **04_EXISTS_NOT_EXISTS.md** - Check existence of records
- **05_IN_NOT_IN.md** - Filter based on subquery result set
- Complete SQL examples (.sql files) for all subquery patterns
- Module README with performance considerations

#### Module 5: CASE WHEN Statements
- **01_SIMPLE_CASE.md** - Simple CASE expressions
- **02_SEARCHED_CASE.md** - Searched CASE expressions
- **03_CASE_IN_AGGREGATIONS.md** - Using CASE with aggregate functions
- **04_CASE_FOR_SEGMENTATION.md** - Customer segmentation with CASE
- **05_NESTED_CASE.md** - Complex nested CASE statements
- Complete SQL examples (.sql files) for all CASE patterns
- Module README with business logic examples

#### Module 6: CTEs (Common Table Expressions)
- **01_BASIC_CTE.md** - Simple WITH clauses for query readability
- **02_MULTIPLE_CTES.md** - Multiple CTEs in a single query
- **03_RECURSIVE_CTE.md** - Recursive CTEs for hierarchical data
- **04_CTE_VS_SUBQUERIES.md** - Performance and readability comparison
- **05_ADVANCED_CTE_PATTERNS.md** - Complex CTE use cases
- Complete SQL examples (.sql files) for all CTE patterns
- Module README with readability improvements

#### Module 7: Window Functions
- **01_ROW_NUMBER.md** - Assign unique sequential numbers
- **02_RANK_DENSE_RANK.md** - Rank rows with gap handling
- **03_LAG_LEAD.md** - Access previous and next row values
- **04_RUNNING_TOTALS.md** - Calculate cumulative sums and counts
- **05_PARTITION_BY.md** - Window functions with PARTITION BY
- **06_FRAME_SPECIFICATIONS.md** - Control window frame boundaries
- Complete SQL examples (.sql files) for all window functions
- Module README with analytical queries and KPI calculations

#### Documentation
- **README.md** - Main handbook overview and navigation
- **LICENSE** - MIT License
- Module-specific README files with learning objectives
- **10_Schema/** - Custom database schema (employees, departments, locations)
- **00_Resources/** - Links to SQL tools and documentation

### Key Features
- 100+ production-ready SQL queries
- Real-world business context for each example
- Common mistakes and how to avoid them
- Interview preparation tips and follow-up questions
- Practice challenges and exercises
- Progression from Beginner → Intermediate → Advanced
- Estimated 40+ hours of learning content

---

## Types of Changes

- **Added** for new features.
- **Changed** for changes in existing functionality.
- **Deprecated** for soon-to-be removed features.
- **Removed** for now removed features.
- **Fixed** for any bug fixes.
- **Security** in case of vulnerabilities.

---

## Future Roadmap

### Planned for v1.1.0
- Query Optimization & Performance Tuning module
- Advanced window functions and analytical patterns
- Views and Materialized Views

### Planned for v1.2.0
- Advanced Business Analytics module
- Customer Segmentation queries
- Revenue Analysis and CLV calculations
- Retention and Cohort Analysis

### Planned for v2.0.0
- PostgreSQL-specific features and optimizations
- Advanced indexing strategies
- Transaction management and concurrency

---

## Contributing

To contribute to this changelog:
1. Follow the format above
2. Group changes by type (Added, Changed, etc.)
3. Link to relevant issues or pull requests when applicable
4. Ensure accuracy of dates and version numbers

For more information, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Support

If you find any errors in the changelog or have suggestions:
- Open an issue on GitHub
- Submit a pull request with corrections
- Reach out via the discussions tab

Your feedback helps us maintain accurate documentation.

---

<p align="center">
  <i>Part of the <a href="./">SQL Engineering Handbook</a></i>
</p>
