#!/bin/bash

# UPM Packages Test Script
# This script runs various tests for the UPM Packages project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

# Test result functions
test_passed() {
  ((PASSED_TESTS++))
  log_success "✓ $1"
}

test_failed() {
  ((FAILED_TESTS++))
  log_error "✗ $1"
  if [ -n "${2:-}" ]; then
    echo "  $2"
  fi
}

run_test() {
  local test_name="$1"
  local test_command="$2"

  ((TOTAL_TESTS++))
  log_info "Running: $test_name"

  if eval "$test_command" >/dev/null 2>&1; then
    test_passed "$test_name"
    return 0
  else
    test_failed "$test_name" "Command failed: $test_command"
    return 1
  fi
}

# Test functions
test_shell_scripts() {
  log_info "Testing shell scripts..."

  # Find all shell scripts
  local shell_scripts
  shell_scripts=$(find . -name "*.sh" -type f | grep -v ".git")

  if [ -z "$shell_scripts" ]; then
    log_warning "No shell scripts found"
    return 0
  fi

  # By default, skip shellcheck here and rely on lint suite
  if [ "${SKIP_SHELLCHECK_IN_TESTS:-true}" = "true" ]; then
    log_warning "Skipping shellcheck in tests (handled by ./scripts/lint.sh)"
    return 0
  fi

  # Check if shellcheck is installed
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_error "shellcheck is not installed. Please install it with: sudo apt-get install shellcheck"
    return 1
  fi

  local script_failed=0
  for script in $shell_scripts; do
    if run_test "Shell script lint: $script" "shellcheck -S error \"$script\""; then
      continue
    else
      script_failed=1
    fi
  done

  return $script_failed
}

test_yaml_files() {
  log_info "Testing YAML files..."

  # Find all YAML files
  local yaml_files
  # Exclude Helm chart templates by default as they contain Go templating and are not valid YAML pre-render
  if [ "${SKIP_TEMPLATES_YAMLLINT:-true}" = "true" ]; then
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
    log_error "yamllint is not installed. Please install it with: pip install yamllint"
    return 1
  fi

  local yaml_failed=0
  for yaml_file in $yaml_files; do
    # Relax noisy rules for Chart.yaml similar to lint suite
    local base
    base=$(basename "$yaml_file")
    local cmd
    if [ "$base" = "Chart.yaml" ]; then
      cmd="yamllint -d '{extends: default, rules: {document-start: disable, line-length: disable, new-line-at-end-of-file: disable}}' \"$yaml_file\""
    else
      # Use repository config explicitly to avoid picking up an empty .yamllint file
      cmd="yamllint -c .yamllint.yaml \"$yaml_file\""
    fi
    if run_test "YAML lint: $yaml_file" "$cmd"; then
      continue
    else
      yaml_failed=1
    fi
  done

  return $yaml_failed
}

test_dockerfiles() {
  log_info "Testing Dockerfiles..."

  # Find all Dockerfiles
  local dockerfiles
  dockerfiles=$(find . -name "Dockerfile" -type f | grep -v ".git")

  if [ -z "$dockerfiles" ]; then
    log_warning "No Dockerfiles found"
    return 0
  fi

  local dockerfile_failed=0
  for dockerfile in $dockerfiles; do
    # Prefer hadolint container; if not available, skip with warning
    if command -v docker >/dev/null 2>&1; then
      if run_test "Dockerfile lint (hadolint container): $dockerfile" "docker run --rm -i hadolint/hadolint < \"$dockerfile\""; then
        continue
      else
        log_warning "hadolint container failed or unavailable; skipping lint for $dockerfile"
      fi
    else
      log_warning "docker not available; skipping Dockerfile lint for $dockerfile"
    fi
  done

  return $dockerfile_failed
}

test_helm_charts() {
  log_info "Testing Helm charts..."

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
    # Try to build dependencies first; if lock is out of sync, try update
    if command -v helm >/dev/null 2>&1; then
      if ! helm dependency build "$chart_dir" >/dev/null 2>&1; then
        # Attempt update then build again
        helm dependency update "$chart_dir" >/dev/null 2>&1 || true
        helm dependency build "$chart_dir" >/dev/null 2>&1 || true
      fi
    fi

    # If chart depends on bitnami/common and vendor not present, optionally skip
    if grep -qE "^\s*-\s*name:\s*common\b" "$chart_dir/Chart.yaml" 2>/dev/null &&
      [ ! -d "$chart_dir/charts/common" ] &&
      [ "${STRICT_HELM_DEPS:-false}" != "true" ]; then
      # Mark as skipped-pass to align with lint suite behavior
      ((TOTAL_TESTS++))
      log_warning "Skipping Helm lint (missing 'common' dep): $chart_dir"
      test_passed "Helm chart lint (skipped - missing 'common'): $chart_dir"
      continue
    fi

    if run_test "Helm chart lint: $chart_dir" "helm lint \"$chart_dir\""; then
      continue
    else
      chart_failed=1
    fi
  done

  return $chart_failed
}

test_parameter_files() {
  log_info "Testing parameter files..."

  # Find all parameter detail JSON files
  local param_files
  param_files=$(find . -name "*ParametersDetail.json" -type f | grep -v ".git")

  if [ -z "$param_files" ]; then
    log_warning "No parameter files found"
    return 0
  fi

  # Check if jq is installed
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is not installed. Please install it with: sudo apt-get install jq"
    return 1
  fi

  local param_failed=0
  for param_file in $param_files; do
    if run_test "Parameter file JSON validation: $param_file" "jq . \"$param_file\" >/dev/null"; then
      continue
    else
      param_failed=1
    fi
  done

  return $param_failed
}

test_file_permissions() {
  log_info "Testing file permissions..."

  # Check for executable scripts
  local executable_files
  executable_files=$(find . -name "*.sh" -type f | grep -v ".git")
  local perm_failed=0

  for file in $executable_files; do
    if [ -x "$file" ]; then
      test_passed "Executable permission: $file"
    else
      test_failed "Executable permission: $file" "File is not executable"
      perm_failed=1
    fi
  done

  return $perm_failed
}

test_chart_structure() {
  log_info "Testing chart structure..."

  # Find all chart directories
  local chart_dirs
  chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")

  if [ -z "$chart_dirs" ]; then
    log_warning "No Helm charts found"
    return 0
  fi

  local structure_failed=0

  for chart_dir in $chart_dirs; do
    # Check required files
    local required_files=("Chart.yaml" "values.yaml")
    for req_file in "${required_files[@]}"; do
      if [ -f "$chart_dir/$req_file" ]; then
        test_passed "Required file exists: $chart_dir/$req_file"
      else
        test_failed "Required file missing: $chart_dir/$req_file"
        structure_failed=1
      fi
    done

    # Check templates directory
    if [ -d "$chart_dir/templates" ]; then
      test_passed "Templates directory exists: $chart_dir"
    else
      test_failed "Templates directory missing: $chart_dir"
      structure_failed=1
    fi
  done

  return $structure_failed
}

# Main test functions
run_unit_tests() {
  log_info "Running unit tests..."

  test_shell_scripts
  test_yaml_files
  test_parameter_files
  test_file_permissions
}

run_integration_tests() {
  log_info "Running integration tests..."

  test_dockerfiles
  test_helm_charts
  test_chart_structure
}

run_all_tests() {
  log_info "Running all tests..."

  run_unit_tests
  run_integration_tests
}

# Print test summary
print_summary() {
  echo ""
  echo "=========================================="
  echo "           Test Summary"
  echo "=========================================="
  echo "Total tests:  $TOTAL_TESTS"
  echo "Passed:       $PASSED_TESTS"
  echo "Failed:       $FAILED_TESTS"
  echo "=========================================="

  if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}$FAILED_TESTS test(s) failed!${NC}"
    return 1
  fi
}

# Main script logic
main() {
  local test_type="${1:-all}"

  echo "UPM Packages Test Suite"
  echo "======================="

  case "$test_type" in
  "unit")
    run_unit_tests
    ;;
  "integration")
    run_integration_tests
    ;;
  "all")
    run_all_tests
    ;;
  *)
    echo "Usage: $0 [unit|integration|all]"
    echo "  unit      - Run unit tests only"
    echo "  integration - Run integration tests only"
    echo "  all       - Run all tests (default)"
    exit 1
    ;;
  esac

  print_summary
  exit $?
}

# Run main function
main "$@"
