# ProxySQL Community Edition

ProxySQL Community Edition component for UPM Packages - providing high-performance MySQL proxy and query caching for Kubernetes environments.

## Overview

This component provides containerized ProxySQL Community Edition as part of the UPM Packages project. ProxySQL is a high-performance MySQL proxy that provides advanced connection pooling, query caching, and load balancing capabilities.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration
- **Query caching**: Advanced query caching and resultset caching
- **Load balancing**: Intelligent MySQL server load balancing
- **Connection pooling**: High-performance connection management

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 2.7.2   | ✅ Stable | 1.29+      | Legacy support |
| 2.7.3   | ✅ Latest | 1.29+      | Latest version |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install ProxySQL
./upm-pkg-mgm.sh install proxysql

# Install specific version
./upm-pkg-mgm.sh install proxysql-2.7.3

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace proxysql
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install proxysql upm-packages/proxysql \
  --namespace proxysql \
  --create-namespace

# Install specific version
helm install proxysql upm-packages/proxysql \
  --version 2.7.3 \
  --namespace proxysql \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Image
image:
  repository: quay.io/upmio/proxysql
  tag: "2.7.3"

# Ports (backed by environment variables in the image/charts)
# ADMIN_PORT   -> admin interface (default 6032)
# PROXYSQL_PORT-> proxy interface (default 6033)
# METRICS_PORT -> REST/metrics (default 6070)
# WEB_PORT     -> web UI (default 6080)
```

Note:
- Backend MySQL servers are configured via ProxySQL admin interface/tables at runtime; this chart does not template `mysql_servers` or hostgroups in values.
- Port values are sourced from environment variables (see Environment Variables section), not Helm values.

### Environment Variables

| Variable        | Default             | Description             |
| --------------- | ------------------- | ----------------------- |
| `DATA_DIR`      | `/var/lib/proxysql` | Data directory          |
| `LOG_MOUNT`     | `/var/log/proxysql` | Log directory           |
| `CONF_DIR`      | `/etc/proxysql`     | Configuration directory |
| `ADMIN_PORT`    | `6032`              | Admin interface port    |
| `PROXYSQL_PORT` | `6033`              | MySQL proxy port        |
| `METRICS_PORT`  | `6070`              | Metrics export port     |
| `WEB_PORT`      | `6080`              | Web interface port      |

## Architecture

### Container Structure

```
├── /var/lib/proxysql/     # Data directory
├── /var/log/proxysql/     # Log directory
├── /etc/proxysql/         # Configuration directory
├── /opt/upm/bin/         # UPM utilities
└── /opt/upm/templates/   # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **ProxySQL**: Main proxy service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# ProxySQL admin interface
mysql -u admin -p -h localhost -P 6032 -e "SELECT * FROM stats_memory_metrics"
```

### Log Files

- `/var/log/proxysql/unit_app.out.log` - Application output
- `/var/log/proxysql/unit_app.err.log` - Application errors
- `/var/log/proxysql/supervisord.log` - Process management logs

### Metrics Export

ProxySQL provides comprehensive metrics through its admin interface:

- **Memory Metrics**: `stats_memory_metrics`
- **Connection Metrics**: `stats_mysql_connection_pool`
- **Query Metrics**: `stats_mysql_query_digest`
- **Command Metrics**: `stats_mysql_commands_counters`

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Secure password management with OpenSSL encryption
- Network isolation
- Admin interface authentication

### Best Practices

1. Use network policies to restrict access to admin interface
2. Implement RBAC for Kubernetes permissions
3. Regular security scanning of images
4. Monitor for suspicious activity
5. Rotate admin credentials regularly

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check ProxySQL health
service-ctl.sh health

# Verify network connectivity
kubectl exec -it proxysql-pod -- netstat -tlnp

# Check admin interface
mysql -u admin -p -h localhost -P 6032 -e "SELECT 1"
```

**Configuration Errors**

```bash
# Validate configuration
proxysql --version

# Check admin interface status
mysql -u admin -p -h localhost -P 6032 -e "SHOW VARIABLES"
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod proxysql-pod

# Check memory metrics
mysql -u admin -p -h localhost -P 6032 -e "SELECT * FROM stats_memory_metrics"
```

## Advanced Features

### Query Caching

ProxySQL provides advanced query caching capabilities:

```sql
-- Enable query caching
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (1, 1, 'SELECT.*', 10, 1);

-- Load rules to runtime
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Load Balancing

Configure intelligent load balancing:

```sql
-- Add MySQL servers
INSERT INTO mysql_servers (hostgroup_id, hostname, port)
VALUES (10, 'mysql-primary', 3306),
       (10, 'mysql-secondary-1', 3306),
       (10, 'mysql-secondary-2', 3306);

-- Configure load balancing
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup)
VALUES (10, 20);

-- Load configuration
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t proxysql:2.7.3 \
  2.7.3/image/

# Test Helm chart
helm lint 2.7.3/charts/
helm template test-release 2.7.3/charts/
```

### Component Structure

```
proxysql/
├── 2.7.2/
│   ├── image/          # Docker build context
│   │   ├── Dockerfile
│   │   ├── service-ctl.sh
│   │   └── supervisord.conf
│   └── charts/        # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── files/
├── 2.7.3/            # Latest version
```

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status proxysql
./upm-pkg-mgm.sh upgrade proxysql
./upm-pkg-mgm.sh uninstall proxysql
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations
- `AESCTRDecrypt` - Password decryption

## Performance Optimization

### Recommended Settings

```yaml
# Production performance tuning
proxy:
  threads: 4
  max_connections: 1000
  default_query_delay: 0
  default_query_timeout: 10000

# Memory optimization
memory:
  stacksize: 1048576
  query_cache_size: 268435456
  session_cache_size: 134217728
```

### Connection Pooling

Optimize connection pooling for high traffic:

```sql
-- Configure connection pool settings
UPDATE global_variables SET variable_value='10000'
WHERE variable_name IN ('mysql-connect_timeout_server', 'mysql-poll_timeout');

-- Apply changes
LOAD MYSQL VARIABLES TO RUNTIME;
```

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Check ProxySQL official documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
