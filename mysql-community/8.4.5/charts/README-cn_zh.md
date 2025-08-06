# MySQL Community 8.4.5 - UPM 软件包定义

<div align="center">

[![Helm Version](https://img.shields.io/badge/Helm-v3-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20%2B-green.svg)](https://kubernetes.io/)
[![Package Type](https://img.shields.io/badge/Type-UPM%20Template-yellow.svg)]()
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**MySQL Community 8.4.5 UPM 软件包和导入模板**

[🇨🇳 中文](README-cn_zh.md) | [🇬🇧 English](README.md)

</div>

## 概述

本软件包定义了 MySQL Community 8.4.5 的软件镜像和导入模板，用于 UPM (Unit Package Manager) 系统。它提供了在 UPM 生态系统中部署 MySQL 实例所需的基础模板和配置。

**重要说明**: 此软件包需要 UPM CRD (Unit 和 UnitSets) 才能运行，不是独立的 Helm Chart，不能直接用于 MySQL 部署。

## 软件包结构

```
charts/
├── Chart.yaml                  # 软件包元数据
├── values.yaml                 # 默认配置值
├── files/                      # 配置文件目录
│   ├── mysqlParametersDetail.json  # 参数定义和验证规则
│   ├── mysqlTemplate.tpl           # MySQL 配置模板
│   └── mysqlValue.yaml             # MySQL 参数值
└── templates/                  # Kubernetes 模板文件
    ├── _helpers.tpl              # 模板辅助函数
    ├── configTemplate.yaml       # 配置模板 ConfigMap
    ├── configValue.yaml          # 配置值 ConfigMap
    ├── parametersDetail.yaml     # 参数详情 ConfigMap
    └── podtemplate.yaml          # Pod 模板定义
```

## UPM 集成

### 核心组件

**软件镜像定义**: 提供 MySQL Community 8.4.5 容器镜像规范和配置模板。

**导入模板**: 定义使用 Unit 和 UnitSets CRD 将 MySQL 实例导入 UPM 生态系统的结构。

**配置管理**: 包含验证、元数据和动态模板生成的综合参数系统。

### 所需 CRD

此软件包需要以下 UPM CRD 才能运行：

- **Unit**: 定义各个 MySQL 实例及其规范
- **UnitSets**: 管理多个 MySQL 实例以实现扩展和高可用性

### UPM 使用方式

1. **软件包安装**: 安装此软件包以使 MySQL 模板可用
2. **Unit 创建**: 创建引用此软件包的 Unit CRD
3. **UnitSet 管理**: 使用 UnitSets 管理多个 MySQL 实例
4. **配置**: 通过 UPM 规范自定义参数

## 关键模板

### Pod 模板

`podtemplate.yaml` 定义了完整的 MySQL pod 结构，包括：

- **MySQL 容器**: 主数据库服务器，带健康检查
- **Unit Agent**: UPM 管理集成，端口 2214
- **Metrics Exporter**: 监控 mysqld-exporter，端口 9104
- **Init Containers**: 服务器初始化和系统配置

### 配置系统

四层配置架构：

1. **参数定义** (`mysqlParametersDetail.json`): 元数据和验证规则
2. **参数值** (`mysqlValue.yaml`): 生产优化设置
3. **配置模板** (`mysqlTemplate.tpl`): 动态配置生成
4. **生成配置**: 运行时 MySQL 配置文件

## 软件包元数据

```yaml
apiVersion: v2
appVersion: 8.4.5
name: mysql-community-8.4.5
version: 2.0.0
description: MySQL 社区版软件包，包含配置模板和 Pod 模板。
type: application
keywords:
  - mysql
  - database
  - sql
  - upm
```

## 安装

```bash
# 将库添加到 repo 中（通常使用标签而不是 main 分支）：
helm repo add upm-packages https://upmio.github.io/upm-packages
helm repo update

# 安装 UPM 软件包
helm install --namespace=upm-system upm-packages-mysql-community-8.4.5 upm-packages/mysql-community-8.4.5

# 验证软件包安装
helm status upm-packages-mysql-community-8.4.5 --namespace=upm-system
```

## 下一步

安装此软件包后：

1. 创建 Unit CRD 来定义 MySQL 实例
2. 创建 UnitSet CRD 来管理多个实例
3. 通过 UPM 规范配置参数
4. 通过 UPM 控制平面监控部署

## 配置文件

### mysqlParametersDetail.json
包含所有 MySQL 8.4.5 配置参数的全面参数元数据、验证规则和双语文档。

### mysqlTemplate.tpl
基于 Go 模板的 MySQL 配置生成器，支持动态参数替换和环境变量集成。

### mysqlValue.yaml
MySQL 部署的生产优化参数值，包括性能、安全性和高可用性设置。

## 模板集成

该软件包生成与 UPM CRD 协同工作的 Kubernetes 资源：

- **ConfigMaps**: 存储配置模板和参数定义
- **PodTemplate**: 定义 MySQL 实例的 pod 结构
- **辅助函数**: 标准化镜像引用和资源管理

---

<div align="center">

**📚 更多 UPM 使用信息，请参考 UPM 文档**

[UPM 文档](https://docs.upmio.io) | 
[软件包注册表](https://packages.upmio.io) | 
[技术支持](https://support.upmio.io)

</div>