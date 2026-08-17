# ClickHouse

ClickHouse package for UPM.

Supported UPM package version:

- `clickhouse/21.8.15.7`
- `clickhouse/23.8.16.40`
- `clickhouse/25.8.29.51`
- `clickhouse/26.3.9.8`

ClickHouse Keeper is provisioned as a separate UnitSet in the same service group. It is not an external ZooKeeper dependency.

The first supported topology is one shard with two or three ClickHouse replicas. The ClickHouse package renders replica macros, one-shard cluster topology, and Keeper endpoints from UnitSet metadata.
