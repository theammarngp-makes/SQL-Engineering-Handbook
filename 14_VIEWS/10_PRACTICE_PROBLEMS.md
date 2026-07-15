# 10 — Practice Problems

**Module:** 14 — Views
**Previous:** [09 — Interview Guide](09_INTERVIEW_GUIDE.md) · **Next:** [11 — Solutions](11_SOLUTIONS.sql)

---

Attempt every problem closed-book against the schema built in `01_INTRODUCTION_TO_VIEWS.sql` and `08_REAL_WORLD_CASE_STUDIES.sql` before checking `11_SOLUTIONS.sql`. Problems are ordered by difficulty within each section.

## Section A — Foundational (Difficulty: Easy)

**A1.** Create a View `vw_amer_customers` exposing only customers in the `'AMER'` region, with explicit column names.

**A2.** Create a View `vw_completed_orders` exposing `order_id`, `customer_id`, and `order_date` for orders with `status = 'COMPLETED'`, with `WITH CHECK OPTION`.

**A3.** Without running any SQL, state whether `vw_completed_order_revenue` (Module 01) is updatable, and justify your answer using the rules from Module 03.

## Section B — Intermediate (Difficulty: Medium)

**B1.** Build a View `vw_department_headcount_costs` joining `hr_departments` and `hr_employees`, showing `department_name`, `headcount`, and `total_annual_cost` (sum of `annual_salary`), including departments with zero employees.

**B2.** Build a `SQL SECURITY DEFINER` View `vw_customer_order_counts` exposing `customer_name` and `completed_order_count` per customer, suitable for granting to a role with no direct access to `sales_orders`.

**B3.** Using `EXPLAIN`, determine whether `vw_department_headcount_costs` (B1) uses `MERGE` or `TEMPTABLE`, and explain why before checking.

**B4.** Create an updatable View `vw_active_hr_departments` over `hr_departments` filtered to `region != 'EMEA'`, with `WITH LOCAL CHECK OPTION`. Write one `UPDATE` statement that should succeed and one that should be rejected, and state which is which before running them.

## Section C — Advanced / Architecture (Difficulty: Hard)

**C1.** Design a 3-layer View architecture (staging + two divergent reporting Views) for a Retail scenario: Marketing wants "customers reachable for a promotion" (any customer with a completed order in the last 12 months, regardless of refund history), while Finance wants "customers contributing to net revenue" (completed orders minus refunded order value, last 12 months only). Use `sales_customers`, `sales_orders`, `sales_order_items`.

**C2.** Write the `information_schema.VIEWS` audit query you would run before renaming `hr_employees.annual_salary` to `hr_employees.base_salary`, and list every View built across this module's `.sql` files that it should find.

**C3.** Design a scheduled "materialized view equivalent" (physical summary table + `EVENT`) for `vw_monthly_revenue_growth` (Module 05), refreshed daily at 2 AM, and justify the refresh frequency choice given the underlying data's actual update pattern (order data arriving throughout each business day).

**C4.** A colleague proposes nesting `vw_customer_segment_summary` (Module 05) inside a new View that further joins it to `finance_accounts` for a "full customer 360" report queried by a real-time customer service tool on every support ticket open. Identify the performance risk using concepts from Module 07, and propose an alternative architecture.

---

## Self-Check

Before moving to `11_SOLUTIONS.sql`, for every problem you completed, ask:

- Did I name columns explicitly, never `SELECT *`?
- Did I consider whether `WITH CHECK OPTION` was needed?
- Did I reason about `MERGE` vs `TEMPTABLE` before running `EXPLAIN`, not just after?
