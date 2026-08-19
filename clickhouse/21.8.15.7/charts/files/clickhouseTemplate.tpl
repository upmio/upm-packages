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
  <prometheus>
    <endpoint>/metrics</endpoint>
    <port>9363</port>
  </prometheus>
  <!-- Required by ClickHouse's built-in /dashboard endpoint. -->
  <metric_log>
    <database>system</database>
    <table>metric_log</table>
    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
    <collect_interval_milliseconds>1000</collect_interval_milliseconds>
  </metric_log>
  <asynchronous_metric_log>
    <database>system</database>
    <table>asynchronous_metric_log</table>
    <flush_interval_milliseconds>7000</flush_interval_milliseconds>
  </asynchronous_metric_log>
  <interserver_http_port>{{ getenv "CLICKHOUSE_INTERSERVER_PORT" "9009" }}</interserver_http_port>
  <max_concurrent_queries>{{ getv "/settings/max_concurrent_queries" }}</max_concurrent_queries>
  <mark_cache_size>{{ getv "/settings/mark_cache_size" }}</mark_cache_size>
  <path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/</path>
  <tmp_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/tmp/</tmp_path>
  <user_files_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/user_files/</user_files_path>
  <format_schema_path>{{ getenv "CLICKHOUSE_DATA_DIR" }}/format_schemas/</format_schema_path>

  <remote_servers>
    <upm_cluster>
{{- $serviceName := getenv "SERVICE_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $tcpPort := getenv "CLICKHOUSE_TCP_PORT" "9000" }}
{{- $adminUser := getenv "ADM_USER" "default" }}
{{- $adminPassword := AESCTRDecrypt (secretRead (getenv "SECRET_NAME") $namespace $adminUser) }}
{{- $shards := jsonArray (getenv "CLICKHOUSE_SHARD_TOPOLOGY" "[]") }}
{{- if $shards }}
{{- range $shard := $shards }}
      <shard>
        <internal_replication>true</internal_replication>
{{- $shardServiceName := printf "%v" $shard.serviceName }}
{{- $replicaCount := atoi (printf "%v" $shard.replicaCount) }}
{{- range $i := seq 0 (sub $replicaCount 1) }}
        <replica>
          <host>{{ $shardServiceName }}-{{ $i }}.{{ $shardServiceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</host>
          <port>{{ $tcpPort }}</port>
          <user>{{ $adminUser }}</user>
          <password><![CDATA[{{ $adminPassword }}]]></password>
        </replica>
{{- end }}
      </shard>
{{- end }}
{{- else }}
      <shard>
        <internal_replication>true</internal_replication>
{{- $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
{{- range $i := seq 0 (sub $unitCount 1) }}
        <replica>
          <host>{{ $serviceName }}-{{ $i }}.{{ $serviceName }}-headless-svc.{{ $namespace }}.svc.cluster.local</host>
          <port>{{ $tcpPort }}</port>
          <user>{{ $adminUser }}</user>
          <password><![CDATA[{{ $adminPassword }}]]></password>
        </replica>
{{- end }}
      </shard>
{{- end }}
    </upm_cluster>
  </remote_servers>

  <zookeeper>
{{- $keeperServiceName := getenv "CLICKHOUSE_KEEPER_SERVICE_NAME" (getenv "KEEPER_SERVICE_NAME" (printf "%s-keeper" (getenv "SERVICE_GROUP_NAME" $serviceName))) }}
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
    <shard>{{ getenv "CLICKHOUSE_SHARD_ID" "01" }}</shard>
    <replica>{{ getenv "POD_NAME" }}</replica>
  </macros>

  <distributed_ddl>
    <path>/clickhouse/task_queue/ddl</path>
  </distributed_ddl>

  <profiles>
    <default>
      <max_threads>{{ getv "/settings/max_threads" }}</max_threads>
      <max_memory_usage>{{ getv "/settings/max_memory_usage" }}</max_memory_usage>
      <max_execution_time>{{ getv "/settings/max_execution_time" }}</max_execution_time>
      <log_queries>{{ getv "/settings/log_queries" }}</log_queries>
    </default>
  </profiles>

  <users>
    <default>
      <password_sha256_hex>{{ sha256sum (AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER" "default"))) }}</password_sha256_hex>
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
