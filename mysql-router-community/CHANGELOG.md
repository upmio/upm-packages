# Changelog

All notable changes to MySQL Router Community Edition will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and documentation
- Multi-architecture container images (linux/amd64, linux/arm64)
- Helm chart for Kubernetes deployment
- Service control script (`service-ctl.sh`)
- Health check and monitoring endpoints
- Security hardening (non-root user, minimal privileges)
- Configuration templates and parameter management

### Changed
- Renamed `mysql-router-init.sh` to `service-ctl.sh` for better extensibility
- Renamed `serverMGR.sh` to `service-ctl.sh` for consistency
- Updated all references to use new naming convention
- Cleaned up Helm chart dependencies (removed `.tgz` files from version control)

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation

## [1.0.0] - 2025-08-07

### Added
- MySQL Router Community Edition 8.0.40 support
- MySQL Router Community Edition 8.0.41 support
- MySQL Router Community Edition 8.0.42 support
- MySQL Router Community Edition 8.4.4 support
- MySQL Router Community Edition 8.4.5 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- MySQL Shell integration
- MySQL Router community package integration
- Bitnami common chart dependency
- Pod template for Kubernetes deployment
- Configuration template system
- Parameter management system
- Service initialization script
- Health check endpoints
- Liveness and readiness probes
- Resource management and limits
- Environment variable configuration
- Persistent volume support
- Service discovery integration
- Logging and monitoring support

### Security
- Container runs as non-root user (mysql-router, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- Secure password management with OpenSSL encryption

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines

---

## Version Classification

- **Major**: Breaking changes, significant new features
- **Minor**: New features, backward-compatible changes
- **Patch**: Bug fixes, security updates, documentation

## Release Process

1. Update version numbers in Chart.yaml files
2. Update CHANGELOG.md
3. Create and test release artifacts
4. Tag the release
5. Publish to container registry
6. Update Helm repository

## Support Policy

- Current version: Full support
- Previous version: Security patches only
- Older versions: No support

For more information about support timelines, please refer to the [README](README.md).