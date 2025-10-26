# UPM Packages

<div align="center">

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Helm Version](https://img.shields.io/badge/Helm-v3-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29%2B-green.svg)](https://kubernetes.io/)
[![Architecture](https://img.shields.io/badge/Platform-linux/amd64%20%7C%20linux/arm64-orange.svg)]()
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Automated-brightgreen.svg)]()

**Unified Platform Management (UPM) Packages - Enterprise-Grade Database & Middleware Deployment System**

[📖 Documentation](#community--support) • [🚀 Quick Start](#quick-start) • [🏗️ Architecture](#architecture) • [📦 Available Packages](#available-packages)

</div>

## Overview

UPM Packages is a comprehensive, production-ready containerization and Kubernetes deployment system designed specifically for database and middleware software components. Built with enterprise requirements in mind, it provides a unified framework for packaging, deploying, and managing complex software ecosystems with consistency, security, and automation at its core.

### 🎯 Key Capabilities

- **🔄 Unified Management**: Single command deployment across 11+ component types
- **🏛️ Enterprise Architecture**: Consistent patterns, security-hardened containers, production-optimized configurations
- **📊 Template System**: Sophisticated Go template engine with dynamic configuration generation
- **🔒 Security First**: Non-root containers, encrypted credentials, process isolation
- **🌐 Multi-Architecture**: Native support for linux/amd64 and linux/arm64
- **📈 Monitoring Ready**: Built-in health checks, metrics exporters, and log management

### 🏢 Production Use Cases

- **Database Clusters**: MySQL, PostgreSQL with automated failover
- **Connection Pooling**: PgBouncer, ProxySQL, MySQL Router for high-performance access
- **Search Platforms**: Elasticsearch, Kibana for log analytics
- **Message Queues**: Kafka for event-driven architectures
- **Coordination Services**: ZooKeeper for distributed system coordination
- **Monitoring**: Database agents with comprehensive metrics collection

## Quick Start

### Prerequisites

```bash
# Required tools
helm version  # Helm 3.x+
docker --version  # Docker with buildx
kubectl version  # Kubernetes cluster access
```

### 🚀 Unified Package Management (Recommended)

Get the complete UPM package management system with a single command:

```bash
# Download and install the unified package management script
curl -sSL https://raw.githubusercontent.com/upmio/upm-packages/main/upm-pkg-mgm.sh -o upm-pkg-mgm.sh
chmod +x upm-pkg-mgm.sh

# View all available packages
./upm-pkg-mgm.sh list

# Install all available packages
./upm-pkg-mgm.sh install all

# Install MySQL Community (component group)
./upm-pkg-mgm.sh install mysql-community

# Check deployment status
./upm-pkg-mgm.sh status

# Upgrade all packages
./upm-pkg-mgm.sh upgrade all
```

> **📖 Complete Guide**: For detailed configuration options and advanced usage, please refer to the [UPM Package Management Documentation](upm-pkg-mgm.md) for comprehensive instructions and best practices.

### 🔧 Manual Helm Installation

For advanced users who prefer direct Helm operations:

```bash
# Add the UPM Packages repository
helm repo add upm-packages https://upmio.github.io/upm-packages
helm repo update

# Install specific version
helm install --namespace=upm-system upm-packages-mysql-community-8.4.5 \
  upm-packages/mysql-community-8.4.5

# Verify deployment
helm status upm-packages-mysql-community-8.4.5 --namespace=upm-system
```

> **📖 Documentation**: For detailed configuration options and advanced usage, see the [Architecture](#architecture), [Available Packages](#available-packages), and [UPM Package Management Documentation](upm-pkg-mgm.md) sections.

## Architecture

### 🏗️ Component Architecture

```
UPM Packages Framework
├── Container Layer
│   ├── Rocky Linux 9.5 Base Image
│   ├── Supervisord Process Management
│   ├── Non-root User (UID 1001)
│   └── Multi-architecture Support
├── Configuration Layer
│   ├── Go Template Engine
│   ├── Parameter Validation System
│   ├── Dynamic Configuration Generation
│   └── Environment Variable Integration
├── Orchestration Layer
│   ├── Helm Charts with bitnami-common
│   ├── Kubernetes Pod Templates
│   ├── ConfigMaps & Secrets
│   └── Health Monitoring Probes
└── Management Layer
    ├── Unified Package Manager (upm-pkg-mgm.sh)
    ├── CI/CD Automation
    └── Quality Assurance Framework
```

### 🔧 Configuration Management System

The sophisticated template system enables dynamic configuration generation:

**Template Functions:**

- `getenv "VAR_NAME"` - Environment variable access
- `getv "/path/to/param"` - Parameter value access
- `add/mul/atoi` - Mathematical operations
- Custom validation and transformation functions

**Configuration Layers:**

1. **Parameter Definitions** (`*ParametersDetail.json`) - Metadata, validation, bilingual docs
2. **Parameter Values** (`*Value.yaml`) - Production-optimized settings
3. **Configuration Templates** (`*.tpl`) - Dynamic configuration generation
4. **Runtime Config** - Environment-specific rendered configurations

### 🏛️ Standardized Component Structure

Every component follows the same enterprise-grade structure:

```
<component>/<version>/
├── image/                    # Docker build context
│   ├── Dockerfile           # Multi-architecture build
│   ├── service-ctl.sh      # Container management & health monitoring
│   └── supervisord.conf    # Process supervisor configuration
└── charts/                  # Helm chart files
    ├── Chart.yaml          # Chart metadata (version: 1.1.0)
    ├── values.yaml         # Default configuration values
    ├── templates/          # Kubernetes resource templates
    │   ├── configTemplate.yaml  # ConfigMap with configuration templates
    │   ├── configValue.yaml     # Parameter value mappings
    │   ├── parametersDetail.yaml # Parameter definitions
    │   └── podtemplate.yaml     # PodTemplate definitions
    └── files/              # Configuration template files
        ├── *.tpl          # Go template files
        ├── *.json         # Parameter detail files
        └── *.yaml         # Value mapping files
```

### 🧭 Design Decision: Supervisord in all services

All services embed `supervisord` as the process manager for two primary reasons:

1. Process reaping and robust child-process management
   - In containers, PID 1 must properly handle SIGCHLD to reap zombie processes. Running `supervisord` as PID 1 ensures orphaned children are re-parented and reaped, preventing zombie buildup and resource leaks. See Docker’s guidance on using an init process to handle reaping: [Use the init flag](https://docs.docker.com/engine/reference/run/#init).
   - `supervisord` provides fine-grained control of managed processes, including exit status handling and automatic restarts via `autorestart`, `startretries`, and related settings. See Supervisor docs: [Program settings](http://supervisord.org/configuration.html#program-x-section-settings) and [Introduction](http://supervisord.org/introduction.html).

2. Restart service processes without deleting Pods
   - Operators can restart the service process inside the container without recreating the Pod, improving availability and MTTR.
   - Example operations:

```bash
# Check process status
supervisorctl status

# Restart main service process (program name may vary per component)
supervisorctl restart unit_app
```

## Project Status

This project is actively maintained. We follow semantic versioning and aim to keep backward compatibility when feasible.

Recent focus areas:

- Packaging new component versions (e.g., MySQL 8.4.x, PostgreSQL 15.x, Redis 7.x)
- Consistent chart structure and validation across components
- Improved unified management experience via `upm-pkg-mgm.sh`

## Available Packages

### 🗄️ Database Systems

| Component           | Versions                             | Description                                   | Status    |
| ------------------- | ------------------------------------ | --------------------------------------------- | --------- |
| **MySQL Community** | 8.0.41, 8.0.42, 8.4.4, 8.4.5         | Production-ready MySQL with monitoring agents | ✅ Stable |
| **PostgreSQL**      | 15.12, 15.13                         | Advanced PostgreSQL with enterprise features  | ✅ Stable |
| **MongoDB**         | 8.0.15                               | Document-oriented NoSQL database              | ✅ Stable |

### 🔗 Database Proxies & Connection Pooling

| Component        | Versions                             | Description                              | Status    |
| ---------------- | ------------------------------------ | ---------------------------------------- | --------- |
| **MySQL Router** | 8.0.41, 8.0.42, 8.4.4, 8.4.5 | Lightweight MySQL routing middleware             | ✅ Stable |
| **ProxySQL**     | 2.7.2, 2.7.3                         | Advanced MySQL proxy with query caching  | ✅ Stable |
| **PgBouncer**    | 1.23.1, 1.24.1                       | Lightweight PostgreSQL connection pooler | ✅ Stable |

### 🔍 Search & Analytics

| Component         | Versions | Description                               | Status    |
| ----------------- | -------- | ----------------------------------------- | --------- |
| **Elasticsearch** | 7.17.14  | Distributed search and analytics engine   | ✅ Stable |
| **Kibana**        | 7.17.14  | Visualization dashboard for Elasticsearch | ✅ Stable |

### ⚡ In-memory Data Stores

| Component          | Versions       | Description                                                                  | Status    |
| ------------------ | -------------- | ---------------------------------------------------------------------------- | --------- |
| **Redis**          | 7.0.15, 7.0.14 | High-performance in-memory key-value store                                   | ✅ Stable |
| **Redis Sentinel** | 7.0.15, 7.0.14 | High-availability monitoring and automatic failover for Redis                | ✅ Stable |

### 📨 Message Queue

| Component | Versions | Description                          | Status    |
| --------- | -------- | ------------------------------------ | --------- |
| **Kafka** | 3.5.2    | Distributed event streaming platform | ✅ Stable |

### 🔄 Coordination & Distributed Systems

| Component     | Versions | Description                      | Status    |
| ------------- | -------- | -------------------------------- | --------- |
| **ZooKeeper** | 3.8.4    | Distributed coordination service | ✅ Stable |
| **etcd**      | 3.5.18   | Distributed key-value store      | ✅ Stable |

### 🎯 Vector Database & Object Storage

| Component  | Versions            | Description                      | Status    |
| ---------- | ------------------- | -------------------------------- | --------- |
| **Milvus** | 2.6.2               | Vector database for AI/ML        | ✅ Stable |
| **MinIO**  | 20250907161309.0.0  | High-performance object storage  | ✅ Stable |

### 🎯 Supported Targets (for upm-pkg-mgm.sh)

Use hyphenated component names or specific chart names:

- Components: `mysql-community`, `mysql-router-community`, `postgresql`, `proxysql`, `pgbouncer`, `elasticsearch`, `kibana`, `kafka`, `redis`, `redis-sentinel`, `zookeeper`, `etcd`, `milvus`, `minio`, `mongodb`
- Specific chart example: `mysql-community-8.4.5`

Notes:

- You can also use the special target `all` to apply the action to all available packages.

### 📊 Monitoring Agents

| Component                 | Versions | Description                                   | Status    |
| ------------------------- | -------- | --------------------------------------------- | --------- |
| **MySQL Community Agent** | 8.0, 8.4 | MySQL monitoring and metrics collection       | ✅ Stable |
| **PostgreSQL Agent**      | 15       | PostgreSQL monitoring and performance metrics | ✅ Stable |

## Development

### 🏗️ Building Components

```bash
# Build multi-architecture Docker image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t quay.io/upmio/mysql-community:8.4.5 \
  mysql-community/8.4.5/image/

# Validate Helm chart
helm lint mysql-community/8.4.5/charts/

# Test installation locally
helm install --dry-run --debug test-release mysql-community/8.4.5/charts/
```

### 🧪 Quality Assurance

```bash
# Run comprehensive validation
./scripts/validate-charts.sh    # Chart structure and naming
./scripts/lint.sh              # Code quality across all formats
./scripts/test.sh              # Unit and integration tests

# Validate specific component
helm lint mysql-community/8.4.5/charts/
yamllint mysql-community/8.4.5/charts/values.yaml
shellcheck mysql-community/8.4.5/image/service-ctl.sh
```

### 📝 Adding New Components

1. **Create Structure**: Follow the standardized component layout
2. **Implement Templates**: Use Go templates with custom functions
3. **Define Parameters**: Create parameter definitions with validation
4. **Update Management Script**: Add component to `upm-pkg-mgm.sh`
5. **Documentation**: Update component-specific README and CHANGELOG
6. **Testing**: Ensure all validation checks pass

## Security Features

### 🔒 Container Security

- **Non-root Operation**: All containers run as UID 1001
- **Process Isolation**: Supervisord manages application processes
- **Resource Limits**: Configurable CPU and memory constraints
- **Read-only Root**: Minimal attack surface with read-only filesystems

### 🔐 Credential Management

- **Encrypted Passwords**: OpenSSL AES-256-CBC encryption
- **Secure Storage**: Kubernetes Secrets for sensitive data
- **Environment Variables**: Secure injection of runtime credentials
- **Rotation Support**: Built-in password rotation capabilities

### 🛡️ Kubernetes Security

- **Network Policies**: Isolated network communication
- **RBAC Integration**: Role-based access control
- **Pod Security Contexts**: Configured security contexts and capabilities
- **Namespace Isolation**: Dedicated namespace separation

## Monitoring & Operations

### 📊 Health Monitoring

```bash
# Container health checks
service-ctl.sh health              # Overall health status
supervisorctl status               # Process-level status
kubectl get pods -l app=mysql     # Kubernetes pod status

# Log management
kubectl logs -f deployment/mysql  # Live container logs
kubectl exec -it mysql-pod -- tail -f /var/log/mysql/unit_app.out.log
```

### 📈 Metrics Collection

- **MySQL Exporter**: Prometheus metrics on port 9104
- **PostgreSQL Exporter**: Comprehensive database metrics
- **Unit Agent**: Management integration on port 2214
- **Custom Metrics**: Application-specific metrics collection

### 🔄 Maintenance Operations

For comprehensive package management operations, see [UPM Package Management Documentation](upm-pkg-mgm.md).

```bash
# Package lifecycle management
./upm-pkg-mgm.sh upgrade mysql-community-8.4.5
./upm-pkg-mgm.sh uninstall mysql-community-8.4.5
./upm-pkg-mgm.sh status

# Backup and recovery
kubectl exec -it mysql-pod -- mysqldump -u root -p --all-databases > backup.sql
```

## CI/CD Pipeline

### 🚀 Automated Workflows

- **Image Building**: Multi-architecture builds on `image/` changes → `quay.io/upmio/`
- **Chart Publishing**: Automated releases on `charts/` changes → GitHub Pages
- **Quality Assurance**: Comprehensive validation on all PRs
- **Security Scanning**: Vulnerability scanning and compliance checks

### 📦 Artifact Management

- **Container Registry**: `quay.io/upmio/` for all images
- **Helm Repository**: `https://upmio.github.io/upm-packages` for charts
- **Version Management**: Semantic versioning with consistent patterns

## Architecture Deep Dive

### 🎛️ Template System Architecture

The template system provides sophisticated configuration generation:

```
Input Parameters → Template Engine → Generated Configuration
       ↓                    ↓                  ↓
  Parameter Values    Go Templates       Runtime Config Files
  Validation Rules    Custom Functions   Environment-Specific
  Default Values     Dynamic Logic       Optimized Settings
```

### 🏛️ Pod Template Architecture

Standardized pod structure across all components:

```yaml
podtemplate.yaml:
  - Main Application Container
    - Health probes (liveness/readiness)
    - Resource limits/requests
    - Security context
  - Unit Agent Sidecar
    - Management API (port 2214)
    - Health monitoring
  - Metrics Exporter
    - Prometheus endpoints
    - Component-specific metrics
  - Init Containers
    - System configuration
    - Dependency checks
```

### 🔄 Configuration Workflow

1. **Package Installation**: Helm installs chart with ConfigMaps
2. **Pod Initialization**: Init containers prepare environment
3. **Template Rendering**: Go templates generate runtime configuration
4. **Service Start**: Supervisord starts managed processes
5. **Health Monitoring**: Continuous health checks and metrics collection

## Roadmap

- Expand supported components and versions
- Enhance observability defaults across charts
- Deepen integration with UPM operators and controllers
- Improve developer ergonomics for validation and local testing

## Related Projects

- Compose Operator (database replication/topology management that works with UPM components): [upmio/compose-operator](https://github.com/upmio/compose-operator)
- Unit Operator (database and middleware operator with HA, scaling and lifecycle management): [upmio/unit-operator](https://github.com/upmio/unit-operator)

## Community & Support

### 📚 Documentation

- **[UPM Package Management Documentation](upm-pkg-mgm.md)**: Complete guide to the unified package management script
- **[Project Documentation](#overview)**: Comprehensive guides and references
- **[Component Documentation](#available-packages)**: Component-specific setup and configuration
- **[Development Guide](#development)**: Contributing and development workflows
- **[Architecture Guide](#architecture)**: Deep technical documentation

### 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Development environment setup
- Code standards and guidelines
- Pull request process
- Testing requirements
- Security guidelines

### 🆘 Getting Help

- **GitHub Issues**: [Report bugs](https://github.com/upmio/upm-packages/issues) and request features
- **Documentation**: Browse component-specific README files
- **Community**: Join discussions and share experiences
- **Support**: Contact the maintainers for enterprise support

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**🌟 Enterprise-Grade Database & Middleware Deployment Platform**

Built with ❤️ by the UPM team for production workloads

[🔗 Repository](https://github.com/upmio/upm-packages) • [📖 Documentation](#community--support) • [🚀 Get Started](#quick-start)

</div>
