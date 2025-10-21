node.id={{ getenv "UNIT_SN" }}
broker.id={{ getenv "UNIT_SN" }}
log.dirs={{ getenv "DATA_DIR" }}

{{- if eq (getenv "UNIT_SERVICE_TYPE") "NodePort" }}
listener.security.protocol.map=EXTERNAL:PLAINTEXT,INTERNAL:PLAINTEXT
listeners=EXTERNAL://0.0.0.0:{{ getenv "KAFKA_PORT" "9094" }},INTERNAL://0.0.0.0:9092
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_KAFKA_NODEPORT_MAP") -}}
{{- with index $m $pod }}
advertised.listeners=EXTERNAL://{{ getenv "NODEPORT_IP" }}:{{ . }},INTERNAL://{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}:9092
{{- end }}
inter.broker.listener.name=INTERNAL
{{- end }}

{{- if eq (getenv "UNIT_SERVICE_TYPE") "LoadBalancer" }}
listener.security.protocol.map=EXTERNAL:PLAINTEXT,INTERNAL:PLAINTEXT
listeners=EXTERNAL://0.0.0.0:{{ getenv "KAFKA_PORT" "9094" }},INTERNAL://0.0.0.0:9092
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_LOADBALANCER_IP_MAP") -}}
{{- with index $m $pod }}
advertised.listeners=EXTERNAL://{{ . }}:{{ getenv "KAFKA_PORT" "9094" }},INTERNAL://{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}:9092
{{- end }}
inter.broker.listener.name=INTERNAL
{{- end }}

{{- if eq (getenv "UNIT_SERVICE_TYPE") "ClusterIP" }}
listener.security.protocol.map=EXTERNAL:PLAINTEXT,INTERNAL:PLAINTEXT
listeners=EXTERNAL://0.0.0.0:{{ getenv "KAFKA_PORT" "9094" }},INTERNAL://0.0.0.0:9092
advertised.listeners=EXTERNAL://{{ getenv "POD_NAME" }}.{{ getenv "NAMESPACE" }}:{{ getenv "KAFKA_PORT" "9094" }},INTERNAL://{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}:9092
inter.broker.listener.name=INTERNAL
{{- end }}

default.replication.factor={{ getv "/defaults/default_replication_factor" }}
inter.broker.protocol.version=3.5
min.insync.replicas={{ getv "/defaults/min_insync_replicas" }}
offsets.topic.replication.factor={{ getv "/defaults/offsets_topic_replication_factor" }}
transaction.state.log.min.isr={{ getv "/defaults/transaction_state_log_min_isr" }}
transaction.state.log.replication.factor={{ getv "/defaults/transaction_state_log_replication_factor" }}
log.message.format.version=3.5
num.network.threads={{ getv "/defaults/num_network_threads" }}
num.io.threads={{ getv "/defaults/num_io_threads" }}
socket.send.buffer.bytes={{ getv "/defaults/socket_send_buffer_bytes" }}
socket.receive.buffer.bytes={{ getv "/defaults/socket_receive_buffer_bytes" }}
socket.request.max.bytes={{ getv "/defaults/socket_request_max_bytes" }}
num.partitions={{ getv "/defaults/num_partitions" }}
num.recovery.threads.per.data.dir={{ getv "/defaults/num_recovery_threads_per_data_dir" }}
log.retention.hours={{ getv "/defaults/log_retention_hours" }}
log.segment.bytes={{ getv "/defaults/log_segment_bytes" }}
log.retention.check.interval.ms={{ getv "/defaults/log_retention_check_interval_ms" }}
group.initial.rebalance.delay.ms={{ getv "/defaults/group_initial_rebalance_delay_ms" }}
delete.topic.enable={{ getv "/defaults/delete_topic_enable" }}
auto.create.topics.enable={{ getv "/defaults/auto_create_topics_enable" }}

zookeeper.connect={{ getenv "ZOOKEEPER_SERVICE_NAME" }}-svc.{{ getenv "NAMESPACE" }}.svc:{{ getenv "ZOOKEEPER_PORT" "2181" }}
zookeeper.connection.timeout.ms={{ getv "/defaults/zookeeper_connection_timeout_ms" }}

