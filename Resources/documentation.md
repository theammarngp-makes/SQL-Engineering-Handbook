# 📘 Documentation

*Part of the [Resources Library](README.md) — [SQL Engineering Handbook](../README.md)*

This is the one file in the library where "why is this here" barely needs an answer — it's the official word, straight from whoever builds the thing. When a module in this repo and a database's own documentation disagree, trust the documentation. Open an issue on the module.

> [!NOTE]
> Root documentation URLs are about as stable as links get — vendors rarely move their main docs domain. If one of these has moved by the time you're reading this, it's a fast PR: see [Contribution Guidelines](README.md#contribution-guidelines).

---

## Table of Contents

- [Relational Databases](#relational-databases)
- [Cloud Data Warehouses](#cloud-data-warehouses)
- [Analytical & Embedded Engines](#analytical--embedded-engines)
- [Analytics Engineering & Tooling](#analytics-engineering--tooling)

---

## Relational Databases

**Recommended reading order:** pick the dialect you're actually using and read that one's tutorial/getting-started section end to end before treating any of these as a reference. Don't read all six front to back — that's what `books.md` → *SQL Pocket Guide* is for.

### PostgreSQL Official Documentation

| Field | Details |
|---|---|
| Author / Organization | The PostgreSQL Global Development Group |
| Category | Relational Databases |
| Difficulty | Beginner (Tutorial) → Advanced (full manual) |
| Best For | The most complete, precisely written open-source database documentation available — the standard other docs get measured against |
| Why It Is Recommended | Written by the people who implement the features, updated on every release, and unusually exact about edge-case behavior (NULL handling, MVCC visibility rules) that third-party tutorials tend to gloss over |
| Key Topics Covered | SQL syntax and functions, indexing (B-tree, GIN, GiST, BRIN), MVCC and transaction isolation, extensions, `EXPLAIN` and query planning |
| Estimated Time | 2–3 hours for the Tutorial section; ongoing as reference after that |
| Official Website | `postgresql.org/docs/` |
| Free or Paid | Free |
| Prerequisites | None for the Tutorial; `03_JOINS` for the rest |
| Who Should Read It | Anyone using PostgreSQL, from first query to `EXPLAIN ANALYZE` |
| Related SQL Handbook Modules | Applies across all modules if PostgreSQL is your dialect |

### MySQL Official Documentation

| Field | Details |
|---|---|
| Author / Organization | Oracle Corporation |
| Category | Relational Databases |
| Difficulty | Beginner (Tutorial) → Advanced (Reference Manual) |
| Best For | Authoritative InnoDB and replication behavior, and MySQL-specific syntax variations |
| Why It Is Recommended | The only fully authoritative source for InnoDB locking behavior and replication semantics, which differ from PostgreSQL in ways that matter for correctness, not just syntax |
| Key Topics Covered | SQL syntax, InnoDB storage engine, replication, indexing, `EXPLAIN` |
| Estimated Time | 2 hours for Tutorial; ongoing as reference |
| Official Website | `dev.mysql.com/doc/` |
| Free or Paid | Free |
| Prerequisites | None for the Tutorial |
| Who Should Read It | Anyone using MySQL or MariaDB in production |
| Related SQL Handbook Modules | Applies across all modules if MySQL is your dialect |

### Microsoft Learn — SQL Server & Azure SQL

| Field | Details |
|---|---|
| Author / Organization | Microsoft |
| Category | Relational Databases |
| Difficulty | Beginner → Advanced |
| Best For | T-SQL specifics and the Azure SQL / Fabric platform ecosystem around SQL Server |
| Why It Is Recommended | Microsoft Learn consolidates docs, structured learning paths, and certification prep in one place — unusually good for going from zero to a specific credential |
| Key Topics Covered | T-SQL syntax, Intelligent Query Processing, indexing, Azure SQL Database, SQL Server on Linux |
| Estimated Time | 2–3 hours for the "Get started" learning path |
| Official Website | `learn.microsoft.com/en-us/sql/` |
| Free or Paid | Free |
| Prerequisites | None |
| Who Should Read It | Anyone on the Microsoft data stack, or preparing for a Microsoft data certification |
| Related SQL Handbook Modules | Applies across all modules if T-SQL is your dialect |

### Oracle Database SQL Documentation

| Field | Details |
|---|---|
| Author / Organization | Oracle Corporation |
| Category | Relational Databases |
| Difficulty | Intermediate → Advanced |
| Best For | Enterprise Oracle Database features — PL/SQL, partitioning, RAC — used in large legacy enterprise systems |
| Why It Is Recommended | The only authoritative source for Oracle-specific SQL extensions (hierarchical queries with `CONNECT BY`, analytic function variations) that diverge meaningfully from standard SQL |
| Key Topics Covered | SQL and PL/SQL reference, partitioning, Real Application Clusters (RAC), Autonomous Database |
| Estimated Time | Reference-style; budget 3–4 hours for the SQL Language Reference basics |
| Official Website | `docs.oracle.com/en/database/oracle/oracle-database/` |
| Free or Paid | Free |
| Prerequisites | `03_JOINS`, `05_SUBQUERIES` |
| Who Should Read It | Engineers in Oracle-standardized enterprise environments |
| Related SQL Handbook Modules | Applies across all modules if Oracle is your dialect |

### SQLite Documentation

| Field | Details |
|---|---|
| Author / Organization | The SQLite Consortium |
| Category | Relational Databases |
| Difficulty | Beginner → Intermediate |
| Best For | Understanding SQLite's intentionally different type system and its query planner, for embedded/local use cases |
| Why It Is Recommended | Unusually short and precisely written for a database manual — SQLite's own documentation is a good model of technical writing regardless of whether you use the database daily |
| Key Topics Covered | Dynamic typing rules, `EXPLAIN QUERY PLAN`, file format, `WITHOUT ROWID` tables |
| Estimated Time | 1–2 hours |
| Official Website | `sqlite.org/docs.html` |
| Free or Paid | Free |
| Prerequisites | `01_FUNDAMENTALS` |
| Who Should Read It | Mobile/embedded developers, and anyone prototyping locally before deploying to a client-server database |
| Related SQL Handbook Modules | `01_FUNDAMENTALS`, `15_INDEXES` |

### MariaDB Documentation (Knowledge Base)

| Field | Details |
|---|---|
| Author / Organization | MariaDB Foundation / MariaDB plc |
| Category | Relational Databases |
| Difficulty | Beginner → Advanced |
| Best For | Where MariaDB has diverged from MySQL since their fork — storage engines, JSON handling, and features MySQL doesn't have |
| Why It Is Recommended | Written specifically to flag divergence from MySQL, which is exactly the information a MySQL-background reader needs and won't get from MySQL's own docs |
| Key Topics Covered | Storage engines (Aria, ColumnStore), JSON functions, MariaDB-specific replication (Galera Cluster) |
| Estimated Time | 1–2 hours if you already know MySQL; longer otherwise |
| Official Website | `mariadb.com/kb/en/` |
| Free or Paid | Free |
| Prerequisites | MySQL Official Documentation, for comparison |
| Who Should Read It | Anyone migrating from or to MariaDB from MySQL |
| Related SQL Handbook Modules | Applies across all modules if MariaDB is your dialect |

## Cloud Data Warehouses

**Recommended reading order:** whichever platform your employer or project already uses. If choosing freely, Snowflake's docs are the most approachable starting point for warehouse-specific concepts (Time Travel, zero-copy cloning) before tackling BigQuery or Redshift's more infrastructure-heavy documentation.

### Snowflake Documentation

| Field | Details |
|---|---|
| Author / Organization | Snowflake Inc. |
| Category | Cloud Data Warehouses |
| Difficulty | Intermediate → Advanced |
| Best For | Snowflake-specific SQL extensions and warehouse architecture concepts (virtual warehouses, Time Travel, Streams/Tasks) |
| Why It Is Recommended | Clear separation between "SQL you already know" and "Snowflake-specific extensions," which makes it fast to onboard from a standard SQL background |
| Key Topics Covered | Virtual warehouses, semi-structured data (VARIANT), Time Travel, Streams and Tasks, Snowpark |
| Estimated Time | 2–3 hours for "Getting Started" |
| Official Website | `docs.snowflake.com` |
| Free or Paid | Free |
| Prerequisites | `18_SQL_BUSINESS_CASE_STUDIES` |
| Who Should Read It | Analytics/data engineers using or evaluating Snowflake |
| Related SQL Handbook Modules | `18_SQL_BUSINESS_CASE_STUDIES` |

### BigQuery Documentation

| Field | Details |
|---|---|
| Author / Organization | Google Cloud |
| Category | Cloud Data Warehouses |
| Difficulty | Intermediate → Advanced |
| Best For | Serverless, distributed SQL at very large scale, and BigQuery's specific pricing/performance model |
| Why It Is Recommended | Google Cloud's docs are unusually clear about the cost implications of query patterns — directly relevant since BigQuery bills by data scanned, not compute time |
| Key Topics Covered | GoogleSQL dialect specifics, partitioning and clustering, slot-based pricing, BigQuery ML |
| Estimated Time | 2–3 hours for "Quickstarts" |
| Official Website | `cloud.google.com/bigquery/docs` |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap basics |
| Who Should Read It | Data engineers on or evaluating the Google Cloud stack |
| Related SQL Handbook Modules | `13_SET_OPERATORS`, `16_QUERY_OPTIMIZATION` |

### Amazon Redshift Documentation

| Field | Details |
|---|---|
| Author / Organization | Amazon Web Services |
| Category | Cloud Data Warehouses |
| Difficulty | Intermediate → Advanced |
| Best For | Redshift's PostgreSQL-derived SQL dialect and its columnar, cluster-based architecture |
| Why It Is Recommended | Clearly documents where Redshift's SQL diverges from standard PostgreSQL (important, since it's built on Postgres but isn't a drop-in replacement) |
| Key Topics Covered | Distribution keys and sort keys, `COPY`/`UNLOAD`, workload management (WLM), Redshift Spectrum |
| Estimated Time | 2–3 hours for "Getting Started" |
| Official Website | `docs.aws.amazon.com/redshift/` |
| Free or Paid | Free |
| Prerequisites | PostgreSQL Official Documentation, for comparison |
| Who Should Read It | Data engineers on or evaluating the AWS data stack |
| Related SQL Handbook Modules | `13_SET_OPERATORS`, `16_QUERY_OPTIMIZATION` |

## Analytical & Embedded Engines

**Recommended reading order:** DuckDB first if you want a fast, local way to feel the difference between OLTP and OLAP query execution. Spark SQL once you're actually working with distributed, cluster-scale data.

### DuckDB Documentation

| Field | Details |
|---|---|
| Author / Organization | DuckDB Foundation |
| Category | Analytical & Embedded Engines |
| Difficulty | Beginner → Intermediate |
| Best For | Learning columnar, vectorized query execution hands-on, locally, with zero infrastructure setup |
| Why It Is Recommended | The fastest way to feel the practical difference between a row-store (Postgres/MySQL) and a column-store engine, since it runs embedded — no server, no cluster, just a file |
| Key Topics Covered | Columnar storage, vectorized execution, Parquet/CSV integration, SQL dialect compatibility notes |
| Estimated Time | 1–2 hours |
| Official Website | `duckdb.org/docs/` |
| Free or Paid | Free |
| Prerequisites | `01_FUNDAMENTALS` |
| Who Should Read It | Anyone curious about OLAP engines without wanting to stand up a warehouse first |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

### Apache Spark SQL Documentation

| Field | Details |
|---|---|
| Author / Organization | Apache Software Foundation |
| Category | Analytical & Embedded Engines |
| Difficulty | Advanced |
| Best For | Distributed SQL execution across a cluster, and the Catalyst optimizer that plans it |
| Why It Is Recommended | Primary source for how Spark's Catalyst optimizer and Tungsten execution engine plan and run distributed SQL — necessary reading before treating Spark SQL like "regular SQL on more machines" |
| Key Topics Covered | DataFrame/SQL API, Catalyst query optimizer, partitioning strategy, joins in a distributed context |
| Estimated Time | 3–4 hours for the SQL Programming Guide |
| Official Website | `spark.apache.org/docs/latest/sql-programming-guide.html` |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap, `16_QUERY_OPTIMIZATION` |
| Who Should Read It | Data engineers working with distributed processing frameworks |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION`, [`19_SQL_PROJECTS`](../19_SQL_PROJECTS/) |

## Analytics Engineering & Tooling

### dbt Documentation

| Field | Details |
|---|---|
| Author / Organization | dbt Labs |
| Category | Analytics Engineering & Tooling |
| Difficulty | Intermediate |
| Best For | Modeling, testing, and documenting SQL transformations the way a modern analytics team actually works |
| Why It Is Recommended | The primary source for dbt's modeling conventions (staging → intermediate → marts), testing framework, and the Semantic Layer — the practical backbone of the Analytics Engineer Roadmap |
| Key Topics Covered | Models, tests, macros (Jinja), sources and seeds, the Semantic Layer, project structure conventions |
| Estimated Time | 3–4 hours for the Quickstart |
| Official Website | `docs.getdbt.com` |
| Free or Paid | Free |
| Prerequisites | `06_CTEs`, Analytics Engineer Roadmap |
| Who Should Read It | Analytics engineers, or anyone on the Analytics Engineer Roadmap |
| Related SQL Handbook Modules | [`projects/nagpurlens`](../projects/nagpurlens/), [`projects/olist`](../projects/olist/) |

### SQLAlchemy Documentation

| Field | Details |
|---|---|
| Author / Organization | Michael Bayer and the SQLAlchemy project |
| Category | Analytics Engineering & Tooling |
| Difficulty | Intermediate → Advanced |
| Best For | Understanding how a Python ORM translates to the SQL underneath it — useful even if you write raw SQL, to know what an ORM is doing on your behalf |
| Why It Is Recommended | Unusually transparent about the generated SQL behind ORM operations (the docs actively show you the SQL each pattern produces), which builds intuition for spotting ORM-generated N+1 query problems |
| Key Topics Covered | Core expression language vs. ORM, session/transaction management, relationship loading strategies (lazy, eager) |
| Estimated Time | 3–4 hours for SQLAlchemy Core basics |
| Official Website | `docs.sqlalchemy.org` |
| Free or Paid | Free |
| Prerequisites | `03_JOINS`, comfort with Python |
| Who Should Read It | Backend developers using Python who want to understand the SQL their ORM generates |
| Related SQL Handbook Modules | Backend Developer Roadmap |

---

*Next in the library: [`youtube.md`](youtube.md). Back to [Resources Library](README.md).*
