# clickhouse-23.8.16.40

This chart packages ClickHouse `23.8.16.40` for UPM.

It provides:

- a ClickHouse `PodTemplate`
- ClickHouse configuration templates
- default ClickHouse parameter values
- ClickHouse parameter metadata
- a `unit-agent` sidecar using `quay.io/upmio/clickhouse-agent:23.8`

The chart supports one shard with two or three replicas.
