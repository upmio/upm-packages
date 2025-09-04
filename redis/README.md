# Redis

Redis component for UPM Packages - providing a high-performance in-memory key-value database for Kubernetes environments.

## Overview

This component provides containerized Redis as part of the UPM Packages project. Redis is an in-memory data store used as a database, cache, message broker, and streaming engine.

## Features

- Multi-architecture support: linux/amd64 and linux/arm64
- Helm Chart deployment with bitnami-common helpers
- Dynamic configuration via template system (`redisTemplate.tpl`, `redisParametersDetail.json`, `redisValue.yaml`)
- Built-in health checks and monitoring integration
- Security hardening (non-root user, secure credentials, read-only FS)
- Data persistence support, AOF/RDB options
- Standalone and replication/cluster friendly

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 7.0.15  | ✅ Latest | 1.29+      | Current stable |
| 7.0.14  | ✅ Stable | 1.29+      | Previous       |

## Quick Start

### Using UPM Package Manager

```bash
./upm-pkg-mgm.sh list
./upm-pkg-mgm.sh install redis        # install latest
./upm-pkg-mgm.sh install redis-7.0.15 # install specific version
```

### Using Helm Directly

```bash
helm install redis upm-packages/redis-7.0.15 \
  --namespace redis \
  --create-namespace
```

## Configuration

### Main Parameters

```yaml
image:
  repository: quay.io/upmio/redis
  tag: "7.0.15"

redis:
  port: 6379
  appendonly: "yes"
  appendfsync: "everysec"
  maxmemory: "" # example: 2gb
  maxmemoryPolicy: noeviction

persistence:
  enabled: true
  size: "8Gi"

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### Environment Variables

| Variable                         | Description                             |
| -------------------------------- | --------------------------------------- |
| `DATA_MOUNT`                     | Data mount root (contains `.init.flag`) |
| `DATA_DIR`                       | Redis data directory                    |
| `CONF_DIR`                       | Redis config directory                  |
| `LOG_MOUNT`                      | Log directory                           |
| `REDIS_PORT`                     | Redis port (default 6379)               |
| `ADM_USER`                       | Admin user name for password decryption |
| `SECRET_MOUNT`, `AES_SECRET_KEY` | Required for credential decryption      |

## Architecture

### Container Structure

```
redis/7.0.15/image/
├── Dockerfile
├── service-ctl.sh
└── supervisord.conf

redis/7.0.15/charts/
├── Chart.yaml
├── values.yaml
├── files/
│   ├── redisParametersDetail.json
│   ├── redisTemplate.tpl
│   └── redisValue.yaml
└── templates/
    ├── _helpers.tpl
    ├── configTemplate.yaml
    ├── configValue.yaml
    ├── parametersDetail.yaml
    └── podtemplate.yaml
```

### Process Management

- Supervisord manages Redis process lifecycle
- `service-ctl.sh` handles initialize, health, login
- Structured logging to `${LOG_MOUNT}`

## Monitoring

### Health Checks

```bash
service-ctl.sh health
supervisorctl status
redis-cli -h localhost -p 6379 ping
```

### Log Files

- `${LOG_MOUNT}/unit_app.out.log`
- `${LOG_MOUNT}/unit_app.err.log`
- `${LOG_MOUNT}/supervisord.log`

## Security

- Runs as non-root (UID 1001)
- Read-only root filesystem
- Encrypted password storage and decryption (OpenSSL AES-256-CTR)
- Optional TLS via external integration

## Persistence & Recovery

- PVC-backed data directories
- RDB snapshots and AOF append-only logging
- Safe initialization with `FORCE_CLEAN` option

## Troubleshooting

```bash
# Ping
redis-cli -h ${POD_NAME} -p ${REDIS_PORT} ping

# Auth errors
kubectl logs -f deploy/redis

# Storage
kubectl exec -it <pod> -- df -h
```

## Development

```bash
# Build image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t quay.io/upmio/redis:7.0.15 redis/7.0.15/image/

# Lint chart
helm lint redis/7.0.15/charts/
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
