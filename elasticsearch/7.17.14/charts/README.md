# Elasticsearch 7.17.14 Helm Chart

This Helm chart deploys Elasticsearch 7.17.14 as part of the UPM Packages project.

## Prerequisites

- Kubernetes 1.29+
- Helm 3.0+
- Sufficient memory and CPU resources
- Persistent storage support

## Installation

```bash
# Install the chart
helm install elasticsearch . --namespace elasticsearch --create-namespace

# Install with custom values
helm install elasticsearch . --namespace elasticsearch --create-namespace -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters of the Elasticsearch chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `quay.io/upmio/elasticsearch` |
| `image.tag` | Image tag | `7.17.14` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.httpPort` | HTTP service port | `9200` |
| `service.transportPort` | Transport service port | `9300` |
| `resources.requests.memory` | Memory request | `2Gi` |
| `resources.requests.cpu` | CPU request | `1000m` |
| `resources.limits.memory` | Memory limit | `4Gi` |
| `resources.limits.cpu` | CPU limit | `2000m` |

## Elasticsearch Configuration

Configure Elasticsearch settings:

```yaml
elasticsearch:
  clusterName: "elasticsearch"
  nodeRoles: ["master", "data", "ingest"]
  discoverySeedHosts: []
  minimumMasterNodes: 1
  httpPort: 9200
  transportPort: 9300
  networkHost: "0.0.0.0"
  discoveryType: "single-node"
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
  tlsEnabled: true
  users:
    elastic: "secure-password"
    kibana_system: "kibana-password"
    remote_monitoring_user: "monitor-password"
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

For multi-node clusters:

```yaml
cluster:
  enabled: true
  replicaCount: 3
  minimumMasterNodes: 2
  discoverySeedHosts: []
  antiAffinity: true
```

## Upgrading

To upgrade the release:

```bash
helm upgrade elasticsearch . --namespace elasticsearch
```

## Uninstalling

To uninstall the chart:

```bash
helm uninstall elasticsearch --namespace elasticsearch
```

## Troubleshooting

### Common Issues

**Cluster formation issues**
- Verify network connectivity between nodes
- Check discovery configuration
- Review cluster logs for errors

**Memory issues**
- Increase JVM heap size
- Monitor garbage collection
- Adjust memory limits

**Disk space issues**
- Increase persistent volume size
- Configure index lifecycle management
- Monitor disk usage

### Logs

Check the logs for troubleshooting:

```bash
kubectl logs -f statefulset/elasticsearch
```

### Health Checks

Check cluster health:

```bash
kubectl exec -it elasticsearch-pod -- curl -u elastic:password http://localhost:9200/_cluster/health
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

- **Elasticsearch Version**: 7.17.14
- **Chart Version**: 1.0.0
- **Kubernetes Version**: 1.29+
- **Helm Version**: 3.0+