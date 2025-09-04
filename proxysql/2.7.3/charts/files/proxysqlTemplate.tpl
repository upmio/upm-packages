datadir="{{ getenv "DATA_DIR" }}"
errorlog="{{ getenv "LOG_MOUNT" }}/proxysql.log"
restart_on_missing_heartbeats={{ getv "/general/restart_on_missing_heartbeats" }}
pidfile="{{ getenv "DATA_DIR" }}/proxysql.pid"

admin_variables=
{
  admin_credentials="admin:{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }};{{ getenv "RADM_USER" }}:{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "RADM_USER")) }}"
  stats_credentials="stats:{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "MON_USER")) }}"
  mysql_ifaces="0.0.0.0:{{ getenv "ADMIN_PORT" "6032" }}"
  debug={{ getv "/admin/debug" }}
  restapi_enabled=true
  restapi_port={{ getenv "METRICS_PORT" "6070" }}
  prometheus_memory_metrics_interval={{ getv "/admin/prometheus_memory_metrics_interval" }}
  web_enabled=true
  web_port={{ getenv "WEB_PORT" "6080" }}
  read_only={{ getv "/admin/read_only" }}
  refresh_interval={{ getv "/admin/refresh_interval" }}
}

mysql_variables=
{
  interfaces="0.0.0.0:{{ getenv "PROXYSQL_PORT" "6033" }}"
  poll_timeout={{ getv "/mysql/poll_timeout" }}
  poll_timeout_on_failure={{ getv "/mysql/poll_timeout_on_failure" }}
  stacksize={{ getv "/mysql/stacksize" }}
  threads={{ getenv "PROXYSQL_CPU_LIMIT" | toFloat64 | printf "%.0f" }}
  threshold_query_length={{ getv "/mysql/threshold_query_length" }}
  threshold_resultset_size={{ getv "/mysql/threshold_resultset_size" }}
  default_schema="{{ getv "/mysql/default_schema" }}"
  monitor_username="{{ getenv "MON_USER" }}"
  monitor_password="{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "MON_USER")) }}"
  max_connections="{{ getv "/mysql/max_connections" }}"
  default_query_delay="{{ getv "/mysql/default_query_delay" }}"
  default_query_timeout="{{ getv "/mysql/default_query_timeout" }}"
  connect_timeout_server={{ getv "/mysql/connect_timeout_server" }}
  connect_retries_on_failure={{ getv "/mysql/connect_retries_on_failure" }}
  ping_interval_server_msec={{ getv "/mysql/ping_interval_server_msec" }}
  ping_timeout_server={{ getv "/mysql/ping_timeout_server" }}
  commands_stats={{ getv "/mysql/commands_stats" }}
  sessions_sort={{ getv "/mysql/sessions_sort" }}
  monitor_enabled=true
  monitor_history={{ getv "/mysql/monitor_history" }}
  monitor_connect_interval={{ getv "/mysql/monitor_connect_interval" }}
  monitor_connect_timeout={{ getv "/mysql/monitor_connect_timeout" }}
  monitor_ping_interval={{ getv "/mysql/monitor_ping_interval" }}
  monitor_read_only_interval={{ getv "/mysql/monitor_read_only_interval" }}
  monitor_read_only_timeout={{ getv "/mysql/monitor_read_only_timeout" }}
}
