# UPM Package Management Script Documentation

## Overview

The `upm-pkg-mgm.sh` script is a unified management tool for UPM (Unified Platform Management) packages. It provides a comprehensive interface for installing, uninstalling, upgrading, and managing UPM software components in Kubernetes environments.

## Features

- **Unified Management**: Single script for all UPM package operations
- **Multiple Package Types**: Support for MySQL, MySQL Router, PostgreSQL, ProxySQL, PgBouncer, Elasticsearch, Kibana, Kafka, Redis, and Zookeeper
- **Idempotent Operations**: Install/upgrade/uninstall are safe to run repeatedly; installs skip when already deployed and reconcile non-deployed states
- **Flexible Targeting**: Install individual packages, component groups, multiple targets in one command, or all packages
- **Dry Run Mode**: Test operations without making actual changes
- **Remote Charts**: Support for remote Helm repositories
- **Comprehensive Status**: List available packages and monitor installed releases
- **Error Handling**: Robust error handling with graceful degradation
  - Network/transient errors during install are retried up to 3 times with backoff

## Prerequisites

### Required Tools

- **kubectl**: Kubernetes command-line tool
- **helm**: Helm package manager for Kubernetes
- **Kubernetes Cluster**: Accessible Kubernetes cluster

### Optional Tools

- **jq**: JSON processor for enhanced status reporting (optional, with fallback)

## Installation

1. **Download the script**:

   ```bash
   curl -o upm-pkg-mgm.sh https://raw.githubusercontent.com/upmio/upm-packages/main/upm-pkg-mgm.sh
   chmod +x upm-pkg-mgm.sh
   ```

2. **Make it executable**:

   ```bash
   chmod +x upm-pkg-mgm.sh
   ```

3. **Verify prerequisites**:
   ```bash
   ./upm-pkg-mgm.sh list
   ```

## Usage

### Basic Syntax

```bash
./upm-pkg-mgm.sh <ACTION> [OPTIONS] [TARGETS]
```

### Actions

| Action      | Description                                    |
| ----------- | ---------------------------------------------- |
| `install`   | Install packages (default action)              |
| `uninstall` | Uninstall packages                             |
| `upgrade`   | Upgrade installed packages                     |
| `list`      | List available packages and installed releases |
| `status`    | Show status of installed packages              |

### Targets

| Target                   | Description                                         |
| ------------------------ | --------------------------------------------------- |
| `all`                    | All available packages                              |
| `mysql-community`        | MySQL Community Server (all versions)               |
| `mysql-router-community` | MySQL Router Community (all versions)               |
| `postgresql`             | PostgreSQL Server (all versions)                    |
| `proxysql`               | ProxySQL (all versions)                             |
| `pgbouncer`              | PgBouncer (all versions)                            |
| `elasticsearch`          | Elasticsearch                                       |
| `kibana`                 | Kibana                                              |
| `kafka`                  | Kafka                                               |
| `redis`                  | Redis                                               |
| `zookeeper`              | Zookeeper                                           |
| `<chart-name>`           | Specific chart name (e.g., `mysql-community-8.4.5`) |

#### Aliases

You can pass user-friendly aliases. The script normalizes them to canonical component names:

- `mysql` → `mysql-community`
- `mysql-router` → `mysql-router-community`
- `postgres` → `postgresql`
- `elastic` → `elasticsearch`
- `zk` → `zookeeper`

### Options

| Option                  | Short | Description                     | Default        |
| ----------------------- | ----- | ------------------------------- | -------------- |
| `--namespace NAMESPACE` | `-n`  | Kubernetes namespace            | `upm-system`   |
| `--dry-run`             | `-d`  | Perform dry run without changes | `false`        |
| `--timeout TIMEOUT`     | `-t`  | Helm timeout duration           | `300s`         |
| `--prefix PREFIX`       | `-p`  | Release name prefix             | `upm-packages` |
| `--help`                | `-h`  | Show help message               | -              |

## Examples

### Basic Operations

**Show help**:

```bash
./upm-pkg-mgm.sh --help
```

**List available packages**:

```bash
./upm-pkg-mgm.sh list
```

**Check status of installed packages**:

```bash
./upm-pkg-mgm.sh status
```

### Installation Examples

**Install all packages**:

```bash
./upm-pkg-mgm.sh install all
```

**Install MySQL components only**:

```bash
./upm-pkg-mgm.sh install mysql-community mysql-router-community
```

**Install multiple components with aliases in a single command**:

```bash
./upm-pkg-mgm.sh install mysql mysql-router proxysql
# Equivalent to:
# ./upm-pkg-mgm.sh install mysql-community mysql-router-community proxysql
```

**Install specific package**:

```bash
./upm-pkg-mgm.sh install mysql-community-8.4.5
```

**Install Redis components only**:

```bash
./upm-pkg-mgm.sh install redis
```

**Install Zookeeper**:

```bash
./upm-pkg-mgm.sh install zookeeper
```

**Dry run installation**:

```bash
./upm-pkg-mgm.sh install --dry-run mysql-community
```

**Install with custom namespace**:

```bash
./upm-pkg-mgm.sh install -n my-namespace postgresql
```

### Upgrade Examples

**Upgrade all packages**:

```bash
./upm-pkg-mgm.sh upgrade all
```

**Upgrade specific package**:

```bash
./upm-pkg-mgm.sh upgrade mysql-community-8.4.5
```

### Uninstall Examples

**Uninstall specific package**:

```bash
./upm-pkg-mgm.sh uninstall mysql-community-8.4.5
```

**Uninstall multiple packages**:

```bash
./upm-pkg-mgm.sh uninstall mysql-community-8.4.5 postgresql-15.13
```

## Available Packages

### MySQL Community

- `mysql-community-8.0.41`
- `mysql-community-8.0.42`
- `mysql-community-8.4.4`
- `mysql-community-8.4.5`

### MySQL Router Community

- `mysql-router-community-8.0.41`
- `mysql-router-community-8.0.42`
- `mysql-router-community-8.4.4`
- `mysql-router-community-8.4.5`

### PostgreSQL

- `postgresql-15.12`
- `postgresql-15.13`

### ProxySQL

- `proxysql-2.7.2`
- `proxysql-2.7.3`

### PgBouncer

- `pgbouncer-1.23.1`
- `pgbouncer-1.24.1`

### Elasticsearch

- `elasticsearch-7.17.14`

### Kibana

- `kibana-7.17.14`

### Kafka

- `kafka-3.5.2`

### Redis

- `redis-7.0.15`
- `redis-7.0.14`

### Zookeeper

- `zookeeper-3.8.4`

## Configuration

### Default Values

- **Namespace**: `upm-system`
- **Release Prefix**: `upm-packages`
- **Timeout**: `300s`
- **Helm Repository**: `https://upmio.github.io/upm-packages`

### Environment Variables

The script can be configured through environment variables:

```bash
export NAMESPACE="custom-namespace"
export RELEASE_PREFIX="my-prefix"
export HELM_REPO_URL="https://custom-repo.example.com/charts"
./upm-pkg-mgm.sh install mysql-community
```

## Release Naming

Installed releases follow this naming pattern:

```
${RELEASE_PREFIX}-${CHART_NAME}
```

Examples:

- `upm-packages-mysql-community-8.4.5`
- `upm-packages-postgresql-15.13`
- `upm-packages-elasticsearch-7.17.14`

## Error Handling

The script includes comprehensive error handling:

- **Prerequisites Check**: Verifies required tools are installed
- **Package Validation**: Ensures package names are valid
- **Release Existence**: Checks if releases exist before operations
- **Dependency Management**: Handles Helm chart dependencies via remote repository
- **Graceful Degradation**: Falls back to basic functionality when optional tools are missing

### Idempotency Behavior

- Install: If the target Helm release already exists and is deployed, the script skips installation. If it exists but is not deployed, it reconciles using `helm upgrade --install` to converge to the desired state.
- Uninstall: If the release does not exist, it is skipped safely.
- Upgrade: Only proceeds when the release exists; otherwise it is skipped.

### Invalid Target Hints

When an unknown target is provided, the script reports the error and prints the available components and packages so you can choose a valid component (canonical name or supported alias) or a specific chart name. Supported aliases include: `mysql` (→ `mysql-community`), `mysql-router` (→ `mysql-router-community`), `postgres` (→ `postgresql`), `elastic` (→ `elasticsearch`), `zk` (→ `zookeeper`).

## Security Considerations

- **Namespace Isolation**: Uses dedicated namespace for UPM packages
- **Release Naming**: Prevents conflicts with other Helm releases
- **Repository Validation**: Uses official UPM Helm repository
- **Dry Run Mode**: Safe testing before actual deployment

## Troubleshooting

### Common Issues

**Permission Denied**:

```bash
chmod +x upm-pkg-mgm.sh
```

**Helm Repository Not Found**:

```bash
helm repo add upm-packages https://upmio.github.io/upm-packages
helm repo update
```

**Kubernetes Cluster Not Accessible**:

```bash
kubectl cluster-info
```

**Package Not Found**:

```bash
./upm-pkg-mgm.sh list  # Check available packages
```

### Debug Mode

Use dry run mode to debug operations (the script will pass `--debug` to Helm when `--dry-run` is set):

```bash
./upm-pkg-mgm.sh install --dry-run mysql-community-8.4.5
```

## Support

For issues and questions:

- Check the script's help: `./upm-pkg-mgm.sh --help`
- Verify prerequisites: `./upm-pkg-mgm.sh list`
- Use dry run mode for testing: `./upm-pkg-mgm.sh install --dry-run <package>`

## License

This script is part of the UPM packages project and follows the same license terms.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

## Changelog

### Version 1.0

- Initial release
- Support for all UPM package types
- Install, uninstall, upgrade, list, and status operations
- Local and remote chart support
- Comprehensive error handling
