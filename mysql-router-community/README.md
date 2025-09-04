# MySQL Router Community Edition

MySQL Router Community Edition component for UPM Packages - providing lightweight database routing middleware for Kubernetes environments.

## Overview

This component provides containerized MySQL Router Community Edition as part of the UPM Packages project. MySQL Router is lightweight middleware that provides transparent routing between applications and backend MySQL servers.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 8.0.41  | ✅ Stable | 1.29+      | Legacy support |
| 8.0.42  | ✅ Stable | 1.29+      | Legacy support |
| 8.4.4   | ✅ Stable | 1.29+      | Current stable |
| 8.4.5   | ✅ Latest | 1.29+      | Latest version |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install MySQL Router (component group)
./upm-pkg-mgm.sh install mysql-router-community

# Install specific version
./upm-pkg-mgm.sh install mysql-router-community-8.4.5

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace mysql-router-community
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install mysql-router upm-packages/mysql-router-community \
  --namespace mysql-router \
  --create-namespace

# Install specific version
helm install mysql-router upm-packages/mysql-router-community \
  --version 8.4.5 \
  --namespace mysql-router \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/mysql-router-community
  tag: "8.4.5"

# MySQL backend servers
mysql:
  hosts:
    - "mysql-primary:3306"
    - "mysql-secondary-1:3306"
    - "mysql-secondary-2:3306"
  mode: "read-write"

# Router settings
router:
  port: 6446
  readOnlyPort: 6447
  maxConnections: 1024

# Service discovery (typical with MySQL InnoDB Cluster)
# These values are commonly provided via environment/cluster config
# and used by the container entrypoint for discovery/bootstrap
service:
  groupName: "mycluster" # maps to SERVICE_GROUP_NAME
  mysqlServiceName: "mysql" # maps to MYSQL_SERVICE_NAME
  mysqlPort: 3306 # maps to MYSQL_PORT
```

### Environment Variables

| Variable             | Default                 | Required | Description                                                      |
| -------------------- | ----------------------- | -------- | ---------------------------------------------------------------- |
| `DATA_MOUNT`         | `/var/lib/mysql-router` | ✅       | Data directory (persistent)                                      |
| `LOG_MOUNT`          | `/var/log/mysql-router` | ✅       | Log directory                                                    |
| `CONF_DIR`           | `/etc/mysql-router`     | ✅       | Configuration directory                                          |
| `DATA_DIR`           | `/opt/upm`              | ✅       | Working directory used by templates (runtime/config)             |
| `PROV_USER`          | —                       | ✅       | Provisioning user for cluster operations and HTTP basic auth     |
| `SECRET_MOUNT`       | —                       | ✅       | Directory containing encrypted secret files (see Security)       |
| `AES_SECRET_KEY`     | —                       | ✅       | Key (hex-derived) used to decrypt `${SECRET_MOUNT}/${PROV_USER}` |
| `SERVICE_GROUP_NAME` | —                       | ✅       | Cluster/Group name used by Router and bootstrap                  |
| `MYSQL_SERVICE_NAME` | —                       | ✅       | Headless Service name for MySQL nodes discovery                  |
| `MYSQL_PORT`         | `3306`                  | ✅       | MySQL service port used for discovery/bootstrap                  |
| `HTTP_PORT`          | `8081`                  | ✅       | HTTP management API port                                         |
| `MYSQL_ROUTER_PORT`  | `6446`                  | ❌       | Classic protocol port exposed by Router (template)               |
| `MYSQLX_ROUTER_PORT` | `6447`                  | ❌       | MySQLX protocol port exposed by Router (template)                |

Notes:

- `MYSQL_ROUTER_PORT` and `MYSQLX_ROUTER_PORT` are template configuration keys (used to render routing ports), and are not required environment variables for the container entrypoint.
- The entrypoint strictly validates variables marked Required=✅; if any are missing, it will exit with an error message.

### Ports and Port Variables

- Exposed container ports:
  - 6446: Classic MySQL protocol routing port (maps to chart value router.port). Template variable MYSQL_ROUTER_PORT defaults to 6446.
  - 6447: MySQL X protocol routing port (maps to chart value router.readOnlyPort). Template variable MYSQLX_ROUTER_PORT defaults to 6447.
  - 8081: Router management REST API (controlled by HTTP_PORT, default 8081).
- Related environment variables:
  - MYSQL_ROUTER_PORT: Default 6446; used by the template to render [routing] classic protocol bind_port. Not required by the entrypoint.
  - MYSQLX_ROUTER_PORT: Default 6447; used by the template to render [routing] MySQLX protocol bind_port. Not required by the entrypoint.
  - HTTP_PORT: Default 8081; used by both entrypoint and template to expose the management API.
  - MYSQL_PORT: Default 3306; used to connect to the MySQL metadata service (bootstrap/discovery). Not exposed by the Router.
- Helm values mapping:
  - router.port -> MYSQL_ROUTER_PORT
  - router.readOnlyPort -> MYSQLX_ROUTER_PORT

## Architecture

### Container Structure

```
├── /var/lib/mysql-router/    # Data directory
├── /var/log/mysql-router/    # Log directory
├── /etc/mysql-router/        # Configuration directory
├── /opt/upm/bin/            # UPM utilities
└── /opt/upm/templates/      # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **MySQL Router**: Main routing service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# MySQL Router connectivity (classic)
mysqlsh --mysql -u root -p -h localhost -P 6446 -e "SELECT 1"

# Management API health (HTTP)
curl -u "${PROV_USER}:$(openssl enc -d -aes-256-ctr -in ${SECRET_MOUNT}/${PROV_USER} -K <hex-key> -iv <iv>)" \
  -s "http://127.0.0.1:8081/api/20190715/routes/mysql_rw/health" -w "\n%{http_code}\n"
```

### Log Files

- `/var/log/mysql-router/unit_app.out.log` - Application output
- `/var/log/mysql-router/unit_app.err.log` - Application errors
- `/var/log/mysql-router/supervisord.log` - Process management logs

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Secure password management
- Network isolation

### Best Practices

1. Use network policies to restrict access
2. Implement RBAC for Kubernetes permissions
3. Regular security scanning of images
4. Monitor for suspicious activity

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check MySQL backend connectivity
service-ctl.sh health

# Verify network connectivity
kubectl exec -it mysql-router-pod -- netstat -tlnp
```

**Configuration Errors**

```bash
# Validate configuration
mysqlrouter --config /etc/mysql-router/mysqlrouter.conf --validate
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod mysql-router-pod
```

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t mysql-router-community:8.4.5 \
  8.4.5/image/

# Test Helm chart
helm lint 8.4.5/charts/
helm template test-release 8.4.5/charts/
```

### Component Structure

```
mysql-router-community/
├── 8.0.41/
├── 8.0.42/
├── 8.4.4/
└── 8.4.5/            # Latest version
```

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status mysql-router-community
./upm-pkg-mgm.sh upgrade mysql-router-community
./upm-pkg-mgm.sh uninstall mysql-router-community
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
