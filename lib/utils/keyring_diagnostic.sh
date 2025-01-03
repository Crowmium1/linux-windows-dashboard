#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in test mode
is_test_mode() {
    [ "${TEST_MODE:-0}" = "1" ]
}

# Check if running in WSL mode
is_wsl_mode() {
    [ "${WSL_MODE:-0}" = "1" ] || grep -qi microsoft /proc/version 2>/dev/null
}

# Get config directory
get_config_dir() {
    local config_file="$1"
    if is_test_mode && [[ "$config_file" == *"keyring_test"* ]]; then
        echo "keyring_test"
    else
        echo "$HOME/.ssh"
    fi
}

# Check file permissions
check_permissions() {
    local file="$1"
    local expected="$2"
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # Skip permission checks in WSL
    if is_wsl_mode; then
        return 0
    fi
    
    local actual
    actual=$(stat -c %a "$file" 2>/dev/null)
    if [ "$actual" != "$expected" ]; then
        return 1
    fi
    
    return 0
}

# Diagnostic function
run_diagnostics() {
    local config_file="${1:-$HOME/.ssh/config}"
    local ssh_dir=$(get_config_dir "$config_file")
    local exit_code=0
    local is_wsl=$(is_wsl_mode && echo 1 || echo 0)
    
    echo "=== Running SSH & Keyring Diagnostics ==="
    
    echo -e "\n1. Current User and Directory:"
    whoami
    pwd
    
    echo -e "\n2. SSH Directory Structure:"
    echo "Expected structure:"
    echo "~/.ssh/ (700)"
    echo "├── config (600)"
    echo "├── id_ed25519 (600)"
    echo "└── id_ed25519.pub (644)"
    echo "\nActual structure:"
    ls -la "$ssh_dir"
    
    echo -e "\n3. Process Status:"
    if pgrep -f "ssh-agent" > /dev/null; then
        echo -e "${GREEN}✓ SSH agent is running${NC}"
        ps aux | grep -i "ssh-agent" | grep -v grep
    else
        echo -e "${RED}✗ SSH agent not running${NC}"
        exit_code=1
    fi
    
    if ! is_wsl_mode; then
        if pgrep -f "gnome-keyring-daemon" > /dev/null; then
            echo -e "${GREEN}✓ Keyring daemon is running${NC}"
            ps aux | grep -i "gnome-keyring" | grep -v grep
        else
            echo -e "${RED}✗ Keyring daemon not running${NC}"
            exit_code=1
        fi
    else
        echo -e "${YELLOW}! Keyring daemon check skipped in WSL${NC}"
    fi
    
    echo -e "\n4. Environment Variables:"
    if ! is_wsl_mode; then
        local required_vars=("SSH_AUTH_SOCK" "DBUS_SESSION_BUS_ADDRESS")
    else
        local required_vars=("SSH_AUTH_SOCK")
    fi
    
    for var in "${required_vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo -e "${GREEN}✓ $var=${!var}${NC}"
        else
            echo -e "${RED}✗ $var not set${NC}"
            exit_code=1
        fi
    done
    
    echo -e "\n5. SSH Config Check:"
    if [ -f "$config_file" ]; then
        echo -e "${GREEN}✓ SSH config exists${NC}"
        if ! check_permissions "$config_file" "600"; then
            if ! is_wsl_mode; then
                echo -e "${RED}✗ SSH config has incorrect permissions${NC}"
                exit_code=1
            fi
        fi
        echo "Configuration:"
        cat "$config_file"
    else
        echo -e "${RED}✗ SSH config missing${NC}"
        exit_code=1
    fi
    
    echo -e "\n6. SSH Key Check:"
    local key_types=("rsa" "ed25519")
    local keys_exist=false
    for type in "${key_types[@]}"; do
        if [ -f "$ssh_dir/id_$type" ] && [ -f "$ssh_dir/id_$type.pub" ]; then
            keys_exist=true
            if ! check_permissions "$ssh_dir/id_$type" "600"; then
                if ! is_wsl_mode; then
                    echo -e "${RED}✗ Private key has incorrect permissions${NC}"
                    exit_code=1
                fi
            fi
            if ! check_permissions "$ssh_dir/id_$type.pub" "644"; then
                if ! is_wsl_mode; then
                    echo -e "${RED}✗ Public key has incorrect permissions${NC}"
                    exit_code=1
                fi
            fi
            echo -e "${GREEN}✓ SSH keys exist${NC}"
            echo "Public key fingerprint:"
            ssh-keygen -lf "$ssh_dir/id_$type.pub"
        fi
    done
    
    if ! $keys_exist; then
        echo -e "${RED}✗ No SSH keys found${NC}"
        exit_code=1
    fi
    
    echo -e "\n7. SSH Connection Test:"
    if grep -q "^Host " "$config_file" 2>/dev/null; then
        local host=$(grep "^Host " "$config_file" | head -1 | awk '{print $2}')
        echo "Testing connection to $host..."
        if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" exit 0 2>/dev/null; then
            echo -e "${GREEN}✓ SSH connection successful${NC}"
        else
            echo -e "${RED}✗ SSH connection failed${NC}"
            exit_code=1
        fi
    else
        echo -e "${YELLOW}! No hosts defined in config${NC}"
    fi
    
    return $exit_code
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            CONFIG_FILE="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run diagnostics and save output
run_diagnostics "$CONFIG_FILE" | tee ~/ssh_diagnostic_$(date +%Y%m%d_%H%M%S).log
echo -e "\nDiagnostic output has been saved to your home directory"
exit ${PIPESTATUS[0]}
