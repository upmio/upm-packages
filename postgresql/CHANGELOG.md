# Changelog

All notable changes to PostgreSQL Community Edition will be documented in this file.

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
- Data persistence and backup management
- High availability configuration options

### Changed
- Replaced `serverMGR.sh` with `service-ctl.sh` for consistency with MySQL components
- Updated all references to use new naming convention
- Cleaned up Helm chart dependencies (removed `.tgz` files from version control)
- Updated container base image to Rocky Linux 9.5.20241118
- Enhanced script structure with better error handling and logging

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations
- Data persistence mounting
- Backup and recovery procedures

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation
- Improved password management with OpenSSL encryption
- Added SSL/TLS configuration support
- Enhanced audit logging capabilities

## [1.0.0] - 2025-08-07

### Added
- PostgreSQL Community Edition 15.12 support
- PostgreSQL Community Edition 15.13 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- PostgreSQL Server community package integration
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
- Backup and recovery utilities
- High availability configuration options

### Security
- Container runs as non-root user (postgres, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- Secure password management with OpenSSL encryption
- SSL/TLS encryption support
- Audit logging capabilities
- Network isolation features

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management
- Data persistence and volume management
- Backup and recovery procedures
- Performance optimization configurations

### Database Features
- PostgreSQL storage engine optimization
- Replication support (streaming replication, logical replication)
- Performance schema configuration
- Query optimization and analysis
- Connection pooling and management
- User privilege management
- Database security hardening
- Transaction support and ACID compliance
- Extension support and management

### Monitoring and Logging
- Comprehensive logging system
- Health check endpoints
- Performance monitoring capabilities
- Resource usage tracking
- Query performance analysis
- Connection monitoring
- Slow query logging
- Error logging and alerting

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- Backup and recovery procedures
- High availability setup guide

### High Availability
- Streaming replication support
- Logical replication configuration
- Automatic failover mechanisms
- Backup and recovery procedures
- Data consistency checking
- Load balancing configuration
- Disaster recovery planning

### Integration
- UPM Package Manager integration
- External monitoring tools integration
- Logging aggregation support
- Backup tool integration
- Security scanning integration
- Container orchestration support

---

## Version Classification

- **Major**: Breaking changes, significant new features, PostgreSQL version upgrades
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

- **Current version** (15.x): Full support, including new features and security updates
- **Previous version** (14.x): Security patches and critical bug fixes only
- **Older versions**: No support, upgrade recommended

### PostgreSQL Community Support Timeline

- PostgreSQL 15.x: Full support until PostgreSQL's EOL date
- PostgreSQL 14.x: Security patches only until PostgreSQL's EOL date
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

1. Backup your data
2. Read the upgrade notes in CHANGELOG.md
3. Update the Helm chart version
4. Apply the upgrade using Helm or UPM Package Manager
5. Verify functionality

### Upgrading Between Major Versions

1. Full backup and verification
2. Review migration documentation
3. Test upgrade in staging environment
4. Plan for potential downtime
5. Execute upgrade during maintenance window
6. Comprehensive testing and verification

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).