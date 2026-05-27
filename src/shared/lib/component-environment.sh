# shellcheck shell=bash

# Dependencies
functions_dir="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
  pwd
)"

. "$functions_dir/log-utilities.sh"

# Validates that required component environment variables are set.
# Exits with code 220 if any required variables are missing.
#
# Usage: init_component_environment "build"
#        init_component_environment "test"
#
# Required environment variables:
#   COMPONENT_SHA          - Git SHA of the component
#   COMPONENT_PROJECT_PATH - GitLab project path
#   COMPONENT_VERSION      - Component version (can be empty)
init_component_environment() {
  local component_name="${1:?Missing component name}"
  local missing_vars=()

  log_info "Initializing $component_name component environment..."

  # Check required environment variables
  if [ -z "${COMPONENT_SHA:-}" ]; then
    missing_vars+=("COMPONENT_SHA")
  fi

  if [ -z "${COMPONENT_PROJECT_PATH:-}" ]; then
    missing_vars+=("COMPONENT_PROJECT_PATH")
  fi

  # COMPONENT_VERSION is optional but should be defined (can be empty)
  if [ -z "${COMPONENT_VERSION+x}" ]; then
    missing_vars+=("COMPONENT_VERSION")
  fi

  # Report and exit if any required variables are missing
  if [ ${#missing_vars[@]} -gt 0 ]; then
    log_fatal "Missing required environment variables: ${missing_vars[*]}"
    log_info "These variables are set automatically when running in GitLab CI."
    log_info "For local testing, export them before running the script."
    exit 220
  fi

  log_info "Component environment validated successfully."
}

# Troubleshooting guide for exit code 220
troubleshoot_220() {
  echo "Missing required environment variables."
  echo ""
  echo "Required variables:"
  echo "  COMPONENT_SHA          - Git SHA of the component"
  echo "  COMPONENT_PROJECT_PATH - GitLab project path"
  echo "  COMPONENT_VERSION      - Component version"
  echo ""
  echo "These are set automatically in GitLab CI pipelines."
  echo "For local testing, export them before running:"
  echo ""
  echo "  export COMPONENT_SHA=\"abc123\""
  echo "  export COMPONENT_PROJECT_PATH=\"my/project\""
  echo "  export COMPONENT_VERSION=\"1.0.0\""
}
