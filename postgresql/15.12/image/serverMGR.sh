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
}

admin_user_login() {
  local func_name="admin_user_login"
  get_pwd || die 41 "${func_name}" "get ${ADM_USER} password failed!"

  PGPASSWORD="${ADM_PWD}" psql -U postgres
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  get_pwd || die 40 "${func_name}" "get password failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    chown -R "1001.1001" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
        die 41 "${func_name}" "chown dir failed!"
    }

    /sbin/runuser -l postgres -c "initdb --data-checksums --pgdata=${DATA_DIR} -A md5 --pwfile=<(echo \"${ADM_PWD}\")" || {
        die 42 "${func_name}" "initdb failed!"
    }

    cat <<EOF >"${DATA_DIR}/pg_hba.conf"
host     all             all             0.0.0.0/0               md5
host     all             all             ::/0                    md5
local    all             all                                     md5
host     replication     replication     0.0.0.0/0               md5
EOF

      /sbin/runuser -l postgres -c "postgres --single -D ${DATA_DIR} postgres <<EOF
CREATE ROLE replication WITH REPLICATION PASSWORD '${REPL_PWD}' LOGIN;
EOF
" || die 43 "${func_name}" "create replication user failed!"

      info "${func_name}" "Initialize postgresql done !"
      touch "${INIT_FLAG_FILE}"
      [[ -f ${INIT_FLAG_FILE} ]] || die 44 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
    }

    chown -R "1001.1001" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
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
[[ -v LOG_MOUNT ]] || die 10 "Globals" "get env LOG_MOUNT failed !"
[[ -d ${LOG_MOUNT} ]] || die 11 "Globals" "Not found LOG_MOUNT !"
[[ -v ADM_USER ]] || die 10 "Globals" "get env ADM_USER failed !"
[[ -v REPL_USER ]] || die 10 "Globals" "get env REPL_USER failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
