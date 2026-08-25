# ClickHouse Agent Image

This image provides the ClickHouse-specific runtime for the existing UPM `unit-agent`.

It includes:

- `unit-agent` from `quay.io/upmio/unit-agent:main-cf9eda9`
- ClickHouse client `26.3.9.8`
- S3-compatible command-line tooling

The image does not add a new gRPC protocol. Backup, restore, and online setting operations continue to enter through the unit-operator ClickHouse agent contract.
