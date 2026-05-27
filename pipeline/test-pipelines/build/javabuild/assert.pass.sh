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

    log_info "Asserting JAR was produced in ${fixture_dir}/target/"

    # Assertions.
    if ls "${fixture_dir}"/target/*.jar 1>/dev/null 2>&1; then
        log_ok "JAR file found"
        ls -la "${fixture_dir}"/target/*.jar
    else
        log_fail "No JAR file found in ${fixture_dir}/target/"
        exit_code="1"
    fi

    exit $exit_code
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
