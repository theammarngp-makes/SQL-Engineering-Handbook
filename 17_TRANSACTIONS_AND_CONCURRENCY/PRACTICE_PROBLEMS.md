[← Module Home](./README.md)

# Module 17 — Practice Problems

`Dialect: MySQL 8.x / 8.4. Schema: 00_Schema (employes, departments, locations).`
`Full solutions with explanation: SOLUTIONS.sql`

---

## Problem 1 — Atomic Transfer (Lesson 01)

Write a transaction that moves an employee from `dept_id = 4` to
`dept_id = 7` AND gives them a flat $3,000 raise, such that if either
statement fails, neither change is kept.

## Problem 2 — Isolation Level Choice (Lesson 02)

A dashboard shows "employees hired this year" and refreshes every
30 seconds by opening a new connection each time. Explain whether
MySQL's default `REPEATABLE READ` creates any problem for this
specific access pattern, and why or why not.

## Problem 3 — Closing a Read-Then-Write Race (Lesson 03)

Two sessions both run "if an employee's salary is below 50000, give
them a $2,000 raise" for the same `emp_id` at nearly the same time.
Write a version of this logic that cannot double-apply the raise,
using a single atomic statement.

## Problem 4 — Diagnosing a Lock Wait (Lesson 03)

Given only `information_schema.INNODB_TRX` output showing one
transaction open for 40 minutes with a pending `UPDATE`, explain what
you'd check next and why.

## Problem 5 — Preventing a Deadlock (Lesson 04)

Two features both need to lock an employee row and that employee's
department row: "give a raise" locks employee-then-department;
"rename department" locks department-then-employee. Identify the
deadlock risk and fix it.

## Problem 6 — MVCC Snapshot Reasoning (Lesson 05)

A transaction under `REPEATABLE READ` reads `salary = 80000` for
`emp_id = 12`, then — without committing or starting a new
transaction — reads it again 10 seconds later after another session
has committed an update to `95000`. What does the second read show,
and why?

## Problem 7 — Anti-Pattern Identification (Lesson 06)

A code review shows: `START TRANSACTION; UPDATE orders SET status =
'processing' WHERE order_id = 501; <call shipping API, ~2s>; UPDATE
orders SET status = 'shipped' WHERE order_id = 501; COMMIT;`.
Name the anti-pattern and the fix.

## Problem 8 — Full Workflow Application (Lesson 07)

Apply the 7-step workflow from Lesson 07 to: "when an order is
cancelled, restock each of its line items' quantities back into
inventory, and this must never partially apply if any line item's
product was deleted in the meantime."

---

*(Solutions, with full reasoning for each, are in `SOLUTIONS.sql`.)*
