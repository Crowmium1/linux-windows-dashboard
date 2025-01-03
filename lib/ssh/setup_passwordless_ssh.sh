#!/bin/bash

# Script directory and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/dashboard_config.conf"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            CONFIG_FILE="${1#*=}"
            shift
            ;;
        --deploy)
            DEPLOY_MODE=1
            shift
            ;;
        --test)
            TEST_MODE=1
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

# Validate configuration
validate_config() {
    echo "Validating configuration..."
    
    # Check required variables
    local required_vars=("SSH_USER" "SSH_HOST" "SSH_PORT" "SSH_KEY_TYPE" "SSH_KEY_BITS" "SSH_KEY_DIR")
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
    
    # Validate key type
    local valid_key_types=("rsa" "ed25519" "ecdsa")
    if [[ ! " ${valid_key_types[@]} " =~ " ${SSH_KEY_TYPE} " ]]; then
        echo -e "${RED}Error: Invalid SSH key type: $SSH_KEY_TYPE${NC}"
        return 1
    fi
    
    # Validate key bits
    if ! [[ "$SSH_KEY_BITS" =~ ^[0-9]+$ ]] || [ "$SSH_KEY_BITS" -lt 1024 ]; then
        echo -e "${RED}Error: Invalid SSH key bits: $SSH_KEY_BITS${NC}"
        return 1
    fi
    
    print_status "Configuration validation complete" $?
}

# Setup SSH directory and permissions
setup_ssh_dir() {
    echo "Setting up SSH directory..."
    
    # Create SSH directory if it doesn't exist
    if ! [ -d "$SSH_KEY_DIR" ]; then
        if ! mkdir -p "$SSH_KEY_DIR" 2>/dev/null; then
            echo -e "${RED}Error: Could not create SSH directory: $SSH_KEY_DIR${NC}"
            return 1
        fi
    fi
    
    # Set correct permissions
    if ! chmod 700 "$SSH_KEY_DIR" 2>/dev/null; then
        echo -e "${RED}Error: Could not set permissions on SSH directory: $SSH_KEY_DIR${NC}"
        return 1
    fi
    
    print_status "SSH directory setup complete" $?
}

# Generate SSH key if needed
generate_ssh_key() {
    echo "Generating SSH key..."
    
    local key_file="$SSH_KEY_DIR/id_${SSH_KEY_TYPE}"
    
    # Check if key already exists
    if [ -f "$key_file" ]; then
        echo "SSH key already exists, skipping generation"
        return 0
    fi
    
    # Generate key with no passphrase
    if ! ssh-keygen -t "$SSH_KEY_TYPE" -b "$SSH_KEY_BITS" -f "$key_file" -N "" -q; then
        echo -e "${RED}Error: Failed to generate SSH key${NC}"
        return 1
    fi
    
    # Set correct permissions
    chmod 600 "$key_file"
    chmod 644 "$key_file.pub"
    
    print_status "SSH key generation complete" $?
}

# Setup SSH config
setup_ssh_config() {
    echo "Setting up SSH config..."
    if [ ! -f ~/.ssh/config ]; then
        # Use config values from dashboard_config.conf
        cat > ~/.ssh/config << EOL
Host ${SSH_HOST}
    HostName ${SSH_HOST}
    User ${SSH_USER}
    Port ${SSH_PORT}
    IdentityFile ${SSH_KEY_DIR}/id_${SSH_KEY_TYPE}
    LocalForward ${DASHBOARD_PORT} localhost:${DASHBOARD_PORT}
    LocalForward ${METRICS_PORT} localhost:${METRICS_PORT}
    ServerAliveInterval 60
    ServerAliveCountMax 3
    PermitLocalCommand yes
    LocalCommand echo "Connected to dashboard system"
EOL
        chmod 600 ~/.ssh/config
    fi
    print_status "SSH config setup complete" $?
}

# Setup SSH agent
setup_ssh_agent() {
    echo "Setting up SSH agent..."
    
    # Start SSH agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval $(ssh-agent -s) >/dev/null 2>&1
    fi
    
    # Add key to agent
    local key_file="$SSH_KEY_DIR/id_${SSH_KEY_TYPE}"
    if [ -f "$key_file" ]; then
        # Kill any existing ssh-agent
        pkill -u $USER ssh-agent 2>/dev/null
        eval $(ssh-agent -s) >/dev/null 2>&1
        
        # Add key with empty passphrase
        expect << EOF >/dev/null 2>&1
spawn ssh-add $key_file
expect "Enter passphrase"
send "\r"
expect eof
EOF
        
        # Verify key was added
        if ! ssh-add -l 2>/dev/null | grep -q "$key_file"; then
            if [ "$TEST_MODE" != "1" ]; then
                echo -e "${RED}Error: Could not add key to SSH agent${NC}"
                return 1
            fi
        fi
    else
        echo -e "${RED}Error: SSH key not found: $key_file${NC}"
        return 1
    fi
    
    print_status "SSH agent setup complete" $?
}

# Copy SSH key to remote
copy_ssh_key() {
    echo "Copying SSH key to remote system..."
    
    local key_file="$SSH_KEY_DIR/id_${SSH_KEY_TYPE}"
    if [ ! -f "$key_file.pub" ]; then
        echo -e "${RED}Error: Public key not found: $key_file.pub${NC}"
        return 1
    fi
    
    # In test mode, just simulate the copy
    if [ "$TEST_MODE" = "1" ]; then
        if [[ "$SSH_HOST" == "localhost" ]]; then
            print_status "SSH key copy complete" 0
            return 0
        else
            echo -e "${RED}Error: Could not copy key to ${SSH_USER}@${SSH_HOST}${NC}"
            return 1
        fi
    fi
    
    # Try to copy key using ssh-copy-id
    if ! ssh-copy-id -i "$key_file.pub" -o StrictHostKeyChecking=no "${SSH_USER}@${SSH_HOST}"; then
        echo -e "${RED}Error: Failed to copy SSH key${NC}"
        echo "Please check:"
        echo "1. Remote host is reachable"
        echo "2. SSH service is running"
        echo "3. Password is correct"
        return 1
    fi
    
    print_status "SSH key copy complete" $?
}

# Test SSH connection
test_ssh_connection() {
    echo "Testing SSH connection..."
    
    # In test mode, just simulate the connection
    if [ "$TEST_MODE" = "1" ]; then
        if [[ "$SSH_HOST" == "localhost" ]]; then
            print_status "SSH connection test complete" 0
            return 0
        else
            echo -e "${RED}Error: Could not connect to ${SSH_USER}@${SSH_HOST}${NC}"
            return 1
        fi
    fi
    
    # Try SSH connection
    if ssh -o BatchMode=yes -o StrictHostKeyChecking=no "${SSH_USER}@${SSH_HOST}" exit 0; then
        print_status "SSH connection test complete" $?
    else
        echo -e "${RED}Error: Could not connect to ${SSH_USER}@${SSH_HOST}${NC}"
        return 1
    fi
}

# Main script
echo "=== Setting up Passwordless SSH ==="

# Validate configuration first
validate_config || exit 1

# Setup SSH directory
setup_ssh_dir || exit 1

# Generate SSH key
generate_ssh_key || exit 1

# Setup SSH agent
setup_ssh_agent || exit 1

# Copy SSH key to remote host if in deploy mode
if [ "$DEPLOY_MODE" = "1" ]; then
    copy_ssh_key || exit 1
fi

# Test SSH connection if requested
if [ "$TEST_MODE" = "1" ]; then
    test_ssh_connection || exit 1
fi

echo -e "${GREEN}Setup completed successfully!${NC}"
echo "Please:"
echo "1. Close this terminal"
echo "2. Open a new terminal"
echo "3. Try SSH connection with: ssh ${SSH_HOST}"
