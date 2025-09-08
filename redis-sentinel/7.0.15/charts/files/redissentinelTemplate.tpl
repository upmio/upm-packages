protected-mode no
port {{ getenv "REDIS_SENTINEL_PORT" "26379" }}
daemonize no
pidfile "{{ getenv "DATA_MOUNT" }}/redis-sentinel.pid"
loglevel {{ getv "/defaults/loglevel" }}
logfile "{{ getenv "LOG_MOUNT" }}/redis-sentinel.log"
dir "{{ getenv "DATA_MOUNT" }}/data"
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel announce-ip {{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}
sentinel announce-port {{ getenv "REDIS_SENTINEL_PORT" "26379" }}
sentinel monitor {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getenv "REDIS_REPLICATION_SOURCE_HOST" }} {{ getenv "REDIS_REPLICATION_SOURCE_PORT" "6379" }} 2
sentinel auth-pass {{ getenv "REDIS_MASTER_NAME" "mymaster" }} "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }}"
sentinel down-after-milliseconds {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getv "/defaults/down-after-milliseconds" }}
sentinel parallel-syncs {{ getenv "REDIS_MASTER_NAME" "mymaster" }} 1
sentinel failover-timeout {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getv "/defaults/failover-timeout" }}
sentinel client-reconfig-script {{ getenv "REDIS_MASTER_NAME" "mymaster" }} /usr/local/bin/sentinelReconfig.sh
sentinel master-reboot-down-after-period {{ getenv "REDIS_MASTER_NAME" "mymaster" }} {{ getv "/defaults/master-reboot-down-after-period" }}
