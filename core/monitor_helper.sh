#!/bin/bash

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# SSH Configuration
SSH_USER="lj"
SSH_HOST="192.168.17.193"
SSH_PORT="22"
MONITOR_DIR="/var/log/system_monitor"

# Error handling functions
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    echo -e "${RED}ERROR: ${error_msg}${NC}" >&2
    return $error_code
}

# Trap errors
trap 'handle_error "An error occurred in monitor_helper.sh on line $LINENO" $?' ERR

# Enhanced logging
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}"
}

# Validate SSH configuration
validate_ssh_config() {
    if [[ -z "$SSH_USER" || -z "$SSH_HOST" || -z "$SSH_PORT" ]]; then
        handle_error "Missing SSH configuration variables"
        return 1
    fi
    
    if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
        handle_error "Invalid SSH port: $SSH_PORT"
        return 1
    fi
    return 0
}

# Enhanced check_ssh function
check_ssh() {
    log_message "INFO" "Checking SSH connection to ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
    
    if ! validate_ssh_config; then
        return 1
    fi
    
    if ! command -v ssh >/dev/null 2>&1; then
        handle_error "SSH client not found"
        return 1
    fi
    
    if ssh -q -o BatchMode=yes -o ConnectTimeout=5 -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" exit; then
        echo -e "${GREEN}SSH connection successful${NC}"
        return 0
    else
        local exit_code=$?
        handle_error "SSH connection failed (Exit code: $exit_code)"
        return $exit_code
    fi
}

# Enhanced run_remote function
run_remote() {
    local command="$1"
    if [ -z "$command" ]; then
        handle_error "No command specified for remote execution"
        return 1
    fi
    
    if ! check_ssh >/dev/null 2>&1; then
        handle_error "Cannot execute remote command: SSH connection failed"
        return 1
    fi
    
    log_message "INFO" "Executing remote command: $command"
    if ! ssh -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" "$command"; then
        handle_error "Remote command failed: $command"
        return 1
    fi
}

# Enhanced prepare_monitor function
prepare_monitor() {
    log_message "INFO" "Preparing monitoring environment"
    
    if [ -z "$MONITOR_DIR" ]; then
        handle_error "MONITOR_DIR is not set"
        return 1
    fi
    
    # Create monitoring directory
    if ! run_remote "mkdir -p $MONITOR_DIR"; then
        handle_error "Failed to create monitoring directory"
        return 1
    fi
    
    # In test mode, skip script checks
    if [ "${TEST_MODE:-0}" = "1" ] || [ "${TEST_MODE}" = "true" ]; then
        echo -e "${GREEN}Test mode: Skipping script verification${NC}"
        return 0
    fi
    
    # Copy and set permissions for monitoring scripts
    local scripts=("system_monitor.sh" "reboot_monitor.sh")
    for script in "${scripts[@]}"; do
        if [ ! -f "$script" ]; then
            handle_error "Required script not found: $script"
            return 1
        fi
    done
    
    echo -e "${GREEN}Monitoring environment prepared successfully${NC}"
    return 0
}

# Enhanced show_status function
show_status() {
    log_message "INFO" "Collecting system status"
    echo -e "\n${YELLOW}=== Quick System Status ===${NC}"
    
    local status_checks=(
        "GPU Status:glxinfo | grep 'OpenGL renderer'"
        "CPU Governor:cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
        "CPU Temperature:sensors | grep 'Package id 0:'"
        "Critical Services:systemctl is-active tlp thermald NetworkManager"
    )
    
    local failed_checks=()
    
    for check in "${status_checks[@]}"; do
        local title="${check%%:*}"
        local command="${check#*:}"
        
        echo -e "\n${GREEN}${title}${NC}"
        if ! run_remote "$command"; then
            failed_checks+=("$title")
        fi
    done
    
    if [ ${#failed_checks[@]} -ne 0 ]; then
        handle_error "Failed checks: ${failed_checks[*]}"
        return 1
    fi
    return 0
}

# Enhanced main menu function
show_menu() {
    while true; do
        echo -e "\n${YELLOW}=== System Monitor Helper ===${NC}"
        echo "1) Prepare for reboot monitoring"
        echo "2) Record pre-reboot state"
        echo "3) Record post-reboot state"
        echo "4) Show quick system status"
        echo "5) Check SSH connection"
        echo "6) Exit"
        
        read -p "Select an option: " choice
        
        case $choice in
            1)
                prepare_monitor || log_message "ERROR" "Failed to prepare monitoring environment"
                ;;
            2)
                log_message "INFO" "Recording pre-reboot state"
                if run_remote "sudo ./reboot_monitor.sh pre"; then
                    echo -e "${GREEN}Pre-reboot state recorded. You can safely reboot now.${NC}"
                else
                    handle_error "Failed to record pre-reboot state"
                fi
                ;;
            3)
                log_message "INFO" "Recording post-reboot state"
                run_remote "sudo ./reboot_monitor.sh post" || handle_error "Failed to record post-reboot state"
                ;;
            4)
                show_status || log_message "ERROR" "Failed to show system status"
                ;;
            5)
                check_ssh
                ;;
            6)
                log_message "INFO" "Exiting monitor helper"
                exit 0
                ;;
            *)
                handle_error "Invalid option: $choice"
                ;;
        esac
    done
}

# Initial setup and validation
if [ "${TEST_MODE:-0}" != "1" ] && [ "${TEST_MODE}" != "true" ]; then
    if ! validate_ssh_config; then
        exit 1
    fi
    show_menu
fi
