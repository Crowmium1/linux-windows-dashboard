#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Error handling functions
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    echo -e "${RED}ERROR: ${error_msg}${NC}" >&2
    log_message "ERROR" "$error_msg"
    return $error_code
}

# Trap errors
trap 'handle_error "An error occurred in reboot_monitor.sh on line $LINENO" $?' ERR

# Enhanced logging
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Validate environment
validate_environment() {
    if [ -z "$MONITOR_DIR" ]; then
        handle_error "MONITOR_DIR is not set"
        return 1
    fi
    
    if ! mkdir -p "$MONITOR_DIR" 2>/dev/null; then
        handle_error "Failed to create monitor directory: $MONITOR_DIR"
        return 1
    fi
    
    if ! touch "$LOG_FILE" 2>/dev/null; then
        handle_error "Failed to create log file: $LOG_FILE"
        return 1
    fi
    
    return 0
}

# Enhanced collect_state function
collect_state() {
    local state_file="$1"
    log_message "INFO" "Collecting system state to $state_file"
    
    if [ -z "$state_file" ]; then
        handle_error "No state file specified"
        return 1
    fi
    
    {
        echo "=== System State at $(date) ==="
        echo
        
        local commands=(
            "uptime:uptime"
            "Memory Usage:free -h"
            "Disk Usage:df -h"
            "System Load:cat /proc/loadavg"
            "Process Count:ps aux | wc -l"
            "Network Connections:netstat -tuln"
            "Systemd Failed Units:systemctl --failed"
            "Recent Kernel Messages:dmesg | tail -n 50"
            "System Errors:journalctl -p err..alert -n 50 --no-pager"
        )
        
        for cmd in "${commands[@]}"; do
            local title="${cmd%%:*}"
            local command="${cmd#*:}"
            
            echo "=== $title ==="
            if ! eval "$command" 2>/dev/null; then
                log_message "WARN" "Failed to collect $title"
                echo "Failed to collect $title"
            fi
            echo
        done
    } > "$state_file" 2>&1 || {
        handle_error "Failed to write state to $state_file"
        return 1
    }
    
    log_message "INFO" "State collection completed: $state_file"
    return 0
}

# Enhanced compare_states function
compare_states() {
    local pre_state="$MONITOR_DIR/pre_reboot_state.txt"
    local post_state="$MONITOR_DIR/post_reboot_state.txt"
    local comparison_file="$MONITOR_DIR/state_comparison.txt"
    
    if [ ! -f "$pre_state" ] || [ ! -f "$post_state" ]; then
        handle_error "Missing state files. Run pre and post reboot collections first."
        return 1
    fi
    
    log_message "INFO" "Comparing pre and post reboot states"
    
    {
        echo "=== State Comparison at $(date) ==="
        echo "Comparing $pre_state and $post_state"
        echo
        
        echo "=== Changes in System State ==="
        if ! diff -u "$pre_state" "$post_state"; then
            log_message "WARN" "Found differences in system state"
        else
            log_message "INFO" "No significant changes found"
        fi
    } > "$comparison_file" || {
        handle_error "Failed to write comparison results"
        return 1
    }
    
    return 0
}

# Check arguments
if [ $# -ne 1 ]; then
    handle_error "Usage: $0 [pre|post|compare]"
    exit 1
fi

# Initialize variables
MONITOR_DIR="/var/log/system_monitor"
LOG_FILE="$MONITOR_DIR/reboot_monitor.log"
ACTION="$1"

# Validate environment
if ! validate_environment; then
    exit 1
fi

# Process command
case "$ACTION" in
    "pre")
        log_message "INFO" "Starting pre-reboot state collection"
        if collect_state "$MONITOR_DIR/pre_reboot_state.txt"; then
            echo -e "${GREEN}Pre-reboot state collected successfully${NC}"
        else
            handle_error "Failed to collect pre-reboot state"
            exit 1
        fi
        ;;
    "post")
        log_message "INFO" "Starting post-reboot state collection"
        if collect_state "$MONITOR_DIR/post_reboot_state.txt"; then
            echo -e "${GREEN}Post-reboot state collected successfully${NC}"
            if compare_states; then
                echo -e "${GREEN}State comparison completed${NC}"
            else
                handle_error "Failed to compare states"
                exit 1
            fi
        else
            handle_error "Failed to collect post-reboot state"
            exit 1
        fi
        ;;
    "compare")
        if compare_states; then
            echo -e "${GREEN}State comparison completed${NC}"
            echo "Results available in: $MONITOR_DIR/state_comparison.txt"
        else
            handle_error "Failed to compare states"
            exit 1
        fi
        ;;
    *)
        handle_error "Invalid action: $ACTION"
        exit 1
        ;;
esac

exit 0
