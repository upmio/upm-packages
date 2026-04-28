<clickhouse>
  <logger>
    <level>information</level>
    <log>{{ getenv "LOG_MOUNT" }}/clickhouse-server.log</log>
    <errorlog>{{ getenv "LOG_MOUNT" }}/clickhouse-server.err.log</errorlog>
    <size>1000M</size>
    <count>10</count>
  </logger>
  <listen_host>0.0.0.0</listen_host>
  <tcp_port>{{ getenv "CLICKHOUSE_TCP_PORT" "9000" }}</tcp_port>
  <http_port>{{ getenv "CLICKHOUSE_HTTP_PORT" "8123" }}</http_port>
  <interserver_http_port>{{ getenv "CLICKHOUSE_INTERSERVER_PORT" "9009" }}</interserver_http_port>
  <path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/</path>
  <tmp_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/tmp/</tmp_path>
  <user_files_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/user_files/</user_files_path>
  <format_schema_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/format_schemas/</format_schema_path>

  <remote_servers>
    <upm_cluster>
      <shard>
        <internal_replication>true</internal_replication>
{{- $serviceName := getenv "SERVICE_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $tcpPort := getenv "CLICKHOUSE_TCP_PORT" "9000" }}
{{- $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
{{- range $i := seq 0 (sub $unitCount 1) }}
        <replica>
          <host>{{ $serviceName }}-{{ $i }}.{{ $serviceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</host>
          <port>{{ $tcpPort }}</port>
        </replica>
{{- end }}
      </shard>
    </upm_cluster>
  </remote_servers>

  <zookeeper>
{{- $keeperServiceName := getenv "CLICKHOUSE_KEEPER_SERVICE_NAME" (printf "%s-keeper" (getenv "SERVICE_GROUP_NAME" $serviceName)) }}
{{- $keeperCount := atoi (getenv "CLICKHOUSE_KEEPER_UNIT_COUNT" "3") }}
{{- $keeperPort := getenv "CLICKHOUSE_KEEPER_PORT" "9181" }}
{{- range $i := seq 0 (sub $keeperCount 1) }}
    <node>
      <host>{{ $keeperServiceName }}-{{ $i }}.{{ $keeperServiceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</host>
      <port>{{ $keeperPort }}</port>
    </node>
{{- end }}
  </zookeeper>

  <macros>
    <shard>01</shard>
    <replica>{{ getenv "POD_NAME" }}</replica>
  </macros>

  <profiles>
    <default>
      <max_threads>{{ getv "/settings/max_threads" }}</max_threads>
      <max_memory_usage>{{ getv "/settings/max_memory_usage" }}</max_memory_usage>
      <max_execution_time>{{ getv "/settings/max_execution_time" }}</max_execution_time>
      <log_queries>{{ getv "/settings/log_queries" }}</log_queries>
      <max_concurrent_queries>{{ getv "/settings/max_concurrent_queries" }}</max_concurrent_queries>
    </default>
  </profiles>

  <users>
    <default>
      <profile>default</profile>
      <networks>
        <ip>::/0</ip>
      </networks>
      <access_management>1</access_management>
    </default>
  </users>

  <backups>
    <allowed_disk>backups</allowed_disk>
    <allowed_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/backups/</allowed_path>
  </backups>
</clickhouse>
