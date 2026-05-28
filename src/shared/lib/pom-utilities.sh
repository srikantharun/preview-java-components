# shellcheck shell=bash

# =============================================================================
# pom-utilities.sh - POM file validation and manipulation utilities
# =============================================================================

# Validates that the Surefire plugin is configured in the pom.xml.
# Exit codes: 201-209 reserved for plugin validation failures.
# Arguments:
#   $1 - Path to the pom.xml file (default: ./pom.xml)
# Returns:
#   0 - Surefire plugin found
#   201 - pom.xml not found
#   202 - Surefire plugin not configured
validate_surefire_plugin() {
	local pom_file="${1:-pom.xml}"

	if [[ ! -f "$pom_file" ]]; then
		log_fatal "pom.xml not found at: $pom_file"
		return 201
	fi

	# Check if Surefire plugin is configured (either explicitly or via parent POM inheritance)
	# Look for maven-surefire-plugin in the pom.xml
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

# Injects skipUnitTests configuration into pom.xml if not already present.
# This allows -DskipUnitTests=true to work for skipping unit tests during integration tests.
# Arguments:
#   $1 - Path to the pom.xml file (default: ./pom.xml)
# Returns:
#   0 - Configuration injected or already present
#   201 - pom.xml not found
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
		# Use sed to add configuration after the artifactId line
		sed -i.tmp '/<artifactId>maven-surefire-plugin<\/artifactId>/a\
        <configuration>\
          <skipTests>${skipUnitTests}</skipTests>\
        </configuration>' "$pom_file"
		rm -f "${pom_file}.tmp"
		log_info "Added skipUnitTests configuration to existing Surefire plugin"
	else
		# Plugin not explicitly configured - add full plugin configuration
		# Find the </plugins> or </build> tag and insert before it
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
			# Build section exists but no plugins - add plugins section
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
			# No build section - add complete build section before </project>
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
# The output format matches GitLab's coverage regex: "XX.XX% covered"
# Arguments:
#   $1 - Path to jacoco.csv file (default: ./target/site/jacoco/jacoco.csv)
# Returns:
#   0 - Coverage extracted successfully
#   1 - Coverage file not found
extract_coverage() {
	local jacoco_csv="${1:-target/site/jacoco/jacoco.csv}"

	if [[ ! -f "$jacoco_csv" ]]; then
		log_warn "JaCoCo CSV report not found at: $jacoco_csv"
		return 1
	fi

	# Extract coverage using awk (matches fragment's approach)
	# Format: "XX.XX% covered" for GitLab coverage regex
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
