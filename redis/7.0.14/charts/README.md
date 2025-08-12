# Redis 7.0.14 - UPM Package Definition

<div align="center">

[![Helm Version](https://img.shields.io/badge/Helm-v3-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29%2B-green.svg)](https://kubernetes.io/)
[![Package Type](https://img.shields.io/badge/Type-UPM%20Template-yellow.svg)]()
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

**Redis 7.0.14 UPM Software Package & Import Template**

</div>

## Overview

This package defines the Redis 7.0.14 software image and UPM import template. It provides templates and configurations to deploy Redis instances in the UPM ecosystem.

Important: This package works with UPM CRDs (Unit, UnitSets) and is not a standalone Helm chart for direct Redis deployment.

## Package Structure

```
charts/
├── Chart.yaml
├── values.yaml
├── files/
│   ├── redisParametersDetail.json
│   ├── redisTemplate.tpl
│   └── redisValue.yaml
└── templates/
    ├── _helpers.tpl
    ├── configTemplate.yaml
    ├── configValue.yaml
    ├── parametersDetail.yaml
    └── podtemplate.yaml
```

## UPM Integration

### Required CRDs
- Unit: Defines individual Redis instances
- UnitSets: Manages groups of Redis units for scaling and HA

### Usage with UPM
1. Install package to register Redis templates
2. Create Unit CRDs referencing this package
3. Optionally create UnitSet CRDs for HA/replication
4. Configure parameters via UPM specifications

## Key Templates

### Pod Template
- Redis container with liveness/readiness probes
- Unit Agent sidecar (management API on 2214)
- Init containers for environment setup

### Configuration System
1. Parameter Definitions (`redisParametersDetail.json`)
2. Parameter Values (`redisValue.yaml`)
3. Configuration Template (`redisTemplate.tpl`)
4. Generated runtime config

## Package Metadata

```yaml
apiVersion: v2
appVersion: 7.0.14
name: redis-7.0.14
version: 1.0.0
description: Redis software packages, including configuration templates and pod templates.
keywords:
  - redis
  - database
  - key-value
  - cache
  - in-memory
```

## Installation

```bash
helm repo add upm-packages https://upmio.github.io/upm-packages
helm repo update

helm install --namespace=upm-system upm-packages-redis-7.0.14 \
  upm-packages/redis-7.0.14

helm status upm-packages-redis-7.0.14 --namespace=upm-system
```

## Next Steps

1. Create Unit CRDs for Redis instances
2. Create UnitSet CRDs for managing multiple instances
3. Configure parameters in UPM specs
4. Monitor deployment via UPM control plane

## Configuration Files

- `redisParametersDetail.json`: Bilingual parameter metadata and validation
- `redisTemplate.tpl`: Go template for dynamic config generation
- `redisValue.yaml`: Production-optimized defaults

## Template Integration

- ConfigMaps store templates and parameter definitions
- PodTemplate defines pod structure for Redis instances
- Helper templates standardize image references

---

<div align="center">

**📚 For more about UPM, see project documentation**

</div>
