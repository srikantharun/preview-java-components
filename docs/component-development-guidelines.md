# Component Development Guidelines

This document captures the principles and patterns to follow when developing GitLab CI components, based on the component-blueprint pattern.

## Template Configuration

### 1. Use `job_stage` Input

Always provide a configurable `job_stage` input instead of hardcoding stages:

```yaml
spec:
  inputs:
    job_stage:
      default: "build"
      description: "Pipeline stage in which jobs are run"
      type: string
```

Then reference it in the job:

```yaml
stage: $[[ inputs.job_stage ]]
```

### 2. Input Naming: Pass-through vs Private

**Pass-through inputs** (values passed from parent to child templates) should NOT have `_` prefix:
- `java_version` - passed through from component to common.yml

**Private inputs** (internal inputs only used within the template) SHOULD have `_` prefix:
- `_component_sha` - derived from `component.sha`
- `_component_version` - derived from `component.version`
- `_component_image_variant` - computed internally

```yaml
include:
  - local: /templates/shared/common.yml
    inputs:
      component_context_dir: "$[[ inputs.component_context_dir ]]"
      job_name_prefix: "$[[ inputs.job_name_prefix ]]"
      job_stage: "$[[ inputs.job_stage ]]"
      _component_sha: "$[[ component.sha ]]"
      _component_version: "$[[ component.version ]]"
      java_version: "$[[ inputs.java_version ]]"  # No underscore - pass-through
```

### 3. Component SHA and Version Pattern

Use `_component_sha` and `_component_version` for image variant selection:

```yaml
spec:
  inputs:
    java_version:                    # Pass-through (no underscore)
    # Private variables.
    _component_sha:
    _component_version:
      default: ""
    _component_image_variant:
      type: string
      rules:
        - if: $[[ inputs._component_version ]] == ""
          default: "sha"
        - default: "version"
---

# Hidden job for SHA-based image
".$[[ inputs.job_name_prefix ]]java::common::image-sha":
  image: "$CI_REGISTRY/.../java:$[[ inputs._component_sha ]]-jdk$[[ inputs.java_version ]]"

# Hidden job for version-based image
".$[[ inputs.job_name_prefix ]]java::common::image-version":
  image: "$CI_REGISTRY/.../java:$[[ inputs._component_version ]]-jdk$[[ inputs.java_version ]]"

# Main common job extends the appropriate image job
".$[[ inputs.job_name_prefix ]]java::common":
  extends: ".$[[ inputs.job_name_prefix ]]java::common::image-$[[ inputs._component_image_variant | expand_vars ]]"
```

### 4. Use `CI_REGISTRY` for Image URLs

Use `$CI_REGISTRY` (not `$CI_TEMPLATE_REGISTRY_HOST`) for Docker image URLs:

```yaml
# CORRECT
image: "$CI_REGISTRY/dwp/engineering/pipeline-solutions/gitlab/components/java:..."

# WRONG
image: "$CI_TEMPLATE_REGISTRY_HOST/dwp/engineering/pipeline-solutions/gitlab/components/java:..."
```

### 5. No Duplicate `before_script`

The `before_script` (cd into context directory) is defined in the common job. Do NOT duplicate it in component jobs:

```yaml
# WRONG - duplicates common job's before_script
"$[[ inputs.job_name_prefix ]]java::build":
  before_script:
    - cd "$[[ inputs.component_context_dir ]]"
  extends: ".$[[ inputs.job_name_prefix ]]java::common"
  script: /component/build/jobs/package.sh

# CORRECT - inherits before_script from common job
"$[[ inputs.job_name_prefix ]]java::build":
  extends: ".$[[ inputs.job_name_prefix ]]java::common"
  script: /component/build/jobs/package.sh
```

### 6. Single Job Pattern

Do not use separate dependency installation jobs or `install` stage:

```yaml
# WRONG
stages:
  - install
  - build

# CORRECT
stages:
  - build
  - assert
```

## Shell Scripts

### 7. Production Script Pattern

Align with checkstyle.sh/spotbugs.sh style:

```bash
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
      init_component_environment "build"  # Use this, not custom validate_environment

      # Script variables.
      local maven_settings_file="$shared_dir/settings.xml"
      local maven_repo_dir=".m2-local"

      # List configuration for debugging purposes.
      log_info "maven_settings_file = $maven_settings_file"
      log_info "maven_repo_dir = $maven_repo_dir"
      log_info "pwd = $(pwd)"

      # Main job logic here...

      log_info "Build completed successfully."
}

# Run main program.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
      main "$@"
fi
```

Key elements:
- `set -euo pipefail` for strict error handling
- Use `# :nocov:` markers around path resolution blocks
- Use `init_component_environment "<component>"` (NOT custom `validate_environment`)
- Use `maven_repo_dir` variable (not hardcoded `.m2-local`)
- Use `shared_dir` for settings.xml path
- Log configuration variables for debugging
- Use tabs for indentation (6 spaces = 1 tab)

### 8. Assertion Script Naming

Use simple names for assertion scripts:

```
# CORRECT
assert.pass.sh
assert.fail.sh

# WRONG (too verbose)
assert.pass.jar-produced.sh
assert.fail.no-jar-produced.sh
```

### 9. Assertion Scripts: Use `log_fail` Not `log_fatal`

In assertion scripts, use `log_fail` to report assertion failures (not `log_fatal`):

```bash
# CORRECT
if ls "${fixture_dir}"/target/*.jar 1>/dev/null 2>&1; then
    log_ok "JAR file found"
else
    log_fail "No JAR file found in ${fixture_dir}/target/"
    exit_code="1"
fi

# WRONG
if ! ls "${fixture_dir}"/target/*.jar 1>/dev/null 2>&1; then
    log_fatal "No JAR file found"  # Don't use log_fatal for assertions
fi
```

### 10. Heredoc Indentation: Use Tabs

When using `<<-EOF` heredocs (with dash for indentation stripping), the content MUST be indented with tabs (not spaces):

```bash
stub_program_output() {
  local program_name="${1:?Missing program_name}"
  local program_stub_output="${2:-}"
  local program_stub_path

  program_stub_path="$(mktemp -d)/$program_name"

  # NOTE: Lines inside heredoc must use TABS for <<-EOF to strip them
  cat<<-EOF >"$program_stub_path"
	#!/usr/bin/env bash
	echo "$program_stub_output"
	EOF
  chmod u+x "$program_stub_path"

  PATH="$(dirname "$program_stub_path"):$PATH"
  export PATH
}
```

## Test Pipelines

### 11. Assert Job Naming

Use `assert::pass` and `assert::fail` naming convention for assertion jobs:

```yaml
# CORRECT
assert::pass:
  stage: assert
  script: pipeline/test-pipelines/build/javabuild/assert.pass.sh "..."

assert::fail:
  stage: assert
  script: pipeline/test-pipelines/build/javabuild/assert.fail.sh "..."

# WRONG
assertions:
  stage: assert
  script: ...
```

### 12. No `needs` in Assert Jobs

Don't use `needs` in assertion jobs - stages handle ordering naturally:

```yaml
# WRONG - unnecessary needs section
assert::pass:
  stage: assert
  needs:
    - "java::build"
  script: ...

# CORRECT - stage ordering is sufficient
assert::pass:
  stage: assert
  script: ...
```

## Unit Testing

### 13. BATS Test Pattern

Use PATH setup and call scripts by name:

```bash
setup_file() {
	local project_root="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.."; pwd)"

	# Setup PATH to reach the job script under test.
	DIR="$(cd "$project_root/src/build/jobs"; pwd)"
	export PATH="$DIR:$PATH"

	# ... other setup ...
}

@test "package.sh succeeds for valid project" {
	stub_valid_component_environment
	prepare_fixture "$FIXTURES_DIR/valid-project"

	run "package.sh"  # Call by name, not full path

	assert_success
}
```

Key elements:
- Add script directory to PATH in `setup_file()`
- Call scripts by name: `run "package.sh"` (not `run "$PROJECT_ROOT/src/build/jobs/package.sh"`)
- Use tabs for indentation throughout
- No need for `PROJECT_ROOT` variable if only used for script paths

### 14. Shared Test Helpers

Place reusable test helpers in `tests/shared/helpers.bash`. Do NOT duplicate helpers in component-specific directories:

```bash
# tests/shared/helpers.bash - single source of truth
stub_valid_component_environment() {
  export COMPONENT_NAME="test"
  export COMPONENT_SHA="abcd1234"
  export COMPONENT_PROJECT_PATH="path/to/component"
  export COMPONENT_VERSION="0.0.0"
  export CI_SERVER_URL="https://nowhere.test/"
}

stub_program_output() {
  local program_name="${1:?Missing program_name}"
  local program_stub_output="${2:-}"
  # ... creates stub executable on PATH ...
}
```

Load from component tests:
```bash
# tests/build/package.bats
load '../shared/helpers.bash'

# tests/lint/checkstyle.bats
load '../shared/helpers.bash'
```

### 15. Test File Naming

Name test files after the production script they test:
- Production: `src/build/jobs/package.sh`
- Test: `tests/build/package.bats`

## Directory Structure Reference

```
src/
  build/
    jobs/
      package.sh          # Production scripts
  shared/
    lib/
      all.sh              # Shared functions
    settings.xml          # Maven settings

tests/
  build/
    package.bats          # Unit tests
    fixtures/
      valid-project/
      compilation-error/
  shared/
    helpers.bash          # Shared test helpers
  vendor/
    bats-support/
    bats-assert/
    bats-file/

pipeline/
  test-pipelines/
    build/
      pass.gitlab-ci.yml    # Contains assert::pass job
      fail.gitlab-ci.yml    # Contains assert::fail job
      assert.pass.sh        # Simple names
      assert.fail.sh
      fixtures/
        pass/
        fail/

templates/
  build.yml               # Component template
  shared/
    common.yml            # Shared template configuration
```

## Checklist for New Components

### Template Configuration
- [ ] `job_stage` input is configurable (not hardcoded)
- [ ] Pass-through inputs have no `_` prefix; private inputs have `_` prefix
- [ ] Using `_component_sha` and `_component_version` pattern
- [ ] Using `$CI_REGISTRY` for image URLs (not `$CI_TEMPLATE_REGISTRY_HOST`)
- [ ] No duplicate `before_script` in component jobs
- [ ] No `install` stage - use single job pattern

### Shell Scripts
- [ ] Shell scripts use `init_component_environment "<component>"`
- [ ] Shell scripts use `maven_repo_dir` variable
- [ ] Shell scripts aligned with checkstyle.sh/spotbugs.sh style
- [ ] Assertion scripts use simple names (assert.pass.sh, assert.fail.sh)
- [ ] Assertion scripts use `log_fail` (not `log_fatal`)
- [ ] Heredocs use tabs for indentation (for `<<-EOF`)

### Test Pipelines
- [ ] Assert jobs named `assert::pass` and `assert::fail`
- [ ] No `needs` section in assert jobs (stages handle ordering)

### Unit Tests
- [ ] BATS tests use PATH setup and call scripts by name
- [ ] BATS tests use tabs indentation
- [ ] Test helpers in `tests/shared/helpers.bash` only (no duplicates)
