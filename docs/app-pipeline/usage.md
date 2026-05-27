# app-pipeline

Meta-component that composes all Java atomic components with prescribed best practices.

## Quick Start

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/app-pipeline@1.0.0

stages:
  - .pre
  - install
  - build
  - unit-test
  - code-analysis
  - package
  - integration-test
  - security-static-analysis
  - security-dynamic-analysis
  - .post
```

**That's it.** Zero inputs required for most projects.

## Prescribed Behavior

With default settings, you get:

| Capability | Included | Rationale |
|------------|----------|-----------|
| Lint (Checkstyle, SpotBugs, PMD) | Always | Code quality |
| Build (JAR) | Always | Produces artifact |
| Unit tests | Always | Non-negotiable |
| Integration tests | Always | Best practice |
| Mutation tests | Always | Quality assurance |
| Docker build | Always | Container deployment |
| Security (SonarQube, container scan) | Always | Shift-left security |
| Release (auto-tag-merge) | Always | Release automation |
| Wiremock API tests | When `has_api=true` | API projects |
| Dynamic security (DAST, API fuzzer) | When `has_api=true` | API security |
| Performance tests | When configured | Opt-in |

## Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `java_version` | string | `25` | Java version (`21` or `25`) |
| `has_api` | boolean | `true` | Project exposes an HTTP API |
| `use_wiremock` | boolean | `true` | Use Wiremock for API tests |
| `run_mutation_tests` | boolean | `true` | Run PiTest mutation testing |
| `run_performance_tests` | boolean | `false` | Run K6 performance tests |
| `k6_test_file` | string | `""` | Path to K6 test script |
| `component_context_dir` | string | `./` | Working directory |
| `job_name_prefix` | string | `""` | Job name prefix |

## Application Profiles

### API Backend (default)

```yaml
include:
  - component: $CI_SERVER_FQDN/.../java/app-pipeline@1.0.0
    # No inputs needed - defaults are correct
```

Jobs: lint, build, test (unit, integration, wiremock, mutation), docker, security, security-dynamic, release

### API Backend without Wiremock

```yaml
include:
  - component: $CI_SERVER_FQDN/.../java/app-pipeline@1.0.0
    inputs:
      use_wiremock: false
```

### Non-API Application

```yaml
include:
  - component: $CI_SERVER_FQDN/.../java/app-pipeline@1.0.0
    inputs:
      has_api: false
```

Excludes: OpenAPI validation, Wiremock, API fuzzing, DAST API

## Invalid Combinations

```yaml
# INVALID - will fail with exit code 70
inputs:
  has_api: false
  use_wiremock: true  # Wiremock needs an API to mock!
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 70 | Invalid input combination |
| 211 | Checkstyle violations |
| 212 | SpotBugs violations |

## Support

- **Issues:** [Raise in this repository][support-issue]
- **Slack:** [#support-cicd-components][support-slack]

[support-issue]: /dwp/engineering/pipeline-solutions/gitlab/components/java/-/issues
[support-slack]: https://dwpdigital.slack.com/archives/C025DK6HFPS
