server.port: {{ getenv "KIBANA_PORT" "5601" }}
server.host: 0.0.0.0
elasticsearch.hosts:
{{- range jsonArray (getenv "MASTER_MEMBER_LIST") }}
- "https://{{.}}:{{ getenv "ELASTICSEARCH_PORT" "9200" }}"
{{- end }}
elasticsearch.ssl.certificate: "{{ getenv "CONF_DIR" }}/tls.crt"
elasticsearch.ssl.key: "{{ getenv "CONF_DIR" }}/tls.key"
elasticsearch.ssl.certificateAuthorities: ["{{ getenv "CONF_DIR" }}/ca.crt"]
elasticsearch.ssl.verificationMode: certificate
elasticsearch.username: "{{ getenv "KBN_USER" }}_user"
elasticsearch.password: "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "KBN_USER")) }}"
pid.file: {{ getenv "DATA_MOUNT" }}/kibana.pid
i18n.locale: "{{ getv "/defaults/i18n_locale" }}"
xpack.encryptedSavedObjects.encryptionKey: {{ getenv "AES_SECRET_KEY" }}
xpack.reporting.encryptionKey:  {{ getenv "AES_SECRET_KEY" }}
xpack.security.encryptionKey:  {{ getenv "AES_SECRET_KEY" }}
monitoring.enabled: {{ getv "/defaults/monitoring_enabled" }}
monitoring.ui.container.apm.enabled: {{ getv "/defaults/monitoring_ui_container_apm_enabled" }}
monitoring.ui.container.elasticsearch.enabled: {{ getv "/defaults/monitoring_ui_container_elasticsearch_enabled" }}
