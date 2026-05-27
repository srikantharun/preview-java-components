#!/usr/bin/env bash

# Strict mode - exit on error (errexit), undefined variables (nounset), and pipe failures (pipefail)
set -euo pipefail

# Dependencies
functions_dir="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/../../../../src/shared/lib" || exit 1
    pwd
)"

# shellcheck source=src/shared/lib/all.sh
. "$functions_dir/all.sh"

# Main program
main() {
    # Setup exit handler.
    init_exit_handler

    # Local variables.
    local exit_code=0
    local fixture_dir="${1:-.}"

    log_info "Asserting unit tests FAILED in ${fixture_dir}/target/"

    # Assertions: Surefire reports should exist (tests ran)
    if ls "${fixture_dir}"/target/surefire-reports/*.xml 1>/dev/null 2>&1; then
        log_ok "Surefire reports found (tests ran)"

        # Check if there are failures in the reports
        if grep -q 'failures="[1-9]' "${fixture_dir}"/target/surefire-reports/*.xml 2>/dev/null || \
           grep -q 'errors="[1-9]' "${fixture_dir}"/target/surefire-reports/*.xml 2>/dev/null; then
            log_ok "Test failures detected (as expected)"
        else
            log_fail "No test failures detected - tests should have failed"
            exit_code="1"
        fi
    else
        log_ok "No surefire reports (tests failed before completion)"
    fi

    exit $exit_code
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
