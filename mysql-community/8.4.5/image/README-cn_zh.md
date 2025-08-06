# MySQL Community 8.4.5 - Docker 镜像定义

<div align="center">

[![Docker](https://img.shields.io/badge/Docker-2496ED.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![MySQL](https://img.shields.io/badge/MySQL-8.4.5-orange.svg)](https://dev.mysql.com/)
[![Rocky Linux](https://img.shields.io/badge/Rocky%20Linux-9-blue.svg)](https://rockylinux.org/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**MySQL Community 8.4.5 Docker 镜像定义**

[🇨🇳 中文](README-cn_zh.md) | [🇬🇧 English](README.md)

</div>

## 概述

本目录包含 MySQL Community 8.4.5 的 Docker 镜像定义，作为 UPM (Unit Package Manager) 系统的基础容器镜像。该镜像基于 Rocky Linux 9 构建，包含完整的服务器管理工具、监控支持和安全配置。

## 镜像组件

### 核心文件

```
image/
├── Dockerfile              # Docker 构建定义
├── serverMGR.sh           # 服务器管理脚本
└── supervisord.conf       # 进程管理配置
```

### Dockerfile

Dockerfile 定义了多阶段构建过程：

**基础镜像**: `rockylinux/rockylinux:9.5.20241118`

**关键组件**:
- **系统包**: 包含 procps-ng、openssl、wget 和网络工具等必需工具
- **MySQL 组件**: MySQL Shell 8.4.5 和 MySQL Server Minimal 8.4.5
- **环境配置**: UTF-8 语言环境、Asia/Shanghai 时区
- **用户管理**: 专用 mysql 用户 (uid=1001, gid=1001)
- **运行时**: 基于 Supervisor 的进程管理

### serverMGR.sh

综合服务器管理脚本，提供以下功能：

**核心功能**:
- **密码管理**: 使用 OpenSSL AES-256-CBC 加密进行安全密码处理
- **数据库初始化**: 为各种部署模式自动设置
- **用户管理**: 创建和配置 MySQL 用户
- **监控**: 健康检查和状态报告

**主要操作**:
```bash
# 初始化数据库
serverMGR.sh initialize

# 管理员登录
serverMGR.sh login

# 密码解密
get_pwd()  # 内部密码管理函数
```

**必需的环境变量**:
- `DATA_MOUNT`, `CONF_DIR`, `TMP_DIR` - 目录配置
- `MYSQL_PORT`, `POD_NAME` - 网络和标识
- `ADM_USER`, `MON_USER`, `REPL_USER`, `PROV_USER` - 用户账户
- `ARCH_MODE` - 部署架构模式
- `SECRET_MOUNT` - 密码密钥位置

### supervisord.conf

可靠运行的进程管理配置：

**配置部分**:
- **[supervisord]**: 支持环境变量的主监控器设置
- **[program:unit_app]**: MySQL 服务器进程定义
- **[inet_http_server]**: 端口 9001 上的管理接口
- **[supervisorctl]**: 控制接口配置

**主要特性**:
- 环境变量替换实现动态配置
- 带轮转的日志管理
- 进程自动重启功能
- 用户级安全 (以 mysql 用户运行)

## 构建说明

```bash
# 构建 Docker 镜像
docker build -t mysql-community:8.4.5 ./image

# 验证构建
docker images | grep mysql-community

# 测试镜像
docker run --rm mysql-community:8.4.5 mysqld --version
```

## UPM 环境中的使用

此镜像设计用于与 UPM 系统配合使用，并被父目录中的 Helm chart 引用。关键集成点：

1. **进程管理**: Supervisor 协调 MySQL 启动和监控
2. **配置**: 通过环境变量进行动态配置
3. **安全**: 集成密码管理和用户隔离
4. **监控**: 内置健康检查和日志记录

## 安全特性

- **非 root 执行**: MySQL 以专用用户运行 (uid=1001)
- **密码加密**: 基于 OpenSSL 的密码管理
- **进程隔离**: Supervisor 管理的进程
- **资源限制**: 可配置的资源约束

## 维护

镜像包含全面的日志记录和监控功能：
- 通过 Supervisor 进行结构化日志记录
- MySQL 错误和通用查询日志
- 进程监控和自动重启
- 健康检查端点

---

<div align="center">

**📚 更多 UPM 使用信息，请参考 UPM 文档**

[UPM 文档](https://docs.upmio.io) | 
[软件包注册表](https://packages.upmio.io) | 
[技术支持](https://support.upmio.io)

</div>