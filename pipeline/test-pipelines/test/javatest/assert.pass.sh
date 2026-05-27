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

    log_info "Asserting unit tests passed in ${fixture_dir}/target/"

    # Assertions: Check surefire reports exist
    if ls "${fixture_dir}"/target/surefire-reports/*.xml 1>/dev/null 2>&1; then
        log_ok "Surefire reports found"
        ls -la "${fixture_dir}"/target/surefire-reports/*.xml
    else
        log_fail "No surefire reports found in ${fixture_dir}/target/surefire-reports/"
        exit_code="1"
    fi

    # Assertions: Check JaCoCo coverage report exists
    if [ -f "${fixture_dir}/target/site/jacoco/jacoco.xml" ]; then
        log_ok "JaCoCo coverage report found"
    else
        log_fail "No JaCoCo coverage report found at ${fixture_dir}/target/site/jacoco/jacoco.xml"
        exit_code="1"
    fi

    exit $exit_code
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
