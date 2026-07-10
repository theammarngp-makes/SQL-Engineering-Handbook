-- ============================================================
-- Module      : 10_STRING_FUNCTIONS
-- Topic       : 04_STRING_CLEANING_AND_VALIDATION
-- Objective   : Compose prior topics' functions into repeatable
--               cleaning and validation routines for contact and
--               identity data.
-- Dialect     : ANSI SQL, verified against PostgreSQL and MySQL 8+
-- Dataset     : patients
-- ============================================================

-- ------------------------------------------------------------
-- Reference schema (for context only)
-- ------------------------------------------------------------
-- patients (patient_id INT PK, patient_name VARCHAR(100),
--           patient_email VARCHAR(150), patient_phone VARCHAR(30))


-- ============================================================
-- SCENARIO 1 — Structural email validation with named failure reasons
-- ============================================================
-- Business Context:
--   Before enabling automated appointment-reminder emails, the
--   patient outreach system requires every email to pass a basic
--   structural check. Records failing validation must be routed
--   to a manual-review queue with a reason, not just excluded
--   silently.

-- Question: Classify each patient email into a specific
--           validation status.
SELECT
    patient_id,
    patient_email,
    CASE
        WHEN patient_email IS NULL THEN 'Missing'
        WHEN TRIM(patient_email) = '' THEN 'Empty'
        WHEN LOCATE('@', TRIM(patient_email)) = 0 THEN 'Missing @'
        WHEN LOCATE('.', SUBSTRING_INDEX(TRIM(patient_email), '@', -1)) = 0
            THEN 'Missing domain dot'
        WHEN LOCATE(' ', TRIM(patient_email)) > 0 THEN 'Contains whitespace'
        ELSE 'Passes basic structure check'
    END AS email_validation_status
FROM patients;

-- Engineering Notes:
--   WHEN clauses are ordered from cheapest/most-severe to most
--   specific: NULL and empty-string checks first (since they make
--   every later check meaningless), then structural checks. This
--   ordering both short-circuits unnecessary work and produces a
--   diagnostically useful, single root-cause status per record.
--
-- Performance Notes:
--   Five conditions evaluated per row in the worst case (a record
--   that passes every check); still O(row count) and acceptable
--   for a nightly outreach-eligibility batch job. If run on every
--   page load of a patient record, this should instead be a
--   stored validation_status column updated on write.
--
-- Expected Output (sample):
--   patient_id | patient_email          | email_validation_status
--   5001         | " j.taylor@clinic.com" | Passes basic structure check
--   5002         | j.taylor.clinic.com     | Missing @
--   5003         | NULL                     | Missing


-- ============================================================
-- SCENARIO 2 — Phone number validation after separator normalization
-- ============================================================
-- Business Context:
--   Patient phone numbers arrive with inconsistent formatting
--   from multiple intake channels (web form, phone intake,
--   paper-to-digital transcription). Before a number is
--   considered usable for SMS reminders, it must normalize to
--   exactly 10 digits after removing known separator characters.

-- Question: Normalize separators and classify each phone number
--           as Missing, Too Short, Too Long, or Valid.
SELECT
    patient_id,
    patient_phone,
    REPLACE(REPLACE(REPLACE(TRIM(patient_phone), '-', ''), '.', ''), ' ', '') AS digits_only,
    CASE
        WHEN patient_phone IS NULL OR TRIM(patient_phone) = '' THEN 'Missing'
        WHEN CHAR_LENGTH(REPLACE(REPLACE(REPLACE(TRIM(patient_phone), '-', ''), '.', ''), ' ', '')) < 10
            THEN 'Too Short'
        WHEN CHAR_LENGTH(REPLACE(REPLACE(REPLACE(TRIM(patient_phone), '-', ''), '.', ''), ' ', '')) > 10
            THEN 'Too Long'
        ELSE 'Valid'
    END AS phone_validation_status
FROM patients;

-- Engineering Notes:
--   Nested REPLACE() calls strip the three known separator
--   characters (dash, period, space) before length-checking —
--   this is intentionally scoped to exactly the separators seen
--   in this dataset's intake channels; a system accepting
--   international numbers with parentheses or '+' country-code
--   prefixes would need additional REPLACE() calls or a REGEXP-
--   based approach instead.
--   The digits_only expression is repeated across three CASE
--   branches for clarity in this teaching example; in production
--   this is exactly the kind of repeated computation to lift into
--   a CTE or a stored generated column, both to avoid recomputing
--   it three times per row and to keep the validation rule
--   defined in exactly one place.
--
-- Performance Notes:
--   As implemented, this query computes the same nested REPLACE()
--   expression up to three times per row. Refactoring with a CTE
--   (`WITH cleaned AS (SELECT patient_id, REPLACE(...) AS
--   digits_only FROM patients)`) avoids the redundant computation
--   and is the recommended production form.
--
-- Expected Output (sample):
--   patient_id | patient_phone   | digits_only  | phone_validation_status
--   5001         | 555-123-4567     | 5551234567    | Valid
--   5002         | 555.123             | 5551234567    | Too Short (example shortened)


-- ============================================================
-- SCENARIO 3 — Cleaning patient names for consistent matching
-- ============================================================
-- Business Context:
--   Patient records are matched across the intake system and the
--   insurance verification system using name as a secondary key
--   (alongside date of birth). Inconsistent whitespace and casing
--   between the two systems has caused false-negative match
--   failures, delaying insurance verification.

-- Question: Produce a normalized comparison key from patient_name
--           — trimmed, single-spaced, and uppercased.
SELECT
    patient_name,
    UPPER(TRIM(REPLACE(REPLACE(patient_name, '  ', ' '), '  ', ' '))) AS name_match_key
FROM patients;

-- Engineering Notes:
--   REPLACE('  ', ' ') is applied twice in sequence to collapse
--   runs of more than two consecutive spaces down to one; a
--   single application only halves a run of spaces (e.g., 4
--   spaces become 2, not 1). This is a known limitation of using
--   REPLACE() for whitespace collapsing — engines with native
--   REGEXP_REPLACE() can do this in one pass with a pattern like
--   `REGEXP_REPLACE(patient_name, '\s+', ' ')`. This nested-
--   REPLACE approach is documented here specifically because it
--   is the most portable option across engines lacking REGEXP_REPLACE.
--
-- Performance Notes:
--   Cheap per row. Because this is used as a *matching key* across
--   two systems, it should be computed identically (ideally via a
--   shared, versioned transformation) in both systems rather than
--   independently re-implemented, to avoid the two normalizations
--   silently drifting apart over time.
--
-- Expected Output (sample):
--   patient_name        | name_match_key
--   "  Sarah   Connor "   | "SARAH CONNOR"
--   "john  smith"           | "JOHN SMITH"


-- ============================================================
-- SCENARIO 4 — Building a combined outreach-eligibility worklist
-- ============================================================
-- Business Context:
--   The outreach coordination team needs a single worklist of
--   patients who cannot currently be reached by either channel —
--   email or phone — so staff can follow up manually rather than
--   relying on automated reminders.

-- Question: Identify patients where both email and phone fail
--           basic validation.
SELECT
    patient_id,
    patient_name,
    patient_email,
    patient_phone
FROM patients
WHERE
    (patient_email IS NULL
        OR TRIM(patient_email) = ''
        OR LOCATE('@', TRIM(patient_email)) = 0)
    AND
    (patient_phone IS NULL
        OR TRIM(patient_phone) = ''
        OR CHAR_LENGTH(REPLACE(REPLACE(REPLACE(TRIM(patient_phone), '-', ''), '.', ''), ' ', '')) <> 10);

-- Engineering Notes:
--   This query intentionally re-expresses the failure conditions
--   from Scenarios 1 and 2 as boolean predicates rather than
--   reusing the CASE-based status columns, since it needs to
--   filter rather than report. In a production system, both this
--   query and Scenarios 1–2 should read from a single shared
--   validation view or materialized column set, so the definition
--   of "invalid" cannot drift between the reporting and filtering
--   use cases.
--
-- Performance Notes:
--   This is the most expensive query in this topic — up to eight
--   function calls per row across both AND branches. For a large
--   patient table run as a recurring batch job, materializing
--   email_validation_status and phone_validation_status as
--   columns (per Scenarios 1–2) and filtering on those directly
--   is strongly preferred over inlining the raw expressions here.
--
-- Expected Output (sample):
--   patient_id | patient_name | patient_email | patient_phone
--   5009         | Amelia Ross    | NULL            | 555.12
-- ============================================================
