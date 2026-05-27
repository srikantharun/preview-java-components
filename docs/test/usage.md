# test

Runs all test types for Java projects with prescribed best practices.

## Quick Start

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/test@1.0.0
```

**That's it.** With zero configuration, you get:
- Unit tests (always)
- Integration tests (prescribed ON)
- Mutation tests (prescribed ON)

## Prescribed Behavior

| Test Type | Default | Rationale |
|-----------|---------|-----------|
| Unit tests | **Always** | Non-negotiable quality gate |
| Integration tests | **ON** | Best practice for Java applications |
| Mutation tests | **ON** | Catches bugs that unit tests miss |
| Wiremock | OFF | Opt-in for API projects |

## Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `java_version` | string | `25` | Java version (`21` or `25`) |
| `run_integration_tests` | boolean | `true` | Run integration tests (prescribed ON) |
| `run_wiremock` | boolean | `false` | Run Wiremock API tests (opt-in) |
| `run_mutation_tests` | boolean | `true` | Run PiTest mutation tests (prescribed ON) |
| `component_context_dir` | string | `./` | Working directory |
| `job_name_prefix` | string | `""` | Prefix for job names |

## Jobs

| Job | Stage | Condition | Description |
|-----|-------|-----------|-------------|
| `java::test::unit` | unit-test | Always | Unit tests (`mvn test`) |
| `java::test::integration` | integration-test | `run_integration_tests=true` | Integration tests (`mvn verify`) |
| `java::test::wiremock` | integration-test | `run_wiremock=true` | Wiremock API tests |
| `java::test::mutation` | security-static-analysis | `run_mutation_tests=true` | PiTest mutation coverage |

## Examples

### Enable Wiremock for API projects

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/test@1.0.0
    inputs:
      run_wiremock: true
```

### Disable mutation tests (not recommended)

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/test@1.0.0
    inputs:
      run_mutation_tests: false
```

## Artifacts

- `target/surefire-reports/` - Unit test reports (JUnit XML)
- `target/failsafe-reports/` - Integration test reports (JUnit XML)
- `target/wiremock-reports/` - Wiremock test reports
- `target/pit-reports/` - PiTest mutation coverage reports
