# Changelog

All notable changes to Kafka Community Edition will be documented in this file.

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
- JVM optimization and memory management
- Zookeeper integration capabilities
- Cluster configuration and management
- Topic management capabilities

### Changed
- Renamed `serverMGR.sh` to `service-ctl.sh` for consistency
- Updated all references to use new naming convention
- Updated container base image to Rocky Linux 9.5.20241118
- Improved health check functionality
- Enhanced error handling and logging
- Standardized exit codes and error handling
- Cleaned up Helm chart dependencies
- Optimized JVM configuration and garbage collection
- Enhanced broker configuration and performance

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations
- JVM memory configuration and validation
- Data persistence mounting
- Network connectivity and health monitoring
- Zookeeper connectivity and coordination
- Topic creation and management
- Consumer group handling

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation
- Added SSL/TLS configuration support
- SASL authentication support
- Network isolation features
- Zookeeper integration security
- Broker authentication configuration

## [1.0.0] - 2025-08-07

### Added
- Apache Kafka 3.5.2 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- Kafka broker community package integration
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
- JVM optimization and configuration

### Security
- Container runs as non-root user (kafka, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- SSL/TLS encryption support
- SASL authentication support
- Network isolation features
- Zookeeper integration security
- Broker authentication configuration

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management
- Data persistence and volume management
- JVM optimization and garbage collection
- Performance optimization configurations
- Network configuration and tuning

### Streaming Features
- High-throughput message processing
- Distributed event streaming
- Topic and partition management
- Producer and consumer APIs
- Message compression support
- Exactly-once semantics
- Transaction support
- Stream processing capabilities
- Connect framework integration
- Schema registry integration

### Cluster Management
- Multi-broker cluster support
- Leader election and coordination
- Replication and fault tolerance
- Consumer group management
- Topic replication and partitioning
- Broker discovery and registration
- Cluster metadata management
- Quorum and consensus protocols
- Load balancing capabilities
- High availability configuration

### Monitoring and Logging
- Comprehensive logging system
- Health check endpoints
- Performance monitoring capabilities
- Resource usage tracking
- Broker health monitoring
- Topic and partition metrics
- Consumer lag monitoring
- Producer performance metrics
- Network throughput monitoring
- JVM memory and garbage collection

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- Cluster setup and management
- High availability configuration
- Topic management procedures

### High Availability
- Multi-broker cluster support
- Leader election and failover
- Data replication and redundancy
- Consumer group rebalancing
- Broker fault tolerance
- Topic replication configuration
- Disaster recovery planning
- Load balancing configuration
- Cluster recovery procedures

### Integration
- UPM Package Manager integration
- External monitoring tools integration
- Logging aggregation support
- Security scanning integration
- Container orchestration support
- Zookeeper seamless integration
- Schema registry integration
- Kafka Connect integration
- Kafka Streams integration
- Third-party client support

---

## Version Classification

- **Major**: Breaking changes, significant new features, Kafka version upgrades
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

- **Current version** (3.5.x): Full support, including new features and security updates
- **Previous versions**: Security patches and critical bug fixes only
- **Older versions**: No support, upgrade recommended

### Kafka Community Support Timeline

- Kafka 3.5.x: Full support until Apache's EOL date
- Older versions: Upgrade immediately

## Security Updates

Security patches will be backported to supported versions according to the following priority:

1. **Critical**: Immediate patch for all supported versions
2. **High**: Patch for current version, backport to previous version within 2 weeks
3. **Medium**: Patch for current version, evaluate backport to previous version
4. **Low**: Patch for current version in next scheduled release

## Migration Guide

### Upgrading Between Minor Versions

1. Backup your topics and configurations
2. Read the upgrade notes in CHANGELOG.md
3. Update the Helm chart version
4. Apply the upgrade using Helm or UPM Package Manager
5. Verify functionality and cluster health
6. Test producer and consumer operations

### Upgrading Between Major Versions

1. Full backup and verification
2. Review migration documentation
3. Test upgrade in staging environment
4. Plan for potential downtime
5. Execute upgrade during maintenance window
6. Comprehensive testing and verification
7. Validate all topics and consumer groups
8. Test third-party integrations

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).