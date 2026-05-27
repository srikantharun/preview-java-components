# build

Builds JAR file for Java projects.

## Quick Start

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/build@1.0.0
```

## What It Does

The build component runs `mvn package -DskipTests` to produce a JAR file. Tests are **not** run here - use the `java/test` component for testing.

**Prescribed behavior:**
- Dependencies resolved in `install` stage
- JAR built in `build` stage
- Tests skipped (separation of concerns)

## Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `java_version` | string | `25` | Java version (`21` or `25`) |
| `component_context_dir` | string | `./` | Working directory |
| `job_name_prefix` | string | `""` | Prefix for job names |

## Jobs

| Job | Stage | Description |
|-----|-------|-------------|
| `java::build::dependencies` | install | Resolve and cache Maven dependencies |
| `java::build::package` | build | Build JAR (`mvn package -DskipTests`) |

## Output

- `target/*.jar` - Built JAR file(s)
- `.m2-local/` - Cached Maven dependencies
