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
readonly EXIT_MYSQL_INIT_FAILED=45
readonly EXIT_FLAG_FILE_CREATION_FAILED=47
readonly EXIT_AUTH_METHOD_FAILED=48
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

get_mysql_auth_method() {
  local func_name="get_mysql_auth_method"

  # Validate required environment variables
  [[ -n "${UNIT_APP_VERSION:-}" ]] || {
    error "${func_name}" "UNIT_APP_VERSION environment variable not set!"
    return "${EXIT_MISSING_ENV_VAR}"
  }

  local version="${UNIT_APP_VERSION}"

  if [[ "${version}" =~ ^8\.0\. ]]; then
    echo "mysql_native_password"
  elif [[ "${version}" =~ ^8\.[4-9]\. ]] || [[ "${version}" =~ ^[9-9]\. ]]; then
    echo "caching_sha2_password"
  else
    error "${func_name}" "Unsupported MySQL version: ${version}"
    return "${EXIT_GENERAL_FAILURE}"
  fi
}

admin_user_login() {
  local func_name="admin_user_login"

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"
  local adm_pwd
  adm_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${adm_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  mysql --defaults-file="${CONF_DIR}/mysql.cnf" "-u${ADM_USER}" "-p${adm_pwd}"
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

  [[ -n "${PROV_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "PROV_USER environment variable not set!"
  local prov_pwd
  prov_pwd=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${prov_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${PROV_USER} password failed!"

  [[ -n "${ARCH_MODE:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ARCH_MODE environment variable not set!"
  [[ "${ARCH_MODE}" == "group_replication" || "${ARCH_MODE}" == "rpl_semi_sync" || "${ARCH_MODE}" == "rpl_async" ]] || {
    die "${EXIT_UNSUPPORTED_ACTION}" "${func_name}" "Unsupported ARCH_MODE: ${ARCH_MODE}"
  }
  [[ -n "${POD_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "POD_NAME environment variable not set!"
  MYSQL_PORT="${MYSQL_PORT:-3306}"

  # Check if already initialized
  if [[ ! -f "${INIT_FLAG_FILE}" ]]; then
    # Handle force clean option
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${TMP_DIR}" "${BIN_LOG_DIR}" "${RELAY_LOG_DIR}" "${CONF_DIR}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} ${TMP_DIR} ${BIN_LOG_DIR} ${RELAY_LOG_DIR} ${CONF_DIR} failed!"
      }
    fi

    # Create required directories
    mkdir -p "${DATA_DIR}" "${TMP_DIR}" "${BIN_LOG_DIR}" "${RELAY_LOG_DIR}" "${CONF_DIR}" || {
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir ${DATA_DIR} ${TMP_DIR} ${BIN_LOG_DIR} ${RELAY_LOG_DIR} ${CONF_DIR} failed!"
    }

    # Generate initialization SQL based on architecture mode
    local init_sql="/tmp/init_${random_id}.sql"
    local auth_method
    auth_method=$(get_mysql_auth_method) || {
      die "${EXIT_AUTH_METHOD_FAILED}" "${func_name}" "Failed to determine MySQL authentication method!"
    }

    # Common SQL setup
    {
      echo "SET @@SESSION.SQL_LOG_BIN=0;"
      echo "INSTALL PLUGIN clone SONAME 'mysql_clone.so';"
      echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH ${auth_method} BY '${adm_pwd}';"
      echo "UPDATE mysql.user SET user='${ADM_USER}' WHERE user='root' AND host='localhost';"
      echo "CREATE USER '${MON_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${mon_pwd}';"
      echo "GRANT USAGE, PROCESS, REPLICATION CLIENT, REPLICATION SLAVE, SELECT ON *.* TO '${MON_USER}'@'%';"
      echo "GRANT SELECT ON mysql.user TO '${MON_USER}'@'%';"
      echo "CREATE USER '${REPL_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${repl_pwd}';"
      echo "GRANT REPLICATION CLIENT, REPLICATION SLAVE, SYSTEM_VARIABLES_ADMIN, REPLICATION_SLAVE_ADMIN, GROUP_REPLICATION_ADMIN, RELOAD, BACKUP_ADMIN, CLONE_ADMIN ON *.* TO '${REPL_USER}'@'%';"
      echo "GRANT SELECT ON performance_schema.* TO '${REPL_USER}'@'%';"
      echo "DROP DATABASE IF EXISTS test;"
      echo "CREATE USER '${PROV_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${prov_pwd}';"
      echo "GRANT ALL PRIVILEGES ON *.* TO '${PROV_USER}'@'%' WITH GRANT OPTION;"
      echo "DELETE FROM mysql.user WHERE User='';"
      echo "DELETE FROM mysql.user WHERE authentication_string='';"
      echo "FLUSH PRIVILEGES;"
    } >"${init_sql}"

    # Architecture-specific plugins
    if [[ "${ARCH_MODE}" == "group_replication" ]]; then
      {
        echo "INSTALL PLUGIN group_replication SONAME 'group_replication.so';"
      } >>"${init_sql}"
    else
      {
        echo "INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.so';"
        echo "INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.so';"
      } >>"${init_sql}"
    fi

    # Create initialization configuration
    local init_config="/tmp/init_${random_id}.cnf"
    {
      echo "[mysqld]"
      echo "user=mysql"
      echo "datadir=${DATA_DIR}"
      echo "log_error=stderr"
      echo "log_bin=${BIN_LOG_DIR}/mysql-bin"
      echo "innodb_undo_directory=${DATA_DIR}"
      echo "innodb_data_file_path=ibdata1:1024M:autoextend"
      echo "gtid_mode=ON"
      echo "enforce_gtid_consistency=ON"
    } >"${init_config}"

    info "${func_name}" "Starting initialize mysql !"
    mysqld --defaults-file="${init_config}" --initialize-insecure --init-file="${init_sql}" || {
      die "${EXIT_MYSQL_INIT_FAILED}" "${func_name}" "Initialize mysqld failed!"
    }

    info "${func_name}" "Initialize mysql done !"
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
    echo "port=${MYSQL_PORT}"
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
  [[ -n "${TMP_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env TMP_DIR failed !"
  [[ -n "${BIN_LOG_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env BIN_LOG_DIR failed !"
  [[ -n "${RELAY_LOG_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env RELAY_LOG_DIR failed !"
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
