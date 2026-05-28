#!/usr/bin/env bats
# ================================================================
# unit.bats – Bats tests for src/test/jobs/unit.sh
#
# Tests the standalone unit test script which runs
# mvn test to execute unit tests.
#
# Exit codes:
#     0 - tests pass
#     1 - Maven/test failure
#   201 - pom.xml not found
#   202 - Surefire plugin not configured
#   220 - required environment variables missing
#
# Requirements: Maven + JDK on PATH (use 'mise install' to set up)
#
# Run with: mise exec -- bats tests/test/unit.bats
# ================================================================

# --------------------------------------- File-level setup (once per .bats file)

setup_file() {
	local project_root="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.."; pwd)"

	# Create a shared Maven cache so plugins aren't re-downloaded for every test.
	SHARED_MAVEN_CACHE="$project_root/.mvn-test-cache"
	if [ ! -d "$SHARED_MAVEN_CACHE" ]; then
		mkdir -p "$SHARED_MAVEN_CACHE"
		echo "First test may take some time to seed the maven test cache ..." >&3
	fi
	export SHARED_MAVEN_CACHE

	# Setup PATH to reach the job script under test.
	DIR="$(cd "$project_root/src/test/jobs"; pwd)"
	export PATH="$DIR:$PATH"

	# Get reference to fixtures directory.
	FIXTURES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/fixtures"; pwd)"
	export FIXTURES_DIR
}

# ---------------------------------------------------- Per-test setup & teardown

setup() {
	# Switch to an isolated sandbox directory for each test.
	TEST_SANDBOX="$(mktemp -d)"
	cd "$TEST_SANDBOX"
	export TEST_SANDBOX

	# Symlink shared Maven cache to avoid re-downloading per test.
	ln -s "$SHARED_MAVEN_CACHE" "$TEST_SANDBOX/.m2-local"

	# Load shared code and helpers.
	load '../../vendor/bats-support/load'
	load '../../vendor/bats-assert/load'
	load '../../vendor/bats-file/load'
	load '../shared/helpers.bash'
}

teardown() {
	rm -rf "$TEST_SANDBOX"
}

# ------------------------------------------------------------------------ Tests

# ================================================================
# Environment validation
# ================================================================

@test "unit.sh fails when required environment variables are missing" {
	unset COMPONENT_SHA
	unset COMPONENT_PROJECT_PATH
	unset COMPONENT_VERSION
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"

	run "unit.sh"

	assert_failure 220
}

# ================================================================
# Surefire plugin validation
# ================================================================

@test "unit.sh fails with exit 201 when pom.xml is missing" {
	stub_valid_component_environment
	# Empty directory - no pom.xml

	run "unit.sh"

	assert_failure 201
}

@test "unit.sh succeeds when Surefire plugin is explicitly configured" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"

	run "unit.sh"

	assert_success
}

@test "unit.sh succeeds when parent POM is present (inherited Surefire)" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"
	# Fixture should have a parent POM reference

	run "unit.sh"

	assert_success
}

# ================================================================
# Unit tests (src/test/jobs/unit.sh)
# ================================================================

@test "unit.sh succeeds for project with passing tests" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"

	run "unit.sh"

	assert_success
}

@test "unit.sh fails for project with failing tests" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/failing-unit-tests"

	run "unit.sh"

	assert_failure
}

@test "unit.sh produces surefire reports" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"

	run "unit.sh"

	assert_success
	assert_file_exists "./target/surefire-reports"
}

@test "unit.sh produces JaCoCo coverage report" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"

	run "unit.sh"

	assert_success
	assert_file_exists "./target/site/jacoco/jacoco.xml"
	assert_file_exists "./target/site/jacoco/jacoco.csv"
}

@test "unit.sh outputs coverage percentage for GitLab" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-unit-tests"

	run "unit.sh"

	assert_success
	# Coverage output should match regex: /^(\d+\.?\d+?\%)\scovered\s*$/
	assert_output --partial "% covered"
}
