#!/bin/bash

# Template Functions Test Script
# Tests for the custom Go template functions used in UPM Packages

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

# Test template function availability
test_template_functions() {
    log_info "Testing template function availability..."
    
    # Find template files
    local template_files
    template_files=$(find . -name "*.tpl" -type f | grep -v ".git")
    
    if [ -z "$template_files" ]; then
        log_warning "No template files found"
        return 0
    fi
    
    local functions=("getenv" "getv" "add" "mul" "atoi")
    local function_failed=0
    
    for func in "${functions[@]}"; do
        local found=false
        for template in $template_files; do
            if grep -q "{{.*$func" "$template"; then
                found=true
                break
            fi
        done
        
        if [ "$found" = true ]; then
            test_passed "Template function found: $func"
        else
            test_failed "Template function not found: $func"
            function_failed=1
        fi
    done
    
    return $function_failed
}

# Test template syntax
test_template_syntax() {
    log_info "Testing template syntax..."
    
    # Find template files
    local template_files
    template_files=$(find . -name "*.tpl" -type f | grep -v ".git")
    
    if [ -z "$template_files" ]; then
        log_warning "No template files found"
        return 0
    fi
    
    local syntax_failed=0
    
    for template in $template_files; do
        # Check for basic template syntax errors
        if run_test "Template syntax: $template" "grep -q '{{.*}}' \"$template\""; then
            continue
        else
            syntax_failed=1
        fi
        
        # Check for unmatched braces
        if run_test "Template braces balance: $template" "
            open_braces=\$(grep -o '{{' \"$template\" | wc -l)
            close_braces=\$(grep -o '}}' \"$template\" | wc -l)
            [ \"\$open_braces\" = \"\$close_braces\" ]
        "; then
            continue
        else
            syntax_failed=1
        fi
    done
    
    return $syntax_failed
}

# Test parameter files
test_parameter_files() {
    log_info "Testing parameter files..."
    
    # Find parameter files
    local param_files
    param_files=$(find . -name "*ParametersDetail.json" -type f | grep -v ".git")
    
    if [ -z "$param_files" ]; then
        log_warning "No parameter files found"
        return 0
    fi
    
    local param_failed=0
    
    for param_file in $param_files; do
        # Check JSON syntax
        if run_test "Parameter file JSON: $param_file" "python3 -m json.tool \"$param_file\" >/dev/null"; then
            continue
        else
            param_failed=1
        fi
        
        # Check required fields
        if run_test "Parameter file fields: $param_file" "
            python3 -c \"
import json
with open('$param_file', 'r') as f:
    data = json.load(f)
for item in data:
    required_fields = ['key', 'scope', 'section', 'type', 'dynamic', 'range', 'default', 'desc_en', 'desc_zh']
    for field in required_fields:
        if field not in item:
            raise Exception(f'Missing field: {field}')
            \"
        "; then
            continue
        else
            param_failed=1
        fi
    done
    
    return $param_failed
}

# Test template function usage
test_template_function_usage() {
    log_info "Testing template function usage..."
    
    # Find template files
    local template_files
    template_files=$(find . -name "*.tpl" -type f | grep -v ".git")
    
    if [ -z "$template_files" ]; then
        log_warning "No template files found"
        return 0
    fi
    
    local usage_failed=0
    
    for template in $template_files; do
        # Test getenv function usage
        if grep -q "getenv" "$template"; then
            if run_test "getenv function usage: $template" "
                grep -o 'getenv \"[^\"]*\"' \"$template\" | while read -r line; do
                    var_name=\$(echo \"\$line\" | sed 's/getenv \"\\([^\"]*\\)\"/\\1/')
                    if [ -z \"\$var_name\" ]; then
                        exit 1
                    fi
                done
            "; then
                continue
            else
                usage_failed=1
            fi
        fi
        
        # Test getv function usage
        if grep -q "getv" "$template"; then
            if run_test "getv function usage: $template" "
                grep -o 'getv \"[^\"]*\"' \"$template\" | while read -r line; do
                    var_name=\$(echo \"\$line\" | sed 's/getv \"\\([^\"]*\\)\"/\\1/')
                    if [ -z \"\$var_name\" ]; then
                        exit 1
                    fi
                done
            "; then
                continue
            else
                usage_failed=1
            fi
        fi
    done
    
    return $usage_failed
}

# Test template variable consistency
test_template_variables() {
    log_info "Testing template variable consistency..."
    
    # Find template files
    local template_files
    template_files=$(find . -name "*.tpl" -type f | grep -v ".git")
    
    if [ -z "$template_files" ]; then
        log_warning "No template files found"
        return 0
    fi
    
    local consistency_failed=0
    
    # Check for common environment variables
    local common_vars=("POD_NAME" "NAMESPACE" "SERVICE_NAME" "UNIT_SN" "DATA_MOUNT" "LOG_MOUNT")
    
    for var in "${common_vars[@]}"; do
        local found=false
        for template in $template_files; do
            if grep -q "$var" "$template"; then
                found=true
                break
            fi
        done
        
        if [ "$found" = true ]; then
            test_passed "Common variable found: $var"
        else
            log_warning "Common variable not found: $var"
        fi
    done
    
    return $consistency_failed
}

# Test template file structure
test_template_structure() {
    log_info "Testing template file structure..."
    
    # Find template directories
    local template_dirs
    template_dirs=$(find . -name "files" -type d | grep -v ".git")
    
    if [ -z "$template_dirs" ]; then
        log_warning "No template directories found"
        return 0
    fi
    
    local structure_failed=0
    
    for template_dir in $template_dirs; do
        # Check if directory contains .tpl files
        local tpl_count
        tpl_count=$(find "$template_dir" -name "*.tpl" -type f | wc -l)
        if [ "$tpl_count" -gt 0 ]; then
            test_passed "Template files found in: $template_dir"
        else
            test_failed "No template files in: $template_dir"
            structure_failed=1
        fi
        
        # Check for corresponding parameter files
        local param_count
        param_count=$(find "$template_dir" -name "*ParametersDetail.json" -type f | wc -l)
        if [ "$param_count" -gt 0 ]; then
            test_passed "Parameter files found in: $template_dir"
        else
            log_warning "No parameter files in: $template_dir"
        fi
    done
    
    return $structure_failed
}

# Run all tests
run_all_tests() {
    log_info "Running all template function tests..."
    
    test_template_functions
    test_template_syntax
    test_parameter_files
    test_template_function_usage
    test_template_variables
    test_template_structure
}

# Print test summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "    Template Functions Test Summary"
    echo "=========================================="
    echo "Total tests:  $TOTAL_TESTS"
    echo "Passed:       $PASSED_TESTS"
    echo "Failed:       $FAILED_TESTS"
    echo "=========================================="
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All template tests passed!${NC}"
        return 0
    else
        echo -e "${RED}$FAILED_TESTS template test(s) failed!${NC}"
        return 1
    fi
}

# Main script logic
main() {
    echo "UPM Packages Template Functions Test Suite"
    echo "========================================="
    
    run_all_tests
    print_summary
    exit $?
}

# Run main function
main "$@"