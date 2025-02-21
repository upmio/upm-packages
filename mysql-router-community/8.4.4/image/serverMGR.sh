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

    mkdir -p "${DATA_DIR}" "${CONF_DIR}" || {
      die 42 "${func_name}" "mkdir ${DATA_DIR} ${CONF_DIR} failed!"
    }
    chown -R "1001.1001" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
      die 43 "${func_name}" "chown dir failed!"
    }

    info "${func_name}" "Starting initialize mysql router!"

    local primary_node
    local node_number=0
    # get primary node
    while [[ ${node_number} -lt 7 ]]; do
      local node_name="${MYSQL_SERVICE_NAME}-${node_number}.${MYSQL_SERVICE_NAME}-headless-svc"
      primary_node=$( mysqlsh --uri "${PROV_USER}@${node_name}:${MYSQL_PORT}" --password="${PROV_PWD}" --sql -e "
        SELECT CONCAT(member_host, ':', member_port) AS primary_node
        FROM performance_schema.replication_group_members
        WHERE member_state = 'ONLINE' AND member_role = 'PRIMARY'
        LIMIT 1;" | grep -v primary_node )
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
WHERE SCHEMA_NAME = 'mysql_innodb_cluster_metadata';" | grep -q "mysql_innodb_cluster_metadata" ; then
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

      # remove all files in DATA_DIR directory
      rm -rf "${DATA_DIR:?}"/* || die 47 "${func_name}" "Force remove ${DATA_DIR} failed!"

      # bootstrap mysql router
      /usr/bin/expect <<EOF
spawn mysqlrouter --bootstrap "${PROV_USER}@${primary_node}" --name "${SERVICE_GROUP_NAME}" --directory "${DATA_DIR}" --user mysql-router --account mysql-router
expect "Please enter MySQL password for ${PROV_USER}:"
send "${PROV_PWD}\r"
expect "Please enter MySQL password for mysql-router:"
send "${MON_PWD}\r"
interact
EOF
      local expect_status=$?
      if [[ ${expect_status} -ne 0 ]]; then
        die 48 "${func_name}" "mysqlrouter --bootstrap failed!"
      fi
      # check keyring file and state.json file and mysqlrouter.key file exists
      if [[ ! -f "${DATA_DIR}/data/keyring" ]] || [[ ! -f "${DATA_DIR}/data/state.json" ]] || [[ ! -f "${DATA_DIR}/mysqlrouter.key" ]]; then
        die 49 "${func_name}" "mysqlrouter --bootstrap failed!"
      fi
    fi

    info "${func_name}" "Initialize mysql router done !"
    touch "${INIT_FLAG_FILE}"
    [[ -f ${INIT_FLAG_FILE} ]] || die 49 "${func_name}" "create ${INIT_FLAG_FILE} failed!"
  }

  chown -R "1001.1001" "${DATA_MOUNT}" "${LOG_MOUNT}" || {
    die 50 "${func_name}" "chown dir failed!"
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
[[ -v SECRET_MOUNT ]] || die 10 "Globals" "get env SECRET_MOUNT failed !"
[[ -v LOG_MOUNT ]] || die 10 "Globals" "get env LOG_MOUNT failed !"
[[ -d ${LOG_MOUNT} ]] || die 11 "Globals" "Not found LOG_MOUNT !"
[[ -v SERVICE_GROUP_NAME ]] || die 10 "Globals" "get env SERVICE_GROUP_NAME failed !"
[[ -v HTTP_PORT ]] || die 10 "Globals" "get env HTTP_PORT failed !"
[[ -v MON_USER ]] || die 10 "Globals" "get env MON_USER failed !"
[[ -v PROV_USER ]] || die 10 "Globals" "get env PROV_USER failed !"
[[ -v MYSQL_SERVICE_NAME ]] || die 10 "Globals" "get env MYSQL_SERVICE_NAME failed !"
[[ -v MYSQL_PORT ]] || die 10 "Globals" "get env MYSQL_PORT failed !"
FORCE_CLEAN="${FORCE_CLEAN:-false}"

main "${@:-""}"
