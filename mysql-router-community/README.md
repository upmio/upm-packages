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

| Version | Status | Kubernetes | Notes |
|---------|--------|------------|-------|
| 8.0.40 | ✅ Stable | 1.29+      | Legacy support |
| 8.0.41 | ✅ Stable | 1.29+      | Legacy support |
| 8.0.42 | ✅ Stable | 1.29+      | Legacy support |
| 8.4.4 | ✅ Stable | 1.29+      | Current stable |
| 8.4.5 | ✅ Latest | 1.29+      | Latest version |

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
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_MOUNT` | `/var/lib/mysql-router` | Data directory |
| `LOG_MOUNT` | `/var/log/mysql-router` | Log directory |
| `CONF_DIR` | `/etc/mysql-router` | Configuration directory |

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

# MySQL Router connectivity
mysqlsh --mysql -u root -p -h localhost -P 6446 -e "SELECT 1"
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