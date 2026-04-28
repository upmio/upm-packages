# ClickHouse Packages Design

Date: 2026-04-28
Source requirement: `docs/specs/2026-04-27-clickhouse-service-type-spec.md`
Repository: `upm-packages`
Target UPM version: 2.0

## Goal

Add ClickHouse as first-class UPM packages in `upm-packages`.

The package version value is `26.3.9.8` for both components:

- `clickhouse/26.3.9.8`
- `clickhouse-keeper/26.3.9.8`

The version string must not include a leading `v` or a release-channel suffix in charts, package inventory, values, docs, or downstream-facing metadata.

## Architecture

The implementation has three delivery units.

### ClickHouse Package

`clickhouse/26.3.9.8` provides the ClickHouse server package:

- server image build context
- Helm chart
- `PodTemplate`
- config template `ConfigMap`
- config value `ConfigMap`
- parameter metadata `ConfigMap`
- package README

The ClickHouse `PodTemplate` contains:

- main container `clickhouse`
- sidecar container `unit-agent`

The sidecar uses the new `quay.io/upmio/clickhouse-agent:26.3` image.

### ClickHouse Keeper Package

`clickhouse-keeper/26.3.9.8` provides the Keeper package:

- Keeper image build context
- Helm chart
- `PodTemplate`
- Keeper config template `ConfigMap`
- config value `ConfigMap`
- parameter metadata `ConfigMap`
- package README

Keeper is a separate UPM component and a separate downstream UnitSet. It is not modeled as an external ZooKeeper dependency and is not embedded in the ClickHouse chart.

### ClickHouse Agent Image

`clickhouse/agent/26.3/image` provides a ClickHouse-specific agent image.

The image is based on the existing `unit-agent` artifact and installs the ClickHouse client and backup/restore tools needed by the approved unit-operator ClickHouse agent contract. This repo does not add a new gRPC protocol or replace `unit-agent` service logic. It only ensures the sidecar runtime has the binaries and environment needed for:

- `LogicalBackup`
- `Restore`
- `SetVariable`

## Package Discovery And Installation

`upm-pkg-mgm.sh` must recognize both components:

- `clickhouse`
- `clickhouse-keeper`

The script should categorize charts matching:

- `clickhouse-*`
- `clickhouse-keeper-*`

Ordering must avoid treating `clickhouse-keeper-*` as a `clickhouse-*` package. List, install, uninstall, upgrade, and status flows should work by component name and by exact chart name.

The top-level README and component READMEs must document:

- ClickHouse version `26.3.9.8`
- ClickHouse Keeper version `26.3.9.8`
- Keeper is provisioned as a separate UnitSet in the same service group
- Keeper is not an external ZooKeeper dependency

## ClickHouse Chart Design

The ClickHouse chart follows the existing package layout:

```text
clickhouse/26.3.9.8/
├── image/
│   ├── Dockerfile
│   ├── service-ctl.sh
│   └── supervisord.conf
└── charts/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── _helpers.tpl
    │   ├── configTemplate.yaml
    │   ├── configValue.yaml
    │   ├── parametersDetail.yaml
    │   └── podtemplate.yaml
    └── files/
        ├── clickhouseTemplate.tpl
        ├── clickhouseValue.yaml
        └── clickhouseParametersDetail.json
```

`Chart.yaml` uses:

- name `clickhouse-26.3.9.8`
- appVersion `26.3.9.8`
- version following existing chart package conventions
- `bitnami-common` dependency, consistent with existing charts

`values.yaml` exposes only package image settings and values needed by the chart itself. Runtime topology values are derived from UnitSet labels, annotations, and environment variables where existing packages already use that pattern.

The `PodTemplate` provides:

- ClickHouse ports for native TCP, HTTP, interserver replication, and metrics if metrics are exposed
- storage and log mount env values from unit-operator annotations
- secret mount env values from unit-operator annotations
- `CONFIG_PATH` for the agent
- resource-derived env values if the template needs memory or CPU tuning
- readiness and liveness checks that fail clearly when ClickHouse cannot answer a local client or HTTP health check

## ClickHouse Configuration

`clickhouseTemplate.tpl` renders deterministic configuration from the UnitSet shape.

It must produce:

- exactly one shard
- exactly two or three replicas
- replica endpoints based on UnitSet service DNS
- replica macros for `shard` and `replica`
- Keeper client endpoints based on the generated Keeper UnitSet service names
- management users/settings required by UPM operations
- backup/restore client configuration entry points without embedding S3 credentials in static config

Replica count is limited to `2` or `3`. Multi-shard topology is not supported.

The template should not require downstream API or UI code to post-process topology. If the UnitSet labels, annotations, or env values are insufficient to render the cluster deterministically, the implementation plan must identify the exact missing value and choose the closest existing unit-operator convention before adding a new one.

## Keeper Chart Design

The Keeper chart follows the same package layout:

```text
clickhouse-keeper/26.3.9.8/
├── image/
│   ├── Dockerfile
│   ├── service-ctl.sh
│   └── supervisord.conf
└── charts/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── _helpers.tpl
    │   ├── configTemplate.yaml
    │   ├── configValue.yaml
    │   ├── parametersDetail.yaml
    │   └── podtemplate.yaml
    └── files/
        ├── clickhouseKeeperTemplate.tpl
        ├── clickhouseKeeperValue.yaml
        └── clickhouseKeeperParametersDetail.json
```

`Chart.yaml` uses:

- name `clickhouse-keeper-26.3.9.8`
- appVersion `26.3.9.8`
- version following existing chart package conventions
- `bitnami-common` dependency

Keeper defaults to three units. Its config template renders:

- deterministic server ID from the unit ordinal
- client listener
- peer and raft listener endpoints
- all ensemble members from UnitSet service DNS

ClickHouse consumes Keeper endpoints. ClickHouse does not reconcile Keeper topology at runtime.

## Parameter Metadata

Both packages use the existing `parametersDetail` pattern.

ClickHouse dynamic parameters use a conservative whitelist. A setting may be marked `dynamic: true` only when it can be applied online through the ClickHouse agent contract. Settings requiring restart, file-only edits, cluster rebuilds, or unsafe replica-wide behavior must not be marked dynamic.

Settings may still exist in default config templates without being dynamic.

Keeper parameter metadata should be minimal. Ensemble identity and peer topology are generated from UnitSet metadata, not presented as user-editable dynamic settings.

## Agent Capability Surface

The ClickHouse package includes a `clickhouse-agent` sidecar image so the existing `unit-agent` contract can execute ClickHouse-specific operations.

The image must contain:

- `/usr/local/bin/unit-agent`
- the standard unit-agent config path used by existing agent images
- ClickHouse client tools
- backup/restore tooling required for S3 logical backup and restore

The `PodTemplate` must expose the environment needed by the agent:

- `UNIT_TYPE`
- `DATA_DIR`
- `CONF_DIR`
- `CONFIG_PATH`
- ClickHouse host and port
- secret mount and AES key values when required by existing secret conventions

Backup and restore errors are reported by the agent contract. S3 credential failure, bucket failure, missing object, incompatible backup data, and command execution failure must all surface as failed operations.

## Runtime Error Handling

Main container startup uses `service-ctl.sh` following existing package conventions:

- validate required env values
- validate mount paths
- create data, log, and config directories
- initialize only when needed
- fail with clear logs when setup cannot continue

Health checks should be local and deterministic:

- ClickHouse readiness uses a local ClickHouse client query or HTTP ping
- Keeper readiness uses its client port or a supported health command
- liveness continues to verify the supervised service process

Configuration errors should be exposed early:

- chart names and app versions are fixed
- replica count is limited to `2` or `3`
- Keeper defaults to `3`
- DNS names are derived from UnitSet metadata rather than hard-coded service instances

## Testing And Validation

Validation should include:

- existing chart lint and validation scripts
- `helm template` render checks for ClickHouse replica count `2`
- `helm template` render checks for ClickHouse replica count `3`
- Keeper render check with default `3` members
- static checks that rendered ClickHouse config contains one shard and the expected number of replicas
- static checks that rendered ClickHouse config points at Keeper endpoints matching the generated Keeper UnitSet service names
- static checks that package inventory and package manager categorization include both components at version `26.3.9.8`
- metadata check that no dynamic parameter requires a restart
- agent image build check that verifies `unit-agent` and ClickHouse client tools are present

Full S3 backup and restore execution requires an integration environment with S3-compatible storage. Local tests should not claim to fully validate those runtime workflows.

## Out Of Scope

This design does not include:

- additional ClickHouse versions
- multi-shard ClickHouse
- external ZooKeeper or external Keeper selection
- Altinity Operator CRDs or controllers
- runtime topology reconciliation
- incremental backup
- point-in-time recovery
- database-level or table-level backup selection
- online changes for settings that require restart
- new unit-agent gRPC protocol or service implementation in this repository

## Acceptance Criteria

- `clickhouse/26.3.9.8` exists and follows existing package layout.
- `clickhouse-keeper/26.3.9.8` exists and follows existing package layout.
- `clickhouse/agent/26.3/image` exists and builds a ClickHouse-specific agent image.
- Both charts use appVersion `26.3.9.8`.
- Package metadata and docs never expose a `v` prefix or release-channel suffix for the UPM version.
- `upm-pkg-mgm.sh list` can categorize both `clickhouse` and `clickhouse-keeper`.
- Installing by component name can select the correct chart group for each component.
- Rendering ClickHouse with two replicas produces one shard and two replicas.
- Rendering ClickHouse with three replicas produces one shard and three replicas.
- Rendering Keeper without an explicit count produces a three-member ensemble.
- ClickHouse config points at the generated Keeper service endpoints.
- Dynamic parameter metadata contains only online-applicable settings.
- Package docs state that Keeper is a separate UnitSet and not an external ZooKeeper dependency.
