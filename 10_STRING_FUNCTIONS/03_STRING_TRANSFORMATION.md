# 03 — String Transformation

## Introduction

Search and extraction (Topic 02) answer "where is it" and "give me a piece." Transformation functions answer "change it" — replace one substring with another, reverse a sequence for a checksum algorithm, pad a value to a fixed width for a legacy fixed-length export, or repeat a character to build a formatted separator line. This topic uses a banking/finance schema — account numbers, transaction references, and report formatting — where fixed-width formatting requirements are common and non-negotiable.

## Concept Overview

Transformation functions modify a string's content or shape without needing to first locate anything within it:

1. **Content replacement** — `REPLACE()`
2. **Sequence manipulation** — `REVERSE()`, `REPEAT()`, `SPACE()`
3. **Positional insertion** — `INSERT()`
4. **Fixed-width formatting** — `LPAD()`, `RPAD()`

## Business Motivation

Legacy financial systems, regulatory reporting formats, and fixed-width file interchange (still common in banking, insurance, and government systems) require exact character-width output — an account number padded to 12 digits with leading zeros, an amount field padded to a fixed width for a mainframe-compatible export. Transformation functions are how SQL meets these formatting contracts without post-processing in another language.

## Why These Functions Exist

Many downstream systems — especially older or regulatory ones — were not designed around variable-length text; they expect exact-width fields at fixed byte offsets. Padding and replacement functions exist to bridge modern variable-length relational storage with these fixed-width contracts, and to perform bulk content standardization (masking, format normalization) directly in the query layer.

## Real Company Use Cases

- **Banking** masking all but the last 4 digits of an account number for display in a support ticket system
- **Finance** formatting transaction reference numbers to a fixed width for a regulatory export file
- **Reporting tools** building ASCII-formatted separator lines or padding labels for aligned plain-text reports
- **Data migration** replacing legacy delimiter characters (e.g., `|` to `,`) when moving between systems with different format conventions

## Functions Covered

| Function | Purpose |
|---|---|
| `REPLACE()` | Replaces all occurrences of a substring with another |
| `REVERSE()` | Reverses the character order of a string |
| `REPEAT()` | Repeats a string a specified number of times |
| `SPACE()` | Returns a string of N spaces |
| `INSERT()` | Inserts a substring at a given position, replacing a given length |
| `LPAD()` | Pads a string on the left to a target length |
| `RPAD()` | Pads a string on the right to a target length |

## Syntax

```sql
REPLACE(str, from_str, to_str)
REVERSE(str)
REPEAT(str, count)
SPACE(count)
INSERT(str, start_pos, length, new_str)
LPAD(str, target_length, pad_str)
RPAD(str, target_length, pad_str)
```

## Parameters

- **`from_str` / `to_str`** — the substring to find and its replacement, for `REPLACE()`
- **`count`** — number of repetitions (`REPEAT`) or spaces (`SPACE`); must be non-negative
- **`start_pos` / `length`** — for `INSERT()`, the 1-indexed position to begin replacing and how many characters to remove before inserting `new_str`
- **`target_length`** — the desired total length after padding; if the input is already this length or longer, most engines truncate rather than pad
- **`pad_str`** — the string used to pad (commonly `'0'` or `' '`)

## Return Values

All functions in this family return a string, or `NULL` if any argument is `NULL`. `LPAD`/`RPAD` with a `target_length` shorter than the input's current length return a **truncated** string in most engines — this is a common source of silent data loss and is called out explicitly in Edge Cases.

## ASCII Visual Explanation

```
account_number = "48213"

LPAD(account_number, 10, '0')
    →  "0000048213"
        ^^^^^^ zero-padding added on the LEFT to reach length 10

RPAD(account_number, 10, '*')
    →  "48213*****"
             ^^^^^ padding added on the RIGHT to reach length 10
```

## Step-by-Step Examples

**Goal:** Format account numbers to a fixed 10-digit width for a regulatory export, zero-padded on the left.

```sql
SELECT
    account_number,
    LPAD(account_number, 10, '0') AS export_account_number
FROM accounts;
```

Reasoning: Regulatory file specifications commonly require fixed-width numeric fields; `LPAD()` with `'0'` matches the conventional zero-padding used for numeric identifiers, as opposed to `RPAD()`, which would be used for left-aligned text fields.

## Production Considerations

- Always validate that source data does not already exceed `target_length` before relying on `LPAD`/`RPAD` — silent truncation of an oversized value is far more dangerous in a financial export than a padding error, since it can produce a *valid-looking but wrong* account number.
- `REPLACE()` performs literal substring replacement, not pattern-based — it cannot express "replace any digit" the way `REGEXP_REPLACE()` can (covered where available per-engine). Reach for `REPLACE()` only when the target substring is exact and known.
- Masking sensitive values (e.g., account numbers) for display should combine `LEFT()`/`RIGHT()` (Topic 01) with `REPEAT()` to build the masked portion, never `REPLACE()`, which cannot mask a variable-length prefix cleanly.

## Performance Notes

- `REPLACE()`, `REVERSE()`, `REPEAT()`, `LPAD()`, `RPAD()` are all O(string length) per row — inexpensive at typical column widths, but worth avoiding inside a `WHERE` clause on large tables for the same sargability reasons discussed in Topics 01–02.
- `INSERT()` is rarely performance-relevant since it is almost always used for display formatting rather than filtering.

## Edge Cases

- `LPAD`/`RPAD` **truncate** rather than error when the input already exceeds `target_length` — verify this explicitly for your engine, since the exact truncation behavior (which end is cut) can differ.
- `REPLACE()` replaces **every** occurrence, not just the first — a frequent surprise when only a single replacement was intended.
- `REVERSE()` on multi-byte character strings can produce corrupted output in some older engine versions if not UTF-8 aware — verify behavior on your specific engine version before using it on non-ASCII data.

## Common Mistakes

- Using `LPAD()` to "add" characters without checking whether the source value could already be at or beyond `target_length`, silently truncating legitimate long values.
- Assuming `REPLACE()` only replaces the first match, then being surprised when a string with the target substring appearing twice gets both replaced.
- Building masked output using `REPLACE()` on a fixed literal (e.g., replacing digits `0`-`9`) instead of `REPEAT()` combined with `LEFT()`/`RIGHT()`, producing masks that don't scale to variable-length input.

## Best Practices

- Always specify the `pad_str` argument for `LPAD`/`RPAD` explicitly, even when padding with a space, rather than relying on any engine's default — defaults vary and this improves readability regardless.
- When masking sensitive data, always leave the *last* few characters visible (`RIGHT()`) rather than the first, matching standard PCI-DSS-style display conventions for account/card numbers.
- Document the exact fixed-width contract a `LPAD`/`RPAD` transformation is satisfying (e.g., "10-digit, zero-padded, per Regulatory Format Spec v3") directly in a query comment — these contracts are external and not otherwise visible in the SQL.

## Interview Questions

1. What happens when `LPAD()`'s target length is shorter than the input string's actual length?
2. How would you mask a customer's account number to show only the last 4 digits, using string functions?
3. `REPLACE('aabbaa', 'a', 'X')` — what's the result, and why might that surprise someone expecting only the first match to be replaced?
4. When would you use `INSERT()` instead of a combination of `LEFT()`, `RIGHT()`, and `CONCAT()`?

## Practice Challenges

1. Write a query that masks each `account_number`, showing only the last 4 digits and replacing the rest with `*`, regardless of the account number's length.
2. Format `transaction_ref` values to a fixed 15-character width, right-padded with spaces, for a legacy fixed-width export.
3. Using `REPLACE()`, normalize a `raw_phone` column that inconsistently uses both `-` and `.` as separators into a single consistent `-` separator.

## Summary

Transformation functions reshape string content and width to satisfy formatting contracts that relational storage doesn't enforce on its own — fixed-width exports, masked display values, and normalized delimiters. The recurring risk across this family is silent truncation and unintended multi-match replacement; both are cheap to guard against once you know to look for them.

## Further Reading

- [PostgreSQL String Functions and Operators](https://www.postgresql.org/docs/current/functions-string.html)
- [MySQL String Functions Reference](https://dev.mysql.com/doc/refman/8.0/en/string-functions.html)
