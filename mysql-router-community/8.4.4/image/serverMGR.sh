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
# 1: General error (fallback)
# 2: General operation failure
# 10: Missing environment variable
# 11: Directory not found
# 21: Unsupported action/argument
# 41: Directory removal failed
# 42: Directory creation failed
# 43: HTTP request failed
# 44: Primary node discovery failed
# 45: MySQL cluster creation failed
# 46: MySQL cluster status check failed
# 47: PROV_USER validation failed
# 48: Password decryption failed
# 49: Router file validation failed
# 50: Router password setting failed
# 51: Flag file creation failed

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

initialize() {
  local func_name="initialize"
  local random="$RANDOM"
  local func_name="${func_name}(${random})"
  info "${func_name}" "Starting run ${func_name} ..."

  [[ -n "${PROV_USER:-}" ]] || die 10 "${func_name}" "PROV_USER environment variable not set!"
  PROV_PWD=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${PROV_PWD}" ]] || die 2 "${func_name}" "get ${PROV_USER} password failed!"

  [[ -f "${INIT_FLAG_FILE}" ]] || {
    if [[ "${FORCE_CLEAN}" == "true" ]]; then
      rm -rf "${DATA_DIR}" "${CONF_DIR}" || {
        die 41 "${func_name}" "Force remove ${DATA_DIR} ${CONF_DIR} failed!"
      }
    fi

    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || {
      die 42 "${func_name}" "mkdir ${DATA_DIR} ${CONF_DIR} failed!"
    }

    info "${func_name}" "Starting initialize mysql router!"

    local primary_node
    local node_number=0
    # get primary node
    while [[ ${node_number} -lt 7 ]]; do
      local node_name="${MYSQL_SERVICE_NAME}-${node_number}.${MYSQL_SERVICE_NAME}-headless-svc"
      primary_node=$(mysqlsh --uri "${PROV_USER}@${node_name}:${MYSQL_PORT}" --password="${PROV_PWD}" --sql -e "
        SELECT CONCAT(member_host, ':', member_port) AS primary_node
        FROM performance_schema.replication_group_members
        WHERE member_state = 'ONLINE' AND member_role = 'PRIMARY'
        LIMIT 1;" | grep -v primary_node)
      if [[ -n ${primary_node} ]]; then
        break
      fi

      if [[ ${node_number} -eq 6 ]]; then
        die 44 "${func_name}" "get primary node failed!"
      fi
      node_number=$((node_number + 1))
    done

    # If mysql_innodb_cluster_metadata schema is not exists, then initialize cluster
    if mysqlsh --uri "${PROV_USER}@${primary_node}" --password="${PROV_PWD}" --sql -e "
SELECT SCHEMA_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'mysql_innodb_cluster_metadata';" | grep -q "mysql_innodb_cluster_metadata"; then
      info "${func_name}" "mysql_innodb_cluster_metadata schema exists, skip initialize cluster!"
    else
      # innodb cluster initialize
      mysqlsh --uri "${PROV_USER}@${primary_node}" --password="${PROV_PWD}" --js -e "
var cluster = dba.createCluster('${SERVICE_GROUP_NAME}', {adoptFromGR: true})" || die 45 "${func_name}" "mysqlsh create cluster failed!"
      # check cluster status
      mysqlsh --uri "${PROV_USER}@${primary_node}" --password="${PROV_PWD}" --js -e "
var cluster;
try {
    // get cluster
    cluster = dba.getCluster('${SERVICE_GROUP_NAME}');
} catch (e) {
    // if failed to get cluster, output error and exit
    throw new Error('Cluster not found');
}

// get cluster status
var status;
try {
    status = cluster.status();
} catch (e) {
    //
    throw new Error('Failed to retrieve cluster status' + e.message);
}

// check if cluster status is OK
if (status.defaultReplicaSet.status === 'OK') {
    print('Cluster status is OK');
} else {
    // if cluster status is not OK, output error and exit
    throw new Error('Cluster status is ' + JSON.stringify(status.defaultReplicaSet.status));
}" || die 46 "${func_name}" "mysqlsh check cluster status failed!"

    fi

    # If keyring file or state.json file or mysqlrouter.key file is not exists, then bootstrap mysql router
    if [[ ! -f "${DATA_DIR}/data/keyring" ]] || [[ ! -f "${DATA_DIR}/data/state.json" ]] || [[ ! -f "${DATA_DIR}/mysqlrouter.key" ]]; then
      # remove all files in DATA_DIR directory
      rm -rf "${DATA_DIR:?}"/* || die 41 "${func_name}" "Force remove ${DATA_DIR} failed!"

      # bootstrap mysql router
      mysqlrouter --bootstrap "${PROV_USER}@${primary_node}" \
        --name "${SERVICE_GROUP_NAME}" \
        --directory "${DATA_DIR}" \
        --user mysql-router \
        --force \
        --disable-rest \
        --ssl-mode=DISABLED \
        --account-create=never \
        --account "${PROV_USER}" < <(echo -e "${PROV_PWD}\n${PROV_PWD}") || {
        die 45 "${func_name}" "mysqlrouter bootstrap failed!"
      }

      # check keyring file and state.json file and mysqlrouter.key file
      if [[ ! -f "${DATA_DIR}/data/keyring" ]] || [[ ! -f "${DATA_DIR}/data/state.json" ]] || [[ ! -f "${DATA_DIR}/mysqlrouter.key" ]]; then
        die 49 "${func_name}" "check keyring file or state.json file or mysqlrouter.key file failed!"
      fi

      mysqlrouter_passwd set "${DATA_MOUNT}/.mysqlrouter.pwd" "${PROV_USER}" < <(echo -e "${PROV_PWD}") || {
        die 50 "${func_name}" "mysqlrouter_passwd set failed!"
      }
    fi
    info "${func_name}" "Initialize mysql router done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 51 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }

  info "${func_name}" "run ${func_name} done."
}

check_health() {
  local func_name="check_health"

  [[ -n "${PROV_USER:-}" ]] || die 10 "${func_name}" "PROV_USER environment variable not set!"
  PROV_PWD=$(decrypt_pwd "${PROV_USER}")
  [[ -n "${PROV_PWD}" ]] || die 2 "${func_name}" "get ${PROV_USER} password failed!"

  # use rest api GET /routes/{routeName}/health check router
  local route_name="mysql_rw"
  local url="http://localhost:${HTTP_PORT}/api/20190715/routes/${route_name}/health"
  local status_code
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -u "${PROV_USER}:${PROV_PWD}" "${url}") || {
    die 43 "${func_name}" "curl ${url} failed!"
  }
  if [[ "${status_code}" -ne 200 ]]; then
    die 43 "${func_name}" "curl ${url} failed! status code: ${status_code}"
  fi
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
  "health")
    check_health
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
[[ -v SERVICE_GROUP_NAME ]] || die 10 "Globals" "get env SERVICE_GROUP_NAME failed !"
[[ -v HTTP_PORT ]] || die 10 "Globals" "get env HTTP_PORT failed !"
[[ -v MYSQL_SERVICE_NAME ]] || die 10 "Globals" "get env MYSQL_SERVICE_NAME failed !"
[[ -v MYSQL_PORT ]] || die 10 "Globals" "get env MYSQL_PORT failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
