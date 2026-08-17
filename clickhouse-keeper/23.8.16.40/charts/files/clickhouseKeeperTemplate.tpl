<clickhouse>
  <logger>
    <level>information</level>
    <log>{{ getenv "LOG_MOUNT" }}/clickhouse-keeper.log</log>
    <errorlog>{{ getenv "LOG_MOUNT" }}/clickhouse-keeper.err.log</errorlog>
    <size>1000M</size>
    <count>10</count>
  </logger>
  <keeper_server>
    <tcp_port>{{ getenv "CLICKHOUSE_KEEPER_PORT" "9181" }}</tcp_port>
    <server_id>{{ add (atoi (getenv "UNIT_SN" "0")) 1 }}</server_id>
    <log_storage_path>{{ getenv "KEEPER_DATA_DIR" }}/coordination/log</log_storage_path>
    <snapshot_storage_path>{{ getenv "KEEPER_DATA_DIR" }}/coordination/snapshots</snapshot_storage_path>
    <coordination_settings>
      <operation_timeout_ms>{{ getv "/defaults/coordination_settings/operation_timeout_ms" }}</operation_timeout_ms>
      <session_timeout_ms>{{ getv "/defaults/coordination_settings/session_timeout_ms" }}</session_timeout_ms>
    </coordination_settings>
    <raft_configuration>
{{- $serviceName := getenv "SERVICE_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $raftPort := getenv "CLICKHOUSE_KEEPER_RAFT_PORT" "9234" }}
{{- $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
{{- range $i := seq 0 (sub $unitCount 1) }}
      <server>
        <id>{{ add $i 1 }}</id>
        <hostname>{{ $serviceName }}-{{ $i }}.{{ $serviceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</hostname>
        <port>{{ $raftPort }}</port>
      </server>
{{- end }}
    </raft_configuration>
  </keeper_server>
  <listen_host>0.0.0.0</listen_host>
</clickhouse>
