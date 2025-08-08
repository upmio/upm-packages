# Changelog

All notable changes to Elasticsearch Community Edition will be documented in this file.

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
- User management system with predefined roles
- Cluster configuration and management
- Plugin system integration

### Changed
- Renamed `serverMGR.sh` to `service-ctl.sh` for consistency
- Updated all references to use new naming convention
- Updated container base image to Rocky Linux 9.5.20241118
- Improved health check functionality
- Enhanced error handling and logging
- Standardized exit codes and error handling
- Cleaned up Helm chart dependencies
- Optimized JVM configuration and memory management

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations
- Certificate handling and validation
- User creation and role assignment
- Data persistence mounting
- Network connectivity and health monitoring
- Cluster formation and discovery
- Plugin installation and management

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation
- Improved certificate management
- Added SSL/TLS configuration support
- Enhanced user authentication and authorization
- Added secure password management with OpenSSL encryption
- Implemented role-based access control
- Added audit logging capabilities

## [1.0.0] - 2025-08-07

### Added
- Elasticsearch Community Edition 7.17.14 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- Elasticsearch server community package integration
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
- Metrics exporter integration
- Cluster management capabilities
- Plugin system support

### Security
- Container runs as non-root user (elastic, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- Secure password management with OpenSSL encryption
- SSL/TLS encryption support
- Certificate management and validation
- User authentication and authorization
- Role-based access control
- Audit logging capabilities
- Network isolation features
- Cluster security configuration

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management
- Data persistence and volume management
- JVM optimization and configuration
- Memory management and garbage collection
- Performance optimization configurations
- Plugin management system
- Index lifecycle management

### Search Features
- Full-text search capabilities
- Index and document management
- Query and aggregation framework
- Mapping and analysis capabilities
- Search performance optimization
- Distributed search architecture
- Real-time indexing and search
- Geo-search capabilities
- Machine learning integration
- SQL support for querying

### Monitoring and Logging
- Comprehensive logging system
- Health check endpoints
- Performance monitoring capabilities
- Resource usage tracking
- Cluster health monitoring
- Index performance metrics
- Query performance analysis
- JVM memory and garbage collection
- Network and disk I/O monitoring
- Error logging and alerting

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- Cluster setup and management
- High availability configuration
- Backup and recovery procedures

### High Availability
- Multi-node cluster support
- Master node election
- Data replication and redundancy
- Shard allocation awareness
- Cluster recovery procedures
- Load balancing configuration
- Failover management
- Disaster recovery planning
- Cross-cluster replication support

### Integration
- UPM Package Manager integration
- External monitoring tools integration
- Logging aggregation support
- Security scanning integration
- Container orchestration support
- Kibana seamless integration
- Logstash integration
- Beats integration
- Third-party plugin support

---

## Version Classification

- **Major**: Breaking changes, significant new features, Elasticsearch version upgrades
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

### Elasticsearch Community Support Timeline

- Elasticsearch 7.17.x: Full support until Elastic's EOL date
- Older versions: Upgrade immediately

## Security Updates

Security patches will be backported to supported versions according to the following priority:

1. **Critical**: Immediate patch for all supported versions
2. **High**: Patch for current version, backport to previous version within 2 weeks
3. **Medium**: Patch for current version, evaluate backport to previous version
4. **Low**: Patch for current version in next scheduled release

## Migration Guide

### Upgrading Between Minor Versions

1. Backup your data and snapshots
2. Read the upgrade notes in CHANGELOG.md
3. Update the Helm chart version
4. Apply the upgrade using Helm or UPM Package Manager
5. Verify functionality and cluster health
6. Test search and indexing operations

### Upgrading Between Major Versions

1. Full backup and verification
2. Review migration documentation
3. Test upgrade in staging environment
4. Plan for potential downtime
5. Execute upgrade during maintenance window
6. Comprehensive testing and verification
7. Validate all indices and mappings
8. Test third-party integrations

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).