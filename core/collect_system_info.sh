#!/bin/bash

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/utils.sh"

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
    return $error_code
}

# Trap errors
trap 'handle_error "An error occurred in collect_system_info.sh on line $LINENO" $?' ERR

# Error handling
set -e  # Exit on error
trap 'cleanup' EXIT
trap 'handle_interrupt' INT TERM

# Global variables
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEFAULT_OUTDIR="ssh_details_${TIMESTAMP}"
OUTPUT_DIR=""
CLEANUP_NEEDED=0

# Cleanup function
cleanup() {
    local exit_code=$?
    if [ "$CLEANUP_NEEDED" -eq 1 ] && [ "${TEST_MODE:-0}" != "1" ] && [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
    fi
    exit $exit_code
}

# Handle interrupt
handle_interrupt() {
    echo -e "\n${RED}Script interrupted by user${NC}"
    CLEANUP_NEEDED=1
    cleanup
    exit 1
}

# Check directory permissions
check_directory_permissions() {
    local dir="$1"
    if ! mkdir -p "$dir" 2>/dev/null; then
        echo -e "${RED}Error: Cannot create directory $dir${NC}"
        return 1
    fi
    if ! touch "$dir/.test_write" 2>/dev/null; then
        echo -e "${RED}Error: Cannot write to directory $dir${NC}"
        return 1
    fi
    rm -f "$dir/.test_write"
    return 0
}

# Check disk space
check_disk_space() {
    local required_space=10240  # 10MB in KB
    local available_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt "$required_space" ]; then
        echo -e "${RED}Error: Insufficient disk space. Need at least 10MB${NC}"
        return 1
    fi
    return 0
}

# Function to run command with timeout
run_with_timeout() {
    local cmd="$1"
    timeout $TIMEOUT_DURATION bash -c "$cmd" 2>/dev/null
    return $?
}

# Function to check if command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        if is_wsl && [[ " lspci lsusb dmidecode " =~ " $cmd " ]]; then
            echo -e "${YELLOW}Warning: $cmd not available in WSL. Some hardware info will be limited.${NC}"
        else
            echo -e "${YELLOW}Warning: $cmd is not installed${NC}"
            if [[ " netstat ss " =~ " $cmd " ]]; then
                echo "Consider installing net-tools package for netstat or iproute2 for ss"
            fi
        fi
        return 1
    fi
    return 0
}

# Function to check if we should run sudo commands
can_run_sudo() {
    # Skip sudo in test mode with SUDO_TEST flag
    if [ "${TEST_MODE:-0}" = "1" ] && [ "${SUDO_TEST:-0}" = "1" ]; then
        echo "Skipping sudo in SUDO_TEST mode"
        return 1
    fi
    # Skip sudo in test mode
    if [ "${TEST_MODE:-0}" = "1" ]; then
        return 1
    fi
    # Check if we can use sudo without password
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    return 1
}

# Function to run command and save output
collect() {
    local command="$1"
    local output_file="$2"
    local main_tool="${command%% *}"
    
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo -e "${RED}Error: Output directory does not exist${NC}"
        return 1
    fi
    
    # Skip sudo commands in test mode
    if [ "${TEST_MODE:-0}" = "1" ] && [[ "$command" == sudo* ]]; then
        echo "Skipping sudo command in test mode: $command"
        echo "Command: $command (SKIPPED IN TEST MODE)" > "$OUTPUT_DIR/$output_file"
        return 0
    fi
    
    # Skip if the main command doesn't exist
    if ! check_command "$main_tool"; then
        echo "Command: $command (NOT AVAILABLE)" > "$OUTPUT_DIR/$output_file"
        echo "Tool '$main_tool' is not installed" >> "$OUTPUT_DIR/$output_file"
        return 0
    fi
    
    echo "Running: $command"
    echo "Command: $command" > "$OUTPUT_DIR/$output_file"
    echo "----------------------------------------" >> "$OUTPUT_DIR/$output_file"
    
    if ! run_with_timeout "$command" >> "$OUTPUT_DIR/$output_file" 2>&1; then
        echo -e "${YELLOW}Warning: Command failed: $command${NC}"
        echo "Warning: Command failed or timed out" >> "$OUTPUT_DIR/$output_file"
        return 0
    fi
    
    echo -e "\n" >> "$OUTPUT_DIR/$output_file"
    return 0
}

# Create output files with proper permissions
create_output_file() {
    local filename="$1"
    if ! touch "$filename" 2>/dev/null; then
        echo -e "${RED}Error: Could not create $filename${NC}"
        return 1
    fi
    if ! chmod 644 "$filename" 2>/dev/null; then
        echo -e "${RED}Error: Could not set permissions on $filename${NC}"
        return 1
    fi
    return 0
}

# Create test files with mock data
create_test_files() {
    local output_dir="$1"
    echo "Creating test files..."
    
    # Create summary file
    cat > "$output_dir/00_summary.txt" << EOL
=== System Information Summary ===
Hostname: test-host
OS: Ubuntu 20.04
Kernel: 5.4.0
CPU: Intel(R) Core(TM) i7
Memory: 16GB
Disk: 500GB
Network: eth0, wlan0
EOL
    
    # Create network config
    echo "eth0: 192.168.1.100" > "$output_dir/01_network_config.txt"
    
    # Create open ports
    echo "22, 80, 443" > "$output_dir/02_open_ports.txt"
    
    # Create memory status
    echo "Available: 8GB" > "$output_dir/08_memory_status.txt"
    
    # Create disk usage
    echo "Used: 50%" > "$output_dir/09_disk_usage.txt"
    
    # List created files
    echo "Listing test files:"
    ls -l "$output_dir"
}

# Print usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --test-mode              Run in test mode"
    echo "  --config=FILE            Use specified config file"
    echo "  --output-dir=DIR         Use specified output directory"
    echo "  --archive                Create archive of existing files"
    echo "  --cleanup                Clean up old files"
    echo "  --retention-days=DAYS    Number of days to retain files (default: 7)"
    exit 1
}

# Validate environment and arguments
validate_args() {
    local config_file="$1"
    local output_dir="$2"
    local do_archive="$3"
    local do_cleanup="$4"
    
    # Either archive or cleanup must be specified
    if [ "$do_archive" -eq 0 ] && [ "$do_cleanup" -eq 0 ]; then
        handle_error "Either --archive or --cleanup must be specified"
        print_usage
    fi
    
    # If config file specified, it must exist
    if [ -n "$config_file" ] && [ ! -f "$config_file" ]; then
        handle_error "Config file does not exist: $config_file"
        return 1
    fi
    
    # If output directory specified, it must be writable
    if [ -n "$output_dir" ] && [ ! -w "$(dirname "$output_dir")" ]; then
        handle_error "Output directory is not writable: $(dirname "$output_dir")"
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    local test_mode=0
    local config_file=""
    local output_dir=""
    local do_archive=0
    local do_cleanup=0
    local retention_days=7  # Default retention period
    
    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        handle_error "No arguments provided"
        print_usage
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-mode)
                test_mode=1
                shift
                ;;
            --config=*)
                config_file="${1#*=}"
                shift
                ;;
            --output-dir=*)
                output_dir="${1#*=}"
                shift
                ;;
            --archive)
                do_archive=1
                CLEANUP_NEEDED=0  # Don't clean up when archiving
                shift
                ;;
            --cleanup)
                do_cleanup=1
                CLEANUP_NEEDED=1  # Clean up when doing cleanup
                shift
                ;;
            --retention-days=*)
                retention_days="${1#*=}"
                shift
                ;;
            --help)
                print_usage
                ;;
            *)
                handle_error "Unknown option: $1"
                print_usage
                ;;
        esac
    done
    
    # Validate arguments
    validate_args "$config_file" "$output_dir" "$do_archive" "$do_cleanup" || exit 1
    
    # Load config if provided
    if [ -n "$config_file" ] && [ -f "$config_file" ]; then
        source "$config_file"
        # Allow config file to override retention days
        if [ -n "$RETENTION_DAYS" ]; then
            retention_days="$RETENTION_DAYS"
        fi
    fi
    
    # Set default output directory if not specified
    if [ -z "$output_dir" ]; then
        if [ -n "$DATA_DIR" ]; then
            output_dir="$DATA_DIR/test_output"
        else
            output_dir="test_output"
        fi
    fi
    
    if [ "$test_mode" = "1" ]; then
        echo "Running in test mode"
    fi
    
    # Handle cleanup
    if [ "$do_cleanup" = "1" ]; then
        echo "Cleaning up old files..."
        cleanup_old_files "$output_dir" "$retention_days"
        return $?
    fi
    
    # Handle archiving
    if [ "$do_archive" = "1" ]; then
        echo "Creating archive of existing files..."
        local archive_name="$output_dir/archive_$(date +%Y%m%d_%H%M%S).tar.gz"
        create_archive "$output_dir" "$archive_name"
        return $?
    fi
    
    # Create output directory
    echo "Creating directory: $output_dir"
    mkdir -p "$output_dir"
    
    if [ "$test_mode" = "1" ]; then
        create_test_files "$output_dir"
    else
        # Check prerequisites
        echo "Checking directory permissions..."
        if ! check_directory_permissions "$output_dir"; then
            echo -e "${RED}Error: Directory permission check failed${NC}"
            exit 1
        fi
        
        echo "Checking disk space..."
        if ! check_disk_space; then
            echo -e "${RED}Error: Disk space check failed${NC}"
            exit 1
        fi
        
        # Create output directory with secure permissions
        echo "Creating output directory..."
        if ! mkdir -p "$output_dir"; then
            echo -e "${RED}Error: Could not create output directory${NC}"
            exit 1
        fi
        if ! chmod 755 "$output_dir"; then
            echo -e "${RED}Error: Could not set directory permissions${NC}"
            exit 1
        fi
        
        # Create a test file to verify we can write
        echo "Creating test file..."
        if ! echo "Test content" > "$output_dir/test.txt"; then
            echo -e "${RED}Error: Could not write to output directory${NC}"
            exit 1
        fi
        
        # In SUDO_TEST mode, exit successfully after creating test file
        if [ "${SUDO_TEST:-0}" = "1" ]; then
            echo "SUDO_TEST mode: Test file created successfully"
            sync  # Ensure file is written to disk
            exit 0
        fi
        
        # Now collect the data
        echo "Collecting system information..."
        # Network Configuration
        collect "ip addr show" "01_network_config.txt"
        collect "netstat -tuln" "02_open_ports.txt"
        if can_run_sudo; then
            collect "sudo systemctl status ssh" "03_ssh_status.txt"
            collect "sudo ufw status" "04_firewall_status.txt"
        else
            collect "systemctl status ssh" "03_ssh_status.txt"
            collect "ufw status" "04_firewall_status.txt"
        fi
        collect "cat /etc/ssh/sshd_config" "05_ssh_config.txt"
        collect "hostname -I" "06_ip_addresses.txt"
        
        # System Health
        collect "top -b -n 1" "07_process_status.txt"
        collect "free -h" "08_memory_status.txt"
        collect "df -h" "09_disk_usage.txt"
        collect "vmstat 1 5" "10_virtual_memory.txt"
        collect "uptime" "11_system_uptime.txt"
        collect "dmesg | tail -n 100" "12_system_messages.txt"
        
        # Hardware Information
        if check_command lspci; then
            collect "lspci" "13_pci_devices.txt"
        fi
        if check_command lsusb; then
            collect "lsusb" "14_usb_devices.txt"
        fi
        if check_command dmidecode; then
            if can_run_sudo; then
                collect "sudo dmidecode" "15_hardware_info.txt"
            else
                collect "dmidecode" "15_hardware_info.txt"
            fi
        fi
        collect "lscpu" "16_cpu_info.txt"
        collect "cat /proc/cpuinfo" "17_detailed_cpu.txt"
        
        # GPU Status
        collect "glxinfo | grep -i renderer" "18_gpu_renderer.txt"
        collect "vulkaninfo --summary" "19_vulkan_info.txt"
        collect "vainfo" "20_vaapi_info.txt"
        if can_run_sudo; then
            collect "sudo lshw -C display" "21_display_info.txt"
        else
            collect "lshw -C display" "21_display_info.txt"
        fi
        
        # Power Management
        if can_run_sudo; then
            collect "sudo tlp-stat -s" "22_tlp_status.txt"
        else
            collect "tlp-stat -s" "22_tlp_status.txt"
        fi
        collect "cat /sys/class/power_supply/*/status" "23_power_status.txt"
        collect "cat /proc/acpi/wakeup" "24_wakeup_status.txt"
        if can_run_sudo; then
            collect "sudo powertop --dump" "25_power_analysis.txt"
        else
            collect "powertop --dump" "25_power_analysis.txt"
        fi
        
        # Thermal and Fans
        collect "sensors" "26_temperature.txt"
        collect "cat /proc/acpi/thermal_zone/*/temperature" "27_thermal_zones.txt"
        collect "cat /sys/class/thermal/thermal_zone*/temp" "28_thermal_temps.txt"
        
        # System Configuration
        collect "cat /etc/default/grub" "29_grub_config.txt"
        collect "cat /proc/cmdline" "30_kernel_params.txt"
        collect "ls -la /etc/modprobe.d/" "31_modprobe_configs.txt"
        collect "systemctl list-units --type=service" "32_services.txt"
        if can_run_sudo; then
            collect "sudo journalctl -p err..emerg -n 100" "33_system_errors.txt"
        else
            collect "journalctl -p err..emerg -n 100" "33_system_errors.txt"
        fi
        
        # Dependencies and Packages
        collect "dpkg -l | grep -i intel" "34_intel_packages.txt"
        collect "dpkg -l | grep -i mesa" "35_mesa_packages.txt"
        collect "dpkg -l | grep -i vulkan" "36_vulkan_packages.txt"
        collect "apt list --installed" "37_installed_packages.txt"
        collect "ldd $(which glxinfo) | grep -i gl" "38_gl_dependencies.txt"
        
        # Network Performance
        collect "ping -c 4 8.8.8.8" "39_internet_connectivity.txt"
        collect "traceroute 8.8.8.8" "40_network_route.txt"
        collect "iwconfig" "41_wireless_info.txt"
        collect "nmcli dev wifi list" "42_wifi_networks.txt"
        
        # Create summary file
        {
            echo "System Information Summary"
            echo "========================="
            echo "Timestamp: $(date)"
            echo "Hostname: $(hostname)"
            echo "Kernel: $(uname -r)"
            echo "Distribution: $(lsb_release -d)"
            echo "IP Address: $(hostname -I)"
            echo "SSH Status: $(systemctl is-active ssh)"
            echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
            echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
            echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
            echo "GPU Driver: $(glxinfo | grep "OpenGL renderer" | head -n1)"
        } > "$output_dir/00_summary.txt"
        
        # Create the archive with proper permissions
        echo "Creating final archive..."
        archive_name="$output_dir/ssh_details_${TIMESTAMP}.tar.gz"
        
        # Convert Windows path to WSL path if needed
        if [[ "$archive_name" == "/mnt/c/"* ]]; then
            # We're in WSL, using a Windows path
            windows_path=$(echo "$archive_name" | sed 's|^/mnt/c|C:|' | sed 's|/|\\|g')
            echo "Windows path: $windows_path"
            archive_name="$windows_path"
        fi
        
        if ! tar -czf "$archive_name" "$output_dir" 2>/dev/null; then
            echo -e "${RED}Error: Failed to create archive${NC}"
            exit 1
        fi
        
        # Double check permissions
        echo "Setting final permissions..."
        if ! chmod 644 "$archive_name"; then
            echo -e "${RED}Error: Could not set archive permissions${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Collection complete. Files are in $archive_name${NC}"
        echo "Extract with: tar -xzf $archive_name"
        return 0
    fi
    
    # Create archive
    echo "Creating archive: test_archive.tar.gz in directory: $output_dir"
    pwd
    cd "$output_dir" || exit 1
    tar -czf test_archive.tar.gz ./*.txt
    echo "Test archive created at: $output_dir/test_archive.tar.gz"
    ls -l test_archive.tar.gz
}

main "$@"
