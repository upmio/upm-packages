# ZooKeeper 3.8.4 Helm Chart

ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Parameters

The following table lists the configurable parameters of the ZooKeeper chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.registry` | Image registry | `quay.io` |
| `image.repository` | Image repository | `upmio/zookeeper` |
| `image.tag` | Image tag | `3.8.4` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `defaults.tick_time` | The length of a tick in milliseconds | `2000` |
| `defaults.init_limit` | The maximum time, in ticks, that the leader allows the followers to connect and sync | `10` |
| `defaults.sync_limit` | The maximum time, in ticks, that a follower is allowed to be out of sync with the leader | `5` |
| `defaults.autopurge_snap_retain_count` | The number of recent snapshots of the database to retain | `30` |
| `defaults.autopurge_purge_interval` | The time interval in hours for which the purge task has to be triggered | `24` |
| `defaults.max_client_cnxns` | The maximum number of client connections | `300` |
| `defaults.max_session_timeout` | The maximum session timeout in milliseconds that the server will allow the client to negotiate | `180000` |

## Installation

To install the chart with the release name `zookeeper`:

```bash
helm install zookeeper ./zookeeper/3.8.4/charts/
```

## Uninstallation

To uninstall/delete the `zookeeper` deployment:

```bash
helm delete zookeeper
```

## Configuration

The configuration is managed through the `configTemplate.yaml` and `configValue.yaml` ConfigMaps. The template uses Go template functions to generate the configuration dynamically.

### Environment Variables

The following environment variables are used in the configuration template:

- `ZOO_DATA_DIR` - ZooKeeper data directory
- `ZOO_DATA_LOG_DIR` - ZooKeeper data log directory
- `POD_NAME` - Kubernetes pod name
- `NAMESPACE` - Kubernetes namespace
- `SERVICE_NAME` - Kubernetes service name
- `UNIT_SN` - Unit sequence number

### Ports

- `2181` - Client port
- `2888` - Transport port
- `3888` - Leadership election port
- `7000` - Metrics port