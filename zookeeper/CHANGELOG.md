# Changelog

All notable changes to ZooKeeper Community Edition will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced service control script with comprehensive health checks
- Improved error handling with standardized exit codes
- Better JVM memory management and garbage collection configuration
- Prometheus metrics exporter integration
- Four-letter command whitelisting for security
- Enhanced ensemble configuration with automatic myid generation
- Improved supervisord configuration with HTTP interface
- Better resource management and monitoring
- Enhanced security with non-root user (UID 1001) operation
- Multi-architecture container image support (linux/amd64, linux/arm64)
- Bitnami common chart dependency for improved Helm integration
- Unit agent integration for better configuration management
- Improved initialization process with force clean option
- Enhanced pod template with proper security contexts
- Better log management and rotation

### Changed
- Renamed `serverMGR.sh` to `service-ctl.sh` for consistency with other components
- Updated container base image to Rocky Linux 9.5.20241118
- Improved health check functionality with process and port validation
- Enhanced error handling and logging with structured timestamps
- Standardized environment variable naming and validation
- Optimized JVM configuration with G1 garbage collector
- Enhanced ensemble configuration and coordination
- Updated supervisord configuration for better process management
- Improved directory structure for data and logs
- Enhanced Kubernetes probe configurations
- Better resource limits and requests management
- Improved template system with Go template functions
- Enhanced parameter management system

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering with proper variable substitution
- Kubernetes probe configurations for better reliability
- JVM memory configuration and validation
- Data persistence mounting with proper ownership
- Network connectivity and health monitoring
- Ensemble coordination and leader election
- Transaction log management with proper separation
- Snapshot management and cleanup
- Data consistency issues with proper validation
- Security context configurations for containers
- File permissions and ownership management
- Environment variable validation and defaults
- Health check endpoint reliability
- Process management with supervisord

### Security
- Enhanced non-root user support (UID 1001) with proper privilege escalation prevention
- Implemented comprehensive file permissions and ownership management
- Added security context configurations for Kubernetes deployments
- Enhanced container isolation with read-only root filesystem support
- Added SSL/TLS configuration support for encrypted communication
- Implemented SASL authentication support for secure access
- Enhanced network isolation features with proper network policies
- Improved ensemble communication security with encrypted channels
- Strengthened configuration management security with proper validation
- Added four-letter command whitelisting to prevent unauthorized access
- Enhanced container security with minimal base image and regular updates

## [1.0.0] - 2025-08-08

### Added
- Apache ZooKeeper 3.8.4 support with latest stable version
- Container image with Rocky Linux 9.5.20241118 base for enhanced security
- Supervisord process management with HTTP interface and health monitoring
- ZooKeeper server community package integration with PGP verification
- Bitnami common chart dependency for improved Helm integration
- Pod template for Kubernetes deployment with init containers
- Configuration template system using Go templates with custom functions
- Parameter management system with JSON schema validation
- Service control script (`service-ctl.sh`) with health checks and initialization
- Health check endpoints with comprehensive process and port validation
- Liveness and readiness probes with proper failure handling
- Resource management and limits with automatic memory allocation
- Environment variable configuration with proper validation
- Persistent volume support for data and transaction logs
- Service discovery integration with headless service support
- Logging and monitoring support with structured log management
- JVM optimization and configuration with G1 garbage collector
- Ensemble management capabilities with automatic myid generation
- Leader election and coordination with quorum management
- Metrics export functionality with Prometheus integration
- Four-letter command whitelisting for enhanced security
- Unit agent integration for configuration management
- Multi-architecture container image support (linux/amd64, linux/arm64)
- Enhanced security with non-root user operation (UID 1001)

### Security
- Container runs as non-root user (zookeeper, UID 1001) with restricted privileges
- Proper file permissions and ownership with secure defaults
- Security context configuration for Kubernetes deployments
- Read-only root filesystem support with proper volume mounting
- Privilege escalation prevention with secure container configuration
- SSL/TLS encryption support for secure client communication
- SASL authentication support for enhanced access control
- Network isolation features with proper network policies
- Ensemble communication security with encrypted channels
- Configuration management security with proper validation and templating
- Four-letter command whitelisting to prevent unauthorized access
- Container security with minimal base image and regular security updates

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
- Transaction log management
- Snapshot management
- Data consistency guarantees

### Coordination Features
- Distributed coordination service
- Leader election algorithms
- Data consistency and synchronization
- Distributed locking mechanisms
- Configuration management
- Group membership management
- Naming service
- Event notification system
- Distributed queue management
- Barrier synchronization
- Two-phase commit coordination

### Ensemble Management
- Multi-node ensemble support
- Leader election and coordination
- Data replication and consistency
- Quorum and consensus protocols
- Fault tolerance and recovery
- Cluster membership management
- Network partition handling
- Data consistency guarantees
- Distributed coordination
- Ensemble scaling capabilities

### Monitoring and Logging
- Comprehensive logging system
- Health check endpoints
- Performance monitoring capabilities
- Resource usage tracking
- Ensemble health monitoring
- Node status metrics
- Request latency monitoring
- Connection statistics
- Data size metrics
- JVM memory and garbage collection

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- Ensemble setup and management
- High availability configuration
- Distributed coordination procedures

### High Availability
- Multi-node ensemble support
- Leader election and failover
- Data replication and consistency
- Quorum management
- Cluster fault tolerance
- Network partition handling
- Data consistency guarantees
- Ensemble recovery procedures
- Load balancing configuration
- Disaster recovery planning

### Integration
- UPM Package Manager integration
- External monitoring tools integration
- Logging aggregation support
- Security scanning integration
- Container orchestration support
- Distributed systems coordination
- Kafka cluster coordination
- Hadoop ecosystem integration
- Database cluster coordination
- Message queue coordination
- Stream processing coordination

### Performance
- Optimized request handling
- Efficient data storage
- Fast leader election
- Low-latency coordination
- High throughput operations
- Memory management optimization
- Network traffic optimization
- Disk I/O performance
- Connection pooling
- Resource utilization optimization

### Scalability
- Horizontal scaling support
- Ensemble size flexibility
- Load distribution
- Resource allocation
- Performance tuning
- Capacity planning
- Monitoring and metrics
- Auto-scaling capabilities
- Cluster management
- Resource optimization

---

## Version Classification

- **Major**: Breaking changes, significant new features, ZooKeeper version upgrades
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

- **Current version** (3.8.x): Full support, including new features and security updates
- **Previous versions**: Security patches and critical bug fixes only
- **Older versions**: No support, upgrade recommended

### ZooKeeper Community Support Timeline

- ZooKeeper 3.8.x: Full support until Apache's EOL date
- Older versions: Upgrade immediately

## Security Updates

Security patches will be backported to supported versions according to the following priority:

1. **Critical**: Immediate patch for all supported versions
2. **High**: Patch for current version, backport to previous version within 2 weeks
3. **Medium**: Patch for current version, evaluate backport to previous version
4. **Low**: Patch for current version in next scheduled release

## Migration Guide

### Upgrading Between Minor Versions

1. Backup your ZooKeeper data
2. Read the upgrade notes in CHANGELOG.md
3. Update the Helm chart version
4. Apply the upgrade using Helm or UPM Package Manager
5. Verify functionality and ensemble health
6. Test coordination operations
7. Verify data consistency

### Upgrading Between Major Versions

1. Full backup and verification
2. Review migration documentation
3. Test upgrade in staging environment
4. Plan for potential downtime
5. Execute upgrade during maintenance window
6. Comprehensive testing and verification
7. Validate all ensemble nodes
8. Test coordination services
9. Verify data consistency
10. Test third-party integrations

### Ensemble Migration

1. Backup all data and configurations
2. Plan migration strategy
3. Create new ensemble
4. Migrate data incrementally
5. Verify data consistency
6. Switch traffic to new ensemble
7. Decommission old ensemble
8. Monitor performance and health

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).