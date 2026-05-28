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

# =============================================================================
# POM Utilities (inlined)
# =============================================================================

# Validates that the Surefire plugin is configured in the pom.xml.
# Exit codes: 201-209 reserved for plugin validation failures.
validate_surefire_plugin() {
	local pom_file="${1:-pom.xml}"

	if [[ ! -f "$pom_file" ]]; then
		log_fatal "pom.xml not found at: $pom_file"
		return 201
	fi

	# Check if Surefire plugin is configured (either explicitly or via parent POM inheritance)
	if grep -q "maven-surefire-plugin" "$pom_file"; then
		log_info "Surefire plugin found in pom.xml"
		return 0
	fi

	# Check if there's a parent POM that might provide Surefire (common in Spring Boot, etc.)
	if grep -q "<parent>" "$pom_file"; then
		log_info "Parent POM detected - assuming Surefire plugin inherited"
		return 0
	fi

	# Check if there's a packaging type that implies Surefire (jar, war, etc.)
	local packaging
	packaging=$(grep -oP '(?<=<packaging>)[^<]+' "$pom_file" 2>/dev/null || echo "jar")
	if [[ "$packaging" =~ ^(jar|war|ear|ejb)$ ]]; then
		log_info "Standard packaging type '$packaging' detected - Surefire plugin assumed via Maven defaults"
		return 0
	fi

	log_fatal "Surefire plugin not configured in pom.xml. Please add maven-surefire-plugin to your build configuration."
	return 202
}

# Extracts and prints coverage percentage from JaCoCo CSV report.
# Output format matches GitLab's coverage regex: "XX.XX% covered"
extract_coverage() {
	local jacoco_csv="${1:-target/site/jacoco/jacoco.csv}"

	if [[ ! -f "$jacoco_csv" ]]; then
		log_warn "JaCoCo CSV report not found at: $jacoco_csv"
		return 1
	fi

	awk -F"," '{
		instructions += $4 + $5
		covered += $5
		line_condition_cov += $7 + $9
		line_condition_total += $6 + $7 + $8 + $9
	} END {
		print line_condition_cov, "/", line_condition_total, " line conditions covered"
		print covered, "/", instructions, " instructions covered"
		print 100*covered/instructions "% covered"
	}' "$jacoco_csv"
}

# =============================================================================
# Main program
# =============================================================================

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
