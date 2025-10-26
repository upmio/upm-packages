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
  maxIncomingConnections: {{ getv "/mongodb/max_incoming_connections" }}
storage:
  dbPath: {{ getenv "DATA_DIR" }}
  wiredTiger:
    engineConfig:
      cacheSizeGB: {{ div (atoi (getenv "MONGODB_MEMORY_LIMIT")) 2 }}
      journalCompressor: {{ getv "/mongodb/journal_compressor" }}
    collectionConfig:
      blockCompressor: {{ getv "/mongodb/block_compressor" }}
replication:
  replSetName: {{ getenv "SERVICE_GROUP_NAME" }}
  oplogSizeMB: {{ getv "/mongodb/oplog_size_mb" }}
operationProfiling:
  mode: slowOp
  slowOpThresholdMs: {{ getv "/mongodb/slow_op_threshold_ms" }}
setParameter:
  enableLocalhostAuthBypass: false
  cursorTimeoutMillis: {{ getv "/mongodb/cursor_timeout_millis" }}
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