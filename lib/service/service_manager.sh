#!/bin/bash

# Service Manager for SSH Dashboard
# Handles service lifecycle and health checks

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load service configuration
SERVICE_CONFIG="${SCRIPT_DIR}/../../config/service/service.yaml"

# Global variables
declare -A SERVICE_STATUS
SERVICE_LOCK_FILE="${HA_STATE_DIR}/service.lock"
LAST_CHECK_TIME=0

# Function to load service configuration
load_service_config() {
    if [[ ! -f "${SERVICE_CONFIG}" ]]; then
        log_error "Service configuration not found: ${SERVICE_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${SERVICE_CONFIG}")"
}

# Function to acquire service lock
acquire_service_lock() {
    if [[ -f "${SERVICE_LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${SERVICE_LOCK_FILE}")
        if kill -0 "${lock_pid}" 2>/dev/null; then
            log_warning "Service operation already in progress (PID: ${lock_pid})"
            return 1
        fi
        rm -f "${SERVICE_LOCK_FILE}"
    fi
    
    echo $$ > "${SERVICE_LOCK_FILE}"
    return 0
}

# Function to release service lock
release_service_lock() {
    rm -f "${SERVICE_LOCK_FILE}"
}

# Function to check service dependencies
check_dependencies() {
    local service=$1
    
    # Check required commands
    for cmd in "${service_dependencies_commands[@]}"; do
        if ! check_command "$cmd"; then
            log_error "Missing required command: $cmd"
            return 1
        fi
    done
    
    # Check required services
    for dep in "${service_dependencies_services[@]}"; do
        if ! systemctl is-active --quiet "$dep"; then
            log_error "Required service not running: $dep"
            return 1
        fi
    done
    
    return 0
}

# Function to validate service configuration
validate_service_config() {
    local service=$1
    
    # Check required directories
    for dir in "${HA_LOG_DIR}" "${HA_STATE_DIR}" "${HA_TEMP_DIR}"; do
        if ! check_directory_permissions "$dir"; then
            log_error "Invalid directory permissions: $dir"
            return 1
        fi
    done
    
    # Check SSH key permissions
    if ! validate_ssh_key "${SSH_KEY_PATH}"; then
        log_error "Invalid SSH key permissions"
        return 1
    fi
    
    return 0
}

# Function to start service
start_service() {
    local service=$1
    
    log_info "Starting service: $service"
    
    # Check dependencies
    if ! check_dependencies "$service"; then
        log_error "Failed to start $service: dependency check failed"
        return 1
    fi
    
    # Validate configuration
    if ! validate_service_config "$service"; then
        log_error "Failed to start $service: invalid configuration"
        return 1
    fi
    
    # Start the service
    if ! systemctl start "$service"; then
        log_error "Failed to start $service"
        return 1
    fi
    
    # Update status
    SERVICE_STATUS["$service"]="running"
    log_info "Service started successfully: $service"
    return 0
}

# Function to stop service
stop_service() {
    local service=$1
    
    log_info "Stopping service: $service"
    
    # Stop the service
    if ! systemctl stop "$service"; then
        log_error "Failed to stop $service"
        return 1
    fi
    
    # Update status
    SERVICE_STATUS["$service"]="stopped"
    log_info "Service stopped successfully: $service"
    return 0
}

# Function to restart service
restart_service() {
    local service=$1
    
    log_info "Restarting service: $service"
    
    if ! stop_service "$service"; then
        log_error "Failed to stop $service during restart"
        return 1
    fi
    
    # Small delay to ensure clean shutdown
    sleep 2
    
    if ! start_service "$service"; then
        log_error "Failed to start $service during restart"
        return 1
    fi
    
    log_info "Service restarted successfully: $service"
    return 0
}

# Function to check service health
check_service_health() {
    local service=$1
    
    # Check if service is running
    if ! systemctl is-active --quiet "$service"; then
        SERVICE_STATUS["$service"]="stopped"
        return 1
    fi
    
    # Check service-specific health indicators
    case "$service" in
        ssh-ha.service)
            # Check HA components
            if ! check_port "localhost" "${SSH_PORT}"; then
                SERVICE_STATUS["$service"]="degraded"
                return 1
            fi
            ;;
        ssh-monitor.service)
            # Check monitoring components
            if ! check_port "localhost" "${MONITOR_PORT}"; then
                SERVICE_STATUS["$service"]="degraded"
                return 1
            fi
            ;;
        *)
            # Generic service check
            if ! systemctl status "$service" >/dev/null 2>&1; then
                SERVICE_STATUS["$service"]="degraded"
                return 1
            fi
            ;;
    esac
    
    SERVICE_STATUS["$service"]="healthy"
    return 0
}

# Function to get service status report
get_service_report() {
    local report=""
    report+="Service Status Report\n"
    report+="Last check: $(date -d @${LAST_CHECK_TIME} '+%Y-%m-%d %H:%M:%S')\n\n"
    
    # Service Status
    report+="Service Status:\n"
    for service in "${!SERVICE_STATUS[@]}"; do
        report+="  ${service}: ${SERVICE_STATUS[${service}]}\n"
        
        # Add service-specific details
        case "$service" in
            ssh-ha.service)
                report+="    HA Status: $(get_ha_status)\n"
                ;;
            ssh-monitor.service)
                report+="    Monitor Status: $(get_monitor_status)\n"
                ;;
        esac
    done
    
    # Resource Usage
    report+="\nResource Usage:\n"
    for service in "${!SERVICE_STATUS[@]}"; do
        local pid
        pid=$(systemctl show -p MainPID "$service" | cut -d= -f2)
        if [ "$pid" -gt 0 ]; then
            report+="  ${service}:\n"
            report+="    CPU: $(ps -p "$pid" -o %cpu=)%\n"
            report+="    Memory: $(ps -p "$pid" -o %mem=)%\n"
        fi
    done
    
    echo -e "${report}"
}

# Function to get HA status
get_ha_status() {
    if [[ -f "${HA_STATE_DIR}/ha_status" ]]; then
        cat "${HA_STATE_DIR}/ha_status"
    else
        echo "unknown"
    fi
}

# Function to get monitor status
get_monitor_status() {
    if [[ -f "${HA_STATE_DIR}/monitor_status" ]]; then
        cat "${HA_STATE_DIR}/monitor_status"
    else
        echo "unknown"
    fi
}

# Main function
main() {
    # Load configuration
    if ! load_service_config; then
        exit 1
    fi
    
    # Create required directories
    mkdir -p "${HA_LOG_DIR}/service" "${HA_STATE_DIR}"
    
    # Process command line arguments
    case "$1" in
        start)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 start <service>"
                exit 1
            fi
            start_service "$2"
            ;;
        stop)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 stop <service>"
                exit 1
            fi
            stop_service "$2"
            ;;
        restart)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 restart <service>"
                exit 1
            fi
            restart_service "$2"
            ;;
        status)
            get_service_report
            ;;
        check)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 check <service>"
                exit 1
            fi
            check_service_health "$2"
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|check} [service]"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
