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

admin_user_login() {
  local func_name="admin_user_login"

  [[ -n "${ADM_USER:-}" ]] || die 41 "${func_name}" "ADM_USER environment variable not set!"
  ADM_PWD=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${ADM_PWD}" ]] || die 42 "${func_name}" "get ${ADM_USER} password failed!"

  PGPASSWORD="${ADM_PWD}" psql -U postgres
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  [[ -n "${ADM_USER:-}" ]] || die 41 "${func_name}" "ADM_USER environment variable not set!"
  ADM_PWD=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${ADM_PWD}" ]] || die 42 "${func_name}" "get ${ADM_USER} password failed!"

  [[ -n "${REPL_USER:-}" ]] || die 43 "${func_name}" "REPL_USER environment variable not set!"
  REPL_PWD=$(decrypt_pwd "${REPL_USER}")
  [[ -n "${REPL_PWD}" ]] || die 44 "${func_name}" "get ${REPL_USER} password failed!"

  [[ -n "${MON_USER:-}" ]] || die 45 "${func_name}" "MON_USER environment variable not set!"
  MON_PWD=$(decrypt_pwd "${MON_USER}")
  [[ -n "${MON_PWD}" ]] || die 46 "${func_name}" "get ${MON_USER} password failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    initdb --data-checksums --pgdata="${DATA_DIR}" -A md5 --pwfile=<(echo "${ADM_PWD}") || {
        die 42 "${func_name}" "initdb failed!"
    }

    # check if the conf dir exists
    [[ -d "${CONF_DIR}" ]] || {
      mkdir -p "${CONF_DIR}" || die 43 "${func_name}" "create ${CONF_DIR} failed!"
    }

    cat <<EOF >"${CONF_DIR}/pg_hba.conf" || die 44 "${func_name}" "create pg_hba.conf failed!"
host     all             all             0.0.0.0/0               md5
host     all             all             ::/0                    md5
local    all             all                                     md5
host     replication     ${REPL_USER}    0.0.0.0/0               md5
host     all             ${MON_USER}     0.0.0.0/0               md5
EOF

    postgres --single -D "${DATA_DIR}" postgres <<EOF || die 45 "${func_name}" "create replication user failed!"
CREATE ROLE ${REPL_USER} WITH REPLICATION PASSWORD '${REPL_PWD}' LOGIN;
CREATE ROLE ${MON_USER} WITH LOGIN PASSWORD '${MON_PWD}' CONNECTION LIMIT 5 IN ROLE pg_monitor;
EOF

    info "${func_name}" "Initialize postgresql done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 46 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
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
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
