#!/bin/bash

# State Synchronization Manager for SSH Dashboard
# Handles synchronization of state between primary and backup hosts

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load failover configuration
FAILOVER_CONFIG="${SCRIPT_DIR}/../../config/ha/failover.yaml"

# Global variables
declare -A SYNC_STATUS
LAST_SYNC_TIME=0
SYNC_LOCK_FILE="${HA_STATE_DIR}/sync.lock"

# Function to load failover configuration
load_failover_config() {
    if [[ ! -f "${FAILOVER_CONFIG}" ]]; then
        log_error "Failover configuration not found: ${FAILOVER_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${FAILOVER_CONFIG}")"
}

# Function to establish SSH connection with global settings
establish_ssh_connection() {
    local host=$1
    local port=$2
    local user=$3
    local cmd=${4:-"exit 0"}
    
    ssh ${SSH_OPTIONS} \
        -p "${port}" \
        -i "${SSH_KEY_PATH}" \
        "${user}@${host}" \
        "${cmd}"
}

# Function to check if sync is needed
check_sync_needed() {
    local current_time
    current_time=$(date +%s)
    
    if [[ $((current_time - LAST_SYNC_TIME)) -lt "${HA_SYNC_INTERVAL}" ]]; then
        return 1
    fi
    
    return 0
}

# Function to acquire sync lock
acquire_sync_lock() {
    if [[ -f "${SYNC_LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${SYNC_LOCK_FILE}")
        if kill -0 "${lock_pid}" 2>/dev/null; then
            log_warning "Sync already in progress (PID: ${lock_pid})"
            return 1
        fi
        rm -f "${SYNC_LOCK_FILE}"
    fi
    
    echo $$ > "${SYNC_LOCK_FILE}"
    return 0
}

# Function to release sync lock
release_sync_lock() {
    rm -f "${SYNC_LOCK_FILE}"
}

# Function to verify file integrity
verify_file_integrity() {
    local source_host=$1
    local target_host=$2
    local file_path=$3
    
    local source_sum
    source_sum=$(establish_ssh_connection "${source_host}" "${SSH_PORT}" "${SSH_USER}" "sha256sum ${file_path}" | awk '{print $1}')
    
    local target_sum
    target_sum=$(establish_ssh_connection "${target_host}" "${SSH_PORT}" "${SSH_USER}" "sha256sum ${file_path}" | awk '{print $1}')
    
    [[ "${source_sum}" == "${target_sum}" ]]
}

# Function to handle sync conflicts
handle_sync_conflict() {
    local source_host=$1
    local target_host=$2
    local file_path=$3
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    
    log_warning "Sync conflict detected for ${file_path} between ${source_host} and ${target_host}"
    
    # Backup target file
    establish_ssh_connection "${target_host}" "${SSH_PORT}" "${SSH_USER}" \
        "cp ${file_path} ${file_path}.${timestamp}.bak"
    
    # Force sync from source
    rsync -avz --delete \
        -e "ssh ${SSH_OPTIONS} -p ${SSH_PORT} -i ${SSH_KEY_PATH}" \
        "${source_host}:${file_path}" "${target_host}:${file_path}"
    
    log_info "Conflict resolved: ${file_path} synced from ${source_host}, backup created on ${target_host}"
}

# Function to sync single host
sync_host() {
    local source_host=$1
    local target_host=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H%M%S')
    
    log_info "Starting sync from ${source_host} to ${target_host}"
    
    # Create temporary directory for sync logs
    local temp_dir="${HA_TEMP_DIR}/sync_${timestamp}"
    mkdir -p "${temp_dir}"
    
    # Parse sync paths and excludes
    IFS=',' read -r -a sync_paths <<< "${HA_SYNC_PATHS}"
    IFS=',' read -r -a sync_excludes <<< "${HA_SYNC_EXCLUDE}"
    
    # Sync each configured path
    for path in "${sync_paths[@]}"; do
        # Build exclude options
        local exclude_opts=""
        for pattern in "${sync_excludes[@]}"; do
            exclude_opts+="--exclude=${pattern} "
        done
        
        # Create target directory if it doesn't exist
        establish_ssh_connection "${target_host}" "${SSH_PORT}" "${SSH_USER}" "mkdir -p ${path}"
        
        # Sync using rsync with global SSH settings
        if ! rsync -avz --delete ${exclude_opts} \
             -e "ssh ${SSH_OPTIONS} -p ${SSH_PORT} -i ${SSH_KEY_PATH}" \
             "${source_host}:${path}/" "${target_host}:${path}/" \
             > "${temp_dir}/rsync_${timestamp}.log" 2>&1; then
            log_error "Failed to sync ${path} from ${source_host} to ${target_host}"
            SYNC_STATUS["${target_host}"]="failed"
            return 1
        fi
        
        # Verify sync integrity
        if ! verify_file_integrity "${source_host}" "${target_host}" "${path}"; then
            log_warning "Integrity check failed for ${path}"
            handle_sync_conflict "${source_host}" "${target_host}" "${path}"
        fi
    done
    
    SYNC_STATUS["${target_host}"]="success"
    log_info "Sync completed successfully for ${target_host}"
    
    # Rotate sync logs
    if [[ -d "${temp_dir}" ]]; then
        mv "${temp_dir}/rsync_${timestamp}.log" "${HA_LOG_DIR}/sync/"
        rm -rf "${temp_dir}"
    fi
    
    return 0
}

# Function to sync all backup hosts
sync_all_hosts() {
    local source_host="${hosts_primary_hostname:-${HA_PRIMARY_HOST}}"
    local sync_failed=false
    
    # Initialize sync status for configured backup hosts
    for backup in "${hosts_backup[@]}"; do
        SYNC_STATUS["${backup[hostname]}"]="pending"
    done
    
    # Try to acquire sync lock
    if ! acquire_sync_lock; then
        return 1
    fi
    
    # Sync each backup host
    for backup in "${hosts_backup[@]}"; do
        if ! sync_host "${source_host}" "${backup[hostname]}"; then
            sync_failed=true
        fi
    done
    
    LAST_SYNC_TIME=$(date +%s)
    release_sync_lock
    
    if [[ "${sync_failed}" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# Function to verify sync status
verify_sync() {
    local source_host=$1
    local target_host=$2
    
    IFS=',' read -r -a sync_paths <<< "${HA_SYNC_PATHS}"
    
    for path in "${sync_paths[@]}"; do
        if ! verify_file_integrity "${source_host}" "${target_host}" "${path}"; then
            log_error "Sync verification failed for ${path} on ${target_host}"
            return 1
        fi
    done
    
    log_info "Sync verification successful for ${target_host}"
    return 0
}

# Function to get sync status report
get_sync_report() {
    local report=""
    report+="Sync Status Report\n"
    report+="Last sync: $(date -d @${LAST_SYNC_TIME} '+%Y-%m-%d %H:%M:%S')\n"
    report+="Sync interval: ${HA_SYNC_INTERVAL} seconds\n"
    report+="Sync paths: ${HA_SYNC_PATHS}\n"
    report+="Exclude patterns: ${HA_SYNC_EXCLUDE}\n\n"
    
    for host in "${!SYNC_STATUS[@]}"; do
        report+="${host}: ${SYNC_STATUS[${host}]}\n"
        if verify_sync "${HA_PRIMARY_HOST}" "${host}" >/dev/null 2>&1; then
            report+="  Integrity: OK\n"
        else
            report+="  Integrity: FAILED\n"
        fi
    done
    
    echo -e "${report}"
}

# Main function
main() {
    # Load configuration
    if ! load_failover_config; then
        exit 1
    fi
    
    # Create required directories
    mkdir -p "${HA_LOG_DIR}/sync" "${HA_STATE_DIR}" "${HA_TEMP_DIR}"
    
    # Process command line arguments
    case "$1" in
        sync)
            if [[ -n "$2" ]] && [[ -n "$3" ]]; then
                sync_host "$2" "$3"
            else
                sync_all_hosts
            fi
            ;;
        verify)
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                echo "Usage: $0 verify <source_host> <target_host>"
                exit 1
            fi
            verify_sync "$2" "$3"
            ;;
        status)
            get_sync_report
            ;;
        monitor)
            # Continuous monitoring loop
            while true; do
                if check_sync_needed; then
                    sync_all_hosts
                fi
                sleep "${HA_CHECK_INTERVAL}"
            done
            ;;
        *)
            echo "Usage: $0 {sync [source_host target_host]|verify <source_host> <target_host>|status|monitor}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
