# ClickHouse Agent Image

This image provides the ClickHouse `25.8` runtime for the existing UPM `unit-agent`.

It includes:

- `unit-agent` from `quay.io/upmio/unit-agent:v1.1.0`
- ClickHouse client `25.8.29.51`, shared by ClickHouse 25.8 releases
- S3-compatible command-line tooling

The image is available for `linux/amd64` and `linux/arm64`.

The image does not add a new gRPC protocol. Backup, restore, and online setting operations continue to enter through the unit-operator ClickHouse agent contract.
