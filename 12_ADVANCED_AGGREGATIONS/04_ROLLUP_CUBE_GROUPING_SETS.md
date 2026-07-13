# 04 · ROLLUP, CUBE, and GROUPING SETS

> **Module:** 02 — Advanced Aggregations
> **Domain used in this file:** Retail (`sales`, `stores`, `regions`, `products`)
> **Companion file:** [`04_ROLLUP_CUBE_GROUPING_SETS.sql`](./04_ROLLUP_CUBE_GROUPING_SETS.sql)

---

## Introduction

Every finance report you've ever seen with subtotal rows and a grand total at the bottom was built with one of three tools: `ROLLUP`, `CUBE`, or `GROUPING SETS`. Without them, producing subtotals means running several separate `GROUP BY` queries at different levels and manually stacking the results — slow, error-prone, and impossible to keep consistent as data changes between runs. This topic is where multi-column `GROUP BY` (Topic 01) grows into full hierarchical reporting.

---

## Concept Overview

- **`ROLLUP(a, b)`** produces the full detail grouped by `(a, b)`, plus a subtotal grouped by `a` alone, plus one grand-total row — following the *hierarchy* of the column order given.
- **`CUBE(a, b)`** produces every possible combination of subtotals: `(a, b)`, `(a)`, `(b)`, and the grand total — with no assumed hierarchy.
- **`GROUPING SETS ((a, b), (a), ())`** lets you specify exactly which combinations you want, by hand — including combinations `ROLLUP` and `CUBE` wouldn't produce, like `(b)` alone without `(a)`.

`ROLLUP(a, b)` is equivalent to `GROUPING SETS ((a, b), (a), ())`. `CUBE(a, b)` is equivalent to `GROUPING SETS ((a, b), (a), (b), ())`. `GROUPING SETS` is the general-purpose tool; `ROLLUP` and `CUBE` are convenient shorthand for its two most common shapes.

---

## Business Motivation

A retail finance report needs: revenue per store per month, a subtotal per store across all months, and a company-wide grand total — all in one downloadable table, because that is exactly the shape a finance stakeholder expects to see in a spreadsheet or BI export. Building this by hand means three separate queries (detail, store subtotal, grand total) unioned together, with a real risk that the numbers drift out of sync if the underlying sales table is written to between queries. `ROLLUP` computes all three levels in a single, internally consistent aggregation pass.

---

## Why This Feature Exists

SQL's standard `GROUP BY` intentionally returns only one grain per query. `ROLLUP`, `CUBE`, and `GROUPING SETS` extend `GROUP BY` specifically to support the very common real-world need for **multiple grains, with totals, in one result set** — because that is the shape nearly every finance and executive report is expected to take, and recomputing it as several separate queries is both slower and harder to keep consistent.

---

## Real Company Examples

- **Retail chains** — revenue by store and month, with store subtotals and a company grand total, in the monthly board report.
- **Manufacturing** — production volume by plant and product line, with plant-level and company-level totals for capacity planning.
- **Telecom** — subscriber counts by plan and region, with regional and national totals for regulatory reporting.

---

## Business Problems Solved

- Financial statements and board reports requiring subtotals and grand totals
- Multi-level org-chart-style reporting (department → division → company)
- Any spreadsheet-style pivot table with row subtotals, produced directly by the database
- Dashboard export tables where the BI tool expects pre-computed totals rather than computing them client-side

---

## Visual Explanation

```
ROLLUP(region, store)                       Hierarchy: region ▸ store ▸ (grand total)

┌────────┬──────────┬─────────┐
│ region │ store     │ revenue │
├────────┼──────────┼─────────┤
│ East    │ Store A   │ 40,000  │  ◀ detail
│ East    │ Store B   │ 35,000  │  ◀ detail
│ East    │ NULL      │ 75,000  │  ◀ subtotal for East (GROUPING(store) = 1)
│ West    │ Store C   │ 28,000  │  ◀ detail
│ West    │ NULL      │ 28,000  │  ◀ subtotal for West
│ NULL    │ NULL      │ 103,000 │  ◀ grand total (GROUPING(region) = 1)
└────────┴──────────┴─────────┘
```

`CUBE(region, store)` would additionally include a subtotal grouped by `store` alone (across all regions), which `ROLLUP` does not produce because it follows a strict hierarchy.

---

## Syntax

```sql
-- ROLLUP: hierarchical subtotals following column order
SELECT region, store, SUM(revenue) AS total_revenue
FROM sales
GROUP BY ROLLUP(region, store);

-- CUBE: every possible subtotal combination
SELECT region, store, SUM(revenue) AS total_revenue
FROM sales
GROUP BY CUBE(region, store);

-- GROUPING SETS: hand-picked combinations only
SELECT region, store, SUM(revenue) AS total_revenue
FROM sales
GROUP BY GROUPING SETS ((region, store), (region), ());

-- GROUPING(): identify which columns are "rolled up" (NULL) in a given row
SELECT
    region, store, SUM(revenue) AS total_revenue,
    GROUPING(region) AS is_region_total,
    GROUPING(store)   AS is_store_total
FROM sales
GROUP BY ROLLUP(region, store);
```

---

## Detailed Walkthrough

```sql
SELECT
    r.region_name,
    s.store_name,
    SUM(sa.revenue)                    AS total_revenue,
    GROUPING(r.region_name)            AS is_region_subtotal,
    GROUPING(s.store_name)             AS is_store_subtotal
FROM sales   AS sa
JOIN stores  AS s ON sa.store_id  = s.store_id
JOIN regions AS r ON s.region_id  = r.region_id
GROUP BY ROLLUP(r.region_name, s.store_name)
ORDER BY r.region_name, s.store_name;
```

1. The engine first computes the full detail grain: one row per `(region, store)`.
2. It then adds a subtotal row per `region`, with `store_name` set to `NULL` — this is what `ROLLUP` adds beyond a plain `GROUP BY`.
3. Finally, it adds one grand-total row with both `region_name` and `store_name` set to `NULL`.
4. `GROUPING(column)` returns `1` on rows where that column has been "rolled up" into `NULL` for subtotal purposes, and `0` on genuine detail rows — this is how the presentation layer distinguishes a real `NULL` value from a subtotal marker.

---

## Production Workflow

`ROLLUP`/`CUBE`/`GROUPING SETS` queries commonly feed directly into finance export tables, scheduled PDF/Excel report generation, or BI tools that expect pre-built subtotal rows (many BI tools can also compute subtotals client-side, but pushing it into SQL keeps the report reproducible and consistent regardless of which tool renders it).

---

## Analytics Engineering Perspective

- **Never hardcode a label like `'All Stores'` into the data.** Use `GROUPING()` to detect subtotal rows and apply the label in the presentation layer (`COALESCE(store_name, CASE WHEN GROUPING(store_name)=1 THEN 'All Stores' END)`), keeping the raw aggregation output clean and machine-readable.
- **Prefer `GROUPING SETS` over `CUBE` once only specific combinations matter.** `CUBE` on more than 3–4 dimensions grows to 2ⁿ combinations fast; an explicit `GROUPING SETS` list is both cheaper and clearer about business intent.
- **`ROLLUP`'s hierarchy depends on column order.** `ROLLUP(region, store)` and `ROLLUP(store, region)` produce different subtotal rows — the first subtotals by region, the second by store — this is a frequent source of confusion in code review.

---

## Performance Considerations

- `ROLLUP(a, b)` on two columns produces at most 3 grouping levels; `CUBE(a, b)` produces at most 4. Each additional `CUBE` dimension doubles the number of grouping combinations (2ⁿ), so `CUBE` beyond 3–4 columns can become expensive quickly.
- `GROUPING SETS` computed explicitly is generally cheaper than `CUBE` when only a handful of the possible combinations are actually needed, since the engine doesn't compute combinations you didn't ask for.
- As with any `GROUP BY`, ensure `WHERE` filters the base rows before aggregation begins — subtotal and grand-total rows are computed from whatever rows survive the `WHERE` clause, not the full table.

---

## Edge Cases

- **Genuine `NULL` values vs. subtotal `NULL`s look identical without `GROUPING()`.** If `store_name` can legitimately be `NULL` in the source data (e.g., an online-only sale with no physical store), that row's `NULL` is indistinguishable from a `ROLLUP`-generated subtotal `NULL` unless `GROUPING()` is used to tell them apart.
- **`HAVING` with `ROLLUP`/`CUBE`.** Filtering with `HAVING SUM(revenue) > 10000` will also apply to subtotal and grand-total rows, potentially dropping a real subtotal that fails the same threshold as a detail row — check whether the filter should exempt subtotal rows using `GROUPING()`.
- **Column order matters for `ROLLUP`, not for `CUBE` or `GROUPING SETS`** (whose combinations are stated explicitly).

---

## Common Mistakes

- Assuming `ROLLUP` and `CUBE` produce the same output — `ROLLUP` follows a strict hierarchy; `CUBE` produces every combination.
- Hardcoding `'Total'`/`'All Regions'` labels directly into query output instead of using `GROUPING()` and applying labels in the presentation layer.
- Using `CUBE` on many columns without checking the resulting row count first, leading to a much larger and slower result set than intended.
- Applying `HAVING` without accounting for how it affects subtotal and grand-total rows.

---

## Best Practices

- Always include `GROUPING()` columns (or an equivalent `COALESCE` pattern) when a `ROLLUP`/`CUBE` query's output will be consumed by anything other than a human reading raw SQL output.
- Default to `ROLLUP` when the report has a natural hierarchy (region → store); default to `GROUPING SETS` when it doesn't, or when only specific combinations are needed; reach for `CUBE` only when every combination is genuinely useful.
- Test row counts before running `CUBE` against a large, high-cardinality table in production.
- Document the intended subtotal hierarchy directly above the query.

---

## Interview Questions

1. **What is the difference between `ROLLUP(a, b)` and `CUBE(a, b)`?**
   `ROLLUP` produces subtotals following the hierarchy `(a,b) → (a) → ()`. `CUBE` produces every combination: `(a,b), (a), (b), ()`.
2. **How do you tell a genuine `NULL` value in the source data apart from a `ROLLUP`-generated subtotal `NULL`?**
   Use the `GROUPING()` function, which returns `1` for rolled-up (subtotal) columns and `0` for real data rows.
3. **Why might `GROUPING SETS` outperform `CUBE` for the same reporting need?**
   `GROUPING SETS` computes only the explicitly listed combinations, while `CUBE` computes every possible combination (2ⁿ for n columns), many of which may not be needed.
4. **What's a risk of applying `HAVING` to a `ROLLUP` query without considering `GROUPING()`?**
   The `HAVING` condition also applies to subtotal and grand-total rows, potentially filtering out a legitimate subtotal that happens to fail the same threshold as a detail row.
5. **Is `ROLLUP(region, store)` the same as `ROLLUP(store, region)`?**
   No — `ROLLUP`'s subtotal hierarchy follows column order, so the two produce different subtotal levels.

---

## Summary

`ROLLUP`, `CUBE`, and `GROUPING SETS` extend `GROUP BY` to produce subtotals and grand totals in a single aggregation pass — exactly the shape financial and executive reports require. `ROLLUP` follows a hierarchy, `CUBE` produces every combination, and `GROUPING SETS` lets you specify exactly what you need by hand. `GROUPING()` is the tool that safely distinguishes a computed subtotal from a genuine `NULL` in the underlying data.

---

## Practice Challenges

1. Rewrite the walkthrough query using `CUBE` instead of `ROLLUP` and explain the extra row(s) it produces.
2. Rewrite the walkthrough query using `GROUPING SETS` to produce only `(region, store)` and the grand total — skipping the region-level subtotal entirely.
3. Add a `COALESCE`-based label column that reads `'All Stores'` on region subtotal rows and `'Company Total'` on the grand-total row, using `GROUPING()`.
4. Explain what would go wrong if `HAVING SUM(revenue) > 50000` were added to the walkthrough query without accounting for `GROUPING()`.
5. Design a `GROUPING SETS` query for a three-dimensional report (region, store, product category) that includes only region-level and store-level subtotals, skipping category-level and any two-way combinations.

---

## Further Reading

- [PostgreSQL Documentation — GROUPING SETS, CUBE, and ROLLUP](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-GROUPING-SETS)
- [MySQL 8.0 Reference Manual — GROUP BY Modifiers](https://dev.mysql.com/doc/refman/8.0/en/group-by-modifiers.html)
- [Microsoft Learn — GROUP BY (Transact-SQL): ROLLUP, CUBE, GROUPING SETS](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-group-by-transact-sql)

---

**◀ Previous:** [`03_CONDITIONAL_AGGREGATION.md`](./03_CONDITIONAL_AGGREGATION.md) · **Next ▶** [`05_BUSINESS_KPI_REPORTS.md`](./05_BUSINESS_KPI_REPORTS.md)
