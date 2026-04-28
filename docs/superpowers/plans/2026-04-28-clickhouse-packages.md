# ClickHouse Packages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add UPM packages for `clickhouse/26.3.9.8`, `clickhouse-keeper/26.3.9.8`, and the ClickHouse agent image needed by the unit-agent ClickHouse contract.

**Architecture:** Implement ClickHouse and ClickHouse Keeper as separate package directories that match existing `upm-packages` conventions. ClickHouse gets a sidecar using `quay.io/upmio/clickhouse-agent:26.3`; Keeper is a separate UnitSet package and is referenced from ClickHouse config by service name.

**Tech Stack:** Helm v3 charts, Kubernetes `PodTemplate`, Go text templates used by UPM config rendering, Bash service scripts, Rocky Linux container images, ClickHouse official RPM packages, existing `unit-agent`.

---

## File Structure

Create these files:

- `scripts/validate-clickhouse-packages.sh`: focused validation script for new ClickHouse package files, package manager registration, metadata, docs, and rendered manifests.
- `clickhouse/README.md`: component documentation for ClickHouse package behavior.
- `clickhouse/26.3.9.8/image/Dockerfile`: ClickHouse server image.
- `clickhouse/26.3.9.8/image/service-ctl.sh`: ClickHouse container initialization, login, and health entrypoint.
- `clickhouse/26.3.9.8/image/supervisord.conf`: supervisord config for `clickhouse-server`.
- `clickhouse/26.3.9.8/charts/Chart.yaml`: ClickHouse chart metadata.
- `clickhouse/26.3.9.8/charts/values.yaml`: ClickHouse chart image values.
- `clickhouse/26.3.9.8/charts/templates/_helpers.tpl`: image helper templates.
- `clickhouse/26.3.9.8/charts/templates/configTemplate.yaml`: config template `ConfigMap`.
- `clickhouse/26.3.9.8/charts/templates/configValue.yaml`: config value `ConfigMap`.
- `clickhouse/26.3.9.8/charts/templates/parametersDetail.yaml`: parameter metadata `ConfigMap`.
- `clickhouse/26.3.9.8/charts/templates/podtemplate.yaml`: ClickHouse server and agent `PodTemplate`.
- `clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl`: ClickHouse XML configuration template.
- `clickhouse/26.3.9.8/charts/files/clickhouseValue.yaml`: ClickHouse default parameter values.
- `clickhouse/26.3.9.8/charts/files/clickhouseParametersDetail.json`: dynamic parameter metadata.
- `clickhouse/26.3.9.8/charts/README.md`: chart-level README.
- `clickhouse/agent/26.3/image/Dockerfile`: ClickHouse unit-agent sidecar image.
- `clickhouse/agent/26.3/image/README.md`: agent image notes.
- `clickhouse-keeper/README.md`: component documentation for Keeper package behavior.
- `clickhouse-keeper/26.3.9.8/image/Dockerfile`: Keeper server image.
- `clickhouse-keeper/26.3.9.8/image/service-ctl.sh`: Keeper container initialization, login, and health entrypoint.
- `clickhouse-keeper/26.3.9.8/image/supervisord.conf`: supervisord config for `clickhouse-keeper`.
- `clickhouse-keeper/26.3.9.8/charts/Chart.yaml`: Keeper chart metadata.
- `clickhouse-keeper/26.3.9.8/charts/values.yaml`: Keeper chart image values.
- `clickhouse-keeper/26.3.9.8/charts/templates/_helpers.tpl`: image helper templates.
- `clickhouse-keeper/26.3.9.8/charts/templates/configTemplate.yaml`: Keeper config template `ConfigMap`.
- `clickhouse-keeper/26.3.9.8/charts/templates/configValue.yaml`: Keeper config value `ConfigMap`.
- `clickhouse-keeper/26.3.9.8/charts/templates/parametersDetail.yaml`: Keeper metadata `ConfigMap`.
- `clickhouse-keeper/26.3.9.8/charts/templates/podtemplate.yaml`: Keeper `PodTemplate`.
- `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl`: Keeper XML configuration template.
- `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperValue.yaml`: Keeper default parameter values.
- `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperParametersDetail.json`: Keeper parameter metadata.
- `clickhouse-keeper/26.3.9.8/charts/README.md`: chart-level README.

Modify these files:

- `upm-pkg-mgm.sh`: add ClickHouse and Keeper component categorization and display text.
- `README.md`: add ClickHouse and ClickHouse Keeper to available package tables.

Keep these source references open during implementation:

- `docs/superpowers/specs/2026-04-28-clickhouse-packages-design.md`
- `docs/specs/2026-04-27-clickhouse-service-type-spec.md`
- `postgresql/15.13/charts/templates/podtemplate.yaml`
- `kafka/3.5.2/charts/files/kafkaTemplate.tpl`
- `zookeeper/3.8.4/charts/files/zookeeperTemplate.tpl`
- `etcd/3.5.18/charts/files/etcdTemplate.tpl`
- `postgresql/agent/15/image/Dockerfile`

## Task 1: Add ClickHouse Package Validation Script

**Files:**
- Create: `scripts/validate-clickhouse-packages.sh`

- [ ] **Step 1: Write the failing validation script**

Create `scripts/validate-clickhouse-packages.sh` with this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

pass() {
  echo "[PASS] $*"
}

require_file() {
  local path="$1"
  [[ -f "${ROOT_DIR}/${path}" ]] || fail "missing file: ${path}"
}

require_dir() {
  local path="$1"
  [[ -d "${ROOT_DIR}/${path}" ]] || fail "missing directory: ${path}"
}

require_grep() {
  local pattern="$1"
  local path="$2"
  if ! grep -Eq "$pattern" "${ROOT_DIR}/${path}"; then
    fail "pattern not found in ${path}: ${pattern}"
  fi
}

validate_manager() {
  require_grep 'local clickhouse=""' upm-pkg-mgm.sh
  require_grep 'local clickhouse_keeper=""' upm-pkg-mgm.sh
  require_grep 'clickhouse-keeper-\*' upm-pkg-mgm.sh
  require_grep 'clickhouse-\*' upm-pkg-mgm.sh
  require_grep 'clickhouse: ClickHouse' upm-pkg-mgm.sh
  require_grep 'clickhouse-keeper: ClickHouse Keeper' upm-pkg-mgm.sh
  pass "package manager contains ClickHouse component groups"
}

validate_structure() {
  local paths=(
    clickhouse/README.md
    clickhouse/26.3.9.8/image/Dockerfile
    clickhouse/26.3.9.8/image/service-ctl.sh
    clickhouse/26.3.9.8/image/supervisord.conf
    clickhouse/26.3.9.8/charts/Chart.yaml
    clickhouse/26.3.9.8/charts/values.yaml
    clickhouse/26.3.9.8/charts/templates/_helpers.tpl
    clickhouse/26.3.9.8/charts/templates/configTemplate.yaml
    clickhouse/26.3.9.8/charts/templates/configValue.yaml
    clickhouse/26.3.9.8/charts/templates/parametersDetail.yaml
    clickhouse/26.3.9.8/charts/templates/podtemplate.yaml
    clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl
    clickhouse/26.3.9.8/charts/files/clickhouseValue.yaml
    clickhouse/26.3.9.8/charts/files/clickhouseParametersDetail.json
    clickhouse/26.3.9.8/charts/README.md
    clickhouse/agent/26.3/image/Dockerfile
    clickhouse/agent/26.3/image/README.md
    clickhouse-keeper/README.md
    clickhouse-keeper/26.3.9.8/image/Dockerfile
    clickhouse-keeper/26.3.9.8/image/service-ctl.sh
    clickhouse-keeper/26.3.9.8/image/supervisord.conf
    clickhouse-keeper/26.3.9.8/charts/Chart.yaml
    clickhouse-keeper/26.3.9.8/charts/values.yaml
    clickhouse-keeper/26.3.9.8/charts/templates/_helpers.tpl
    clickhouse-keeper/26.3.9.8/charts/templates/configTemplate.yaml
    clickhouse-keeper/26.3.9.8/charts/templates/configValue.yaml
    clickhouse-keeper/26.3.9.8/charts/templates/parametersDetail.yaml
    clickhouse-keeper/26.3.9.8/charts/templates/podtemplate.yaml
    clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl
    clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperValue.yaml
    clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperParametersDetail.json
    clickhouse-keeper/26.3.9.8/charts/README.md
  )
  for path in "${paths[@]}"; do
    require_file "$path"
  done
  require_dir clickhouse/26.3.9.8/charts/templates
  require_dir clickhouse-keeper/26.3.9.8/charts/templates
  pass "ClickHouse package structure exists"
}

validate_versions() {
  require_grep '^name:[[:space:]]*clickhouse-26\.3\.9\.8$' clickhouse/26.3.9.8/charts/Chart.yaml
  require_grep '^appVersion:[[:space:]]*"?26\.3\.9\.8"?$' clickhouse/26.3.9.8/charts/Chart.yaml
  require_grep '^name:[[:space:]]*clickhouse-keeper-26\.3\.9\.8$' clickhouse-keeper/26.3.9.8/charts/Chart.yaml
  require_grep '^appVersion:[[:space:]]*"?26\.3\.9\.8"?$' clickhouse-keeper/26.3.9.8/charts/Chart.yaml
  if grep -RInE 'v26\.3\.9\.8|26\.3\.9\.8-(lts|stable|testing|prestable)' "${ROOT_DIR}/clickhouse" "${ROOT_DIR}/clickhouse-keeper"; then
    fail "invalid ClickHouse UPM version string found"
  fi
  pass "ClickHouse chart versions are exact"
}

validate_metadata() {
  python3 - <<'PY' "${ROOT_DIR}"
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for rel in [
    "clickhouse/26.3.9.8/charts/files/clickhouseParametersDetail.json",
    "clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperParametersDetail.json",
]:
    data = json.loads((root / rel).read_text())
    if not isinstance(data, list):
        raise SystemExit(f"{rel} must contain a JSON list")
    for item in data:
        for key in ["key", "scope", "section", "type", "dynamic", "default", "desc_en", "desc_zh"]:
            if key not in item:
                raise SystemExit(f"{rel} entry missing {key}: {item}")
        if item["dynamic"] is True and item["key"] not in {
            "max_threads",
            "max_memory_usage",
            "max_execution_time",
            "log_queries",
            "max_concurrent_queries",
        }:
            raise SystemExit(f"{rel} contains unapproved dynamic setting: {item['key']}")
PY
  pass "parameter metadata is valid"
}

validate_templates() {
  require_grep '<remote_servers>' clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl
  require_grep '<macros>' clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl
  require_grep 'CLICKHOUSE_KEEPER_SERVICE_NAME' clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl
  require_grep 'UNIT_COUNT' clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl
  require_grep '<keeper_server>' clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl
  require_grep '<raft_configuration>' clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl
  require_grep 'UNIT_COUNT' clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl
  pass "configuration templates contain topology sections"
}

validate_docs() {
  require_grep 'ClickHouse' README.md
  require_grep '26\.3\.9\.8' README.md
  require_grep 'separate UnitSet' clickhouse/README.md
  require_grep 'not an external ZooKeeper dependency' clickhouse/README.md
  require_grep 'separate UnitSet' clickhouse-keeper/README.md
  pass "documentation mentions ClickHouse package scope"
}

validate_agent() {
  require_grep 'FROM quay\.io/upmio/unit-agent:' clickhouse/agent/26.3/image/Dockerfile
  require_grep 'clickhouse-client-26\.3\.9\.8' clickhouse/agent/26.3/image/Dockerfile
  require_grep 'CMD \["unit-agent","daemon","-f","/opt/unit-agent/config.toml"\]' clickhouse/agent/26.3/image/Dockerfile
  pass "ClickHouse agent image Dockerfile contains unit-agent and client"
}

validate_helm() {
  command -v helm >/dev/null 2>&1 || fail "helm command is required"
  helm lint "${ROOT_DIR}/clickhouse/26.3.9.8/charts" >/tmp/clickhouse-helm-lint.out
  helm lint "${ROOT_DIR}/clickhouse-keeper/26.3.9.8/charts" >/tmp/clickhouse-keeper-helm-lint.out
  helm template test-clickhouse "${ROOT_DIR}/clickhouse/26.3.9.8/charts" >/tmp/clickhouse-render.yaml
  helm template test-clickhouse-keeper "${ROOT_DIR}/clickhouse-keeper/26.3.9.8/charts" >/tmp/clickhouse-keeper-render.yaml
  grep -q 'name: clickhouse-26.3.9.8' /tmp/clickhouse-render.yaml || fail "ClickHouse chart did not render expected PodTemplate name"
  grep -q 'name: clickhouse-keeper-26.3.9.8' /tmp/clickhouse-keeper-render.yaml || fail "Keeper chart did not render expected PodTemplate name"
  pass "helm lint and template succeeded"
}

case "${1:-all}" in
  manager) validate_manager ;;
  structure) validate_structure ;;
  versions) validate_versions ;;
  metadata) validate_metadata ;;
  templates) validate_templates ;;
  docs) validate_docs ;;
  agent) validate_agent ;;
  helm) validate_helm ;;
  all)
    validate_manager
    validate_structure
    validate_versions
    validate_metadata
    validate_templates
    validate_docs
    validate_agent
    validate_helm
    ;;
  *)
    echo "usage: $0 [manager|structure|versions|metadata|templates|docs|agent|helm|all]" >&2
    exit 2
    ;;
esac
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x scripts/validate-clickhouse-packages.sh
```

Expected: no output.

- [ ] **Step 3: Run it to verify the first check fails**

Run:

```bash
scripts/validate-clickhouse-packages.sh manager
```

Expected: FAIL with a message containing `pattern not found in upm-pkg-mgm.sh`.

- [ ] **Step 4: Commit**

Run:

```bash
git add scripts/validate-clickhouse-packages.sh
git commit -m "test: add clickhouse package validation"
```

Expected: commit succeeds.

## Task 2: Register ClickHouse Components In Package Manager

**Files:**
- Modify: `upm-pkg-mgm.sh`

- [ ] **Step 1: Run the focused failing test**

Run:

```bash
scripts/validate-clickhouse-packages.sh manager
```

Expected: FAIL because `upm-pkg-mgm.sh` does not contain ClickHouse categories yet.

- [ ] **Step 2: Add component accumulators**

In `get_component_categories()`, after `local kafka=""`, add:

```bash
  local clickhouse=""
  local clickhouse_keeper=""
```

- [ ] **Step 3: Add package matching cases**

In the `case "$package" in` block inside `get_component_categories()`, add this block before the generic `clickhouse-*` pattern:

```bash
    clickhouse-keeper-*)
      if [[ -z "$clickhouse_keeper" ]]; then
        clickhouse_keeper="$package"
      else
        clickhouse_keeper="$clickhouse_keeper $package"
      fi
      ;;
    clickhouse-*)
      if [[ -z "$clickhouse" ]]; then
        clickhouse="$package"
      else
        clickhouse="$clickhouse $package"
      fi
      ;;
```

The `clickhouse-keeper-*` case must appear before `clickhouse-*`.

- [ ] **Step 4: Add component output entries**

In the component result assembly section, after the Kafka block, add:

```bash
  if [[ -n "$clickhouse" ]]; then
    if [[ -n "$components" ]]; then
      components="$components|clickhouse:$clickhouse"
    else
      components="clickhouse:$clickhouse"
    fi
  fi
  if [[ -n "$clickhouse_keeper" ]]; then
    if [[ -n "$components" ]]; then
      components="$components|clickhouse-keeper:$clickhouse_keeper"
    else
      components="clickhouse-keeper:$clickhouse_keeper"
    fi
  fi
```

- [ ] **Step 5: Add component display text**

In `show_available_components()`, add these cases before `other)`:

```bash
    clickhouse)
      echo "  clickhouse: ClickHouse analytics database"
      ;;
    clickhouse-keeper)
      echo "  clickhouse-keeper: ClickHouse Keeper coordination service"
      ;;
```

- [ ] **Step 6: Run the focused test**

Run:

```bash
scripts/validate-clickhouse-packages.sh manager
```

Expected: PASS with `package manager contains ClickHouse component groups`.

- [ ] **Step 7: Commit**

Run:

```bash
git add upm-pkg-mgm.sh
git commit -m "feat: register clickhouse package groups"
```

Expected: commit succeeds.

## Task 3: Add ClickHouse Keeper Package

**Files:**
- Create: `clickhouse-keeper/README.md`
- Create: `clickhouse-keeper/26.3.9.8/image/Dockerfile`
- Create: `clickhouse-keeper/26.3.9.8/image/service-ctl.sh`
- Create: `clickhouse-keeper/26.3.9.8/image/supervisord.conf`
- Create: `clickhouse-keeper/26.3.9.8/charts/Chart.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/values.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/templates/_helpers.tpl`
- Create: `clickhouse-keeper/26.3.9.8/charts/templates/configTemplate.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/templates/configValue.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/templates/parametersDetail.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/templates/podtemplate.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl`
- Create: `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperValue.yaml`
- Create: `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperParametersDetail.json`
- Create: `clickhouse-keeper/26.3.9.8/charts/README.md`

- [ ] **Step 1: Run the focused failing test**

Run:

```bash
scripts/validate-clickhouse-packages.sh structure
```

Expected: FAIL with `missing file: clickhouse/README.md`. This is acceptable because the structure test covers both packages; this task will make the Keeper half pass.

- [ ] **Step 2: Create Keeper directories**

Run:

```bash
mkdir -p clickhouse-keeper/26.3.9.8/image
mkdir -p clickhouse-keeper/26.3.9.8/charts/templates
mkdir -p clickhouse-keeper/26.3.9.8/charts/files
```

Expected: no output.

- [ ] **Step 3: Add Keeper chart metadata**

Create `clickhouse-keeper/26.3.9.8/charts/Chart.yaml`:

```yaml
apiVersion: v2
appVersion: "26.3.9.8"
dependencies:
  - name: common
    repository: oci://registry-1.docker.io/bitnamicharts
    tags:
      - bitnami-common
    version: 2.31.3
name: clickhouse-keeper-26.3.9.8
version: 1.1.0
description: ClickHouse Keeper software packages, including configuration templates and pod templates.
type: application
keywords:
  - clickhouse
  - clickhouse-keeper
  - keeper
  - coordination
  - raft
```

Create `clickhouse-keeper/26.3.9.8/charts/values.yaml`:

```yaml
---
global:
  imageRegistry: ""

image:
  registry: quay.io
  repository: upmio/clickhouse-keeper
  tag: "26.3.9.8"
  digest: ""
  pullPolicy: IfNotPresent

agent:
  image:
    registry: quay.io
    repository: upmio/unit-agent
    tag: "v1.1.0"
    pullPolicy: IfNotPresent
```

Create `clickhouse-keeper/26.3.9.8/charts/templates/_helpers.tpl`:

```gotemplate
{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper ClickHouse Keeper image name.
*/}}
{{- define "clickhouse-keeper.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper unit-agent image name.
*/}}
{{- define "clickhouse-keeper.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
```

- [ ] **Step 4: Add Keeper ConfigMaps**

Create `clickhouse-keeper/26.3.9.8/charts/templates/configTemplate.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-config-template
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse-keeper
    version: {{ .Chart.AppVersion | quote }}
data:
  clickhouse-keeper: |
{{ .Files.Get "files/clickhouseKeeperTemplate.tpl" | indent 4 }}
```

Create `clickhouse-keeper/26.3.9.8/charts/templates/configValue.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-config-value
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse-keeper
    version: {{ .Chart.AppVersion | quote }}
data:
  clickhouse-keeper: |
{{ .Files.Get "files/clickhouseKeeperValue.yaml" | indent 4 }}
```

Create `clickhouse-keeper/26.3.9.8/charts/templates/parametersDetail.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-parameters-detail
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse-keeper
    version: {{ .Chart.AppVersion | quote }}
data:
  clickhouse-keeper: |
{{ .Files.Get "files/clickhouseKeeperParametersDetail.json" | indent 4 }}
```

- [ ] **Step 5: Add Keeper config files**

Create `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperValue.yaml`:

```yaml
defaults:
  coordination_settings:
    operation_timeout_ms: "10000"
    session_timeout_ms: "30000"
```

Create `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperParametersDetail.json`:

```json
[
  {
    "key": "operation_timeout_ms",
    "scope": "Global",
    "section": "coordination_settings",
    "type": "Integer",
    "dynamic": false,
    "range": "1000-120000",
    "default": "10000",
    "desc_en": "Timeout for Keeper coordination operations in milliseconds.",
    "desc_zh": "Keeper 协调操作的超时时间，单位为毫秒。"
  },
  {
    "key": "session_timeout_ms",
    "scope": "Global",
    "section": "coordination_settings",
    "type": "Integer",
    "dynamic": false,
    "range": "3000-300000",
    "default": "30000",
    "desc_en": "Keeper session timeout in milliseconds.",
    "desc_zh": "Keeper 会话超时时间，单位为毫秒。"
  }
]
```

Create `clickhouse-keeper/26.3.9.8/charts/files/clickhouseKeeperTemplate.tpl`:

```gotemplate
<clickhouse>
  <logger>
    <level>information</level>
    <log>{{ getenv "LOG_MOUNT" }}/clickhouse-keeper.log</log>
    <errorlog>{{ getenv "LOG_MOUNT" }}/clickhouse-keeper.err.log</errorlog>
    <size>1000M</size>
    <count>10</count>
  </logger>
  <keeper_server>
    <tcp_port>{{ getenv "CLICKHOUSE_KEEPER_PORT" "9181" }}</tcp_port>
    <server_id>{{ add (atoi (getenv "UNIT_SN" "0")) 1 }}</server_id>
    <log_storage_path>{{ getenv "KEEPER_DATA_DIR" }}/coordination/log</log_storage_path>
    <snapshot_storage_path>{{ getenv "KEEPER_DATA_DIR" }}/coordination/snapshots</snapshot_storage_path>
    <coordination_settings>
      <operation_timeout_ms>{{ getv "/defaults/coordination_settings/operation_timeout_ms" }}</operation_timeout_ms>
      <session_timeout_ms>{{ getv "/defaults/coordination_settings/session_timeout_ms" }}</session_timeout_ms>
    </coordination_settings>
    <raft_configuration>
{{- $serviceName := getenv "SERVICE_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $raftPort := getenv "CLICKHOUSE_KEEPER_RAFT_PORT" "9234" }}
{{- $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
{{- range $i := seq 0 (sub $unitCount 1) }}
      <server>
        <id>{{ add $i 1 }}</id>
        <hostname>{{ $serviceName }}-{{ $i }}.{{ $serviceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</hostname>
        <port>{{ $raftPort }}</port>
      </server>
{{- end }}
    </raft_configuration>
  </keeper_server>
  <listen_host>0.0.0.0</listen_host>
</clickhouse>
```

- [ ] **Step 6: Add Keeper PodTemplate**

Create `clickhouse-keeper/26.3.9.8/charts/templates/podtemplate.yaml` using the existing zookeeper security and env pattern:

```yaml
apiVersion: v1
kind: PodTemplate
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse-keeper
    version: {{ .Chart.AppVersion | quote }}
template:
  metadata:
    annotations:
      kubectl.kubernetes.io/default-container: clickhouse-keeper
    labels:
      type: clickhouse-keeper
      version: {{ .Chart.AppVersion | quote }}
  spec:
    tolerations:
      - key: "key"
        operator: "Equal"
        value: "value"
        effect: "NoSchedule"
    dnsPolicy: ClusterFirst
    restartPolicy: Always
    terminationGracePeriodSeconds: 30
    securityContext:
      fsGroup: 1001
      fsGroupChangePolicy: OnRootMismatch
    initContainers:
      - name: init-container
        image: {{ include "clickhouse-keeper.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
        securityContext:
          runAsUser: 1001
          runAsGroup: 1001
          allowPrivilegeEscalation: false
        command:
          - "bash"
          - "-c"
          - "service-ctl.sh initialize"
        env:
          - name: UNIT_SN
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unit.sn']"
          - name: UNIT_COUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unitset.units.count']"
          - name: DATA_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.data.mountPath']"
          - name: LOG_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.log.mountPath']"
          - name: KEEPER_DATA_DIR
            value: "$(DATA_MOUNT)/data"
          - name: KEEPER_CONF_DIR
            value: "$(DATA_MOUNT)/conf"
      - name: sysctl
        image: {{ include "clickhouse-keeper.image" . }}
        command:
          - "bash"
          - "-c"
          - "ulimit -n 65535"
        securityContext:
          privileged: true
          runAsUser: 0
    containers:
      - name: clickhouse-keeper
        image: {{ include "clickhouse-keeper.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
        securityContext:
          runAsUser: 1001
          runAsGroup: 1001
          allowPrivilegeEscalation: false
        ports:
          - containerPort: 9181
            name: keeper
          - containerPort: 9234
            name: raft
        env:
          - name: UNIT_SN
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unit.sn']"
          - name: UNIT_COUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unitset.units.count']"
          - name: DATA_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.data.mountPath']"
          - name: LOG_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.log.mountPath']"
          - name: KEEPER_DATA_DIR
            value: "$(DATA_MOUNT)/data"
          - name: KEEPER_CONF_DIR
            value: "$(DATA_MOUNT)/conf"
          - name: NAMESPACE
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.namespace"
          - name: POD_NAME
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.name"
          - name: SERVICE_NAME
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unitset.name']"
          - name: CLICKHOUSE_KEEPER_PORT
            value: "9181"
          - name: CLICKHOUSE_KEEPER_RAFT_PORT
            value: "9234"
        livenessProbe:
          exec:
            command:
              - "timeout"
              - "3"
              - "bash"
              - "-c"
              - "</dev/tcp/localhost/9001"
          failureThreshold: 3
          initialDelaySeconds: 12
          periodSeconds: 12
          timeoutSeconds: 4
          successThreshold: 1
        readinessProbe:
          exec:
            command:
              - "bash"
              - "-c"
              - "service-ctl.sh health"
          failureThreshold: 3
          initialDelaySeconds: 12
          periodSeconds: 12
          timeoutSeconds: 4
          successThreshold: 1
        startupProbe:
          exec:
            command:
              - "timeout"
              - "3"
              - "bash"
              - "-c"
              - "</dev/tcp/localhost/9001"
          failureThreshold: 3
          initialDelaySeconds: 12
          periodSeconds: 12
          timeoutSeconds: 4
          successThreshold: 1
      - name: unit-agent
        image: {{ include "clickhouse-keeper.agent.image" . }}
        imagePullPolicy: {{ .Values.agent.image.pullPolicy | quote }}
        securityContext:
          runAsUser: 1001
          runAsGroup: 1001
          allowPrivilegeEscalation: false
        ports:
          - containerPort: 2214
            name: unit-agent
        env:
          - name: UNIT_TYPE
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['kubectl.kubernetes.io/default-container']"
          - name: DATA_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.data.mountPath']"
          - name: LOG_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.log.mountPath']"
          - name: CONF_DIR
            value: "$(DATA_MOUNT)/conf"
          - name: CONFIG_PATH
            value: "$(DATA_MOUNT)/conf/keeper_config.xml"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

- [ ] **Step 7: Add Keeper image files**

Create `clickhouse-keeper/26.3.9.8/image/Dockerfile`:

```dockerfile
FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG CLICKHOUSE_VERSION="26.3.9.8"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-keeper" \
      org.opencontainers.image.description="UPM ClickHouse Keeper image"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  dnf install -y \
    yum-utils \
    procps-ng \
    openssl \
    net-tools \
    hostname \
    telnet \
    wget \
    glibc-common \
    glibc-langpack-en \
    glibc-locale-source \
    supervisor; \
  yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "clickhouse-keeper-${CLICKHOUSE_VERSION}"; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /var/tmp/*; \
  localedef -i en_US -f UTF-8 en_US.UTF-8

ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN set -eux; \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
  echo "$TZ" > /etc/timezone; \
  groupadd --system --gid 1001 unit-app; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" unit-app

COPY service-ctl.sh /usr/local/bin/service-ctl.sh
COPY supervisord.conf /etc/supervisord.conf

RUN chmod +x /usr/local/bin/service-ctl.sh

USER unit-app
EXPOSE 9181 9234
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
```

Create `clickhouse-keeper/26.3.9.8/image/supervisord.conf`:

```ini
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid

[inet_http_server]
port=127.0.0.1:9001

[supervisorctl]
serverurl=http://127.0.0.1:9001

[program:unit_app]
command=/usr/bin/clickhouse-keeper --config-file=%(ENV_KEEPER_CONF_DIR)s/keeper_config.xml
autorestart=true
startretries=3
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
```

Create `clickhouse-keeper/26.3.9.8/image/service-ctl.sh`:

```bash
#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

readonly SCRIPT_VERSION="v1.0.0"
readonly EXIT_MISSING_ENV_VAR=10
readonly EXIT_DIR_CREATION_FAILED=42
readonly EXIT_UNSUPPORTED_ACTION=21
readonly EXIT_INVALID_UNIT_COUNT=61

log() {
  local level="$1"
  local function_name="$2"
  shift 2
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"
  echo "[${timestamp}] ${level}| (${SCRIPT_VERSION})[${function_name}]: $* ;"
}

die() {
  local exit_code="$1"
  local function_name="$2"
  shift 2
  log "ERR " "$function_name" "$*"
  exit "$exit_code"
}

require_env() {
  local name="$1"
  local function_name="$2"
  [[ -n "${!name:-}" ]] || die "$EXIT_MISSING_ENV_VAR" "$function_name" "${name} environment variable not set"
}

initialize() {
  local function_name="initialize"
  require_env KEEPER_DATA_DIR "$function_name"
  require_env KEEPER_CONF_DIR "$function_name"
  require_env UNIT_COUNT "$function_name"
  case "$UNIT_COUNT" in
    3) ;;
    *) die "$EXIT_INVALID_UNIT_COUNT" "$function_name" "ClickHouse Keeper supports exactly 3 units, got ${UNIT_COUNT}" ;;
  esac
  mkdir -p "$KEEPER_DATA_DIR" "$KEEPER_CONF_DIR" "$KEEPER_DATA_DIR/coordination/log" "$KEEPER_DATA_DIR/coordination/snapshots" || {
    die "$EXIT_DIR_CREATION_FAILED" "$function_name" "failed to create Keeper directories"
  }
  log "INFO" "$function_name" "ClickHouse Keeper initialization complete"
}

health() {
  timeout 3 bash -c "</dev/tcp/127.0.0.1/${CLICKHOUSE_KEEPER_PORT:-9181}"
}

main() {
  local action="${1:-}"
  case "$action" in
    initialize) initialize ;;
    health) health ;;
    *) die "$EXIT_UNSUPPORTED_ACTION" main "service action(${action}) nonsupport" ;;
  esac
}

main "$@"
```

- [ ] **Step 8: Add Keeper docs**

Create `clickhouse-keeper/README.md`:

```markdown
# ClickHouse Keeper

ClickHouse Keeper package for UPM.

Supported UPM package version:

- `clickhouse-keeper/26.3.9.8`

ClickHouse Keeper is provisioned as a separate UnitSet in the same service group as ClickHouse. It is not an external ZooKeeper dependency.

The package renders a three-member Keeper ensemble by default. Server IDs and peer endpoints are generated from UnitSet ordinals and the UnitSet headless service name.
```

Create `clickhouse-keeper/26.3.9.8/charts/README.md`:

```markdown
# clickhouse-keeper-26.3.9.8

This chart packages ClickHouse Keeper `26.3.9.8` for UPM.

It provides:

- a Keeper `PodTemplate`
- Keeper configuration templates
- default Keeper parameter values
- Keeper parameter metadata

Keeper runs as a separate UnitSet and defaults to three units.
```

- [ ] **Step 9: Run focused tests**

Run:

```bash
scripts/validate-clickhouse-packages.sh templates
scripts/validate-clickhouse-packages.sh metadata
scripts/validate-clickhouse-packages.sh versions
```

Expected: `templates` and `metadata` may fail until the ClickHouse package exists; `versions` may fail until the ClickHouse chart exists. Confirm the failure message points to `clickhouse/...`, not `clickhouse-keeper/...`.

- [ ] **Step 10: Commit**

Run:

```bash
git add clickhouse-keeper
git commit -m "feat: add clickhouse keeper package"
```

Expected: commit succeeds.

## Task 4: Add ClickHouse Agent Image

**Files:**
- Create: `clickhouse/agent/26.3/image/Dockerfile`
- Create: `clickhouse/agent/26.3/image/README.md`

- [ ] **Step 1: Run focused failing test**

Run:

```bash
scripts/validate-clickhouse-packages.sh agent
```

Expected: FAIL with `missing file` or `pattern not found` for `clickhouse/agent/26.3/image/Dockerfile`.

- [ ] **Step 2: Create agent image directory**

Run:

```bash
mkdir -p clickhouse/agent/26.3/image
```

Expected: no output.

- [ ] **Step 3: Add agent Dockerfile**

Create `clickhouse/agent/26.3/image/Dockerfile`:

```dockerfile
FROM quay.io/upmio/unit-agent:v1.1.0 AS agent

FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG AGENT_VERSION="v1.1.0"
ARG CLICKHOUSE_VERSION="26.3.9.8"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse-agent" \
      org.opencontainers.image.description="UPM ClickHouse Agent image" \
      org.opencontainers.image.agent.version="$AGENT_VERSION"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  dnf install -y \
    yum-utils \
    procps-ng \
    openssl \
    xz \
    zstd \
    net-tools \
    hostname \
    telnet \
    wget \
    glibc-common \
    glibc-langpack-en \
    glibc-locale-source \
    ca-certificates \
    awscli; \
  yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "clickhouse-client-${CLICKHOUSE_VERSION}"; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /var/tmp/*; \
  localedef -i en_US -f UTF-8 en_US.UTF-8

ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN set -eux; \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
  echo "$TZ" > /etc/timezone; \
  groupadd --system --gid 1001 unit-agent; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" unit-agent

WORKDIR /home/unit-agent
COPY --from=agent /usr/local/bin/unit-agent /usr/local/bin/unit-agent
COPY --from=agent /opt/unit-agent/config.toml /opt/unit-agent/config.toml

CMD ["unit-agent","daemon","-f","/opt/unit-agent/config.toml"]

USER unit-agent
EXPOSE 2214
```

- [ ] **Step 4: Add agent README**

Create `clickhouse/agent/26.3/image/README.md`:

```markdown
# ClickHouse Agent Image

This image provides the ClickHouse-specific runtime for the existing UPM `unit-agent`.

It includes:

- `unit-agent` from `quay.io/upmio/unit-agent:v1.1.0`
- ClickHouse client `26.3.9.8`
- S3-compatible command-line tooling

The image does not add a new gRPC protocol. Backup, restore, and online setting operations continue to enter through the unit-operator ClickHouse agent contract.
```

- [ ] **Step 5: Run focused test**

Run:

```bash
scripts/validate-clickhouse-packages.sh agent
```

Expected: PASS with `ClickHouse agent image Dockerfile contains unit-agent and client`.

- [ ] **Step 6: Commit**

Run:

```bash
git add clickhouse/agent/26.3
git commit -m "feat: add clickhouse agent image"
```

Expected: commit succeeds.

## Task 5: Add ClickHouse Server Package

**Files:**
- Create: `clickhouse/README.md`
- Create: `clickhouse/26.3.9.8/image/Dockerfile`
- Create: `clickhouse/26.3.9.8/image/service-ctl.sh`
- Create: `clickhouse/26.3.9.8/image/supervisord.conf`
- Create: `clickhouse/26.3.9.8/charts/Chart.yaml`
- Create: `clickhouse/26.3.9.8/charts/values.yaml`
- Create: `clickhouse/26.3.9.8/charts/templates/_helpers.tpl`
- Create: `clickhouse/26.3.9.8/charts/templates/configTemplate.yaml`
- Create: `clickhouse/26.3.9.8/charts/templates/configValue.yaml`
- Create: `clickhouse/26.3.9.8/charts/templates/parametersDetail.yaml`
- Create: `clickhouse/26.3.9.8/charts/templates/podtemplate.yaml`
- Create: `clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl`
- Create: `clickhouse/26.3.9.8/charts/files/clickhouseValue.yaml`
- Create: `clickhouse/26.3.9.8/charts/files/clickhouseParametersDetail.json`
- Create: `clickhouse/26.3.9.8/charts/README.md`

- [ ] **Step 1: Run focused failing tests**

Run:

```bash
scripts/validate-clickhouse-packages.sh structure
scripts/validate-clickhouse-packages.sh versions
scripts/validate-clickhouse-packages.sh templates
scripts/validate-clickhouse-packages.sh metadata
```

Expected: FAIL messages point to missing `clickhouse/...` files.

- [ ] **Step 2: Create ClickHouse directories**

Run:

```bash
mkdir -p clickhouse/26.3.9.8/image
mkdir -p clickhouse/26.3.9.8/charts/templates
mkdir -p clickhouse/26.3.9.8/charts/files
```

Expected: no output.

- [ ] **Step 3: Add ClickHouse chart metadata**

Create `clickhouse/26.3.9.8/charts/Chart.yaml`:

```yaml
apiVersion: v2
appVersion: "26.3.9.8"
dependencies:
  - name: common
    repository: oci://registry-1.docker.io/bitnamicharts
    tags:
      - bitnami-common
    version: 2.31.3
name: clickhouse-26.3.9.8
version: 1.1.0
description: ClickHouse software packages, including configuration templates and pod templates.
type: application
keywords:
  - clickhouse
  - database
  - analytics
  - olap
```

Create `clickhouse/26.3.9.8/charts/values.yaml`:

```yaml
---
global:
  imageRegistry: ""

image:
  registry: quay.io
  repository: upmio/clickhouse
  tag: "26.3.9.8"
  digest: ""
  pullPolicy: IfNotPresent

agent:
  image:
    registry: quay.io
    repository: upmio/clickhouse-agent
    tag: "26.3"
    pullPolicy: IfNotPresent
```

Create `clickhouse/26.3.9.8/charts/templates/_helpers.tpl`:

```gotemplate
{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper ClickHouse image name.
*/}}
{{- define "clickhouse.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper ClickHouse agent image name.
*/}}
{{- define "clickhouse.agent.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}
```

- [ ] **Step 4: Add ClickHouse ConfigMaps**

Create `clickhouse/26.3.9.8/charts/templates/configTemplate.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-config-template
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse
    version: {{ .Chart.AppVersion | quote }}
data:
  clickhouse: |
{{ .Files.Get "files/clickhouseTemplate.tpl" | indent 4 }}
```

Create `clickhouse/26.3.9.8/charts/templates/configValue.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-config-value
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse
    version: {{ .Chart.AppVersion | quote }}
data:
  clickhouse: |
{{ .Files.Get "files/clickhouseValue.yaml" | indent 4 }}
```

Create `clickhouse/26.3.9.8/charts/templates/parametersDetail.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-parameters-detail
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse
    version: {{ .Chart.AppVersion | quote }}
data:
  clickhouse: |
{{ .Files.Get "files/clickhouseParametersDetail.json" | indent 4 }}
```

- [ ] **Step 5: Add ClickHouse config files**

Create `clickhouse/26.3.9.8/charts/files/clickhouseValue.yaml`:

```yaml
settings:
  max_threads: "8"
  max_memory_usage: "0"
  max_execution_time: "0"
  log_queries: "1"
  max_concurrent_queries: "100"
```

Create `clickhouse/26.3.9.8/charts/files/clickhouseParametersDetail.json`:

```json
[
  {
    "key": "max_threads",
    "scope": "Global",
    "section": "settings",
    "type": "Integer",
    "dynamic": true,
    "range": "1-1024",
    "default": "8",
    "desc_en": "Maximum query processing threads available to a query.",
    "desc_zh": "单个查询可使用的最大查询处理线程数。"
  },
  {
    "key": "max_memory_usage",
    "scope": "Global",
    "section": "settings",
    "type": "Integer",
    "dynamic": true,
    "range": "0-9223372036854775807",
    "default": "0",
    "desc_en": "Maximum memory usage for a query in bytes. A value of 0 leaves the limit disabled.",
    "desc_zh": "单个查询可使用的最大内存字节数。0 表示不启用该限制。"
  },
  {
    "key": "max_execution_time",
    "scope": "Global",
    "section": "settings",
    "type": "Integer",
    "dynamic": true,
    "range": "0-86400",
    "default": "0",
    "desc_en": "Maximum query execution time in seconds. A value of 0 leaves the limit disabled.",
    "desc_zh": "单个查询的最大执行时间，单位为秒。0 表示不启用该限制。"
  },
  {
    "key": "log_queries",
    "scope": "Global",
    "section": "settings",
    "type": "Boolean",
    "dynamic": true,
    "range": "[\"0\",\"1\"]",
    "default": "1",
    "desc_en": "Enable or disable query logging.",
    "desc_zh": "启用或禁用查询日志。"
  },
  {
    "key": "max_concurrent_queries",
    "scope": "Global",
    "section": "settings",
    "type": "Integer",
    "dynamic": true,
    "range": "1-100000",
    "default": "100",
    "desc_en": "Maximum number of concurrently running queries.",
    "desc_zh": "允许同时运行的最大查询数。"
  }
]
```

Create `clickhouse/26.3.9.8/charts/files/clickhouseTemplate.tpl`:

```gotemplate
<clickhouse>
  <logger>
    <level>information</level>
    <log>{{ getenv "LOG_MOUNT" }}/clickhouse-server.log</log>
    <errorlog>{{ getenv "LOG_MOUNT" }}/clickhouse-server.err.log</errorlog>
    <size>1000M</size>
    <count>10</count>
  </logger>
  <listen_host>0.0.0.0</listen_host>
  <tcp_port>{{ getenv "CLICKHOUSE_TCP_PORT" "9000" }}</tcp_port>
  <http_port>{{ getenv "CLICKHOUSE_HTTP_PORT" "8123" }}</http_port>
  <interserver_http_port>{{ getenv "CLICKHOUSE_INTERSERVER_PORT" "9009" }}</interserver_http_port>
  <path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/</path>
  <tmp_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/tmp/</tmp_path>
  <user_files_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/user_files/</user_files_path>
  <format_schema_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/format_schemas/</format_schema_path>

  <remote_servers>
    <upm_cluster>
      <shard>
        <internal_replication>true</internal_replication>
{{- $serviceName := getenv "SERVICE_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $tcpPort := getenv "CLICKHOUSE_TCP_PORT" "9000" }}
{{- $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
{{- range $i := seq 0 (sub $unitCount 1) }}
        <replica>
          <host>{{ $serviceName }}-{{ $i }}.{{ $serviceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</host>
          <port>{{ $tcpPort }}</port>
        </replica>
{{- end }}
      </shard>
    </upm_cluster>
  </remote_servers>

  <zookeeper>
{{- $keeperServiceName := getenv "CLICKHOUSE_KEEPER_SERVICE_NAME" (printf "%s-keeper" (getenv "SERVICE_GROUP_NAME" $serviceName)) }}
{{- $keeperCount := atoi (getenv "CLICKHOUSE_KEEPER_UNIT_COUNT" "3") }}
{{- $keeperPort := getenv "CLICKHOUSE_KEEPER_PORT" "9181" }}
{{- range $i := seq 0 (sub $keeperCount 1) }}
    <node>
      <host>{{ $keeperServiceName }}-{{ $i }}.{{ $keeperServiceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</host>
      <port>{{ $keeperPort }}</port>
    </node>
{{- end }}
  </zookeeper>

  <macros>
    <shard>01</shard>
    <replica>{{ getenv "POD_NAME" }}</replica>
  </macros>

  <profiles>
    <default>
      <max_threads>{{ getv "/settings/max_threads" }}</max_threads>
      <max_memory_usage>{{ getv "/settings/max_memory_usage" }}</max_memory_usage>
      <max_execution_time>{{ getv "/settings/max_execution_time" }}</max_execution_time>
      <log_queries>{{ getv "/settings/log_queries" }}</log_queries>
      <max_concurrent_queries>{{ getv "/settings/max_concurrent_queries" }}</max_concurrent_queries>
    </default>
  </profiles>

  <users>
    <default>
      <profile>default</profile>
      <networks>
        <ip>::/0</ip>
      </networks>
      <access_management>1</access_management>
    </default>
  </users>

  <backups>
    <allowed_disk>backups</allowed_disk>
    <allowed_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/backups/</allowed_path>
  </backups>
</clickhouse>
```

- [ ] **Step 6: Add ClickHouse PodTemplate**

Create `clickhouse/26.3.9.8/charts/templates/podtemplate.yaml` using the same security, env, and probe style as PostgreSQL and Kafka:

```yaml
apiVersion: v1
kind: PodTemplate
metadata:
  name: {{ .Chart.Name }}
  namespace: {{ .Release.Namespace | quote }}
  labels:
    upm.io/owner: upm
    type: clickhouse
    version: {{ .Chart.AppVersion | quote }}
template:
  metadata:
    annotations:
      kubectl.kubernetes.io/default-container: clickhouse
    labels:
      type: clickhouse
      version: {{ .Chart.AppVersion | quote }}
  spec:
    tolerations:
      - key: "key"
        operator: "Equal"
        value: "value"
        effect: "NoSchedule"
    dnsPolicy: ClusterFirst
    restartPolicy: Always
    terminationGracePeriodSeconds: 30
    securityContext:
      fsGroup: 1001
      fsGroupChangePolicy: OnRootMismatch
    initContainers:
      - name: init-container
        image: {{ include "clickhouse.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
        securityContext:
          runAsUser: 1001
          runAsGroup: 1001
          allowPrivilegeEscalation: false
        command:
          - "bash"
          - "-c"
          - "service-ctl.sh initialize"
        env:
          - name: UNIT_COUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unitset.units.count']"
          - name: DATA_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.data.mountPath']"
          - name: LOG_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.log.mountPath']"
          - name: CLICKHOUSE_DATA_DIR
            value: "$(DATA_MOUNT)/data"
          - name: CLICKHOUSE_CONF_DIR
            value: "$(DATA_MOUNT)/conf"
      - name: sysctl
        image: {{ include "clickhouse.image" . }}
        command:
          - "bash"
          - "-c"
          - "ulimit -n 65535"
        securityContext:
          privileged: true
          runAsUser: 0
    containers:
      - name: clickhouse
        image: {{ include "clickhouse.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
        securityContext:
          runAsUser: 1001
          runAsGroup: 1001
          allowPrivilegeEscalation: false
        ports:
          - containerPort: 9000
            name: tcp
          - containerPort: 8123
            name: http
          - containerPort: 9009
            name: interserver
          - containerPort: 9363
            name: metrics
        env:
          - name: UNIT_COUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unitset.units.count']"
          - name: DATA_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.data.mountPath']"
          - name: LOG_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.log.mountPath']"
          - name: CLICKHOUSE_DATA_DIR
            value: "$(DATA_MOUNT)/data"
          - name: CLICKHOUSE_CONF_DIR
            value: "$(DATA_MOUNT)/conf"
          - name: NAMESPACE
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.namespace"
          - name: POD_NAME
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.name"
          - name: SERVICE_NAME
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['unit-operator/unitset.name']"
          - name: SERVICE_GROUP_NAME
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.labels['upm.api/service-group.name']"
          - name: CLICKHOUSE_KEEPER_SERVICE_NAME
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['upm.api/clickhouse-keeper.service-name']"
          - name: CLICKHOUSE_TCP_PORT
            value: "9000"
          - name: CLICKHOUSE_HTTP_PORT
            value: "8123"
          - name: CLICKHOUSE_INTERSERVER_PORT
            value: "9009"
          - name: CLICKHOUSE_KEEPER_PORT
            value: "9181"
          - name: CLICKHOUSE_KEEPER_UNIT_COUNT
            value: "3"
        livenessProbe:
          exec:
            command:
              - "timeout"
              - "3"
              - "bash"
              - "-c"
              - "</dev/tcp/localhost/9001"
          failureThreshold: 3
          initialDelaySeconds: 12
          periodSeconds: 12
          timeoutSeconds: 4
          successThreshold: 1
        readinessProbe:
          exec:
            command:
              - "bash"
              - "-c"
              - "service-ctl.sh health"
          failureThreshold: 3
          initialDelaySeconds: 12
          periodSeconds: 12
          timeoutSeconds: 4
          successThreshold: 1
        startupProbe:
          exec:
            command:
              - "timeout"
              - "3"
              - "bash"
              - "-c"
              - "</dev/tcp/localhost/9001"
          failureThreshold: 3
          initialDelaySeconds: 12
          periodSeconds: 12
          timeoutSeconds: 4
          successThreshold: 1
      - name: unit-agent
        image: {{ include "clickhouse.agent.image" . }}
        imagePullPolicy: {{ .Values.agent.image.pullPolicy | quote }}
        securityContext:
          runAsUser: 1001
          runAsGroup: 1001
          allowPrivilegeEscalation: false
        ports:
          - containerPort: 2214
            name: unit-agent
        env:
          - name: UNIT_TYPE
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['kubectl.kubernetes.io/default-container']"
          - name: DATA_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.data.mountPath']"
          - name: LOG_MOUNT
            valueFrom:
              fieldRef:
                apiVersion: "v1"
                fieldPath: "metadata.annotations['unit-operator/storage.volume.log.mountPath']"
          - name: DATA_DIR
            value: "$(DATA_MOUNT)/data"
          - name: CONF_DIR
            value: "$(DATA_MOUNT)/conf"
          - name: CONFIG_PATH
            value: "$(DATA_MOUNT)/conf/config.xml"
          - name: CLICKHOUSE_HOST
            value: "127.0.0.1"
          - name: CLICKHOUSE_PORT
            value: "9000"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

- [ ] **Step 7: Add ClickHouse image files**

Create `clickhouse/26.3.9.8/image/Dockerfile`:

```dockerfile
FROM rockylinux/rockylinux:9.6.20250531

ARG BUILD_DATE
ARG VCS_REF
ARG CLICKHOUSE_VERSION="26.3.9.8"

LABEL org.opencontainers.image.source="https://github.com/upmio/upm-packages" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.title="clickhouse" \
      org.opencontainers.image.description="UPM ClickHouse image"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
  dnf install -y \
    yum-utils \
    procps-ng \
    openssl \
    net-tools \
    hostname \
    telnet \
    wget \
    glibc-common \
    glibc-langpack-en \
    glibc-locale-source \
    supervisor; \
  yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo; \
  dnf install -y --setopt=install_weak_deps=False --setopt=tsflags=nodocs "clickhouse-server-${CLICKHOUSE_VERSION}" "clickhouse-client-${CLICKHOUSE_VERSION}"; \
  dnf clean all; \
  rm -rf /var/cache/dnf /var/cache/yum /var/tmp/*; \
  localedef -i en_US -f UTF-8 en_US.UTF-8

ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN set -eux; \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
  echo "$TZ" > /etc/timezone; \
  groupadd --system --gid 1001 unit-app; \
  useradd --system --uid 1001 --gid 1001 -m -c "Default Application User" unit-app

COPY service-ctl.sh /usr/local/bin/service-ctl.sh
COPY supervisord.conf /etc/supervisord.conf

RUN chmod +x /usr/local/bin/service-ctl.sh

USER unit-app
EXPOSE 9000 8123 9009 9363
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
```

Create `clickhouse/26.3.9.8/image/supervisord.conf`:

```ini
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid

[inet_http_server]
port=127.0.0.1:9001

[supervisorctl]
serverurl=http://127.0.0.1:9001

[program:unit_app]
command=/usr/bin/clickhouse-server --config-file=%(ENV_CLICKHOUSE_CONF_DIR)s/config.xml
autorestart=true
startretries=3
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
```

Create `clickhouse/26.3.9.8/image/service-ctl.sh`:

```bash
#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

readonly SCRIPT_VERSION="v1.0.0"
readonly EXIT_MISSING_ENV_VAR=10
readonly EXIT_DIR_CREATION_FAILED=42
readonly EXIT_UNSUPPORTED_ACTION=21
readonly EXIT_INVALID_UNIT_COUNT=61

log() {
  local level="$1"
  local function_name="$2"
  shift 2
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"
  echo "[${timestamp}] ${level}| (${SCRIPT_VERSION})[${function_name}]: $* ;"
}

die() {
  local exit_code="$1"
  local function_name="$2"
  shift 2
  log "ERR " "$function_name" "$*"
  exit "$exit_code"
}

require_env() {
  local name="$1"
  local function_name="$2"
  [[ -n "${!name:-}" ]] || die "$EXIT_MISSING_ENV_VAR" "$function_name" "${name} environment variable not set"
}

initialize() {
  local function_name="initialize"
  require_env CLICKHOUSE_DATA_DIR "$function_name"
  require_env CLICKHOUSE_CONF_DIR "$function_name"
  require_env UNIT_COUNT "$function_name"
  case "$UNIT_COUNT" in
    2|3) ;;
    *) die "$EXIT_INVALID_UNIT_COUNT" "$function_name" "ClickHouse supports 2 or 3 replicas, got ${UNIT_COUNT}" ;;
  esac
  mkdir -p \
    "$CLICKHOUSE_DATA_DIR" \
    "$CLICKHOUSE_CONF_DIR" \
    "$CLICKHOUSE_DATA_DIR/tmp" \
    "$CLICKHOUSE_DATA_DIR/user_files" \
    "$CLICKHOUSE_DATA_DIR/format_schemas" \
    "$CLICKHOUSE_DATA_DIR/backups" || {
    die "$EXIT_DIR_CREATION_FAILED" "$function_name" "failed to create ClickHouse directories"
  }
  log "INFO" "$function_name" "ClickHouse initialization complete"
}

health() {
  clickhouse-client --host 127.0.0.1 --port "${CLICKHOUSE_TCP_PORT:-9000}" --query "SELECT 1" >/dev/null
}

login() {
  clickhouse-client --host 127.0.0.1 --port "${CLICKHOUSE_TCP_PORT:-9000}"
}

main() {
  local action="${1:-}"
  case "$action" in
    initialize) initialize ;;
    health) health ;;
    login) login ;;
    *) die "$EXIT_UNSUPPORTED_ACTION" main "service action(${action}) nonsupport" ;;
  esac
}

main "$@"
```

- [ ] **Step 8: Add ClickHouse docs**

Create `clickhouse/README.md`:

```markdown
# ClickHouse

ClickHouse package for UPM.

Supported UPM package version:

- `clickhouse/26.3.9.8`

ClickHouse Keeper is provisioned as a separate UnitSet in the same service group. It is not an external ZooKeeper dependency.

The first supported topology is one shard with two or three ClickHouse replicas. The ClickHouse package renders replica macros, one-shard cluster topology, and Keeper endpoints from UnitSet metadata.
```

Create `clickhouse/26.3.9.8/charts/README.md`:

```markdown
# clickhouse-26.3.9.8

This chart packages ClickHouse `26.3.9.8` for UPM.

It provides:

- a ClickHouse `PodTemplate`
- ClickHouse configuration templates
- default ClickHouse parameter values
- ClickHouse parameter metadata
- a `unit-agent` sidecar using `quay.io/upmio/clickhouse-agent:26.3`

The chart supports one shard with two or three replicas.
```

- [ ] **Step 9: Run focused tests**

Run:

```bash
scripts/validate-clickhouse-packages.sh structure
scripts/validate-clickhouse-packages.sh versions
scripts/validate-clickhouse-packages.sh templates
scripts/validate-clickhouse-packages.sh metadata
```

Expected: all four commands PASS.

- [ ] **Step 10: Commit**

Run:

```bash
git add clickhouse
git commit -m "feat: add clickhouse package"
```

Expected: commit succeeds.

## Task 6: Update Top-Level Documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Run focused failing test**

Run:

```bash
scripts/validate-clickhouse-packages.sh docs
```

Expected: FAIL because the top-level README does not list ClickHouse `26.3.9.8`.

- [ ] **Step 2: Add database table rows**

In `README.md`, in the `Database Systems` table, add these rows after PostgreSQL:

```markdown
| **ClickHouse**      | 26.3.9.8                            | Analytics database with Keeper-backed replication | ✅ Stable |
| **ClickHouse Keeper** | 26.3.9.8                          | Coordination service for ClickHouse UnitSets      | ✅ Stable |
```

- [ ] **Step 3: Add architecture note**

In `README.md`, near the package architecture section, add:

```markdown
### ClickHouse Keeper Topology

ClickHouse is packaged as two UPM components: `clickhouse` and `clickhouse-keeper`. Keeper is provisioned as a separate UnitSet in the same service group and is not an external ZooKeeper dependency. Both components use the UPM version value `26.3.9.8`.
```

- [ ] **Step 4: Run focused test**

Run:

```bash
scripts/validate-clickhouse-packages.sh docs
```

Expected: PASS with `documentation mentions ClickHouse package scope`.

- [ ] **Step 5: Commit**

Run:

```bash
git add README.md
git commit -m "docs: document clickhouse packages"
```

Expected: commit succeeds.

## Task 7: Run Full Validation And Fix Integration Issues

**Files:**
- Modify: files reported by validation commands.

- [ ] **Step 1: Run repository chart validation**

Run:

```bash
scripts/validate-charts.sh
```

Expected: PASS. If it fails because the new charts are missing `Chart.lock`, run dependency build in Step 2 before changing chart content.

- [ ] **Step 2: Build Helm dependencies for new charts**

Run:

```bash
helm dependency build clickhouse/26.3.9.8/charts
helm dependency build clickhouse-keeper/26.3.9.8/charts
```

Expected: both commands complete successfully and create or update `Chart.lock` plus `charts/` dependency content according to the repository's Helm workflow.

- [ ] **Step 3: Run focused ClickHouse validation**

Run:

```bash
scripts/validate-clickhouse-packages.sh all
```

Expected: PASS. The output includes PASS lines for manager, structure, versions, metadata, templates, docs, agent, and helm.

- [ ] **Step 4: Run shell lint**

Run:

```bash
scripts/lint.sh
```

Expected: PASS. If this script requires tools that are not installed in the local environment, record the missing tool name in the final implementation handoff and still run `bash -n` on all new shell scripts:

```bash
bash -n scripts/validate-clickhouse-packages.sh
bash -n clickhouse/26.3.9.8/image/service-ctl.sh
bash -n clickhouse-keeper/26.3.9.8/image/service-ctl.sh
```

Expected: no output from all `bash -n` commands.

- [ ] **Step 5: Render both charts directly**

Run:

```bash
helm template test-clickhouse clickhouse/26.3.9.8/charts >/tmp/clickhouse-render.yaml
helm template test-clickhouse-keeper clickhouse-keeper/26.3.9.8/charts >/tmp/clickhouse-keeper-render.yaml
grep -n 'type: clickhouse' /tmp/clickhouse-render.yaml
grep -n 'type: clickhouse-keeper' /tmp/clickhouse-keeper-render.yaml
grep -n 'CLICKHOUSE_KEEPER_SERVICE_NAME' /tmp/clickhouse-render.yaml
grep -n 'unit-operator/unitset.units.count' /tmp/clickhouse-render.yaml
grep -n 'unit-operator/unitset.units.count' /tmp/clickhouse-keeper-render.yaml
```

Expected: both `helm template` commands succeed and each `grep` prints at least one matching line.

- [ ] **Step 6: Commit validation fixes**

Run:

```bash
git status --short
git add scripts/validate-clickhouse-packages.sh clickhouse clickhouse-keeper upm-pkg-mgm.sh README.md
git commit -m "test: validate clickhouse packages"
```

Expected: commit succeeds if validation required file changes. If `git status --short` shows no changes, skip this commit and keep the validation output for the final handoff.

## Self-Review Checklist

Spec coverage:

- Package inventory: Task 2 and Task 7.
- ClickHouse chart and values: Task 5.
- Keeper chart and values: Task 3.
- Config templates: Task 3 and Task 5.
- Parameter metadata: Task 3 and Task 5.
- Agent image: Task 4.
- Docs: Task 6.
- Validation: Task 1 and Task 7.

Risk notes for the implementing agent:

- ClickHouse official RPM installation should follow the ClickHouse Redhat/CentOS install docs: add `https://packages.clickhouse.com/rpm/clickhouse.repo`, then install package names with `-26.3.9.8`.
- The plan uses the existing `unit-operator/unitset.units.count` label for ClickHouse replica count and Keeper ensemble count.
- The plan uses annotation `upm.api/clickhouse-keeper.service-name` as the explicit cross-UnitSet Keeper service input, with template fallback to `<SERVICE_GROUP_NAME>-keeper`.
- Full S3 backup and restore execution remains an integration-environment validation item; local validation checks the agent image contains the required runtime tools.
