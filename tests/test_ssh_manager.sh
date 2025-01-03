#!/bin/bash

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Set test mode
export TEST_MODE=1

# Source dependencies
source "${ROOT_DIR}/utils/utils.sh"
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Test environment variables
TEST_TMP_DIR="${ROOT_DIR}/var/tmp/test"
TEST_LOG_DIR="${ROOT_DIR}/var/log/test"
TEST_ROOT="${TEST_TMP_DIR}/ssh_manager_test"

# SSH manager paths
SSH_MANAGER="${ROOT_DIR}/ssh/ssh_manager.sh"
CONFIG_DIR="${ROOT_DIR}/config"

# Test environment setup
setup() {
    set_test_group "Environment Setup"
    
    # Create test directories
    mkdir -p "$TEST_ROOT/ssh"
    mkdir -p "$TEST_ROOT/config"
    mkdir -p "$TEST_ROOT/sessions"
    mkdir -p "$TEST_LOG_DIR"
    
    # Create mock config
    cat > "$TEST_ROOT/config/manager_config.conf" << EOL
SSH_USER=testuser
SSH_HOST=localhost
SSH_PORT=22
SESSION_DIR=$TEST_ROOT/sessions
MAX_SESSIONS=5
TIMEOUT=30
LOG_DIR=$TEST_LOG_DIR
EOL
    
    # Copy required files
    cp "${CONFIG_DIR}/ssh_config" "$TEST_ROOT/config/"
    cp "$SSH_MANAGER" "$TEST_ROOT/ssh/"
    
    return 0
}

# Test session management
test_session_management() {
    set_test_group "Session Management"
    
    # Test session creation
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --new
    assertTrue "Session creation should succeed" $?
    
    # Check session file exists
    local session_file
    session_file=$(ls "$TEST_ROOT/sessions/"* | head -n 1)
    assertTrue "Session file should exist" "[ -f "$session_file" ]"
    
    # Test session listing
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --list
    assertTrue "Session listing should succeed" $?
}

# Test session limits
test_session_limits() {
    set_test_group "Session Limits"
    
    # Create max sessions
    for i in {1..5}; do
        "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --new
        assertTrue "Session creation should succeed" $?
    done
    
    # Test session limit
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --new
    assertFalse "Session creation should fail due to limit" $?
    
    # Test session pruning
    touch -d "2 days ago" "$TEST_ROOT/sessions/session_1"
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --prune
    assertTrue "Session pruning should succeed" $?
    assertFalse "Old session should be removed" "[ -f '$TEST_ROOT/sessions/session_1' ]"
}

# Test error handling
test_error_handling() {
    set_test_group "Error Handling"
    
    # Test with invalid config
    "$SSH_MANAGER" --config "nonexistent.conf"
    assertFalse "Invalid config should fail" $?
    
    # Test with read-only sessions directory
    chmod 444 "$TEST_ROOT/sessions"
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --new
    assertFalse "Read-only directory should fail" $?
    chmod 755 "$TEST_ROOT/sessions"
    
    # Test with missing sessions directory
    rm -rf "$TEST_ROOT/sessions"
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --list
    assertFalse "Missing directory should fail" $?
}

# Test session monitoring
test_session_monitoring() {
    set_test_group "Session Monitoring"
    
    # Setup mock processes
    mkdir -p "$TEST_ROOT/sessions"
    echo "$$" > "$TEST_ROOT/sessions/active_session"
    
    # Test active session detection
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --check-active
    assertTrue "Active session detection should succeed" $?
    
    # Test inactive session detection
    echo "999999" > "$TEST_ROOT/sessions/inactive_session"
    "$SSH_MANAGER" --config "$TEST_ROOT/config/manager_config.conf" --cleanup-inactive
    assertTrue "Inactive session cleanup should succeed" $?
    assertFalse "Inactive session should be removed" "[ -f '$TEST_ROOT/sessions/inactive_session' ]"
}

# Cleanup function
cleanup() {
    rm -rf "${TEST_ROOT:?}/"*
}

# Run all tests
setup
test_session_management
test_session_limits
test_error_handling
test_session_monitoring
cleanup

exit $?
