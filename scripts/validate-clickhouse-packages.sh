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
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' RETURN

  helm lint "${ROOT_DIR}/clickhouse/26.3.9.8/charts" >"${tmpdir}/clickhouse-helm-lint.out" || return
  helm lint "${ROOT_DIR}/clickhouse-keeper/26.3.9.8/charts" >"${tmpdir}/clickhouse-keeper-helm-lint.out" || return
  helm template test-clickhouse "${ROOT_DIR}/clickhouse/26.3.9.8/charts" >"${tmpdir}/clickhouse-render.yaml" || return
  helm template test-clickhouse-keeper "${ROOT_DIR}/clickhouse-keeper/26.3.9.8/charts" >"${tmpdir}/clickhouse-keeper-render.yaml" || return
  if ! grep -q 'name: clickhouse-26.3.9.8' "${tmpdir}/clickhouse-render.yaml"; then
    echo "[FAIL] ClickHouse chart did not render expected PodTemplate name" >&2
    return 1
  fi
  if ! grep -q 'name: clickhouse-keeper-26.3.9.8' "${tmpdir}/clickhouse-keeper-render.yaml"; then
    echo "[FAIL] Keeper chart did not render expected PodTemplate name" >&2
    return 1
  fi
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
