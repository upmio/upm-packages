# Changelog

All notable changes to ProxySQL Community Edition will be documented in this file.

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
- Comprehensive metrics and monitoring support
- Query caching capabilities
- Load balancing and connection pooling

### Changed
- Renamed `serverMGR.sh` to `service-ctl.sh` for consistency
- Updated all references to use new naming convention
- Cleaned up Helm chart dependencies (removed `.tgz` files from version control)
- Standardized configuration file naming
- Enhanced security configurations
- Improved error handling and logging

### Fixed
- Container initialization and lifecycle management
- Configuration template rendering
- Kubernetes probe configurations
- Password decryption and management
- Admin interface authentication
- Memory leak issues in long-running deployments

### Security
- Added non-root user support (UID 1001)
- Implemented proper file permissions
- Added security context configurations
- Enhanced container isolation
- Improved credential management with OpenSSL encryption
- Added network isolation policies
- Secure admin interface access control

## [1.0.0] - 2025-08-08

### Added
- ProxySQL Community Edition 2.7.2 support
- ProxySQL Community Edition 2.7.3 support
- Container image with Rocky Linux 9.5.20241118 base
- Supervisord process management
- ProxySQL community package integration
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

### Performance
- High-performance connection pooling
- Advanced query caching
- Intelligent load balancing
- Connection multiplexing
- Query result caching
- Memory optimization
- Thread pool management
- Network optimization

### Security
- Container runs as non-root user (proxysql, UID 1001)
- Proper file permissions and ownership
- Security context configuration
- Read-only root filesystem support
- Privilege escalation prevention
- Secure password management with OpenSSL encryption
- Admin interface authentication
- Network isolation and security policies

### Technical
- Multi-architecture support (linux/amd64, linux/arm64)
- Optimized Docker layer structure
- Efficient package management
- Locale and timezone configuration
- Process supervision with health monitoring
- Graceful shutdown handling
- Resource cleanup and management
- Configuration validation and testing

### Monitoring
- Comprehensive metrics collection
- Prometheus metrics export
- Admin interface for statistics
- Memory usage monitoring
- Connection pool monitoring
- Query performance metrics
- System health monitoring
- Log aggregation and rotation

### Documentation
- Comprehensive README with installation guide
- Configuration examples and best practices
- Troubleshooting guide
- Security recommendations
- Performance optimization tips
- Development and contribution guidelines
- API documentation
- Integration guide with UPM ecosystem

### Integration
- UPM package manager integration
- MySQL server discovery and management
- Kubernetes service discovery
- Configuration management system
- Template-based configuration generation
- Parameter validation and management
- Secret management integration
- Network policy configuration

---

## Version Classification

- **Major**: Breaking changes, significant new features, architecture changes
- **Minor**: New features, backward-compatible changes, performance improvements
- **Patch**: Bug fixes, security updates, documentation improvements

## Release Process

1. Update version numbers in Chart.yaml files
2. Update CHANGELOG.md
3. Create and test release artifacts
4. Tag the release
5. Publish to container registry
6. Update Helm repository
7. Update UPM package manager references

## Support Policy

- **Current version (2.7.3)**: Full support including bug fixes and security patches
- **Previous version (2.7.2)**: Security patches only, limited support
- **Older versions**: No support, upgrade recommended

## Upgrade Path

### From 2.7.2 to 2.7.3
- Backup configuration before upgrade
- Review configuration changes in changelog
- Test upgrade in staging environment
- Monitor performance post-upgrade
- Update monitoring and alerting rules

### Migration Notes
- Configuration file format changes
- Environment variable updates
- Security setting enhancements
- Performance tuning recommendations

For more information about support timelines and upgrade procedures, please refer to the [README](README.md).

## Known Issues

### Current Known Issues
- Memory usage may increase gradually in high-traffic environments (monitor and restart as needed)
- Admin interface may become unresponsive under heavy load (implement load balancing)
- Query cache invalidation may have delays in cluster environments
- Connection pool exhaustion under spike traffic (configure appropriate limits)

### Workarounds
- Implement regular health checks and automatic restarts
- Use multiple ProxySQL instances for high availability
- Monitor memory usage and set appropriate limits
- Configure connection pool settings based on expected load
- Implement proper logging and monitoring

## Future Roadmap

### Planned Features
- Enhanced query optimization
- Advanced clustering support
- Automated failover mechanisms
- Improved monitoring and alerting
- Configuration management UI
- Performance analytics dashboard
- Integration with other database systems
- Enhanced security features

### Performance Improvements
- Reduced memory footprint
- Improved connection handling
- Better query caching algorithms
- Enhanced load balancing strategies
- Network optimization
- Resource usage optimization

### Security Enhancements
- Multi-factor authentication
- Role-based access control
- Audit logging
- Network encryption improvements
- Vulnerability scanning integration
- Compliance reporting

---

*Last updated: 2025-08-08*