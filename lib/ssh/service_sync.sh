#!/bin/bash

# Service synchronization script for SSH Dashboard Monitor
# Handles service-level synchronization between local and remote systems

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config_loader.sh"
source "${SCRIPT_DIR}/../utils/utils.sh"

# Global variables
SYNC_LOCK_FILE="/tmp/service_sync.lock"
SYNC_STATUS_FILE="/tmp/service_sync_status"
SYNC_INTERVAL=300  # 5 minutes default

# Function to check if sync is already running
check_sync_lock() {
    if [[ -f "${SYNC_LOCK_FILE}" ]]; then
        local pid
        pid=$(cat "${SYNC_LOCK_FILE}")
        if kill -0 "$pid" 2>/dev/null; then
            log_error "Sync process already running with PID: $pid"
            return 1
        else
            rm -f "${SYNC_LOCK_FILE}"
        fi
    fi
    echo $$ > "${SYNC_LOCK_FILE}"
    return 0
}

# Function to sync service status
sync_service_status() {
    local remote_host=$1
    local remote_user=$2
    local service_name=$3
    
    log_info "Syncing service status for ${service_name} on ${remote_host}"
    
    # Get local service status
    local local_status
    local_status=$(systemctl is-active "${service_name}" 2>/dev/null || echo "unknown")
    
    # Get remote service status
    local remote_status
    remote_status=$(ssh "${remote_user}@${remote_host}" "systemctl is-active ${service_name}" 2>/dev/null || echo "unknown")
    
    # Compare and log statuses
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${service_name} Local: ${local_status} Remote: ${remote_status}" >> "${SYNC_STATUS_FILE}"
    
    # Handle status mismatch
    if [[ "${local_status}" != "${remote_status}" ]]; then
        log_warning "Service status mismatch detected for ${service_name}"
        log_warning "Local: ${local_status}, Remote: ${remote_status}"
        handle_status_mismatch "${remote_host}" "${remote_user}" "${service_name}" "${local_status}" "${remote_status}"
    fi
}

# Function to handle status mismatch
handle_status_mismatch() {
    local remote_host=$1
    local remote_user=$2
    local service_name=$3
    local local_status=$4
    local remote_status=$5
    
    # Log the mismatch event
    log_warning "Handling status mismatch for ${service_name}"
    
    case "${local_status}" in
        "active")
            if [[ "${remote_status}" != "active" ]]; then
                log_info "Starting remote service ${service_name}"
                ssh "${remote_user}@${remote_host}" "sudo systemctl start ${service_name}"
            fi
            ;;
        "inactive"|"failed")
            if [[ "${remote_status}" == "active" ]]; then
                log_info "Stopping remote service ${service_name}"
                ssh "${remote_user}@${remote_host}" "sudo systemctl stop ${service_name}"
            fi
            ;;
    esac
}

# Function to sync service configuration
sync_service_config() {
    local remote_host=$1
    local remote_user=$2
    local service_name=$3
    
    log_info "Syncing service configuration for ${service_name}"
    
    # Define config paths
    local local_config="/etc/systemd/system/${service_name}.service"
    local remote_config="/etc/systemd/system/${service_name}.service"
    
    # Compare configurations
    if ! ssh "${remote_user}@${remote_host}" "cat ${remote_config}" | diff - "${local_config}" >/dev/null 2>&1; then
        log_info "Configuration difference detected, syncing..."
        scp "${local_config}" "${remote_user}@${remote_host}:${remote_config}.new"
        ssh "${remote_user}@${remote_host}" "sudo mv ${remote_config}.new ${remote_config} && sudo systemctl daemon-reload"
    fi
}

# Function to cleanup
cleanup() {
    log_info "Cleaning up service sync"
    rm -f "${SYNC_LOCK_FILE}"
}

# Main sync function
main() {
    local remote_host=$1
    local remote_user=$2
    local service_name=$3
    
    # Setup cleanup trap
    trap cleanup EXIT
    
    # Check arguments
    if [[ -z "${remote_host}" || -z "${remote_user}" || -z "${service_name}" ]]; then
        log_error "Usage: $0 <remote_host> <remote_user> <service_name>"
        exit 1
    fi
    
    # Check if sync is already running
    if ! check_sync_lock; then
        exit 1
    fi
    
    # Load environment config
    if ! load_environment_config; then
        log_error "Failed to load environment configuration"
        exit 1
    fi
    
    # Main sync loop
    while true; do
        log_info "Starting service sync for ${service_name}"
        
        # Sync service status
        sync_service_status "${remote_host}" "${remote_user}" "${service_name}"
        
        # Sync service configuration
        sync_service_config "${remote_host}" "${remote_user}" "${service_name}"
        
        # Wait for next sync
        sleep "${SYNC_INTERVAL}"
    done
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi