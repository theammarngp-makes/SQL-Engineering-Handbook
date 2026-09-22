#!/usr/bin/env bash
# ==============================================================================
# run_benchmark.sh — Module 16 Performance Regression Gate
# ==============================================================================
#
# PURPOSE
#   Seeds the shared schema (00_Schema.sql) plus supporting indexes from
#   11_AUTOMATED_PERFORMANCE_TESTING_AND_CICD_INTEGRATION.sql, runs the
#   fraud-review workbench query under test, captures its EXPLAIN plan shape
#   and p50 latency, and fails (non-zero exit) if either regresses against
#   the committed baseline in baseline.json.
#
# REQUIREMENTS
#   mysql client, jq, bc, python3 (for portable millisecond timing)
#
# USAGE
#   ./run_benchmark.sh                  # PR validation (requires baseline.json)
#   ./run_benchmark.sh --update-baseline  # Create/update baseline (maintainer only)
#
# BASELINE STRATEGY
#   A committed baseline.json is REQUIRED for regression detection.
#   - In PR validation mode, the script compares current results against
#     the committed baseline and fails if the baseline file is missing.
#   - To create or update the baseline, a maintainer must explicitly run
#     this script with --update-baseline.
#   - The updated baseline.json should then be committed to the repository.
#
# MEASUREMENT LIMITATIONS
#   - Wall-clock timing includes mysql client startup, network overhead,
#     and process teardown — not pure server-side query latency.
#   - Results vary by hardware, OS load, cold/warm cache, and MySQL version.
#   - The default 50 iterations provide a rough p50; increase ITERATIONS
#     for more statistical confidence.
#   - This gate is designed to catch large regressions (>20% default),
#     not to measure microsecond-level differences.
# ==============================================================================
set -euo pipefail

UPDATE_BASELINE=false
if [[ "${1:-}" == "--update-baseline" ]]; then
    UPDATE_BASELINE=true
fi

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_USER="${DB_USER:-root}"
DB_NAME="${DB_NAME:-perf_gate_ci}"
SCHEMA_FILE="$(dirname "$0")/../00_Schema.sql"
LAB_SQL_FILE="$(dirname "$0")/../11_AUTOMATED_PERFORMANCE_TESTING_AND_CICD_INTEGRATION.sql"
BASELINE_FILE="$(dirname "$0")/baseline.json"
ITERATIONS="${ITERATIONS:-50}"
P50_REGRESSION_TOLERANCE_PCT="${P50_REGRESSION_TOLERANCE_PCT:-20}"

# --------------------------------------------------------------------------
# Step 0: Check baseline (unless updating)
# --------------------------------------------------------------------------
if [ "$UPDATE_BASELINE" = false ] && [ ! -f "${BASELINE_FILE}" ]; then
    echo "=========================================="
    echo "ERROR: Baseline file not found at ${BASELINE_FILE}"
    echo ""
    echo "A committed baseline is required for regression detection."
    echo "The baseline must be deliberately created by a maintainer."
    echo ""
    echo "To create a new baseline, run:"
    echo "  $0 --update-baseline"
    echo ""
    echo "Then commit the generated baseline.json to the repository."
    echo "=========================================="
    exit 1
fi

# --------------------------------------------------------------------------
# Step 1: Seed benchmark database
# --------------------------------------------------------------------------
echo "== Seeding benchmark database: ${DB_NAME} =="
mysql -h "${DB_HOST}" -u "${DB_USER}" -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME};"
mysql -h "${DB_HOST}" -u "${DB_USER}" "${DB_NAME}" < "${SCHEMA_FILE}" > /dev/null

# Load indexes from lesson 11 (stop before regression simulation section)
sed '/-- REGRESSION SIMULATION/,$d' "${LAB_SQL_FILE}" \
    | mysql -h "${DB_HOST}" -u "${DB_USER}" "${DB_NAME}" > /dev/null

QUERY="SELECT transaction_id, transaction_date, transaction_status FROM transactions WHERE processed_by_emp_id = 42 ORDER BY transaction_date DESC LIMIT 10;"

# --------------------------------------------------------------------------
# Step 2: Validate EXPLAIN plan shape
# --------------------------------------------------------------------------
echo "== Capturing EXPLAIN plan shape =="
PLAN_OUTPUT=$(mysql -h "${DB_HOST}" -u "${DB_USER}" "${DB_NAME}" -e "EXPLAIN ${QUERY}")
echo "${PLAN_OUTPUT}"

if echo "${PLAN_OUTPUT}" | grep -q "Using filesort"; then
    echo "FAIL: plan shape regressed -- 'Using filesort' detected."
    exit 1
fi
if ! echo "${PLAN_OUTPUT}" | grep -q "idx_transactions_emp_date"; then
    echo "FAIL: plan shape regressed -- expected index idx_transactions_emp_date not used."
    exit 1
fi

# --------------------------------------------------------------------------
# Step 3: Verify query correctness (row count sanity check)
# --------------------------------------------------------------------------
echo "== Verifying query correctness =="
ROW_COUNT=$(mysql -h "${DB_HOST}" -u "${DB_USER}" -N "${DB_NAME}" -e "SELECT COUNT(*) FROM (${QUERY%?}) AS q;")
echo "== Query returned ${ROW_COUNT} rows (expected <= 10) =="
if [ "${ROW_COUNT}" -gt 10 ]; then
    echo "FAIL: query returned more than LIMIT 10 rows."
    exit 1
fi

# --------------------------------------------------------------------------
# Step 4: Run timed iterations
#   Uses python3 for portable millisecond timing (works on macOS + Linux).
#   date +%s%N is GNU-only and fails on macOS BSD date.
# --------------------------------------------------------------------------
echo "== Plan shape OK. Running ${ITERATIONS} timed iterations =="
LATENCIES_MS=()
for i in $(seq 1 "${ITERATIONS}"); do
    START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')
    mysql -h "${DB_HOST}" -u "${DB_USER}" "${DB_NAME}" -e "${QUERY}" > /dev/null
    END_MS=$(python3 -c 'import time; print(int(time.time()*1000))')
    LATENCIES_MS+=( $(( END_MS - START_MS )) )
done

# --------------------------------------------------------------------------
# Step 5: Calculate p50 (median)
# --------------------------------------------------------------------------
SORTED=($(printf '%s\n' "${LATENCIES_MS[@]}" | sort -n))
P50_INDEX=$(( ITERATIONS / 2 ))
[ "${P50_INDEX}" -ge "${ITERATIONS}" ] && P50_INDEX=$(( ITERATIONS - 1 ))
P50_MS="${SORTED[$P50_INDEX]}"

echo "== p50 (median) latency: ${P50_MS}ms over ${ITERATIONS} iterations =="
echo "== Min: ${SORTED[0]}ms | Max: ${SORTED[$((ITERATIONS - 1))]}ms =="

# --------------------------------------------------------------------------
# Step 6: Compare against baseline OR update baseline
# --------------------------------------------------------------------------
if [ "$UPDATE_BASELINE" = true ]; then
    cat > "${BASELINE_FILE}" <<EOF
{
  "_metadata": {
    "description": "Committed performance baseline for Module 16 regression detection",
    "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "mysql_version": "$(mysql -h "${DB_HOST}" -u "${DB_USER}" -N -e "SELECT VERSION();")",
    "dataset": "00_Schema.sql sample data (~5000 employees, ~300000 transactions)",
    "iterations": ${ITERATIONS},
    "measurement": "Wall-clock p50 including mysql client overhead",
    "notes": "Update deliberately via: run_benchmark.sh --update-baseline"
  },
  "p50_ms": ${P50_MS},
  "regression_tolerance_pct": ${P50_REGRESSION_TOLERANCE_PCT}
}
EOF
    echo "== Baseline updated: ${BASELINE_FILE} =="
    echo "== Commit this file to the repository to finalize the new baseline. =="
    exit 0
fi

# PR validation: compare against committed baseline
BASELINE_P50=$(jq -r '.p50_ms' "${BASELINE_FILE}")
TOLERANCE=$(jq -r '.regression_tolerance_pct // 20' "${BASELINE_FILE}")
MAX_ALLOWED=$(echo "scale=4; ${BASELINE_P50} * (1 + ${TOLERANCE} / 100)" | bc)

echo "== Baseline p50: ${BASELINE_P50}ms | Tolerance: ${TOLERANCE}% | Max allowed: ${MAX_ALLOWED}ms =="

if (( $(echo "${P50_MS} > ${MAX_ALLOWED}" | bc -l) )); then
    echo "FAIL: p50 latency (${P50_MS}ms) regressed beyond ${TOLERANCE}% tolerance (max: ${MAX_ALLOWED}ms)."
    echo ""
    echo "If this regression is intentional (e.g., schema change), update the baseline:"
    echo "  ./run_benchmark.sh --update-baseline"
    exit 1
fi

echo "== PASS: plan shape and latency within budget =="
