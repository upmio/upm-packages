# Changelog

This project adheres to Keep a Changelog and Semantic Versioning.

## 1.0.0 - 2025-08-19

### Added

- Initial stable release (component: mysql-router-community), unified under `upm-packages`.
- Unified Helm chart structure and templates with `helm-docs`-generated documentation.
- Local quality gates via `pre-commit` (prettier, yamllint, shellcheck, shfmt).
- `upm-pkg-mgm.sh`: Idempotent install/upgrade/uninstall, improved `status` and `list` outputs.

### Changed

- Only hyphenated component names are supported (e.g., `mysql-community`); underscore aliases removed.
- Documentation aligned with `compose-operator`; default port values and naming made consistent.

### Fixed

- Resolved empty available package list and duplicate fetch logs.
- Removed image build from CI; release logic moved to `release.yml`.

### Notes

- CI now runs quality checks only; image build/push occurs in release workflow with special `agent/` naming.
- Future changes will evolve per chart/image versions in their respective directories.
