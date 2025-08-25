# Changelog

This project adheres to Keep a Changelog and Semantic Versioning.

## 1.0.0 - 2025-08-19

### Added

- Initial stable release (component: redis-sentinel), unified under `upm-packages`.
- Helm chart and image layout aligned with other components.
- `service-ctl.sh` with `initialize`, `health`, `login` actions and structured logs.

### Changed

- Standardized environment variable: use `REDIS_SENTINEL_PORT` (defaults to 26379).

### Fixed

- Eliminated illegal hyphenated variable usage that caused shell errors.

### Notes

- CI focuses on lint/validate; image build/push occurs in release workflow.
- Future changes will be documented per chart/image version under `7.0.14/`.


