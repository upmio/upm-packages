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
readonly EXIT_CERT_FILE_NOT_FOUND=43
readonly EXIT_CHOWN_FAILED=46
readonly EXIT_MEMORY_LIMIT_INVALID=49
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

  # Open Kibana session (this would typically use browser-based authentication)
  info "${func_name}" "Kibana admin user: ${ADM_USER}"
  info "${func_name}" "Access Kibana at: http://${POD_NAME}:${KIBANA_PORT}"
}

health() {
  local func_name="health"

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"
  local adm_pwd
  adm_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${adm_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  local http_code
  http_code=$(curl --output /dev/null -X GET -s -w '%{http_code}' -u "${ADM_USER}:${adm_pwd}" "http://${POD_NAME}:${KIBANA_PORT}/app/kibana")

  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    die "${EXIT_GENERAL_FAILURE}" "${func_name}" "curl health check failed with RC ${rc}"
  fi

  # ready if HTTP code 200
  [[ ${http_code} == "200" ]] || {
    die "${EXIT_GENERAL_FAILURE}" "${func_name}" "health check failed with HTTP code ${http_code}"
  }

  info "${func_name}" "Kibana health check passed (HTTP ${http_code})"
}

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Check if already initialized
  if [[ ! -f "${INIT_FLAG_FILE}" ]]; then
    # Handle force clean option
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${KBN_PATH_CONF}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${KBN_PATH_CONF} failed!"
      }
    fi

    # Create required directories
    mkdir -p "${KBN_PATH_CONF}" || {
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir ${KBN_PATH_CONF} failed!"
    }

    # Copy certificates if they exist
    if [[ -f ${CERT_MOUNT}/ca.crt ]]; then
      \cp "${CERT_MOUNT}/ca.crt" "${KBN_PATH_CONF}"
      chmod 600 "${KBN_PATH_CONF}/ca.crt"
    else
      die "${EXIT_CERT_FILE_NOT_FOUND}" "${func_name}" "Not found ${CERT_MOUNT}/ca.crt !"
    fi

    if [[ -f ${CERT_MOUNT}/tls.crt ]]; then
      \cp "${CERT_MOUNT}/tls.crt" "${KBN_PATH_CONF}"
      chmod 600 "${KBN_PATH_CONF}/tls.crt"
    else
      die "${EXIT_CERT_FILE_NOT_FOUND}" "${func_name}" "Not found ${CERT_MOUNT}/tls.crt !"
    fi

    if [[ -f ${CERT_MOUNT}/tls.key ]]; then
      \cp "${CERT_MOUNT}/tls.key" "${KBN_PATH_CONF}"
      chmod 600 "${KBN_PATH_CONF}/tls.key"
    else
      die "${EXIT_CERT_FILE_NOT_FOUND}" "${func_name}" "Not found ${CERT_MOUNT}/tls.key !"
    fi

    info "${func_name}" "Initialize kibana done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

  # Validate and configure memory settings
  [[ -n "${KBN_MEMORY_LIMIT:-}" ]] || {
    die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env KBN_MEMORY_LIMIT failed !"
  }
  [[ ${KBN_MEMORY_LIMIT} -gt 0 ]] || {
    die "${EXIT_MEMORY_LIMIT_INVALID}" "${func_name}" "KBN_MEMORY_LIMIT(${KBN_MEMORY_LIMIT}) is invalid !"
  }

  local max_old_space_size=$((KBN_MEMORY_LIMIT / 2))
  # check max_old_space_size is set, min value is 512
  [[ ${max_old_space_size} -ge 512 ]] || {
    die "${EXIT_MEMORY_LIMIT_INVALID}" "${func_name}" "max_old_space_size(${max_old_space_size}) is invalid !"
  }

  # Create Node.js options file
  cat <<EOF >"${KBN_PATH_CONF}/node.options"
## max size of old space in megabytes
--max-old-space-size=${max_old_space_size}

## do not terminate process on unhandled promise rejection
--unhandled-rejections=warn

## restore < Node 16 default DNS lookup behavior
--dns-result-order=ipv4first
EOF

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
  [[ -n "${KBN_PATH_CONF:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env KBN_PATH_CONF failed !"
  [[ -n "${LOG_MOUNT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env LOG_MOUNT failed !"
  [[ -d ${LOG_MOUNT} ]] || die "${EXIT_DIR_NOT_FOUND}" "${func_name}" "Not found LOG_MOUNT !"
  [[ -n "${POD_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env POD_NAME failed !"
  KIBANA_PORT="${KIBANA_PORT:-5601}"

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
