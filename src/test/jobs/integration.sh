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

# Injects skipUnitTests configuration into pom.xml if not already present.
# This allows -DskipUnitTests=true to work for skipping unit tests during integration tests.
inject_skip_unit_tests_config() {
	local pom_file="${1:-pom.xml}"

	if [[ ! -f "$pom_file" ]]; then
		log_fatal "pom.xml not found at: $pom_file"
		return 201
	fi

	# Check if skipUnitTests configuration already exists
	if grep -q "skipUnitTests" "$pom_file"; then
		log_info "skipUnitTests configuration already present in pom.xml"
		return 0
	fi

	log_info "Injecting skipUnitTests configuration into pom.xml"

	# Create backup
	cp "$pom_file" "${pom_file}.backup"

	# Check if maven-surefire-plugin is already configured
	if grep -q "maven-surefire-plugin" "$pom_file"; then
		# Plugin exists - inject configuration into existing plugin block
		sed -i.tmp '/<artifactId>maven-surefire-plugin<\/artifactId>/a\
        <configuration>\
          <skipTests>${skipUnitTests}</skipTests>\
        </configuration>' "$pom_file"
		rm -f "${pom_file}.tmp"
		log_info "Added skipUnitTests configuration to existing Surefire plugin"
	else
		# Plugin not explicitly configured - add full plugin configuration
		if grep -q "</plugins>" "$pom_file"; then
			sed -i.tmp 's|</plugins>|<plugin>\
        <groupId>org.apache.maven.plugins</groupId>\
        <artifactId>maven-surefire-plugin</artifactId>\
        <configuration>\
          <skipTests>${skipUnitTests}</skipTests>\
        </configuration>\
      </plugin>\
      </plugins>|' "$pom_file"
			rm -f "${pom_file}.tmp"
			log_info "Added Surefire plugin with skipUnitTests configuration"
		elif grep -q "<build>" "$pom_file"; then
			sed -i.tmp 's|</build>|<plugins>\
      <plugin>\
        <groupId>org.apache.maven.plugins</groupId>\
        <artifactId>maven-surefire-plugin</artifactId>\
        <configuration>\
          <skipTests>${skipUnitTests}</skipTests>\
        </configuration>\
      </plugin>\
    </plugins>\
    </build>|' "$pom_file"
			rm -f "${pom_file}.tmp"
			log_info "Added plugins section with Surefire configuration"
		else
			sed -i.tmp 's|</project>|<build>\
    <plugins>\
      <plugin>\
        <groupId>org.apache.maven.plugins</groupId>\
        <artifactId>maven-surefire-plugin</artifactId>\
        <configuration>\
          <skipTests>${skipUnitTests}</skipTests>\
        </configuration>\
      </plugin>\
    </plugins>\
  </build>\
</project>|' "$pom_file"
			rm -f "${pom_file}.tmp"
			log_info "Added build section with Surefire configuration"
		fi
	fi

	return 0
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

	# Inject skipUnitTests configuration into pom.xml if not already present
	# This allows -DskipUnitTests=true to skip unit tests during integration test phase
	inject_skip_unit_tests_config "$pom_file"

	# Run Maven integration tests with JaCoCo coverage.
	# - prepare-agent: Instruments bytecode to track coverage
	# - verify: Runs full lifecycle including integration tests (failsafe)
	# - -DskipUnitTests=true: Skip unit tests (run integration tests only)
	# - report: Generates coverage XML at target/site/jacoco/jacoco.xml
	log_info "Running integration tests with JaCoCo coverage..."
	mvn org.jacoco:jacoco-maven-plugin:${jacoco_version}:prepare-agent \
		verify \
		org.jacoco:jacoco-maven-plugin:${jacoco_version}:report \
		-DskipUnitTests=true \
		-Dmaven.repo.local="$maven_repo_dir" \
		-s "$maven_settings_file"

	log_info "Integration tests completed successfully."

	# Extract and display coverage for GitLab
	# Output format matches coverage regex: /^(\d+\.?\d+?\%)\scovered\s*$/
	log_info "Extracting coverage report..."
	extract_coverage "target/site/jacoco/jacoco.csv" || true
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
