# Redis Sentinel

Redis Sentinel component for UPM Packages - providing high-availability monitoring, notification, and automatic failover for Redis.

## Overview

This component delivers Redis Sentinel to supervise Redis masters and replicas, perform leader election, and trigger failover when needed. It integrates with UPM Packages charts and images for consistent deployment and operations on Kubernetes.

## Features

- Multi-architecture support: linux/amd64 and linux/arm64
- Helm Chart deployment with bitnami-common helpers
- Dynamic configuration via template system (`kafkaTemplate.tpl`-style equivalents for Redis Sentinel under this package)
- Health checks via `service-ctl.sh`
- Security hardening (non-root user, read-only FS, encrypted credential consumption)
- Simple integration with standalone Redis or replication setups

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 7.0.15  | ✅ Latest | 1.29+      | Current stable |
| 7.0.14  | ✅ Stable | 1.29+      | Previous       |

## Quick Start

### Using UPM Package Manager

```bash
./upm-pkg-mgm.sh list
./upm-pkg-mgm.sh install redis-sentinel        # install latest
./upm-pkg-mgm.sh install redis-sentinel-7.0.15 # install specific version
```

### Using Helm Directly

```bash
helm install redis-sentinel upm-packages/redis-sentinel-7.0.15 \
  --namespace redis \
  --create-namespace
```

## Configuration

### Environment Variables

| Variable                         | Description                                           |
| -------------------------------- | ----------------------------------------------------- |
| `DATA_MOUNT`                     | Data mount root (contains `.init.flag`)               |
| `DATA_DIR`                       | Data directory used by the container                  |
| `CONF_DIR`                       | Config directory used by the container                |
| `LOG_MOUNT`                      | Log directory                                         |
| `SENTINEL_PORT`                  | Redis Sentinel port (default 26379)                   |
| `ADM_USER`                       | Admin user name for password decryption               |
| `SECRET_MOUNT`, `AES_SECRET_KEY` | Required for credential decryption via `decrypt_pwd`  |

> Note: Historically the script used `REDIS_SENTINEL_PORT` (an invalid shell variable name). We standardize on `SENTINEL_PORT`. If legacy environments still export the old name, map it to `SENTINEL_PORT` in the container entrypoint.

## Architecture

### Container Structure

```
redis-sentinel/7.0.15/image/
├── Dockerfile
├── service-ctl.sh
├── sentinelReconfig.sh
└── supervisord.conf

redis-sentinel/7.0.15/charts/
├── Chart.yaml
├── values.yaml
├── files/
│   ├── redisSentinelParametersDetail.json
│   ├── redisSentinelTemplate.tpl
│   └── redisSentinelValue.yaml
└── templates/
    ├── _helpers.tpl
    ├── configTemplate.yaml
    ├── configValue.yaml
    ├── parametersDetail.yaml
    └── podtemplate.yaml
```

### Process Management

- Supervisord manages the Sentinel process lifecycle
- `service-ctl.sh` exposes `initialize`, `health`, and `login` actions
- Structured logs are written to `${LOG_MOUNT}`

### Failover Reconfiguration

- `sentinelReconfig.sh` is configured as Redis Sentinel client reconfiguration script. When a failover occurs and this node acts as the leader, the script updates the replication source to the new master address.
- Arguments passed by Sentinel: `<master-name> <role> <state> <from-ip> <from-port> <to-ip> <to-port>`. The script performs actions only when `role == leader` and uses the `to-ip` as the new master.
- It calls the local unit agent gRPC endpoint to persist the new replication source, ensuring downstream components observe the updated master.
- Key environment variables: `LOG_MOUNT`, `NAMESPACE`, `POD_NAME`, `REDIS_SERVICE_NAME`.

## Monitoring

### Health Checks

```bash
service-ctl.sh health
supervisorctl status
redis-cli -h localhost -p 26379 PING
```

### Log Files

- `${LOG_MOUNT}/unit_app.out.log`
- `${LOG_MOUNT}/unit_app.err.log`
- `${LOG_MOUNT}/supervisord.log`

## Security

- Runs as non-root (UID 1001)
- Read-only root filesystem
- Decrypts administrative credentials using OpenSSL AES-256-CTR via `decrypt_pwd`
- Integrates with external TLS and network policies

## Persistence & Recovery

- If Sentinel state persistence is required, mount a PVC (optional)
- `FORCE_CLEAN` controls initialization cleanup behavior

## Troubleshooting

```bash
# Ping
redis-cli -h ${POD_IP} -p ${SENTINEL_PORT:-26379} PING

# Auth errors
kubectl logs -f deploy/redis-sentinel

# Storage
kubectl exec -it <pod> -- df -h
```

## Development

```bash
# Build image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t quay.io/upmio/redis-sentinel:7.0.15 redis-sentinel/7.0.15/image/

# Lint chart
helm lint redis-sentinel/7.0.15/charts/
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.


