# ClickHouse

ClickHouse package for UPM.

Supported UPM package version:

- `clickhouse/21.8.15.7`
- `clickhouse/23.8.16.40`
- `clickhouse/25.8.29.51`
- `clickhouse/26.3.9.8`

Each ClickHouse service group selects either a UPM-managed ZooKeeper or ClickHouse Keeper for coordination. ClickHouse Keeper is provisioned as a separate UnitSet when selected. The ClickHouse templates receive the selected coordination service name, port, and member count from the UnitSet metadata.

The first supported topology is one shard with two or three ClickHouse replicas. The ClickHouse package renders replica macros, one-shard cluster topology, and the selected ZooKeeper or Keeper endpoints from UnitSet metadata.
