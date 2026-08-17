# clickhouse-21.8.15.7

This chart packages ClickHouse `21.8.15.7` for UPM.

It provides:

- a ClickHouse `PodTemplate`
- ClickHouse configuration templates
- default ClickHouse parameter values
- ClickHouse parameter metadata
- a `unit-agent` sidecar using `quay.io/upmio/clickhouse-agent:26.3`

The chart supports one shard with two or three replicas.
