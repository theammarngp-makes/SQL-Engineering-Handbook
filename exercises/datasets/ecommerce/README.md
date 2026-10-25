# Dataset: E-commerce

**Database:** `handbook_ecommerce` · **Engine:** MySQL 8.0+, InnoDB, utf8mb4
**As-of date:** the data ends **2025-06-30**; exercises treat **2025-07-01** as "today".

```bash
mysql -u root < schema.sql
mysql -u root < seed.sql
```

## Grain

| Table | One row = |
|---|---|
| `customers` | one signed-up person (24 rows) |
| `products` | one sellable SKU (12 rows, 1 inactive) |
| `orders` | one checkout event (49 rows) |
| `order_items` | one product line within one order (91 rows) — **this is the revenue grain**, not `orders` |
| `payments` | one payment attempt on one order — an order can have 0, 1, or several |
| `refunds` | one refund against one payment; `order_item_id` NULL means order-level, not tied to a line |
| `shipments` | one shipment on one order — an order can have more than one (split shipment) |
| `reviews` | one rating; not constrained to buyers, and a customer can review the same product twice |

## Relationships

`customers 1—N orders 1—N order_items N—1 products` · `orders 1—N payments 1—N refunds` · `orders 1—N shipments` · `customers N—N products via reviews`

## Known data-quality traps (intentional — teach with these, don't "fix" them)

- **`orders.status`** is `placed | shipped | delivered | cancelled | returned`. Revenue and "units sold" queries must state which statuses count — a plain `COUNT(*)` on `orders` double-counts nothing, but summing `order_items` for *all* statuses overstates revenue by including cancelled orders.
- **Email is not unique, and the column is deliberately case-sensitive** (`utf8mb4_0900_as_cs`, not
  MySQL's usual case-insensitive default). Customer 7 and customer 19 are the same person signed up twice
  with different casing (`priya.nair@…` vs `Priya.Nair@…`). Because the collation is case-sensitive, a
  plain `GROUP BY email` or `WHERE email = ...` treats them as two different people — only `LOWER(email)`
  (or another explicit normalization) catches the duplicate. `COUNT(DISTINCT email)` and
  `COUNT(DISTINCT LOWER(email))` disagree.
- **`customers.segment` is NULL** for 4 customers — not every customer has been classified. `GROUP BY segment` silently drops them into a NULL bucket unless handled.
- **`products.cost_price` is NULL** for one product — margin queries using `unit_price - cost_price` will produce a NULL margin for that row, not zero.
- **Split payments:** order 28's line-item total (143.00) does not equal its single captured payment (138.00) by design — one exercise/interview question is built on this exact mismatch. Some orders have two captured payments that together cover the total; treat "amount paid" as `SUM(amount) WHERE payment_status='captured'`, not `MAX` or the first row.
- **Failed-then-retried payments:** several orders have a `failed` payment followed by a `captured` one for the same order — summing all payment rows regardless of status overstates cash collected.
- **Split shipments:** at least one order has two shipment rows. Joining `orders → order_items → shipments` naively multiplies the item rows — a classic join-fan-out trap for revenue totals.
- **Cancelled orders have inconsistent payment rows** — some have no payment row at all, some have a `failed` one. Never assume `NOT EXISTS (payments)` means "not cancelled."
- **`shipping_city` is NULL** on one order — don't assume it always mirrors the customer's city.
- **Refunds with `order_item_id IS NULL`** are order-level (e.g., a delivery-delay goodwill credit) and must not be attributed to any single product's returns.
- **Reviews from non-buyers and duplicate reviews** exist (2 non-buyer reviews; one customer reviewed the same product twice) — "average rating per product" and "did this reviewer buy the product" are two different, both-valid questions.
- **5 customers have never ordered** — an INNER JOIN from `customers` to `orders` silently excludes them; use when teaching LEFT JOIN vs INNER JOIN.
- **One product has never been sold** and one is `is_active = 0` — "top products" queries should decide whether to include zero-sale or inactive products.
- **Prices changed over time**: `order_items.unit_price` is the price charged *at order time* and can differ from `products.unit_price` (current price) — never join to `products.unit_price` to compute historical revenue.

## Recommended exercises

Aggregation/HAVING (email & segment traps) · Joins (fan-out via shipments, LEFT JOIN for never-ordered customers) · Window functions (running totals per customer, rank products per month) · NULL handling (segment/cost_price/shipping_city) · Date analytics (as-of 2025-07-01, monthly cohorts) · Business analytics (revenue by status, payment reconciliation, refund attribution).
