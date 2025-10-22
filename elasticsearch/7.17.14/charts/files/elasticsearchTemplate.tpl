path.data: "{{ getenv "DATA_DIR" }}"
path.logs: "{{ getenv "LOG_MOUNT" }}"
cluster.name: "{{ getenv "SERVICE_GROUP_NAME" }}"
node.name: "{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}.svc.cluster.local"
network.host: "{{ getv "/defaults/network_host" }}"
{{- if eq (getenv "ARCH_MODE") "master" }}
node.roles: ["master","ingest","remote_cluster_client"]
{{- end }}
{{- if eq (getenv "ARCH_MODE") "data" }}
node.roles: ["master","data","ingest","remote_cluster_client"]
{{- end }}
{{- if eq (getenv "ARCH_MODE") "data_warm" }}
node.roles: ["data_warm","ingest","remote_cluster_client"]
{{- end }}
{{- if eq (getenv "ARCH_MODE") "data_hot" }}
node.roles: ["data_hot","data_content","ingest","remote_cluster_client"]
{{- end }}
{{- if eq (getenv "ARCH_MODE") "coordinate" }}
node.roles: []
{{- end }}
http.port: {{ getenv "ELASTICSEARCH_PORT" "9200" }}
transport.port: {{ getenv "TRANSPORT_PORT" "9300" }}
discovery.seed_hosts: {{ getenv "ALL_MEMBER_LIST" }}
cluster.initial_master_nodes: {{ getenv "MASTER_MEMBER_LIST" }}
xpack.monitoring.collection.enabled: true
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: {{ getenv "CONF_DIR" }}/tls.key
xpack.security.transport.ssl.certificate: {{ getenv "CONF_DIR" }}/tls.crt
xpack.security.transport.ssl.certificate_authorities: ["{{ getenv "CONF_DIR" }}/ca.crt"]
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.key: {{ getenv "CONF_DIR" }}/tls.key
xpack.security.http.ssl.certificate: {{ getenv "CONF_DIR" }}/tls.crt
xpack.security.http.ssl.certificate_authorities: ["{{ getenv "CONF_DIR" }}/ca.crt"]
