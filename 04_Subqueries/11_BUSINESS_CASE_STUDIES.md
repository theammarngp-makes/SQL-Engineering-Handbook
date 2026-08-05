# Enterprise Business Case Studies: Subquery Engineering in Production

This document presents 6 real-world enterprise business case studies across Finance, Healthcare, Retail/E-Commerce, FinTech, HR Analytics, and Logistics. Each case study details the domain business problem, relational schema design, technical challenges, production-grade SQL solutions using subqueries and refactored joins, and scaling considerations.

---

## Learning Objectives

- Solve end-to-end industry problems using advanced subquery architectures.
- Architect high-throughput query pipelines across diverse business domains.
- Evaluate trade-offs between correlated subqueries, window functions, and CTEs in real systems.
- Design defensive subquery filters for high-concurrency transactional databases.

---

## Case Study 1: FinTech — High-Risk Fraud Pattern Detection

### Business Context
A global payment network processes over 100,000,000 daily wire transactions. Fraud safety systems require isolating accounts that executed a transaction exceeding $3\times$ the historical median transaction size of *that specific account* within the last 24 hours.

### Production SQL Solution

```sql
SELECT 
    t.transaction_id,
    t.account_id,
    t.amount,
    t.created_at,
    account_stats.median_amount
FROM transactions t
JOIN (
    SELECT 
        sub.account_id,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY sub.amount) AS median_amount
    FROM transactions sub
    WHERE sub.created_at >= CURRENT_TIMESTAMP - INTERVAL '90 days'
    GROUP BY sub.account_id
) account_stats ON t.account_id = account_stats.account_id
WHERE t.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
  AND t.amount > (3 * account_stats.median_amount);
```

### Scaling Considerations
- **Indexing**: Partial B-Tree index on `transactions(account_id, created_at) INCLUDE (amount)`.
- **Pre-Aggregation**: In high-throughput environments, `account_stats` is updated asynchronously via materialized views refreshed every hour.

---

## Case Study 2: E-Commerce — Customer Churn & Re-Engagement Segmentation

### Business Context
An online marketplace needs to identify high-value VIP customers (lifetime spend $> \$5,000$) who have **not placed an order in the last 180 days** (Anti-Join churn pattern).

### Production SQL Solution

```sql
SELECT 
    c.customer_id,
    c.email,
    c.total_lifetime_spend
FROM customers c
WHERE c.total_lifetime_spend > 5000
  AND NOT EXISTS (
      SELECT 1 
      FROM orders o
      WHERE o.customer_id = c.customer_id
        AND o.order_date >= CURRENT_DATE - INTERVAL '180 days'
  )
ORDER BY c.total_lifetime_spend DESC;
```

---

## Case Study 3: Healthcare — Patient Vital Sign Anomaly Escalation

### Business Context
An intensive care unit (ICU) telemetry system monitors continuous heart rate readings. The engine must flag patient records where the latest reading exceeds the maximum baseline reading recorded during admission.

### Production SQL Solution

```sql
SELECT 
    v.patient_id,
    v.reading_timestamp,
    v.heart_rate,
    v.room_number
FROM patient_vitals v
WHERE v.reading_timestamp >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'
  AND v.heart_rate > (
      SELECT MAX(baseline.heart_rate)
      FROM patient_vitals baseline
      WHERE baseline.patient_id = v.patient_id
        AND baseline.is_admission_baseline = TRUE
  );
```

---

## Case Study 4: Logistics & Supply Chain — Backordered Hub Inventory Allocation

### Business Context
A logistics carrier identifies regional distribution centers that have zero available stock for items currently flagged in critical backorder status.

### Production SQL Solution

```sql
SELECT 
    wh.warehouse_id,
    wh.warehouse_name,
    wh.region
FROM warehouses wh
WHERE NOT EXISTS (
    SELECT 1 
    FROM warehouse_inventory inv
    JOIN backordered_items item ON inv.item_id = item.item_id
    WHERE inv.warehouse_id = wh.warehouse_id
      AND inv.available_quantity > 0
);
```

---

## Case Study 5: Enterprise HR — Department Compensation Inequality Audit

### Business Context
Corporate HR audits executive compensation by selecting employees who earn more than 200% of the average salary of their own department.

### Production SQL Solution

```sql
SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d_avg.dept_avg_salary
FROM employes e
JOIN (
    SELECT dept_id, AVG(salary) AS dept_avg_salary
    FROM employes
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) d_avg ON e.dept_id = d_avg.dept_id
WHERE e.salary > (2.0 * d_avg.dept_avg_salary);
```

---

## Case Study 6: SaaS Platform — Multi-Tenant Quota Violation Monitoring

### Business Context
A multi-tenant cloud platform alerts account admins whose current monthly storage usage exceeds the maximum allocated storage quota for their subscription tier.

### Production SQL Solution

```sql
SELECT 
    tenant.tenant_id,
    tenant.company_name,
    tenant.current_storage_bytes,
    tier.max_storage_bytes
FROM tenant_accounts tenant
JOIN subscription_tiers tier ON tenant.tier_id = tier.tier_id
WHERE tenant.current_storage_bytes > (
    SELECT tier_limits.max_storage_bytes
    FROM subscription_tiers tier_limits
    WHERE tier_limits.tier_id = tenant.tier_id
);
```

---

## Summary

Across all 6 enterprise business cases, refactoring row-by-row subquery expressions into set-based `EXISTS` anti-joins or pre-aggregated derived table joins ensures low-latency execution and high scalability.

---

## Related Modules

- [Module 08 — Subquery Rewrites](./08_SUBQUERY_REWRITES.md)
- [Module 12 — Production Incidents](./12_PRODUCTION_INCIDENTS.md)
