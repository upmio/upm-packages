# MySQL Community Edition

MySQL Community Edition component for UPM Packages - providing open-source relational database management system for Kubernetes environments.

## Overview

This directory contains the UPM package for MySQL Community Edition. This is not a standalone Helm chart and is designed to be used with the UPM (Unit Package Manager) system, which manages deployment and configuration through Custom Resource Definitions (CRDs).

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **UPM Package deployment**: Simplified Kubernetes deployment via UPM.
- **Dynamic configuration**: Template-based configuration generation.
- **Health monitoring**: Built-in health checks and monitoring.
- **Security hardening**: Non-root user operation, secure configuration.
- **Data persistence**: Persistent volume support.
- **High availability**: Support for replication and clustering.

## Version Support

| Version | Status | Kubernetes | Notes |
|---------|--------|------------|-------|
| 8.0.40 | ✅ Stable | 1.29+      | Legacy support |
| 8.0.41 | ✅ Stable | 1.29+      | Legacy support |
| 8.0.42 | ✅ Stable | 1.29+      | Legacy support |
| 8.4.4 | ✅ Stable | 1.29+      | Current stable |
| 8.4.5 | ✅ Latest | 1.29+      | Latest version |

## Quick Start

This package is managed by the UPM (Unit Package Manager). To deploy a MySQL instance, you need to have UPM installed and configured in your Kubernetes cluster.

### Using UPM Package Manager

First, ensure the MySQL UPM package is installed in your `upm-system` namespace.

```bash
# Add the upm-packages Helm repo
helm repo add upm-packages https://upmio.github.io/upm-packages
helm repo update

# Install the mysql-community UPM package for a specific version
helm install --namespace=upm-system upm-packages-mysql-community-8.4.5 upm-packages/mysql-community-8.4.5
```

Once the package is installed, you can create `Unit` and `UnitSet` resources to deploy and manage MySQL instances.

## Configuration

Configuration is managed through UPM's `Unit` and `UnitSet` CRDs, not through a `values.yaml` file in a traditional Helm workflow. The available parameters and their default values are defined within the UPM package.

For a detailed list of configurable parameters, please refer to the `mysqlParametersDetail.json` and `mysqlValue.yaml` files located within each version's `charts/files` directory (e.g., `8.4.5/charts/files/`).

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_MOUNT` | `/var/lib/mysql` | Data directory |
| `LOG_MOUNT` | `/var/log/mysql` | Log directory |
| `CONF_DIR` | `/etc/mysql` | Configuration directory |
| `MYSQL_ROOT_PASSWORD` | - | Root password (required) |
| `MYSQL_DATABASE` | - | Default database name |
| `MYSQL_USER` | - | Database user |
| `MYSQL_PASSWORD` | - | Database user password |

## Architecture

### Container Structure

```
├── /var/lib/mysql/          # Data directory
├── /var/log/mysql/          # Log directory
├── /etc/mysql/              # Configuration directory
├── /opt/upm/bin/            # UPM utilities
└── /opt/upm/templates/      # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **MySQL Server**: Main database service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management
- **Backup Management**: Backup and recovery tools

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# MySQL connectivity
mysql -u root -p -h localhost -e "SELECT 1"
```

### Log Files

- `/var/log/mysql/unit_app.out.log` - Application output
- `/var/log/mysql/unit_app.err.log` - Application errors
- `/var/log/mysql/supervisord.log` - Process management logs
- `/var/log/mysql/mysql.log` - MySQL server logs

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Secure password management with OpenSSL encryption
- Network isolation
- SSL/TLS support
- Audit logging

### Best Practices

1. Use strong passwords and rotate them regularly
2. Enable SSL/TLS for encrypted connections
3. Implement network policies to restrict access
4. Use RBAC for Kubernetes permissions
5. Regular security scanning of images
6. Monitor for suspicious activity
7. Enable MySQL audit logging
8. Use dedicated service accounts

## Backup and Recovery

### Backup Strategies

```bash
# Create backup
service-ctl.sh backup

# Restore from backup
service-ctl.sh restore /path/to/backup.sql

# Schedule regular backups
# Use Kubernetes CronJobs for automated backups
```

### Data Persistence

- Persistent volume claims for data storage
- Backup and recovery procedures
- Point-in-time recovery support
- Replication for high availability

## Performance Optimization

### Configuration Tuning

```yaml
# Memory optimization
mysql:
  innodbBufferPoolSize: "1G"
  innodbLogFileSize: "256M"
  maxConnections: 200
  threadCacheSize: 16
  
# Query optimization
  queryCacheSize: "64M"
  queryCacheType: "ON"
  slowQueryLog: "ON"
  longQueryTime: 2
```

### Monitoring Metrics

- Connection counts and usage
- Query performance metrics
- Memory and CPU usage
- Disk I/O statistics
- Replication lag (if configured)

## Troubleshooting

### Common Issues

**Connection Timeout**
```bash
# Check MySQL service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it mysql-pod -- netstat -tlnp

# Check MySQL logs
kubectl logs mysql-pod -f
```

**Storage Issues**
```bash
# Check disk space
kubectl exec -it mysql-pod -- df -h

# Check data directory permissions
kubectl exec -it mysql-pod -- ls -la /var/lib/mysql
```

**Memory Issues**
```bash
# Monitor resource usage
kubectl top pod mysql-pod

# Check MySQL memory usage
kubectl exec -it mysql-pod -- mysql -u root -p -e "SHOW STATUS LIKE 'Memory%';"
```

## High Availability

### Replication Setup

```yaml
# Master-Slave replication
replication:
  enabled: true
  mode: "master-slave"
  slaves: 2
  
# Group Replication (InnoDB Cluster)
replication:
  enabled: true
  mode: "group-replication"
  nodes: 3
```

### Failover Management

- Automatic failover detection
- Manual failover procedures
- Backup promotion strategies
- Consistency checking

## Development

### Local Development

To build the container image for a specific version:

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t upmio/mysql-community:8.4.5 \
  8.4.5/image/
```

To test the UPM package:

```bash
# Lint the UPM package
helm lint 8.4.5/charts/

# Template the UPM package to inspect the output
helm template test-release 8.4.5/charts/
```

### Component Structure

```
mysql-community/
├── agent/              # MySQL Agent - Sidecar container for MySQL operations
│   ├── 8.0/           # MySQL 8.0 series agent
│   │   └── image/
│   │       └── Dockerfile
│   └── 8.4/           # MySQL 8.4 series agent
│       └── image/
│           └── Dockerfile
├── 8.0.40/
│   ├── image/          # Docker build context
│   │   ├── Dockerfile
│   │   ├── service-ctl.sh
│   │   └── supervisord.conf
│   └── charts/        # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── files/
├── 8.0.41/
├── 8.0.42/
├── 8.4.4/
└── 8.4.5/            # Latest version
```

### MySQL Agent

The MySQL Community component includes a specialized agent that runs as a sidecar container to provide MySQL-specific operations and monitoring capabilities. The agent is based on `unit-agent` and includes MySQL operation and maintenance tools for database management tasks.

**Agent Features:**
- **Backup and Recovery**: Percona XtraBackup integration for hot backups
- **Monitoring**: MySQL performance metrics and health monitoring
- **Maintenance**: Database optimization and maintenance tasks
- **Replication Management**: Replication monitoring and failover support
- **Security**: Security auditing and compliance checking

**Agent Version Compatibility:**
- `agent/8.0/` - Compatible with MySQL 8.0.x series
- `agent/8.4/` - Compatible with MySQL 8.4.x series

See [agent/README.md](agent/README.md) for detailed agent documentation.

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status mysql-community
./upm-pkg-mgm.sh upgrade mysql-community
./upm-pkg-mgm.sh uninstall mysql-community
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

### External Services

- **Monitoring**: Prometheus, Grafana integration
- **Logging**: ELK stack integration
- **Backup**: External backup tools
- **Security**: Security scanning tools

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Refer to MySQL Community documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.