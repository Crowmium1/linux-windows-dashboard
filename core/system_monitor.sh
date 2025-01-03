#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running in test mode
is_test_mode() {
    [ "${TEST_MODE:-0}" = "1" ]
}

# Check if running in WSL
is_wsl() {
    if uname -r | grep -qi microsoft; then
        return 0  # true in bash
    else
        return 1  # false in bash
    fi
}

# Set up logging
setup_logging() {
    if [ -z "${LOG_FILE}" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        if is_test_mode; then
            LOG_FILE="${TEST_LOG_DIR:-/tmp}/system_monitor_${timestamp}.log"
        else
            LOG_FILE="/var/log/system_monitor_${timestamp}.log"
        fi
        export LOG_FILE
    fi
    
    # Create log directory if it doesn't exist
    local log_dir=$(dirname "$LOG_FILE")
    if ! mkdir -p "$log_dir" 2>/dev/null; then
        echo -e "${RED}Error: Failed to create log directory: $log_dir${NC}"
        return 1
    fi
    
    # Test if we can write to the log file
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo -e "${RED}Error: Cannot write to log file: $LOG_FILE${NC}"
        return 1
    fi
}

# Check if running as root
check_root() {
    if is_test_mode; then
        return 0
    fi
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        return 1
    fi
}

# Error handling functions
handle_error() {
    local message="$1"
    local exit_code="${2:-1}"
    
    if is_test_mode; then
        echo "ERROR: $message"
    else
        log "${RED}ERROR: $message${NC}"
    fi
    
    return "$exit_code"
}

# Enhanced logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -z "$LOG_FILE" ]; then
        setup_logging || return 1
    fi
    
    if is_test_mode; then
        echo -e "[${timestamp}] ${message}" >> "$LOG_FILE"
    else
        echo -e "[${timestamp}] ${message}" | tee -a "$LOG_FILE"
    fi
}

# Disable error trap in test mode
if is_test_mode; then
    trap - ERR
else
    trap 'handle_error "An error occurred on line $LINENO" $?' ERR
fi

check_gpu() {
    log "\n${BLUE}=== GPU Status ===${NC}"
    
    # Check if we're in WSL first
    if is_wsl; then
        log "${YELLOW}Warning: Limited GPU information in WSL environment${NC}"
        return 0
    fi
    
    # Check if we're in test mode
    if is_test_mode; then
        log "Test mode: Simulating GPU check"
        return 0
    fi
    
    # Check GPU driver with error handling
    log "\n${YELLOW}GPU Driver:${NC}"
    if ! lspci -nnk | grep -A3 "VGA\|Display" 2>/dev/null; then
        log "${RED}Failed to detect GPU information${NC}"
        return 1
    fi
    
    # Check GPU temperature if sensors is available
    if command -v sensors &> /dev/null; then
        log "\n${YELLOW}GPU Temperature:${NC}"
        sensors | grep -i gpu || true
    fi
    
    # Check GPU utilization if nvidia-smi is available
    if command -v nvidia-smi &> /dev/null; then
        log "\n${YELLOW}GPU Utilization:${NC}"
        nvidia-smi || true
    fi
    
    return 0
}

check_power() {
    log "\n${BLUE}=== Power Management ===${NC}"
    
    # Check TLP status
    log "\n${YELLOW}TLP Status:${NC}"
    tlp-stat -s | tee -a "$LOG_FILE"
    
    # Check CPU frequency scaling
    log "\n${YELLOW}CPU Frequency Scaling:${NC}"
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$cpu: $(cat $cpu 2>/dev/null)" | tee -a "$LOG_FILE"
    done
    
    # Check battery status if laptop
    if [ -d "/sys/class/power_supply/BAT0" ]; then
        log "\n${YELLOW}Battery Status:${NC}"
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | tee -a "$LOG_FILE"
    fi
}

check_thermal() {
    log "\n${BLUE}=== Thermal Status ===${NC}"
    
    # Check temperatures
    log "\n${YELLOW}Temperatures:${NC}"
    sensors | tee -a "$LOG_FILE"
    
    # Check thermald status
    log "\n${YELLOW}Thermald Status:${NC}"
    systemctl status thermald | tee -a "$LOG_FILE"
}

check_services() {
    log "\n${BLUE}=== Service Status ===${NC}"
    
    # Check if systemctl is available
    if ! command -v systemctl &> /dev/null; then
        if is_wsl; then
            log "${YELLOW}Warning: systemctl not available in WSL. Service status checks are limited.${NC}"
            return 0
        else
            log "${RED}Error: systemctl not found. Cannot check service status.${NC}"
            return 1
        fi
    fi
    
    local SERVICES=(
        "bluetooth"
        "tlp"
        "thermald"
        "power-profiles-daemon"
    )
    
    for service in "${SERVICES[@]}"; do
        log "\n${YELLOW}${service} Status:${NC}"
        if is_test_mode; then
            mock_systemctl | tee -a "$LOG_FILE"
        else
            systemctl status "$service" --no-pager | tee -a "$LOG_FILE" || true
        fi
    done
    
    return 0
}

check_kernel_params() {
    log "\n${BLUE}=== Kernel Parameters ===${NC}"
    
    # Check current kernel parameters
    log "\n${YELLOW}Current Kernel Parameters:${NC}"
    cat /proc/cmdline | tee -a "$LOG_FILE"
    
    # Check loaded modules
    log "\n${YELLOW}Loaded GPU Modules:${NC}"
    lsmod | grep -E "i915|intel_guc|intel_huc" | tee -a "$LOG_FILE"
}

check_firmware() {
    log "\n${BLUE}=== Firmware Status ===${NC}"
    
    # Check firmware loading
    log "\n${YELLOW}Firmware Loading Status:${NC}"
    dmesg | grep -i firmware | tail -n 20 | tee -a "$LOG_FILE"
    
    # Check Intel microcode
    log "\n${YELLOW}Intel Microcode:${NC}"
    dmesg | grep -i microcode | tee -a "$LOG_FILE"
}

check_errors() {
    log "\n${BLUE}=== System Errors ===${NC}"
    
    # Check system journal for errors
    log "\n${YELLOW}Recent System Errors:${NC}"
    journalctl -p err..emerg -n 50 --no-pager | tee -a "$LOG_FILE"
    
    # Check GPU errors
    log "\n${YELLOW}GPU Errors:${NC}"
    dmesg | grep -i "error\|fail" | grep -i "i915\|gpu" | tail -n 20 | tee -a "$LOG_FILE"
}

check_dependencies() {
    # In test mode, skip actual dependency checks
    if is_test_mode; then
        log "Test mode: Skipping dependency checks"
        return 0
    fi
    
    local missing_deps=()
    local required_tools=("sensors" "systemctl" "journalctl" "lspci")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            if is_wsl && [[ " lspci sensors " =~ " $tool " ]]; then
                log "${YELLOW}Warning: $tool not available in WSL. Some features will be limited.${NC}"
            else
                missing_deps+=("$tool")
            fi
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "${RED}Missing required tools: ${missing_deps[*]}${NC}"
        log "${YELLOW}Please install missing dependencies:${NC}"
        log "sudo apt install lm-sensors pciutils"
        return 1
    fi
    return 0
}

main() {
    if ! check_root; then
        return 1
    fi
    
    setup_logging
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Initialize log file with proper permissions
    if ! touch "$LOG_FILE" 2>/dev/null; then
        handle_error "Failed to create log file: $LOG_FILE"
        exit 1
    fi
    chmod 640 "$LOG_FILE"
    
    log "${GREEN}Starting system monitoring at $(date)${NC}"
    log "${GREEN}Log file: $LOG_FILE${NC}"
    
    # Run all checks with error handling
    local failed_checks=()
    
    check_gpu || failed_checks+=("GPU")
    check_power || failed_checks+=("Power")
    check_thermal || failed_checks+=("Thermal")
    check_services || failed_checks+=("Services")
    check_kernel_params || failed_checks+=("Kernel")
    check_firmware || failed_checks+=("Firmware")
    check_errors || failed_checks+=("System Errors")
    
    # Summary with error reporting
    log "\n${BLUE}=== Monitor Summary ===${NC}"
    log "Full log available at: $LOG_FILE"
    
    if [ ${#failed_checks[@]} -ne 0 ]; then
        log "\n${RED}The following checks failed: ${failed_checks[*]}${NC}"
        exit 1
    else
        log "\n${GREEN}All checks completed successfully${NC}"
    fi
    
    # Check for critical errors
    ERROR_COUNT=$(grep -c -i "error\|fail" "$LOG_FILE")
    WARNING_COUNT=$(grep -c -i "warning" "$LOG_FILE")
    
    log "\n${YELLOW}Found:${NC}"
    log "- $ERROR_COUNT potential errors"
    log "- $WARNING_COUNT warnings"
    
    if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
        log "\n${GREEN}System appears to be in a healthy state${NC}"
    else
        log "\n${YELLOW}Review the log file for details: $LOG_FILE${NC}"
    fi
}

# Run main function if not sourced
if ! is_test_mode; then
    main
fi
