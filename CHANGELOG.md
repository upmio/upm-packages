# Changelog

All notable changes to this repository will be documented in this file.
This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Planned: extend component coverage and examples; improve local kind-based integration test recipes.

## 1.0.0 - 2025-08-19

### Highlights

- This is a re-release that establishes `upm-packages` as the home for a curated set of data infrastructure charts and images.
- Focus on deterministic developer workflow, idempotent scripting, consistent documentation, and clean CI/CD separation.

### Added

- Monorepo layout hosting the following components (initial set):
  - `mysql-community`, `mysql-router-community`, `postgresql`, `pgbouncer`, `proxysql`, `redis`, `redis-sentinel`, `elasticsearch`, `kibana`, `kafka`, `zookeeper`.
- `upm-pkg-mgm.sh`:
  - Idempotent operations for install/upgrade/uninstall based on Helm release state.
  - Richer `status` and `list` outputs; invalid input now shows available components and packages.
  - Classification extended to include `redis` and `zookeeper` families.
- Documentation system:
  - `helm-docs` generates chart READMEs automatically.
  - Repository-wide documentation style aligned with `upmio/compose-operator`.
- Local quality gates via `pre-commit`:
  - `prettier`, `yamllint`, `shellcheck`, `shfmt` integrated and tuned for this codebase.

### Changed

- Naming policy: only hyphenated component names are supported (e.g., `mysql-community`); underscore aliases have been removed.
- CI split of responsibilities:
  - CI (`.github/workflows/ci.yml`) runs quality checks (linting, docs, validations) only.
  - Release (`.github/workflows/release.yml`) discovers, builds, and pushes images to `quay.io` with correct naming (including `*-agent` special cases).
- Pre-commit tuning to avoid Go template false-positives:
  - `yamllint` ignores `**/charts/templates/**`.
  - `helm-docs` runs before `prettier`; `prettier` excludes `*/charts/README.md`.
- Docs refresh:
  - `README.md` and `upm-pkg-mgm.md` rewritten for consistency and clarity.
  - Component READMEs updated; default port values verified across references.

### Fixed

- Resolved empty “Available components and packages” and duplicate "Fetching available packages" logs.
- Standardized `list` output formatting and titles.
- Corrected CI image naming for `agent/` images (e.g., `mysql-community-agent:8.0`).

### Removed

- Legacy underscore aliases (e.g., `mysql_community`, `mysql_router`).
- Duplicate or unnecessary CI image build/test logic from CI workflow.

### Security / Images

- Dockerfiles streamlined: OCI labels, unified shell options, reduced image size (`dnf` with no weak deps and no docs), cache cleanup, added required plugin installation steps and platform checks.

### Notes

- Image publishing occurs in release workflows, targeting `quay.io/upmio` with multi-arch support via Buildx where appropriate.
- Related projects: `upmio/compose-operator`, `upmio/unit-operator`.

[Unreleased]: https://github.com/upmio/upm-packages/compare/1.0.0...HEAD
