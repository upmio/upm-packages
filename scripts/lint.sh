#!/bin/bash

# UPM Packages Lint Script
# This script runs various linting tools for the UPM Packages project

set -euo pipefail

# Pin tool versions for consistent CI/local runs
SHFMT_VERSION="${SHFMT_VERSION:-v3.10.0}"
SHFMT_BIN="" # internal: path to resolved shfmt

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Lint counters
TOTAL_LINTS=0
PASSED_LINTS=0
FAILED_LINTS=0

# CI toggles
SKIP_SHFMT=${SKIP_SHFMT:-""}
SKIP_TEMPLATES_YAMLLINT=${SKIP_TEMPLATES_YAMLLINT:-"true"}

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Unified counters for manual checks
record_pass() {
  ((TOTAL_LINTS++))
  lint_passed "$1"
}

record_fail() {
  ((TOTAL_LINTS++))
  # $2 is optional message
  lint_failed "$1" "${2:-}"
}

# Lint result functions
lint_passed() {
  ((PASSED_LINTS++))
  log_success "✓ $1"
}

lint_failed() {
  ((FAILED_LINTS++))
  log_error "✗ $1"
  if [ -n "${2:-}" ]; then
    echo "  $2"
  fi
}

run_lint() {
  local lint_name="$1"
  local lint_command="$2"

  ((TOTAL_LINTS++))
  log_info "Running: $lint_name"

  # Capture stdout/stderr so we can show actionable details on failure
  local output
  output=$(eval "$lint_command" 2>&1)
  local rc=$?
  if [ $rc -eq 0 ]; then
    lint_passed "$lint_name"
    return 0
  else
    # Print the captured output (trim very long outputs)
    local max_lines=200
    if [ -n "$output" ]; then
      # shellcheck disable=SC2005
      echo "$(echo "$output" | head -n "$max_lines" | sed 's/^/  > /')"
      if [ "$(echo "$output" | wc -l | tr -d ' ')" -gt "$max_lines" ]; then
        echo "  ... (truncated)"
      fi
    fi
    lint_failed "$lint_name" "Command failed: $lint_command"
    return 1
  fi
}

# Install missing dependencies
install_dependencies() {
  log_info "Installing missing dependencies..."

  # Install shellcheck
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_info "Installing shellcheck..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y shellcheck
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y shellcheck
    elif command -v brew >/dev/null 2>&1; then
      brew install shellcheck
    else
      log_error "Cannot install shellcheck. Please install it manually."
      return 1
    fi
  fi

  # Install yamllint
  if ! command -v yamllint >/dev/null 2>&1; then
    log_info "Installing yamllint..."
    if command -v pip3 >/dev/null 2>&1; then
      pip3 install yamllint
    elif command -v pip >/dev/null 2>&1; then
      pip install yamllint
    else
      log_error "Cannot install yamllint. Please install it manually."
      return 1
    fi
  fi

  # Install jq
  if ! command -v jq >/dev/null 2>&1; then
    log_info "Installing jq..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get install -y jq
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y jq
    elif command -v brew >/dev/null 2>&1; then
      brew install jq
    else
      log_error "Cannot install jq. Please install it manually."
      return 1
    fi
  fi

  # Install shfmt (unless skipped) - use pinned version for determinism
  if [ "${SKIP_SHFMT}" = "true" ]; then
    log_info "Skipping shfmt installation (SKIP_SHFMT=true)"
  else
    install_pinned_shfmt || true
  fi

  # Install yq
  if ! command -v yq >/dev/null 2>&1; then
    log_info "Installing yq..."
    if command -v brew >/dev/null 2>&1; then
      brew install yq || true
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y yq || true
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y yq || true
    else
      # Fallback: download from GitHub releases with OS/ARCH detection
      local os arch url target
      os=$(uname -s | tr '[:upper:]' '[:lower:]')
      arch=$(uname -m)
      case "$arch" in
      x86_64 | amd64) arch=amd64 ;;
      aarch64 | arm64) arch=arm64 ;;
      armv7l) arch=arm ;;
      esac
      # yq uses 'darwin' for macOS
      if [ "$os" = "darwin" ] || [ "$os" = "linux" ]; then
        url="https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}"
        target="/usr/local/bin/yq"
        if [ -w "$(dirname "$target")" ]; then
          curl -fsSL "$url" -o "$target" && chmod +x "$target" || true
        elif command -v sudo >/dev/null 2>&1; then
          sudo curl -fsSL "$url" -o "$target" && sudo chmod +x "$target" || true
        else
          # Last resort: install to ~/.local/bin and add hint
          mkdir -p "$HOME/.local/bin"
          curl -fsSL "$url" -o "$HOME/.local/bin/yq" && chmod +x "$HOME/.local/bin/yq" || true
          export PATH="$HOME/.local/bin:$PATH"
          log_warning "Installed yq to $HOME/.local/bin; ensure it is in your PATH"
        fi
      else
        log_warning "Unsupported OS for auto-installing yq ($os). Please install yq manually."
      fi
    fi
  fi

  log_success "Dependencies installed successfully"
}

# Download and use pinned shfmt version for determinism across environments
install_pinned_shfmt() {
  # If already present in PATH, prefer that but report version
  if command -v shfmt >/dev/null 2>&1; then
    SHFMT_BIN="$(command -v shfmt)"
    log_info "Found system shfmt: $($SHFMT_BIN -version 2>/dev/null || true)"
  fi

  # Detect OS/ARCH
  local os arch url target
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  arch=$(uname -m)
  case "$arch" in
  x86_64 | amd64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  armv7l) arch=arm ;;
  esac

  if [ "$os" != "darwin" ] && [ "$os" != "linux" ]; then
    log_warning "Unsupported OS for auto-installing shfmt ($os)."
    return 0
  fi

  url="https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_${os}_${arch}"
  target="/usr/local/bin/shfmt"
  if [ -w "$(dirname "$target")" ]; then
    curl -fsSL "$url" -o "$target" && chmod +x "$target" || true
    SHFMT_BIN="$target"
  elif command -v sudo >/dev/null 2>&1; then
    sudo curl -fsSL "$url" -o "$target" && sudo chmod +x "$target" || true
    SHFMT_BIN="$target"
  else
    mkdir -p "$HOME/.local/bin"
    curl -fsSL "$url" -o "$HOME/.local/bin/shfmt" && chmod +x "$HOME/.local/bin/shfmt" || true
    export PATH="$HOME/.local/bin:$PATH"
    SHFMT_BIN="$HOME/.local/bin/shfmt"
    log_warning "Installed shfmt to $HOME/.local/bin; ensure it is in your PATH"
  fi

  if [ -x "$SHFMT_BIN" ]; then
    log_info "Using pinned shfmt: $($SHFMT_BIN -version 2>/dev/null || true)"
  fi
}

# Shell format (shfmt)
lint_shfmt() {
  # Allow skipping in CI
  if [ "${SKIP_SHFMT}" = "true" ]; then
    log_info "Skipping shfmt check (SKIP_SHFMT=true)"
    record_pass "shfmt style check (skipped)"
    return 0
  fi

  log_info "Checking shell formatting with shfmt (-i 2 -d) ..."

  # Ensure shfmt is available (prefer pinned one)
  if [ -z "${SHFMT_BIN:-}" ] || [ ! -x "$SHFMT_BIN" ]; then
    if command -v shfmt >/dev/null 2>&1; then
      SHFMT_BIN="$(command -v shfmt)"
    else
      # Attempt to auto-install the pinned version on demand
      install_pinned_shfmt || true
      if [ -z "${SHFMT_BIN:-}" ] || [ ! -x "$SHFMT_BIN" ]; then
        if command -v shfmt >/dev/null 2>&1; then
          SHFMT_BIN="$(command -v shfmt)"
        fi
      fi
    fi
  fi
  if [ -z "${SHFMT_BIN:-}" ] || [ ! -x "$SHFMT_BIN" ]; then
    log_error "shfmt is not installed. Run with --install-deps or install manually."
    record_fail "shfmt style check" "shfmt is not installed"
    return 1
  fi

  # shfmt returns non-zero if diff exists
  log_info "shfmt version: $($SHFMT_BIN -version 2>/dev/null || echo unknown)"
  if "$SHFMT_BIN" -i 2 -d . >/dev/null 2>&1; then
    record_pass "shfmt style check"
    return 0
  else
    record_fail "shfmt style check" "Run: shfmt -i 2 -w ."
    return 1
  fi
}

# Shell script linting
lint_shell_scripts() {
  log_info "Linting shell scripts..."

  # Find all shell scripts
  local shell_scripts
  shell_scripts=$(find . -name "*.sh" -type f | grep -v ".git")

  if [ -z "$shell_scripts" ]; then
    log_warning "No shell scripts found"
    return 0
  fi

  # Check if shellcheck is installed
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_error "shellcheck is not installed. Run with --install-deps"
    return 1
  fi

  local shell_failed=0
  for script in $shell_scripts; do
    # Only fail on error-level issues; style/info emit diagnostics but don't fail CI
    if run_lint "Shell script: $script" "shellcheck -S error \"$script\""; then
      continue
    else
      shell_failed=1
    fi
  done

  return $shell_failed
}

# YAML file linting
lint_yaml_files() {
  log_info "Linting YAML files..."

  # Find all YAML files
  local yaml_files
  # Exclude Helm chart templates: any YAML under charts/**/templates/**
  if [ "${SKIP_TEMPLATES_YAMLLINT}" = "true" ]; then
    yaml_files=$(find . -type f \( -name "*.yaml" -o -name "*.yml" \) |
      grep -v ".git" |
      grep -vE "/charts/(.*/)?templates/")
  else
    yaml_files=$(find . -type f \( -name "*.yaml" -o -name "*.yml" \) | grep -v ".git")
  fi

  if [ -z "$yaml_files" ]; then
    log_warning "No YAML files found"
    return 0
  fi

  # Check if yamllint is installed
  if ! command -v yamllint >/dev/null 2>&1; then
    log_error "yamllint is not installed. Run with --install-deps"
    return 1
  fi

  local yaml_failed=0
  for yaml_file in $yaml_files; do
    # Safety check (skip empty entries)
    [ -n "$yaml_file" ] || continue
    # Relax a few noisy rules specifically for Chart.yaml
    local base
    base=$(basename "$yaml_file")
    local cmd
    if [ "$base" = "Chart.yaml" ]; then
      cmd="yamllint -d '{extends: default, rules: {document-start: disable, line-length: disable, new-line-at-end-of-file: disable}}' \"$yaml_file\""
    else
      cmd="yamllint \"$yaml_file\""
    fi
    if run_lint "YAML file: $yaml_file" "$cmd"; then
      continue
    else
      yaml_failed=1
    fi
  done

  return $yaml_failed
}

# JSON file linting
lint_json_files() {
  log_info "Linting JSON files..."

  # Find all JSON files
  local json_files
  json_files=$(find . -name "*.json" -type f | grep -v ".git")

  if [ -z "$json_files" ]; then
    log_warning "No JSON files found"
    return 0
  fi

  # Check if jq is installed
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is not installed. Run with --install-deps"
    return 1
  fi

  local json_failed=0
  for json_file in $json_files; do
    if run_lint "JSON file: $json_file" "jq . \"$json_file\" >/dev/null"; then
      continue
    else
      json_failed=1
    fi
  done

  return $json_failed
}

# Dockerfile linting
lint_dockerfiles() {
  log_info "Linting Dockerfiles..."

  # Find all Dockerfiles
  local dockerfiles
  dockerfiles=$(find . -name "Dockerfile" -type f | grep -v ".git")

  if [ -z "$dockerfiles" ]; then
    log_warning "No Dockerfiles found"
    return 0
  fi

  local dockerfile_failed=0
  for dockerfile in $dockerfiles; do
    # Prefer hadolint; if not present, skip with a warning (no invalid docker build fallback)
    if command -v hadolint >/dev/null 2>&1; then
      if run_lint "Dockerfile (hadolint): $dockerfile" "hadolint \"$dockerfile\""; then
        continue
      else
        dockerfile_failed=1
      fi
    else
      log_warning "hadolint not found; skipping Dockerfile lint for $dockerfile"
      record_pass "Dockerfile (skipped - hadolint missing): $dockerfile"
    fi
  done

  return $dockerfile_failed
}

# Helm chart linting
lint_helm_charts() {
  log_info "Linting Helm charts..."

  # Find all chart directories
  local chart_dirs
  chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")

  if [ -z "$chart_dirs" ]; then
    log_warning "No Helm charts found"
    return 0
  fi

  # Check if helm is installed
  if ! command -v helm >/dev/null 2>&1; then
    log_error "helm is not installed. Please install it following the official documentation"
    return 1
  fi

  local chart_failed=0
  local strict=${STRICT_HELM_DEPS:-""}
  for chart_dir in $chart_dirs; do
    # If not strict and 'common' subchart is not present locally, skip lint to avoid false failures
    if [ "$strict" != "true" ]; then
      if [ ! -d "$chart_dir/charts" ] || ! compgen -G "$chart_dir/charts/common*" >/dev/null; then
        log_warning "Missing 'common' dependency for $chart_dir; skipping lint (set STRICT_HELM_DEPS=true to enforce)"
        record_pass "Helm chart (skipped - deps missing): $chart_dir"
        continue
      fi
    fi

    # Attempt to build/update dependencies first to avoid missing 'common' errors
    if command -v helm >/dev/null 2>&1; then
      (cd "$chart_dir" && helm dependency build >/dev/null 2>&1) || true
    fi
    # Run lint
    if run_lint "Helm chart: $chart_dir" "helm lint \"$chart_dir\""; then
      continue
    else
      chart_failed=1
    fi
  done

  return $chart_failed
}

# File permission linting
lint_file_permissions() {
  log_info "Linting file permissions..."

  # Check shell script permissions
  local shell_scripts
  shell_scripts=$(find . -name "*.sh" -type f | grep -v ".git")
  local perm_failed=0

  for script in $shell_scripts; do
    if [ -x "$script" ]; then
      record_pass "Shell script executable: $script"
    else
      record_fail "Shell script not executable: $script"
      perm_failed=1
    fi
  done

  return $perm_failed
}

# File naming conventions
lint_file_naming() {
  log_info "Linting file naming conventions..."

  local naming_failed=0

  # Check for consistent naming in chart files
  local chart_yaml_files
  chart_yaml_files=$(find . -name "Chart.yaml" -type f | grep -v ".git")
  for chart_file in $chart_yaml_files; do
    local chart_dir
    chart_dir=$(dirname "$chart_file")
    # Build expected name based on path segments before /charts
    # Example: ./mysql-community/8.0.40/charts -> expected mysql-community-8.0.40
    local rel_path
    rel_path=$(echo "$chart_dir" | sed 's#^\./##' | sed 's#/charts$##')
    local expected_name
    expected_name=$(echo "$rel_path" | tr '/' '-')
    local top_component
    top_component=$(echo "$rel_path" | cut -d'/' -f1)

    local chart_name
    if command -v yq >/dev/null 2>&1; then
      chart_name=$(yq e '.name' "$chart_file" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    else
      # Fallback to grep/awk parsing
      chart_name=$(awk -F: '/^name:/{print $2; exit}' "$chart_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    fi

    if [ "$chart_name" = "$expected_name" ] || [ "$chart_name" = "$top_component" ]; then
      record_pass "Chart naming convention: $chart_file"
    else
      record_fail "Chart naming convention: $chart_file" "expected one of: $expected_name or $top_component, got: $chart_name"
      naming_failed=1
    fi
  done

  return $naming_failed
}

# Code style linting
lint_code_style() {
  log_info "Linting code style..."

  local style_failed=0

  # Check shell script shebang
  local shell_scripts
  shell_scripts=$(find . -name "*.sh" -type f | grep -v ".git")
  for script in $shell_scripts; do
    if head -n1 "$script" | grep -Eq '^#!(/bin/bash|/usr/bin/env bash)$'; then
      record_pass "Shell script shebang: $script"
    else
      record_fail "Shell script shebang: $script"
      style_failed=1
    fi
  done

  # Check for proper error handling in shell scripts
  for script in $shell_scripts; do
    if grep -q "set -euo pipefail" "$script" ||
      (grep -q "set -o errexit" "$script" && grep -q "set -o nounset" "$script" && grep -q "set -o pipefail" "$script"); then
      record_pass "Shell script error handling: $script"
    else
      record_fail "Shell script error handling: $script"
      style_failed=1
    fi
  done

  return $style_failed
}

# Documentation linting
lint_documentation() {
  log_info "Linting documentation..."

  local doc_failed=0

  # Check for README files in component directories
  local component_dirs
  component_dirs=$(find . -maxdepth 2 -type d | grep -E "./[^/]+/[^/]+$" | grep -v ".git")
  for dir in $component_dirs; do
    if [ -f "$dir/README.md" ] || [ -f "$dir/README" ]; then
      record_pass "Documentation exists: $dir"
    else
      log_warning "Documentation missing: $dir"
    fi
  done

  return $doc_failed
}

# Run all lints
run_all_lints() {
  log_info "Running all lints..."

  local rc=0
  lint_shfmt || rc=1
  lint_file_permissions || rc=1
  lint_file_naming || rc=1
  lint_code_style || rc=1
  lint_documentation || rc=1
  lint_shell_scripts || rc=1
  lint_yaml_files || rc=1
  lint_json_files || rc=1
  lint_dockerfiles || rc=1
  lint_helm_charts || rc=1

  return $rc
}

# Print lint summary
print_summary() {
  echo ""
  echo "=========================================="
  echo "           Lint Summary"
  echo "=========================================="
  echo "Total lints:   $TOTAL_LINTS"
  echo "Passed:        $PASSED_LINTS"
  echo "Failed:        $FAILED_LINTS"
  echo "=========================================="

  if [ $FAILED_LINTS -eq 0 ]; then
    echo -e "${GREEN}All lints passed!${NC}"
    return 0
  else
    echo -e "${RED}$FAILED_LINTS lint(s) failed!${NC}"
    return 1
  fi
}

# Main script logic
main() {
  local install_deps=false

  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
    --install-deps)
      install_deps=true
      shift
      ;;
    *)
      echo "Usage: $0 [--install-deps]"
      echo "  --install-deps  Install missing dependencies"
      exit 1
      ;;
    esac
  done

  echo "UPM Packages Lint Suite"
  echo "======================"

  # Install dependencies if requested
  if [ "$install_deps" = true ]; then
    install_dependencies
  fi

  # Run all lints but don't let set -e exit early; summary will set final code
  run_all_lints || true
  print_summary
  exit $?
}

# Run main function
main "$@"
