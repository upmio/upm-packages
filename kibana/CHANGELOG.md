# Changelog

All notable changes to Kibana Community Edition will be documented in this file.

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
- Certificate management and SSL/TLS support
- Memory optimization and Node.js configuration
- Elasticsearch integration capabilities

### Changed
- Renamed `serverMGR.sh` to `service-ctl.sh` for consistency
- Updated all references to use new naming convention
- Updated container base image to Rocky Linux 9.5.20241118
- Improved health check functionality
- Enhanced error handling and logging
- Standardized exit codes and error handling
- Cleaned up Helm chart dependencies

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations
- Certificate handling and validation
- Memory limit validation and configuration
- Data persistence mounting
- Network connectivity and health monitoring

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation
- Improved certificate management
- Added SSL/TLS configuration support
- Enhanced authentication with Elasticsearch
- Added secure password management with OpenSSL encryption

## [1.0.0] - 2025-08-07

### Added
- Kibana Community Edition 7.17.14 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- Kibana server community package integration
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
- Visualization and exploration capabilities
- Dashboard and visualization management
- User session management

### Security
- Container runs as non-root user (kibana, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- Secure password management with OpenSSL encryption
- SSL/TLS encryption support
- Certificate management and validation
- Authentication with Elasticsearch
- Network isolation features
- Session security management

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management
- Data persistence and volume management
- Node.js optimization and configuration
- Memory management and garbage collection
- Performance optimization configurations

### Visualization Features
- Kibana dashboard management
- Data visualization and exploration
- Index pattern management
- Saved searches and visualizations
- Canvas and Lens capabilities
- Maps and graph visualizations
- Machine learning features
- Reporting and export capabilities
- Dashboard sharing and collaboration

### Monitoring and Logging
- Comprehensive logging system
- Health check endpoints
- Performance monitoring capabilities
- Resource usage tracking
- User activity monitoring
- Query performance analysis
- Error logging and alerting
- System metrics collection
- Elasticsearch integration monitoring

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- Elasticsearch integration procedures
- High availability setup guide

### High Availability
- Multi-instance deployment support
- Load balancing configuration
- Failover management
- Session affinity support
- Health-based routing
- Graceful degradation
- Cluster management capabilities
- Disaster recovery planning

### Integration
- UPM Package Manager integration
- External monitoring tools integration
- Logging aggregation support
- Security scanning integration
- Container orchestration support
- Elasticsearch seamless integration
- Visualization tool integration
- Authentication system integration

---

## Version Classification

- **Major**: Breaking changes, significant new features, Kibana version upgrades
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

- **Current version** (7.17.x): Full support, including new features and security updates
- **Previous versions**: Security patches and critical bug fixes only
- **Older versions**: No support, upgrade recommended

### Kibana Community Support Timeline

- Kibana 7.17.x: Full support until Elastic's EOL date
- Older versions: Upgrade immediately

## Security Updates

Security patches will be backported to supported versions according to the following priority:

1. **Critical**: Immediate patch for all supported versions
2. **High**: Patch for current version, backport to previous version within 2 weeks
3. **Medium**: Patch for current version, evaluate backport to previous version
4. **Low**: Patch for current version in next scheduled release

## Migration Guide

### Upgrading Between Minor Versions

1. Backup your dashboards and saved objects
2. Read the upgrade notes in CHANGELOG.md
3. Update the Helm chart version
4. Apply the upgrade using Helm or UPM Package Manager
5. Verify functionality and data integrity

### Upgrading Between Major Versions

1. Full backup and verification
2. Review migration documentation
3. Test upgrade in staging environment
4. Plan for potential downtime
5. Execute upgrade during maintenance window
6. Comprehensive testing and verification
7. Validate all dashboards and visualizations

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).