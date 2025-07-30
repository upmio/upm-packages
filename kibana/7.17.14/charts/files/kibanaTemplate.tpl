server.port: {{ getenv "KIBANA_PORT" }}
server.host: 0.0.0.0
elasticsearch.hosts:
{{- range jsonArray (getv "/master_member_list") }}
- "https://{{.}}:{{ getv "/elasticsearch_elasticsearch_port" }}"
{{- end }}
elasticsearch.ssl.certificate: "{{ getenv "CONF_DIR" }}/tls.crt"
elasticsearch.ssl.key: "{{ getenv "CONF_DIR" }}/tls.key"
elasticsearch.ssl.certificateAuthorities: ["{{ getenv "CONF_DIR" }}/ca.crt"]
elasticsearch.ssl.verificationMode: certificate
elasticsearch.username: "{{ getenv "KBN_USER" }}_user"
elasticsearch.password: "{{ AESCBCDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "KBN_USER")) }}"
pid.file: {{getenv "DATA_MOUNT"}}/kibana.pid
i18n.locale: "{{ getv "/defaults/i18n_locale" }}"
xpack.encryptedSavedObjects.encryptionKey: {{ getv "/defaults/encryption_key" }}
xpack.reporting.encryptionKey: {{ getv "/defaults/encryption_key" }}
xpack.security.encryptionKey: {{ getv "/defaults/encryption_key" }}
monitoring.enabled: {{ getv "/defaults/monitoring_enabled" }}
monitoring.ui.container.apm.enabled: {{ getv "/defaults/monitoring_ui_container_apm_enabled" }}
monitoring.ui.container.elasticsearch.enabled: {{ getv "/defaults/monitoring_ui_container_elasticsearch_enabled" }}