systemLog:
  destination: file
  path: {{ getenv "LOG_MOUNT" }}/mongod.log
  logAppend: true
  logRotate: reopen
  verbosity: 0
processManagement:
  pidFilePath: {{ getenv "DATA_MOUNT" }}/mongod.pid
net:
  port: {{ getenv "MONGODB_PORT"}}
  bindIp: 0.0.0.0
  maxIncomingConnections: {{ getv "/net/max_incoming_connections" }}
storage:
  dbPath: {{ getenv "DATA_DIR" }}
  wiredTiger:
    engineConfig:
      cacheSizeGB: {{ $mem := atoi (getenv "MONGODB_MEMORY_LIMIT") -}}{{ $cacheMi := div $mem 2 -}}{{- if ge $mem 4096 -}}{{ $cacheMi = div (sub $mem 1024) 2 -}}{{- end -}}{{ $centiGb := div (add (mul $cacheMi 100) 512) 1024 -}}{{ printf "%d.%02d" (div $centiGb 100) (sub $centiGb (mul (div $centiGb 100) 100)) }}
      journalCompressor: {{ getv "/storage/journal_compressor" }}
    collectionConfig:
      blockCompressor: {{ getv "/storage/block_compressor" }}
replication:
  replSetName: {{ getenv "SERVICE_GROUP_NAME" }}
operationProfiling:
  mode: slowOp
  slowOpThresholdMs: {{ getv "/operationProfiling/slow_op_threshold_ms" }}
setParameter:
  enableLocalhostAuthBypass: false
  cursorTimeoutMillis: {{ getv "/setParameter/cursor_timeout_millis" }}
security:
  authorization: enabled
  keyFile: {{ getenv "DATA_MOUNT" }}/mongod.key
{{- if eq (getenv "ARCH_MODE") "shardsvr" }} 
sharding:
  clusterRole: shardsvr
{{- else if eq (getenv "ARCH_MODE") "configsvr" }}
sharding:
  clusterRole: configsvr
{{ end }}