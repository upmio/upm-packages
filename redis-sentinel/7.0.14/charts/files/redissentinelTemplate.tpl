protected-mode no
port {{ getenv "SENTINEL_PORT" "26379" }}
daemonize no
pidfile "{{ getenv "DATA_MOUNT" }}/redis-sentinel.pid"
loglevel {{ getv "/defaults/loglevel" }}
logfile "{{ getenv "LOG_MOUNT" }}/redis-sentinel.log"
sentinel announce-ip {{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}
dir "{{ getenv "DATA_MOUNT" }}/data"
{{- range $index, $value := jsonArray (getv "/service_redis_array")}}
{{- $master_ip := printf "/%s_redis-sentinel_master_ip" $value }}
sentinel monitor {{ $value }} {{ getv $master_ip }} {{ getv "/redis_redis_port" }} 2
sentinel auth-pass {{ $value }} "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }}"
sentinel down-after-milliseconds {{ $value }} {{ getv "/defaults/down-after-milliseconds" }}
sentinel parallel-syncs {{ $value }} 1
sentinel failover-timeout {{ $value }} {{ getv "/defaults/failover-timeout" }}
sentinel client-reconfig-script {{ $value }} /usr/local/bin/sentinelReconfig.sh
sentinel master-reboot-down-after-period {{ $value }} {{ getv "/defaults/master-reboot-down-after-period" }}
{{- end }}
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
