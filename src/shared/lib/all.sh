# shellcheck shell=bash disable=SC1091

# Convenience wrapper to include all shared functions.
functions_dir="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
  pwd
)"

. "$functions_dir/log-utilities.sh"
. "$functions_dir/exit-handler.sh"
. "$functions_dir/component-environment.sh"
