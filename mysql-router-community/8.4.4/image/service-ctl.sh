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
readonly EXIT_HTTP_REQUEST_FAILED=43
readonly EXIT_PRIMARY_NODE_DISCOVERY_FAILED=44
readonly EXIT_MYSQL_CLUSTER_CREATION_FAILED=45
readonly EXIT_MYSQL_CLUSTER_STATUS_FAILED=46
readonly EXIT_ROUTER_FILE_VALIDATION_FAILED=49
readonly EXIT_ROUTER_PASSWORD_SET_FAILED=50
readonly EXIT_FLAG_FILE_CREATION_FAILED=51

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

initialize() {
  local func_name="initialize"
  local random_id="$RANDOM"
  local func_instance="${func_name}(${random_id})"

  info "${func_instance}" "Starting run ${func_instance} ..."

  # Validate required environment variables
  [[ -n "${PROV_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "PROV_USER environment variable not set!"
  local prov_pwd
  prov_pwd=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${prov_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${PROV_USER} password failed!"

  [[ -n "${MYSQL_SERVICE_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "MYSQL_SERVICE_NAME environment variable not set!"
  [[ -n "${SERVICE_GROUP_NAME:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "SERVICE_GROUP_NAME environment variable not set!"
  MYSQL_PORT="${MYSQL_PORT:-3306}"

  # Check if already initialized
  if [[ ! -f "${INIT_FLAG_FILE}" ]]; then
    # Handle force clean option
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    # Create required directories
    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || {
      die "${EXIT_DIR_CREATION_FAILED}" "${func_name}" "mkdir ${DATA_DIR} ${CONF_DIR} failed!"
    }

    info "${func_name}" "Starting initialize mysql router!"

    # Discover primary node
    local primary_node
    local node_number=0
    while [[ ${node_number} -lt 7 ]]; do
      local node_name="${MYSQL_SERVICE_NAME}-${node_number}.${MYSQL_SERVICE_NAME}-headless-svc"
      primary_node=$(mysqlsh --uri "${PROV_USER}@${node_name}:${MYSQL_PORT}" --password="${prov_pwd}" --sql -e "
        SELECT CONCAT(member_host, ':', member_port) AS primary_node
        FROM performance_schema.replication_group_members
        WHERE member_state = 'ONLINE' AND member_role = 'PRIMARY'
        LIMIT 1;" | grep -v primary_node)

      if [[ -n ${primary_node} ]]; then
        break
      fi

      if [[ ${node_number} -eq 6 ]]; then
        die "${EXIT_PRIMARY_NODE_DISCOVERY_FAILED}" "${func_name}" "get primary node failed!"
      fi
      node_number=$((node_number + 1))
    done

    # Initialize MySQL cluster if needed
    if mysqlsh --uri "${PROV_USER}@${primary_node}" --password="${prov_pwd}" --sql -e "
SELECT SCHEMA_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'mysql_innodb_cluster_metadata';" | grep -q "mysql_innodb_cluster_metadata"; then
      info "${func_name}" "mysql_innodb_cluster_metadata schema exists, skip initialize cluster!"
    else
      # Create InnoDB cluster
      mysqlsh --uri "${PROV_USER}@${primary_node}" --password="${prov_pwd}" --js -e "
var cluster = dba.createCluster('${SERVICE_GROUP_NAME}', {adoptFromGR: true})" || die "${EXIT_MYSQL_CLUSTER_CREATION_FAILED}" "${func_name}" "mysqlsh create cluster failed!"

      # Check cluster status
      mysqlsh --uri "${PROV_USER}@${primary_node}" --password="${prov_pwd}" --js -e "
var cluster;
try {
    cluster = dba.getCluster('${SERVICE_GROUP_NAME}');
} catch (e) {
    throw new Error('Cluster not found');
}

var status;
try {
    status = cluster.status();
} catch (e) {
    throw new Error('Failed to retrieve cluster status' + e.message);
}

if (status.defaultReplicaSet.status === 'OK') {
    print('Cluster status is OK');
} else {
    throw new Error('Cluster status is ' + JSON.stringify(status.defaultReplicaSet.status));
}" || die "${EXIT_MYSQL_CLUSTER_STATUS_FAILED}" "${func_name}" "mysqlsh check cluster status failed!"
    fi

    # Bootstrap MySQL Router if needed
    if [[ ! -f "${DATA_DIR}/data/keyring" ]] || [[ ! -f "${DATA_DIR}/data/state.json" ]] || [[ ! -f "${DATA_DIR}/mysqlrouter.key" ]]; then
      # Clean up existing data
      rm -rf "${DATA_DIR:?}"/* || die "${EXIT_DIR_REMOVAL_FAILED}" "${func_name}" "Force remove ${DATA_DIR} failed!"

      # Bootstrap MySQL Router
      mysqlrouter --bootstrap "${PROV_USER}@${primary_node}" \
        --name "${SERVICE_GROUP_NAME}" \
        --directory "${DATA_DIR}" \
        --user mysql-router \
        --force \
        --disable-rest \
        --ssl-mode=DISABLED \
        --account-create=never \
        --account "${PROV_USER}" < <(echo -e "${prov_pwd}\n${prov_pwd}") || {
        die "${EXIT_MYSQL_CLUSTER_CREATION_FAILED}" "${func_name}" "mysqlrouter bootstrap failed!"
      }

      # Validate router files
      if [[ ! -f "${DATA_DIR}/data/keyring" ]] || [[ ! -f "${DATA_DIR}/data/state.json" ]] || [[ ! -f "${DATA_DIR}/mysqlrouter.key" ]]; then
        die "${EXIT_ROUTER_FILE_VALIDATION_FAILED}" "${func_name}" "check keyring file or state.json file or mysqlrouter.key file failed!"
      fi

      # Set router password
      mysqlrouter_passwd set "${DATA_MOUNT}/.mysqlrouter.pwd" "${PROV_USER}" < <(echo -e "${prov_pwd}") || {
        die "${EXIT_ROUTER_PASSWORD_SET_FAILED}" "${func_name}" "mysqlrouter_passwd set failed!"
      }
    fi

    info "${func_name}" "Initialize mysql router done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die "${EXIT_FLAG_FILE_CREATION_FAILED}" "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  fi

  info "${func_instance}" "run ${func_instance} done."
}

health() {
  local func_name="health"

  # Validate required environment variables
  [[ -n "${PROV_USER:-}" ]] || die "${EXIT_MISSING_ENV_VAR}" "${func_name}" "PROV_USER environment variable not set!"
  local prov_pwd
  prov_pwd=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${prov_pwd}" ]] || die "${EXIT_GENERAL_FAILURE}" "${func_name}" "get ${PROV_USER} password failed!"

  HTTP_PORT="${HTTP_PORT:-8081}"

  # Health check via REST API
  local route_name="mysql_rw"
  local health_url="http://localhost:${HTTP_PORT}/api/20190715/routes/${route_name}/health"
  local status_code

  status_code=$(curl -s -o /dev/null -w "%{http_code}" -u "${PROV_USER}:${prov_pwd}" "${health_url}") || {
    die "${EXIT_HTTP_REQUEST_FAILED}" "${func_name}" "curl ${health_url} failed!"
  }

  if [[ "${status_code}" -ne 200 ]]; then
    die "${EXIT_HTTP_REQUEST_FAILED}" "${func_name}" "curl ${health_url} failed! status code: ${status_code}"
  fi
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

  # Set global variables with defaults
  readonly INIT_FLAG_FILE="${DATA_MOUNT}/.init.flag"
  readonly FORCE_CLEAN="${FORCE_CLEAN:-false}"
}

# ##############################################################################
# Main Entry Point
# ##############################################################################
validate_environment
main "$@"
