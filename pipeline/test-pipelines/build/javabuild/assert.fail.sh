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

    log_info "Asserting JAR was NOT produced in ${fixture_dir}/target/"

    # Assertions.
    if ls "${fixture_dir}"/target/*.jar 1>/dev/null 2>&1; then
        log_fail "JAR file was produced but should have failed"
        ls -la "${fixture_dir}"/target/*.jar
        exit_code="1"
    else
        log_ok "No JAR file produced (build failed as expected)"
    fi

    exit $exit_code
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
