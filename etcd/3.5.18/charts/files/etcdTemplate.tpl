name: {{ getenv "POD_NAME" }}
data-dir: {{ getenv "DATA_DIR" }}

logger: zap

listen-client-urls: https://0.0.0.0:{{ getenv "ETCD_PORT" "2379" }}
listen-peer-urls: https://0.0.0.0:{{ getenv "PEER_PORT" "2380" }}
listen-metrics-urls:  https://0.0.0.0:{{ getenv "METRICS_PORT" "2381" }}
advertise-client-urls: https://{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}.svc.cluster.local:{{ getenv "ETCD_PORT" "2379" }}
initial-advertise-peer-urls: https://{{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}.svc.cluster.local:{{ getenv "PEER_PORT" "2380" }}

{{- $serviceName := getenv "SERVICE_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $peerPort := getenv "PEER_PORT" "2380" }}
{{- $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
initial-cluster: {{ $unitCount := atoi (getenv "UNIT_COUNT" "3") }}
{{- range $i := seq 0 (sub $unitCount 1) -}}
{{ printf "%s-%d=https://%s-%d.%s-headless-svc.%s.svc.cluster.local:%s" $serviceName $i $serviceName $i $serviceName $namespace $peerPort }}{{if lt $i (sub $unitCount 1)}},{{- end}}
{{- end }}

initial-cluster-token: {{ getenv "SERVICE_GROUP_NAME" }}
initial-cluster-state: new

client-transport-security:
  cert-file: {{ getenv "CERT_MOUNT" }}/tls.crt
  key-file: {{ getenv "CERT_MOUNT" }}/tls.key
  client-cert-auth: true
  trusted-ca-file: "{{ getenv "CERT_MOUNT" }}/ca.crt"

peer-transport-security:
  cert-file: {{ getenv "CERT_MOUNT" }}/tls.crt
  key-file: {{ getenv "CERT_MOUNT" }}/tls.key
  client-cert-auth: true
  trusted-ca-file: "{{ getenv "CERT_MOUNT" }}/ca.crt"

quota-backend-bytes: {{ getv "/defaults/quota_backend_bytes"}}
heartbeat-interval: {{ getv "/defaults/heartbeat_interval"}}
election-timeout: {{ getv "/defaults/election_timeout"}}
