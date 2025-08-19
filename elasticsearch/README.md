# Elasticsearch Community Edition

Elasticsearch Community Edition component for UPM Packages - providing distributed search and analytics engine for Kubernetes environments.

## Overview

This component provides containerized Elasticsearch Community Edition as part of the UPM Packages project. Elasticsearch is the distributed search and analytics engine at the heart of the Elastic Stack.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration
- **Data persistence**: Persistent volume support
- **Cluster management**: Multi-node cluster support
- **Plugin system**: Extensible plugin architecture

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 7.17.14 | ✅ Stable | 1.29+      | Current stable |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install Elasticsearch
./upm-pkg-mgm.sh install elasticsearch

# Install specific version
./upm-pkg-mgm.sh install elasticsearch-7.17.14

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace elasticsearch
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install elasticsearch upm-packages/elasticsearch \
  --namespace elasticsearch \
  --create-namespace

# Install specific version
helm install elasticsearch upm-packages/elasticsearch \
  --version 7.17.14 \
  --namespace elasticsearch \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/elasticsearch
  tag: "7.17.14"

# Elasticsearch configuration
elasticsearch:
  clusterName: "elasticsearch"
  nodeRoles: ["master", "data", "ingest"]
  discoverySeedHosts: []
  minimumMasterNodes: 1
  httpPort: 9200
  transportPort: 9300

# JVM settings
jvm:
  heapSize: "1g"
  options: |
    -Xms1g
    -Xmx1g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=20

# Storage
persistence:
  enabled: true
  size: "20Gi"
  storageClass: "standard"

# Security
security:
  enabled: true
  tlsEnabled: true
  users:
    elastic: "secure-password"
    kibana_system: "kibana-password"
    remote_monitoring_user: "monitor-password"

# Resources
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

### Environment Variables

| Variable       | Default                       | Description             |
| -------------- | ----------------------------- | ----------------------- |
| `DATA_MOUNT`   | `/var/lib/elasticsearch`      | Data directory          |
| `LOG_MOUNT`    | `/var/log/elasticsearch`      | Log directory           |
| `CONF_DIR`     | `/etc/elasticsearch`          | Configuration directory |
| `ES_PATH_CONF` | `/etc/elasticsearch`          | Configuration path      |
| `ES_PATH_DATA` | `/var/lib/elasticsearch/data` | Data path               |
| `ES_PATH_LOGS` | `/var/log/elasticsearch`      | Log path                |

## Architecture

### Container Structure

```
├── /var/lib/elasticsearch/     # Data directory
├── /var/log/elasticsearch/     # Log directory
├── /etc/elasticsearch/         # Configuration directory
├── /usr/local/elasticsearch/   # Elasticsearch installation
├── /opt/upm/bin/              # UPM utilities
└── /opt/upm/templates/        # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **Elasticsearch Server**: Main search service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management
- **Metrics Exporter**: Prometheus metrics export

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# Elasticsearch connectivity
curl -u elastic:password http://localhost:9200/_cluster/health
```

### Log Files

- `/var/log/elasticsearch/unit_app.out.log` - Application output
- `/var/log/elasticsearch/unit_app.err.log` - Application errors
- `/var/log/elasticsearch/supervisord.log` - Process management logs
- `/var/log/elasticsearch/elasticsearch.log` - Elasticsearch server logs

### Monitoring Metrics

- Cluster health status
- Node performance metrics
- Index statistics
- JVM memory and garbage collection
- Query performance and latency

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Secure password management with OpenSSL encryption
- Network isolation
- SSL/TLS support
- User authentication and authorization
- Role-based access control
- Audit logging

### Best Practices

1. Use strong passwords and rotate them regularly
2. Enable SSL/TLS for encrypted communications
3. Implement network policies to restrict access
4. Use RBAC for Kubernetes permissions
5. Regular security scanning of images
6. Monitor for suspicious activity
7. Enable Elasticsearch security features
8. Use dedicated service accounts

## Performance Optimization

### Configuration Tuning

```yaml
# JVM optimization
jvm:
  heapSize: "4g"
  options: |
    -Xms4g
    -Xmx4g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=20
    -XX:InitiatingHeapOccupancyPercent=35
    -XX:+ExplicitGCInvokesConcurrent
    -Djava.awt.headless=true

# Elasticsearch settings
elasticsearch:
  indices:
    memory:
      indexBufferSize: "10%"
  threadPool:
    search:
      size: 100
      queueSize: 1000
  network:
    host: "0.0.0.0"

# Index settings
indices:
  query:
    bool:
      maxClauseCount: 4096
  memory:
    indexBufferSize: "10%"
```

### Monitoring Metrics

- Cluster health and status
- Node resource usage
- Index performance metrics
- Query response times
- JVM memory management
- Disk I/O statistics
- Network traffic patterns

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check Elasticsearch service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it elasticsearch-pod -- netstat -tlnp

# Check Elasticsearch logs
kubectl logs elasticsearch-pod -f
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod elasticsearch-pod

# Check JVM memory usage
kubectl exec -it elasticsearch-pod -- curl -u elastic:password http://localhost:9200/_nodes/stats/jvm
```

**Cluster Formation Issues**

```bash
# Check cluster health
kubectl exec -it elasticsearch-pod -- curl -u elastic:password http://localhost:9200/_cluster/health

# Verify node discovery
kubectl exec -it elasticsearch-pod -- curl -u elastic:password http://localhost:9200/_cat/nodes
```

**Storage Issues**

```bash
# Check disk space
kubectl exec -it elasticsearch-pod -- df -h

# Check data directory permissions
kubectl exec -it elasticsearch-pod -- ls -la /var/lib/elasticsearch
```

## High Availability

### Cluster Configuration

```yaml
# Multi-node cluster
replicaCount: 3

# Node roles
elasticsearch:
  nodeRoles: ["master", "data", "ingest"]
  minimumMasterNodes: 2
  discoverySeedHosts: []

# Anti-affinity rules
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - elasticsearch
        topologyKey: "kubernetes.io/hostname"
```

### Data Management

- Index lifecycle management (ILM)
- Snapshot and restore
- Shard allocation awareness
- Cluster routing management
- Data replication and redundancy

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t elasticsearch:7.17.14 \
  7.17.14/image/

# Test Helm chart
helm lint 7.17.14/charts/
helm template test-release 7.17.14/charts/
```

### Component Structure

```
elasticsearch/
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
./upm-pkg-mgm.sh status elasticsearch
./upm-pkg-mgm.sh upgrade elasticsearch
./upm-pkg-mgm.sh uninstall elasticsearch
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

### External Services

- **Kibana**: Visualization and exploration interface
- **Logstash**: Data processing pipeline
- **Beats**: Data shippers
- **Monitoring**: Prometheus, Grafana integration
- **Backup**: External backup tools
- **Security**: Security scanning tools

## Backup and Recovery

### Backup Strategies

```bash
# Create snapshot
service-ctl.sh backup

# Restore from snapshot
service-ctl.sh restore /path/to/snapshot

# Schedule regular backups
# Use Elasticsearch snapshot lifecycle management
```

### Data Persistence

- Persistent volume claims for data storage
- Snapshot and restore procedures
- Point-in-time recovery support
- Cluster replication for disaster recovery

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Refer to Elasticsearch Community documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
