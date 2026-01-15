# MongoDB

MongoDB component for UPM Packages - providing a production-ready, containerized document database for Kubernetes environments.

## Overview

This component packages MongoDB Community Server as part of the UPM Packages project. It is designed to work with UPM's unit-operator conventions (template-based config generation, sidecar agent, standardized mounts).

## Features

- **Multi-architecture support**: linux/amd64 and linux/arm64
- **Helm Chart deployment**: Simplified Kubernetes deployment
- **Dynamic configuration**: Template-based configuration generation (`mongodbTemplate.tpl`, `mongodbParametersDetail.json`, `mongodbValue.yaml`)
- **Health monitoring**: Built-in readiness/liveness/startup checks
- **Security hardening**: Non-root user operation, authentication enabled by default
- **Replica set friendly**: Replica set name derived from service group name (`SERVICE_GROUP_NAME`)
- **Sharding roles support**: Supports `configsvr` / `shardsvr` via `ARCH_MODE`

## Version Support

| Version | Status    | Kubernetes | Notes          |
| ------- | --------- | ---------- | -------------- |
| 8.0.15  | ✅ Latest | 1.29+      | Current stable |

## Quick Start

### Using UPM Package Manager

```bash
# List available packages
./upm-pkg-mgm.sh list

# Install MongoDB (latest)
./upm-pkg-mgm.sh install mongodb

# Install specific version
./upm-pkg-mgm.sh install mongodb-8.0.15

# Install with custom namespace
./upm-pkg-mgm.sh install -n mongodb mongodb
```

### Using Helm Directly

```bash
helm install mongodb upm-packages/mongodb-8.0.15 \
  --namespace mongodb \
  --create-namespace
```

## Configuration

### Main Parameters

The chart values primarily define images used by the workload and the sidecar agent:

```yaml
image:
  registry: quay.io
  repository: upmio/mongodb
  tag: "8.0.15"
  pullPolicy: IfNotPresent

agent:
  image:
    registry: quay.io
    repository: upmio/unit-agent
    tag: "v1.1.0"
    pullPolicy: IfNotPresent
```

### MongoDB Tunables

MongoDB runtime configuration is generated from templates and parameter values:

- Template: `8.0.15/charts/files/mongodbTemplate.tpl`
- Default values: `8.0.15/charts/files/mongodbValue.yaml`
- Parameter metadata: `8.0.15/charts/files/mongodbParametersDetail.json`

Common tunables (with default values in `mongodbValue.yaml`):

- `mongodb.max_incoming_connections`
- `mongodb.block_compressor`
- `mongodb.journal_compressor`
- `mongodb.slow_op_threshold_ms`
- `mongodb.cursor_timeout_millis`

## Environment Variables

The PodTemplate wires several environment variables that are used by `service-ctl.sh` and/or the configuration templates.

| Variable | Description |
| --- | --- |
| `DATA_MOUNT` | Data mount root (contains `.init.flag`, `mongod.key`) |
| `LOG_MOUNT` | Log directory (e.g. `mongod.log`, `supervisord.log`) |
| `SECRET_MOUNT` | Secret mount path for encrypted credentials |
| `DATA_DIR` | MongoDB data directory (`${DATA_MOUNT}/data`) |
| `CONF_DIR` | MongoDB config directory (`${DATA_MOUNT}/conf`) |
| `SERVICE_GROUP_NAME` | Used as replica set name and key material |
| `ADM_USER` | Admin username used by `service-ctl.sh` (password decrypted from `SECRET_MOUNT`) |
| `AES_SECRET_KEY` | AES key used to decrypt credentials |
| `ARCH_MODE` | Architecture role (e.g. `configsvr`, `shardsvr`) |
| `MONGODB_MEMORY_LIMIT` | Memory limit (MiB) used to compute WiredTiger cache size |
| `CONFIG_PATH` | Agent-side config path (defaults to `${CONF_DIR}/mongod.conf`) |

## Ports

- Container ports:
  - `27017/TCP`: MongoDB service port
  - `2214/TCP`: unit-agent management port

- Internal ports:
  - `9001/TCP` (loopback): Supervisord HTTP server (used by startup/liveness probes)

## Architecture

### Container Structure

The container follows UPM's standard layout via mounted paths:

```
${DATA_MOUNT}/
├── data/              # MongoDB dbPath
├── conf/              # Generated mongod.conf
├── .init.flag         # Initialization marker
└── mongod.key         # Replica set keyFile

${LOG_MOUNT}/
├── mongod.log
├── supervisord.log
├── unit_app.out.log
└── unit_app.err.log
```

### Component Structure

```
mongodb/
└── 8.0.15/
    ├── charts/
    │   ├── Chart.yaml
    │   ├── values.yaml
    │   ├── files/
    │   │   ├── mongodbParametersDetail.json
    │   │   ├── mongodbTemplate.tpl
    │   │   └── mongodbValue.yaml
    │   └── templates/
    │       ├── _helpers.tpl
    │       ├── configTemplate.yaml
    │       ├── configValue.yaml
    │       ├── parametersDetail.yaml
    │       └── podtemplate.yaml
    └── image/
        ├── Dockerfile
        ├── service-ctl.sh
        └── supervisord.conf
```

## Monitoring

### Health Checks

```bash
# Container-level health check (mongosh ping)
service-ctl.sh health

# Login as admin (interactive mongosh)
service-ctl.sh login

# Supervisord status (inside container)
supervisorctl -s http://127.0.0.1:9001 status
```

### Log Files

- `${LOG_MOUNT}/mongod.log` - MongoDB server log
- `${LOG_MOUNT}/unit_app.out.log` - MongoDB stdout (supervisord managed)
- `${LOG_MOUNT}/unit_app.err.log` - MongoDB stderr (supervisord managed)
- `${LOG_MOUNT}/supervisord.log` - Supervisord log

## Security

- Runs as non-root user (UID/GID 1001)
- `authorization: enabled` by default in generated config
- Keyfile-based internal authentication via `${DATA_MOUNT}/mongod.key`
- Credentials are expected to be encrypted in `SECRET_MOUNT` and decrypted using `AES_SECRET_KEY`

## Troubleshooting

### Readiness Probe Failures

```bash
# Check readiness command output
kubectl exec -it <pod> -c mongodb -- service-ctl.sh health

# Check mongod logs
kubectl exec -it <pod> -c mongodb -- tail -n 200 "${LOG_MOUNT}/mongod.log"
```

### Supervisord Not Ready

```bash
# Probes expect supervisord to listen on 127.0.0.1:9001
kubectl exec -it <pod> -c mongodb -- bash -lc 'ss -lntp | grep 9001 || true'

kubectl exec -it <pod> -c mongodb -- tail -n 200 "${LOG_MOUNT}/supervisord.log"
```

## Development

```bash
# Build image (multi-arch)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t mongodb:8.0.15 \
  8.0.15/image/

# Lint and render chart
helm lint 8.0.15/charts/
helm template test-release 8.0.15/charts/
```

## Support

- Issues: https://github.com/upmio/upm-packages/issues

---

**Note**: This is a component of the UPM Packages project. Refer to the main project documentation for overall architecture and usage guidelines.
