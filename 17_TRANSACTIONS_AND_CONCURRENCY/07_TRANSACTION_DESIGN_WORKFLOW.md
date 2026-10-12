[← Module Home](./README.md)

# Lesson 07 — Transaction Design Workflow

`Module 17: Transactions & Concurrency Control · Lesson 7 of 7`

---

## 1. Introduction

Lessons 01–06 gave you the mechanisms and the failure modes. This
closing lesson gives you an actual decision process for designing a
new transaction boundary from scratch, so the earlier material becomes
something you apply deliberately rather than recall after the fact.

## 2. Learning Objectives

- Walk a new feature's data-access requirement through a concrete
  decision sequence to arrive at a transaction boundary, isolation
  level, and locking strategy
- Justify each decision by name (which Lesson 01–06 concept it rests
  on), not by habit or default
- Apply the workflow to a realistic multi-step scenario

## 3. Why This Exists

Without an explicit process, transaction design defaults to whatever
the ORM or framework does automatically — which is sometimes fine and
sometimes exactly how Lesson 06's anti-patterns end up in production.
A short, repeatable decision sequence makes the choice deliberate.

## 4. The Workflow

### Step 1 — Identify the atomic unit
What is the smallest set of statements that must all succeed or all
fail together, as one business fact? Not "everything this request
touches" — the minimum. (Lesson 01, §4, §8)

### Step 2 — Identify every concurrent access pattern against the same rows
Will another session plausibly read or write the same rows while this
operation runs? If genuinely no (truly private data, no other writer
exists), isolation/locking choices matter less. If yes, continue.

### Step 3 — Does this operation read a value it will act on, then write
based on that read?
If yes, this is the Lesson 03 read-then-write shape. Decide: can it be
a single atomic statement instead (preferred), or does it genuinely
need a locking read (`SELECT ... FOR UPDATE`)?

### Step 4 — Choose the isolation level
Default to MySQL's `REPEATABLE READ` unless you can name a specific
reason it's insufficient (true cross-row consistency needs that
`SERIALIZABLE` specifically provides) or a specific reason a weaker
level is acceptable and beneficial (a high-throughput, staleness-
tolerant read path). "Default habit" is not a reason in either
direction — name the actual requirement. (Lesson 02, §6–7)

### Step 5 — Check for multi-resource lock ordering
If this operation (or any operation that could run concurrently
against the same resources) locks more than one row/table, confirm a
consistent acquisition order is enforced across every code path that
touches those same resources. (Lesson 04, §7)

### Step 6 — Plan for the expected failure modes
Does the application layer catch and retry deadlock errors (Lesson
04)? Does it catch lock-wait-timeout errors (Lesson 03, §7)
separately, with different handling (that one is not necessarily
retryable the same way)? Decide this before shipping, not after the
first production incident.

### Step 7 — Audit against the anti-pattern catalog
Run the finished design against Lesson 06, §4's seven patterns
explicitly. Any external call inside the boundary? Any statement that
could run alone under autocommit when it needs a partner? Any
unbounded-scope `UPDATE`?

## 5. Worked Example

**Scenario:** "When an employee is promoted, update their salary and
insert a promotion-history record, and this must never leave the two
out of sync."

- **Step 1:** Atomic unit = the salary `UPDATE` + the history `INSERT`.
  Nothing else needs to be in this boundary.
- **Step 2:** Yes — another session could concurrently give the same
  employee a different raise (a cost-of-living adjustment batch job,
  say).
- **Step 3:** The salary change here is a direct `SET salary = <new
  value>`, not computed from a prior read of the current salary in
  application code — so this is NOT a read-then-write race by itself.
  If the new salary *were* computed as "current salary + 10%," that
  would reintroduce the Lesson 03 race and need a locking read or an
  atomic `salary = salary * 1.10`.
- **Step 4:** `REPEATABLE READ` (MySQL default) is sufficient — no
  named requirement for `SERIALIZABLE` here.
- **Step 5:** Only one row locked (this employee's), so no
  multi-resource ordering concern for this operation in isolation —
  but confirm no OTHER operation in the codebase locks this employee's
  row and another resource in a conflicting order.
- **Step 6:** Deadlock is unlikely here (single-row lock) but still
  catch-and-retry defensively; this is cheap insurance.
- **Step 7:** No external call inside the boundary, boundary is
  explicit (not relying on autocommit across two statements), scope is
  a single row — clean against the catalog.

```sql
START TRANSACTION;
UPDATE employes SET salary = 98000.00 WHERE emp_id = 12;
-- (promotion_history table not in this handbook's 00_Schema;
--  shown here as the shape of the second statement this transaction protects)
-- INSERT INTO promotion_history (emp_id, new_salary, effective_date)
-- VALUES (12, 98000.00, CURRENT_DATE);
COMMIT;
```

## 6. Engineering Notes

- This workflow is a checklist, not a bureaucratic process — for a
  genuinely simple single-statement operation under autocommit, Steps
  1–7 resolve almost instantly ("atomic unit = this one statement,
  autocommit already handles it"). The value shows up on multi-
  statement, multi-resource operations where skipping the checklist
  is exactly how Lesson 06's anti-patterns get introduced.
- Document the isolation level and locking decision in a code comment
  at the transaction boundary itself when the choice is non-default or
  non-obvious — this is what makes Lesson 06, §4.7's cross-engine
  drift risk visible to the next person who touches the code.

## 7. MySQL / PostgreSQL / SQL Server Notes

The workflow itself is engine-agnostic; Step 4's "default" differs by
engine (MySQL: `REPEATABLE READ`; PostgreSQL/SQL Server: `READ
COMMITTED`) — always state which engine's default you're reasoning
against, per Lesson 02, §8.

## 8. Common Mistakes

1. **Skipping straight to "wrap it in a transaction" without Steps
   2–3** — atomicity alone doesn't address a read-then-write race;
   this workflow exists specifically to not let that gap slide through
   unnoticed.
2. **Treating isolation level as a one-time project-wide decision**
   rather than a per-operation one — different operations in the same
   codebase can legitimately want different isolation levels.

## 9. Edge Cases

- **An operation with no concurrent access risk at all** (Step 2
  resolves "no"): the workflow still completes in one pass, concluding
  "default autocommit / default isolation level is fine" — that's a
  legitimate, fast conclusion, not a reason to skip the check.

## 10. Troubleshooting Guidance

If a production incident traces back to a transaction design issue,
re-running this workflow against the actual code (not the intended
design) is usually the fastest way to identify exactly which step was
skipped or answered incorrectly.

## 11. Scalability Considerations

Revisit Step 4 (isolation level) and Step 1 (atomic unit scope,
Lesson 06 §4.3) specifically as load grows — a design that was correct
at low concurrency can need its atomic unit narrowed or its isolation
level reconsidered purely due to contention, even with zero change in
business logic correctness.

## 12. Additional Dialect Notes

Not applicable as a new section — see §7 above; all dialect-specific
detail was established in Lessons 01–06.

## 13. Interview Questions

1. **"Walk me through how you'd decide the transaction boundary for
   [a new feature]."** — Tests whether the candidate has an actual
   process (ideally resembling Steps 1–7) versus reaching for "just
   wrap it in a transaction" without further analysis.
2. **"When would you deliberately choose a non-default isolation
   level, and how would you document that choice for the next
   engineer?"** — Tests Step 4 and the Engineering Notes' documentation
   point together.

## 14. Summary

A repeatable seven-step workflow — atomic unit, concurrent access
check, read-then-write check, isolation level choice, lock ordering
check, failure-mode planning, anti-pattern audit — turns Lessons 01–06
from reference material into an applied design process. The worked
promotion example shows each step resolving concretely against a
realistic scenario.

## 15. Practice Challenges

1. Apply the full 7-step workflow to: "transferring an employee from
   one department to another, including updating that department's
   headcount-derived fields if any exist, with a concurrent HR batch
   job that might also modify the same employee's department
   assignment."
2. Apply the workflow to: "a nightly job that gives every employee in
   the company a cost-of-living raise, calculated as current salary
   times a percentage." Pay specific attention to which catalog entry
   from Lesson 06 this scenario is most at risk of, by scope alone.
3. Write the explicit code comment you'd place at a non-default
   isolation-level transaction boundary, stating the specific named
   reason for the choice (per Engineering Notes above).

*(Some challenges are scaffolded in this lesson's `.sql` file. The cross-lesson problem set, with full solutions, is in `PRACTICE_PROBLEMS.md` and `SOLUTIONS.sql`.)*

## 16. Further Reading

- MySQL 8.4 Reference Manual — [InnoDB and the ACID Model](https://dev.mysql.com/doc/refman/8.4/en/mysql-acid.html)
- This module's own Lessons 01–06 — this lesson deliberately introduces
  no new engine mechanism; it's a synthesis.

---

**Previous:** [Lesson 06 — Transaction Anti-Patterns](./06_TRANSACTION_ANTI_PATTERNS.md) · **Back to:** [Module Home](./README.md)
