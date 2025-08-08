# Changelog

All notable changes to PgBouncer Community Edition will be documented in this file.

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
- Connection pooling and load balancing capabilities
- High availability configuration options

### Changed
- Replaced `serverMGR.sh` with `service-ctl.sh` for consistency with other components
- Updated all references to use new naming convention
- Cleaned up Helm chart dependencies (removed `.tgz` files from version control)
- Updated container base image to Rocky Linux 9.5.20241118
- Enhanced script structure with better error handling and logging

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations
- Connection pooling configuration
- Backend server health checking
- Authentication and authorization mechanisms

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation
- Improved password management with OpenSSL encryption
- Added SSL/TLS configuration support
- Enhanced authentication mechanisms
- Added connection security features

## [1.0.0] - 2025-08-07

### Added
- PgBouncer Community Edition 1.23.1 support
- PgBouncer Community Edition 1.24.1 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- PgBouncer community package integration
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
- Connection pooling management
- Load balancing capabilities
- High availability configuration options

### Security
- Container runs as non-root user (pgbouncer, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- Secure password management with OpenSSL encryption
- SSL/TLS encryption support
- Authentication and authorization mechanisms
- Network isolation features
- Connection security hardening

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management
- Connection pooling optimization
- Load balancing algorithms
- Health checking mechanisms
- Failover detection and recovery

### Connection Pooling Features
- Transaction-level connection pooling
- Session-level connection pooling
- Connection reuse optimization
- Pool size management
- Connection timeout handling
- Connection limits and quotas
- Pool statistics and monitoring
- Connection cleanup and reuse

### High Availability
- Multiple PostgreSQL backend support
- Automatic failover detection
- Load balancing strategies
- Health checking and monitoring
- Connection routing optimization
- Backend server discovery
- Service health monitoring
- Graceful degradation handling

### Monitoring and Logging
- Comprehensive logging system
- Health check endpoints
- Performance monitoring capabilities
- Resource usage tracking
- Connection pool monitoring
- Query throughput analysis
- Error logging and alerting
- Performance metrics collection

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- High availability setup guide
- Connection pooling configuration guide

### Integration
- UPM Package Manager integration
- PostgreSQL cluster integration
- External monitoring tools integration
- Logging aggregation support
- Security scanning integration
- Container orchestration support
- Database connection management

---

## Version Classification

- **Major**: Breaking changes, significant new features, PgBouncer version upgrades
- **Minor**: New features, backward-compatible changes, configuration improvements
- **Patch**: Bug fixes, security updates, documentation, performance optimizations

## Release Process

1. Update version numbers in Chart.yaml files
2. Update CHANGELOG.md
3. Create and test release artifacts
4. Tag the release
5. Publish to container registry
6. Update Helm repository
7. Update documentation

## Support Policy

- **Current version** (1.24.x): Full support, including new features and security updates
- **Previous version** (1.23.x): Security patches and critical bug fixes only
- **Older versions**: No support, upgrade recommended

### PgBouncer Community Support Timeline

- PgBouncer 1.24.x: Full support until PgBouncer's EOL date
- PgBouncer 1.23.x: Security patches only until PgBouncer's EOL date
- Older versions: Upgrade immediately

### Version Lifecycle

- **Active Development**: New features, bug fixes, security updates
- **Maintenance**: Security patches, critical bug fixes only
- **End of Life**: No support, security vulnerabilities, upgrade required

## Security Updates

Security patches will be backported to supported versions according to the following priority:

1. **Critical**: Immediate patch for all supported versions
2. **High**: Patch for current version, backport to previous version within 2 weeks
3. **Medium**: Patch for current version, evaluate backport to previous version
4. **Low**: Patch for current version in next scheduled release

## Migration Guide

### Upgrading Between Minor Versions

1. Backup your configuration
2. Read the upgrade notes in CHANGELOG.md
3. Update the Helm chart version
4. Apply the upgrade using Helm or UPM Package Manager
5. Verify connection pooling functionality
6. Test backend connectivity

### Upgrading Between Major Versions

1. Full backup and verification
2. Review migration documentation
3. Test upgrade in staging environment
4. Plan for potential downtime
5. Execute upgrade during maintenance window
6. Comprehensive testing and verification
7. Validate connection pooling performance

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).