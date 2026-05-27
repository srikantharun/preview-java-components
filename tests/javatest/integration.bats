#!/usr/bin/env bats
# ================================================================
# integration.bats – Bats tests for src/test/jobs/integration.sh
#
# Tests the standalone integration test script which runs
# mvn verify -DskipUnitTests to execute integration tests.
#
# Exit codes:
#     0 - tests pass
#     1 - Maven/test failure
#   220 - required environment variables missing
#
# Requirements: Maven + JDK on PATH (use 'mise install' to set up)
#
# Run with: mise exec -- bats tests/javatest/integration.bats
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

@test "integration.sh fails when required environment variables are missing" {
	unset COMPONENT_SHA
	unset COMPONENT_PROJECT_PATH
	unset COMPONENT_VERSION
	prepare_fixture "$FIXTURES_DIR/passing-integration-tests"

	run "integration.sh"

	assert_failure 220
}

# ================================================================
# Integration tests (src/test/jobs/integration.sh)
# ================================================================

@test "integration.sh succeeds for project with passing integration tests" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-integration-tests"

	run "integration.sh"

	assert_success
}

@test "integration.sh fails for project with failing integration tests" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/failing-integration-tests"

	run "integration.sh"

	assert_failure
}

@test "integration.sh produces failsafe reports" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/passing-integration-tests"

	run "integration.sh"

	assert_success
	assert_file_exists "./target/failsafe-reports"
}

@test "integration.sh skips unit tests" {
	stub_valid_component_environment
	# Use passing-integration-tests fixture which only has IT tests
	prepare_fixture "$FIXTURES_DIR/passing-integration-tests"

	# Add a failing unit test to verify it gets skipped
	mkdir -p src/test/java/com/example
	cat > src/test/java/com/example/FailingUnitTest.java << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class FailingUnitTest {
    @Test
    void thisShouldBeSkipped() {
        fail("This unit test should be skipped");
    }
}
EOF

	run "integration.sh"

	# Should pass because unit tests are skipped
	assert_success
}
