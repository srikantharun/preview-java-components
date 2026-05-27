#!/usr/bin/env bash
# =============================================================================
# Assertion: Verify checkstyle passed (no violations)
# =============================================================================

set -euo pipefail

FIXTURE_DIR="${1:-.}"
REPORT_FILE="${FIXTURE_DIR}/target/checkstyle-result.xml"

echo "Asserting checkstyle passed for ${FIXTURE_DIR}"

if [[ ! -f "${REPORT_FILE}" ]]; then
    echo "FAIL: Checkstyle report not found at ${REPORT_FILE}"
    exit 1
fi

if grep -q "<error" "${REPORT_FILE}"; then
    echo "FAIL: Checkstyle found violations"
    grep "<error" "${REPORT_FILE}"
    exit 1
else
    echo "PASS: No checkstyle violations found"
    exit 0
fi
