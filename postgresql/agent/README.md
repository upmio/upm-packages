# PostgreSQL Community Agent

PostgreSQL Community Agent for UPM Packages - providing sidecar container capabilities for PostgreSQL database operations, monitoring, and maintenance tasks.

## Overview

The PostgreSQL Community Agent is a specialized sidecar container that runs alongside PostgreSQL Community instances to provide advanced database management capabilities. Built on top of the `unit-agent` framework, it includes PostgreSQL client tools and utilities for enterprise-grade database operations.

## Architecture

### Base Components

- **Unit Agent**: Core agent framework for container orchestration
- **PostgreSQL Client**: Command-line tools for database interaction
- **PostgreSQL Server**: Full PostgreSQL server installation for management tasks
- **Monitoring Tools**: Performance monitoring and metrics collection
- **Maintenance Utilities**: Database optimization and repair tools

### Container Role

The agent runs as a sidecar container in the same pod as the main PostgreSQL server, providing:

- **Logical backups** using pg_dump and pg_restore
- **Real-time monitoring** of PostgreSQL performance
- **Automated maintenance** tasks
- **Replication management** and failover support
- **Security auditing** and compliance checking

## Version Support

| Agent Version | PostgreSQL Compatibility | Status    | Features                                  |
| ------------- | ------------------------ | --------- | ----------------------------------------- |
| 15            | PostgreSQL 15.x          | ✅ Stable | PostgreSQL 15 client, pg_dump, pg_restore |

## Features

### Backup and Recovery

**Logical Backups with pg_dump**

- Consistent backups without interrupting database service
- Custom backup formats (plain, custom, directory)
- Selective database and table backups
- Compression and encryption support

```bash
# Create logical backup
pg_dump -U postgres -h localhost -F c -f /backups/postgresql.dump postgresdb

# Create compressed SQL backup
pg_dump -U postgres -h localhost -Fc -Z 9 -f /backups/postgresql.sqlc postgresdb

# Restore from backup
pg_restore -U postgres -h localhost -d postgresdb /backups/postgresql.dump

# Restore from SQL backup
psql -U postgres -h localhost -d postgresdb < /backups/postgresql.sql
```

### Monitoring and Metrics

**Real-time Monitoring**

- Query performance analysis
- Connection pool monitoring
- Resource usage tracking
- Replication status monitoring
- Long-running query detection

**Key Metrics**

- Connections count and usage
- Query response times
- Cache hit ratios
- Transaction rates
- Lock contention
- Vacuum and analyze statistics
- Replication lag and status

### Maintenance Operations

**Database Optimization**

- Index analysis and optimization
- Table maintenance (VACUUM, ANALYZE)
- Statistics updates
- Log file management
- Performance tuning recommendations

**Automated Tasks**

- Scheduled backups
- Regular VACUUM operations
- Statistics collection
- Health checks
- Cleanup operations

### Security Features

**Security Auditing**

- User permission analysis
- Role membership verification
- Access pattern monitoring
- Compliance checking
- Audit log management

**Access Control**

- Role-based access control
- Privilege monitoring
- Password policy enforcement
- SSL/TLS connection verification

## Deployment

### Sidecar Container Configuration

The agent is deployed as a sidecar container in the same pod as PostgreSQL:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
spec:
  template:
    spec:
      containers:
        - name: postgresql
          image: quay.io/upmio/postgresql:15.13
          # ... PostgreSQL container configuration
        - name: postgresql-agent
          image: quay.io/upmio/postgresql-agent:15
          env:
            - name: POSTGRES_HOST
              value: "localhost"
            - name: POSTGRESQL_PORT
              value: "5432"
            - name: BACKUP_SCHEDULE
              value: "0 2 * * *"
          # ... Agent configuration
```

### Environment Variables

| Variable             | Default     | Description                     |
| -------------------- | ----------- | ------------------------------- |
| `POSTGRES_HOST`      | `localhost` | PostgreSQL server hostname      |
| `POSTGRESQL_PORT`    | `5432`      | PostgreSQL server port          |
| `BACKUP_DIR`         | `/backups`  | Backup storage directory        |
| `BACKUP_SCHEDULE`    | -           | Cron schedule for backups       |
| `BACKUP_RETENTION`   | `7`         | Backup retention period in days |
| `MONITORING_ENABLED` | `true`      | Enable monitoring features      |
| `LOG_LEVEL`          | `INFO`      | Logging level                   |

### Resource Requirements

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Configuration

### Agent Configuration

The agent configuration is managed through the unit-agent framework:

```toml
[agent]
name = "postgresql-agent"
version = "2.0.0"

[postgresql]
host = "localhost"
port = 5432
timeout = "30s"

[backup]
enabled = true
schedule = "0 2 * * *"
retention_days = 7
format = "custom"
compression = true

[monitoring]
enabled = true
interval = "60s"
metrics_port = "8080"

[maintenance]
enabled = true
vacuum_schedule = "0 1 * * 6"
analyze_schedule = "0 3 * * 0"
log_retention_days = 30
```

### Backup Configuration

**pg_dump Configuration**

```bash
# Environment variables for backup
PGDUMP_OPTS="-Fc -Z 9 -U postgres"
PGRESTORE_OPTS="-U postgres -j 4"
BACKUP_FORMAT="custom"
BACKUP_COMPRESSION=9
```

### Monitoring Configuration

**Metrics Collection**

```yaml
monitoring:
  enabled: true
  interval: 60s
  metrics:
    - connections
    - transactions
    - cache_hit_ratio
    - replication_lag
    - lock_waits
    - vacuum_progress
  alerts:
    - high_connections
    - long_queries
    - replication_lag
    - disk_usage
    - bloat_ratio
```

## Security

### Security Best Practices

1. **Network Isolation**: Use network policies to restrict agent access
2. **Secrets Management**: Store credentials in Kubernetes secrets
3. **TLS Encryption**: Enable SSL/TLS for PostgreSQL connections
4. **Audit Logging**: Enable comprehensive audit logging
5. **Regular Updates**: Keep agent and tools updated
6. **Resource Limits**: Set appropriate resource limits
7. **Health Monitoring**: Monitor agent health and restart if needed

### Access Control

```yaml
securityContext:
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

## Monitoring and Logging

### Health Checks

```yaml
livenessProbe:
  exec:
    command:
      - /usr/local/bin/unit-agent
      - health
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command:
      - /usr/local/bin/unit-agent
      - ready
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Log Management

**Log Configuration**

- Agent logs: `/var/log/unit-agent/`
- Backup logs: `/var/log/postgresql/`
- Monitoring logs: `/var/log/monitoring/`
- Structured logging in JSON format

**Log Rotation**

- Daily log rotation
- 30-day retention
- Compressed archival
- Size-based rotation

## Integration

### UPM Package Manager Integration

The agent integrates with the UPM package manager for seamless operations:

```bash
# Check agent status
./upm-pkg-mgm.sh status postgresql-agent

# Update agent configuration
./upm-pkg-mgm.sh configure postgresql-agent

# Restart agent
./upm-pkg-mgm.sh restart postgresql-agent
```

### External Integration

**Monitoring Systems**

- Prometheus metrics endpoint
- Grafana dashboard templates
- AlertManager integration
- Custom metrics export

**Backup Systems**

- Integration with external backup storage
- Cloud storage support (S3, GCS, Azure)
- Backup verification and testing
- Disaster recovery procedures

## Troubleshooting

### Common Issues

**Agent Connectivity Issues**

```bash
# Check agent status
kubectl exec -it postgresql-pod -c postgresql-agent -- unit-agent status

# Test PostgreSQL connectivity
kubectl exec -it postgresql-pod -c postgresql-agent -- psql -h localhost -U postgres -c "SELECT 1"

# Check agent logs
kubectl logs postgresql-pod -c postgresql-agent
```

**Backup Issues**

```bash
# Check PostgreSQL client version
kubectl exec -it postgresql-pod -c postgresql-agent -- psql --version

# Test backup creation
kubectl exec -it postgresql-pod -c postgresql-agent -- pg_dump -U postgres -h localhost -Fc -f /tmp/test.dump postgresdb

# Check backup directory
kubectl exec -it postgresql-pod -c postgresql-agent -- ls -la /backups
```

**Performance Issues**

```bash
# Monitor resource usage
kubectl top pod postgresql-pod --containers

# Check PostgreSQL performance
kubectl exec -it postgresql-pod -c postgresql-agent -- psql -U postgres -h localhost -c "SELECT * FROM pg_stat_activity;"

# Check agent performance
kubectl logs postgresql-pod -c postgresql-agent | grep -i performance
```

## Development

### Building the Agent

```bash
# Build agent image for PostgreSQL 15 series
docker buildx build --platform linux/amd64,linux/arm64 \
  -t quay.io/upmio/postgresql-agent:15 \
  agent/15/image/
```

### Testing

```bash
# Test agent functionality
docker run --rm quay.io/upmio/postgresql-agent:15 unit-agent --version

# Test PostgreSQL client tools
docker run --rm quay.io/upmio/postgresql-agent:15 psql --version

# Test PostgreSQL server
docker run --rm quay.io/upmio/postgresql-agent:15 postgres --version
```

## Support

For support and issues:

1. Review [UPM Packages issues](https://github.com/upmio/upm-packages/issues)
2. Check PostgreSQL Community documentation
3. Refer to PostgreSQL official documentation
4. Contact UPM support team

## License

This component is licensed under the terms of the MIT License.

---

**Note**: This is a component of the [UPM Packages](https://github.com/upmio/upm-packages) project and is designed to work as a sidecar container with PostgreSQL Community instances.
