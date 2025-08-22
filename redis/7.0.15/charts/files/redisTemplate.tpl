protected-mode no
replica-announce-ip {{ getenv "POD_NAME" }}.{{ getenv "SERVICE_NAME" }}-headless-svc.{{ getenv "NAMESPACE" }}
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
masterauth "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }}"
requirepass "{{ AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER")) }}"
user default on sanitize-payload #{{ sha256sum (AESCTRDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "ADM_USER"))) }}  ~* &* +@all
maxclients {{ getv "/defaults/maxclients" }}
maxmemory {{ mul (div (atoi (getenv "REDIS_MEMORY_LIMIT")) 4) 3 }}mb
maxmemory-policy {{ getv "/defaults/maxmemory-policy" }}
maxmemory-samples {{ getv "/defaults/maxmemory-samples" }}
lazyfree-lazy-eviction {{ getv "/defaults/lazyfree-lazy-eviction" }}
lazyfree-lazy-expire {{ getv "/defaults/lazyfree-lazy-expire" }}
replica-lazy-flush {{ getv "/defaults/replica-lazy-flush" }}
appendonly {{ getv "/defaults/appendonly" }}
appendfilename appendonly.aof
appendfsync {{ getv "/defaults/appendfsync" }}
no-appendfsync-on-rewrite {{ getv "/defaults/no-appendfsync-on-rewrite" }}
auto-aof-rewrite-percentage {{ getv "/defaults/auto-aof-rewrite-percentage" }}
auto-aof-rewrite-min-size {{ getv "/defaults/auto-aof-rewrite-min-size" }}
aof-load-truncated {{ getv "/defaults/aof-load-truncated" }}
aof-use-rdb-preamble {{ getv "/defaults/aof-use-rdb-preamble" }}
lua-time-limit {{ getv "/defaults/lua-time-limit" }}
{{- if contains (getenv "ARCH_MODE") "cluster" }}
cluster-enabled yes
cluster-config-file "{{ getenv "DATA_MOUNT" }}/conf/nodes.conf"
cluster-node-timeout {{ getv "/defaults/cluster-node-timeout" }}
cluster-require-full-coverage {{ getv "/defaults/cluster-require-full-coverage" }}
cluster-preferred-endpoint-type ip
{{- $podname := getenv "POD_NAME" }}
{{- $namespace := getenv "NAMESPACE" }}
{{- $svrname := printf "%s.%s.svc" $podname $namespace }}
cluster-announce-ip {{index (lookupIP $svrname) 0}}
{{- end }}
slowlog-log-slower-than {{ getv "/defaults/slowlog-log-slower-than" }}
slowlog-max-len {{ getv "/defaults/slowlog-max-len" }}
latency-monitor-threshold {{ getv "/defaults/latency-monitor-threshold" }}
notify-keyspace-events "{{ getv "/defaults/notify-keyspace-events" }}"
hash-max-ziplist-entries {{ getv "/defaults/hash-max-ziplist-entries" }}
hash-max-ziplist-value {{ getv "/defaults/hash-max-ziplist-value" }}
list-max-ziplist-size {{ getv "/defaults/list-max-ziplist-size" }}
list-compress-depth {{ getv "/defaults/list-compress-depth" }}
set-max-intset-entries {{ getv "/defaults/set-max-intset-entries" }}
zset-max-ziplist-entries {{ getv "/defaults/zset-max-ziplist-entries" }}
zset-max-ziplist-value {{ getv "/defaults/zset-max-ziplist-value" }}
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
