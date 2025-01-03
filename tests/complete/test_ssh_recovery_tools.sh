#!/bin/bash

# Enable debug mode
set -x

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Create necessary directories
mkdir -p "$ROOT_DIR"/{tmp,log,var}
mkdir -p "$ROOT_DIR/tmp/test"
mkdir -p "$ROOT_DIR/log/test"
mkdir -p "$ROOT_DIR/var/test"

# Test environment variables
TEST_DIR="$ROOT_DIR/tmp/test"
LOG_DIR="$ROOT_DIR/log/test"
VAR_DIR="$ROOT_DIR/var/test"

# Export test mode globally
export TEST_MODE=1

# Check if test_helpers.sh exists
if [ ! -f "$SCRIPT_DIR/utils/test_helpers.sh" ]; then
    echo "Error: test_helpers.sh not found in $SCRIPT_DIR/utils/"
    exit 1
fi

source "$SCRIPT_DIR/utils/test_helpers.sh"

# Initialize test environment
setup_test_env
TEST_ROOT="$TEST_DIR/ssh_recovery_test"
CONFIG_DIR="$ROOT_DIR/config"

# Test environment setup
setup() {
    echo "Starting environment setup..."
    set_test_group "Environment Setup"
    
    # Create test directories
    echo "Creating test directories..."
    setup_test_dir "$TEST_ROOT"
    mkdir -p "$TEST_ROOT/.ssh"
    mkdir -p "$TEST_ROOT/config"
    mkdir -p "$TEST_ROOT/sync/local"
    mkdir -p "$TEST_ROOT/sync/remote"
    mkdir -p "$TEST_ROOT/backups"
    mkdir -p "$TEST_ROOT/logs"
    
    echo "Creating test config..."
    # Create test config
    cat > "$TEST_ROOT/config/main_config.conf" << EOL
# Core Configuration
ENV="testing"
DEBUG=true
TEST_MODE=1

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

# Sync Configuration
SYNC_ENABLED=true
SYNC_INTERVAL=1
LOCAL_SYNC_DIR="$TEST_ROOT/sync/local"
REMOTE_SYNC_DIR="$TEST_ROOT/sync/remote"
SYNC_EXCLUDE=".git,.svn"
SYNC_LOCK_FILE="$TEST_ROOT/sync.lock"
EOL
    
    echo "Verifying paths..."
    assert_path "$TEST_ROOT/config/main_config.conf" "file" "Config file creation"
    assert_path "$TEST_ROOT/sync/local" "dir" "Source directory creation"
    assert_path "$TEST_ROOT/sync/remote" "dir" "Destination directory creation"
}

# Test sync setup
test_sync() {
    echo "Starting sync test..."
    set_test_group "Sync Setup"
    
    # Test with valid config
    echo "Testing sync with config: $TEST_ROOT/config/main_config.conf"
    if [ ! -f "${ROOT_DIR}/ssh/ssh_recovery_tools.sh" ]; then
        echo "Error: ssh_recovery_tools.sh not found at ${ROOT_DIR}/ssh/ssh_recovery_tools.sh"
        exit 1
    fi
    
    # Pass TEST_MODE explicitly in the environment
    TEST_MODE=1 CONFIG_FILE="$TEST_ROOT/config/main_config.conf" \
    assert_success "${ROOT_DIR}/ssh/ssh_recovery_tools.sh --sync" \
        "Sync setup with valid config"
}

# Run all tests
echo "Starting tests..."
setup
test_sync

# Print test summary
echo "Tests completed. Printing summary..."
print_test_summary

# Disable debug mode
set +x
