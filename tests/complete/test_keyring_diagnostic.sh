#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "${ROOT_DIR}/config/main_config.conf"
source "${ROOT_DIR}/config/monitor_config.conf"
source "${SCRIPT_DIR}/utils/assertions.sh"
source "${SCRIPT_DIR}/utils/test_helpers.sh"

# Fix WSL terminal size warning
export TERM=xterm-256color

# Check if running in WSL
is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# Setup WSL environment
setup_wsl_env() {
    # Start gnome-keyring-daemon if not running
    if ! pgrep -f "gnome-keyring-daemon" > /dev/null; then
        local keyring_env=$(gnome-keyring-daemon --start)
        if [ $? -eq 0 ]; then
            eval $keyring_env
        fi
    fi
    
    # Setup SSH agent if not running and keyring didn't set SSH_AUTH_SOCK
    if [ -z "$SSH_AUTH_SOCK" ]; then
        if ! pgrep -f "ssh-agent" > /dev/null; then
            eval $(ssh-agent -s)
        else
            # Find existing SSH agent socket
            export SSH_AUTH_SOCK=$(find /tmp -maxdepth 2 -type s -name "agent.*" 2>/dev/null | head -n 1)
        fi
    fi
    
    # Verify SSH agent connection
    ssh-add -l >/dev/null 2>&1 || {
        echo "SSH agent not responding, restarting..."
        eval $(ssh-agent -s)
    }
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_status="${3:-0}"
    
    echo -n "Testing $test_name... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    eval "$test_command" > /dev/null 2>&1
    local status=$?
    
    if [ $status -eq $expected_status ]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo "Expected status: $expected_status, got: $status"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    echo -e "\n${YELLOW}Setting up test environment...${NC}"
    clean_test_dirs
    
    # Create test directories
    mkdir -p "${TEST_BASE_DIR}/var/data/keyring"
    mkdir -p "${TEST_BASE_DIR}/var/log"
    mkdir -p "${TEST_BASE_DIR}/var/tmp"
    mkdir -p "${TEST_BASE_DIR}/var/ssh"
    
    echo -e "${GREEN}✓ Test environment setup complete${NC}"
}

# Cleanup test environment
cleanup_test_env() {
    echo -e "\n${YELLOW}Cleaning up test environment...${NC}"
    rm -rf "${TEST_BASE_DIR}/var"
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Print test summary
print_test_summary() {
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo "Tests Run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
}

# Test keyring diagnostics
test_keyring_diagnostics() {
    echo -e "\n${YELLOW}Testing Keyring Diagnostics${NC}"
    
    # Setup test environment
    setup_test_env
    
    # Create mock config
    cat > "${TEST_BASE_DIR}/var/data/keyring/keyring_config.conf" << EOL
LOG_DIR=${TEST_BASE_DIR}/var/log
DATA_DIR=${TEST_BASE_DIR}/var/data/keyring
TEMP_DIR=${TEST_BASE_DIR}/var/tmp
SSH_KEY_DIR=${TEST_BASE_DIR}/var/ssh
CHECK_INTERVAL=${MONITOR_INTERVAL}
MAX_RETRIES=${MAX_RETRIES}
RETRY_DELAY=${RETRY_DELAY}
EOL
    
    # Generate test SSH keys
    ssh-keygen -t ${SSH_KEY_TYPE} -b ${SSH_KEY_BITS} -f "${TEST_BASE_DIR}/var/ssh/test_key1" -N "" -q
    ssh-keygen -t ${SSH_KEY_TYPE} -b ${SSH_KEY_BITS} -f "${TEST_BASE_DIR}/var/ssh/test_key2" -N "" -q
    
    # Create mock keyring data
    cat > "${TEST_BASE_DIR}/var/data/keyring/keyring.json" << EOL
{
    "keys": [
        {
            "id": "test_key1",
            "path": "${TEST_BASE_DIR}/var/ssh/test_key1",
            "type": "${SSH_KEY_TYPE}",
            "bits": ${SSH_KEY_BITS},
            "status": "active"
        },
        {
            "id": "test_key2",
            "path": "${TEST_BASE_DIR}/var/ssh/test_key2",
            "type": "${SSH_KEY_TYPE}",
            "bits": ${SSH_KEY_BITS},
            "status": "inactive"
        }
    ]
}
EOL
    
    # Test with valid config
    (
        # Run in subshell to isolate environment changes
        export TEST_MODE=1
        export TERM=xterm-256color
        setup_wsl_env  # Ensure SSH agent is available in subshell
        ${ROOT_DIR}/utils/keyring_diagnostic.sh --config=${TEST_BASE_DIR}/var/data/keyring/keyring_config.conf
    )
    assert_true "[ $? -eq 0 ]" "Valid config diagnostics"
    
    # Test key permissions
    assert_true "[ -f ${TEST_BASE_DIR}/var/ssh/test_key1 ]" "Private key exists"
    assert_true "[ -f ${TEST_BASE_DIR}/var/ssh/test_key2 ]" "Public key exists"
    
    # Test with missing keys
    rm -f ${TEST_BASE_DIR}/var/ssh/test_key1*
    (
        export TEST_MODE=1
        export TERM=xterm-256color
        setup_wsl_env  # Ensure SSH agent is available in subshell
        ${ROOT_DIR}/utils/keyring_diagnostic.sh --config=${TEST_BASE_DIR}/var/data/keyring/keyring_config.conf
    )
    assert_true "[ $? -eq 1 ]" "Missing keys detection"
    
    # Test with invalid config
    echo "INVALID_CONFIG=true" > "${TEST_BASE_DIR}/var/data/keyring/invalid_config.conf"
    (
        export TEST_MODE=1
        export TERM=xterm-256color
        setup_wsl_env  # Ensure SSH agent is available in subshell
        ${ROOT_DIR}/utils/keyring_diagnostic.sh --config=${TEST_BASE_DIR}/var/data/keyring/invalid_config.conf
    )
    assert_true "[ $? -eq 1 ]" "Invalid config detection"
    
    # Cleanup test environment
    cleanup_test_env
}

# Run tests
echo -e "${YELLOW}=== Running Keyring Diagnostic Tests ===${NC}"
test_keyring_diagnostics

# Print test summary and exit
print_test_summary
[ $TESTS_FAILED -eq 0 ]
