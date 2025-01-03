#!/bin/bash

# Exit on error
set -e

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source utility functions
source "${ROOT_DIR}/utils/utils.sh"

# Default values
TOOLKIT_DIR="${ROOT_DIR}/ssh"
export TEST_MODE=${TEST_MODE:-0}
CONFIG_FILE="${ROOT_DIR}/config/main_config.conf"
VALIDATE_ONLY=""

# Debug output for test mode
if [ "$TEST_MODE" = "1" ]; then
    echo "Running in TEST_MODE"
    echo "ROOT_DIR: $ROOT_DIR"
    echo "CONFIG_FILE: $CONFIG_FILE"
fi

# Required files
CORE_FILES=(
    "system_monitor.sh"
    "collect_system_info.sh"
    "monitor_helper.sh"
)

UTILS_FILES=(
    "utils.sh"
    "keyring_diagnostic.sh"
    "cleanup.sh"
)

SSH_FILES=(
    "ssh_manager.sh"
    "setup_environment.sh"
    "setup_passwordless_ssh.sh"
    "ssh_recovery_tools.sh"
    "sync_helper.sh"
    "logout.sh"
)

CONFIG_FILES=(
    "main_config.conf"
    "ssh_config"
)

# Function to validate toolkit
validate_toolkit() {
    local toolkit_dir="$1"
    
    # Check required directories
    local required_dirs=(
        "${ROOT_DIR}/var/log"
        "${ROOT_DIR}/var/tmp"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
    
    # Check core files
    for file in "${CORE_FILES[@]}"; do
        if [ ! -f "${toolkit_dir}/$(basename "$file")" ]; then
            echo "Missing core file: $(basename "$file")"
            return 1
        fi
    done
    
    # Check utils files
    for file in "${UTILS_FILES[@]}"; do
        if [ ! -f "${toolkit_dir}/$(basename "$file")" ]; then
            echo "Missing utils file: $(basename "$file")"
            return 1
        fi
    done
    
    # Check SSH files
    for file in "${SSH_FILES[@]}"; do
        if [ ! -f "${toolkit_dir}/$(basename "$file")" ]; then
            echo "Missing SSH file: $(basename "$file")"
            return 1
        fi
    done
    
    # Check config files
    for file in "${CONFIG_FILES[@]}"; do
        if [ ! -f "${toolkit_dir}/$(basename "$file")" ]; then
            echo "Missing config file: $(basename "$file")"
            return 1
        fi
    done
    
    return 0
}

# Function to check directory permissions
check_permissions() {
    local dir="$1"
    if [ ! -w "$dir" ]; then
        echo "Error: Directory not writable: $dir"
        return 1
    fi
    return 0
}

# Function to clean directory
clean_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        rm -rf "${dir:?}/"*
    else
        mkdir -p "$dir"
    fi
}

# Function to copy file with error handling
copy_file() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ ! -f "$src" ]; then
        echo "Error: $name not found: $src"
        return 1
    fi
    
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest" || {
        echo "Error: Failed to copy $name"
        return 1
    }
    chmod +x "$dest" 2>/dev/null || true  # Make executable if it's a script
    return 0
}

# Main script
main() {
    # Validate arguments
    if [ -n "$CONFIG_FILE" ] && [ ! -f "$CONFIG_FILE" ]; then
        error_exit "Config file not found: $CONFIG_FILE"
    fi
    
    # Load config if provided
    if [ -n "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    # Set up logging
    LOG_FILE="${ROOT_DIR}/var/log/orchestrator.log"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    
    # Validate toolkit
    validate_toolkit "$TOOLKIT_DIR"
    
    # Only validate if requested
    if [ -n "$VALIDATE_ONLY" ]; then
        log_info "Validation completed successfully"
        exit 0
    fi
    
    # Check if parent directory exists and is writable
    local parent_dir
    parent_dir="$(dirname "$TOOLKIT_DIR")"
    
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir" || {
            echo "Error: Cannot create parent directory: $parent_dir"
            exit 1
        }
    fi
    
    if ! check_permissions "$parent_dir"; then
        exit 1
    fi
    
    # Check if tools directory exists (test requirement)
    if [ ! -d "$ROOT_DIR/tests/tools" ]; then
        echo "Error: Required tools directory not found"
        exit 1
    fi
    
    # Clean and recreate toolkit directory
    if ! clean_directory "$TOOLKIT_DIR"; then
        exit 1
    fi
    
    # Copy core files
    for file in "${CORE_FILES[@]}"; do
        if ! copy_file "$ROOT_DIR/core/$file" "$TOOLKIT_DIR/$(basename "$file")" "Core file ($file)"; then
            exit 1
        fi
    done
    
    # Copy utils files
    for file in "${UTILS_FILES[@]}"; do
        if ! copy_file "$ROOT_DIR/utils/$file" "$TOOLKIT_DIR/$(basename "$file")" "Utils file ($file)"; then
            exit 1
        fi
    done
    
    # Copy SSH files
    for file in "${SSH_FILES[@]}"; do
        if ! copy_file "$ROOT_DIR/ssh/$file" "$TOOLKIT_DIR/$(basename "$file")" "SSH file ($file)"; then
            exit 1
        fi
    done
    
    # Copy config files
    for file in "${CONFIG_FILES[@]}"; do
        if ! copy_file "$ROOT_DIR/config/$file" "$TOOLKIT_DIR/$(basename "$file")" "Config file ($file)"; then
            exit 1
        fi
    done
    
    # Create control script content
    cat > "$TOOLKIT_DIR/ssh_control.sh" << 'EOF'
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# SSH connection details
SSH_USER="lj"
SSH_HOST="192.168.17.193"

# Function to check SSH connection
check_ssh() {
    ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${SSH_USER}@${SSH_HOST}" exit
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}SSH connection failed${NC}"
        return 1
    fi
}

# Main menu
show_menu() {
    clear
    echo -e "${YELLOW}=== SSH Control Center ===${NC}"
    echo "1) System Monitoring"
    echo "2) Environment Setup"
    echo "3) Passwordless SSH Setup"
    echo "4) SSH Recovery Tools"
    echo "5) Sync Helper"
    echo "6) Logout"
    echo "7) Exit"
    
    read -p "Select an option: " choice
    
    case $choice in
        1)
            ./system_monitor.sh
            ;;
        2)
            ./setup_environment.sh
            ;;
        3)
            ./setup_passwordless_ssh.sh
            ;;
        4)
            ./ssh_recovery_tools.sh
            ;;
        5)
            ./sync_helper.sh
            ;;
        6)
            ./logout.sh
            ;;
        7)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

# Check SSH connection before starting
if ! check_ssh; then
    echo -e "${RED}Cannot connect to SSH host. Some features may be limited.${NC}"
    sleep 2
fi

# Start menu
while true; do
    show_menu
    read -p "Press Enter to continue..."
done
EOF
    
    # Make scripts executable
    find "$TOOLKIT_DIR" -type f -name "*.sh" -exec chmod +x {} \; || {
        echo "Error: Failed to set executable permissions"
        exit 1
    }
    
    # Validate the toolkit after creation
    if ! validate_toolkit "$TOOLKIT_DIR"; then
        echo "Error: Toolkit validation failed"
        exit 1
    fi
    
    echo "SSH toolkit prepared. Use ./$TOOLKIT_DIR/ssh_control.sh to start"
    return 0
}

# Run main function
main "$@"
