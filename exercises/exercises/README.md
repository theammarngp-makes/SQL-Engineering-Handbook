# Exercises

Hands-on practice paired to each learning module. Every exercise runs against one of three **shared
datasets** in [`../datasets/`](../datasets/) — never one-off toy tables:
[`ecommerce`](../datasets/ecommerce/README.md), [`banking`](../datasets/banking/README.md), or
[`saas`](../datasets/saas/README.md). Each dataset's README documents its grain and intentional
data-quality traps. Each exercise's front matter names the dataset it uses.

**Baseline:** MySQL 8.0+. Any non-MySQL SQL block is fenced ```` ```sql postgresql```` and never presented as MySQL.

## Running the exercises

To practice an exercise by hand, load the dataset named in its front matter (`dataset:` field):

```bash
mysql -u root < ../datasets/<dataset>/schema.sql   # <dataset> = ecommerce | banking | saas
mysql -u root < ../datasets/<dataset>/seed.sql
```

To validate every exercise (the script loads each exercise's dataset itself, so no manual load is needed):

```bash
python3 ../scripts/validate_exercises.py   # structure + dialect + runs on MySQL + checks expected output
```

The validator needs a reachable MySQL 8.x server for its live checks (or `--no-db` for static checks only).
In a full repository checkout it also verifies module folders and relative links; in a standalone copy it
skips those two checks. See the docstring in [`../scripts/validate_exercises.py`](../scripts/validate_exercises.py).

## Difficulty

| Level | Difficulty | Means |
|---|---|---|
| L1 | BEGINNER | Single table, one concept, no NULLs or edge cases to reason about |
| L2 | EASY | Single table or simple two-table join; one filtering/aggregation twist |
| L3 | INTERMEDIATE | Multi-table join or subquery; grain and NULL handling matter |
| L4 | ADVANCED | Window functions, CTEs, or multi-step aggregation; a "the obvious query is wrong" trap |
| L5 | EXPERT | Combines several concepts; requires validating the result, not just producing one |

## Categories

`FOUNDATIONS` `FILTERING` `AGGREGATION` `JOINS` `SUBQUERIES` `CTES` `WINDOW_FUNCTIONS` `DATE_ANALYTICS`
`STRING_ANALYTICS` `NULL_LOGIC` `DATA_CLEANING` `BUSINESS_ANALYTICS` `PERFORMANCE` `DATABASE_ENGINEERING`
`PRODUCTION_DEBUGGING` `SET_OPERATORS`

_`SET_OPERATORS` was added beyond the original 15-category list once Module 13 got its first exercise —
UNION/INTERSECT/EXCEPT work don't cleanly fit any of the other categories._

## Structure of an exercise

Front matter (`id`, `title`, `module`, `category`, `difficulty`/`level`, `estimated_time_min`,
`business_domain`, `dataset`, `tables`, `mysql_version`, `related_interview`) then, in order:
Learning objectives · Business context · Scenario · Input assumptions · Task · Constraints ·
Expected output · Hints (exactly 3, progressive, in `<details>`) · Solution (exactly one plain
` ```sql ` block; optional ` ```sql setup ` blocks first) · Explanation (9 labeled points — see
any exercise for the labels) · Common mistakes (each with a ` ```sql wrong ` block that the
validator proves returns a *different* result than the solution) · Edge cases · Performance notes ·
Optional challenge · Related module / interview question.

## Index

| ID | Title | Module | Difficulty | Category | Dataset |
|---|---|---|---|---|---|
| [EX-01-001](01_fundamentals/EX-01-001_active-products-under-50.md) | Active Products Under $50 | [01_Fundamentals](../01_Fundamentals/) | BEGINNER (L1) | FOUNDATIONS | ecommerce |
| [EX-02-001](02_aggregations/EX-02-001_customers-by-segment-including-unclassified.md) | Customers by Segment, Including Unclassified | [02_Aggregations](../02_Aggregations/) | EASY (L2) | AGGREGATION | ecommerce |
| [EX-03-001](03_joins/EX-03-001_customers-with-zero-orders.md) | Customers With Zero Orders | [03_Joins](../03_Joins/) | EASY (L2) | JOINS | ecommerce |
| [EX-03-002](03_joins/EX-03-002_revenue-without-shipment-fan-out.md) | Revenue Without the Shipment Fan-Out | [03_Joins](../03_Joins/) | ADVANCED (L4) | JOINS | ecommerce |
| [EX-03-003](03_joins/EX-03-003_products-never-ordered.md) | Products That Have Never Been Ordered | [03_Joins](../03_Joins/) | EASY (L2) | JOINS | ecommerce |
| [EX-04-001](04_subqueries/EX-04-001_dormant-accounts-excluding-closed.md) | Dormant Accounts, Excluding Closed Ones | [04_Subqueries](../04_Subqueries/) | INTERMEDIATE (L3) | SUBQUERIES | banking |
| [EX-05-001](05_case_when/EX-05-001_account-balance-from-signed-transaction-types.md) | Account Balance from Signed Transaction Types | [05_CASE_WHEN](../05_CASE_WHEN/) | INTERMEDIATE (L3) | FILTERING | banking |
| [EX-06-001](06_ctes/EX-06-001_customers-with-strong-net-deposits.md) | Customers With Strong Net Deposits | [06_CTEs](../06_CTEs/) | EASY (L2) | CTES | banking |
| [EX-07-001](07_window_functions/EX-07-001_top-2-products-by-monthly-revenue.md) | Top-2 Products by Monthly Revenue | [07_Window_Functions](../07_Window_Functions/) | INTERMEDIATE (L3) | WINDOW_FUNCTIONS | ecommerce |
| [EX-08-001](08_window_business_cases/EX-08-001_running-balance-for-a-single-account.md) | Running Balance for a Single Account | [08_WINDOW_BUSINESS_CASES](../08_WINDOW_BUSINESS_CASES/) | ADVANCED (L4) | WINDOW_FUNCTIONS | banking |
| [EX-09-001](09_date_functions/EX-09-001_customer-tenure-and-days-since-last-order.md) | Customer Tenure and Days Since Last Order | [09_Date_Functions](../09_Date_Functions/) | INTERMEDIATE (L3) | DATE_ANALYTICS | ecommerce |
| [EX-10-001](10_string_functions/EX-10-001_finding-duplicate-customers-by-normalized-email.md) | Finding Duplicate Customers by Normalized Email | [10_STRING_FUNCTIONS](../10_STRING_FUNCTIONS/) | EASY (L2) | STRING_ANALYTICS | ecommerce |
| [EX-11-001](11_null_handling/EX-11-001_amount-actually-collected-per-order.md) | Amount Actually Collected per Order | [11_NULL_HANDLING_AND_DATA_CLEANING](../11_NULL_HANDLING_AND_DATA_CLEANING/) | INTERMEDIATE (L3) | NULL_LOGIC | ecommerce |
| [EX-11-002](11_null_handling/EX-11-002_products-with-no-recorded-cost.md) | Products With No Recorded Cost | [11_NULL_HANDLING_AND_DATA_CLEANING](../11_NULL_HANDLING_AND_DATA_CLEANING/) | BEGINNER (L1) | NULL_LOGIC | ecommerce |
| [EX-12-001](12_advanced_aggregations/EX-12-001_current-mrr-by-plan-with-a-grand-total.md) | Current MRR by Plan, With a Grand Total | [12_ADVANCED_AGGREGATIONS](../12_ADVANCED_AGGREGATIONS/) | INTERMEDIATE (L3) | AGGREGATION | saas |
| [EX-13-001](13_set_operators/EX-13-001_customers-with-savings-account-or-active-loan.md) | Customers With a Savings Account or an Active Loan | [13_SET_OPERATORS](../13_SET_OPERATORS/) | EASY (L2) | SET_OPERATORS | banking |
| [EX-14-001](14_views/EX-14-001_a-view-that-encodes-eligible-revenue-once.md) | A View That Encodes "Eligible Revenue" Once | [14_VIEWS](../14_VIEWS/) | INTERMEDIATE (L3) | DATABASE_ENGINEERING | ecommerce |
| [EX-15-001](15_indexes/EX-15-001_a-composite-index-that-actually-gets-used.md) | A Composite Index That Actually Gets Used | [15_INDEXES](../15_INDEXES/) | ADVANCED (L4) | PERFORMANCE | ecommerce |
| [EX-16-001](16_query_optimization/EX-16-001_rewriting-correlated-subquery-as-a-join.md) | Rewriting a Per-Row Correlated Subquery as a Join | [16_QUERY_OPTIMIZATION](../16_QUERY_OPTIMIZATION/) | ADVANCED (L4) | PERFORMANCE | ecommerce |

_19 exercises — every taught module (01–16) has at least one. Each carries a real, verified trap from its
dataset ([ecommerce](../datasets/ecommerce/README.md), [banking](../datasets/banking/README.md), or
[saas](../datasets/saas/README.md)) rather than a clean-data demo, and every solution, wrong-answer block,
and Expected-output table has been executed against a live MySQL 8.0 server — see `PROJECT_STATUS.md` for
what's next._
