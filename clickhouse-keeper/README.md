# ClickHouse Keeper

ClickHouse Keeper package for UPM.

Supported UPM package version:

- `clickhouse-keeper/21.8.15.7`
- `clickhouse-keeper/23.8.16.40`
- `clickhouse-keeper/25.8.29.51`
- `clickhouse-keeper/26.3.9.8`

ClickHouse Keeper is provisioned as a separate UnitSet in the same service group as ClickHouse. It is not an external ZooKeeper dependency.

The package renders a three-member Keeper ensemble by default. Server IDs and peer endpoints are generated from UnitSet ordinals and the UnitSet headless service name.
