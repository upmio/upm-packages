dataLogDir={{ getenv "ZOO_DATA_LOG_DIR" }}
dataDir={{ getenv "ZOO_DATA_DIR" }}
tickTime={{ getv "/defaults/tick_time" }}
initLimit={{ getv "/defaults/init_limit" }}
syncLimit={{ getv "/defaults/sync_limit" }}
autopurge.snapRetainCount={{ getv "/defaults/autopurge_snap_retain_count" }}
autopurge.purgeInterval={{ getv "/defaults/autopurge_purge_interval" }}
maxClientCnxns={{ getv "/defaults/max_client_cnxns" }}
maxSessionTimeout={{ getv "/defaults/max_session_timeout" }}
clientPort={{ getenv "ZOOKEEPER_PORT" "2181" }}
{{- range $i := seq 1 3 }}
server.{{ $i }}={{ getenv "SERVICE_NAME" }}-{{ sub $i 1 }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}:{{ getenv "TRANSPORT_PORT" "2888" }}:{{ getenv "LEADERSHIP_PORT" "3888" }}
{{end}}
admin.enableServer=false
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.exportJvmInfo=true
metricsProvider.httpPort={{ getenv "METRICS_PORT" "7000" }}
4lw.commands.whitelist=stat, ruok, conf, isro, dump, mntr
