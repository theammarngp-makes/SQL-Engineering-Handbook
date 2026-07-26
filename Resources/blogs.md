# 📰 Blogs

*Part of the [Resources Library](README.md) — [SQL Engineering Handbook](../README.md)*

Two tiers here, in order of authority: **vendor blogs** (the team that builds the database writing about the database) and **engineering blogs** (companies running these databases at a scale most of us will never personally operate at, writing about what broke and why). Both outrank generic "10 SQL Tips" content, which is why you won't find any of that here.

---

## Table of Contents

- [Official & Vendor Blogs](#official--vendor-blogs)
- [Engineering Blogs](#engineering-blogs)

---

## Official & Vendor Blogs

### Planet PostgreSQL

| Field | Details |
|---|---|
| Author / Organization | PostgreSQL community (aggregates official contributor blogs) |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | Following PostgreSQL development, release details, and internals commentary straight from core contributors |
| Why It Is Recommended | Aggregates posts directly from PostgreSQL committers and major contributors — closer to primary source than any single third-party PostgreSQL blog |
| Key Topics Covered | New release features, extension development, performance case studies, community events |
| Estimated Time | 15–20 min/week to skim |
| Official Website | `planet.postgresql.org` |
| Free or Paid | Free |
| Prerequisites | Comfortable with PostgreSQL basics |
| Who Should Read It | Anyone standardizing on PostgreSQL long-term |
| Related SQL Handbook Modules | Applies across all modules once a PostgreSQL dialect is chosen |

### Microsoft SQL Server Blog

| Field | Details |
|---|---|
| Author / Organization | Microsoft, SQL Server engineering team |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | SQL Server / Azure SQL release notes, performance features, and migration guidance straight from the product team |
| Why It Is Recommended | Direct product-team source for T-SQL feature changes and Azure SQL platform updates, rather than third-party interpretation |
| Key Topics Covered | T-SQL feature updates, query performance features (Intelligent Query Processing), Azure SQL and Fabric integration |
| Estimated Time | 15 min/week to skim |
| Official Website | Microsoft Tech Community, SQL Server section |
| Free or Paid | Free |
| Prerequisites | Comfortable with T-SQL basics |
| Who Should Read It | Backend developers and DBAs on the Microsoft data stack |
| Related SQL Handbook Modules | `14_VIEWS`, `15_INDEXES`, `16_QUERY_OPTIMIZATION` |

### MySQL Server Blog

| Field | Details |
|---|---|
| Author / Organization | Oracle, MySQL engineering team |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | MySQL/InnoDB release notes and replication features direct from the team that ships them |
| Why It Is Recommended | Primary source for InnoDB storage engine changes and replication behavior — the details that third-party MySQL tutorials tend to get slightly stale on |
| Key Topics Covered | InnoDB internals updates, replication, MySQL 8.x feature releases, security patches |
| Estimated Time | 15 min/week to skim |
| Official Website | Oracle's MySQL blog, hosted under `blogs.oracle.com/mysql` |
| Free or Paid | Free |
| Prerequisites | Comfortable with MySQL basics |
| Who Should Read It | Anyone running MySQL/InnoDB in production |
| Related SQL Handbook Modules | `14_VIEWS`, `15_INDEXES` |

### Oracle Database Blog

| Field | Details |
|---|---|
| Author / Organization | Oracle, Database engineering team |
| Category | Official & Vendor Blogs |
| Difficulty | Advanced |
| Best For | Enterprise-scale Oracle Database features (partitioning, RAC, autonomous database) |
| Why It Is Recommended | Direct source for Oracle-specific SQL extensions and enterprise features not covered by dialect-agnostic material |
| Key Topics Covered | PL/SQL updates, Autonomous Database, partitioning, enterprise performance tuning |
| Estimated Time | 15 min/week to skim |
| Official Website | `blogs.oracle.com/database` |
| Free or Paid | Free |
| Prerequisites | Comfortable with SQL fundamentals; Oracle-specific syntax varies from the Handbook's core schema |
| Who Should Read It | Engineers working in Oracle-standardized enterprise environments |
| Related SQL Handbook Modules | `14_VIEWS`, `16_QUERY_OPTIMIZATION` |

### Snowflake Blog

| Field | Details |
|---|---|
| Author / Organization | Snowflake |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | Cloud data warehouse architecture and Snowflake-specific SQL features (Streams, Tasks, Time Travel) |
| Why It Is Recommended | Snowflake popularized several warehouse patterns (separation of storage/compute, zero-copy cloning) that show up across the industry — worth understanding at the source |
| Key Topics Covered | Warehouse architecture, semi-structured data (VARIANT), performance and cost optimization, Snowpark |
| Estimated Time | 15–20 min/week |
| Official Website | `snowflake.com/blog` |
| Free or Paid | Free |
| Prerequisites | Data Warehousing category in `books.md`, or equivalent |
| Who Should Read It | Analytics and data engineers working with or evaluating cloud warehouses |
| Related SQL Handbook Modules | `18_SQL_BUSINESS_CASE_STUDIES` |

### Google Cloud Blog — Databases

| Field | Details |
|---|---|
| Author / Organization | Google Cloud |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | BigQuery and Cloud SQL feature updates and architecture patterns |
| Why It Is Recommended | Primary source for BigQuery's distributed query engine changes and pricing/performance trade-offs, which shift often enough that third-party tutorials go stale quickly |
| Key Topics Covered | BigQuery architecture and pricing, Cloud SQL, AlloyDB, Spanner |
| Estimated Time | 15–20 min/week |
| Official Website | `cloud.google.com/blog`, Databases category |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap basics |
| Who Should Read It | Data engineers on or evaluating the Google Cloud data stack |
| Related SQL Handbook Modules | `13_SET_OPERATORS`, `16_QUERY_OPTIMIZATION` |

### dbt Blog

| Field | Details |
|---|---|
| Author / Organization | dbt Labs |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate |
| Best For | Analytics engineering practice — testing, modeling conventions, and the "analytics as software engineering" philosophy |
| Why It Is Recommended | dbt Labs effectively named and popularized the "analytics engineer" role; this blog is the primary source for the practices that define it |
| Key Topics Covered | Data modeling conventions, testing strategy, the Analytics Engineering Guide, semantic layers |
| Estimated Time | 20 min/week |
| Official Website | `getdbt.com/blog` |
| Free or Paid | Free |
| Prerequisites | `06_CTEs`, familiarity with what dbt is (see `documentation.md`) |
| Who Should Read It | Anyone on the Analytics Engineer Roadmap |
| Related SQL Handbook Modules | [`projects/nagpurlens`](../projects/nagpurlens/), [`projects/olist`](../projects/olist/) |

### DuckDB Blog

| Field | Details |
|---|---|
| Author / Organization | DuckDB Labs / DuckDB Foundation |
| Category | Official & Vendor Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | Understanding embedded, in-process OLAP query engines — a genuinely different architecture from client-server databases |
| Why It Is Recommended | DuckDB's own team writes unusually clear internals posts explaining *why* an embedded columnar engine performs the way it does, which doubles as a readable intro to columnar storage in general |
| Key Topics Covered | Columnar storage, vectorized execution, embedded analytics, file-format integrations (Parquet, CSV) |
| Estimated Time | 20 min/week |
| Official Website | `duckdb.org/news` |
| Free or Paid | Free |
| Prerequisites | `16_QUERY_OPTIMIZATION` |
| Who Should Read It | Anyone curious how analytical (OLAP) engines differ architecturally from transactional (OLTP) ones |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

### ClickHouse Blog

| Field | Details |
|---|---|
| Author / Organization | ClickHouse, Inc. |
| Category | Official & Vendor Blogs |
| Difficulty | Advanced |
| Best For | Real-time analytics at very large scale — a different performance regime than most warehouse content covers |
| Why It Is Recommended | ClickHouse's engineering posts on benchmark methodology and columnar compression are unusually rigorous and transparent about trade-offs, not just marketing benchmarks |
| Key Topics Covered | Columnar compression, real-time ingestion, distributed query execution, benchmarking methodology |
| Estimated Time | 20 min/week |
| Official Website | `clickhouse.com/blog` |
| Free or Paid | Free |
| Prerequisites | `16_QUERY_OPTIMIZATION`, Data Engineer Roadmap |
| Who Should Read It | Data engineers working on high-throughput analytics systems |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

## Engineering Blogs

Company engineering blogs, not vendor blogs — these teams *use* databases at scale rather than build them, so the content skews toward real incidents, benchmarks, and architecture decisions instead of feature documentation.

### Netflix Tech Blog

| Field | Details |
|---|---|
| Author / Organization | Netflix |
| Category | Engineering Blogs |
| Difficulty | Advanced |
| Best For | Distributed data architecture at extreme scale, and the operational thinking (chaos engineering, graceful degradation) behind it |
| Why It Is Recommended | Consistently transparent about real incidents and the reasoning behind architecture changes, not just after-the-fact wins |
| Key Topics Covered | Distributed data stores, caching layers, resilience engineering, data platform architecture |
| Estimated Time | 20–30 min/week |
| Official Website | `netflixtechblog.com` |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap |
| Who Should Read It | Data and backend engineers interested in large-scale distributed systems |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

### Uber Engineering Blog

| Field | Details |
|---|---|
| Author / Organization | Uber |
| Category | Engineering Blogs |
| Difficulty | Advanced |
| Best For | Real-time, geospatially-heavy data systems and the migrations (like their well-documented MySQL work) behind them |
| Why It Is Recommended | Unusually detailed postmortems and migration write-ups — the kind of "here's exactly what we changed and why" content that's rare outside a company's own blog |
| Key Topics Covered | Geospatial indexing, real-time data pipelines, database migrations at scale, schema design for high-write workloads |
| Estimated Time | 20–30 min/week |
| Official Website | `uber.com/blog/engineering` |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap |
| Who Should Read It | Data engineers interested in write-heavy, real-time systems |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

### Airbnb Engineering & Data Science

| Field | Details |
|---|---|
| Author / Organization | Airbnb |
| Category | Engineering Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | Data infrastructure and analytics-engineering-adjacent tooling — Airbnb's data team originated Apache Airflow |
| Why It Is Recommended | One of the few company blogs that writes as much about the analytics/data-science side of the stack as the pure backend side, which fits an analytics engineer's day-to-day better than most engineering blogs |
| Key Topics Covered | Data pipeline orchestration, experimentation platforms, data quality tooling, analytics infrastructure |
| Estimated Time | 20 min/week |
| Official Website | Airbnb's engineering publication (currently hosted on Medium as `airbnb.io` / Airbnb Engineering & Data Science) |
| Free or Paid | Free |
| Prerequisites | Analytics Engineer Roadmap |
| Who Should Read It | Analytics engineers, especially anyone curious where dbt-style tooling and orchestration overlap |
| Related SQL Handbook Modules | [`projects/nagpurlens`](../projects/nagpurlens/) |

### Stripe Engineering Blog

| Field | Details |
|---|---|
| Author / Organization | Stripe |
| Category | Engineering Blogs |
| Difficulty | Advanced |
| Best For | Transactional correctness and financial-data integrity — a domain where "close enough" isn't acceptable |
| Why It Is Recommended | Stripe's business depends on exact financial correctness, so their posts on idempotency, consistency, and migrations are held to a higher precision bar than most engineering content |
| Key Topics Covered | Idempotent operations, transactional consistency, large-scale schema migrations, API and data reliability |
| Estimated Time | 20 min/week |
| Official Website | `stripe.com/blog/engineering` |
| Free or Paid | Free |
| Prerequisites | Backend Developer Roadmap |
| Who Should Read It | Backend developers building anything involving money or exactly-once semantics |
| Related SQL Handbook Modules | `14_VIEWS` |

### Cloudflare Blog

| Field | Details |
|---|---|
| Author / Organization | Cloudflare |
| Category | Engineering Blogs |
| Difficulty | Advanced |
| Best For | Data systems operating under extreme network-edge latency and scale constraints |
| Why It Is Recommended | Unusually deep, first-principles technical writing on distributed systems problems, including database and storage layer design at the network edge |
| Key Topics Covered | Edge data storage, distributed systems, incident postmortems, performance engineering |
| Estimated Time | 20–30 min/week |
| Official Website | `blog.cloudflare.com` |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap |
| Who Should Read It | Engineers interested in distributed systems and infrastructure-level data problems |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

### Meta Engineering Blog

| Field | Details |
|---|---|
| Author / Organization | Meta |
| Category | Engineering Blogs |
| Difficulty | Advanced |
| Best For | Data infrastructure at some of the largest scale publicly written about anywhere |
| Why It Is Recommended | Among the few sources with genuine, credible experience running relational and distributed data systems at Meta's scale — useful for understanding what breaks at the extreme end |
| Key Topics Covered | Distributed storage, data warehouse infrastructure, large-scale schema and query systems |
| Estimated Time | 20–30 min/week |
| Official Website | `engineering.fb.com` |
| Free or Paid | Free |
| Prerequisites | Data Engineer Roadmap |
| Who Should Read It | Data engineers interested in extreme-scale infrastructure |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

### Spotify Engineering Blog

| Field | Details |
|---|---|
| Author / Organization | Spotify |
| Category | Engineering Blogs |
| Difficulty | Intermediate–Advanced |
| Best For | Data platform and experimentation infrastructure supporting product analytics at scale |
| Why It Is Recommended | Strong, consistent coverage of the data-platform-for-product-analytics use case specifically — a good complement to Airbnb's more analytics-engineering-flavored posts |
| Key Topics Covered | Data platform architecture, experimentation infrastructure, event pipelines, internal analytics tooling |
| Estimated Time | 20 min/week |
| Official Website | `engineering.atspotify.com` |
| Free or Paid | Free |
| Prerequisites | Analytics Engineer Roadmap |
| Who Should Read It | Analytics and data engineers working on product-analytics platforms |
| Related SQL Handbook Modules | `18_SQL_BUSINESS_CASE_STUDIES` |

---

*Next in the library: [`documentation.md`](documentation.md). Back to [Resources Library](README.md).*
