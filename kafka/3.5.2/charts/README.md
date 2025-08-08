# Kafka 3.5.2 Helm Chart

This Helm chart deploys Apache Kafka 3.5.2 as part of the UPM Packages project.

## Prerequisites

- Kubernetes 1.29+
- Helm 3.0+
- Zookeeper cluster (external or managed)
- Sufficient memory and CPU resources
- Persistent storage support

## Installation

```bash
# Install the chart
helm install kafka . --namespace kafka --create-namespace

# Install with custom values
helm install kafka . --namespace kafka --create-namespace -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters of the Kafka chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `quay.io/upmio/kafka` |
| `image.tag` | Image tag | `3.5.2` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `9092` |
| `service.internalPort` | Internal service port | `9093` |
| `resources.requests.memory` | Memory request | `2Gi` |
| `resources.requests.cpu` | CPU request | `1000m` |
| `resources.limits.memory` | Memory limit | `4Gi` |
| `resources.limits.cpu` | CPU limit | `2000m` |

## Kafka Configuration

Configure Kafka broker settings:

```yaml
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
```

## JVM Configuration

Configure JVM settings:

```yaml
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
```

## Security Configuration

Configure security features:

```yaml
security:
  enabled: true
  tlsEnabled: false
  saslEnabled: false
  saslMechanism: "PLAIN"
  certificates:
    ca: |
      -----BEGIN CERTIFICATE-----
      # Your CA certificate here
      -----END CERTIFICATE-----
    tls:
      crt: |
        -----BEGIN CERTIFICATE-----
        # Your TLS certificate here
        -----END CERTIFICATE-----
      key: |
        -----BEGIN PRIVATE KEY-----
        # Your private key here
        -----END PRIVATE KEY-----
```

## Persistence

Configure persistent storage:

```yaml
persistence:
  enabled: true
  size: "20Gi"
  storageClass: "standard"
  accessModes:
    - ReadWriteOnce
```

## Zookeeper Configuration

Configure Zookeeper connection:

```yaml
zookeeper:
  enabled: true
  connectString: "zookeeper:2181"
  chroot: "/kafka"
  connectionTimeoutMs: 18000
  sessionTimeoutMs: 18000
  syncTimeMs: 2000
```

## Monitoring

The chart includes monitoring capabilities:

```yaml
monitoring:
  enabled: true
  metrics:
    enabled: true
    port: 9114
  logging:
    enabled: true
    level: "info"
```

## Cluster Configuration

For multi-broker clusters:

```yaml
cluster:
  enabled: true
  replicaCount: 3
  brokerIds: [0, 1, 2]
  minimumBrokerNodes: 2
  antiAffinity: true
```

## Topic Configuration

Pre-configure topics:

```yaml
topics:
  - name: "example-topic"
    partitions: 3
    replicationFactor: 3
    config:
      retention.ms: "604800000"
      cleanup.policy: "delete"
      compression.type: "producer"
```

## Upgrading

To upgrade the release:

```bash
helm upgrade kafka . --namespace kafka
```

## Uninstalling

To uninstall the chart:

```bash
helm uninstall kafka --namespace kafka
```

## Troubleshooting

### Common Issues

**Broker cannot connect to Zookeeper**
- Verify Zookeeper is running and accessible
- Check connection string and network policies
- Review Zookeeper logs for errors

**Consumer lag issues**
- Monitor consumer group status
- Check consumer configuration
- Review broker performance metrics

**Memory issues**
- Increase JVM heap size
- Monitor garbage collection
- Adjust memory limits

**Disk space issues**
- Increase persistent volume size
- Configure log retention policies
- Monitor disk usage

### Logs

Check the logs for troubleshooting:

```bash
kubectl logs -f statefulset/kafka
```

### Health Checks

Check broker health:

```bash
kubectl exec -it kafka-pod -- kafka-broker-api-versions --bootstrap-server localhost:9092
```

### Topic Management

List topics:

```bash
kubectl exec -it kafka-pod -- kafka-topics.sh --bootstrap-server localhost:9092 --list
```

Describe consumer groups:

```bash
kubectl exec -it kafka-pod -- kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group my-group
```

## Development

### Local Testing

```bash
# Lint the chart
helm lint .

# Template the chart
helm template test-release .

# Test installation
helm install test-release . --namespace test --create-namespace
```

### Values Schema

The chart supports a comprehensive set of values for configuration. Refer to `values.yaml` for the complete schema.

## Support

For support, please refer to the main [UPM Packages documentation](https://github.com/upmio/upm-packages).

## Version Information

- **Kafka Version**: 3.5.2
- **Chart Version**: 1.0.0
- **Kubernetes Version**: 1.29+
- **Helm Version**: 3.0+