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

# shellcheck source=src/shared/lib/pom-utilities.sh
. "$functions_dir/pom-utilities.sh"

# Main program.
main() {
	init_exit_handler
	init_component_environment "test"

	# Script variables.
	local maven_settings_file="$shared_dir/settings.xml"
	local maven_repo_dir=".m2-local"
	local pom_file="pom.xml"

	# renovate: datasource=maven depName=org.jacoco:jacoco-maven-plugin
	local jacoco_version="0.8.12"

	# List configuration for debugging purposes.
	log_info "maven_settings_file = $maven_settings_file"
	log_info "maven_repo_dir = $maven_repo_dir"
	log_info "jacoco_version = $jacoco_version"
	log_info "pwd = $(pwd)"

	# Validate Surefire plugin is configured (exit 201-209 if not)
	validate_surefire_plugin "$pom_file"

	# Run Maven unit tests with JaCoCo coverage.
	# - prepare-agent: Instruments bytecode to track coverage
	# - test: Runs unit tests only (not verify which includes integration tests)
	# - -DskipITs=true: Explicitly skip integration tests
	# - report: Generates coverage XML at target/site/jacoco/jacoco.xml
	log_info "Running unit tests with JaCoCo coverage..."
	mvn org.jacoco:jacoco-maven-plugin:${jacoco_version}:prepare-agent \
		test \
		org.jacoco:jacoco-maven-plugin:${jacoco_version}:report \
		-DskipITs=true \
		-Dmaven.repo.local="$maven_repo_dir" \
		-s "$maven_settings_file"

	log_info "Unit tests completed successfully."

	# Extract and display coverage for GitLab
	# Output format matches coverage regex: /^(\d+\.?\d+?\%)\scovered\s*$/
	log_info "Extracting coverage report..."
	extract_coverage "target/site/jacoco/jacoco.csv" || true
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
