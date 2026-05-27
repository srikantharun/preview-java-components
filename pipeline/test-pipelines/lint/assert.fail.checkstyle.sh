#!/usr/bin/env bash
# =============================================================================
# Assertion: Verify checkstyle found violations (expected failure)
# =============================================================================

set -euo pipefail

FIXTURE_DIR="${1:-.}"
REPORT_FILE="${FIXTURE_DIR}/target/checkstyle-result.xml"

echo "Asserting checkstyle found violations for ${FIXTURE_DIR}"

if [[ ! -f "${REPORT_FILE}" ]]; then
    echo "FAIL: Checkstyle report not found at ${REPORT_FILE}"
    exit 1
fi

if grep -q "<error" "${REPORT_FILE}"; then
    echo "PASS: Checkstyle correctly found violations"
    exit 0
else
    echo "FAIL: Checkstyle should have found violations but didn't"
    exit 1
fi
