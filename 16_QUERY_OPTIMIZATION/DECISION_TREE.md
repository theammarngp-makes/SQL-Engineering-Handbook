# Decision Trees — Query Optimization

> **Module 16 · Query Optimization · Reference Library**
> [Home](./README.md) · [Troubleshooting](./TROUBLESHOOTING_GUIDE.md) · [Playbook](./OPTIMIZATION_PLAYBOOK.md) · [Rewrite Cookbook](./REWRITE_COOKBOOK.md)

Visual decision guides for common tuning and rewrite choices. Use alongside [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md) during active incidents.

---

## Tree 1: Slow Query — Where to Start?

```mermaid
flowchart TD
    A[Slow Query] --> B{Same SQL as before?}
    B -->|Yes, no code change| C[Stale stats or data growth]
    B -->|No, new query| D[Run EXPLAIN ANALYZE]

    C --> C1[Compare plan to last known-good]
    C1 --> C2[Run ANALYZE]
    C2 --> C3[Re-measure]

    D --> E{Most expensive node?}
    E -->|Full scan: Seq Scan/type ALL| F[SARGability check → Tree 2]
    E -->|Nested Loop, no index| G[Add join-column index]
    E -->|Hash spill| H[Increase work_mem or filter earlier]
    E -->|Sort| I[Index matching ORDER BY]
    E -->|SubPlan loops > 1| J[Rewrite subquery → Tree 3]
    E -->|Plan looks fine| K[Check locks, I/O, cache]
```

---

## Tree 2: Should I Add an Index or Rewrite the Query?

```mermaid
flowchart TD
    A[Full scan on filtered column: Seq Scan/type ALL] --> B{Function on column in WHERE?}
    B -->|Yes| C[Rewrite to SARGable first]
    C --> D{Still a full scan?}
    D -->|Yes| E[Add index on bare column]
    B -->|No| F{Index exists?}
    F -->|No| E
    F -->|Yes| G{Composite index?}
    G -->|Yes| H{Using leftmost column?}
    H -->|No| I[Add index with correct leading column]
    H -->|Yes| J[Check selectivity — filter may be too broad]
    G -->|No| J
    J --> K[Full scan may be correct for low-selectivity filter]
```

---

## Tree 3: Subquery Rewrite Decision

```mermaid
flowchart TD
    A[Expensive Subquery] --> B{NOT IN?}
    B -->|Yes| C{Rewrite to NOT EXISTS}
    B -->|No| D{Existence check?}
    D -->|Yes| E{Rewrite to EXISTS}
    D -->|No| F{Correlated?}
    F -->|Yes| G{Computing rank/aggregate per group?}
    G -->|Yes| H[Rewrite to Window Function]
    G -->|No| I{Rewrite to JOIN}
    F -->|No| J[Check if CTE is materialized vs inlined]
```

---

## Tree 4: Join Algorithm Prediction

```mermaid
flowchart TD
    A[Join between two tables] --> B{Outer table small?}
    B -->|Yes| C{Inner has index on join col?}
    C -->|Yes| D[Nested Loop]
    C -->|No| E[Hash Join]
    B -->|No| F{Both sides large?}
    F -->|Yes| G{Both sorted on join key?}
    G -->|Yes| H[Merge Join]
    G -->|No| I[Hash Join]
    F -->|No| E
```

---

## Tree 5: Pagination Strategy

```mermaid
flowchart TD
    A[Need pagination] --> B{Jump to arbitrary page number?}
    B -->|Yes| C{Acceptable performance cost?}
    C -->|No| D[Use keyset + store cursors client-side]
    C -->|Yes, small dataset| E[OFFSET acceptable for < 10K rows]
    B -->|No| F[Keyset pagination]
    F --> G[Use indexed, unique sort column as cursor]
```

---

## Tree 6: Index Design

```mermaid
flowchart TD
    A[Design index for query] --> B{Single equality filter?}
    B -->|Yes| C[Index on that column]
    B -->|No| D{Multiple equality filters?}
    D -->|Yes| E[Composite: most selective equality first]
    D -->|No| F{Range filter + ORDER BY?}
    F -->|Yes| G[Composite: equality cols, then range/ORDER BY col]
    F -->|No| H{Query selects few columns?}
    H -->|Yes| I[Covering index with all needed columns]
    H -->|No| C
```

---

## Related Documents

- [REWRITE_COOKBOOK.md](./REWRITE_COOKBOOK.md)
- [OPTIMIZATION_PLAYBOOK.md](./OPTIMIZATION_PLAYBOOK.md)
- [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md)
- [CHEATSHEET.md](./CHEATSHEET.md)

[← Back to Module Home](./README.md)
