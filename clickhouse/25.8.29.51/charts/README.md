# clickhouse-25.8.29.51

This chart packages ClickHouse `25.8.29.51` for UPM.

It provides:

- a ClickHouse `PodTemplate`
- ClickHouse configuration templates
- default ClickHouse parameter values
- ClickHouse parameter metadata
- a `unit-agent` sidecar using `quay.io/upmio/clickhouse-agent:25.8`

The chart supports one shard with two or three replicas.
