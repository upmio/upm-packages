#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLICKHOUSE_PACKAGE_VERSIONS=(21.8.15.7 23.8.16.40 25.8.29.51 26.3.9.8)

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
  local version path
  local clickhouse_paths=(
    image/Dockerfile
    image/service-ctl.sh
    image/supervisord.conf
    charts/Chart.yaml
    charts/values.yaml
    charts/templates/_helpers.tpl
    charts/templates/configTemplate.yaml
    charts/templates/configValue.yaml
    charts/templates/parametersDetail.yaml
    charts/templates/podtemplate.yaml
    charts/files/clickhouseTemplate.tpl
    charts/files/clickhouseValue.yaml
    charts/files/clickhouseParametersDetail.json
    charts/README.md
  )
  local keeper_paths=(
    image/Dockerfile
    image/service-ctl.sh
    image/supervisord.conf
    charts/Chart.yaml
    charts/values.yaml
    charts/templates/_helpers.tpl
    charts/templates/configTemplate.yaml
    charts/templates/configValue.yaml
    charts/templates/parametersDetail.yaml
    charts/templates/podtemplate.yaml
    charts/files/clickhouseKeeperTemplate.tpl
    charts/files/clickhouseKeeperValue.yaml
    charts/files/clickhouseKeeperParametersDetail.json
    charts/README.md
  )

  require_file clickhouse/README.md
  require_file clickhouse/agent/26.3/image/Dockerfile
  require_file clickhouse/agent/26.3/image/README.md
  require_file clickhouse-keeper/README.md

  for version in "${CLICKHOUSE_PACKAGE_VERSIONS[@]}"; do
    for path in "${clickhouse_paths[@]}"; do
      require_file "clickhouse/${version}/${path}"
    done
    for path in "${keeper_paths[@]}"; do
      require_file "clickhouse-keeper/${version}/${path}"
    done
    require_dir "clickhouse/${version}/charts/templates"
    require_dir "clickhouse-keeper/${version}/charts/templates"
    if [[ "$version" != "26.3.9.8" ]]; then
      require_file "clickhouse/agent/${version%.*.*}/image/Dockerfile"
      require_file "clickhouse/agent/${version%.*.*}/image/README.md"
    fi
  done
  pass "ClickHouse package structure exists"
}

validate_versions() {
  local version escaped_version agent_version
  for version in "${CLICKHOUSE_PACKAGE_VERSIONS[@]}"; do
    escaped_version="${version//./\\.}"
    require_grep "^name:[[:space:]]*clickhouse-${escaped_version}$" "clickhouse/${version}/charts/Chart.yaml"
    require_grep "^appVersion:[[:space:]]*\\\"?${escaped_version}\\\"?$" "clickhouse/${version}/charts/Chart.yaml"
    require_grep "^  tag:[[:space:]]*\\\"${escaped_version}\\\"$" "clickhouse/${version}/charts/values.yaml"
    if [[ "$version" != "26.3.9.8" ]]; then
      agent_version="${version%.*.*}"
      require_grep "^    tag:[[:space:]]*\\\"${agent_version}\\\"$" "clickhouse/${version}/charts/values.yaml"
    fi
    require_grep "^ARG CLICKHOUSE_VERSION=\\\"${escaped_version}\\\"$" "clickhouse/${version}/image/Dockerfile"
    require_grep "^name:[[:space:]]*clickhouse-keeper-${escaped_version}$" "clickhouse-keeper/${version}/charts/Chart.yaml"
    require_grep "^appVersion:[[:space:]]*\\\"?${escaped_version}\\\"?$" "clickhouse-keeper/${version}/charts/Chart.yaml"
    require_grep "^  tag:[[:space:]]*\\\"${escaped_version}\\\"$" "clickhouse-keeper/${version}/charts/values.yaml"
    require_grep "^ARG CLICKHOUSE_VERSION=\\\"${escaped_version}\\\"$" "clickhouse-keeper/${version}/image/Dockerfile"
    require_grep '^EXPOSE 9181 9234$' "clickhouse-keeper/${version}/image/Dockerfile"
    if [[ "$version" != "26.3.9.8" ]]; then
      require_grep '^ARG CLICKHOUSE_REPOSITORY="https://packages\.clickhouse\.com/rpm/lts"$' "clickhouse-keeper/${version}/image/Dockerfile"
      if [[ "$version" == "21.8.15.7" ]]; then
        require_grep 'clickhouse keeper --version' "clickhouse-keeper/${version}/image/Dockerfile"
        require_grep '^command=/usr/bin/clickhouse keeper ' "clickhouse-keeper/${version}/image/supervisord.conf"
      else
        require_grep 'clickhouse-keeper --version' "clickhouse-keeper/${version}/image/Dockerfile"
        require_grep '^command=/usr/bin/clickhouse-keeper ' "clickhouse-keeper/${version}/image/supervisord.conf"
      fi
    fi
  done
  pass "ClickHouse chart versions are exact"
}

validate_metadata() {
  python3 - <<'PY' "${ROOT_DIR}"
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
versions = ("21.8.15.7", "23.8.16.40", "25.8.29.51", "26.3.9.8")
for version in versions:
    for rel in [
        f"clickhouse/{version}/charts/files/clickhouseParametersDetail.json",
        f"clickhouse-keeper/{version}/charts/files/clickhouseKeeperParametersDetail.json",
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
  local version template_path
  for version in "${CLICKHOUSE_PACKAGE_VERSIONS[@]}"; do
    template_path="clickhouse/${version}/charts/files/clickhouseTemplate.tpl"
    require_grep '<remote_servers>' "$template_path"
    require_grep '<macros>' "$template_path"
    require_grep 'CLICKHOUSE_KEEPER_SERVICE_NAME' "$template_path"
    require_grep 'UNIT_COUNT' "$template_path"
    require_grep '<no_password>1</no_password>' "$template_path"
    python3 - "${ROOT_DIR}/${template_path}" <<'PY'
import pathlib
import re
import sys

template = pathlib.Path(sys.argv[1]).read_text()
profiles_match = re.search(r"<profiles>.*?</profiles>", template, re.S)
if not profiles_match:
    raise SystemExit("ClickHouse template must contain profiles")
if "<max_concurrent_queries>" in profiles_match.group(0):
    raise SystemExit("max_concurrent_queries is a server setting and must not be in profiles")
if "<max_concurrent_queries>" not in template:
    raise SystemExit("ClickHouse template must configure max_concurrent_queries")
PY
    require_grep '<keeper_server>' "clickhouse-keeper/${version}/charts/files/clickhouseKeeperTemplate.tpl"
    require_grep '<raft_configuration>' "clickhouse-keeper/${version}/charts/files/clickhouseKeeperTemplate.tpl"
    require_grep 'UNIT_COUNT' "clickhouse-keeper/${version}/charts/files/clickhouseKeeperTemplate.tpl"
  done
  pass "configuration templates contain topology sections"
}

validate_docs() {
  local version escaped_version
  require_grep 'ClickHouse' README.md
  require_grep 'separate UnitSet' clickhouse/README.md
  require_grep 'not an external ZooKeeper dependency' clickhouse/README.md
  require_grep 'separate UnitSet' clickhouse-keeper/README.md
  for version in "${CLICKHOUSE_PACKAGE_VERSIONS[@]}"; do
    escaped_version="${version//./\\.}"
    require_grep "$escaped_version" README.md
    require_grep "clickhouse/${escaped_version}" clickhouse/README.md
    require_grep "clickhouse-keeper/${escaped_version}" clickhouse-keeper/README.md
  done
  pass "documentation mentions ClickHouse package scope"
}

validate_agent() {
  local agent_version clickhouse_version escaped_version dockerfile
  require_grep 'FROM quay\.io/upmio/unit-agent:' clickhouse/agent/26.3/image/Dockerfile
  require_grep 'clickhouse-client-26\.3\.9\.8' clickhouse/agent/26.3/image/Dockerfile
  require_grep 'CMD \["unit-agent","daemon","-f","/opt/unit-agent/config.toml"\]' clickhouse/agent/26.3/image/Dockerfile

  for agent_version in 21.8 23.8 25.8; do
    case "$agent_version" in
      21.8) clickhouse_version="21.8.15.7" ;;
      23.8) clickhouse_version="23.8.16.40" ;;
      25.8) clickhouse_version="25.8.29.51" ;;
    esac
    escaped_version="${clickhouse_version//./\\.}"
    dockerfile="clickhouse/agent/${agent_version}/image/Dockerfile"
    require_grep 'FROM quay\.io/upmio/unit-agent:v1\.1\.0 AS agent' "$dockerfile"
    require_grep "^ARG CLICKHOUSE_VERSION=\\\"${escaped_version}\\\"$" "$dockerfile"
    require_grep '^ARG CLICKHOUSE_REPOSITORY="https://packages\.clickhouse\.com/rpm/lts"$' "$dockerfile"
    require_grep 'clickhouse-common-static' "$dockerfile"
    require_grep 'clickhouse-client --version' "$dockerfile"
    require_grep 'CMD \["unit-agent","daemon","-f","/opt/unit-agent/config.toml"\]' "$dockerfile"
    require_grep "ClickHouse .*${agent_version}.*runtime" "clickhouse/agent/${agent_version}/image/README.md"
    require_grep "${escaped_version}" "clickhouse/agent/${agent_version}/image/README.md"
  done

  require_grep '^ARG CLICKHOUSE_RELEASE="2"$' clickhouse/agent/21.8/image/Dockerfile
  require_grep 'upstream arm64 RPM packages' clickhouse/agent/21.8/image/README.md
  require_grep '^ARG TARGETARCH$' clickhouse/agent/23.8/image/Dockerfile
  require_grep '^ARG TARGETARCH$' clickhouse/agent/25.8/image/Dockerfile
  require_grep 'clickhouse/agent/21\.8/image' .github/workflows/release.yml
  pass "ClickHouse agent image Dockerfile contains unit-agent and client"
}

validate_helm() {
  command -v helm >/dev/null 2>&1 || fail "helm command is required"
  local tmpdir version clickhouse_chart keeper_chart agent_tag
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' RETURN

  for version in "${CLICKHOUSE_PACKAGE_VERSIONS[@]}"; do
    clickhouse_chart="${tmpdir}/clickhouse-${version}"
    keeper_chart="${tmpdir}/clickhouse-keeper-${version}"
    cp -R "${ROOT_DIR}/clickhouse/${version}/charts" "${clickhouse_chart}"
    cp -R "${ROOT_DIR}/clickhouse-keeper/${version}/charts" "${keeper_chart}"
    helm dependency build "${clickhouse_chart}" >"${tmpdir}/clickhouse-${version}-dependency-build.out" || return
    helm dependency build "${keeper_chart}" >"${tmpdir}/clickhouse-keeper-${version}-dependency-build.out" || return
    helm lint "${clickhouse_chart}" >"${tmpdir}/clickhouse-${version}-helm-lint.out" || return
    helm lint "${keeper_chart}" >"${tmpdir}/clickhouse-keeper-${version}-helm-lint.out" || return
    helm template "test-clickhouse-${version}" "${clickhouse_chart}" >"${tmpdir}/clickhouse-${version}-render.yaml" || return
    helm template "test-clickhouse-keeper-${version}" "${keeper_chart}" >"${tmpdir}/clickhouse-keeper-${version}-render.yaml" || return
    if ! grep -Fq "name: clickhouse-${version}" "${tmpdir}/clickhouse-${version}-render.yaml"; then
      echo "[FAIL] ClickHouse ${version} chart did not render expected PodTemplate name" >&2
      return 1
    fi
    agent_tag="${version%.*.*}"
    if [[ "$version" == "26.3.9.8" ]]; then
      agent_tag="26.3"
    fi
    if ! grep -Fq "image: quay.io/upmio/clickhouse-agent:${agent_tag}" "${tmpdir}/clickhouse-${version}-render.yaml"; then
      echo "[FAIL] ClickHouse ${version} chart did not render expected agent image tag" >&2
      return 1
    fi
    if ! grep -Fq "name: clickhouse-keeper-${version}" "${tmpdir}/clickhouse-keeper-${version}-render.yaml"; then
      echo "[FAIL] Keeper ${version} chart did not render expected PodTemplate name" >&2
      return 1
    fi
  done
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
