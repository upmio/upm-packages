#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# ##############################################################################
# Globals, settings
# ##############################################################################
POSIXLY_CORRECT=1
export POSIXLY_CORRECT
LANG=C

FILE_NAME="sentinelReconfig"
VERSION="1.0.5"

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
  local log_file="${LOG_FILE:-"/tmp/${FILE_NAME}.log"}"

  local log_dir="${log_file%/*}"
  [[ -d ${log_dir} ]] || log_file="/tmp/${FILE_NAME}.log"

  echo "[${timestamp}] ERR | (${VERSION})[${function_name}]: $* ;" | tee -a "${log_file}"
}

info() {
  local function_name="${1}"
  shift
  local timestamp
  timestamp="$(date +"%Y-%m-%d %T %N")"
  local log_file="${LOG_FILE:-"/tmp/${FILE_NAME}.log"}"

  local log_dir="${log_file%/*}"
  [[ -d ${log_dir} ]] || log_file="/tmp/${FILE_NAME}.log"

  echo "[${timestamp}] INFO| (${VERSION})[${function_name}]: $* ;" >>"${log_file}"
}

update_redis_replication_source() {
  local func_name="update_redis_replication_source"

  local new_master_ip="${1}"

  grpcurl -plaintext -d '{"redis_replication_name":"'"${REDIS_SERVICE_NAME}-replication"'","namespace":"'"${NAMESPACE}"'","self_unit_name":"'"${POD_NAME}"'","master_host":"'"${new_master_ip}"'"}' "${UNIT_AGENT_ENDPOINT}" sentinel.SentinelOperation.UpdateRedisReplication

  info "${func_name}" "update redis replication source success !"
}

# ##############################################################################
# The main() function is called at the action function.
# ##############################################################################
main() {
  local func_name="main"

  # CLIENTS RECONFIGURATION SCRIPT
  # sentinel client-reconfig-script <master-name> <script-path>
  # The following arguments are passed to the script:
  # <master-name> <role> <state> <from-ip> <from-port> <to-ip> <to-port>
  local master_name="${1}"
  local role="${2}"
  local state="${3}"
  local from_ip="${4}"
  local from_port="${5}"
  local to_ip="${6}"
  local to_port="${7}"

  [[ ${role} == "leader" ]] || {
    info "${func_name}" "role is not leader, skip !"
    exit 0
  }

  UNIT_AGENT_ENDPOINT="127.0.0.1:2214"

  info "${func_name}" "master_name: ${master_name} , role: ${role} , state: ${state} , from_ip: ${from_ip} , from_port: ${from_port} , to_ip: ${to_ip} , to_port: ${to_port}"
  info "${func_name}" "arguments: ${master_name} ${role} ${state} ${from_ip} ${from_port} ${to_ip} ${to_port}"

  update_redisreplication_source "${to_ip}" || die 21 "${func_name}" "update redisreplication source failed !"

  info "${func_name}" "update shared configmap and redis replication source success !"
}

[[ -d ${LOG_MOUNT} ]] || die 10 "Globals" "Not found LOG_MOUNT !"
LOG_FILE="${LOG_MOUNT}/${FILE_NAME}.log"
[[ -v SERVICE_GROUP_NAME ]] || die 10 "Globals" "get env SERVICE_GROUP_NAME failed !"
[[ -n "${NAMESPACE:-}" ]] || die 10 "Globals" "get env NAMESPACE failed !"
[[ -n "${POD_NAME:-}" ]] || die 10 "Globals" "get env POD_NAME failed !"
[[ -n "${REDIS_SERVICE_NAME:-}" ]] || die 10 "Globals" "get env REDIS_SERVICE_NAME failed !"

main "${@:-""}"
