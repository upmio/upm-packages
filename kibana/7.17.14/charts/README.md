# Kibana 7.17.14 Helm Chart

This Helm chart deploys Kibana 7.17.14 as part of the UPM Packages project.

## Prerequisites

- Kubernetes 1.29+
- Helm 3.0+
- Access to Elasticsearch cluster
- Proper certificates and credentials

## Installation

```bash
# Install the chart
helm install kibana . --namespace kibana --create-namespace

# Install with custom values
helm install kibana . --namespace kibana --create-namespace -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters of the Kibana chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `quay.io/upmio/kibana` |
| `image.tag` | Image tag | `7.17.14` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `5601` |
| `resources.requests.memory` | Memory request | `1Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `resources.limits.cpu` | CPU limit | `1000m` |

## Elasticsearch Configuration

Kibana requires connection to an Elasticsearch cluster:

```yaml
elasticsearch:
  hosts:
    - "elasticsearch:9200"
  username: "elastic"
  password: "secure-password"
  sslVerification: true
```

## Security Configuration

Configure SSL/TLS and authentication:

```yaml
security:
  enabled: true
  tlsEnabled: true
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
  size: "10Gi"
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

## Upgrading

To upgrade the release:

```bash
helm upgrade kibana . --namespace kibana
```

## Uninstalling

To uninstall the chart:

```bash
helm uninstall kibana --namespace kibana
```

## Troubleshooting

### Common Issues

**Kibana cannot connect to Elasticsearch**
- Verify Elasticsearch is running and accessible
- Check credentials and SSL configuration
- Review network policies and service discovery

**Memory issues**
- Increase memory limits in resources configuration
- Monitor JVM memory usage
- Adjust Node.js heap settings

**Certificate errors**
- Verify certificates are properly formatted
- Check certificate expiration dates
- Ensure proper file permissions

### Logs

Check the logs for troubleshooting:

```bash
kubectl logs -f deployment/kibana
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

- **Kibana Version**: 7.17.14
- **Chart Version**: 1.0.0
- **Kubernetes Version**: 1.29+
- **Helm Version**: 3.0+