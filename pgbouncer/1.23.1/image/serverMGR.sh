#!/usr/bin/env bash

set -o nounset
# ##############################################################################
# Globals, settings
# ##############################################################################
POSIXLY_CORRECT=1
export POSIXLY_CORRECT
LANG=C

VERSION="v1.6.9"

# ##############################################################################
# function package
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
}

admin_user_login() {
  local func_name="user_login"

  get_pwd || die 41 "${func_name}" "get admin password failed!"

  PGPASSWORD="${ADM_PWD}" psql -U "${ADM_USER}" "-p${PGBOUNCER_PORT}" '-h127.0.0.1' pgbouncer
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  get_pwd || die 40 "${func_name}" "get pwd failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi
    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || die 42 "${func_name}" "mkdir dir failed!"

    info "${func_name}" "Initialize pgbouncer done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 43 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }

  # check postgres service connectivity
  local pg_host="${POSTGRESQL_SERVICE_NAME}-replication-readwrite"
  local pg_port="${POSTGRESQL_PORT}"

  PGPASSWORD="${ADM_PWD}" psql -U "${ADM_USER}" "-p${pg_port}" "-h${pg_host}" postgres -c "SELECT 1" || {
    die 44 "${func_name}" "connect to postgres service failed!"
  }
  info "${func_name}" "connect to postgres service done!"

  local adm_passwd_md5
  adm_passwd_md5="$(
    echo -n "md5"
    echo -n "${ADM_PWD}${ADM_USER}" | md5sum | awk '{print $1}'
  )"

  local userlist_txt="${DATA_MOUNT}/userlist.txt"
  {
    echo "\"${ADM_USER}\" \"${adm_passwd_md5}\""
  } >"${userlist_txt}" || die 45 "${func_name}" "create ${userlist_txt} failed!"

  info "${func_name}" "run ${func_name} done."
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
  "login")
    admin_user_login
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
[[ -v ADM_USER ]] || die 10 "Globals" "get env ADM_USER failed !"
[[ -v PGBOUNCER_PORT ]] || die 10 "Globals" "get env PGBOUNCER_PORT failed !"
[[ -v POSTGRESQL_SERVICE_NAME ]] || die 10 "Globals" "get env POSTGRESQL_SERVICE_NAME failed !"
[[ -v POSTGRESQL_PORT ]] || die 10 "Globals" "get env POSTGRESQL_PORT failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
