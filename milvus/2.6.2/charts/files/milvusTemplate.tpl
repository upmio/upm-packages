common:
  DiskIndex:
    BeamWidthRatio: 4
    BuildNumThreadsRatio: 1
    LoadNumThreadRatio: 8
    MaxDegree: 56
    PQCodeBudgetGBRatio: 0.125
    SearchCacheBudgetGBRatio: 0.1
    SearchListSize: 100
  bloomFilterApplyBatchSize: 1000
  bloomFilterSize: 100000
  bloomFilterType: BlockedBloomFilter
  buildIndexThreadPoolRatio: 0.75
  collectionReplicateEnable: false
  defaultIndexName: _default_idx
  defaultPartitionName: _default
  diskWriteBufferSizeKb: 64
  diskWriteMode: buffered
  diskWriteNumThreads: 0
  diskWriteRateLimiter:
    avgKBps: 262144
    highPriorityRatio: -1
    lowPriorityRatio: -1
    maxBurstKBps: 524288
    middlePriorityRatio: -1
    refillPeriodUs: 100000
  enableConfigParamTypeCheck: true
  enablePosixMode: false
  enableVectorClusteringKey: false
  enabledGrowingSegmentJSONKeyStats: false
  enabledJSONKeyStats: false
  enabledOptimizeExpr: true
  entityExpiration: -1
  gracefulStopTimeout: 1800
  gracefulTime: 5000
  indexSliceSize: 16
  localRPCEnabled: false
  locks:
    maxWLockConditionalWaitTime: 600
    metrics:
      enable: false
    threshold:
      info: 500
      warn: 1000
  maxBloomFalsePositive: 0.001
  retentionDuration: {{ getv "/defaults/common_retention_duration" }}
  security:
    authorizationEnabled: true
    defaultRootPassword: {{ AESCBCDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "MILVUS_USER")) }}
    enablePublicPrivilege: true
    internaltlsEnabled: false
    rbac:
      cluster:
        admin:
          privileges: ListDatabases,SelectOwnership,SelectUser,DescribeResourceGroup,ListResourceGroups,ListPrivilegeGroups,FlushAll,TransferNode,TransferReplica,UpdateResourceGroups,BackupRBAC,RestoreRBAC,CreateDatabase,DropDatabase,CreateOwnership,DropOwnership,ManageOwnership,CreateResourceGroup,DropResourceGroup,UpdateUser,RenameCollection,CreatePrivilegeGroup,DropPrivilegeGroup,OperatePrivilegeGroup
        readonly:
          privileges: ListDatabases,SelectOwnership,SelectUser,DescribeResourceGroup,ListResourceGroups,ListPrivilegeGroups
        readwrite:
          privileges: ListDatabases,SelectOwnership,SelectUser,DescribeResourceGroup,ListResourceGroups,ListPrivilegeGroups,FlushAll,TransferNode,TransferReplica,UpdateResourceGroups
      collection:
        admin:
          privileges: Query,Search,IndexDetail,GetFlushState,GetLoadState,GetLoadingProgress,HasPartition,ShowPartitions,DescribeCollection,DescribeAlias,GetStatistics,ListAliases,GetImportProgress,ListImport,Load,Release,Insert,Delete,Upsert,Import,Flush,Compaction,LoadBalance,CreateIndex,DropIndex,CreatePartition,DropPartition,AddCollectionField,CreateAlias,DropAlias
        readonly:
          privileges: Query,Search,IndexDetail,GetFlushState,GetLoadState,GetLoadingProgress,HasPartition,ShowPartitions,DescribeCollection,DescribeAlias,GetStatistics,ListAliases,GetImportProgress,ListImport
        readwrite:
          privileges: Query,Search,IndexDetail,GetFlushState,GetLoadState,GetLoadingProgress,HasPartition,ShowPartitions,DescribeCollection,DescribeAlias,GetStatistics,ListAliases,GetImportProgress,ListImport,Load,Release,Insert,Delete,Upsert,Import,Flush,Compaction,LoadBalance,CreateIndex,DropIndex,CreatePartition,DropPartition,AddCollectionField
      database:
        admin:
          privileges: ShowCollections,DescribeDatabase,AlterDatabase,CreateCollection,DropCollection
        readonly:
          privileges: ShowCollections,DescribeDatabase
        readwrite:
          privileges: ShowCollections,DescribeDatabase,AlterDatabase
      overrideBuiltInPrivilegeGroups:
        enabled: false
    rootShouldBindRole: false
    superUsers: null
    tlsMode: 0
  session:
    retryTimes: 30
    ttl: 10
  simdType: auto
  storage:
    enablev2: true
  storageType: remote
  sync:
    taskPoolReleaseTimeoutSeconds: 60
  threadCoreCoefficient:
    highPriority: 10
    lowPriority: 1
    middlePriority: 5
  traceLogMode: 0
  ttMsgEnabled: true
  usePartitionKeyAsClusteringKey: false
  useVectorAsClusteringKey: false
credential:
  aksk1:
    access_key_id: null
    secret_access_key: null
  apikey1:
    apikey: null
  gcp1:
    credential_json: null
dataCoord:
  autoBalance: true
  autoUpgradeSegmentIndex: false
  brokerTimeout: 5000
  channel:
    balanceInterval: 360
    balanceSilentDuration: 300
    checkInterval: 1
    legacyVersionWithoutRPCWatch: 2.4.1
    notifyChannelOperationTimeout: 5
    watchTimeoutInterval: 300
  checkAutoBalanceConfigInterval: 10
  compaction:
    clustering:
      autoEnable: false
      enable: true
      maxCentroidsNum: 10240
      maxClusterSize: 5g
      maxClusterSizeRatio: 10
      maxInterval: 259200
      maxSegmentSizeRatio: 1
      maxTrainSizeRatio: 0.8
      minCentroidsNum: 16
      minClusterSizeRatio: 0.01
      minInterval: 3600
      newDataSizeThreshold: 512m
      preferSegmentSizeRatio: 0.8
      triggerInterval: 600
    dropTolerance: 86400
    enableAutoCompaction: true
    expiry:
      tolerance: -1
    gcInterval: 1800
    indexBasedCompaction: true
    levelzero:
      forceTrigger:
        deltalogMaxNum: 30
        deltalogMinNum: 10
        maxSize: 67108864
        minSize: 8388608
      triggerInterval: 10
    maxParallelTaskNum: -1
    mix:
      triggerInterval: 60
    rpcTimeout: 10
    scheduleInterval: 500
    single:
      deltalog:
        maxnum: 200
        maxsize: 16777216
      expiredlog:
        maxsize: 10485760
      ratio:
        threshold: 0.2
    taskPrioritizer: default
    taskQueueCapacity: 100000
  enableActiveStandby: true
  enableCompaction: true
  enableGarbageCollection: true
  forceRebuildSegmentIndex: false
  gc:
    dropTolerance: 10800
    interval: 3600
    missingTolerance: 86400
    scanInterval: 168
    slowDownCPUUsageThreshold: 0.6
  gracefulStopTimeout: 5
  grpc:
    clientMaxRecvSize: 536870912
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 268435456
    serverMaxSendSize: 536870912
  import:
    checkIntervalHigh: 2
    checkIntervalLow: 120
    fileNumPerSlot: 1
    filesPerPreImportTask: 2
    maxImportFileNumPerReq: 1024
    maxImportJobNum: 1024
    maxSizeInMBPerImportTask: 16384
    memoryLimitPerSlot: 160
    scheduleInterval: 2
    taskRetention: 10800
    waitForIndex: true
  index:
    memSizeEstimateMultiplier: 2
  ip: null
  jsonKeyStatsMemoryBudgetInTantivy: 16777216
  jsonStatsTriggerCount: 10
  jsonStatsTriggerInterval: 10
  port: 13333
  sealPolicy:
    channel:
      blockingL0EntryNum: 5000000
      blockingL0SizeInMB: 64
      growingSegmentsMemSize: 4096
  segment:
    allocLatestExpireAttempt: 200
    assignmentExpiration: 2000
    compactableProportion: 0.85
    diskSegmentMaxSize: 2048
    expansionRate: 1.25
    maxBinlogFileNumber: 32
    maxIdleTime: 600
    maxLife: 86400
    maxSize: 1024
    minSizeFromIdleToSealed: 16
    sealProportion: 0.12
    sealProportionJitter: 0.1
    smallProportion: 0.5
  segmentFlushInterval: 2
  slot:
    analyzeTaskSlotUsage: 65535
    clusteringCompactionUsage: 65535
    indexTaskSlotUsage: 64
    l0DeleteCompactionUsage: 8
    mixCompactionUsage: 4
    statsTaskSlotUsage: 8
  syncSegmentsInterval: 300
  targetVecIndexVersion: -1
dataNode:
  bloomFilterApplyParallelFactor: 2
  channel:
    channelCheckpointUpdateTickInSeconds: 10
    maxChannelCheckpointsPerPRC: 128
    updateChannelCheckpointInterval: 60
    updateChannelCheckpointMaxParallel: 10
    updateChannelCheckpointRPCTimeout: 20
    workPoolSize: -1
  clusteringCompaction:
    memoryBufferRatio: 0.3
    workPoolSize: 8
  compaction:
    levelZeroBatchMemoryRatio: 0.5
    levelZeroMaxBatchSize: -1
    maxSegmentMergeSort: 30
    useMergeSort: true
  dataSync:
    flowGraph:
      maxParallelism: 1024
      maxQueueLength: 16
    maxParallelSyncMgrTasksPerCPUCore: 16
    skipMode:
      coldTime: 60
      enable: true
      skipNum: 4
  gracefulStopTimeout: 1800
  grpc:
    clientMaxRecvSize: 536870912
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 268435456
    serverMaxSendSize: 536870912
  import:
    concurrencyPerCPUCore: 4
    maxImportFileSizeInGB: 16
    memoryLimitPercentage: 10
    readBufferSizeInMB: 16
    readDeleteBufferSizeInMB: 16
  ip: null
  memory:
    checkInterval: 3000
    forceSyncEnable: true
    forceSyncSegmentNum: 1
    forceSyncWatermark: 0.5
  port: 21124
  segment:
    deleteBufBytes: 16777216
    insertBufSize: 16777216
    syncPeriod: 600
  slot:
    slotCap: 16
  storage:
    deltalog: json
  timetick:
    interval: 500
etcd:
  auth:
    enabled: false
    password: null
    userName: null
  data:
    dir: default.etcd
  endpoints:
  {{- range jsonArray (getenv "ETCD_MEMBER_LIST") }}
  - "https://{{.}}:{{ getenv "ETCD_PORT" "2379" }}"
  {{- end }}

  kvSubPath: kv
  log:
    level: info
    path: stdout
  metaSubPath: meta
  requestTimeout: 10000
  rootPath: milvus-local
  ssl:
    enabled: true
    tlsCACert: {{ getenv "CERT_MOUNT" }}/ca.crt
    tlsCert: {{ getenv "CERT_MOUNT" }}/tls.crt
    tlsKey: {{ getenv "CERT_MOUNT" }}/tls.key
    tlsMinVersion: 1.3
  use:
    embed: false
function:
  analyzer:
    local_resource_path: {{ getenv "DATA_DIR" }}/analyzer
  rerank:
    model:
      providers:
        cohere:
          credential: null
          enable: true
          url: null
        siliconflow:
          credential: null
          enable: true
          url: null
        tei:
          credential: null
          enable: true
        vllm:
          credential: null
          enable: true
        voyageai:
          credential: null
          enable: true
          url: null
  textEmbedding:
    providers:
      azure_openai:
        credential: null
        enable: true
        resource_name: null
        url: null
      bedrock:
        credential: null
        enable: true
      cohere:
        credential: null
        enable: true
        url: null
      dashscope:
        credential: null
        enable: true
        url: null
      openai:
        credential: null
        enable: true
        url: null
      siliconflow:
        credential: null
        enable: true
        url: null
      tei:
        credential: null
        enable: true
      vertexai:
        credential: null
        enable: true
        url: null
      voyageai:
        credential: null
        enable: true
        url: null
gpu:
  initMemSize: 2048
  maxMemSize: 4096
  overloadedMemoryThresholdPercentage: 95
grpc:
  client:
    backoffMultiplier: 2
    compressionEnabled: false
    dialTimeout: 200
    initialBackoff: 0.2
    keepAliveTime: 10000
    keepAliveTimeout: 20000
    maxBackoff: 10
    maxCancelError: 32
    maxMaxAttempts: 10
    minResetInterval: 1000
    minSessionCheckInterval: 200
  gracefulStopTimeout: 3
  log:
    level: WARNING
indexCoord:
  bindIndexNodeMode:
    address: localhost:22930
    enable: false
    nodeID: 0
    withCred: false
  enableActiveStandby: true
  segment:
    minSegmentNumRowsToEnableIndex: 1024
indexNode:
  scheduler:
    buildParallel: 1
internaltls:
  caPemPath: {{ getenv "CERT_MOUNT" }}/ca.crt
  serverKeyPath: {{ getenv "CERT_MOUNT" }}/tls.key
  serverPemPath: {{ getenv "CERT_MOUNT" }}/tls.crt
  sni: localhost
knowhere:
  DISKANN:
    build:
      max_degree: 56
      pq_code_budget_gb_ratio: 0.125
      search_cache_budget_gb_ratio: 0.1
      search_list_size: 100
    search:
      beam_width_ratio: 4
  enable: true
localStorage:
  path: {{ getenv "DATA_DIR" }}
log:
  file:
    maxAge: 10
    maxBackups: 20
    maxSize: 300
    rootPath: null
  format: text
  level: info
  stdout: true
messageQueue: woodpecker
metastore:
  snapshot:
    reserveTime: 3600
    ttl: 86400
  type: etcd
minio:
  accessKeyID: {{ getenv "MINIO_USER" }}
  address: {{ getenv "MINIO_ADDR" }}
  bucketName: {{ getenv "MINIO_BUCKET" }}
  cloudProvider: aws
  gcpCredentialJSON: null
  iamEndpoint: null
  listObjectsMaxKeys: 0
  logLevel: fatal
  port: {{ getenv "MINIO_PORT"}}
  region: null
  requestTimeoutMs: 10000
  rootPath: files
  secretAccessKey: {{ AESCBCDecrypt (secretRead (getenv "SECRET_NAME") (getenv "NAMESPACE") (getenv "MINIO_USER")) }}
  ssl:
    tlsCACert: {{ getenv "CERT_MOUNT" }}/ca.crt
  useIAM: false
  useSSL: false
  useVirtualHost: false
mixCoord:
  enableActiveStandby: true
mq:
  dispatcher:
    maxTolerantLag: 3
    mergeCheckInterval: 0.1
    targetBufSize: 16
  enablePursuitMode: true
  mqBufSize: 16
  pursuitBufferSize: 8388608
  pursuitBufferTime: 60
  pursuitLag: 10
  type: woodpecker
msgChannel:
  chanNamePrefix:
    cluster: milvus-local
    dataCoordSegmentInfo: segment-info-channel
    dataCoordTimeTick: datacoord-timetick-channel
    queryTimeTick: queryTimeTick
    replicateMsg: replicate-msg
    rootCoordDml: rootcoord-dml
    rootCoordStatistics: rootcoord-statistics
    rootCoordTimeTick: rootcoord-timetick
  subNamePrefix:
    dataCoordSubNamePrefix: dataCoord
    dataNodeSubNamePrefix: dataNode
proxy:
  accessLog:
    cacheFlushInterval: 3
    cacheSize: 0
    enable: false
    filename: null
    formatters:
      base:
        format: '[$time_now] [ACCESS] <$user_name: $user_addr> $method_name [status:
          $method_status] [code: $error_code] [sdk: $sdk_version] [msg: $error_msg]
          [traceID: $trace_id] [timeCost: $time_cost]'
      query:
        format: '[$time_now] [ACCESS] <$user_name: $user_addr> $method_name [status:
          $method_status] [code: $error_code] [sdk: $sdk_version] [msg: $error_msg]
          [traceID: $trace_id] [timeCost: $time_cost] [database: $database_name] [collection:
          $collection_name] [partitions: $partition_name] [expr: $method_expr] [params:
          $query_params]'
        methods: Query, Delete
      search:
        format: '[$time_now] [ACCESS] <$user_name: $user_addr> $method_name [status:
          $method_status] [code: $error_code] [sdk: $sdk_version] [msg: $error_msg]
          [traceID: $trace_id] [timeCost: $time_cost] [database: $database_name] [collection:
          $collection_name] [partitions: $partition_name] [expr: $method_expr] [nq:
          $nq] [params: $search_params]'
        methods: HybridSearch, Search
    localPath: /tmp/milvus_access
    maxSize: 64
    minioEnable: false
    remoteMaxTime: 0
    remotePath: access_log/
    rotatedTime: 0
  connectionCheckIntervalSeconds: 120
  connectionClientInfoTTLSeconds: 86400
  dclConcurrency: 16
  ddlConcurrency: 16
  ginLogSkipPaths: /
  ginLogging: true
  gracefulStopTimeout: 30
  grpc:
    clientMaxRecvSize: 67108864
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 67108864
    serverMaxSendSize: 268435456
  healthCheckTimeout: 3000
  http:
    acceptTypeAllowInt64: true
    debug_mode: false
    enableHSTS: false
    enablePprof: true
    enableWebUI: true
    enabled: true
    hstsIncludeSubDomains: false
    hstsMaxAge: 31536000
    port: null
  internalPort: 19529
  ip: null
  maxConnectionNum: 10000
  maxDimension: 32768
  maxFieldNum: 64
  maxNameLength: 255
  maxResultEntries: -1
  maxShardNum: 16
  maxTaskNum: 1024
  maxVectorFieldNum: 4
  msgStream:
    timeTick:
      bufSize: 512
  mustUsePartitionKey: false
  partialResultRequiredDataRatio: 1
  port: {{ getenv "MILVUS_PORT" 19530 }}
  queryNodePooling:
    size: 10
  slowQuerySpanInSeconds: 5
  timeTickInterval: 200
queryCoord:
  autoBalance: true
  autoBalanceChannel: true
  autoBalanceInterval: 3000
  autoHandoff: true
  balanceCostThreshold: 0.001
  balanceIntervalSeconds: 60
  balancer: ScoreBasedBalancer
  brokerTimeout: 5000
  channelExclusiveNodeFactor: 4
  channelTaskTimeout: 60000
  checkAutoBalanceConfigInterval: 10
  checkBalanceInterval: 300
  checkChannelInterval: 1000
  checkExecutedFlagInterval: 100
  checkHandoffInterval: 5000
  checkHealthInterval: 3000
  checkHealthRPCTimeout: 2000
  checkIndexInterval: 10000
  checkInterval: 1000
  checkNodeSessionInterval: 60
  checkSegmentInterval: 1000
  cleanExcludeSegmentInterval: 60
  collectionChannelCountFactor: 10
  collectionObserverInterval: 200
  collectionRecoverTimes: 3
  delegatorMemoryOverloadFactor: 0.1
  distPullInterval: 500
  distRequestTimeout: 5000
  enableActiveStandby: true
  enableStoppingBalance: true
  globalRowCountFactor: 0.1
  globalSegmentCountFactor: 0.1
  gracefulStopTimeout: 5
  growingRowCountWeight: 4
  grpc:
    clientMaxRecvSize: 536870912
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 268435456
    serverMaxSendSize: 536870912
  heartbeatAvailableInterval: 10000
  heatbeatWarningLag: 5000
  ip: null
  loadTimeoutSeconds: 600
  memoryUsageMaxDifferencePercentage: 30
  observerTaskParallel: 16
  overloadedMemoryThresholdPercentage: 90
  port: 19531
  randomMaxSteps: 10
  reverseUnBalanceTolerationFactor: 1.3
  rowCountFactor: 0.4
  rowCountMaxSteps: 50
  scoreUnbalanceTolerationFactor: 0.05
  segmentCountFactor: 0.4
  segmentCountMaxSteps: 50
  segmentTaskTimeout: 120000
  taskExecutionCap: 256
  taskMergeCap: 1
  updateCollectionLoadStatusInterval: 5
queryNode:
  bloomFilterApplyParallelFactor: 2
  cache:
    memoryLimit: 2147483648
    readAheadPolicy: willneed
  dataSync:
    flowGraph:
      maxParallelism: 1024
      maxQueueLength: 16
  enableDisk: false
  enableSegmentPrune: false
  exprCache:
    capacityBytes: 268435456
    enabled: false
  forwardBatchSize: 4194304
  grouping:
    maxNQ: 1000
    topKMergeRatio: 20
  grpc:
    clientMaxRecvSize: 536870912
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 268435456
    serverMaxSendSize: 536870912
  idfOracle:
    enableDisk: true
    writeConcurrency: 4
  indexOffsetCacheEnabled: false
  ip: null
  lazyload:
    enabled: false
    maxEvictPerRetry: 1
    maxRetryTimes: 1
    requestResourceRetryInterval: 2000
    requestResourceTimeout: 5000
    waitTimeout: 30000
  levelZeroForwardPolicy: FilterByBF
  loadMemoryUsageFactor: 1
  maxDiskUsagePercentage: 95
  mmap:
    fixedFileSizeForMmapAlloc: 1
    growingMmapEnabled: false
    maxDiskUsagePercentageForMmapAlloc: 50
    scalarField: false
    scalarIndex: false
    vectorField: true
    vectorIndex: false
  port: 21123
  queryStreamBatchSize: 4194304
  queryStreamMaxBatchSize: 134217728
  scheduler:
    cpuRatio: 10
    maxReadConcurrentRatio: 1
    maxTimestampLag: 86400
    receiveChanSize: 10240
    scheduleReadPolicy:
      enableCrossUserGrouping: false
      maxPendingTaskPerUser: 1024
      name: fifo
      taskQueueExpire: 60
    unsolvedQueueSize: 10240
  segcore:
    chunkRows: 128
    interimIndex:
      buildParallelRate: 0.5
      denseVectorIndexType: IVF_FLAT_CC
      enableIndex: true
      indexBuildRatio: 0.1
      memExpansionRate: 1.15
      nlist: 128
      nprobe: 16
      refineQuantType: NONE
      refineRatio: 4.5
      refineWithQuant: true
      subDim: 4
    jsonKeyStatsCommitInterval: 200
    knowhereScoreConsistency: false
    knowhereThreadPoolNumRatio: 4
    multipleChunkedEnable: true
    tieredStorage:
      cacheTtl: 0
      diskHighWatermarkRatio: 0.8
      diskLowWatermarkRatio: 0.75
      evictableDiskCacheRatio: 0.3
      evictableMemoryCacheRatio: 0.3
      evictionEnabled: false
      memoryHighWatermarkRatio: 0.8
      memoryLowWatermarkRatio: 0.75
      warmup:
        scalarField: sync
        scalarIndex: sync
        vectorField: disable
        vectorIndex: sync
  stats:
    publishInterval: 1000
  streamingDeltaForwardPolicy: FilterByBF
  workerPooling:
    size: 10
quotaAndLimits:
  compactionRate:
    db:
      max: -1
    enabled: false
    max: -1
  dbRate:
    enabled: false
    max: -1
  ddl:
    collectionRate: -1
    db:
      collectionRate: -1
      partitionRate: -1
    enabled: false
    partitionRate: -1
  dml:
    bulkLoadRate:
      collection:
        max: -1
      db:
        max: -1
      max: -1
      partition:
        max: -1
    deleteRate:
      collection:
        max: -1
      db:
        max: -1
      max: -1
      partition:
        max: -1
    enabled: false
    insertRate:
      collection:
        max: -1
      db:
        max: -1
      max: -1
      partition:
        max: -1
    upsertRate:
      collection:
        max: -1
      db:
        max: -1
      max: -1
      partition:
        max: -1
  dql:
    enabled: false
    queryRate:
      collection:
        max: -1
      db:
        max: -1
      max: -1
      partition:
        max: -1
    searchRate:
      collection:
        max: -1
      db:
        max: -1
      max: -1
      partition:
        max: -1
  enabled: true
  flushRate:
    collection:
      max: 0.1
    db:
      max: -1
    enabled: true
    max: -1
  forceDenyAllDDL: false
  indexRate:
    db:
      max: -1
    enabled: false
    max: -1
  limitReading:
    forceDeny: false
  limitWriting:
    deleteBufferRowCountProtection:
      enabled: false
      highWaterLevel: 65536
      lowWaterLevel: 32768
    deleteBufferSizeProtection:
      enabled: false
      highWaterLevel: 268435456
      lowWaterLevel: 134217728
    diskProtection:
      diskQuota: -1
      diskQuotaPerCollection: -1
      diskQuotaPerDB: -1
      diskQuotaPerPartition: -1
      enabled: true
    forceDeny: false
    growingSegmentsSizeProtection:
      enabled: false
      highWaterLevel: 0.4
      lowWaterLevel: 0.2
      minRateRatio: 0.5
    l0SegmentsRowCountProtection:
      enabled: false
      highWaterLevel: 50000000
      lowWaterLevel: 30000000
    memProtection:
      dataNodeMemoryHighWaterLevel: 0.95
      dataNodeMemoryLowWaterLevel: 0.85
      enabled: true
      queryNodeMemoryHighWaterLevel: 0.95
      queryNodeMemoryLowWaterLevel: 0.85
    ttProtection:
      enabled: false
      maxTimeTickDelay: 1200
  limits:
    allocRetryTimes: 15
    allocWaitInterval: 1000
    complexDeleteLimitEnable: false
    maxCollectionNum: 65536
    maxCollectionNumPerDB: 65536
    maxGroupSize: 10
    maxInsertSize: -1
    maxResourceGroupNumOfQueryNode: 1024
  quotaCenterCollectInterval: 3
rootCoord:
  dmlChannelNum: 16
  enableActiveStandby: true
  gracefulStopTimeout: 5
  grpc:
    clientMaxRecvSize: 536870912
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 268435456
    serverMaxSendSize: 536870912
  ip: null
  maxDatabaseNum: 64
  maxGeneralCapacity: 65536
  maxPartitionNum: 1024
  minSegmentSizeToEnableIndex: 1024
  port: 53100
streaming:
  flush:
    growingSegmentBytesHwmThreshold: 0.2
    growingSegmentBytesLwmThreshold: 0.1
    l0:
      maxLifetime: 10m
      maxRowNum: 500000
      maxSize: 32m
    memoryThreshold: 0.6
  logging:
    appendSlowThreshold: 1s
  txn:
    defaultKeepaliveTimeout: 10s
  walBalancer:
    backoffInitialInterval: 10ms
    backoffMaxInterval: 5s
    backoffMultiplier: 2
    balancePolicy:
      allowRebalance: true
      allowRebalanceRecoveryLagThreshold: 1s
      minRebalanceIntervalThreshold: 5m
      name: vchannelFair
      vchannelFair:
        antiAffinityWeight: 0.01
        pchannelWeight: 0.4
        rebalanceMaxStep: 3
        rebalanceTolerance: 0.01
        vchannelWeight: 0.3
    operationTimeout: 30s
    triggerInterval: 1m
  walBroadcaster:
    concurrencyRatio: 1
  walReadAheadBuffer:
    length: 128
  walRecovery:
    gracefulCloseTimeout: 3s
    maxDirtyMessage: 100
    persistInterval: 10s
  walTruncate:
    retentionInterval: 72h
    sampleInterval: 30m
  walWriteAheadBuffer:
    capacity: 64m
    keepalive: 30s
streamingNode:
  grpc:
    clientMaxRecvSize: 268435456
    clientMaxSendSize: 268435456
    serverMaxRecvSize: 268435456
    serverMaxSendSize: 268435456
  ip: null
  port: 22222
tikv:
  endpoints: 127.0.0.1:2389
  kvSubPath: kv
  metaSubPath: meta
  requestTimeout: 10000
  rootPath: by-dev
  snapshotScanSize: 256
  ssl:
    enabled: false
    tlsCACert: null
    tlsCert: null
    tlsKey: null
tls:
  caPemPath: {{ getenv "CERT_MOUNT" }}/ca.crt
  serverKeyPath: {{ getenv "CERT_MOUNT" }}/tls.key
  serverPemPath: {{ getenv "CERT_MOUNT" }}/tls.crt
trace:
  exporter: noop
  initTimeoutSeconds: 10
  jaeger:
    url: null
  otlp:
    endpoint: null
    headers: null
    method: null
    secure: true
  sampleFraction: 0
woodpecker:
  client:
    auditor:
      maxInterval: 10s
    segmentAppend:
      maxRetries: 3
      queueSize: 10000
    segmentRollingPolicy:
      maxBlocks: 1000
      maxInterval: 10m
      maxSize: 256M
  logstore:
    segmentCompactionPolicy:
      maxParallelReads: 8
      maxParallelUploads: 4
      maxSize: 2M
    segmentReadPolicy:
      maxBatchSize: 16M
      maxFetchThreads: 32
    segmentSyncPolicy:
      maxBytes: 256M
      maxEntries: 10000
      maxFlushRetries: 5
      maxFlushSize: 2M
      maxFlushThreads: 32
      maxInterval: 200ms
      maxIntervalForLocalStorage: 10ms
      retryInterval: 1000ms
  meta:
    prefix: woodpecker
    type: etcd
  storage:
    rootPath: {{ getenv "DATA_DIR" }}/woodpecker
    type: minio
