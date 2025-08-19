# Kibana Community Edition

Kibana Community Edition component for UPM Packages - providing visualization and exploration capabilities for Elasticsearch data in Kubernetes environments.

## Overview

This component provides containerized Kibana Community Edition as part of the UPM Packages project. Kibana is a free and open user interface that lets you visualize your Elasticsearch data and navigate the Elastic Stack.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration
- **Elasticsearch integration**: Seamless integration with Elasticsearch clusters
- **Visualization tools**: Dashboards, visualizations, and discovery capabilities

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 7.17.14 | ✅ Stable | 1.29+      | Current stable |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install Kibana
./upm-pkg-mgm.sh install kibana

# Install specific version
./upm-pkg-mgm.sh install kibana-7.17.14

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace kibana
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install kibana upm-packages/kibana \
  --namespace kibana \
  --create-namespace

# Install specific version
helm install kibana upm-packages/kibana \
  --version 7.17.14 \
  --namespace kibana \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/kibana
  tag: "7.17.14"

# Elasticsearch connection
elasticsearch:
  hosts:
    - "elasticsearch:9200"
  username: "elastic"
  password: "secure-password"
  sslVerification: true

# Kibana settings
kibana:
  port: 5601
  serverHost: "0.0.0.0"
  maxOldSpaceSize: 1024

# Security
security:
  enabled: true
  tlsEnabled: true

# Resources
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### Environment Variables

| Variable                 | Default           | Description             |
| ------------------------ | ----------------- | ----------------------- |
| `DATA_MOUNT`             | `/var/lib/kibana` | Data directory          |
| `LOG_MOUNT`              | `/var/log/kibana` | Log directory           |
| `CONF_DIR`               | `/etc/kibana`     | Configuration directory |
| `KIBANA_PORT`            | `5601`            | Kibana service port     |
| `ELASTICSEARCH_HOSTS`    | -                 | Elasticsearch hosts     |
| `ELASTICSEARCH_USERNAME` | -                 | Elasticsearch username  |
| `ELASTICSEARCH_PASSWORD` | -                 | Elasticsearch password  |

## Architecture

### Container Structure

```
├── /var/lib/kibana/         # Data directory
├── /var/log/kibana/         # Log directory
├── /etc/kibana/             # Configuration directory
├── /usr/local/kibana/       # Kibana installation
├── /opt/upm/bin/            # UPM utilities
└── /opt/upm/templates/      # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **Kibana Server**: Main visualization service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# Kibana connectivity
curl -u elastic:password http://localhost:5601/api/status
```

### Log Files

- `/var/log/kibana/unit_app.out.log` - Application output
- `/var/log/kibana/unit_app.err.log` - Application errors
- `/var/log/kibana/supervisord.log` - Process management logs
- `/var/log/kibana/kibana.log` - Kibana server logs

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Secure password management with OpenSSL encryption
- Network isolation
- SSL/TLS support for Elasticsearch communication
- Certificate management

### Best Practices

1. Use network policies to restrict access
2. Implement RBAC for Kubernetes permissions
3. Regular security scanning of images
4. Monitor for suspicious activity
5. Use SSL/TLS for encrypted connections
6. Implement proper certificate management
7. Regular password rotation
8. Use dedicated service accounts

## Performance Optimization

### Configuration Tuning

```yaml
# Memory optimization
kibana:
  maxOldSpaceSize: 1024
  nodeOptions: |
    --max-old-space-size=1024
    --unhandled-rejections=warn
    --dns-result-order=ipv4first

# Connection optimization
elasticsearch:
  requestTimeout: 30000
  shardTimeout: 30000
  startupTimeout: 5000

# Logging optimization
logging:
  quiet: false
  silent: false
  verbose: false
```

### Monitoring Metrics

- Memory usage and garbage collection
- Request response times
- Elasticsearch connection health
- User session activity
- Plugin status and performance

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check Kibana service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it kibana-pod -- netstat -tlnp

# Check Kibana logs
kubectl logs kibana-pod -f
```

**Elasticsearch Connection Issues**

```bash
# Test Elasticsearch connectivity
kubectl exec -it kibana-pod -- curl -u elastic:password http://elasticsearch:9200

# Check Elasticsearch logs
kubectl logs elasticsearch-pod -f
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod kibana-pod

# Check Node.js memory usage
kubectl exec -it kibana-pod -- ps aux | grep node
```

**Certificate Issues**

```bash
# Verify certificates
kubectl exec -it kibana-pod -- ls -la /etc/kibana/

# Check certificate validity
kubectl exec -it kibana-pod -- openssl x509 -in /etc/kibana/tls.crt -text -noout
```

## High Availability

### Load Balancing

```yaml
# Multiple Kibana instances
replicaCount: 3

# Load balancer configuration
service:
  type: LoadBalancer
  port: 5601
  annotations: {}

# Session affinity
affinity:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

### Failover Management

- Automatic failover detection
- Load balancing across multiple instances
- Health-based routing
- Graceful degradation

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t kibana:7.17.14 \
  7.17.14/image/

# Test Helm chart
helm lint 7.17.14/charts/
helm template test-release 7.17.14/charts/
```

### Component Structure

```
kibana/
└── 7.17.14/
    ├── image/          # Docker build context
    │   ├── Dockerfile
    │   ├── service-ctl.sh
    │   └── supervisord.conf
    └── charts/        # Helm chart
        ├── Chart.yaml
        ├── values.yaml
        ├── templates/
        └── files/
```

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status kibana
./upm-pkg-mgm.sh upgrade kibana
./upm-pkg-mgm.sh uninstall kibana
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

### External Services

- **Elasticsearch**: Primary data source and backend
- **Monitoring**: Prometheus, Grafana integration
- **Logging**: ELK stack integration
- **Security**: Security scanning tools
- **Load Balancing**: External load balancer support

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Refer to Kibana Community documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
