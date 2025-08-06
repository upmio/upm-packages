# MySQL Community 8.4.5 - Docker Image Definition

<div align="center">

[![Docker](https://img.shields.io/badge/Docker-2496ED.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![MySQL](https://img.shields.io/badge/MySQL-8.4.5-orange.svg)](https://dev.mysql.com/)
[![Rocky Linux](https://img.shields.io/badge/Rocky%20Linux-9-blue.svg)](https://rockylinux.org/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**MySQL Community 8.4.5 Docker Image Definition**

[🇨🇳 中文](README-cn_zh.md) | [🇬🇧 English](README.md)

</div>

## Overview

This directory contains the Docker image definition for MySQL Community 8.4.5, which serves as the foundational container image for the UPM (Unit Package Manager) system. The image is built on Rocky Linux 9 and includes comprehensive server management tools, monitoring support, and security configurations.

## Image Components

### Core Files

```
image/
├── Dockerfile              # Docker build definition
├── serverMGR.sh           # Server management script
└── supervisord.conf       # Process management configuration
```

### Dockerfile

The Dockerfile defines a multi-stage build process:

**Base Image**: `rockylinux/rockylinux:9.5.20241118`

**Key Components**:
- **System Packages**: Essential tools including procps-ng, openssl, wget, and network utilities
- **MySQL Components**: MySQL Shell 8.4.5 and MySQL Server Minimal 8.4.5
- **Environment Configuration**: UTF-8 locale, Asia/Shanghai timezone
- **User Management**: Dedicated mysql user (uid=1001, gid=1001)
- **Runtime**: Supervisor-based process management

### serverMGR.sh

Comprehensive server management script providing:

**Core Functions**:
- **Password Management**: OpenSSL AES-256-CBC encryption for secure password handling
- **Database Initialization**: Automated setup for various deployment modes
- **User Management**: Creation and configuration of MySQL users
- **Monitoring**: Health checks and status reporting

**Key Operations**:
```bash
# Initialize database
serverMGR.sh initialize

# Administrator login
serverMGR.sh login

# Password decryption
get_pwd()  # Internal function for password management
```

**Environment Variables Required**:
- `DATA_MOUNT`, `CONF_DIR`, `TMP_DIR` - Directory configurations
- `MYSQL_PORT`, `POD_NAME` - Network and identification
- `ADM_USER`, `MON_USER`, `REPL_USER`, `PROV_USER` - User accounts
- `ARCH_MODE` - Deployment architecture mode
- `SECRET_MOUNT` - Password secrets location

### supervisord.conf

Process management configuration for reliable operation:

**Configuration Sections**:
- **[supervisord]**: Main supervisor settings with environment variable support
- **[program:unit_app]**: MySQL server process definition
- **[inet_http_server]**: Management interface on port 9001
- **[supervisorctl]**: Control interface configuration

**Key Features**:
- Environment variable substitution for dynamic configuration
- Log management with rotation
- Process auto-restart capabilities
- User-level security (runs as mysql user)

## Build Instructions

```bash
# Build the Docker image
docker build -t mysql-community:8.4.5 ./image

# Verify the build
docker images | grep mysql-community

# Test the image
docker run --rm mysql-community:8.4.5 mysqld --version
```

## Usage in UPM Context

This image is designed to work with the UPM system and is referenced by the Helm chart in the parent directory. Key integration points:

1. **Process Management**: Supervisor coordinates MySQL startup and monitoring
2. **Configuration**: Dynamic configuration through environment variables
3. **Security**: Integrated password management and user isolation
4. **Monitoring**: Built-in health checks and logging

## Security Features

- **Non-root Execution**: MySQL runs as dedicated user (uid=1001)
- **Password Encryption**: OpenSSL-based password management
- **Process Isolation**: Supervisor-managed processes
- **Resource Limits**: Configurable resource constraints

## Maintenance

The image includes comprehensive logging and monitoring capabilities:
- Structured logging through Supervisor
- MySQL error and general query logs
- Process monitoring and auto-restart
- Health check endpoints

---

<div align="center">

**📚 For more information on UPM usage, refer to the UPM documentation**

[UPM Documentation](https://docs.upmio.io) | 
[Package Registry](https://packages.upmio.io) | 
[Support](https://support.upmio.io)

</div>