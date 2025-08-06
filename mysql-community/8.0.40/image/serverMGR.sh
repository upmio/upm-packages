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

decrypt_pwd() {
  local func_name="decrypt_pwd"
  local enc_in="/tmp/${1}-ciphertext.bin"

  # Clean up temporary file on exit
  trap 'rm -f "${enc_in}"' RETURN

  local username="${1}"
  [[ -n "${username}" ]] || {
    error "${func_name}" "get username failed !"
    return 2
  }

  [[ -n "${SECRET_MOUNT:-}" ]] || {
    error "${func_name}" "get env SECRET_MOUNT failed !"
    return 2
  }

  [[ -d "${SECRET_MOUNT}" ]] || {
    error "${func_name}" "Not found ${SECRET_MOUNT} failed !"
    return 2
  }

  [[ -n "${AES_SECRET_KEY:-}" ]] || {
    error "${func_name}" "get env AES_SECRET_KEY failed !"
    return 2
  }

  local enc_key
  enc_key="$(echo -n "${AES_SECRET_KEY}" | od -t x1 -An -v | tr -d ' \n')"
  local enc_type="-aes-256-ctr"

  local secret_file="${SECRET_MOUNT}/${username}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return 2
  }

  local enc_iv
  enc_iv=$(cat "${secret_file}" | head -c 16 | od -t x1 -An -v | tr -d ' \n')
  [[ -n "${enc_iv}" ]] || {
    error "${func_name}" "get enc_iv failed!"
    return 2
  }

  tail -c +17 "${secret_file}" >"${enc_in}"
  [[ -f "${enc_in}" ]] || {
    error "${func_name}" "get enc_in failed!"
    return 2
  }

  local decrypted_pwd
  decrypted_pwd=$(openssl enc -d ${enc_type} -in "${enc_in}" -iv "${enc_iv}" -K "${enc_key}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return 2
  }

  echo "${decrypted_pwd}"
}

get_mysql_auth_method() {
  local func_name="get_mysql_auth_method"

  [[ -n "${UNIT_APP_VERSION:-}" ]] || {
    error "${func_name}" "UNIT_APP_VERSION environment variable not set!"
    return 2
  }

  local version="${UNIT_APP_VERSION}"

  if [[ "${version}" =~ ^8\.0\. ]]; then
    echo "mysql_native_password"
  elif [[ "${version}" =~ ^8\.[4-9]\. ]] || [[ "${version}" =~ ^[9-9]\. ]]; then
    echo "caching_sha2_password"
  else
    error "${func_name}" "Unsupported MySQL version: ${version}"
    return 2
  fi
}

admin_user_login() {
  local func_name="admin_user_login"

  [[ -n "${ADM_USER:-}" ]] || die 41 "${func_name}" "ADM_USER environment variable not set!"
  ADM_PWD=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${ADM_PWD}" ]] || die 42 "${func_name}" "get ${ADM_USER} password failed!"

  mysql --defaults-file="${CONF_DIR}/mysql.cnf" '-u'"${ADM_USER}"'' '-p'"${ADM_PWD}"''
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  # Get environment variables
  [[ -n "${ADM_USER:-}" ]] || die 41 "${func_name}" "ADM_USER environment variable not set!"
  ADM_PWD=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${ADM_PWD}" ]] || die 42 "${func_name}" "get ${ADM_USER} password failed!"

  [[ -n "${MON_USER:-}" ]] || die 43 "${func_name}" "MON_USER environment variable not set!"
  MON_PWD=$(decrypt_pwd "${MON_USER}")
  [[ -n "${MON_PWD}" ]] || die 44 "${func_name}" "get ${MON_USER} password failed!"

  [[ -n "${REPL_USER:-}" ]] || die 45 "${func_name}" "REPL_USER environment variable not set!"
  REPL_PWD=$(decrypt_pwd "${REPL_USER}")
  [[ -n "${REPL_PWD}" ]] || die 46 "${func_name}" "get ${REPL_USER} password failed!"

  [[ -n "${PROV_USER:-}" ]] || die 47 "${func_name}" "PROV_USER environment variable not set!"
  PROV_PWD=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${PROV_PWD}" ]] || die 48 "${func_name}" "get ${PROV_USER} password failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${TMP_DIR}" "${BIN_LOG_DIR}" "${RELAY_LOG_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${TMP_DIR} ${BIN_LOG_DIR} ${RELAY_LOG_DIR} ${CONF_DIR} failed!"
      }
    fi
    mkdir -p "${DATA_DIR}" "${TMP_DIR}" "${BIN_LOG_DIR}" "${RELAY_LOG_DIR}" "${CONF_DIR}" || {
      die 42 "${func_name}" "mkdir ${DATA_DIR} ${TMP_DIR} ${BIN_LOG_DIR} ${RELAY_LOG_DIR} ${CONF_DIR} failed!"
    }

    if [[ "${ARCH_MODE}" == "group_replication" ]]; then
      local init_sql="/tmp/init_${random}.sql"
      local auth_method
      auth_method=$(get_mysql_auth_method) || {
        die 43 "${func_name}" "Failed to determine MySQL authentication method!"
      }
      {
        echo "SET @@SESSION.SQL_LOG_BIN=0;"
        echo "INSTALL PLUGIN group_replication SONAME 'group_replication.so';"
        echo "INSTALL PLUGIN clone SONAME 'mysql_clone.so';"
        echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH ${auth_method} BY '${ADM_PWD}';"
        echo "UPDATE mysql.user SET user='${ADM_USER}' WHERE user='root' AND host='localhost';"
        echo "CREATE USER '${MON_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${MON_PWD}';"
        echo "GRANT USAGE, PROCESS, REPLICATION CLIENT, REPLICATION SLAVE, SELECT ON *.* TO '${MON_USER}'@'%';"
        echo "GRANT SELECT ON mysql.user TO '${MON_USER}'@'%';"
        echo "CREATE USER '${REPL_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${REPL_PWD}';"
        echo "GRANT REPLICATION CLIENT, REPLICATION SLAVE, SYSTEM_VARIABLES_ADMIN, REPLICATION_SLAVE_ADMIN, GROUP_REPLICATION_ADMIN, RELOAD, BACKUP_ADMIN, CLONE_ADMIN ON *.* TO '${REPL_USER}'@'%';"
        echo "GRANT SELECT ON performance_schema.* TO '${REPL_USER}'@'%';"
        echo "DROP DATABASE IF EXISTS test;"
        echo "CREATE USER '${PROV_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${PROV_PWD}';"
        echo "GRANT ALL PRIVILEGES ON *.* TO '${PROV_USER}'@'%' WITH GRANT OPTION;"
        echo "DELETE FROM mysql.user WHERE User='';"
        echo "DELETE FROM mysql.user WHERE authentication_string='';"
        echo "FLUSH PRIVILEGES;"
      } >"${init_sql}"
    else
      local init_sql="/tmp/init_${random}.sql"
      local auth_method
      auth_method=$(get_mysql_auth_method) || {
        die 44 "${func_name}" "Failed to determine MySQL authentication method!"
      }
      {
        echo "SET @@SESSION.SQL_LOG_BIN=0;"
        echo "INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.so';"
        echo "INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.so';"
        echo "INSTALL PLUGIN clone SONAME 'mysql_clone.so';"
        echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH ${auth_method} BY '${ADM_PWD}';"
        echo "UPDATE mysql.user SET user='${ADM_USER}' WHERE user='root' AND host='localhost';"
        echo "CREATE USER '${MON_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${MON_PWD}';"
        echo "GRANT USAGE, PROCESS, REPLICATION CLIENT, REPLICATION SLAVE, SELECT ON *.* TO '${MON_USER}'@'%';"
        echo "GRANT SELECT ON mysql.user TO '${MON_USER}'@'%';"
        echo "CREATE USER '${REPL_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${REPL_PWD}';"
        echo "GRANT REPLICATION CLIENT, REPLICATION SLAVE, SYSTEM_VARIABLES_ADMIN, REPLICATION_SLAVE_ADMIN, GROUP_REPLICATION_ADMIN, RELOAD, BACKUP_ADMIN, CLONE_ADMIN ON *.* TO '${REPL_USER}'@'%';"
        echo "GRANT SELECT ON performance_schema.* TO '${REPL_USER}'@'%';"
        echo "DROP DATABASE IF EXISTS test;"
        echo "CREATE USER '${PROV_USER}'@'%' IDENTIFIED WITH ${auth_method} BY '${PROV_PWD}';"
        echo "GRANT ALL PRIVILEGES ON *.* TO '${PROV_USER}'@'%' WITH GRANT OPTION;"
        echo "DELETE FROM mysql.user WHERE User='';"
        echo "DELETE FROM mysql.user WHERE authentication_string='';"
        echo "FLUSH PRIVILEGES;"
      } >"${init_sql}"
    fi

    local init_config="/tmp/init_${random}.cnf"
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
      die 45 "${func_name}" "Initialize mysqld failed!"
    }

    info "${func_name}" "Initialize mysql done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 47 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }

  local mon_config="${CONF_DIR}/.monitor.cnf"
  {
    echo "[client]"
    echo "user=${MON_USER}"
    echo "password=${MON_PWD}"
    echo "host=${POD_NAME}"
    echo "port=${MYSQL_PORT}"
  } >"${mon_config}"

  info "${func_name}" "run ${func_name} done."
}

# ##############################################################################
# The main() function is called at the action function.
# ##############################################################################
main() {
  local func_name="main"
  local action="${1}"
  shift

  case "${action}" in
  "initialize")
    initialize
    ;;
  "login")
    admin_user_login
    ;;
  *)
    die 21 "${func_name}" "service action(${action}) nonsupport"
    ;;
  esac
}

[[ -v DATA_MOUNT ]] || die 10 "Globals" "get env DATA_MOUNT failed !"
[[ -d ${DATA_MOUNT} ]] || die 11 "Globals" "Not found DATA_MOUNT !"
INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
[[ -v DATA_DIR ]] || die 10 "Globals" "get env DATA_DIR failed !"
[[ -v CONF_DIR ]] || die 10 "Globals" "get env CONF_DIR failed !"
[[ -v TMP_DIR ]] || die 10 "Globals" "get env TMP_DIR failed !"
[[ -v BIN_LOG_DIR ]] || die 10 "Globals" "get env BIN_LOG_DIR failed !"
[[ -v RELAY_LOG_DIR ]] || die 10 "Globals" "get env RELAY_LOG_DIR failed !"
[[ -v LOG_MOUNT ]] || die 10 "Globals" "get env LOG_MOUNT failed !"
[[ -d ${LOG_MOUNT} ]] || die 11 "Globals" "Not found LOG_MOUNT !"
[[ -v MYSQL_PORT ]] || die 10 "Globals" "get env MYSQL_PORT failed !"
[[ -v POD_NAME ]] || die 10 "Globals" "get env POD_NAME failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
