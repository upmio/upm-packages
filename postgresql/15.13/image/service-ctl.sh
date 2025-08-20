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
readonly EXIT_POSTGRES_INIT_FAILED=45
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

  PGPASSWORD="${adm_pwd}" psql -U postgres -h "${POD_NAME}" -p "${POSTGRESQL_PORT}"
}

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Validate required environment variables and get passwords
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"
  local adm_pwd
  adm_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${adm_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  [[ -n "${MON_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "MON_USER environment variable not set!"
  local mon_pwd
  mon_pwd=$(decrypt_pwd "${MON_USER}")
  [[ -n "${mon_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${MON_USER} password failed!"

  [[ -n "${REPL_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "REPL_USER environment variable not set!"
  local repl_pwd
  repl_pwd=$(decrypt_pwd "${REPL_USER}")
  [[ -n "${repl_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${REPL_USER} password failed!"

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

    # Initialize PostgreSQL database
    info "${func_name}" "Starting initialize postgresql !"
    initdb --data-checksums --pgdata="${DATA_DIR}" -A md5 --pwfile=<(echo "${adm_pwd}") || {
      die "${EXIT_POSTGRES_INIT_FAILED}" "${func_name}" "initdb failed!"
    }

    # Create PostgreSQL configuration
    cat <<EOF >"${CONF_DIR}/pg_hba.conf" || die "${EXIT_CONFIG_FILE_FAILED}" "${func_name}" "create pg_hba.conf failed!"
host     all             all             0.0.0.0/0               md5
host     all             all             ::/0                    md5
local    all             all                                     md5
host     replication     ${REPL_USER}    0.0.0.0/0               md5
host     all             ${MON_USER}     0.0.0.0/0               md5
EOF

    # Create replication and monitoring users
    postgres --single -D "${DATA_DIR}" postgres <<EOF || die "${EXIT_POSTGRES_INIT_FAILED}" "${func_name}" "create users failed!"
CREATE ROLE ${REPL_USER} WITH REPLICATION PASSWORD '${repl_pwd}' LOGIN;
CREATE ROLE ${MON_USER} WITH LOGIN PASSWORD '${mon_pwd}' CONNECTION LIMIT 5 IN ROLE pg_monitor;
EOF

    info "${func_name}" "Initialize postgresql done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

  # Create monitoring configuration
  local mon_config="${CONF_DIR}/.monitor.cnf"
  {
    echo "[client]"
    echo "user=${MON_USER}"
    echo "password=${mon_pwd}"
    echo "host=${POD_NAME}"
    echo "port=${POSTGRESQL_PORT}"
  } >"${mon_config}" || {
    die "${EXIT_CONFIG_FILE_FAILED}" "${func_name}" "create monitoring config failed!"
  }

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
  "login")
    admin_user_login
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
  [[ -n "${POD_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env POD_NAME failed !"
  POSTGRESQL_PORT="${POSTGRESQL_PORT:-5432}"

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
