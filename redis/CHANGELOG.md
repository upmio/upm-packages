# Changelog

All notable changes to Redis will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

### Added
- Initial Redis component structure and documentation
- Multi-architecture container images (linux/amd64, linux/arm64)
- Helm chart for UPM package deployment
- `service-ctl.sh` with initialize/health/login
- Health checks and monitoring integration
- Security hardening (non-root user, minimal privileges)
- Template system: `redisParametersDetail.json`, `redisTemplate.tpl`, `redisValue.yaml`
- Data persistence (AOF/RDB) configuration

### Changed
- Unified script style with other components

### Fixed
- Parameter detail JSON and translations

## [1.0.0] - 2025-08-12

### Added
- Redis 7.0.14 support
- Container image (Rocky Linux 9.5.20241118 base)
- Supervisord process management
- Bitnami common chart dependency
- Pod template for Kubernetes deployment
- Configuration template system
- Parameter management system
- Initialization script and health endpoints
- Liveness/readiness probes
- Resource management and limits
- Environment-based configuration
- PVC-backed data persistence
