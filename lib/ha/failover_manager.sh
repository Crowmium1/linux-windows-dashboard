#!/bin/bash

# High Availability Failover Manager for SSH Dashboard
# Handles SSH connection failover and service redundancy

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Ensure required environment variables are set
check_required_vars() {
    local required_vars=(
        "HA_ENABLED"
        "HA_PRIMARY_HOST"
        "HA_PRIMARY_PORT"
        "HA_PRIMARY_USER"
        "HA_CHECK_INTERVAL"
        "HA_MAX_FAILURES"
        "HA_BACKUP_HOSTS"
        "HA_BACKUP_PORTS"
        "HA_BACKUP_USERS"
        "HA_BACKUP_PRIORITIES"
        "SSH_KEY_PATH"
        "SSH_PORT"
        "SSH_OPTIONS"
        "HA_SYNC_PATHS"
        "HA_SYNC_EXCLUDE"
        "HA_REQUIRED_SERVICES"
        "HA_NOTIFY_ENABLED"
        "HA_NOTIFY_EMAIL"
        "HA_NOTIFY_SLACK_WEBHOOK"
        "HA_NOTIFY_SLACK_CHANNEL"
        "DEFAULT_MAX_LOG_SIZE"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            log_error "Required environment variable ${var} is not set"
            return 1
        fi
    done

    return 0
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

# Function to get best backup host
get_best_backup() {
    local best_host=""
    local best_priority=999
    
    for ((i=0; i<${#BACKUP_HOSTS[@]}; i++)); do
        if [[ "${HOST_STATUS[${BACKUP_HOSTS[i]}]}" == "healthy" ]] && \
           [[ "${BACKUP_PRIORITIES[i]}" -lt "${best_priority}" ]]; then
            best_host="${BACKUP_HOSTS[i]}"
            best_priority="${BACKUP_PRIORITIES[i]}"
        fi
    done
    
    echo "${best_host}"
}

# Function to check service health
check_service_health() {
    local hostname=$1
    local service=$2
    local required=$3
    
    if establish_ssh_connection "${hostname}" "${SSH_PORT}" "${SSH_USER}" "systemctl is-active ${service}" >/dev/null 2>&1; then
        return 0
    elif [[ "${required}" == "true" ]]; then
        log_warning "Required service ${service} is not active on ${hostname}"
        return 1
    fi
    
    return 0
}

# Function to check host health
check_host_health() {
    local hostname=$1
    local port=$2
    local user=$3
    local timeout="${HA_HEALTH_CHECK_TIMEOUT}"
    local retries="${HA_HEALTH_CHECK_RETRIES}"
    
    for ((i=1; i<=retries; i++)); do
        if timeout "${timeout}" establish_ssh_connection "${hostname}" "${port}" "${user}"; then
            # Check required services if specified
            if [[ -n "${HA_REQUIRED_SERVICES}" ]]; then
                IFS=',' read -r -a services <<< "${HA_REQUIRED_SERVICES}"
                for service in "${services[@]}"; do
                    if ! check_service_health "${hostname}" "${service}" "true"; then
                        return 1
                    fi
                done
            fi
            return 0
        fi
        sleep 1
    done
    
    return 1
}

# Function to update host status
update_host_status() {
    local hostname=$1
    local port=$2
    local user=$3
    
    # Check connection health
    if ! check_host_health "${hostname}" "${port}" "${user}"; then
        HOST_STATUS["${hostname}"]="unreachable"
        ((FAILURE_COUNT["${hostname}"]++))
        log_warning "Host ${hostname} is unreachable (Failure count: ${FAILURE_COUNT[${hostname}]})"
        return 1
    fi
    
    # Check required services
    local service_failed=false
    for service in "${health_check_services[@]}"; do
        if ! check_service_health "${hostname}" "${service[name]}" "${service[required]}"; then
            service_failed=true
            log_error "Service ${service[name]} check failed on ${hostname}"
            break
        fi
    done
    
    if [[ "${service_failed}" == "true" ]]; then
        HOST_STATUS["${hostname}"]="service_failure"
        ((FAILURE_COUNT["${hostname}"]++))
        return 1
    fi
    
    HOST_STATUS["${hostname}"]="healthy"
    FAILURE_COUNT["${hostname}"]=0
    log_info "Host ${hostname} is healthy"
    return 0
}

# Function to sync state before failover
sync_before_failover() {
    local from_host=$1
    local to_host=$2
    
    # Use global SSH settings for rsync
    rsync -avz -e "ssh ${SSH_OPTIONS} -p ${SSH_PORT} -i ${SSH_KEY_PATH}" \
        --exclude="${HA_SYNC_EXCLUDE}" \
        "${from_host}:${HA_SYNC_PATHS}" "${to_host}:/"
}

# Function to perform failover
perform_failover() {
    local from_host=$1
    local to_host=$2
    
    if [[ "${FAILOVER_IN_PROGRESS}" == "true" ]]; then
        log_warning "Failover already in progress"
        return 1
    fi
    
    FAILOVER_IN_PROGRESS=true
    log_info "Starting failover from ${from_host} to ${to_host}"
    
    # Sync state before failover
    if ! sync_before_failover "${from_host}" "${to_host}"; then
        log_error "State synchronization failed during failover"
        FAILOVER_IN_PROGRESS=false
        return 1
    fi
    
    # Update current primary
    CURRENT_PRIMARY="${to_host}"
    
    # Send notifications
    if [[ "${HA_NOTIFY_ENABLED}" == "true" ]]; then
        notify_failover "${from_host}" "${to_host}"
    fi
    
    FAILOVER_IN_PROGRESS=false
    log_info "Failover completed successfully"
    return 0
}

# Function to notify about failover
notify_failover() {
    local from_host=$1
    local to_host=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local message="SSH Failover Event\n"
    message+="Time: ${timestamp}\n"
    message+="From: ${from_host}\n"
    message+="To: ${to_host}\n"
    message+="Status: Completed"
    
    if [[ "${HA_NOTIFY_ENABLED}" == "true" ]]; then
        # Email notification using global settings
        if [[ -n "${HA_NOTIFY_EMAIL}" ]]; then
            echo -e "${message}" | mail -s "SSH Failover Alert" "${HA_NOTIFY_EMAIL}"
        fi
        
        # Slack notification using global webhook
        if [[ -n "${HA_NOTIFY_SLACK_WEBHOOK}" ]]; then
            local payload="{\"channel\": \"${HA_NOTIFY_SLACK_CHANNEL}\", \"text\": \"${message}\"}"
            curl -X POST -H 'Content-type: application/json' \
                --data "${payload}" "${HA_NOTIFY_SLACK_WEBHOOK}"
        fi
    fi
    
    # Log the event with rotation based on global settings
    log_info "${message}" >> "${HA_LOG_DIR}/failover.log"
    rotate_logs "${HA_LOG_DIR}/failover.log"
}

# Function to rotate logs based on global settings
rotate_logs() {
    local log_file=$1
    local max_size=$((${DEFAULT_MAX_LOG_SIZE:-500} * 1024 * 1024)) # Convert MB to bytes
    
    if [[ -f "${log_file}" ]] && [[ $(stat -f%z "${log_file}") -gt ${max_size} ]]; then
        mv "${log_file}" "${log_file}.$(date +%Y%m%d_%H%M%S)"
        gzip "${log_file}.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Function to verify SSH key permissions based on global security settings
verify_ssh_key_permissions() {
    if [[ -f "${SSH_KEY_PATH}" ]]; then
        current_perms=$(stat -f %Lp "${SSH_KEY_PATH}")
        if [[ "${current_perms}" != "600" ]]; then
            log_warning "SSH key permissions are not secure (${current_perms}). Fixing..."
            chmod 600 "${SSH_KEY_PATH}"
        fi
    else
        log_error "SSH key not found at ${SSH_KEY_PATH}"
        exit 1
    fi
}

# Function to check failback conditions
check_failback() {
    local original_primary="${HA_PRIMARY_HOST}"
    
    # Skip if we're already on the primary
    if [[ "${CURRENT_PRIMARY}" == "${original_primary}" ]]; then
        return 0
    fi
    
    # Check if primary is healthy
    if [[ "${HOST_STATUS[${original_primary}]}" != "healthy" ]]; then
        log_info "Original primary ${original_primary} is not healthy yet"
        return 1
    fi
    
    # Check if we should wait
    if [[ "${HA_REQUIRE_MANUAL_FAILBACK}" == "true" ]]; then
        log_info "Manual failback required for ${original_primary}"
        return 1
    fi
    
    # Check failback delay
    if [[ -n "${FAILOVER_TIME}" ]]; then
        local current_time
        current_time=$(date +%s)
        local elapsed_time=$((current_time - FAILOVER_TIME))
        
        if [[ ${elapsed_time} -lt ${HA_FAILBACK_DELAY} ]]; then
            log_info "Waiting for failback delay (${elapsed_time}/${HA_FAILBACK_DELAY} seconds)"
            return 1
        fi
    fi
    
    # Perform failback
    log_info "Attempting failback to original primary ${original_primary}"
    if perform_failover "${CURRENT_PRIMARY}" "${original_primary}"; then
        log_info "Failback to ${original_primary} completed successfully"
        return 0
    fi
    
    log_error "Failback to ${original_primary} failed"
    return 1
}

# Main function
main() {
    # Check if HA is enabled
    if [[ "${HA_ENABLED}" != "true" ]]; then
        log_error "High Availability is not enabled"
        exit 1
    fi
    
    # Verify SSH key permissions based on global security settings
    verify_ssh_key_permissions
    
    # Load configuration
    if ! check_required_vars; then
        exit 1
    fi
    
    # Set initial primary
    CURRENT_PRIMARY="${HA_PRIMARY_HOST}"
    
    # Process command line arguments
    case "$1" in
        monitor)
            # Continuous monitoring loop
            while true; do
                # Update status for primary host
                update_host_status "${HA_PRIMARY_HOST}" "${HA_PRIMARY_PORT}" "${HA_PRIMARY_USER}"
                
                # Update status for backup hosts
                for ((i=0; i<${#BACKUP_HOSTS[@]}; i++)); do
                    update_host_status "${BACKUP_HOSTS[i]}" "${BACKUP_PORTS[i]}" "${BACKUP_USERS[i]}"
                done
                
                # Check current primary status
                if [[ "${HOST_STATUS[${CURRENT_PRIMARY}]}" != "healthy" ]] && \
                   [[ "${FAILURE_COUNT[${CURRENT_PRIMARY}]}" -ge "${HA_MAX_FAILURES}" ]]; then
                    backup_host=$(get_best_backup)
                    if [[ -n "${backup_host}" ]]; then
                        perform_failover "${CURRENT_PRIMARY}" "${backup_host}"
                    else
                        log_error "No healthy backup hosts available"
                    fi
                fi
                
                # Check failback conditions
                check_failback
                
                sleep "${HA_CHECK_INTERVAL}"
            done
            ;;
        status)
            # Print current status
            echo "Current Primary: ${CURRENT_PRIMARY}"
            for host in "${!HOST_STATUS[@]}"; do
                echo "${host}: ${HOST_STATUS[${host}]}"
            done
            ;;
        failover)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 failover <target_host>"
                exit 1
            fi
            perform_failover "${CURRENT_PRIMARY}" "$2"
            ;;
        *)
            echo "Usage: $0 {monitor|status|failover <target_host>}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
