protected-mode no
bind 0.0.0.0
port {{ getenv "REDIS_PORT" "6379" }}
tcp-backlog {{ getv "/defaults/tcp-backlog" }}
unixsocket {{ getenv "DATA_MOUNT" }}/redis.sock
timeout {{ getv "/defaults/timeout" }}
tcp-keepalive {{ getv "/defaults/tcp-keepalive" }}
daemonize no
supervised auto
pidfile {{ getenv "DATA_MOUNT" }}/redis-server.pid
loglevel {{ getv "/defaults/loglevel" }}
logfile {{ getenv "LOG_MOUNT" }}/redis-server.log
databases {{ getv "/defaults/databases" }}
always-show-logo {{ getv "/defaults/always-show-logo" }}
{{- range jsonArray (getv "/defaults/save")}}
save {{.}}
{{- end }}
rdbcompression {{ getv "/defaults/rdbcompression" }}
rdbchecksum {{ getv "/defaults/rdbchecksum" }}
dbfilename dump.rdb
dir "{{ getenv "DATA_MOUNT" }}/data"
user default on sanitize-payload #{{ sha256sum (AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER"))) }}  ~* &* +@all
maxclients {{ getv "/defaults/maxclients" }}
maxmemory {{ mul (div (atoi (getenv "REDIS_MEMORY_LIMIT")) 100) 48 }}mb
maxmemory-policy {{ getv "/defaults/maxmemory-policy" }}
maxmemory-samples {{ getv "/defaults/maxmemory-samples" }}
repl-diskless-sync {{ getv "/defaults/repl-diskless-sync" }}
repl-diskless-sync-delay {{ getv "/defaults/repl-diskless-sync-delay" }}
lazyfree-lazy-eviction {{ getv "/defaults/lazyfree-lazy-eviction" }}
lazyfree-lazy-expire {{ getv "/defaults/lazyfree-lazy-expire" }}
appendonly {{ getv "/defaults/appendonly" }}
appendfilename appendonly.aof
appendfsync {{ getv "/defaults/appendfsync" }}
no-appendfsync-on-rewrite {{ getv "/defaults/no-appendfsync-on-rewrite" }}
auto-aof-rewrite-percentage {{ getv "/defaults/auto-aof-rewrite-percentage" }}
auto-aof-rewrite-min-size {{ getv "/defaults/auto-aof-rewrite-min-size" }}
aof-load-truncated {{ getv "/defaults/aof-load-truncated" }}
aof-use-rdb-preamble {{ getv "/defaults/aof-use-rdb-preamble" }}
lua-time-limit {{ getv "/defaults/lua-time-limit" }}
{{- if eq (getenv "ARCH_MODE") "cluster" }}
min-replicas-to-write {{ getv "/defaults/min-replicas-to-write" }}
min-replicas-max-lag {{ getv "/defaults/min-replicas-max-lag" }}
replica-lazy-flush {{ getv "/defaults/replica-lazy-flush" }}
masterauth "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }}"
cluster-port {{ add (atoi (getenv "REDIS_PORT" "6379")) 10000 }}
cluster-enabled yes
cluster-config-file "{{ getenv "DATA_MOUNT" }}/conf/nodes.conf"
cluster-node-timeout {{ getv "/defaults/cluster-node-timeout" }}
cluster-require-full-coverage {{ getv "/defaults/cluster-require-full-coverage" }}
cluster-preferred-endpoint-type ip
{{- if eq (getenv "UNIT_SERVICE_TYPE") "ClusterIP" }}
{{- $podname := getenv "POD_NAME" -}}
{{- $namespace := getenv "NAMESPACE" -}}
{{- $svrname := printf "%s-svc.%s.svc" $podname $namespace }}
cluster-announce-ip {{index (lookupIP $svrname) 0}}
cluster-announce-port {{ getenv "REDIS_PORT" "6379" }}
cluster-announce-bus-port {{ add (atoi (getenv "REDIS_PORT" "6379")) 10000 }}
{{- end }}
{{- if eq (getenv "UNIT_SERVICE_TYPE") "NodePort" }}
cluster-announce-ip {{ getenv "NODEPORT_IP" }}
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_REDIS_NODEPORT_MAP") -}}
{{- with index $m $pod }}
cluster-announce-port {{ . }}
{{- end }}
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_REDIS_CLUSTER_BUS_NODEPORT_MAP") -}}
{{- with index $m $pod }}
cluster-announce-bus-port {{ . }}
{{- end }}
{{- end }}
{{- if eq (getenv "UNIT_SERVICE_TYPE") "LoadBalancer" }}
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_LOADBALANCER_IP_MAP") -}}
{{- with index $m $pod }}
cluster-announce-ip {{ . }}
cluster-announce-port {{ getenv "REDIS_PORT" "6379" }}
cluster-announce-bus-port {{ add (atoi (getenv "REDIS_PORT" "6379")) 10000 }}
{{- end }}
{{- end }}
{{- end }}
{{- if eq (getenv "ARCH_MODE") "replication" }}
{{- if ( checkLabelExists (getenv "POD_NAME") (getenv "NAMESPACE") "compose-operator/redis-replication.readonly" ) }}
{{- if eq ( getPodLabelValueByKey (getenv "POD_NAME") (getenv "NAMESPACE") "compose-operator/redis-replication.readonly" ) "true" }}
replicaof {{ getPodLabelValueByKey (getenv "POD_NAME") (getenv "NAMESPACE") "compose-operator/redis-replication.source.host" }} {{ getPodLabelValueByKey (getenv "POD_NAME") (getenv "NAMESPACE") "compose-operator/redis-replication.source.port" }}
{{- end }}
{{- end }}
masterauth "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }}"
min-replicas-to-write {{ getv "/defaults/min-replicas-to-write" }}
min-replicas-max-lag {{ getv "/defaults/min-replicas-max-lag" }}
replica-lazy-flush {{ getv "/defaults/replica-lazy-flush" }}
{{- if eq (getenv "UNIT_SERVICE_TYPE") "ClusterIP" }}
replica-announce-ip {{ getenv "POD_NAME" }}-svc.{{ getenv "NAMESPACE" }}.svc
replica-announce-port {{ getenv "REDIS_PORT" "6379" }}
{{- end }}
{{- if eq (getenv "UNIT_SERVICE_TYPE") "NodePort" }}
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_REDIS_NODEPORT_MAP") -}}
{{- with index $m $pod }}
replica-announce-ip {{ getenv "NODEPORT_IP" }}
replica-announce-port {{ . }}
{{- end }}
{{- end }}
{{- if eq (getenv "UNIT_SERVICE_TYPE") "LoadBalancer" }}
{{- $pod := getenv "POD_NAME" -}}
{{- $m := json (getenv "UNIT_SERVICE_LOADBALANCER_IP_MAP") -}}
{{- with index $m $pod }}
replica-announce-ip {{ . }}
replica-announce-port {{ getenv "REDIS_PORT" "6379" }}
{{- end }}
{{- end }}
{{- end }}
slowlog-log-slower-than {{ getv "/defaults/slowlog-log-slower-than" }}
slowlog-max-len {{ getv "/defaults/slowlog-max-len" }}
latency-monitor-threshold {{ getv "/defaults/latency-monitor-threshold" }}
notify-keyspace-events "{{ getv "/defaults/notify-keyspace-events" }}"
hash-max-listpack-entries {{ getv "/defaults/hash-max-listpack-entries" }}
hash-max-listpack-value {{ getv "/defaults/hash-max-listpack-value" }}
list-max-ziplist-size {{ getv "/defaults/list-max-ziplist-size" }}
list-compress-depth {{ getv "/defaults/list-compress-depth" }}
set-max-intset-entries {{ getv "/defaults/set-max-intset-entries" }}
zset-max-listpack-entries {{ getv "/defaults/zset-max-listpack-entries" }}
zset-max-listpack-value {{ getv "/defaults/zset-max-listpack-value" }}
hll-sparse-max-bytes {{ getv "/defaults/hll-sparse-max-bytes" }}
stream-node-max-bytes {{ getv "/defaults/stream-node-max-bytes" }}
stream-node-max-entries {{ getv "/defaults/stream-node-max-entries" }}
activerehashing {{ getv "/defaults/activerehashing" }}
{{- range jsonArray (getv "/defaults/client-output-buffer-limit")}}
client-output-buffer-limit {{.}}
{{- end }}
hz {{ getv "/defaults/hz" }}
dynamic-hz {{ getv "/defaults/dynamic-hz" }}
aof-rewrite-incremental-fsync {{ getv "/defaults/aof-rewrite-incremental-fsync" }}
rdb-save-incremental-fsync {{ getv "/defaults/rdb-save-incremental-fsync" }}
