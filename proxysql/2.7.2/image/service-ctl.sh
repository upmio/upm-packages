#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail
umask 027

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
readonly EXIT_HTTP_REQUEST_FAILED=43
readonly EXIT_PROXYSQL_FILE_VALIDATION_FAILED=49
readonly EXIT_FLAG_FILE_CREATION_FAILED=51
readonly EXIT_PROXYSQL_START_FAILED=52
readonly EXIT_PROXYSQL_CONFIG_FAILED=53

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

  [[ -n "${username}" ]] || { error "${func_name}" "get username failed !"; return "${EXIT_GENERAL_FAILURE}"; }
  [[ -n "${SECRET_MOUNT:-}" ]] || { error "${func_name}" "get env SECRET_MOUNT failed !"; return "${EXIT_MISSING_ENV_VAR}"; }
  [[ -d "${SECRET_MOUNT}" ]] || { error "${func_name}" "Not found ${SECRET_MOUNT} failed !"; return "${EXIT_DIR_NOT_FOUND}"; }
  [[ -n "${AES_SECRET_KEY:-}" ]] || { error "${func_name}" "get env AES_SECRET_KEY failed !"; return "${EXIT_MISSING_ENV_VAR}"; }

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

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"
  [[ -n "${PROV_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "PROV_USER environment variable not set!"

  local admin_pwd
  admin_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${admin_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  local prov_pwd
  prov_pwd=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${prov_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${PROV_USER} password failed!"

  # Check if already initialized
  if [[ ! -f "${INIT_FLAG_FILE}" ]]; then
    # Handle force clean option
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    # Create required directories
    mkdir -p "${DATA_DIR}" "${CONF_DIR}" "${LOG_MOUNT}" || {
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir ${DATA_DIR} ${CONF_DIR} ${LOG_MOUNT} failed!"
    }

    info "${func_name}" "Starting initialize ProxySQL!"

    local config_template="${CONF_DIR}/proxysql.cnf.template"

    # Generate ProxySQL configuration file from template
    if [[ -f "${config_template}" ]]; then
      # Render configuration template
      local config_file="${CONF_DIR}/proxysql.cnf"

      # Copy template to config location
      cp "${config_template}" "${config_file}" || {
        die "${EXIT_PROXYSQL_CONFIG_FAILED}" "${func_name}" "copy config template failed!"
      }

      # Set proper permissions
      chmod 640 "${config_file}" || {
        die "${EXIT_GENERAL_FAILURE}" "${func_name}" "set config permissions failed!"
      }

      info "${func_name}" "ProxySQL configuration file generated successfully"
    else
      info "${func_name}" "Using default ProxySQL configuration"
    fi

    # Discover MySQL backend servers if not already configured
    if [[ -n "${MYSQL_SERVICE_NAME:-}" ]]; then
      info "${func_name}" "Discovering MySQL backend servers..."

      local mysql_servers=()
      local node_number=0

      while [[ ${node_number} -lt 7 ]]; do
        local node_name="${MYSQL_SERVICE_NAME}-${node_number}.${MYSQL_SERVICE_NAME}-headless-svc"

        # Test MySQL connectivity
        if mysqladmin --user="${PROV_USER}" --password="${prov_pwd}" --host="${node_name}" --port="${MYSQL_PORT:-3306}" ping &>/dev/null; then
          mysql_servers+=("${node_name}:${MYSQL_PORT:-3306}")
          info "${func_name}" "Discovered MySQL server: ${node_name}:${MYSQL_PORT:-3306}"
        fi

        node_number=$((node_number + 1))
      done

      # Configure ProxySQL with discovered MySQL servers
      if [[ ${#mysql_servers[@]} -gt 0 ]]; then
        info "${func_name}" "Configuring ProxySQL with ${#mysql_servers[@]} MySQL servers"

        # Start ProxySQL temporarily to configure it
        if ! proxysql --config="${CONF_DIR}/proxysql.cnf" --datadir="${DATA_DIR}" --pidfile="${DATA_DIR}/proxysql.pid" --daemon; then
          die "${EXIT_PROXYSQL_START_FAILED}" "${func_name}" "ProxySQL temporary start failed!"
        fi

        # Wait for ProxySQL to start
        sleep 3

        # Configure MySQL servers in ProxySQL
        for server in "${mysql_servers[@]}"; do
          local host="${server%:*}"
          local port="${server#*:}"

          # Add MySQL server to ProxySQL
          mysql --user="admin" --password="${admin_pwd}" --host="localhost" --port="${ADMIN_PORT:-6032}" --execute="
            INSERT INTO mysql_servers (hostgroup_id, hostname, port)
            VALUES (10, '${host}', ${port});" || {
            error "${func_name}" "Failed to add MySQL server ${server} to ProxySQL"
          }
        done

        # Load changes to runtime
        mysql --user="admin" --password="${admin_pwd}" --host="localhost" --port="${ADMIN_PORT:-6032}" --execute="
          LOAD MYSQL SERVERS TO RUNTIME;
          SAVE MYSQL SERVERS TO DISK;" || {
          error "${func_name}" "Failed to load MySQL servers to runtime"
        }

        # Stop temporary ProxySQL
        if [[ -f "${DATA_DIR}/proxysql.pid" ]]; then
          local proxy_pid
          proxy_pid=$(cat "${DATA_DIR}/proxysql.pid")
          kill "${proxy_pid}" 2>/dev/null || true
          sleep 2
        fi
      else
        error "${func_name}" "No MySQL servers discovered, using default configuration"
      fi
    fi

    # Initialize ProxySQL data directory
    if [[ ! -f "${DATA_DIR}/proxysql.db" ]]; then
      info "${func_name}" "Initializing ProxySQL data directory..."

      # Initialize ProxySQL database
      proxysql --initial --config="${CONF_DIR}/proxysql.cnf" --datadir="${DATA_DIR}" --daemon || {
        die "${EXIT_PROXYSQL_START_FAILED}" "${func_name}" "ProxySQL initialization failed!"
      }

      # Wait for initialization
      sleep 5

      # Stop initialization process
      if [[ -f "${DATA_DIR}/proxysql.pid" ]]; then
        local proxy_pid
        proxy_pid=$(cat "${DATA_DIR}/proxysql.pid")
        kill "${proxy_pid}" 2>/dev/null || true
        sleep 2
      fi

      # Validate ProxySQL files
      if [[ ! -f "${DATA_DIR}/proxysql.db" ]]; then
        die "${EXIT_PROXYSQL_FILE_VALIDATION_FAILED}" "${func_name}" "ProxySQL database file not found!"
      fi
    fi

    # Set up admin credentials
    if [[ -n "${admin_pwd}" ]]; then
      info "${func_name}" "Setting up admin credentials..."

      # Update admin password in configuration
      sed -i "s/admin_credentials=\"admin:.*/admin_credentials=\"admin:${admin_pwd}\"/g" "${CONF_DIR}/proxysql.cnf" || {
        error "${func_name}" "Failed to update admin credentials"
      }
    fi

    info "${func_name}" "Initialize ProxySQL done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

  info "${func_instance}" "run ${func_instance} done."
}

health() {
  local func_name="health"

  # Validate required environment variables
  [[ -n "${ADM_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "ADM_USER environment variable not set!"

  local admin_pwd
  admin_pwd=$(decrypt_pwd "${ADM_USER}")
  [[ -n "${admin_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${ADM_USER} password failed!"

  # Health check via ProxySQL admin interface
  local health_check_sql="SELECT 1 AS health_check"
  local result

  result=$(mysql --user="${ADM_USER}" --password="${admin_pwd}" --host="localhost" --port="${ADMIN_PORT:-6032}" --silent --skip-column-names --execute="${health_check_sql}") || {
    die "${EXIT_HTTP_REQUEST_FAILED}" "${func_name}" "ProxySQL admin interface health check failed!"
  }

  if [[ "${result}" != "1" ]]; then
    die "${EXIT_HTTP_REQUEST_FAILED}" "${func_name}" "ProxySQL health check returned unexpected result: ${result}"
  fi

  # Additional health checks
  local stats_check_sql="SELECT COUNT(*) AS server_count FROM mysql_servers"
  local server_count

  server_count=$(mysql --user="${ADM_USER}" --password="${admin_pwd}" --host="localhost" --port="${ADMIN_PORT:-6032}" --silent --skip-column-names --execute="${stats_check_sql}") || {
    error "${func_name}" "Failed to check server count, but basic health check passed"
    return 0
  }

  info "${func_name}" "ProxySQL is healthy with ${server_count} backend servers configured"
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
  [[ -n "${ADMIN_PORT:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "get env ADMIN_PORT failed !"

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
