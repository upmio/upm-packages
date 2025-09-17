protected-mode no
port {{ getenv "REDIS_SENTINEL_PORT" "26379" }}
daemonize no
pidfile "{{ getenv "DATA_MOUNT" "/DATA_MOUNT" }}/redis-sentinel.pid"
loglevel {{ getv "/defaults/loglevel" }}
logfile "{{ getenv "LOG_MOUNT" "/LOG_MOUNT" }}/redis-sentinel.log"
dir "{{ getenv "DATA_MOUNT" "/DATA_MOUNT" }}/data"
user default on sanitize-payload #{{ sha256sum (AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER" "default"))) }}  ~* &* +@all
latency-tracking yes
latency-tracking-info-percentiles 50 99 99.9
sentinel myid {{ sha1sum (getenv "POD_NAME") }}
sentinel announce-ip {{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}
sentinel announce-port {{ getenv "REDIS_SENTINEL_PORT" "26379" }}
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel monitor {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getPodLabelValueByKey (getenv "POD_NAME") (getenv "NAMESPACE") "compose-operator/redis-replication.source.host" }} {{ getPodLabelValueByKey (getenv "POD_NAME") (getenv "NAMESPACE") "compose-operator/redis-replication.source.port" }} 2
sentinel auth-user {{ getenv "REDIS_MASTER_NAME" "mymaster" }} default
sentinel auth-pass {{ getenv "REDIS_MASTER_NAME" "mymaster" }} "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER" "default")) }}"
sentinel sentinel-user default
sentinel sentinel-pass "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER" "default")) }}"
sentinel down-after-milliseconds {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getv "/defaults/down-after-milliseconds" }}
sentinel parallel-syncs {{ getenv "REDIS_MASTER_NAME" "mymaster" }} 1
sentinel failover-timeout {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getv "/defaults/failover-timeout" }}
sentinel client-reconfig-script {{ getenv "REDIS_MASTER_NAME" "mymaster" }} /usr/local/bin/sentinelReconfig.sh
sentinel master-reboot-down-after-period {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getv "/defaults/master-reboot-down-after-period" }}
