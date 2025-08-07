#!/bin/bash

# UPM Packages Chart Validation Script
# This script validates all Helm charts in the project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation counters
TOTAL_VALIDATIONS=0
PASSED_VALIDATIONS=0
FAILED_VALIDATIONS=0

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

# Validation result functions
validation_passed() {
    ((PASSED_VALIDATIONS++))
    log_success "✓ $1"
}

validation_failed() {
    ((FAILED_VALIDATIONS++))
    log_error "✗ $1"
    if [ -n "${2:-}" ]; then
        echo "  $2"
    fi
}

run_validation() {
    local validation_name="$1"
    local validation_command="$2"
    
    ((TOTAL_VALIDATIONS++))
    log_info "Running: $validation_name"
    
    if eval "$validation_command" >/dev/null 2>&1; then
        validation_passed "$validation_name"
        return 0
    else
        validation_failed "$validation_name" "Command failed: $validation_command"
        return 1
    fi
}

# Validate chart structure
validate_chart_structure() {
    log_info "Validating chart structure..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local structure_failed=0
    
    for chart_dir in $chart_dirs; do
        # Check required files
        local required_files=("Chart.yaml" "values.yaml")
        for req_file in "${required_files[@]}"; do
            if [ -f "$chart_dir/$req_file" ]; then
                validation_passed "Required file exists: $chart_dir/$req_file"
            else
                validation_failed "Required file missing: $chart_dir/$req_file"
                structure_failed=1
            fi
        done
        
        # Check required directories
        local required_dirs=("templates")
        for req_dir in "${required_dirs[@]}"; do
            if [ -d "$chart_dir/$req_dir" ]; then
                validation_passed "Required directory exists: $chart_dir/$req_dir"
            else
                validation_failed "Required directory missing: $chart_dir/$req_dir"
                structure_failed=1
            fi
        done
    done
    
    return $structure_failed
}

# Validate chart naming consistency
validate_chart_naming() {
    log_info "Validating chart naming consistency..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local naming_failed=0
    
    for chart_dir in $chart_dirs; do
        local chart_file="$chart_dir/Chart.yaml"
        local component
        component=$(echo "$chart_dir" | awk -F'/' '{print $(NF-1)}')
        local chart_name
        chart_name=$(grep "^name:" "$chart_file" | sed 's/name: //')
        local expected_name
        expected_name=${component//-/_}
        
        if [ "$chart_name" = "$expected_name" ]; then
            validation_passed "Chart naming consistency: $chart_dir"
        else
            validation_failed "Chart naming consistency: $chart_dir (expected: $expected_name, got: $chart_name)"
            naming_failed=1
        fi
    done
    
    return $naming_failed
}

# Validate for duplicate chart versions
validate_duplicate_versions() {
    log_info "Validating duplicate chart versions..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    # Check for duplicate chart versions
    local duplicate_check
    duplicate_check=$(find . -name "Chart.yaml" -exec sh -c '
        chart_dir=$(dirname "$1")
        chart_name=$(grep "^name:" "$1" | sed "s/name: //")
        chart_version=$(grep "^version:" "$1" | sed "s/version: //")
        echo "$chart_name-$chart_version"
    ' _ {} \; | sort | uniq -c | grep -v " 1 ")
    
    if [ -z "$duplicate_check" ]; then
        validation_passed "No duplicate chart versions found"
        return 0
    else
        validation_failed "Duplicate chart versions found"
        echo "$duplicate_check"
        return 1
    fi
}

# Validate Chart.yaml completeness
validate_chart_yaml_completeness() {
    log_info "Validating Chart.yaml completeness..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local completeness_failed=0
    
    for chart_dir in $chart_dirs; do
        local chart_file="$chart_dir/Chart.yaml"
        
        # Check required fields
        local required_fields=("name" "version" "description" "type")
        for field in "${required_fields[@]}"; do
            if grep -q "^$field:" "$chart_file"; then
                validation_passed "Chart.yaml field exists: $field in $chart_dir"
            else
                validation_failed "Chart.yaml field missing: $field in $chart_dir"
                completeness_failed=1
            fi
        done
        
        # Check if it has bitnami-common dependency
        if grep -q "bitnami-common" "$chart_file"; then
            validation_passed "bitnami-common dependency exists: $chart_dir"
        else
            validation_failed "bitnami-common dependency missing: $chart_dir"
            completeness_failed=1
        fi
    done
    
    return $completeness_failed
}

# Validate chart linting
validate_chart_lint() {
    log_info "Validating chart linting..."
    
    # Check if helm is installed
    if ! command -v helm >/dev/null 2>&1; then
        log_error "helm is not installed. Please install it following the official documentation"
        return 1
    fi
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local lint_failed=0
    
    for chart_dir in $chart_dirs; do
        if run_validation "Chart lint: $chart_dir" "helm lint \"$chart_dir\""; then
            continue
        else
            lint_failed=1
        fi
    done
    
    return $lint_failed
}

# Validate chart dependencies
validate_chart_dependencies() {
    log_info "Validating chart dependencies..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local deps_failed=0
    
    for chart_dir in $chart_dirs; do
        local chart_file="$chart_dir/Chart.yaml"
        
        # Check if dependencies are defined
        if grep -q "dependencies:" "$chart_file"; then
            validation_passed "Dependencies defined: $chart_dir"
            
            # Check if dependency versions are pinned
            if grep -A 10 "dependencies:" "$chart_file" | grep -q "version:"; then
                validation_passed "Dependency versions pinned: $chart_dir"
            else
                validation_failed "Dependency versions not pinned: $chart_dir"
                deps_failed=1
            fi
        else
            log_warning "No dependencies defined: $chart_dir"
        fi
    done
    
    return $deps_failed
}

# Validate chart values
validate_chart_values() {
    log_info "Validating chart values..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local values_failed=0
    
    for chart_dir in $chart_dirs; do
        local values_file="$chart_dir/values.yaml"
        
        if [ -f "$values_file" ]; then
            # Check if values.yaml is valid YAML
            if run_validation "Values.yaml syntax: $chart_dir" "yq . \"$values_file\" >/dev/null"; then
                continue
            else
                values_failed=1
            fi
        else
            validation_failed "Values.yaml missing: $chart_dir"
            values_failed=1
        fi
    done
    
    return $values_failed
}

# Validate chart templates
validate_chart_templates() {
    log_info "Validating chart templates..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local templates_failed=0
    
    for chart_dir in $chart_dirs; do
        local templates_dir="$chart_dir/templates"
        
        if [ -d "$templates_dir" ]; then
            # Check if templates directory has YAML files
            local yaml_count
            yaml_count=$(find "$templates_dir" -name "*.yaml" -o -name "*.yml" | wc -l)
            if [ "$yaml_count" -gt 0 ]; then
                validation_passed "Templates exist: $chart_dir"
                
                # Check template syntax
                for template_file in "$templates_dir"/*.yaml "$templates_dir"/*.yml; do
                    if [ -f "$template_file" ]; then
                        if run_validation "Template syntax: $template_file" "yq . \"$template_file\" >/dev/null"; then
                            continue
                        else
                            templates_failed=1
                        fi
                    fi
                done
            else
                validation_failed "No templates found: $chart_dir"
                templates_failed=1
            fi
        else
            validation_failed "Templates directory missing: $chart_dir"
            templates_failed=1
        fi
    done
    
    return $templates_failed
}

# Validate chart files directory
validate_chart_files() {
    log_info "Validating chart files directory..."
    
    # Find all chart directories
    local chart_dirs
    chart_dirs=$(find . -name "Chart.yaml" -exec dirname {} \; | grep -v ".git")
    
    if [ -z "$chart_dirs" ]; then
        log_error "No Helm charts found"
        return 1
    fi
    
    local files_failed=0
    
    for chart_dir in $chart_dirs; do
        local files_dir="$chart_dir/files"
        
        if [ -d "$files_dir" ]; then
            # Check for template files
            local tpl_count
            tpl_count=$(find "$files_dir" -name "*.tpl" | wc -l)
            if [ "$tpl_count" -gt 0 ]; then
                validation_passed "Template files exist: $chart_dir"
                
                # Check for parameter files
                local param_count
                param_count=$(find "$files_dir" -name "*ParametersDetail.json" | wc -l)
                if [ "$param_count" -gt 0 ]; then
                    validation_passed "Parameter files exist: $chart_dir"
                else
                    log_warning "Parameter files missing: $chart_dir"
                fi
            else
                log_warning "No template files: $chart_dir"
            fi
        else
            log_warning "Files directory missing: $chart_dir"
        fi
    done
    
    return $files_failed
}

# Run all validations
run_all_validations() {
    log_info "Running all chart validations..."
    
    validate_chart_structure
    validate_chart_naming
    validate_duplicate_versions
    validate_chart_yaml_completeness
    validate_chart_lint
    validate_chart_dependencies
    validate_chart_values
    validate_chart_templates
    validate_chart_files
}

# Print validation summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "        Chart Validation Summary"
    echo "=========================================="
    echo "Total validations:  $TOTAL_VALIDATIONS"
    echo "Passed:             $PASSED_VALIDATIONS"
    echo "Failed:             $FAILED_VALIDATIONS"
    echo "=========================================="
    
    if [ $FAILED_VALIDATIONS -eq 0 ]; then
        echo -e "${GREEN}All chart validations passed!${NC}"
        return 0
    else
        echo -e "${RED}$FAILED_VALIDATIONS chart validation(s) failed!${NC}"
        return 1
    fi
}

# Main script logic
main() {
    echo "UPM Packages Chart Validation Suite"
    echo "=================================="
    
    run_all_validations
    print_summary
    exit $?
}

# Run main function
main "$@"