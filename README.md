# Java Components

A collection of GitLab CI/CD Components for building, testing, and deploying Java applications.

## Design Philosophy

**Convention over Configuration** - Components work out of the box with prescribed best practices. Minimal inputs required.

| Principle | Implementation |
|-----------|---------------|
| Sensible defaults | Best practices are ON by default |
| Minimal inputs | Only expose what users truly need to change |
| Hide Maven | Abstracts Maven lifecycle - customers see `build`, `test`, `lint` |
| Prescribe quality | Mutation tests, integration tests enabled by default |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    java/app-pipeline                            │
│                    (meta-component)                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌──────┐ ┌────────┐ ┌───────┐         │
│  │lint │ │build│ │test │ │docker│ │security│ │release│   ...   │
│  └─────┘ └─────┘ └─────┘ └──────┘ └────────┘ └───────┘         │
│                    (atomic components)                          │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Option 1: Use the meta-component (recommended)

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/app-pipeline@1.0.0
```

That's it. Zero configuration needed for most projects.

### Option 2: Compose atomic components

```yaml
include:
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/build@1.0.0
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/test@1.0.0
  - component: $CI_SERVER_FQDN/dwp/engineering/pipeline-solutions/gitlab/components/java/lint@1.0.0
```

## Components

### Meta-Component

| Component | Description |
|-----------|-------------|
| [app-pipeline](./docs/app-pipeline/usage.md) | Complete pipeline for Java applications. Composes atomic components with prescribed best practices. |

### Atomic Components

| Component | What It Does | Prescribed Behavior |
|-----------|--------------|---------------------|
| [build](./docs/build/usage.md) | Builds JAR file | `mvn package -DskipTests` |
| [test](./docs/test/usage.md) | Runs all tests | Unit, integration, mutation ON by default |
| [lint](./docs/lint/usage.md) | Static analysis | Checkstyle, SpotBugs, PMD |
| [docker](./docs/docker/usage.md) | Docker image | Build and push |
| [security](./docs/security/usage.md) | Security scanning | SonarQube, container scan |
| [security-dynamic](./docs/security-dynamic/usage.md) | Dynamic security | API fuzzing, DAST |
| [performance](./docs/performance/usage.md) | Performance tests | K6 load testing |
| [release](./docs/release/usage.md) | Release management | Auto-tag-merge |

## Prescribed Best Practices

| Feature | Default | Why |
|---------|---------|-----|
| Integration tests | ON | Essential for quality |
| Mutation tests | ON | Catches bugs unit tests miss |
| Static analysis | ON | Early bug detection |
| Security scanning | ON | Shift-left security |

## Standard Inputs

All components accept these minimal inputs:

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `java_version` | string | `25` | Java version (`21` or `25`) |
| `component_context_dir` | string | `./` | Working directory (for monorepos) |
| `job_name_prefix` | string | `""` | Job name prefix (for monorepos) |

## Migration from Legacy Templates

| Legacy Template | New Configuration |
|-----------------|-------------------|
| `java-backend` | `has_api: true, use_wiremock: true` |
| `java-backend-without-wiremock` | `has_api: true, use_wiremock: false` |
| `java-backend-no-api` | `has_api: false` |

See the [Migration Guide](./docs/app-pipeline/migration.md) for details.

## Support

- **Issues:** [Raise in this repository][support-issue]
- **Slack:** [#support-cicd-components][support-slack]

[support-issue]: /dwp/engineering/pipeline-solutions/gitlab/components/java/-/issues
[support-slack]: https://dwpdigital.slack.com/archives/C025DK6HFPS
