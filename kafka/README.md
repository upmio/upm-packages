# Kafka Community Edition

Kafka Community Edition component for UPM Packages - providing distributed event streaming platform for Kubernetes environments.

## Overview

This component provides containerized Apache Kafka as part of the UPM Packages project. Apache Kafka is an open-source distributed event streaming platform used for high-performance data pipelines, streaming analytics, data integration, and mission-critical applications.

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation
- **Health monitoring**: Built-in health checks and monitoring
- **Security hardening**: Non-root user operation, secure configuration
- **Data persistence**: Persistent volume support
- **Cluster management**: Multi-broker cluster support
- **High throughput**: Optimized for high message throughput

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 3.5.2   | ✅ Stable | 1.29+      | Current stable |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install Kafka
./upm-pkg-mgm.sh install kafka

# Install specific version
./upm-pkg-mgm.sh install kafka-3.5.2

# Install with custom namespace
./upm-pkg-mgm.sh install -n my-namespace kafka
```

### Using Helm Directly

```bash
# Install from UPM Packages repository
helm install kafka upm-packages/kafka \
  --namespace kafka \
  --create-namespace

# Install specific version
helm install kafka upm-packages/kafka \
  --version 3.5.2 \
  --namespace kafka \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
# Basic configuration
image:
  repository: quay.io/upmio/kafka
  tag: "3.5.2"

# Kafka configuration
kafka:
  brokerId: 0
  port: 9092
  internalPort: 9093
  zookeeperConnect: "zookeeper:2181"
  listeners: "PLAINTEXT://:9092,INTERNAL://:9093"
  advertisedListeners: "PLAINTEXT://localhost:9092,INTERNAL://:9093"
  listenerSecurityProtocolMap: "PLAINTEXT:PLAINTEXT,INTERNAL:PLAINTEXT"
  interBrokerListenerName: "INTERNAL"
  logRetentionHours: 168
  logSegmentBytes: 1073741824
  logRetentionBytes: 10737418240
  numPartitions: 1
  defaultReplicationFactor: 1
  offsetsTopicReplicationFactor: 1
  transactionStateLogReplicationFactor: 1

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

| Variable          | Default          | Description             |
| ----------------- |------------------| ----------------------- |
| `DATA_MOUNT`      | `/var/lib/kafka` | Data directory          |
| `LOG_MOUNT`       | `/var/log/kafka` | Log directory           |
| `CONF_DIR`        | `/etc/kafka`     | Configuration directory |
| `KAFKA_PORT`      | `9094`           | Kafka service port      |
| `KAFKA_HEAP_OPTS` | -                | JVM heap options        |
| `KAFKA_BROKER_ID` | `0`              | Broker ID               |

## Architecture

### Container Structure

```
├── /var/lib/kafka/          # Data directory
├── /var/log/kafka/          # Log directory
├── /etc/kafka/              # Configuration directory
├── /usr/local/kafka/        # Kafka installation
├── /opt/upm/bin/            # UPM utilities
└── /opt/upm/templates/      # Configuration templates
```

### Process Management

- **Supervisord**: Process management and monitoring
- **Kafka Broker**: Main message broker service
- **Health Checks**: Built-in health monitoring
- **Log Rotation**: Automated log management

## Monitoring

### Health Checks

```bash
# Container health check
service-ctl.sh health

# Supervisord status
supervisorctl status

# Kafka broker health
kafka-broker-api-versions --bootstrap-server localhost:9092
```

### Log Files

- `/var/log/kafka/unit_app.out.log` - Application output
- `/var/log/kafka/unit_app.err.log` - Application errors
- `/var/log/kafka/supervisord.log` - Process management logs
- `/var/log/kafka/server.log` - Kafka server logs
- `/var/log/kafka/controller.log` - Kafka controller logs

### Monitoring Metrics

- Broker health and status
- Topic and partition metrics
- Producer and consumer metrics
- Network throughput
- Disk I/O statistics
- JVM memory management

## Security

### Security Features

- Non-root user (UID 1001)
- Read-only root filesystem
- Minimal privilege containers
- Network isolation
- SSL/TLS support for encrypted communication
- SASL authentication support
- Zookeeper integration for coordination

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
  heapSize: "4g"
  options: |
    -Xms4g
    -Xmx4g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=20
    -XX:InitiatingHeapOccupancyPercent=35
    -XX:+ExplicitGCInvokesConcurrent
    -Djava.awt.headless=true

# Kafka performance settings
kafka:
  numNetworkThreads: 3
  numIoThreads: 8
  socketSendBufferBytes: 1024000
  socketReceiveBufferBytes: 1024000
  socketRequestMaxBytes: 104857600
  logFlushIntervalMessages: 10000
  logFlushIntervalMs: 1000
  numPartitions: 3
  defaultReplicationFactor: 3

# Topic configuration
topics:
  - name: "example-topic"
    partitions: 3
    replicationFactor: 3
    config:
      retention.ms: "604800000"
      cleanup.policy: "delete"
```

### Monitoring Metrics

- Message throughput rates
- Consumer lag metrics
- Producer performance
- Network bandwidth usage
- Disk I/O performance
- JVM memory and garbage collection
- Broker and partition health

## Troubleshooting

### Common Issues

**Connection Timeout**

```bash
# Check Kafka service status
service-ctl.sh health

# Verify network connectivity
kubectl exec -it kafka-pod -- netstat -tlnp

# Check Kafka logs
kubectl logs kafka-pod -f
```

**Consumer Lag**

```bash
# Check consumer group status
kubectl exec -it kafka-pod -- kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group my-group

# Monitor consumer lag
kubectl exec -it kafka-pod -- kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

**Memory Issues**

```bash
# Monitor resource usage
kubectl top pod kafka-pod

# Check JVM memory usage
kubectl exec -it kafka-pod -- jstat -gc $(jps | grep Kafka | awk '{print $1}')
```

**Disk Space Issues**

```bash
# Check disk space
kubectl exec -it kafka-pod -- df -h

# Check log directory size
kubectl exec -it kafka-pod -- du -sh /var/lib/kafka/*
```

**Zookeeper Connectivity**

```bash
# Test Zookeeper connectivity
kubectl exec -it kafka-pod -- echo "ruok" | nc zookeeper 2181

# Check Zookeeper logs
kubectl logs zookeeper-pod -f
```

## High Availability

### Cluster Configuration

```yaml
# Multi-broker cluster
replicaCount: 3

# Broker configuration
kafka:
  brokerId: 0
  zookeeperConnect: "zookeeper1:2181,zookeeper2:2181,zookeeper3:2181"
  defaultReplicationFactor: 3
  offsetsTopicReplicationFactor: 3
  transactionStateLogReplicationFactor: 3
  minInSyncReplicas: 2

# Anti-affinity rules
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - kafka
        topologyKey: "kubernetes.io/hostname"
```

### Data Management

- Topic replication and partitioning
- Leader election and failover
- Consumer group management
- Message retention policies
- Log compaction and cleanup

## Development

### Local Development

```bash
# Build specific version
docker buildx build --platform linux/amd64,linux/arm64 \
  -t kafka:3.5.2 \
  3.5.2/image/

# Test Helm chart
helm lint 3.5.2/charts/
helm template test-release 3.5.2/charts/
```

### Component Structure

```
kafka/
└── 3.5.2/
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
./upm-pkg-mgm.sh status kafka
./upm-pkg-mgm.sh upgrade kafka
./upm-pkg-mgm.sh uninstall kafka
```

### UPM Templates

Uses UPM's standard template system:

- `getenv "VAR_NAME"` - Environment variables
- `getv "/path/to/param"` - Parameter values
- `add/mul/atoi` - Mathematical operations

### External Services

- **Zookeeper**: Distributed coordination service
- **Schema Registry**: Schema management
- **Kafka Connect**: Data integration
- **Kafka Streams**: Stream processing
- **Monitoring**: Prometheus, Grafana integration
- **Security**: Security scanning tools

## Data Management

### Backup Strategies

```bash
# Create topic backup
kubectl exec -it kafka-pod -- kafka-topics.sh --bootstrap-server localhost:9092 --list

# Backup topic configurations
kubectl exec -it kafka-pod -- kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --describe

# Mirror topics to backup cluster
kubectl exec -it kafka-pod -- kafka-mirror-maker.sh --consumer.config consumer.properties --producer.config producer.properties --whitelist ".*"
```

### Data Persistence

- Persistent volume claims for data storage
- Log retention and cleanup policies
- Topic replication and redundancy
- Disaster recovery procedures

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Contact UPM support team
3. Refer to Apache Kafka documentation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project. Please refer to the main project documentation for overall architecture and usage guidelines.
