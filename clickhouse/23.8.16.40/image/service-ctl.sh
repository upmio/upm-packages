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

decrypt_admin_password() {
  local function_name="decrypt_admin_password"
  require_env ADM_USER "$function_name"
  require_env SECRET_MOUNT "$function_name"
  require_env AES_SECRET_KEY "$function_name"

  local secret_file="${SECRET_MOUNT}/${ADM_USER}"
  [[ -f "$secret_file" ]] || die "$EXIT_MISSING_ENV_VAR" "$function_name" "${secret_file} not found"

  local aes_key iv
  aes_key="$(printf %s "$AES_SECRET_KEY" | od -t x1 -An -v | tr -d ' ')"
  iv="$(head -c 16 "$secret_file" | od -t x1 -An -v | tr -d ' ')"
  tail -c +17 "$secret_file" | openssl enc -d -aes-256-ctr -K "$aes_key" -iv "$iv" 2>/dev/null
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
  local password
  password="$(decrypt_admin_password)"
  CLICKHOUSE_PASSWORD="$password" clickhouse-client --host 127.0.0.1 --port "${CLICKHOUSE_TCP_PORT:-9000}" --user "$ADM_USER" --query "SELECT 1" >/dev/null
}

login() {
  local password
  password="$(decrypt_admin_password)"
  CLICKHOUSE_PASSWORD="$password" clickhouse-client --host 127.0.0.1 --port "${CLICKHOUSE_TCP_PORT:-9000}" --user "$ADM_USER"
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
