# UPM Packages

The UPM packages project provides containerized database and middleware software packages for the Universal Platform Manager (UPM). This repository includes Docker images, Helm charts, configuration templates, and parameter management files for deploying and managing various software components.

## Overview

This repository offers pre-packaged deployments for:
- **Databases**: MySQL, PostgreSQL
- **Proxies**: PgBouncer, ProxySQL, MySQL Router
- **Message Queue**: Kafka
- **Search & Analytics**: Elasticsearch, Kibana
- **Agents**: Database-specific monitoring agents

## Repository Structure

Each component follows a consistent structure:

```
<component>/
  <version>/
    image/           # Docker image context
      Dockerfile     # Multi-stage build with Rocky Linux base
      serverMGR.sh   # Initialization and management script
      supervisord.conf # Process supervisor configuration
    charts/          # Helm chart files
      Chart.yaml     # Chart metadata with bitnami-common dependency
      values.yaml    # Default configuration values
      templates/     # Kubernetes resource templates
        configTemplate.yaml  # ConfigMap with configuration templates
        podtemplate.yaml     # PodTemplate definition
        configValue.yaml     # Configuration value mappings
        parametersDetail.yaml # Parameter definitions
      files/         # Configuration template files
        *.tpl        # Go template files for dynamic configuration
        *.json       # Parameter detail definitions
```

## Quick Start

### Prerequisites

- [Helm](https://helm.sh) must be installed to use the charts
- [Docker](https://docker.com) for building images
- Kubernetes cluster for deployment

### Adding the Repository

```bash
# Add the Helm repository
helm repo add upm-packages https://upmio.github.io/upm-packages

# Update the repository
helm repo update

# List available charts
helm search repo upm-packages
```

### Installing a Package

The following example demonstrates installing MySQL Community 8.4.5:

```bash
# Install MySQL Community 8.4.5
helm install --namespace=upm-system upm-packages-mysql-community-8.4.5 upm-packages/mysql-community-8.4.5
```

### Uninstalling

```bash
# Uninstall the package
helm uninstall --namespace=upm-system upm-packages-mysql-community-8.4.5 --wait

# Optionally remove the repository
helm repo remove upm-packages
```

## Development

### Docker Image Building

```bash
# Build for linux/amd64 platform
docker buildx build --platform linux/amd64 -t <image-name>:<version> <context-path>

# Example: Build MySQL 8.4.5 image
docker buildx build --platform linux/amd64 -t quay.io/upmio/mysql-community:8.4.5 mysql-community/8.4.5/image/
```

### Helm Chart Operations

```bash
# Validate chart syntax
helm lint <chart-path>

# Test chart installation (dry run)
helm install --dry-run --debug <release-name> <chart-path>

# Package chart
helm package <chart-directory>
```

### Local Development

```bash
# Install from local chart (for testing)
helm install --namespace=upm-system test-mysql mysql-community/8.4.5
```

## Architecture

### Configuration Management

- **Template System**: Uses Go templates in `.tpl` files with custom functions like `getenv`, `getv`
- **Parameter Mapping**: JSON files define parameter details and validation
- **Dynamic Configuration**: Templates render based on environment variables and values

### Container Management

- **Base Image**: Rocky Linux 9.5 with common tools and locale setup
- **Process Supervision**: Uses supervisord to manage database processes
- **User Management**: Creates application-specific users (UID 1001) for security

### Kubernetes Integration

- **Pod Templates**: Standardized pod specifications with security contexts
- **Config Maps**: Store configuration templates and parameter mappings
- **Helm Dependencies**: Uses bitnami-common charts for shared functionality

## Available Packages

### Database Systems
- **MySQL Community**: Versions 8.0.40, 8.0.41, 8.0.42, 8.4.4, 8.4.5
- **PostgreSQL**: Versions 15.12, 15.13

### Database Proxies
- **PgBouncer**: Versions 1.23.1, 1.24.1
- **ProxySQL**: Versions 2.7.2, 2.7.3
- **MySQL Router**: Versions 8.0.40, 8.0.41, 8.0.42, 8.4.4, 8.4.5

### Message Queue
- **Kafka**: Version 3.5.2

### Search & Analytics
- **Elasticsearch**: Version 7.17.14
- **Kibana**: Version 7.17.14

### Monitoring Agents
- **MySQL Community Agent**: Versions 8.0, 8.4
- **PostgreSQL Agent**: Version 15.12

## CI/CD Pipeline

- **Image Building**: Images are automatically built and pushed to quay.io on changes to `image/` directories
- **Chart Publishing**: Helm charts are automatically released on changes to `charts/` directories
- **Repository**: Charts are published to GitHub Pages at https://upmio.github.io/upm-packages

## Key Components

1. **serverMGR.sh**: Initialization script with logging, password management, and service control
2. **supervisord.conf**: Process management configuration
3. **configTemplate.yaml**: Kubernetes ConfigMap for configuration templates
4. **parametersDetail.json**: Parameter definitions with types and defaults

## Support

For issues and questions, please refer to the [GitHub repository](https://github.com/upmio/upm-packages).
