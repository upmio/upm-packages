#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly INIT_FLAG_FILE="${DATA_MOUNT}/.hugegraph-config-initialized"
readonly STORE_FLAG_FILE="${DATA_MOUNT}/.hugegraph-store-initialized"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

initialize() {
  if [[ -f "${INIT_FLAG_FILE}" ]]; then
    return
  fi

  mkdir -p "${DATA_MOUNT}/data" "${LOG_MOUNT}" "${CONF_DIR}"
  # The server package contains static configuration files that are not
  # rendered by unit-agent. Keep a persistent copy for the graph definition.
  cp -a "${HUGEGRAPH_HOME}/conf/graphs" "${CONF_DIR}/"
  sed -i \
    -e "s|^#rocksdb.data_path=.*|rocksdb.data_path=${DATA_DIR}/rocksdb|" \
    -e "s|^#rocksdb.wal_path=.*|rocksdb.wal_path=${DATA_DIR}/rocksdb|" \
    "${CONF_DIR}/graphs/hugegraph.properties"
  touch "${INIT_FLAG_FILE}"
}

start() {
  [[ -f "${CONFIG_PATH}" ]] || die "rendered configuration not found: ${CONFIG_PATH}"

  # init-store.sh reads the rest-server.properties from the package directory.
  # Copying the agent-rendered file makes that script and the server use the
  # same RocksDB and graph paths.
  cp "${CONFIG_PATH}" "${HUGEGRAPH_HOME}/conf/rest-server.properties"
  rm -rf "${HUGEGRAPH_HOME}/logs"
  ln -s "${LOG_MOUNT}" "${HUGEGRAPH_HOME}/logs"

  if [[ ! -f "${STORE_FLAG_FILE}" ]]; then
    "${HUGEGRAPH_HOME}/bin/init-store.sh"
    touch "${STORE_FLAG_FILE}"
  fi

  exec "${HUGEGRAPH_HOME}/bin/hugegraph-server.sh" \
    "${HUGEGRAPH_HOME}/conf/gremlin-server.yaml" \
    "${HUGEGRAPH_HOME}/conf/rest-server.properties" \
    false
}

health() {
  curl --fail --silent --show-error --max-time 5 http://127.0.0.1:"${HUGEGRAPH_PORT}"/graphs >/dev/null
}

validate_environment() {
  : "${DATA_MOUNT:?DATA_MOUNT must be set}"
  : "${LOG_MOUNT:?LOG_MOUNT must be set}"
  : "${CONF_DIR:?CONF_DIR must be set}"
  : "${CONFIG_PATH:?CONFIG_PATH must be set}"
  : "${HUGEGRAPH_PORT:?HUGEGRAPH_PORT must be set}"
  [[ -d "${DATA_MOUNT}" ]] || die "DATA_MOUNT does not exist: ${DATA_MOUNT}"
  [[ -d "${LOG_MOUNT}" ]] || die "LOG_MOUNT does not exist: ${LOG_MOUNT}"
}

validate_environment

case "${1:-}" in
  initialize) initialize ;;
  start) start ;;
  health) health ;;
  *) die "unsupported action: ${1:-}" ;;
esac
