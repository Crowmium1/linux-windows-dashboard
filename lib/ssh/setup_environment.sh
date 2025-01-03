#!/bin/bash

# Script directory and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/dashboard_config.conf"
SSH_CONFIG_FILE="$SCRIPT_DIR/../config/ssh_config"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            CONFIG_FILE="${1#*=}"
            # If config file is specified, use the same directory for SSH config
            SSH_CONFIG_FILE="$(dirname "$CONFIG_FILE")/ssh_config"
            shift
            ;;
        --log=*)
            LOG_FILE="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print with color
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# Check for required packages
check_packages() {
    echo "Checking Required Packages..."
    
    local packages=("gnome-keyring" "dbus-x11" "ssh" "ssh-client")
    local missing=()
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            missing+=("$pkg")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Installing missing packages: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
    
    print_status "Package check complete" $?
}

# Validate configuration
validate_config() {
    echo "Validating configuration..."
    
    # Check required variables
    local required_vars=("SSH_USER" "SSH_HOST" "SSH_PORT")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}Error: Required variable $var not set${NC}"
            return 1
        fi
    done
    
    # Validate SSH port
    if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
        echo -e "${RED}Error: Invalid SSH port: $SSH_PORT${NC}"
        return 1
    fi
    
    print_status "Configuration validation complete" $?
}

# Setup directories
setup_directories() {
    echo "Setting up directories..."
    
    # Create and check log directory if specified
    if [ ! -z "$LOG_DIR" ]; then
        # Check if directory exists and is not writable
        if [ -d "$LOG_DIR" ] && ! [ -w "$LOG_DIR" ]; then
            echo -e "${RED}Error: Log directory exists but is not writable: $LOG_DIR${NC}"
            return 1
        fi
        
        # Try to create directory if it doesn't exist
        if ! [ -d "$LOG_DIR" ]; then
            if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
                echo -e "${RED}Error: Could not create log directory: $LOG_DIR${NC}"
                return 1
            fi
        fi
        
        # Set permissions
        if ! chmod 755 "$LOG_DIR" 2>/dev/null; then
            echo -e "${RED}Error: Could not set permissions on log directory: $LOG_DIR${NC}"
            return 1
        fi
    fi
    
    # Create and check log file if specified
    if [ ! -z "$LOG_FILE" ]; then
        # Create parent directory if it doesn't exist
        local log_dir="$(dirname "$LOG_FILE")"
        if ! [ -d "$log_dir" ]; then
            if ! mkdir -p "$log_dir" 2>/dev/null; then
                echo -e "${RED}Error: Could not create log directory: $log_dir${NC}"
                return 1
            fi
            chmod 755 "$log_dir"
        fi
        
        # Create log file if it doesn't exist
        if ! [ -f "$LOG_FILE" ]; then
            if ! touch "$LOG_FILE" 2>/dev/null; then
                echo -e "${RED}Error: Could not create log file: $LOG_FILE${NC}"
                return 1
            fi
            chmod 644 "$LOG_FILE"
        fi
        
        # Check if file is writable
        if ! [ -w "$LOG_FILE" ]; then
            echo -e "${RED}Error: Log file is not writable: $LOG_FILE${NC}"
            return 1
        fi
    fi
    
    print_status "Directory setup complete" $?
}

# Setup SSH config
setup_ssh_config() {
    echo "Setting up SSH config..."
    
    # Create .ssh directory if it doesn't exist
    if ! mkdir -p ~/.ssh 2>/dev/null; then
        echo -e "${RED}Error: Could not create .ssh directory${NC}"
        return 1
    fi
    chmod 700 ~/.ssh
    
    # Copy SSH config if it exists
    if [ -f "$SSH_CONFIG_FILE" ]; then
        if ! cp "$SSH_CONFIG_FILE" ~/.ssh/config 2>/dev/null; then
            echo -e "${RED}Error: Could not copy SSH config file${NC}"
            return 1
        fi
        if ! chmod 600 ~/.ssh/config 2>/dev/null; then
            echo -e "${RED}Error: Could not set permissions on SSH config file${NC}"
            return 1
        fi
        print_status "SSH config setup complete" $?
    else
        # Skip if SSH config is not required
        if [ "$REQUIRE_SSH_CONFIG" = "1" ]; then
            echo -e "${RED}Error: SSH config file not found: $SSH_CONFIG_FILE${NC}"
            return 1
        else
            echo "No SSH config file found, skipping..."
            print_status "SSH config setup complete" 0
        fi
    fi
}

# Setup keyring directories
setup_keyring() {
    echo "Setting up Keyring..."
    
    # Create necessary directories
    mkdir -p ~/.local/share/keyrings
    chmod 700 ~/.local/share/keyrings
    
    # Start dbus if not running
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        eval $(dbus-launch --sh-syntax)
    fi
    
    # Start keyring daemon
    if command -v gnome-keyring-daemon &> /dev/null; then
        eval $(gnome-keyring-daemon --start)
        export SSH_AUTH_SOCK
    fi
    
    print_status "Keyring setup complete" $?
}

# Main script
echo "=== Environment Setup ==="

# Check if running in WSL
if ! uname -a | grep -qi microsoft && [ "$WSL_TEST" != "1" ]; then
    echo -e "${RED}Error: This script must be run in WSL${NC}"
    exit 1
fi

# Run setup steps
if [ "$TEST_MODE" != "1" ]; then
    check_packages
fi

# Validate configuration first
validate_config || exit 1

# Setup directories
setup_directories || exit 1

# Setup SSH config
setup_ssh_config || exit 1

# Setup keyring
setup_keyring || exit 1

# Add environment variables to bashrc if not present
if ! grep -q "export SSH_AUTH_SOCK" ~/.bashrc; then
    echo -e "\n# Dashboard environment variables" >> ~/.bashrc
    echo 'export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"' >> ~/.bashrc
    if [ "$ENABLE_DEBUG_MODE" = "true" ]; then
        echo 'export DEBUG_MODE=1' >> ~/.bashrc
    fi
fi

echo -e "\n${GREEN}Setup completed!${NC}"
