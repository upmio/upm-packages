# PostgreSQL Community Edition

PostgreSQL Community Edition component for UPM Packages - providing open-source relational database management system for Kubernetes environments.

## Overview

This component provides containerized PostgreSQL Community Edition as part of the UPM Packages project. PostgreSQL is the world's most advanced open-source relational database system.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration
- **Data persistence**: Persistent volume support

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 15.12   | ✅ Stable | 1.29+      | Current stable |
| 15.13   | ✅ Latest | 1.29+      | Latest version |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install PostgreSQL Community
./upm-pkg-mgm.sh install postgresql

# Install specific version
./upm-pkg-mgm.sh install postgresql-15.13

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace postgresql
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install postgresql upm-packages/postgresql \
  --namespace postgresql \
  --create-namespace

# Install specific version
helm install postgresql upm-packages/postgresql \
  --version 15.13 \
  --namespace postgresql \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/postgresql
  tag: "15.13"

# PostgreSQL configuration
postgresql:
  postgresPassword: "secure-password"
  database: "app_db"
  username: "app_user"
  password: "app_password"
  port: 5432
  maxConnections: 200
  sharedBuffers: "256MB"
  effectiveCacheSize: "1GB"
  maintenanceWorkMem: "64MB"
  checkpointCompletionTarget: 0.9
  walBuffers: "16MB"
  defaultStatisticsTarget: 100
  logMinDurationStatement: 1000
  logCheckpoints: "on"
  logConnections: "on"
  logDisconnections: "on"
  sharedPreloadLibraries: "pg_stat_statements"

# Storage
persistence:
  enabled: true
  size: "20Gi"
  storageClass: "standard"

# Resources
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

# Security
securityContext:
  enabled: true
  fsGroup: 1001
  runAsUser: 1001
  runAsGroup: 1001

# Service
service:
  type: ClusterIP
  port: 5432
  annotations: {}
```

### Environment Variables

| Variable            | Default               | Description                    |
| ------------------- | --------------------- | ------------------------------ |
| `DATA_MOUNT`        | `/var/lib/postgresql` | Data directory                 |
| `LOG_MOUNT`         | `/var/log/postgresql` | Log directory                  |
| `CONF_DIR`          | `/etc/postgresql`     | Configuration directory        |
| `POSTGRES_PASSWORD` | -                     | PostgreSQL password (required) |
| `POSTGRES_DB`       | -                     | Default database name          |
| `POSTGRES_USER`     | -                     | Database user                  |
| `POSTGRES_PASSWORD` | -                     | Database user password         |

## Architecture

### Container Structure

```
├── /var/lib/postgresql/     # Data directory
├── /var/log/postgresql/     # Log directory
├── /etc/postgresql/         # Configuration directory
├── /opt/upm/bin/           # UPM utilities
└── /opt/upm/templates/     # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **PostgreSQL Server**: Main database service
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

# PostgreSQL connectivity
psql -U postgres -h localhost -c "SELECT 1"
```

### Log Files

- `/var/log/postgresql/unit_app.out.log` - Application output
- `/var/log/postgresql/unit_app.err.log` - Application errors
- `/var/log/postgresql/supervisord.log` - Process management logs
- `/var/log/postgresql/postgresql.log` - PostgreSQL server logs

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
7. Enable PostgreSQL audit logging
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
postgresql:
  sharedBuffers: "256MB"
  effectiveCacheSize: "1GB"
  maintenanceWorkMem: "64MB"
  checkpointCompletionTarget: 0.9
  walBuffers: "16MB"
  defaultStatisticsTarget: 100

  # Connection optimization
  maxConnections: 200
  sharedPreloadLibraries: "pg_stat_statements"

  # Logging optimization
  logMinDurationStatement: 1000
  logCheckpoints: "on"
  logConnections: "on"
  logDisconnections: "on"
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
# Check PostgreSQL service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it postgresql-pod -- netstat -tlnp

# Check PostgreSQL logs
kubectl logs postgresql-pod -f
```

**Storage Issues**

```bash
# Check disk space
kubectl exec -it postgresql-pod -- df -h

# Check data directory permissions
kubectl exec -it postgresql-pod -- ls -la /var/lib/postgresql
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod postgresql-pod

# Check PostgreSQL memory usage
kubectl exec -it postgresql-pod -- psql -U postgres -c "SELECT * FROM pg_stat_activity;"
```

## High Availability

### Replication Setup

```yaml
# Streaming replication
replication:
  enabled: true
  mode: "streaming"
  standbyNodes: 2
  synchronousCommit: "on"
  maxWalSenders: 3
  maxReplicationSlots: 3

# Logical replication
replication:
  enabled: true
  mode: "logical"
  publisherNodes: 1
  subscriberNodes: 2
  maxLogicalReplicationWorkers: 4
  maxSyncWorkersPerSubscription: 2

# High availability with automatic failover
replication:
  enabled: true
  mode: "ha"
  primaryNode: 1
  standbyNodes: 2
  automaticFailover: true
  failoverTimeout: 60
  healthCheckInterval: 10
```

### Failover Management

- Automatic failover detection
- Manual failover procedures
- Backup promotion strategies
- Consistency checking

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t postgresql:15.13 \
  15.13/image/

# Test Helm chart
helm lint 15.13/charts/
helm template test-release 15.13/charts/
```

### Component Structure

```
postgresql/
├── agent/              # PostgreSQL Agent - Sidecar container for PostgreSQL operations
│   └── 15/            # PostgreSQL 15 series agent
│       └── image/
│           └── Dockerfile
├── 15.12/
│   ├── image/          # Docker build context
│   │   ├── Dockerfile
│   │   ├── service-ctl.sh
│   │   └── supervisord.conf
│   └── charts/        # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── files/
└── 15.13/            # Latest version
```

### PostgreSQL Agent

The PostgreSQL Community component includes a specialized agent that runs as a sidecar container to provide PostgreSQL-specific operations and monitoring capabilities. The agent is based on `unit-agent` and includes PostgreSQL client tools for database management tasks.

**Agent Features:**

- **Backup and Recovery**: pg_dump and pg_restore integration for logical backups
- **Monitoring**: PostgreSQL performance metrics and health monitoring
- **Maintenance**: Database optimization and maintenance tasks
- **Replication Management**: Replication monitoring and failover support
- **Security**: Security auditing and compliance checking

**Agent Version Compatibility:**

- `agent/15/` - Compatible with PostgreSQL 15.x series

See [agent/README.md](agent/README.md) for detailed agent documentation.

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status postgresql
./upm-pkg-mgm.sh upgrade postgresql
./upm-pkg-mgm.sh uninstall postgresql
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
3. Refer to PostgreSQL Community documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
