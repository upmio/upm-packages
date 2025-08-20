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
readonly EXIT_HTTP_REQUEST_FAILED=43
readonly EXIT_FLAG_FILE_CREATION_FAILED=51

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

decrypt_pwd() {
  local func_name="decrypt_pwd"
  local username="${1}"
  local enc_in="/tmp/${username}-ciphertext.bin"

  # Clean up temporary file on exit
  trap 'rm -f "${enc_in}"' RETURN

  [[ -n "${username}" ]] || {
    error "${func_name}" "get username failed !"
    return "${EXIT_GENERAL_FAILURE}"
  }
  [[ -n "${SECRET_MOUNT:-}" ]] || {
    error "${func_name}" "get env SECRET_MOUNT failed !"
    return "${EXIT_MISSING_ENV_VAR}"
  }
  [[ -d "${SECRET_MOUNT}" ]] || {
    error "${func_name}" "Not found ${SECRET_MOUNT} failed !"
    return "${EXIT_DIR_NOT_FOUND}"
  }
  [[ -n "${AES_SECRET_KEY:-}" ]] || {
    error "${func_name}" "get env AES_SECRET_KEY failed !"
    return "${EXIT_MISSING_ENV_VAR}"
  }

  # Process encryption
  local enc_key
  enc_key="$(echo -n "${AES_SECRET_KEY}" | od -t x1 -An -v | tr -d ' \n')"
  local enc_type="-aes-256-ctr"

  local secret_file="${SECRET_MOUNT}/${username}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return "${EXIT_GENERAL_FAILURE}"
  }

  local enc_iv
  enc_iv=$(cat "${secret_file}" | head -c 16 | od -t x1 -An -v | tr -d ' \n')
  [[ -n "${enc_iv}" ]] || {
    error "${func_name}" "get enc_iv failed!"
    return "${EXIT_GENERAL_FAILURE}"
  }

  tail -c +17 "${secret_file}" >"${enc_in}"
  [[ -f "${enc_in}" ]] || {
    error "${func_name}" "get enc_in failed!"
    return "${EXIT_GENERAL_FAILURE}"
  }

  local decrypted_pwd
  decrypted_pwd=$(openssl enc -d ${enc_type} -in "${enc_in}" -iv "${enc_iv}" -K "${enc_key}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return "${EXIT_GENERAL_FAILURE}"
  }

  echo "${decrypted_pwd}"
}

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Validate required environment variables
  [[ -n "${MON_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "MON_USER environment variable not set!"
  local mon_pwd
  mon_pwd=$(decrypt_pwd "${MON_USER}")
  [[ -n "${mon_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${MON_USER} password failed!"

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
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir ${DATA_DIR} ${CONF_DIR} failed!"
    }

    info "${func_name}" "Initialize ProxySQL done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

  local stats_config="${CONF_DIR}/.stats.cnf"
  {
    echo "[client]"
    echo "user=stats"
    echo "host=127.0.0.1"
    echo "port=${ADMIN_PORT}"
    echo "password=${mon_pwd}"
  } >"${stats_config}"

  info "${func_instance}" "run ${func_instance} done."
}

health() {
  local func_name="health"

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"
  local admin_pwd
  admin_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${admin_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  # Health check via ProxySQL admin interface
  local health_check_sql="SELECT 1 AS health_check"
  local result

  result=$(mysql --user="${ADM_USER}" --password="${admin_pwd}" --host="localhost" --port="${ADMIN_PORT}" --silent --skip-column-names --execute="${health_check_sql}") || {
    die "${EXIT_HTTP_REQUEST_FAILED}" "${func_name}" "ProxySQL admin interface health check failed!"
  }

  if [[ "${result}" != "1" ]]; then
    die "${EXIT_HTTP_REQUEST_FAILED}" "${func_name}" "ProxySQL health check returned unexpected result: ${result}"
  fi

  # Additional health checks
  local stats_check_sql="SELECT COUNT(*) AS server_count FROM mysql_servers"
  local server_count

  server_count=$(mysql --user="${ADM_USER}" --password="${admin_pwd}" --host="localhost" --port="${ADMIN_PORT}" --silent --skip-column-names --execute="${stats_check_sql}") || {
    error "${func_name}" "Failed to check server count, but basic health check passed"
    return 0
  }

  info "${func_name}" "ProxySQL is healthy with ${server_count} backend servers configured"
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
  ADMIN_PORT=${ADMIN_PORT:-6032}

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
