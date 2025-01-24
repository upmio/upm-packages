#!/usr/bin/env bash

set -o nounset
# ##############################################################################
# Globals, settings
# ##############################################################################
POSIXLY_CORRECT=1
export POSIXLY_CORRECT
LANG=C

VERSION="v1.6.6"

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

get_pwd() {
  local func_name="get_pwd"

  [[ -v SECRET_MOUNT ]] || {
    error "${func_name}" "get env SECRET_MOUNT failed !"
    return 2
  }

  [[ -d ${SECRET_MOUNT} ]] || {
    error "${func_name}" "Not found ${SECRET_MOUNT} failed !"
    return 2
  }

  # echo -n "password" | od -A n -t x1 | tr -d ' '
  local enc_key="3765323063323065613735363432333161373664643833616331636637303133"
  local enc_iv="66382f4e654c734a2a732a7679675640"
  local enc_type="-aes-256-cbc"

  local secret_file="${SECRET_MOUNT}/${ADM_USER}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return 2
  }
  local enc_base64
  enc_base64="$(cat "${secret_file}")" || {
    error "${func_name}" "get enc_base64 failed!"
    return 2
  }
  export ADM_PWD
  ADM_PWD=$(printf "%s\n" "${enc_base64}" | openssl enc -d "${enc_type}" -base64 -K "${enc_key}" -iv "${enc_iv}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return 2
  }

  local secret_file="${SECRET_MOUNT}/${MON_USER}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return 2
  }
  local enc_base64
  enc_base64="$(cat "${secret_file}")" || {
    error "${func_name}" "get enc_base64 failed!"
    return 2
  }
  export MON_PWD
  MON_PWD=$(printf "%s\n" "${enc_base64}" | openssl enc -d "${enc_type}" -base64 -K "${enc_key}" -iv "${enc_iv}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return 2
  }

  local secret_file="${SECRET_MOUNT}/${REPL_USER}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return 2
  }
  local enc_base64
  enc_base64="$(cat "${secret_file}")" || {
    error "${func_name}" "get enc_base64 failed!"
    return 2
  }
  export REPL_PWD
  REPL_PWD=$(printf "%s\n" "${enc_base64}" | openssl enc -d "${enc_type}" -base64 -K "${enc_key}" -iv "${enc_iv}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return 2
  }

  local secret_file="${SECRET_MOUNT}/${PROV_USER}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return 2
  }
  local enc_base64
  enc_base64="$(cat "${secret_file}")" || {
    error "${func_name}" "get enc_base64 failed!"
    return 2
  }
  export PROV_PWD
  PROV_PWD=$(printf "%s\n" "${enc_base64}" | openssl enc -d "${enc_type}" -base64 -K "${enc_key}" -iv "${enc_iv}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return 2
  }
}

admin_user_login() {
  local func_name="admin_user_login"

  get_pwd || die 41 "${func_name}" "get ${ADM_USER} password failed!"

  mysql --defaults-file="${CONF_DIR}/mysql.cnf" '-u'"${ADM_USER}"'' '-p'"${ADM_PWD}"''
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  get_pwd || die 44 "${func_name}" "get password failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${TMP_DIR}" "${BIN_LOG_DIR}" "${RELAY_LOG_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${TMP_DIR} ${BIN_LOG_DIR} ${RELAY_LOG_DIR} ${CONF_DIR} failed!"
      }
    fi
    mkdir -p "${DATA_DIR}" "${TMP_DIR}" "${BIN_LOG_DIR}" "${RELAY_LOG_DIR}" "${CONF_DIR}" || {
      die 42 "${func_name}" "mkdir ${DATA_DIR} ${TMP_DIR} ${BIN_LOG_DIR} ${RELAY_LOG_DIR} ${CONF_DIR} failed!"
    }
    chown -R "mysql.mysql" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
      die 43 "${func_name}" "chown dir failed!"
    }

    local init_sql="/tmp/init_${random}.sql"
    {
      echo "SET @@SESSION.SQL_LOG_BIN=0;"
      echo "INSTALL PLUGIN rpl_semi_sync_source SONAME 'semisync_source.so';"
      echo "INSTALL PLUGIN rpl_semi_sync_replica SONAME 'semisync_replica.so';"
      echo "INSTALL PLUGIN group_replication SONAME 'group_replication.so';"
      echo "INSTALL PLUGIN clone SONAME 'mysql_clone.so';"
      echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ADM_PWD}';"
      echo "UPDATE mysql.user SET user='${ADM_USER}' WHERE user='root' AND host='localhost';"
      echo "CREATE USER '${MON_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${MON_PWD}';"
      echo "GRANT USAGE, PROCESS, REPLICATION CLIENT, REPLICATION SLAVE, SELECT ON *.* TO '${MON_USER}'@'%';"
      echo "GRANT SELECT ON mysql.user TO '${MON_USER}'@'%';"
      echo "CREATE USER '${REPL_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${REPL_PWD}';"
      echo "GRANT REPLICATION CLIENT, REPLICATION SLAVE, SYSTEM_VARIABLES_ADMIN, REPLICATION_SLAVE_ADMIN, GROUP_REPLICATION_ADMIN, RELOAD, BACKUP_ADMIN, CLONE_ADMIN ON *.* TO '${REPL_USER}'@'%';"
      echo "GRANT SELECT ON performance_schema.* TO '${REPL_USER}'@'%';"
      echo "DROP DATABASE IF EXISTS test;"
      echo "CREATE USER '${PROV_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${PROV_PWD}';"
      echo "GRANT ALL PRIVILEGES ON *.* TO '${PROV_USER}'@'%' WITH GRANT OPTION;"
      echo "DELETE FROM mysql.user WHERE User='';"
      echo "DELETE FROM mysql.user WHERE authentication_string='';"
      echo "FLUSH PRIVILEGES;"
    } >"${init_sql}"

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

  chown -R "mysql.mysql" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
    die 46 "${func_name}" "chown dir failed!"
  }

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
[[ -v ADM_USER ]] || die 10 "Globals" "get env ADM_USER failed !"
[[ -v MON_USER ]] || die 10 "Globals" "get env MON_USER failed !"
[[ -v REPL_USER ]] || die 10 "Globals" "get env REPL_USER failed !"
[[ -v PROV_USER ]] || die 10 "Globals" "get env PROV_USER failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
