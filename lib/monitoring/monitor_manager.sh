#!/bin/bash

# SSH Service Monitor Manager
# Handles monitoring of SSH services across primary and backup hosts

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load failover configuration
FAILOVER_CONFIG="${SCRIPT_DIR}/../../config/ha/failover.yaml"

# Global variables
declare -A HOST_STATUS
declare -A SERVICE_STATUS
MONITOR_LOCK_FILE="${HA_STATE_DIR}/monitor.lock"
LAST_CHECK_TIME=0

# Function to load failover configuration
load_failover_config() {
    if [[ ! -f "${FAILOVER_CONFIG}" ]]; then
        log_error "Failover configuration not found: ${FAILOVER_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${FAILOVER_CONFIG}")"
}

# Function to acquire monitor lock
acquire_monitor_lock() {
    if [[ -f "${MONITOR_LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${MONITOR_LOCK_FILE}")
        if kill -0 "${lock_pid}" 2>/dev/null; then
            log_warning "Monitoring already in progress (PID: ${lock_pid})"
            return 1
        fi
        rm -f "${MONITOR_LOCK_FILE}"
    fi
    
    echo $$ > "${MONITOR_LOCK_FILE}"
    return 0
}

# Function to release monitor lock
release_monitor_lock() {
    rm -f "${MONITOR_LOCK_FILE}"
}

# Function to check SSH connectivity
check_ssh_connectivity() {
    local host=$1
    local port=$2
    local user=$3
    local timeout=${4:-${SSH_TIMEOUT}}
    
    ssh ${SSH_OPTIONS} \
        -p "${port}" \
        -i "${SSH_KEY_PATH}" \
        -o ConnectTimeout="${timeout}" \
        "${user}@${host}" "exit 0" >/dev/null 2>&1
}

# Function to check service status
check_service_status() {
    local host=$1
    local service=$2
    local required=$3
    
    local status
    status=$(ssh ${SSH_OPTIONS} \
        -p "${SSH_PORT}" \
        -i "${SSH_KEY_PATH}" \
        "${SSH_USER}@${host}" "systemctl is-active ${service}" 2>/dev/null)
    
    if [[ "${status}" == "active" ]]; then
        SERVICE_STATUS["${host}.${service}"]="active"
        return 0
    else
        SERVICE_STATUS["${host}.${service}"]="inactive"
        if [[ "${required}" == "true" ]]; then
            return 1
        fi
        return 0
    fi
}

# Function to check system resources
check_system_resources() {
    local host=$1
    local cpu_threshold=${2:-${RESOURCE_CPU_THRESHOLD}}
    local mem_threshold=${3:-${RESOURCE_MEM_THRESHOLD}}
    local disk_threshold=${4:-${RESOURCE_DISK_THRESHOLD}}
    
    # Get system stats
    local stats
    stats=$(ssh ${SSH_OPTIONS} \
        -p "${SSH_PORT}" \
        -i "${SSH_KEY_PATH}" \
        "${SSH_USER}@${host}" \
        "echo -n CPU: && top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' && \
         echo -n MEM: && free | grep Mem | awk '{print \$3/\$2 * 100}' && \
         echo -n DISK: && df -h / | tail -1 | awk '{print \$5}' | tr -d '%'"
    )
    
    # Parse stats
    local cpu_usage mem_usage disk_usage
    cpu_usage=$(echo "${stats}" | grep CPU | cut -d' ' -f2)
    mem_usage=$(echo "${stats}" | grep MEM | cut -d' ' -f2)
    disk_usage=$(echo "${stats}" | grep DISK | cut -d' ' -f2)
    
    # Check thresholds
    local status="healthy"
    if (( $(echo "${cpu_usage} > ${cpu_threshold}" | bc -l) )); then
        status="cpu_high"
    fi
    if (( $(echo "${mem_usage} > ${mem_threshold}" | bc -l) )); then
        status="mem_high"
    fi
    if (( $(echo "${disk_usage} > ${disk_threshold}" | bc -l) )); then
        status="disk_high"
    fi
    
    HOST_STATUS["${host}.resources"]="${status}"
    echo "${status}"
}

# Function to check single host
check_host() {
    local host=$1
    local port=$2
    local user=$3
    
    # Check SSH connectivity
    if ! check_ssh_connectivity "${host}" "${port}" "${user}"; then
        HOST_STATUS["${host}"]="unreachable"
        log_error "Host ${host} is unreachable"
        return 1
    fi
    
    HOST_STATUS["${host}"]="reachable"
    
    # Check required services
    local service_failed=false
    for service in "${health_check_services[@]}"; do
        if ! check_service_status "${host}" "${service[name]}" "${service[required]}"; then
            service_failed=true
            log_error "Required service ${service[name]} is down on ${host}"
        fi
    done
    
    # Check system resources
    local resource_status
    resource_status=$(check_system_resources "${host}")
    if [[ "${resource_status}" != "healthy" ]]; then
        log_warning "Resource issue on ${host}: ${resource_status}"
        service_failed=true
    fi
    
    if [[ "${service_failed}" == "true" ]]; then
        HOST_STATUS["${host}"]="degraded"
        return 1
    fi
    
    HOST_STATUS["${host}"]="healthy"
    return 0
}

# Function to check all hosts
check_all_hosts() {
    local check_failed=false
    
    # Try to acquire monitor lock
    if ! acquire_monitor_lock; then
        return 1
    fi
    
    # Check primary host
    if ! check_host "${hosts_primary_hostname}" "${SSH_PORT}" "${SSH_USER}"; then
        check_failed=true
    fi
    
    # Check backup hosts
    for backup in "${hosts_backup[@]}"; do
        if ! check_host "${backup[hostname]}" "${SSH_PORT}" "${SSH_USER}"; then
            check_failed=true
        fi
    done
    
    LAST_CHECK_TIME=$(date +%s)
    release_monitor_lock
    
    if [[ "${check_failed}" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# Function to get monitoring report
get_monitoring_report() {
    local report=""
    report+="Monitoring Status Report\n"
    report+="Last check: $(date -d @${LAST_CHECK_TIME} '+%Y-%m-%d %H:%M:%S')\n"
    report+="Check interval: ${HA_CHECK_INTERVAL} seconds\n\n"
    
    # Host status
    report+="Host Status:\n"
    for host in "${!HOST_STATUS[@]}"; do
        if [[ "${host}" != *".resources" ]]; then
            report+="  ${host}: ${HOST_STATUS[${host}]}\n"
            if [[ -n "${HOST_STATUS[${host}.resources]}" ]]; then
                report+="    Resources: ${HOST_STATUS[${host}.resources]}\n"
            fi
        fi
    done
    
    # Service status
    report+="\nService Status:\n"
    for service in "${!SERVICE_STATUS[@]}"; do
        report+="  ${service}: ${SERVICE_STATUS[${service}]}\n"
    done
    
    echo -e "${report}"
}

# Function to send notifications
send_notifications() {
    local status=$1
    local message=$2
    
    # Check if notifications are enabled
    if [[ "${notifications_enabled}" != "true" ]]; then
        return 0
    fi
    
    # Send to each configured channel
    for channel in "${notifications_channels[@]}"; do
        case "${channel[type]}" in
            email)
                if [[ -n "${channel[recipients]}" ]]; then
                    echo "${message}" | mail -s "SSH Monitor: ${status}" "${channel[recipients]}"
                fi
                ;;
            slack)
                if [[ -n "${channel[webhook]}" ]]; then
                    curl -X POST -H 'Content-type: application/json' \
                        --data "{\"text\":\"${message}\"}" \
                        "${channel[webhook]}"
                fi
                ;;
        esac
    done
}

# Main function
main() {
    # Load configuration
    if ! load_failover_config; then
        exit 1
    fi
    
    # Create required directories
    mkdir -p "${HA_LOG_DIR}/monitor" "${HA_STATE_DIR}" "${HA_TEMP_DIR}"
    
    # Process command line arguments
    case "$1" in
        check)
            if [[ -n "$2" ]]; then
                check_host "$2" "${SSH_PORT}" "${SSH_USER}"
            else
                check_all_hosts
            fi
            ;;
        status)
            get_monitoring_report
            ;;
        monitor)
            # Continuous monitoring loop
            while true; do
                if check_all_hosts; then
                    log_info "All hosts healthy"
                else
                    log_warning "Some hosts have issues"
                    send_notifications "WARNING" "$(get_monitoring_report)"
                fi
                sleep "${HA_CHECK_INTERVAL}"
            done
            ;;
        *)
            echo "Usage: $0 {check [host]|status|monitor}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
