#!/usr/bin/env bash
# Regression checks for MongoDB's metrics image helper and PodTemplate YAML.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chart="${repo_root}/mongodb/8.0.15/charts"
audit_dir="$(mktemp -d)"
trap 'rm -rf "${audit_dir}"' EXIT

helm lint "${chart}"
helm template audit "${chart}" >"${audit_dir}/default.yaml"
grep -Fq 'image: quay.io/upmio/mongodb-exporter:0.47.2' "${audit_dir}/default.yaml"
grep -Fq 'kind: PodTemplate' "${audit_dir}/default.yaml"

helm template audit "${chart}" --set global.imageRegistry=mirror.example.test \
  --set metrics.image.tag=regression >"${audit_dir}/mirror.yaml"
grep -Fq 'image: mirror.example.test/upmio/mongodb-exporter:regression' "${audit_dir}/mirror.yaml"

digest="sha256:$(printf '%064d' 0)"
helm template audit "${chart}" --set "metrics.image.digest=${digest}" >"${audit_dir}/digest.yaml"
grep -Fq "image: quay.io/upmio/mongodb-exporter@${digest}" "${audit_dir}/digest.yaml"
printf 'MongoDB Chart default, mirror, and digest rendering passed.\n'
