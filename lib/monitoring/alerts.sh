#!/bin/bash

# Alert management for SSH Dashboard Monitor
# Handles alert generation, notification, and history management

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load alert configuration
ALERT_CONFIG="${SCRIPT_DIR}/../../config/monitoring/alerts.yaml"

# Global variables
ALERT_HISTORY=()
MAX_HISTORY_SIZE=1000

# Function to load alert configuration
load_alert_config() {
    if [[ ! -f "${ALERT_CONFIG}" ]]; then
        log_error "Alert configuration not found: ${ALERT_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${ALERT_CONFIG}")"
}

# Function to send email notification
send_email_alert() {
    local subject=$1
    local message=$2
    
    if [[ "${notification_channels_email_enabled}" != "true" ]]; then
        return 0
    fi
    
    # Prepare email content
    local email_content="Subject: ${subject}\n\n${message}"
    
    # Send email using configured SMTP server
    echo -e "${email_content}" | sendmail -f "${notification_channels_email_from_address}" "${notification_channels_email_to_addresses}"
}

# Function to send Slack notification
send_slack_alert() {
    local message=$1
    
    if [[ "${notification_channels_slack_enabled}" != "true" ]]; then
        return 0
    fi
    
    # Prepare JSON payload
    local payload="{\"channel\": \"${notification_channels_slack_channel}\", \"username\": \"${notification_channels_slack_username}\", \"text\": \"${message}\"}"
    
    # Send to Slack webhook
    curl -X POST -H 'Content-type: application/json' --data "${payload}" "${notification_channels_slack_webhook_url}"
}

# Function to check threshold
check_threshold() {
    local metric=$1
    local value=$2
    local threshold=$3
    
    if (( $(echo "${value} > ${threshold}" | bc -l) )); then
        return 0
    fi
    return 1
}

# Function to generate alert
generate_alert() {
    local alert_type=$1
    local message=$2
    local severity=$3
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create alert object
    local alert="{\"type\": \"${alert_type}\", \"message\": \"${message}\", \"severity\": \"${severity}\", \"timestamp\": \"${timestamp}\"}"
    
    # Add to history
    ALERT_HISTORY+=("${alert}")
    
    # Trim history if needed
    if [[ ${#ALERT_HISTORY[@]} -gt ${MAX_HISTORY_SIZE} ]]; then
        ALERT_HISTORY=("${ALERT_HISTORY[@]:1}")
    fi
    
    # Log alert
    log_warning "Alert generated: ${message}"
    
    # Send notifications based on channels
    if [[ " ${rules_${alert_type}_channels[*]} " =~ " email " ]]; then
        send_email_alert "[SSH Dashboard] ${severity}: ${alert_type}" "${message}"
    fi
    
    if [[ " ${rules_${alert_type}_channels[*]} " =~ " slack " ]]; then
        send_slack_alert "${message}"
    fi
}

# Function to check connection alerts
check_connection_alerts() {
    local latency=$1
    local failed_attempts=$2
    
    # Check latency threshold
    if check_threshold "latency" "${latency}" "${thresholds_connection_latency_ms}"; then
        generate_alert "high_latency" "High latency detected: ${latency}ms" "warning"
    fi
    
    # Check failed attempts
    if [[ ${failed_attempts} -ge ${thresholds_connection_failed_attempts} ]]; then
        generate_alert "connection_failed" "Multiple connection failures detected: ${failed_attempts}" "critical"
    fi
}

# Function to check service alerts
check_service_alerts() {
    local service_name=$1
    local status=$2
    local restart_count=$3
    
    # Check service status
    if [[ "${status}" != "active" ]]; then
        generate_alert "service_down" "Service ${service_name} is down" "critical"
    fi
    
    # Check restart count
    if [[ ${restart_count} -ge ${thresholds_service_restart_count} ]]; then
        generate_alert "service_unstable" "Service ${service_name} has restarted ${restart_count} times" "warning"
    fi
}

# Function to save alert history
save_alert_history() {
    local history_file="${history_log_file}"
    
    # Create directory if needed
    mkdir -p "$(dirname "${history_file}")"
    
    # Save history to file
    printf "%s\n" "${ALERT_HISTORY[@]}" > "${history_file}"
}

# Main function
main() {
    # Load configuration
    if ! load_alert_config; then
        exit 1
    fi
    
    # Process command line arguments
    case "$1" in
        check-connection)
            check_connection_alerts "$2" "$3"
            ;;
        check-service)
            check_service_alerts "$2" "$3" "$4"
            ;;
        save-history)
            save_alert_history
            ;;
        *)
            echo "Usage: $0 {check-connection <latency> <failed_attempts>|check-service <name> <status> <restart_count>|save-history}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi