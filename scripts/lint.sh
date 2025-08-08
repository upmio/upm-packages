#!/bin/bash

# UPM Packages Lint Script
# This script runs various linting tools for the UPM Packages project

set -euo pipefail

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

  if eval "$lint_command" >/dev/null 2>&1; then
    lint_passed "$lint_name"
    return 0
  else
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

  # Install yq
  if ! command -v yq >/dev/null 2>&1; then
    log_info "Installing yq..."
    sudo wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
  fi

  log_success "Dependencies installed successfully"
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
    if run_lint "Shell script: $script" "shellcheck \"$script\""; then
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
  yaml_files=$(find . -name "*.yaml" -o -name "*.yml" -type f | grep -v ".git")

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
    if run_lint "YAML file: $yaml_file" "yamllint \"$yaml_file\""; then
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
    # Try hadolint first
    if command -v hadolint >/dev/null 2>&1; then
      if run_lint "Dockerfile (hadolint): $dockerfile" "hadolint \"$dockerfile\""; then
        continue
      else
        dockerfile_failed=1
      fi
    else
      # Fallback to basic Docker build check
      if run_lint "Dockerfile (build test): $dockerfile" "docker build --no-cache --dry-run -f \"$dockerfile\" ."; then
        continue
      else
        dockerfile_failed=1
      fi
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
  for chart_dir in $chart_dirs; do
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
      lint_passed "Shell script executable: $script"
    else
      lint_failed "Shell script not executable: $script"
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
    local component
    component=$(echo "$chart_dir" | awk -F'/' '{print $(NF-1)}')
    local chart_name
    chart_name=$(grep "^name:" "$chart_file" | sed 's/name: //')
    local expected_name
    expected_name=${component//-/_}

    if [ "$chart_name" = "$expected_name" ]; then
      lint_passed "Chart naming convention: $chart_file"
    else
      lint_failed "Chart naming convention: $chart_file (expected: $expected_name, got: $chart_name)"
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
    if head -n1 "$script" | grep -q "^#!/bin/bash"; then
      lint_passed "Shell script shebang: $script"
    else
      lint_failed "Shell script shebang: $script"
      style_failed=1
    fi
  done

  # Check for proper error handling in shell scripts
  for script in $shell_scripts; do
    if grep -q "set -euo pipefail" "$script"; then
      lint_passed "Shell script error handling: $script"
    else
      lint_failed "Shell script error handling: $script"
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
      lint_passed "Documentation exists: $dir"
    else
      log_warning "Documentation missing: $dir"
    fi
  done

  return $doc_failed
}

# Run all lints
run_all_lints() {
  log_info "Running all lints..."

  lint_file_permissions
  lint_file_naming
  lint_code_style
  lint_documentation
  lint_shell_scripts
  lint_yaml_files
  lint_json_files
  lint_dockerfiles
  lint_helm_charts
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

  run_all_lints
  print_summary
  exit $?
}

# Run main function
main "$@"
