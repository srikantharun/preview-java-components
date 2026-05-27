#!/usr/bin/env bash
# =============================================================================
# Assertion: Verify spotbugs passed (no bugs)
# =============================================================================

set -euo pipefail

FIXTURE_DIR="${1:-.}"
REPORT_FILE="${FIXTURE_DIR}/target/spotbugsXml.xml"

echo "Asserting spotbugs passed for ${FIXTURE_DIR}"

if [[ ! -f "${REPORT_FILE}" ]]; then
    echo "FAIL: SpotBugs report not found at ${REPORT_FILE}"
    exit 1
fi

if grep -q "<BugInstance" "${REPORT_FILE}"; then
    echo "FAIL: SpotBugs found bugs"
    grep "<BugInstance" "${REPORT_FILE}"
    exit 1
else
    echo "PASS: No SpotBugs violations found"
    exit 0
fi
