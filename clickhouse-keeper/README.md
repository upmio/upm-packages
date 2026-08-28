# ClickHouse Keeper

ClickHouse Keeper package for UPM.

Supported UPM package version:

- `clickhouse-keeper/21.8.15.7`
- `clickhouse-keeper/23.8.16.40`
- `clickhouse-keeper/25.8.29.51`
- `clickhouse-keeper/26.3.9.8`

ClickHouse Keeper is provisioned as a separate UnitSet in the same service group as ClickHouse when it is selected as the coordination service. ZooKeeper is the alternative UPM-managed coordination option.

The package renders a three-member Keeper ensemble by default. Server IDs and peer endpoints are generated from UnitSet ordinals and the UnitSet headless service name.

Keeper 23.8 and later expose ClickHouse's built-in Prometheus endpoint at `/metrics` on the named `metrics` port `9363`. UPM enables a PodMonitor for those Keeper UnitSets so Prometheus can scrape their metrics without a sidecar exporter.

Keeper 21.8 implements neither the built-in Prometheus HTTP endpoint nor the later Keeper four-letter-command monitoring path. UPM therefore leaves its PodMonitor disabled instead of creating a permanently down scrape target. Full monitoring of that legacy version requires upgrading Keeper or providing a dedicated compatible collector; a standard `mntr` exporter is not sufficient.
