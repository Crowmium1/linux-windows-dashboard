#!/bin/bash

# Resource tracking for SSH Dashboard Monitor
# Monitors and manages system resources used by the SSH Dashboard

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load resource configuration
RESOURCE_CONFIG="${SCRIPT_DIR}/../../config/monitoring/resources.yaml"

# Global variables
declare -A RESOURCE_CACHE
declare -A TRIGGER_STATES

# Function to load resource configuration
load_resource_config() {
    if [[ ! -f "${RESOURCE_CONFIG}" ]]; then
        log_error "Resource configuration not found: ${RESOURCE_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${RESOURCE_CONFIG}")"
}

# Function to check process resources
check_process_resources() {
    local pid=$1
    local metrics=()
    
    # CPU usage
    local cpu_usage
    cpu_usage=$(ps -p "${pid}" -o %cpu | tail -1)
    metrics+=("cpu_usage=${cpu_usage}")
    
    # Memory usage
    local memory_usage
    memory_usage=$(($(ps -p "${pid}" -o rss | tail -1) / 1024))  # Convert to MB
    metrics+=("memory_usage=${memory_usage}")
    
    # File handles
    local file_handles
    file_handles=$(lsof -p "${pid}" | wc -l)
    metrics+=("file_handles=${file_handles}")
    
    # Thread count
    local thread_count
    thread_count=$(ps -p "${pid}" -o nlwp | tail -1)
    metrics+=("thread_count=${thread_count}")
    
    echo "${metrics[*]}"
}

# Function to check connection resources
check_connection_resources() {
    local metrics=()
    
    # Concurrent connections
    local concurrent_connections
    concurrent_connections=$(ss -tn | grep -c ESTAB)
    metrics+=("concurrent_connections=${concurrent_connections}")
    
    # Per-host connections
    local per_host_connections
    per_host_connections=$(ss -tn | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -1 | awk '{print $1}')
    metrics+=("per_host_connections=${per_host_connections}")
    
    # Bandwidth usage
    local bandwidth_usage
    bandwidth_usage=$(awk '{if($1=="eth0:"){print int(($2+$10)/1024/1024)}}' /proc/net/dev)
    metrics+=("bandwidth_usage=${bandwidth_usage}")
    
    echo "${metrics[*]}"
}

# Function to check storage resources
check_storage_resources() {
    local metrics=()
    
    # Log directory size
    local log_size
    log_size=$(($(du -sm "${limits_storage_max_log_size_mb}" 2>/dev/null | cut -f1) || echo "0"))
    metrics+=("log_size=${log_size}")
    
    # Metrics directory size
    local metrics_size
    metrics_size=$(($(du -sm "${limits_storage_max_metrics_size_mb}" 2>/dev/null | cut -f1) || echo "0"))
    metrics+=("metrics_size=${metrics_size}")
    
    # Temp directory size
    local temp_size
    temp_size=$(($(du -sm "${limits_storage_max_temp_size_mb}" 2>/dev/null | cut -f1) || echo "0"))
    metrics+=("temp_size=${temp_size}")
    
    echo "${metrics[*]}"
}

# Function to check trigger conditions
check_trigger_conditions() {
    local trigger=$1
    local value=$2
    local threshold=$3
    local duration=$4
    
    # Initialize trigger state if needed
    TRIGGER_STATES["${trigger}_start"]=0
    
    if (( $(echo "${value} > ${threshold}" | bc -l) )); then
        if [[ ${TRIGGER_STATES["${trigger}_start"]} -eq 0 ]]; then
            TRIGGER_STATES["${trigger}_start"]=$(date +%s)
        elif [[ $(($(date +%s) - TRIGGER_STATES["${trigger}_start"])) -ge ${duration} ]]; then
            return 0
        fi
    else
        TRIGGER_STATES["${trigger}_start"]=0
    fi
    
    return 1
}

# Function to handle resource triggers
handle_resource_trigger() {
    local trigger=$1
    local value=$2
    
    case "${trigger}" in
        cpu_high|memory_high)
            # Alert via alert manager
            "${SCRIPT_DIR}/alerts.sh" resource-alert "${trigger}" "${value}"
            ;;
        disk_full)
            # Trigger cleanup
            cleanup_resources
            ;;
    esac
}

# Function to cleanup resources
cleanup_resources() {
    log_info "Starting resource cleanup"
    
    # Cleanup logs
    find "${cleanup_logs_max_age_days}" -type f -mtime "+${cleanup_logs_max_age_days}" -delete
    
    # Cleanup metrics
    find "${cleanup_metrics_max_age_days}" -type f -mtime "+${cleanup_metrics_max_age_days}" -delete
    
    # Cleanup temp files
    find "${cleanup_temp_max_age_hours}" -type f -mmin "+$((cleanup_temp_max_age_hours * 60))" -delete
}

# Function to manage resource allocation
manage_resource_allocation() {
    local current_connections=$1
    
    # Calculate needed worker threads
    local needed_threads
    needed_threads=$(( current_connections / 10 + 1 ))
    needed_threads=$(( needed_threads > allocation_worker_threads_max_count ? allocation_worker_threads_max_count : needed_threads ))
    needed_threads=$(( needed_threads < allocation_worker_threads_min_count ? allocation_worker_threads_min_count : needed_threads ))
    
    # Adjust thread pool
    if [[ ${needed_threads} != "${RESOURCE_CACHE[current_threads]:-0}" ]]; then
        log_info "Adjusting worker thread count to ${needed_threads}"
        RESOURCE_CACHE[current_threads]=${needed_threads}
        # Implementation-specific thread pool adjustment would go here
    fi
}

# Main function
main() {
    # Load configuration
    if ! load_resource_config; then
        exit 1
    fi
    
    # Process command line arguments
    case "$1" in
        check)
            case "$2" in
                process)
                    metrics=($(check_process_resources "$3"))
                    echo "${metrics[*]}"
                    ;;
                connection)
                    metrics=($(check_connection_resources))
                    echo "${metrics[*]}"
                    ;;
                storage)
                    metrics=($(check_storage_resources))
                    echo "${metrics[*]}"
                    ;;
                *)
                    echo "Usage: $0 check {process <pid>|connection|storage}"
                    exit 1
                    ;;
            esac
            ;;
        monitor)
            # Continuous monitoring loop
            while true; do
                # Check process resources
                metrics=($(check_process_resources "$$"))
                for metric in "${metrics[@]}"; do
                    name=${metric%=*}
                    value=${metric#*=}
                    if check_trigger_conditions "${name}" "${value}" "${monitoring_triggers_${name}_threshold}" "${monitoring_triggers_${name}_duration_sec}"; then
                        handle_resource_trigger "${name}" "${value}"
                    fi
                done
                
                # Check connection resources
                metrics=($(check_connection_resources))
                manage_resource_allocation "$(echo "${metrics[0]}" | cut -d= -f2)"
                
                # Sleep for monitoring interval
                sleep "${monitoring_interval_sec}"
            done
            ;;
        cleanup)
            cleanup_resources
            ;;
        *)
            echo "Usage: $0 {check {process <pid>|connection|storage}|monitor|cleanup}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi