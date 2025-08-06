#!/usr/bin/env bash

set -o nounset
# ##############################################################################
# Globals, settings
# ##############################################################################
POSIXLY_CORRECT=1
export POSIXLY_CORRECT
LANG=C

VERSION="v2.0.0"

# ##############################################################################
# common function package
# ##############################################################################
die() {
  local status="${1}"
  shift
  local function_name="${1}"
  shift
  error "${function_name}" "$*"
  exit "$status"
}

error() {
  local function_name="${1}"
  shift
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"

  echo "[${timestamp}] ERR | (${VERSION})[${function_name}]: $* ;"
}

info() {
  local function_name="${1}"
  shift
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"

  echo "[${timestamp}] INFO| (${VERSION})[${function_name}]: $* ;"
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi
    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || {
      die 43 "${func_name}" "mkdir dir failed!"
    }

    chown -R "1001.1001" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
      die 44 "${func_name}" "chown dir failed!"
    }

    info "${func_name}" "Initialize kafka done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 47 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }

  # Check that the KAFKA_MEMORY_LIMIT variable exists and its value is greater than 0
  [[ -v KAFKA_MEMORY_LIMIT ]] || {
    die 10 "${func_name}" "get env KAFKA_MEMORY_LIMIT failed !"
  }
  [[ ${KAFKA_MEMORY_LIMIT} -gt 0 ]] || {
    die 11 "${func_name}" "KAFKA_MEMORY_LIMIT(${KAFKA_MEMORY_LIMIT}) invalid !"
  }

  local memory_half=$((KAFKA_MEMORY_LIMIT / 2))

  cat >"${CONF_DIR}/env.sh" <<EOF
export KAFKA_HEAP_OPTS="-Xmx${memory_half}m -Xms${memory_half}m"
EOF
}

# ##############################################################################
# The main() function is called at the action function.
# ##############################################################################
main() {
  local func_name="main"
  local action="${1}"

  case "${action}" in
  "initialize")
    initialize
    ;;
  *)
    die 21 "${func_name}" "action(${action}) nonsupport"
    ;;
  esac
}

[[ -v DATA_MOUNT ]] || die 10 "Globals" "get env DATA_MOUNT failed !"
[[ -d ${DATA_MOUNT} ]] || die 11 "Globals" "Not found DATA_MOUNT !"
INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
[[ -v DATA_DIR ]] || die 10 "Globals" "get env DATA_DIR failed !"
[[ -v CONF_DIR ]] || die 10 "Globals" "get env CONF_DIR failed !"
[[ -v LOG_MOUNT ]] || die 10 "Globals" "get env LOG_MOUNT failed !"
[[ -d ${LOG_MOUNT} ]] || die 11 "Globals" "Not found LOG_MOUNT !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
