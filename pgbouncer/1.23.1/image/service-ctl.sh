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
readonly EXIT_PGBouncer_INIT_FAILED=45
readonly EXIT_FLAG_FILE_CREATION_FAILED=47
readonly EXIT_CONFIG_FILE_FAILED=49

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

admin_user_login() {
  local func_name="admin_user_login"

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"

  local adm_pwd
  adm_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${adm_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  PGPASSWORD="${adm_pwd}" psql -U "${ADM_USER}" "-p${PGBOUNCER_PORT}" '-h127.0.0.1' pgbouncer
}

health() {
  local func_name="health"

  # Check if PgBouncer process is running
  if pgrep -f "pgbouncer" >/dev/null; then
    info "${func_name}" "PgBouncer process is running"

    # Test connectivity to PgBouncer
    if [[ -n "${ADM_USER:-}" ]]; then
      local adm_pwd
      adm_pwd=$(decrypt_pwd "${ADM_USER}")
      if [[ -n "${adm_pwd}" ]]; then
        if PGPASSWORD="${adm_pwd}" psql -U "${ADM_USER}" "-p${PGBOUNCER_PORT}" '-h127.0.0.1' pgbouncer -c "SHOW VERSION;" >/dev/null 2>&1; then
          info "${func_name}" "PgBouncer connectivity test successful"
          return 0
        else
          error "${func_name}" "PgBouncer connectivity test failed"
          return 1
        fi
      else
        error "${func_name}" "Failed to decrypt admin password"
        return 1
      fi
    else
      info "${func_name}" "ADM_USER not set, skipping connectivity test"
      return 0
    fi
  else
    error "${func_name}" "PgBouncer process is not running"
    return 1
  fi
}

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"
  local adm_pwd
  adm_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${adm_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  [[ -n "${POSTGRESQL_SERVICE_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "POSTGRESQL_SERVICE_NAME environment variable not set!"
  POSTGRESQL_PORT="${POSTGRESQL_PORT:-5432}"

  # Check if initialization is needed
  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN:-false}" == "true" ]]; then
      info "${func_name}" "Force clean enabled, removing existing data..."
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    # Create necessary directories
    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir dir failed!"

    info "${func_name}" "Initialize pgbouncer done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f "${INIT_FLAG_FILE}" ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }

  # Check PostgreSQL service connectivity
  local pg_host="${POSTGRESQL_SERVICE_NAME}-replication-readwrite"

  info "${func_name}" "Testing connectivity to PostgreSQL service at ${pg_host}:${POSTGRESQL_PORT}..."
  if ! PGPASSWORD="${adm_pwd}" psql -U "${ADM_USER}" "-p${POSTGRESQL_PORT}" "-h${pg_host}" postgres -c "SELECT 1;" >/dev/null 2>&1; then
    error "${func_name}" "connect to postgres service failed!"
    return "${EXIT_PGBouncer_INIT_FAILED}"
  fi
  info "${func_name}" "connect to postgres service done!"

  # Create userlist.txt for PgBouncer authentication
  local adm_passwd_md5
  adm_passwd_md5="$(
    echo -n "md5"
    echo -n "${adm_pwd}${ADM_USER}" | md5sum | awk '{print $1}'
  )"

  local userlist_txt="${DATA_MOUNT}/userlist.txt"
  {
    echo "\"${ADM_USER}\" \"${adm_passwd_md5}\""
  } >"${userlist_txt}" || die "${EXIT_CONFIG_FILE_FAILED}" "${func_name}" "create ${userlist_txt} failed!"

  info "${func_name}" "run ${func_name} done."
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
  "login")
    admin_user_login
    ;;
  *)
    die "${EXIT_UNSUPPORTED_ACTION}" "${func_name}" "action(${action}) nonsupport"
    ;;
  esac
}

validate_environment() {
  local func_name="validate_environment"
  [[ -n "${DATA_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env DATA_MOUNT failed !"
  [[ -d ${DATA_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found DATA_MOUNT !"
  [[ -n "${DATA_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env DATA_DIR failed !"
  [[ -n "${CONF_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env CONF_DIR failed !"
  [[ -n "${LOG_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env LOG_MOUNT failed !"
  [[ -d ${LOG_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found LOG_MOUNT !"
  PGBOUNCER_PORT="${PGBOUNCER_PORT:-6432}"

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

validate_environment
main "$@"
