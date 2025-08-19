# PgBouncer Community Edition

PgBouncer Community Edition component for UPM Packages - providing lightweight connection pooler for PostgreSQL databases in Kubernetes environments.

## Overview

This component provides containerized PgBouncer Community Edition as part of the UPM Packages project. PgBouncer is lightweight connection pooler for PostgreSQL databases, reducing connection overhead and improving performance.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration
- **Connection pooling**: Efficient connection management
- **High availability**: Support for multiple PostgreSQL backends

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 1.23.1  | ✅ Stable | 1.29+      | Current stable |
| 1.24.1  | ✅ Latest | 1.29+      | Latest version |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install PgBouncer
./upm-pkg-mgm.sh install pgbouncer

# Install specific version
./upm-pkg-mgm.sh install pgbouncer-1.24.1

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace pgbouncer
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install pgbouncer upm-packages/pgbouncer \
  --namespace pgbouncer \
  --create-namespace

# Install specific version
helm install pgbouncer upm-packages/pgbouncer \
  --version 1.24.1 \
  --namespace pgbouncer \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/pgbouncer
  tag: "1.24.1"

# PostgreSQL backend servers
postgresql:
  hosts:
    - "postgresql-primary:5432"
    - "postgresql-secondary-1:5432"
    - "postgresql-secondary-2:5432"
  database: "app_db"
  username: "app_user"
  password: "app_password"

# PgBouncer settings
pgbouncer:
  port: 6432
  maxClientConnections: 1000
  defaultPoolSize: 20
  minPoolSize: 5
  poolMode: "transaction"
  serverResetQuery: "DISCARD ALL"
  serverLifetime: 3600
  serverIdleTimeout: 600

# Authentication
authType: "md5"
authUser: "pgbouncer"
authQuery: "SELECT usename, passwd FROM pg_shadow WHERE usename=$1"

# Logging
logConnections: "yes"
logDisconnections: "yes"
logPoolerErrors: "yes"

# Stats
statsPeriod: 60
```

### Environment Variables

| Variable              | Default                       | Description             |
| --------------------- | ----------------------------- | ----------------------- |
| `DATA_MOUNT`          | `/var/lib/pgbouncer`          | Data directory          |
| `LOG_MOUNT`           | `/var/log/pgbouncer`          | Log directory           |
| `CONF_DIR`            | `/etc/pgbouncer`              | Configuration directory |
| `PGBOUNCER_AUTH_FILE` | `/etc/pgbouncer/userlist.txt` | Authentication file     |

## Architecture

### Container Structure

```
├── /var/lib/pgbouncer/      # Data directory
├── /var/log/pgbouncer/      # Log directory
├── /etc/pgbouncer/          # Configuration directory
├── /opt/upm/bin/           # UPM utilities
└── /opt/upm/templates/     # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **PgBouncer**: Main connection pooling service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# PgBouncer connectivity
psql -U pgbouncer -h localhost -p 6432 -c "SHOW VERSION;"
```

### Log Files

- `/var/log/pgbouncer/unit_app.out.log` - Application output
- `/var/log/pgbouncer/unit_app.err.log` - Application errors
- `/var/log/pgbouncer/supervisord.log` - Process management logs
- `/var/log/pgbouncer/pgbouncer.log` - PgBouncer service logs

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Secure password management
- Network isolation
- Authentication and authorization

### Best Practices

1. Use network policies to restrict access
2. Implement RBAC for Kubernetes permissions
3. Regular security scanning of images
4. Monitor for suspicious activity
5. Use SSL/TLS for encrypted connections
6. Implement connection limits
7. Regular password rotation
8. Use dedicated service accounts

## Performance Optimization

### Configuration Tuning

```yaml
# Connection pooling optimization
pgbouncer:
  maxClientConnections: 1000
  defaultPoolSize: 20
  minPoolSize: 5
  reservePool: 5
  reservePoolTimeout: 3.0

  # Memory optimization
  maxDbConnections: 100
  maxUserConnections: 100

  # Timeout optimization
  serverLifetime: 3600
  serverIdleTimeout: 600
  clientLoginTimeout: 60
  queryTimeout: 0
```

### Monitoring Metrics

- Active connections
- Pool utilization
- Query throughput
- Response times
- Connection errors
- Pool wait times

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check PgBouncer service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it pgbouncer-pod -- netstat -tlnp

# Check PgBouncer logs
kubectl logs pgbouncer-pod -f
```

**Configuration Errors**

```bash
# Validate configuration
kubectl exec -it pgbouncer-pod -- pgbouncer -R /etc/pgbouncer/pgbouncer.ini -v
```

**Pool Exhaustion**

```bash
# Check pool statistics
psql -U pgbouncer -h localhost -p 6432 -c "SHOW POOLS;"

# Monitor active connections
psql -U pgbouncer -h localhost -p 6432 -c "SHOW CLIENTS;"
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod pgbouncer-pod

# Check PgBouncer memory usage
kubectl exec -it pgbouncer-pod -- ps aux | grep pgbouncer
```

## High Availability

### Backend Configuration

```yaml
# Multiple PostgreSQL backends
postgresql:
  hosts:
    - "postgresql-primary:5432"
    - "postgresql-secondary-1:5432"
    - "postgresql-secondary-2:5432"
  loadBalancing: "round-robin"
  healthCheckInterval: 10
  connectionTimeout: 5

# Failover configuration
failover:
  enabled: true
  automaticFailover: true
  failoverTimeout: 30
  healthCheckCommand: "SELECT 1"
```

### Load Balancing

- Round-robin distribution
- Connection-based load balancing
- Health-based routing
- Automatic failover detection

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t pgbouncer:1.24.1 \
  1.24.1/image/

# Test Helm chart
helm lint 1.24.1/charts/
helm template test-release 1.24.1/charts/
```

### Component Structure

```
pgbouncer/
├── 1.23.1/
│   ├── image/          # Docker build context
│   │   ├── Dockerfile
│   │   ├── service-ctl.sh
│   │   └── supervisord.conf
│   └── charts/        # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── files/
└── 1.24.1/            # Latest version
```

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status pgbouncer
./upm-pkg-mgm.sh upgrade pgbouncer
./upm-pkg-mgm.sh uninstall pgbouncer
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

### External Services

- **Monitoring**: Prometheus, Grafana integration
- **Logging**: ELK stack integration
- **Security**: Security scanning tools
- **PostgreSQL**: Seamless integration with PostgreSQL clusters

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Refer to PgBouncer Community documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
