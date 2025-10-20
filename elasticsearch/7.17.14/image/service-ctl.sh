#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

# ##############################################################################
# Global Constants and Configuration
# ##############################################################################
readonly SCRIPT_VERSION="v1.0.1"
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
readonly EXIT_CERT_FILE_NOT_FOUND=43
readonly EXIT_CHOWN_FAILED=46
readonly EXIT_USER_ADD_FAILED=49
readonly EXIT_FLAG_FILE_CREATION_FAILED=47

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

  # Elasticsearch REST API authentication
  info "${func_name}" "Elasticsearch admin user: ${ADM_USER}"
  info "${func_name}" "Access Elasticsearch at: https://${POD_NAME}:${ELASTICSEARCH_PORT}"
}

health() {
  local func_name="health"

  # Validate required environment variables
  [[ -n "${MON_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "MON_USER environment variable not set!"
  local mon_pwd
  mon_pwd=$(decrypt_pwd "${MON_USER}")
  [[ -n "${mon_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${MON_USER} password failed!"

  local http_code
  http_code=$(curl --output /dev/null -k -X GET -s -w '%{http_code}' -u "${MON_USER}:${mon_pwd}" "https://${POD_NAME}:${ELASTICSEARCH_PORT}")

  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    die "${EXIT_GENERAL_FAILURE}" "${func_name}" "curl health check failed with RC ${rc}"
  fi

  # ready if HTTP code 200
  [[ ${http_code} == "200" ]] || {
    die "${EXIT_GENERAL_FAILURE}" "${func_name}" "health check failed with HTTP code ${http_code}"
  }

  info "${func_name}" "Elasticsearch health check passed (HTTP ${http_code})"
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

  [[ -n "${KBN_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "KBN_USER environment variable not set!"
  local kbn_pwd
  kbn_pwd=$(decrypt_pwd "${KBN_USER}")
  [[ -n "${kbn_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${KBN_USER} password failed!"

  # Check if already initialized
  if [[ ! -f "${INIT_FLAG_FILE}" ]]; then
    # Handle force clean option
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    # Create required directories
    mkdir -p "${DATA_DIR}" || {
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir ${DATA_DIR} failed!"
    }

    # Copy configuration directory
    cp -r "${ELASTICSEARCH_BASE_DIR}/config" "${DATA_MOUNT}" || {
      die "${EXIT_GENERAL_FAILURE}" "${func_name}" "copy config dir failed!"
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

    # Create Elasticsearch users
    "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-users" useradd "${MON_USER}" -p "${mon_pwd}" -r remote_monitoring_collector || {
      die "${EXIT_USER_ADD_FAILED}" "${func_name}" "add monitor user failed!"
    }

    "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-users" useradd "${ADM_USER}" -p "${adm_pwd}" -r superuser || {
      die "${EXIT_USER_ADD_FAILED}" "${func_name}" "add admin user failed!"
    }

    "${ELASTICSEARCH_BASE_DIR}/bin/elasticsearch-users" useradd "${KBN_USER}_user" -p "${kbn_pwd}" -r kibana_system || {
      die "${EXIT_USER_ADD_FAILED}" "${func_name}" "add kibana user failed!"
    }

    # Store KBN user's username and password for elasticsearch-exporter
    echo "${KBN_USER}_user" >"${DATA_DIR}/kbn_user.txt"
    echo "${kbn_pwd}" >>"${DATA_DIR}/kbn_user.txt"

    info "${func_name}" "Initialize elasticsearch done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

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
  "health")
    health
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
  [[ -n "${ES_PATH_CONF:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env ES_PATH_CONF failed !"
  [[ -n "${DATA_DIR:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env DATA_DIR failed !"
  [[ -n "${LOG_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env LOG_MOUNT failed !"
  [[ -d ${LOG_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found LOG_MOUNT !"
  [[ -n "${CERT_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env CERT_MOUNT failed !"
  [[ -d ${CERT_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found CERT_MOUNT !"
  [[ -n "${POD_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env POD_NAME failed !"
  ELASTICSEARCH_PORT="${ELASTICSEARCH_PORT:-9200}"

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
