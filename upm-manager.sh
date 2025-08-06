#!/usr/bin/env bash

# UPM Packages Unified Management Script
# This script provides unified management for all UPM packages including install, uninstall, and upgrade operations

set -euo pipefail

# Default values
NAMESPACE="upm-system"
DRY_RUN=false
HELM_REPO_NAME="upm-packages"
HELM_REPO_URL="https://upmio.github.io/upm-packages"
TIMEOUT="300s"
RELEASE_PREFIX="upm-packages"
ACTION=""

# Component categories

# All packages array
ALL_PACKAGES=(
    "mysql-community-8.0.40"
    "mysql-community-8.0.41"
    "mysql-community-8.0.42"
    "mysql-community-8.4.4"
    "mysql-community-8.4.5"
    "mysql-router-community-8.0.40"
    "mysql-router-community-8.0.41"
    "mysql-router-community-8.0.42"
    "mysql-router-community-8.4.4"
    "mysql-router-community-8.4.5"
    "postgresql-15.12"
    "postgresql-15.13"
    "proxysql-2.7.2"
    "proxysql-2.7.3"
    "pgbouncer-1.23.1"
    "pgbouncer-1.24.1"
    "elasticsearch-7.17.14"
    "kibana-7.17.14"
    "kafka-3.5.2"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Function to display help
show_help() {
    cat << EOF
UPM Packages Unified Management Script

This script provides unified management for all UPM packages including install, uninstall, and upgrade operations.

USAGE:
    $0 <ACTION> [OPTIONS] [TARGETS]

ACTIONS:
    install                         Install packages (default)
    uninstall                       Uninstall packages
    upgrade                         Upgrade packages
    list                            List available packages and installed releases
    status                          Show status of installed packages

TARGETS:
    all                             All available packages
    mysql_community                 MySQL Community Server (all versions)
    mysql_router                    MySQL Router Community (all versions)
    postgresql                      PostgreSQL Server (all versions)
    proxysql                        ProxySQL (all versions)
    pgbouncer                       PgBouncer (all versions)
    elasticsearch                   Elasticsearch
    kibana                          Kibana
    kafka                           Kafka
    <chart-name>                    Specific chart name (e.g., mysql-community-8.4.5)

OPTIONS:
    -n, --namespace NAMESPACE      Kubernetes namespace (default: upm-system)
    -d, --dry-run                  Perform a dry run without making changes
    -t, --timeout TIMEOUT          Helm timeout duration (default: 300s)
    -p, --prefix PREFIX            Release name prefix (default: upm-packages)
    -h, --help                     Show this help message

EXAMPLES:
    # Install all packages
    $0 install all

    # Install MySQL components only
    $0 install mysql_community mysql_router

    # Uninstall specific package
    $0 uninstall mysql-community-8.4.5

    # Upgrade all packages
    $0 upgrade all

    # List all available packages
    $0 list

    # Show status of installed packages
    $0 status

    # Dry run installation
    $0 install --dry-run mysql_community

NOTE: These are UPM packages that require UPM CRDs to function.

EOF
}

# Function to parse command line arguments
parse_args() {
    # Check if help is requested first
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            show_help
            exit 0
        fi
    done

    if [[ $# -eq 0 ]]; then
        print_error "No action specified. Use --help for usage information."
        exit 1
    fi

    ACTION="$1"
    shift

    # Validate action
    case "$ACTION" in
        install|uninstall|upgrade|list|status)
            ;;
        *)
            print_error "Invalid action: $ACTION"
            show_help
            exit 1
            ;;
    esac

    local targets=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -p|--prefix)
                RELEASE_PREFIX="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                targets+=("$1")
                shift
                ;;
        esac
    done

    # Set targets based on action
    case "$ACTION" in
        install|uninstall|upgrade)
            if [[ ${#targets[@]} -eq 0 ]]; then
                print_error "No targets specified for $ACTION action"
                show_help
                exit 1
            fi
            SELECTED_TARGETS=("${targets[@]}")
            ;;
        list|status)
            # These actions don't require targets
            SELECTED_TARGETS=()
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi

    # Check if kubernetes cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster is not accessible"
        exit 1
    fi

    # Check if jq is installed for JSON parsing (optional)
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. JSON parsing will be limited."
    fi

    print_success "Prerequisites check passed"
}

# Function to create namespace if it doesn't exist
create_namespace() {
    if [[ "$ACTION" == "install" ]]; then
        print_info "Creating namespace: $NAMESPACE"

        if kubectl get namespace "$NAMESPACE" &> /dev/null; then
            print_warning "Namespace $NAMESPACE already exists"
        else
            kubectl create namespace "$NAMESPACE"
            print_success "Namespace $NAMESPACE created"
        fi
    fi
}

# Function to add helm repository
add_helm_repo() {
    if [[ "$ACTION" == "install" ]]; then
        print_info "Adding helm repository: $HELM_REPO_NAME"

        if helm repo list | grep -q "^$HELM_REPO_NAME "; then
            print_info "Repository $HELM_REPO_NAME already exists, updating..."
            helm repo update "$HELM_REPO_NAME"
        else
            helm repo add "$HELM_REPO_NAME" "$HELM_REPO_URL"
            print_success "Repository $HELM_REPO_NAME added"
        fi
    fi
}

# Function to get packages from targets
get_packages_from_targets() {
    local result=""

    # Ensure SELECTED_TARGETS is set
    if [[ ${#SELECTED_TARGETS[@]} -eq 0 ]]; then
        echo ""
        return
    fi

    for target in "${SELECTED_TARGETS[@]}"; do
        case "$target" in
            all)
                for package in "${ALL_PACKAGES[@]}"; do
                    if [[ -z "$result" ]]; then
                        result="$package"
                    else
                        result="$result $package"
                    fi
                done
                ;;
            mysql_community|mysql_router|postgresql|proxysql|pgbouncer|elasticsearch|kibana|kafka)
                local component_packages
                case "$target" in
                    mysql_community)
                        component_packages=("mysql-community-8.0.40" "mysql-community-8.0.41" "mysql-community-8.0.42" "mysql-community-8.4.4" "mysql-community-8.4.5")
                        ;;
                    mysql_router)
                        component_packages=("mysql-router-community-8.0.40" "mysql-router-community-8.0.41" "mysql-router-community-8.0.42" "mysql-router-community-8.4.4" "mysql-router-community-8.4.5")
                        ;;
                    postgresql)
                        component_packages=("postgresql-15.12" "postgresql-15.13")
                        ;;
                    proxysql)
                        component_packages=("proxysql-2.7.2" "proxysql-2.7.3")
                        ;;
                    pgbouncer)
                        component_packages=("pgbouncer-1.23.1" "pgbouncer-1.24.1")
                        ;;
                    elasticsearch)
                        component_packages=("elasticsearch-7.17.14")
                        ;;
                    kibana)
                        component_packages=("kibana-7.17.14")
                        ;;
                    kafka)
                        component_packages=("kafka-3.5.2")
                        ;;
                esac
                for package in "${component_packages[@]}"; do
                    if [[ -z "$result" ]]; then
                        result="$package"
                    else
                        result="$result $package"
                    fi
                done
                ;;
            *)
                # Check if it's a valid package name
                local valid_package=false
                for package in "${ALL_PACKAGES[@]}"; do
                    if [[ "$package" == "$target" ]]; then
                        valid_package=true
                        break
                    fi
                done

                if [[ "$valid_package" == true ]]; then
                    if [[ -z "$result" ]]; then
                        result="$target"
                    else
                        result="$result $target"
                    fi
                else
                    print_error "Invalid package name: $target"
                    print_info "Available packages:"
                    printf '  %s\n' "${ALL_PACKAGES[@]}"
                    exit 1
                fi
                ;;
        esac
    done

    # Remove duplicates while preserving order
    local unique_result=""
    if [[ -n "$result" ]]; then
        for package in $result; do
            local duplicate=false
            for upackage in $unique_result; do
                if [[ "$upackage" == "$package" ]]; then
                    duplicate=true
                    break
                fi
            done
            if [[ "$duplicate" == false ]]; then
                if [[ -z "$unique_result" ]]; then
                    unique_result="$package"
                else
                    unique_result="$unique_result $package"
                fi
            fi
        done
    fi

    echo "$unique_result"
}

# Function to install package
install_package() {
    local package_name="$1"
    local release_name="${RELEASE_PREFIX}-${package_name}"

    print_info "Installing UPM package: $package_name"

    local helm_cmd="helm install"
    local helm_opts=()

    # Add namespace option
    helm_opts+=("--namespace=$NAMESPACE")

    # Add dry-run option if specified
    if [[ "$DRY_RUN" == true ]]; then
        helm_opts+=("--dry-run" "--debug")
    fi

    # Add timeout option
    helm_opts+=("--timeout=$TIMEOUT")

    # Add release name and package
    helm_opts+=("$release_name" "$HELM_REPO_NAME/$package_name")

    # Show the command being executed
    print_info "Running: $helm_cmd ${helm_opts[*]}"

    # Execute helm command
    if $helm_cmd "${helm_opts[@]}"; then
        print_success "UPM package $package_name installed successfully as $release_name"

        # Verify installation if not dry run
        if [[ "$DRY_RUN" != true ]]; then
            sleep 2
            verify_package_installation "$release_name" "$package_name"
        fi
    else
        print_error "Failed to install UPM package $package_name"
        return 1
    fi
}

# Function to uninstall package
uninstall_package() {
    local package_name="$1"
    local release_name="${RELEASE_PREFIX}-${package_name}"

    print_info "Uninstalling UPM package: $package_name"

    # Check if release exists
    if ! helm status "$release_name" --namespace="$NAMESPACE" &> /dev/null; then
        print_warning "Release $release_name not found, skipping..."
        return 0
    fi

    local helm_cmd="helm uninstall"
    local helm_opts=()

    # Add namespace option
    helm_opts+=("--namespace=$NAMESPACE")

    # Add dry-run option if specified
    if [[ "$DRY_RUN" == true ]]; then
        helm_opts+=("--dry-run")
    fi

    # Add release name
    helm_opts+=("$release_name")

    # Show the command being executed
    print_info "Running: $helm_cmd ${helm_opts[*]}"

    # Execute helm command
    if $helm_cmd "${helm_opts[@]}"; then
        print_success "UPM package $package_name uninstalled successfully"
    else
        print_error "Failed to uninstall UPM package $package_name"
        return 1
    fi
}

# Function to upgrade package
upgrade_package() {
    local package_name="$1"
    local release_name="${RELEASE_PREFIX}-${package_name}"

    print_info "Upgrading UPM package: $package_name"

    # Check if release exists
    if ! helm status "$release_name" --namespace="$NAMESPACE" &> /dev/null; then
        print_warning "Release $release_name not found, skipping..."
        return 0
    fi

    local helm_cmd="helm upgrade"
    local helm_opts=()

    # Add namespace option
    helm_opts+=("--namespace=$NAMESPACE")

    # Add dry-run option if specified
    if [[ "$DRY_RUN" == true ]]; then
        helm_opts+=("--dry-run" "--debug")
    fi

    # Add timeout option
    helm_opts+=("--timeout=$TIMEOUT")

    # Add release name and package
    helm_opts+=("$release_name" "$HELM_REPO_NAME/$package_name")

    # Show the command being executed
    print_info "Running: $helm_cmd ${helm_opts[*]}"

    # Execute helm command
    if $helm_cmd "${helm_opts[@]}"; then
        print_success "UPM package $package_name upgraded successfully"

        # Verify installation if not dry run
        if [[ "$DRY_RUN" != true ]]; then
            sleep 2
            verify_package_installation "$release_name" "$package_name"
        fi
    else
        print_error "Failed to upgrade UPM package $package_name"
        return 1
    fi
}

# Function to verify package installation
verify_package_installation() {
    local release_name="$1"
    local package_name="$2"

    print_info "Verifying UPM package installation: $release_name"

    # Check package status
    if helm status "$release_name" --namespace="$NAMESPACE" > /dev/null 2>&1; then
        print_success "UPM package $release_name verification passed"

        # Show package status
        echo "Package Status:"
        helm status "$release_name" --namespace="$NAMESPACE" | head -10
        echo
    else
        print_warning "UPM package $release_name verification failed"
    fi
}

# Function to list available packages
list_packages() {
    print_header "Available UPM Packages"
    echo

    echo "mysql_community:"
    echo "  - mysql-community-8.0.40"
    echo "  - mysql-community-8.0.41"
    echo "  - mysql-community-8.0.42"
    echo "  - mysql-community-8.4.4"
    echo "  - mysql-community-8.4.5"
    echo

    echo "mysql_router:"
    echo "  - mysql-router-community-8.0.40"
    echo "  - mysql-router-community-8.0.41"
    echo "  - mysql-router-community-8.0.42"
    echo "  - mysql-router-community-8.4.4"
    echo "  - mysql-router-community-8.4.5"
    echo

    echo "postgresql:"
    echo "  - postgresql-15.12"
    echo "  - postgresql-15.13"
    echo

    echo "proxysql:"
    echo "  - proxysql-2.7.2"
    echo "  - proxysql-2.7.3"
    echo

    echo "pgbouncer:"
    echo "  - pgbouncer-1.23.1"
    echo "  - pgbouncer-1.24.1"
    echo

    echo "elasticsearch:"
    echo "  - elasticsearch-7.17.14"
    echo

    echo "kibana:"
    echo "  - kibana-7.17.14"
    echo

    echo "kafka:"
    echo "  - kafka-3.5.2"
    echo

    print_header "Installed Releases"
    echo
    helm list --namespace "$NAMESPACE" --output table 2>/dev/null || echo "No releases found in namespace $NAMESPACE"
}

# Function to show status of installed packages
show_status() {
    print_header "UPM Packages Status"
    echo

    local releases
    local installed_count

    if command -v jq &> /dev/null; then
        releases=$(helm list --namespace "$NAMESPACE" --output json 2>/dev/null || echo "[]")
        installed_count=$(echo "$releases" | jq '. | length' 2>/dev/null || echo "0")
    else
        releases=$(helm list --namespace "$NAMESPACE" --output table 2>/dev/null | tail -n +2)
        installed_count=$(echo "$releases" | grep -c "^" || echo "0")
        if [[ "$installed_count" -gt 0 ]]; then
            installed_count=$((installed_count - 1))  # Subtract header line
        fi
    fi

    print_info "Found $installed_count UPM package releases in namespace $NAMESPACE"

    if [[ "$installed_count" -gt 0 ]]; then
        echo
        helm list --namespace "$NAMESPACE" --output table
    else
        print_warning "No UPM package releases found in namespace $NAMESPACE"
    fi
}

# Function to execute action on packages
execute_action() {
    local package_list
    package_list=$(get_packages_from_targets)

    if [[ -z "$package_list" ]]; then
        print_warning "No packages to process"
        return 0
    fi

    local packages
    read -ra packages <<< "$package_list"

    print_info "Processing ${#packages[@]} packages for $ACTION action"
    echo

    local failed_packages=()

    for package in "${packages[@]}"; do
        case "$ACTION" in
            install)
                if ! install_package "$package"; then
                    failed_packages+=("$package")
                fi
                ;;
            uninstall)
                if ! uninstall_package "$package"; then
                    failed_packages+=("$package")
                fi
                ;;
            upgrade)
                if ! upgrade_package "$package"; then
                    failed_packages+=("$package")
                fi
                ;;
        esac

        # Add delay between operations if not dry run
        if [[ "$DRY_RUN" != true ]]; then
            sleep 3
        fi
    done

    # Print summary
    if [[ ${#failed_packages[@]} -eq 0 ]]; then
        print_success "All packages processed successfully!"
    else
        print_error "Failed to process the following packages:"
        for package in "${failed_packages[@]}"; do
            echo "  - $package"
        done
        return 1
    fi
}

# Main function
main() {
    print_header "UPM Packages Unified Management"
    echo

    parse_args "$@"

    case "$ACTION" in
        list)
            check_prerequisites
            list_packages
            ;;
        status)
            check_prerequisites
            show_status
            ;;
        install|uninstall|upgrade)
            check_prerequisites
            create_namespace
            add_helm_repo

            if execute_action; then
                print_success "$ACTION action completed successfully!"
            else
                print_error "$ACTION action completed with errors"
                exit 1
            fi
            ;;
    esac
}

# Run main function
main "$@"