#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# ##############################################################################
# Global Constants and Configuration
# ##############################################################################
readonly SCRIPT_VERSION="v1.0.0"
readonly POSIXLY_CORRECT=1
export POSIXLY_CORRECT
export LANG=C

# ##############################################################################
# Exit Code Conventions
# ##############################################################################
# 1-9: General system errors
# 10-19: Environment validation errors
# 20-29: Argument/usage errors
# 30-39: Network/communication errors
# 40-49: Filesystem/permission errors
# 50-59: Database operation errors
# 60-69: Configuration errors
# 70-79: Process management errors
# 80-89: Resource allocation errors
# 90-99: Unknown/unexpected errors

# Exit code definitions:
readonly EXIT_GENERAL_FAILURE=2
readonly EXIT_MISSING_ENV_VAR=10
readonly EXIT_DIR_NOT_FOUND=11
readonly EXIT_UNSUPPORTED_ACTION=21
readonly EXIT_DIR_REMOVAL_FAILED=41
readonly EXIT_DIR_CREATION_FAILED=42
readonly EXIT_FLAG_FILE_CREATION_FAILED=47
readonly EXIT_MEMORY_LIMIT_INVALID=49

# ##############################################################################
# Common Functions
# ##############################################################################
die() {
  local exit_code="${1}"
  shift
  local function_name="${1}"
  shift
  error "${function_name}" "$*"
  exit "${exit_code}"
}

error() {
  local function_name="${1}"
  shift
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"

  echo "[${timestamp}] ERR | (${SCRIPT_VERSION})[${function_name}]: $* ;"
}

info() {
  local function_name="${1}"
  shift
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"

  echo "[${timestamp}] INFO| (${SCRIPT_VERSION})[${function_name}]: $* ;"
}

health() {
  local func_name="health"

  # Check if Kafka process is running
  if pgrep -f "kafka.Kafka" >/dev/null; then
    info "${func_name}" "Kafka process is running"

    KAFKA_PORT="${KAFKA_PORT:-9094}"

    # Check Kafka port availability
    if timeout 5 bash -c "</dev/tcp/localhost/${KAFKA_PORT}" 2>/dev/null; then
      info "${func_name}" "Kafka port ${KAFKA_PORT} is accessible"
    else
      die "${EXIT_GENERAL_FAILURE}" "${func_name}" "Kafka port ${KAFKA_PORT} is not accessible"
    fi

    # Check Kafka broker health using kafka-broker-api-versions if available
    if command -v kafka-broker-api-versions >/dev/null 2>&1; then
      if kafka-broker-api-versions --bootstrap-server localhost:"${KAFKA_PORT}" >/dev/null 2>&1; then
        info "${func_name}" "Kafka broker API is responding"
      else
        die "${EXIT_GENERAL_FAILURE}" "${func_name}" "Kafka broker API is not responding"
      fi
    fi

    info "${func_name}" "Kafka health check passed"
  else
    die "${EXIT_GENERAL_FAILURE}" "${func_name}" "Kafka process is not running"
  fi
}

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Check if already initialized
  if [[ ! -f "${INIT_FLAG_FILE}" ]]; then
    # Handle force clean option
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    # Create required directories
    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || {
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir dir failed!"
    }

    info "${func_name}" "Initialize kafka done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

  # Validate and configure memory settings
  [[ -n "${KAFKA_MEMORY_LIMIT:-}" ]] || {
    die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env KAFKA_MEMORY_LIMIT failed !"
  }
  [[ ${KAFKA_MEMORY_LIMIT} -gt 0 ]] || {
    die "${EXIT_MEMORY_LIMIT_INVALID}" "${func_name}" "KAFKA_MEMORY_LIMIT(${KAFKA_MEMORY_LIMIT}) invalid !"
  }

  local memory_half=$((KAFKA_MEMORY_LIMIT / 2))

  # Create Kafka environment configuration
  cat >"${CONF_DIR}/env.sh" <<EOF
export KAFKA_HEAP_OPTS="-Xmx${memory_half}m -Xms${memory_half}m"
export KAFKA_JVM_PERFORMANCE_OPTS="-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -XX:MaxInlineLevel=15 -Djava.awt.headless=true"
EOF

  info "${func_instance}" "run ${func_instance} done."
}

# ##############################################################################
# The main() function is called at the action function.
# ##############################################################################
main() {
  local func_name="main"
  local action="${1:-}"

  case "${action}" in
  "initialize")
    initialize
    ;;
  "health")
    health
    ;;
  *)
    die "${EXIT_UNSUPPORTED_ACTION}" "${func_name}" "service action(${action}) nonsupport"
    ;;
  esac
}

# ##############################################################################
# Global Environment Validation
# ##############################################################################
validate_environment() {
  local func_name="validate_environment"

  # Validate required environment variables
  [[ -n "${DATA_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env DATA_MOUNT failed !"
  [[ -d ${DATA_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found DATA_MOUNT !"
  [[ -n "${DATA_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env DATA_DIR failed !"
  [[ -n "${CONF_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env CONF_DIR failed !"
  [[ -n "${LOG_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env LOG_MOUNT failed !"
  [[ -d ${LOG_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found LOG_MOUNT !"

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
