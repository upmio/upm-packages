# PgBouncer 1.24.1 Helm Chart

This Helm chart deploys PgBouncer 1.24.1 as part of the UPM Packages project.

## Prerequisites

- Kubernetes 1.29+
- Helm 3.0+
- Access to PostgreSQL backend databases

## Installation

```bash
# Install from UPM Packages repository
helm install pgbouncer upm-packages/pgbouncer \
  --version 1.24.1 \
  --namespace pgbouncer \
  --create-namespace

# Install with custom values
helm install pgbouncer upm-packages/pgbouncer \
  --version 1.24.1 \
  --namespace pgbouncer \
  --create-namespace \
  -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters of the PgBouncer chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `quay.io/upmio/pgbouncer` |
| `image.tag` | Image tag | `1.24.1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `6432` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `256Mi` |

## PostgreSQL Backend Configuration

Configure PostgreSQL backend servers:

```yaml
postgresql:
  hosts:
    - "postgresql-primary:5432"
    - "postgresql-secondary-1:5432"
    - "postgresql-secondary-2:5432"
  database: "app_db"
  username: "app_user"
  password: "app_password"
```

## PgBouncer Configuration

Configure PgBouncer settings:

```yaml
pgbouncer:
  port: 6432
  maxClientConnections: 1000
  defaultPoolSize: 20
  minPoolSize: 5
  poolMode: "transaction"
  serverResetQuery: "DISCARD ALL"
  serverLifetime: 3600
  serverIdleTimeout: 600
  authType: "md5"
  logConnections: "yes"
  logDisconnections: "yes"
  logPoolerErrors: "yes"
  statsPeriod: 60
```

## Persistence

Enable persistent storage for PgBouncer data:

```yaml
persistence:
  enabled: true
  size: "1Gi"
  storageClass: "standard"
  accessModes:
    - ReadWriteOnce
```

## Security

Configure security settings:

```yaml
securityContext:
  enabled: true
  fsGroup: 1001
  runAsUser: 1001
  runAsGroup: 1001

podSecurityContext:
  fsGroup: 1001
  runAsUser: 1001
  runAsGroup: 1001
```

## Monitoring

Enable monitoring with Prometheus:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    interval: 30s
    scrapeTimeout: 10s
```

## Values

See `values.yaml` for the complete configuration reference.

## Upgrading

```bash
# Upgrade to newer version
helm upgrade pgbouncer upm-packages/pgbouncer \
  --version 1.24.1 \
  --namespace pgbouncer

# Upgrade with new values
helm upgrade pgbouncer upm-packages/pgbouncer \
  --version 1.24.1 \
  --namespace pgbouncer \
  -f new-values.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall pgbouncer --namespace pgbouncer
```

## Contributing

Please refer to the [UPM Packages](https://github.com/upmio/upm-packages) project for contribution guidelines.

## License

This project is licensed under the terms of the MIT License.