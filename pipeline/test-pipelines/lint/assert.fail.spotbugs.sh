#!/usr/bin/env bash
# =============================================================================
# Assertion: Verify spotbugs found bugs (expected failure)
# =============================================================================

set -euo pipefail

FIXTURE_DIR="${1:-.}"
REPORT_FILE="${FIXTURE_DIR}/target/spotbugsXml.xml"

echo "Asserting spotbugs found bugs for ${FIXTURE_DIR}"

if [[ ! -f "${REPORT_FILE}" ]]; then
    echo "FAIL: SpotBugs report not found at ${REPORT_FILE}"
    exit 1
fi

if grep -q "<BugInstance" "${REPORT_FILE}"; then
    echo "PASS: SpotBugs correctly found bugs"
    exit 0
else
    echo "FAIL: SpotBugs should have found bugs but didn't"
    exit 1
fi
