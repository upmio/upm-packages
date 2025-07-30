#!/usr/bin/env bash

set -o nounset
# ##############################################################################
# Globals, settings
# ##############################################################################
POSIXLY_CORRECT=1
export POSIXLY_CORRECT
LANG=C

VERSION="v1.6.7"

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

  local secret_file="${SECRET_MOUNT}/${KBN_USER}"
  [[ -f "${secret_file}" ]] || {
    error "${func_name}" "get file ${secret_file} failed !"
    return 2
  }
  local enc_base64
  enc_base64="$(cat "${secret_file}")" || {
    error "${func_name}" "get enc_base64 failed!"
    return 2
  }
  export KBN_PWD
  KBN_PWD=$(printf "%s\n" "${enc_base64}" | openssl enc -d "${enc_type}" -base64 -K "${enc_key}" -iv "${enc_iv}" 2>/dev/null) || {
    error "${func_name}" "openssl enc failed"
    return 2
  }
}

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  get_pwd || die 40 "${func_name}" "get password failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi
    mkdir -p "${DATA_DIR}" || {
      die 43 "${func_name}" "mkdir ${DATA_DIR} failed!"
    }

    cp -r "${ELASTICSEARCH_BASE_DIR}/config" "${DATA_MOUNT}" || {
      die 44 "${func_name}" "copy config dir failed!"
    }

    if [[ -f ${CERT_MOUNT}/ca.crt ]]; then
      \cp "${CERT_MOUNT}/ca.crt" "${ES_PATH_CONF}"
      chmod 600 "${ES_PATH_CONF}/ca.crt"
    else
      die 45 "${func_name}" "Not found ${CERT_MOUNT}/ca.crt !"
    fi

    if [[ -f ${CERT_MOUNT}/tls.crt ]]; then
      \cp "${CERT_MOUNT}/tls.crt" "${ES_PATH_CONF}"
      chmod 600 "${ES_PATH_CONF}/tls.crt"
    else
      die 46 "${func_name}" "Not found ${CERT_MOUNT}/tls.crt !"
    fi

    if [[ -f ${CERT_MOUNT}/tls.key ]]; then
      \cp "${CERT_MOUNT}/tls.key" "${ES_PATH_CONF}"
      chmod 600 "${ES_PATH_CONF}/tls.key"
    else
      die 47 "${func_name}" "Not found ${CERT_MOUNT}/tls.key !"
    fi

    chown -R "1001.1001" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
      die 48 "${func_name}" "chown dir failed!"
    }

    "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-users" useradd "${MON_USER}" -p "${MON_PWD}" -r remote_monitoring_collector || {
      die 49 "${func_name}" "add monitor user failed!"
    }

    "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-users" useradd "${ADM_USER}" -p "${ADM_PWD}" -r superuser || {
      die 51 "${func_name}" "add admin user failed!"
    }

    "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-users" useradd "${KBN_USER}_user" -p "${KBN_PWD}" -r kibana_system || {
      die 53 "${func_name}" "add kibana user failed!"
    }

    # Store KBN user's username and password into a file, used for elasticsearch-exporter to set ES_USERNAME and ES_PASSWORD environment variables for password authentication
    echo "${KBN_USER}_user" > "${DATA_DIR}/kbn_user.txt"
    echo "${KBN_PWD}" >> "${DATA_DIR}/kbn_user.txt"

    info "${func_name}" "Initialize elasticsearch done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 47 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }
}

status() {
  local func_name="status"

  get_pwd || die 40 "${func_name}" "get password failed!"

  local http_code
  http_code=$(curl --output /dev/null -k -X GET -s -w '%{http_code}' -u "${MON_USER}:${MON_PWD}" "https://${POD_NAME}:${ELASTICSEARCH_PORT}")

  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    die 41 "${func_name}" "curl --output /dev/null -k -X GET -s -w '%{http_code}' failed with RC ${rc}"
  fi
  # ready if HTTP code 200, 503 is tolerable if ES version is 6.x
  [[ ${http_code} == "200" ]] || {
    die 42 "${func_name}" "curl --output /dev/null -k -X GET -s -w '%{http_code}' failed with HTTP code ${http_code}"
  }
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
  "status")
    status
    ;;
  *)
    die 21 "${func_name}" "action(${action}) nonsupport"
    ;;
  esac
}

[[ -v DATA_MOUNT ]] || die 10 "Globals" "get env DATA_MOUNT failed !"
[[ -d ${DATA_MOUNT} ]] || die 11 "Globals" "Not found DATA_MOUNT !"
INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
[[ -v ES_PATH_CONF ]] || die 10 "Globals" "get env ES_PATH_CONF failed !"
[[ -v DATA_DIR ]] || die 10 "Globals" "get env DATA_DIR failed !"
[[ -v LOG_MOUNT ]] || die 10 "Globals" "get env LOG_MOUNT failed !"
[[ -d ${LOG_MOUNT} ]] || die 11 "Globals" "Not found LOG_MOUNT !"
[[ -v ADM_USER ]] || die 10 "Globals" "get env ADM_USER failed !"
[[ -v KBN_USER ]] || die 10 "Globals" "get env KBN_USER failed !"
[[ -v MON_USER ]] || die 10 "Globals" "get env MON_USER failed !"
[[ -v CERT_MOUNT ]] || die 10 "Globals" "get env CERT_MOUNT failed !"
[[ -d ${CERT_MOUNT} ]] || die 11 "Globals" "Not found CERT_MOUNT !"
[[ -v POD_NAME ]] || die 10 "Globals" "get env POD_NAME failed !"
[[ -v ELASTICSEARCH_PORT ]] || die 10 "Globals" "get env ELASTICSEARCH_PORT failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
