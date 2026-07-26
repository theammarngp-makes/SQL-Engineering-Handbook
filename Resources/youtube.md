# 🎥 YouTube

*Part of the [Resources Library](README.md) — [SQL Engineering Handbook](../README.md)*

Channels here were picked for a teaching track record, not view count. A few are full university courses filmed and published for free — treat those as textbook replacements, not casual watching.

---

## Table of Contents

- [SQL Fundamentals](#sql-fundamentals)
- [Advanced SQL](#advanced-sql)
- [Database Design](#database-design)
- [Analytics Engineering](#analytics-engineering)
- [Data Engineering](#data-engineering)
- [Performance Optimization](#performance-optimization)
- [Query Optimization](#query-optimization)
- [System Design](#system-design)
- [Data Warehousing](#data-warehousing)
- [Business Intelligence](#business-intelligence)
- [Interview Preparation](#interview-preparation)

---

## SQL Fundamentals

**Recommended order:** freeCodeCamp's full course first, start to finish, before anything else in this file.

### freeCodeCamp

| Field | Details |
|---|---|
| Channel | freeCodeCamp.org |
| Category | SQL Fundamentals |
| Difficulty | Beginner |
| Best Playlist | Full-length SQL/relational database courses (multi-hour, single-video format) |
| Why It Is Valuable | Complete, free, start-to-finish courses rather than fragmented short videos — you can genuinely learn fundamentals from a single sitting-based video |
| Recommended Order | Watch a full SQL fundamentals course video before branching into any other channel on this page |
| Estimated Time | 3–5 hours per full course video |
| Free or Paid | Free |
| Who Should Read It | Complete beginners |
| Related SQL Handbook Modules | `00_SAMPLE_DATABASE`, `01_FUNDAMENTALS` |

### Amigoscode

| Field | Details |
|---|---|
| Channel | Amigoscode |
| Category | SQL Fundamentals |
| Difficulty | Beginner–Intermediate |
| Best Playlist | SQL and relational database playlists, taught alongside real backend-development context |
| Why It Is Valuable | Ties SQL directly into how it's used inside an actual backend application, rather than teaching it in isolation |
| Recommended Order | After a first fundamentals pass — useful for seeing SQL "in context" |
| Estimated Time | 2–4 hours |
| Free or Paid | Free |
| Who Should Read It | Beginners who want to see SQL used inside a real application, not just a query console |
| Related SQL Handbook Modules | `01_FUNDAMENTALS`, `02_AGGREGATIONS` |

## Advanced SQL

**Recommended order:** Alex The Analyst for applied advanced patterns; CMU's full course only once you're ready for a genuine semester-length commitment.

### Alex The Analyst

| Field | Details |
|---|---|
| Channel | Alex The Analyst |
| Category | Advanced SQL |
| Difficulty | Intermediate–Advanced |
| Best Playlist | SQL project-based and advanced-query playlists |
| Why It Is Valuable | Project-driven teaching style — advanced techniques taught by building something, similar in spirit to this Handbook's business-case approach |
| Recommended Order | After `06_CTEs` and `07_WINDOW_FUNCTIONS` |
| Estimated Time | 3–5 hours |
| Free or Paid | Free |
| Who Should Read It | Intermediate learners moving into portfolio-project territory |
| Related SQL Handbook Modules | `07_WINDOW_FUNCTIONS`, `08_WINDOW_BUSINESS_CASES` |

### CMU Database Group

| Field | Details |
|---|---|
| Channel | Carnegie Mellon University Database Group (Andy Pavlo) |
| Category | Advanced SQL |
| Difficulty | Advanced |
| Best Playlist | "Intro to Database Systems" (15-445/645) — the full filmed semester course |
| Why It Is Valuable | A complete, rigorous university course on database internals published free — as close as YouTube gets to an actual CS graduate course on how databases work under the hood |
| Recommended Order | After the Advanced Roadmap's modules; treat as a multi-week commitment, not a single sitting |
| Estimated Time | 20–25 hours for the full course |
| Free or Paid | Free |
| Who Should Read It | Anyone serious about database internals, not just SQL syntax |
| Related SQL Handbook Modules | `15_INDEXES`, `16_QUERY_OPTIMIZATION` |

## Database Design

**Recommended order:** Stanford's course for the conceptual foundation, Database Star for quicker applied videos afterward.

### Stanford Online

| Field | Details |
|---|---|
| Channel | Stanford Online / Stanford Engineering (Jennifer Widom) |
| Category | Database Design |
| Difficulty | Intermediate–Advanced |
| Best Playlist | "Introduction to Databases" self-paced course videos |
| Why It Is Valuable | One of the most widely referenced free university database courses — rigorous relational theory and design taught by a leading database researcher |
| Recommended Order | After `03_JOINS`, before attempting a from-scratch schema design |
| Estimated Time | 15–20 hours for the full course |
| Free or Paid | Free |
| Who Should Read It | Anyone who wants the academic grounding behind schema design decisions |
| Related SQL Handbook Modules | `03_JOINS`, Database Design category in `books.md` |

### Database Star

| Field | Details |
|---|---|
| Channel | Database Star |
| Category | Database Design |
| Difficulty | Beginner–Intermediate |
| Best Playlist | Schema design and SQL concept explainer videos |
| Why It Is Valuable | Short, focused videos on individual design and query concepts — useful for a specific "wait, what's the difference between X and Y" question rather than a full course commitment |
| Recommended Order | As-needed reference alongside `books.md` → *Database Design for Mere Mortals* |
| Estimated Time | 10–20 min per video |
| Free or Paid | Free |
| Who Should Read It | Learners who want a quick, focused explainer rather than a long course |
| Related SQL Handbook Modules | `03_JOINS`, `14_VIEWS` |

## Analytics Engineering

### dbt Labs

| Field | Details |
|---|---|
| Channel | dbt Labs |
| Category | Analytics Engineering |
| Difficulty | Intermediate |
| Best Playlist | Conference talks (Coalesce) and product walkthroughs |
| Why It Is Valuable | Direct from the team defining analytics engineering practice — conference talks cover real modeling and testing patterns from practitioners, not just product demos |
| Recommended Order | After `documentation.md` → dbt Documentation Quickstart |
| Estimated Time | 20–40 min per talk |
| Free or Paid | Free |
| Who Should Read It | Anyone on the Analytics Engineer Roadmap |
| Related SQL Handbook Modules | [`projects/nagpurlens`](../projects/nagpurlens/) |

## Data Engineering

### Google Cloud Tech

| Field | Details |
|---|---|
| Channel | Google Cloud Tech |
| Category | Data Engineering |
| Difficulty | Intermediate–Advanced |
| Best Playlist | BigQuery and data engineering product playlists |
| Why It Is Valuable | Official product-team walkthroughs of BigQuery architecture and pricing — direct source rather than third-party interpretation |
| Recommended Order | Alongside `documentation.md` → BigQuery Documentation |
| Estimated Time | 15–30 min per video |
| Free or Paid | Free |
| Who Should Read It | Data engineers on or evaluating Google Cloud |
| Related SQL Handbook Modules | `13_SET_OPERATORS`, `16_QUERY_OPTIMIZATION` |

### MIT OpenCourseWare

| Field | Details |
|---|---|
| Channel | MIT OpenCourseWare |
| Category | Data Engineering |
| Difficulty | Advanced |
| Best Playlist | Database systems course lectures |
| Why It Is Valuable | Full MIT course lectures on database systems, free — rigorous systems-level treatment of the material underneath any data engineering pipeline |
| Recommended Order | After the Advanced Roadmap; a genuine multi-week commitment |
| Estimated Time | 20+ hours for a full course |
| Free or Paid | Free |
| Who Should Read It | Data engineers wanting the systems-course depth behind pipeline tools |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION`, [`19_SQL_PROJECTS`](../19_SQL_PROJECTS/) |

## Performance Optimization

### Hussein Nasser

| Field | Details |
|---|---|
| Channel | Hussein Nasser (`@hnasr`) |
| Category | Performance Optimization |
| Difficulty | Intermediate–Advanced |
| Best Playlist | Backend engineering and database performance playlists |
| Why It Is Valuable | Practicing backend engineer explaining real performance trade-offs (connection pooling, N+1 queries, indexing decisions) from production experience, not just theory |
| Recommended Order | After `16_QUERY_OPTIMIZATION` |
| Estimated Time | 15–40 min per video |
| Free or Paid | Free |
| Who Should Read It | Backend and data engineers debugging real performance problems |
| Related SQL Handbook Modules | `15_INDEXES`, `16_QUERY_OPTIMIZATION` |

## Query Optimization

### Decomplexify

| Field | Details |
|---|---|
| Channel | Decomplexify |
| Category | Query Optimization |
| Difficulty | Advanced |
| Best Playlist | Distributed systems and database theory explainers |
| Why It Is Valuable | Slow, deliberate first-principles explanations of concepts (consensus, replication, query planning) that most channels rush through |
| Recommended Order | After `books.md` → *SQL Performance Explained* |
| Estimated Time | 15–30 min per video |
| Free or Paid | Free |
| Who Should Read It | Anyone who wants the "why" behind an optimizer's decisions explained patiently |
| Related SQL Handbook Modules | `16_QUERY_OPTIMIZATION` |

## System Design

### ByteByteGo

| Field | Details |
|---|---|
| Channel | ByteByteGo |
| Category | System Design |
| Difficulty | Intermediate–Advanced |
| Best Playlist | System design fundamentals, including database-selection and scaling episodes |
| Why It Is Valuable | Clear, visual explanations of where a database fits inside a larger system — sharding, replication, and CAP trade-offs explained in the context of real architecture decisions |
| Recommended Order | After Data Engineer or Backend Developer Roadmap basics |
| Estimated Time | 8–15 min per video |
| Free or Paid | Free |
| Who Should Read It | Anyone prepping for a system design interview that includes data-layer questions |
| Related SQL Handbook Modules | Data Engineer Roadmap |

## Data Warehousing

### dbt Labs *(see Analytics Engineering above)* & Google Cloud Tech *(see Data Engineering above)*

Both channels above cover warehousing directly — dbt Labs from the modeling side, Google Cloud Tech from the BigQuery architecture side. No separate entries to avoid duplicating the cards above; see `books.md` → *The Data Warehouse Toolkit* for the foundational theory these videos assume.

## Business Intelligence

### Alex The Analyst *(see Advanced SQL above)*

The same channel's BI and dashboarding content (Tableau, Power BI, paired with the SQL feeding them) is the recommended entry point here — see the card under [Advanced SQL](#advanced-sql).

### Microsoft Developer

| Field | Details |
|---|---|
| Channel | Microsoft Developer |
| Category | Business Intelligence |
| Difficulty | Beginner–Intermediate |
| Best Playlist | Power BI and Azure data platform playlists |
| Why It Is Valuable | Official product-team content on how Power BI's data model and DAX layer connect back to the SQL underneath it |
| Recommended Order | After `documentation.md` → Microsoft Learn SQL Server & Azure SQL |
| Estimated Time | 15–30 min per video |
| Free or Paid | Free |
| Who Should Read It | Analysts building BI dashboards on top of SQL sources |
| Related SQL Handbook Modules | `18_SQL_BUSINESS_CASE_STUDIES` |

## Interview Preparation

**Note:** the staged interview plan lives in [`interview-resources.md`](interview-resources.md) — these two channels are the video-format complement, not the full plan.

### freeCodeCamp *(see SQL Fundamentals above)*

freeCodeCamp also publishes dedicated SQL interview-question walkthroughs — same channel as the fundamentals entry above.

### Alex The Analyst *(see Advanced SQL above)*

Regularly covers real Data Analyst interview experiences and SQL interview questions specifically — the same channel referenced under Advanced SQL and Business Intelligence above.

---

*Next in the library: [`interview-resources.md`](interview-resources.md). Back to [Resources Library](README.md).*
