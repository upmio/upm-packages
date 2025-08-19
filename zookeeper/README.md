# ZooKeeper Community Edition

ZooKeeper Community Edition component for UPM Packages - providing distributed coordination service for Kubernetes environments.

## Overview

This component provides containerized Apache ZooKeeper as part of the UPM Packages project. Apache ZooKeeper is an open-source server which enables highly reliable distributed coordination. It is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment with Bitnami common chart dependency
- **Dynamic configuration**: Template-based configuration generation using Go templates
- **Health monitoring**: Built-in health checks and monitoring with service control script
- **Security hardening**: Non-root user operation (UID 1001), secure configuration
- **Data persistence**: Persistent volume support for data and logs
- **Cluster management**: Multi-node ensemble support with automatic configuration
- **High availability**: Leader election and failover mechanisms
- **Metrics export**: Prometheus metrics integration with configurable exporter port
- **Process management**: Supervisord-based process management
- **Resource optimization**: JVM memory management and garbage collection tuning

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 3.8.4   | ✅ Stable | 1.29+      | Current stable |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install ZooKeeper
./upm-pkg-mgm.sh install zookeeper

# Install specific version
./upm-pkg-mgm.sh install zookeeper-3.8.4

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace zookeeper
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install zookeeper upm-packages/zookeeper \
  --namespace zookeeper \
  --create-namespace

# Install specific version
helm install zookeeper upm-packages/zookeeper \
  --version 3.8.4 \
  --namespace zookeeper \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/zookeeper
  tag: "3.8.4"

# ZooKeeper configuration
zookeeper:
  tickTime: 2000
  initLimit: 10
  syncLimit: 5
  autopurgeSnapRetainCount: 30
  autopurgePurgeInterval: 24
  maxClientCnxns: 300
  maxSessionTimeout: 180000
  clientPort: 2181
  serverPort: 2888
  electionPort: 3888
  metricsPort: 7000
  # Additional performance settings
  globalOutstandingLimit: 1000
  snapCount: 100000
  preAllocSize: 67108864
  snapSizeLimitInKb: 4194304

# JVM settings
jvm:
  heapSize: "1g"
  options: |
    -Xms1g
    -Xmx1g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=20
    -XX:InitiatingHeapOccupancyPercent=35
    -XX:+ExplicitGCInvokesConcurrent
    -Djava.awt.headless=true

# Storage
persistence:
  enabled: true
  size: "20Gi"
  storageClass: "standard"

# Resources
resources:
  requests:
    memory: "2Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "1000m"
```

### Environment Variables

| Variable           | Default                 | Description                              |
| ------------------ | ----------------------- | ---------------------------------------- |
| `DATA_MOUNT`       | `/data`                 | Data directory                           |
| `LOG_MOUNT`        | `/log`                  | Log directory                            |
| `ZOO_DATA_DIR`     | `$(DATA_MOUNT)/data`    | ZooKeeper data directory                 |
| `ZOO_DATA_LOG_DIR` | `$(DATA_MOUNT)/dataLog` | ZooKeeper data log directory             |
| `ZOO_LOG_DIR`      | `$(LOG_MOUNT)/logs`     | ZooKeeper log directory                  |
| `ZOOCFGDIR`        | `$(DATA_MOUNT)/conf`    | Configuration directory                  |
| `ZK_MEMORY_LIMIT`  | -                       | JVM memory limit (from container limits) |
| `ZOOKEEPER_PORT`   | `2181`                  | ZooKeeper client port                    |
| `NAMESPACE`        | -                       | Kubernetes namespace                     |
| `SERVICE_NAME`     | -                       | Kubernetes service name                  |
| `UNIT_SN`          | -                       | Unit sequence number for ensemble        |

## Architecture

### Container Structure

```
├── /data/data/               # ZooKeeper data directory
├── /data/dataLog/            # Transaction log directory
├── /log/logs/                # Log directory
├── /data/conf/               # Configuration directory
├── /apache-zookeeper-3.8.4-bin/ # ZooKeeper installation
├── /usr/local/bin/           # UPM utilities (service-ctl.sh)
└── /etc/supervisord.conf     # Process management configuration
```

### Process Management

- **Supervisord**: Process management and monitoring with HTTP interface on port 9001
- **ZooKeeper Server**: Main coordination service running as `QuorumPeerMain`
- **Service Control Script**: Health checks and initialization (`service-ctl.sh`)
- **Health Checks**: Built-in health monitoring with process and port checks
- **Log Rotation**: Automated log management with supervisord
- **Init Container**: Automatic initialization and configuration setup

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status (via HTTP interface)
curl http://localhost:9001

# ZooKeeper health using four-letter commands
echo "ruok" | nc localhost 2181    # Should return "imok"
echo "stat" | nc localhost 2181    # Server statistics
echo "mntr" | nc localhost 2181    # Monitoring metrics
echo "conf" | nc localhost 2181    # Server configuration

# Kubernetes probes
kubectl exec -it zookeeper-pod -- service-ctl.sh health
```

### Log Files

- `/log/unit_app.out.log` - ZooKeeper application output
- `/log/unit_app.err.log` - ZooKeeper application errors
- `/log/supervisord.log` - Process management logs
- `/log/logs/zookeeper.log` - ZooKeeper server logs
- `/log/logs/zookeeper_audit.log` - ZooKeeper audit logs (if enabled)

### Monitoring Metrics

- Server health and status (via `mntr` command)
- Node count and ensemble status
- Request latency and throughput
- Connection count and statistics
- Watcher count and events
- Network traffic metrics
- JVM memory management
- Prometheus metrics exporter (configurable port)
- Four-letter command metrics for debugging

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Network isolation
- SSL/TLS support for encrypted communication
- SASL authentication support
- Secure configuration management
- Zookeeper ensemble security

### Best Practices

1. Use network policies to restrict access
2. Implement RBAC for Kubernetes permissions
3. Regular security scanning of images
4. Monitor for suspicious activity
5. Use SSL/TLS for encrypted communications
6. Implement proper authentication mechanisms
7. Use dedicated service accounts
8. Regular security updates and patches

## Performance Optimization

### Configuration Tuning

```yaml
# JVM optimization
jvm:
  heapSize: "2g"
  options: |
    -Xms2g
    -Xmx2g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=20
    -XX:InitiatingHeapOccupancyPercent=35
    -XX:+ExplicitGCInvokesConcurrent
    -Djava.awt.headless=true

# ZooKeeper performance settings
zookeeper:
  tickTime: 2000
  initLimit: 10
  syncLimit: 5
  maxClientCnxns: 1000
  globalOutstandingLimit: 1000
  snapCount: 100000
  preAllocSize: 67108864
  snapSizeLimitInKb: 4194304
  autopurgePurgeInterval: 24
  autopurgeSnapRetainCount: 30
```

### Monitoring Metrics

- Request latency and throughput
- Connection pool statistics
- Watcher event metrics
- Data size and growth
- Disk I/O performance
- Network traffic analysis
- JVM memory and garbage collection
- Ensemble coordination metrics

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check ZooKeeper service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it zookeeper-pod -- netstat -tlnp

# Check ZooKeeper logs
kubectl logs zookeeper-pod -f
```

**Ensemble Issues**

```bash
# Check ensemble status
echo "stat" | nc localhost 2181

# Check node configuration
echo "conf" | nc localhost 2181

# Monitor leader election
echo "mntr" | nc localhost 2181
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod zookeeper-pod

# Check JVM memory usage
kubectl exec -it zookeeper-pod -- jstat -gc $(jps | grep QuorumPeerMain | awk '{print $1}')
```

**Disk Space Issues**

```bash
# Check disk space
kubectl exec -it zookeeper-pod -- df -h

# Check data directory size
kubectl exec -it zookeeper-pod -- du -sh /data/zookeeper/*
```

**Data Corruption**

```bash
# Check data integrity
kubectl exec -it zookeeper-pod -- zkServer.sh status

# Verify snapshot files
kubectl exec -it zookeeper-pod -- ls -la /data/zookeeper/version-2/

# Check transaction logs
kubectl exec -it zookeeper-pod -- ls -la /data/zookeeper-log/version-2/
```

## High Availability

### Ensemble Configuration

```yaml
# Multi-node ensemble
replicaCount: 3

# ZooKeeper configuration
zookeeper:
  tickTime: 2000
  initLimit: 10
  syncLimit: 5
  ensemble:
    - server.1: "zookeeper-0:2888:3888"
    - server.2: "zookeeper-1:2888:3888"
    - server.3: "zookeeper-2:2888:3888"

# Anti-affinity rules
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - zookeeper
        topologyKey: "kubernetes.io/hostname"
```

### Data Management

- Leader election and failover
- Data replication and consistency
- Snapshot management
- Transaction log management
- Quorum and consensus protocols
- Cluster membership management
- Distributed coordination

## Development

### Local Development

```bash
# Build multi-architecture image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t quay.io/upmio/zookeeper:3.8.4 \
  3.8.4/image/

# Test Helm chart
helm lint 3.8.4/charts/
helm template test-release 3.8.4/charts/

# Test installation locally
helm install --dry-run --debug test-release 3.8.4/charts/

# Package chart for distribution
helm package 3.8.4/charts/
```

### Component Structure

```
zookeeper/
├── README.md                    # Component documentation
├── CHANGELOG.md                 # Version history
└── 3.8.4/
    ├── image/          # Docker build context
    │   ├── Dockerfile          # Multi-architecture container image
    │   ├── service-ctl.sh      # Service control and health script
    │   └── supervisord.conf    # Process management configuration
    └── charts/        # Helm chart
        ├── Chart.yaml           # Chart metadata and dependencies
        ├── values.yaml          # Default configuration values
        ├── README.md            # Chart-specific documentation
        ├── templates/           # Kubernetes resource templates
        │   ├── podtemplate.yaml  # Pod template with init containers
        │   ├── configTemplate.yaml # Configuration template
        │   ├── configValue.yaml   # Configuration values
        │   ├── parametersDetail.yaml # Parameter definitions
        │   └── _helpers.tpl      # Template helpers
        └── files/               # Configuration files
            ├── zookeeperParametersDetail.json # Parameter schema
            ├── zookeeperTemplate.tpl          # ZooKeeper configuration template
            └── zookeeperValue.yaml            # Default parameter values
```

## Integration

### UPM Package Manager Integration

This component integrates seamlessly with the UPM package manager:

```bash
# Component operations
./upm-pkg-mgm.sh status zookeeper
./upm-pkg-mgm.sh upgrade zookeeper
./upm-pkg-mgm.sh uninstall zookeeper
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

### External Services

- **Kafka**: Distributed event streaming
- **Hadoop**: Distributed storage
- **HBase**: Distributed database
- **Solr**: Search platform
- **Storm**: Stream processing
- **Mesos**: Cluster management
- **Monitoring**: Prometheus, Grafana integration
- **Security**: Security scanning tools

## Data Management

### Backup Strategies

```bash
# Create data backup
kubectl exec -it zookeeper-pod -- zkCli.sh -server localhost:2181 get /

# Backup configuration
kubectl exec -it zookeeper-pod -- cat /data/conf/zoo.cfg

# Copy data files
kubectl cp zookeeper-pod:/data/zookeeper/ ./zookeeper-backup/
```

### Data Persistence

- Persistent volume claims for data storage
- Transaction log management
- Snapshot management
- Data consistency guarantees
- Disaster recovery procedures

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Refer to Apache ZooKeeper documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
