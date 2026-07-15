# 09 — Interview Guide: Views

**Module:** 14 — Views
**Previous:** [08 — Real-World Case Studies](08_REAL_WORLD_CASE_STUDIES.md) · **Next:** [10 — Practice Problems](10_PRACTICE_PROBLEMS.md)

---

This guide is structured in three tiers, matching how Views actually get tested: conceptual fluency (any Data Analyst interview), design/architecture (Analytics Engineering interviews), and "spot the bug" (both, and the most revealing tier).

## Tier 1 — Conceptual Fluency

**Q1. What is a View, exactly? Does it store data?**
No. A View stores a query definition in the catalog (`information_schema.VIEWS`). Every query against a View re-executes (or is merged into) that definition against current base-table data. There is no independent storage of rows.

**Q2. If I insert a row into a base table, does an existing View immediately reflect it?**
Yes, always — MySQL Views are never cached snapshots by default. There is no refresh step.

**Q3. What's the difference between a View and a CTE?**
A CTE exists only for the duration of a single query and isn't a catalog object. A View is permanent, named, reusable across sessions, queryable by other users/applications, and independently grantable.

**Q4. Can you index a View?**
No — indexes exist only on base tables. A View's performance depends entirely on the indexing of the tables it reads from.

**Q5. Does using a View make a query faster?**
No, never, by itself. A View adds zero performance benefit over its underlying query — it's an abstraction and reuse mechanism, not an optimization.

## Tier 2 — Design & Architecture

**Q6. Design a reporting layer for a company where Finance and Product need different definitions of "active customer" from the same raw tables.**
Expected shape: raw tables never queried directly by BI → one staging View normalizing/cleaning the raw data → two divergent reporting Views, each encoding one team's business rule explicitly, each documented → BI tools point only at the reporting layer. See Module 08.

**Q7. How would you restrict a role to see only aggregated salary data, never individual salaries?**
An aggregated `SQL SECURITY DEFINER` View grouping by department/role, granted `SELECT` instead of the base table; explicitly revoke/never-grant base table access to that role. Strong candidates also mention that column-level grants alone don't solve this, because they still expose one row per employee.

**Q8. Does MySQL support materialized Views? What do you do instead?**
No native support. The practical equivalent is a physical summary table refreshed on a schedule (via `EVENT` or an external ETL job), trading staleness for read speed — the same tradeoff Postgres/Snowflake materialized Views make explicit.

**Q9. You have a 3-layer nested View chain that's slow in production but fast in testing. Walk through your diagnosis.**
Run `EXPLAIN` (and `EXPLAIN FORMAT=TREE`) on the exact production query pattern; look for `Using temporary` at each layer; identify whether an outer filter is failing to push down into a `TEMPTABLE`-algorithm layer; consider flattening the chain or moving an aggregating layer to a scheduled summary table.

**Q10. When would you choose `SQL SECURITY INVOKER` over the default `DEFINER`?**
When you want the View to enforce access using the *querying* user's own privileges/context — e.g., a row-level "my own records" pattern relying on `CURRENT_USER()` — rather than a fixed elevated privilege level for every consumer.

## Tier 3 — Spot the Bug

**Q11.**
```sql
CREATE VIEW vw_active_orders AS
SELECT * FROM sales_orders WHERE status = 'PENDING';
```
*What's wrong?* `SELECT *` — any base table schema change silently changes this View's output columns. Also missing `WITH CHECK OPTION` if this View is meant to be written through.

**Q12.**
```sql
CREATE VIEW vw_pending AS
SELECT order_id, status FROM sales_orders WHERE status = 'PENDING'
WITH CHECK OPTION;
-- Application code:
UPDATE vw_pending SET status = 'COMPLETED' WHERE order_id = 106;
-- Application logs an error and the team is confused why "a simple update failed."
```
*What's wrong?* Nothing is wrong with the View — this is `WITH CHECK OPTION` working as intended. The update is correctly rejected because the resulting row would no longer satisfy `status = 'PENDING'`. The bug is in the application's expectation, not the SQL. This scenario tests whether a candidate understands `WITH CHECK OPTION`'s purpose or just recognizes the syntax.

**Q13.**
```sql
CREATE OR REPLACE ALGORITHM = MERGE VIEW vw_customer_totals AS
SELECT customer_id, SUM(total) AS lifetime_total
FROM orders
GROUP BY customer_id;
```
*What's wrong?* `ALGORITHM = MERGE` is only a hint; `GROUP BY` structurally disqualifies merge, so MySQL silently falls back to `TEMPTABLE` regardless. The hint isn't "wrong" syntactically, but the author likely misunderstands that it won't actually force merge behavior here.

**Q14.**
```sql
GRANT SELECT ON vw_salary_bands TO 'regional_manager'@'%';
GRANT SELECT ON hr_employees TO 'regional_manager'@'%';  -- "just in case reporting needs it"
```
*What's wrong?* The second grant defeats the entire point of the security View — `regional_manager` now has direct access to individual salaries regardless of what `vw_salary_bands` restricts.

**Q15.**
```sql
ALTER TABLE hr_employees DROP COLUMN annual_salary;
-- Migration passes CI with no errors. Two weeks later, vw_salary_bands
-- starts throwing errors in production.
```
*What's wrong / what should have happened?* MySQL does not block a column-level `ALTER TABLE` for View dependents the way it can for `DROP TABLE`. The migration should have included an `information_schema.VIEWS` dependency audit (Module 06) as a required pre-migration step; the failure was deferred to View query time, not caught in CI.

---

## How to Use This Guide

Work through Tier 1 until every answer is automatic. Tier 2 questions should be answered out loud, as a design conversation, not a one-liner — practice narrating tradeoffs. Tier 3 is best done cold: read only the code, find the bug before reading the explanation.

## Further Reading

- MySQL 8.0 Reference Manual — [Views](https://dev.mysql.com/doc/refman/8.0/en/views.html)
