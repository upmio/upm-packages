# ClickHouse Agent Image

This image provides the ClickHouse `21.8.15.7`-specific runtime for the existing UPM `unit-agent`.

It includes:

- `unit-agent` from `quay.io/upmio/unit-agent:v1.1.0`
- ClickHouse client `21.8.15.7`
- S3-compatible command-line tooling

The image is available for `linux/amd64` only because this ClickHouse LTS release has no upstream arm64 RPM packages.

The image does not add a new gRPC protocol. Backup, restore, and online setting operations continue to enter through the unit-operator ClickHouse agent contract.
