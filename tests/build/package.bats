#!/usr/bin/env bats
# ================================================================
# package.bats – Bats tests for src/build/jobs/package.sh
#
# Tests the standalone package script which runs
# mvn package -DskipTests to build JAR files.
#
# Exit codes:
#     0 - build successful, JAR produced
#     1 - Maven/infrastructure failure (compilation error, missing deps)
#   220 - required environment variables missing
#
# Requirements: Maven + JDK on PATH (use 'mise install' to set up)
#
# Run with: mise exec -- bats tests/build/package.bats
# ================================================================

# --------------------------------------- File-level setup (once per .bats file)

setup_file() {
	local project_root="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.."; pwd)"

	# Create a shared Maven cache so plugins aren't re-downloaded for every test.
	# This cache can be cleaned via the "make clean" command.
	SHARED_MAVEN_CACHE="$project_root/.mvn-test-cache"
	if [ ! -d "$SHARED_MAVEN_CACHE" ]; then
		mkdir -p "$SHARED_MAVEN_CACHE"
		echo "First test may take some time to seed the maven test cache ..." >&3
	fi
	export SHARED_MAVEN_CACHE

	# Setup PATH to reach the job script under test.
	DIR="$(cd "$project_root/src/build/jobs"; pwd)"
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

@test "fails when required environment variables are missing" {
	unset COMPONENT_SHA
	unset COMPONENT_PROJECT_PATH
	unset COMPONENT_VERSION
	prepare_fixture "$FIXTURES_DIR/valid-project"

	run "package.sh"

	assert_failure 220
}

# ================================================================
# Package build (src/build/jobs/package.sh)
# ================================================================

@test "package.sh succeeds and produces JAR for valid project" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/valid-project"

	run "package.sh"

	assert_success
	assert_jar_exists
}

@test "package.sh fails for project with compilation error" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/compilation-error"

	run "package.sh"

	assert_failure
	assert_jar_not_exists
}

@test "package.sh skips tests even when test would fail" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/failing-test"

	run "package.sh"

	assert_success
	assert_jar_exists
}

# ================================================================
# JAR artifact verification
# ================================================================

@test "produced JAR contains compiled classes" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/valid-project"

	run "package.sh"

	# Verify JAR contains expected class
	local jar_file
	jar_file=$(find ./target -maxdepth 1 -name "*.jar" -type f | head -1)

	run jar -tf "$jar_file"

	assert_success
	assert_output --partial "com/example/App.class"
}

@test "produced JAR has correct artifact name from pom.xml" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/valid-project"

	run "package.sh"

	assert_file_exists "./target/test-app-1.0.0-SNAPSHOT.jar"
}
