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
