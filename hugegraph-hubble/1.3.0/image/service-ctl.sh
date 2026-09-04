#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly INIT_FLAG_FILE="${DATA_MOUNT}/.hubble-config-initialized"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

initialize() {
  if [[ -f "${INIT_FLAG_FILE}" ]]; then
    return
  fi

  mkdir -p "${DATA_DIR}" "${LOG_MOUNT}" "${CONF_DIR}"
  touch "${INIT_FLAG_FILE}"
}

start() {
  [[ -f "${CONFIG_PATH}" ]] || die "rendered configuration not found: ${CONFIG_PATH}"

  # Hubble's bundled application.properties stores H2 at ./db. Running from
  # DATA_DIR keeps its connection metadata across Pod recreation, while the
  # supplied argument makes Hubble consume the unit-agent rendered config.
  cd "${DATA_DIR}"
  exec java -server -Xms512m \
    -Dhubble.home.path="${HUBBLE_HOME}" \
    -Dlogging.file="${LOG_MOUNT}/hugegraph-hubble.log" \
    -cp ".:${HUBBLE_HOME}:${HUBBLE_HOME}/lib/*" \
    org.apache.hugegraph.HugeGraphHubble "${CONFIG_PATH}"
}

health() {
  curl --fail --silent --show-error --max-time 5 http://127.0.0.1:"${HUBBLE_PORT}"/actuator/health >/dev/null
}

validate_environment() {
  : "${DATA_MOUNT:?DATA_MOUNT must be set}"
  : "${DATA_DIR:?DATA_DIR must be set}"
  : "${LOG_MOUNT:?LOG_MOUNT must be set}"
  : "${CONF_DIR:?CONF_DIR must be set}"
  : "${CONFIG_PATH:?CONFIG_PATH must be set}"
  : "${HUBBLE_PORT:?HUBBLE_PORT must be set}"
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
