#!/usr/bin/env bash

# Strict mode
set -euo pipefail

# Dependencies
# :nocov:
functions_dir="$(
      cd "$(dirname "${BASH_SOURCE[0]}")/../../shared/lib" || exit 1
      pwd
)"

shared_dir="$(
      cd "$(dirname "${BASH_SOURCE[0]}")/../../shared" || exit 1
      pwd
)"
# :nocov:

# shellcheck source=src/shared/lib/all.sh
. "$functions_dir/all.sh"

# Main program.
main() {
      init_exit_handler
      init_component_environment "build"

      # Script variables.
      local maven_settings_file="$shared_dir/settings.xml"
      local maven_repo_dir=".m2-local"

      # List configuration for debugging purposes.
      log_info "maven_settings_file = $maven_settings_file"
      log_info "maven_repo_dir = $maven_repo_dir"
      log_info "pwd = $(pwd)"

      # Run Maven package, skipping tests.
      mvn package -DskipTests \
            -Dmaven.repo.local="$maven_repo_dir" \
            -s "$maven_settings_file"

      log_info "Build completed successfully."
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
      main "$@"
fi
