path.data: "{{ getenv "DATA_DIR" }}"
path.logs: "{{ getenv "LOG_MOUNT" }}"
cluster.name: "{{ getenv "SERVICE_GROUP_NAME" }}"
node.name: "{{ getenv "POD_NAME" }}"
network.host: "{{ getv "/defaults/network_host" }}"
node.roles: {{ getenv "NODE_ROLES" }}
http.port: {{ getenv "ELASTICSEARCH_PORT" "9200" }}
transport.port: {{ getenv "TRANSPORT_PORT" "9300" }}
discovery.seed_hosts: {{ getenv "ALL_MEMBER_LIST" }}
cluster.initial_master_nodes: {{ getenv "MASTER_MEMBER_LIST" }}
xpack.monitoring.collection.enabled: true
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: {{ getenv "ES_PATH_CONF" }}/tls.key
xpack.security.transport.ssl.certificate: {{ getenv "ES_PATH_CONF" }}/tls.crt
xpack.security.transport.ssl.certificate_authorities: ["{{ getenv "ES_PATH_CONF" }}/ca.crt"]
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.key: {{ getenv "ES_PATH_CONF" }}/tls.key
xpack.security.http.ssl.certificate: {{ getenv "ES_PATH_CONF" }}/tls.crt
xpack.security.http.ssl.certificate_authorities: ["{{ getenv "ES_PATH_CONF" }}/ca.crt"]
