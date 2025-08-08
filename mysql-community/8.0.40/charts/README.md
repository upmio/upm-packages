# MySQL Community 8.0.40 - UPM Package Definition

<div align="center">

[![Helm Version](https://img.shields.io/badge/Helm-v3-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20%2B-green.svg)](https://kubernetes.io/)
[![Package Type](https://img.shields.io/badge/Type-UPM%20Template-yellow.svg)]()
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**MySQL Community 8.0.40 UPM Software Package & Import Template**

[🇬🇧 English](README.md)

</div>

## Overview

This package defines the MySQL Community 8.0.40 software image and import template for the UPM (Unit Package Manager) system. It provides the foundational templates and configurations required to deploy MySQL instances within the UPM ecosystem.

**Important**: This package requires UPM CRDs (Unit and UnitSets) to function and is not a standalone Helm chart for direct MySQL deployment.

## Package Structure

```
charts/
├── Chart.yaml                  # Package metadata
├── values.yaml                 # Default configuration values
├── files/                      # Configuration files directory
│   ├── mysqlParametersDetail.json  # Parameter definitions and validation
│   ├── mysqlTemplate.tpl           # MySQL configuration template
│   └── mysqlValue.yaml             # MySQL parameter values
└── templates/                  # Kubernetes template files
    ├── _helpers.tpl              # Template helper functions
    ├── configTemplate.yaml       # Configuration template ConfigMap
    ├── configValue.yaml          # Configuration values ConfigMap
    ├── parametersDetail.yaml     # Parameter details ConfigMap
    └── podtemplate.yaml          # Pod template definition
```

## UPM Integration

### Core Components

**Software Image Definition**: Provides the MySQL Community 8.0.40 container image specification and configuration templates.

**Import Template**: Defines the structure for importing MySQL instances into the UPM ecosystem using Unit and UnitSets CRDs.

**Configuration Management**: Comprehensive parameter system with validation, metadata, and dynamic template generation.

### Required CRDs

This package requires the following UPM CRDs to function:

- **Unit**: Defines individual MySQL instances with their specifications
- **UnitSets**: Manages groups of MySQL units for scaling and high availability

### Usage with UPM

1. **Package Installation**: Install this package to make MySQL templates available
2. **Unit Creation**: Create Unit CRDs referencing this package
3. **UnitSet Management**: Use UnitSets to manage multiple MySQL instances
4. **Configuration**: Customize parameters through UPM specifications

## Key Templates

### Pod Template

The `podtemplate.yaml` defines the complete MySQL pod structure including:

- **MySQL Container**: Main database server with health probes
- **Unit Agent**: UPM management integration on port 2214
- **Metrics Exporter**: Monitoring with mysqld-exporter on port 9104
- **Init Containers**: Server initialization and system configuration

### Configuration System

Four-layer configuration architecture:

1. **Parameter Definitions** (`mysqlParametersDetail.json`): Metadata and validation rules
2. **Parameter Values** (`mysqlValue.yaml`): Production-optimized settings
3. **Configuration Template** (`mysqlTemplate.tpl`): Dynamic configuration generation
4. **Generated Config**: Runtime MySQL configuration files

## Package Metadata

```yaml
apiVersion: v2
appVersion: 8.0.40
name: mysql-community-8.0.40
version: 2.0.0
description: MySQL community edition software packages, including configuration templates and pod templates.
type: application
keywords:
  - mysql
  - database
  - sql
  - upm
```

## Installation

```bash
# Add the repo to helm (typically use a tag rather than main):
helm repo add upm-packages https://upmio.github.io/upm-packages
helm repo update

# Install the UPM package
helm install --namespace=upm-system upm-packages-mysql-community-8.0.40 upm-packages/mysql-community-8.0.40

# Verify package installation
helm status upm-packages-mysql-community-8.0.40 --namespace=upm-system
```

## Next Steps

After installing this package:

1. Create Unit CRDs to define MySQL instances
2. Create UnitSet CRDs for managing multiple instances
3. Configure parameters through UPM specifications
4. Monitor deployments through the UPM control plane

## Configuration Files

### mysqlParametersDetail.json
Comprehensive parameter metadata with validation rules and bilingual documentation for all MySQL 8.0.40 configuration parameters.

### mysqlTemplate.tpl
Go template-based MySQL configuration generator with dynamic parameter substitution and environment variable integration.

### mysqlValue.yaml
Production-optimized parameter values for MySQL deployment, including performance, security, and high availability settings.

## Template Integration

The package generates Kubernetes resources that work with UPM CRDs:

- **ConfigMaps**: Store configuration templates and parameter definitions
- **PodTemplate**: Defines pod structure for MySQL instances
- **Helper Functions**: Standardize image references and resource management

---

<div align="center">

**📚 For more information on UPM usage, refer to the UPM documentation**

[UPM Documentation](https://docs.upmio.io) | 
[Package Registry](https://packages.upmio.io) | 
[Support](https://support.upmio.io)

</div>