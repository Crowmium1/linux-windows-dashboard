#!/bin/bash

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print status with color
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# Initialize test environment
setup_test_env
TEST_ROOT="$TEST_DIR/ssh_test"
CONFIG_DIR="$ROOT_DIR/config"

# Test environment setup
setup() {
    set_test_group "Environment Setup"
    
    # Create test directories
    setup_test_dir "$TEST_ROOT"
    mkdir -p "$TEST_ROOT/.ssh"
    mkdir -p "$TEST_ROOT/config"
    
    # Create test config based on main config
    cat > "$TEST_ROOT/config/main_config.conf" << EOL
# Core Configuration
ENV="testing"
DEBUG=true
TEST_MODE=true

# Base Paths
BASE_DIR="$TEST_ROOT"
CONFIG_DIR="$TEST_ROOT/config"
LOG_DIR="$TEST_ROOT/logs"
TEMP_DIR="$TEST_ROOT/tmp"
BACKUP_DIR="$TEST_ROOT/backups"

# SSH Configuration
SSH_HOST="localhost"
SSH_USER="$USER"
SSH_PORT=22
SSH_KEY_TYPE="ed25519"
SSH_KEY_BITS=4096
SSH_KEY_DIR="$TEST_ROOT/.ssh"
SSH_TIMEOUT=5

# Test-specific settings
SYNC_ENABLED=true
SYNC_INTERVAL=1
LOCAL_SYNC_DIR="$TEST_ROOT/sync/local"
REMOTE_SYNC_DIR="$TEST_ROOT/sync/remote"
EOL
    
    assert_path "$TEST_ROOT/config/main_config.conf" "file" "Config file creation"
    assert_path "$TEST_ROOT/.ssh" "dir" "SSH directory creation"
}

# Test SSH key generation
test_ssh_key_generation() {
    set_test_group "SSH Key Generation"
    
    # Test with valid config
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$TEST_ROOT/config/main_config.conf" \
        "SSH key generation with valid config"
    
    # Verify key files
    assert_path "$TEST_ROOT/.ssh/id_ed25519" "file" "Private key creation"
    assert_path "$TEST_ROOT/.ssh/id_ed25519.pub" "file" "Public key creation"
    assert_success "[ $(stat -c %a $TEST_ROOT/.ssh/id_ed25519) = '600' ]" "Private key has correct permissions"
    assert_success "[ $(stat -c %a $TEST_ROOT/.ssh/id_ed25519.pub) = '644' ]" "Public key has correct permissions"
}

# Test SSH key types
test_ssh_key_types() {
    set_test_group "SSH Key Types"
    
    # Test RSA key
    sed -i 's/SSH_KEY_TYPE=.*/SSH_KEY_TYPE=rsa/' "$TEST_ROOT/config/main_config.conf"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$TEST_ROOT/config/main_config.conf" \
        "RSA key generation"
    assert_file_contains "$TEST_ROOT/.ssh/id_rsa.pub" "ssh-rsa" "RSA key verification"
    
    # Test ED25519 key
    sed -i 's/SSH_KEY_TYPE=.*/SSH_KEY_TYPE=ed25519/' "$TEST_ROOT/config/main_config.conf"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$TEST_ROOT/config/main_config.conf" \
        "ED25519 key generation"
    assert_file_contains "$TEST_ROOT/.ssh/id_ed25519.pub" "ssh-ed25519" "ED25519 key verification"
}

# Test error handling
test_error_handling() {
    set_test_group "Error Handling"
    
    # Test invalid config file
    assert_output "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=nonexistent.conf" \
        "Error: Configuration file not found" \
        "Invalid config detection"
    
    # Test invalid key type
    local orig_config="$TEST_ROOT/config/main_config.conf"
    local bad_config="$TEST_ROOT/config/bad_config.conf"
    cp "$orig_config" "$bad_config"
    sed -i 's/SSH_KEY_TYPE=.*/SSH_KEY_TYPE=invalid/' "$bad_config"
    assert_output "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$bad_config" \
        "Error: Invalid SSH key type" \
        "Invalid key type detection"
    
    # Test read-only directory
    local test_dir="$TEST_ROOT/read_only_test"
    mkdir -p "$test_dir/.ssh"
    chmod 555 "$test_dir/.ssh"
    
    local ro_config="$test_dir/ro_config.conf"
    cp "$orig_config" "$ro_config"
    sed -i "s|SSH_KEY_DIR=.*|SSH_KEY_DIR=$test_dir/.ssh|" "$ro_config"
    
    assert_output "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$ro_config" \
        "Error: Could not set permissions" \
        "Read-only directory handling"
        
    chmod 755 "$test_dir/.ssh"
}

# Test key deployment
test_key_deployment() {
    set_test_group "Key Deployment"
    
    # Test successful deployment
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$TEST_ROOT/config/main_config.conf --deploy" \
        "Successful key deployment"
    
    # Test failed deployment with invalid host
    local orig_config="$TEST_ROOT/config/main_config.conf"
    local bad_config="$TEST_ROOT/config/bad_host_config.conf"
    cp "$orig_config" "$bad_config"
    sed -i 's/SSH_HOST=.*/SSH_HOST=invalid.host/' "$bad_config"
    assert_output "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$bad_config --deploy" \
        "Error: Could not copy key" \
        "Failed key deployment handling"
}

# Test SSH connection
test_ssh_connection() {
    set_test_group "SSH Connection"
    
    # Test successful connection
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$TEST_ROOT/config/main_config.conf --test" \
        "Successful SSH connection"
    
    # Test failed connection
    local orig_config="$TEST_ROOT/config/main_config.conf"
    local bad_config="$TEST_ROOT/config/bad_host_config.conf"
    cp "$orig_config" "$bad_config"
    sed -i 's/SSH_HOST=.*/SSH_HOST=invalid.host/' "$bad_config"
    assert_output "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_passwordless_ssh.sh --config=$bad_config --test" \
        "Error: Could not connect" \
        "Failed SSH connection handling"
}

# Run all tests
setup
test_ssh_key_generation
test_ssh_key_types
test_error_handling
test_key_deployment
test_ssh_connection

# Print test summary
print_test_summary
