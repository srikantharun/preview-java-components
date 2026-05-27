# ${{ values.name }}

${{ values.description }}

## Getting Started

### Prerequisites

- Java ${{ values.java_version }}
- Maven 3.9+

### Build

```bash
mvn clean package
```

### Run

```bash
java -jar target/${{ values.artifact_id }}-0.0.1-SNAPSHOT.jar
```

### Test

```bash
mvn test
```

## CI/CD Pipeline

This project uses the [java/app-pipeline](https://gitlab.com/dwp/engineering/pipeline-solutions/gitlab/components/java) GitLab CI component.

Pipeline includes:
- Build (JAR)
- Unit tests
- Integration tests
- Static analysis (Checkstyle, SpotBugs, PMD)
- Security scanning (SonarQube, container scan)
- Docker image build
{% if values.has_api %}
- API testing{% if values.use_wiremock %} with Wiremock{% endif %}
- API fuzzing
- DAST API
{% endif %}

## Owner

${{ values.owner }}
