#!/bin/bash

# Source test utilities
. "$TEST_BASE_DIR/utils/test_helpers.sh"

# Set test mode
export TEST_MODE=1

# Source dependencies
source "$LIB_DIR/utils.sh"

# Directory setup
mkdir -p "$TEST_BASE_DIR/var/data/ssh/sessions" "$TEST_BASE_DIR/var/log/ssh" "$TEST_BASE_DIR/var/tmp/ssh"

# Test environment setup
function setup() {
    set_test_group "Environment Setup"
    
    # Create mock config
    cat > "$TEST_CONFIG_DIR/manager_config.conf" << EOL
SSH_USER=testuser
SSH_HOST=localhost
SSH_PORT=22
SESSION_DIR=$TEST_BASE_DIR/var/data/ssh/sessions
MAX_SESSIONS=5
TIMEOUT=30
LOG_DIR=$TEST_BASE_DIR/var/log/ssh
EOL
    
    # Copy required files
    cp "$CONFIG_DIR/ssh_config" "$TEST_CONFIG_DIR/"
    
    return 0
}

# Test session management
function test_session_management() {
    set_test_group "Session Management"
    
    # Test session creation
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --new
    assertTrue "Session creation should succeed" $?
    
    # Check session file exists
    local session_file
    session_file=$(ls "$TEST_BASE_DIR/var/data/ssh/sessions/"* | head -n 1)
    assertTrue "Session file should exist" "[ -f "$session_file" ]"
    
    # Test session listing
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --list
    assertTrue "Session listing should succeed" $?
}

# Test session limits
function test_session_limits() {
    set_test_group "Session Limits"
    
    # Create max sessions
    for i in {1..5}; do
        "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --new
        assertTrue "Session creation should succeed" $?
    done
    
    # Test session limit
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --new
    assertFalse "Session creation should fail due to limit" $?
    
    # Test session pruning
    touch -d "2 days ago" "$TEST_BASE_DIR/var/data/ssh/sessions/session_1"
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --prune
    assertTrue "Session pruning should succeed" $?
    assertFalse "Old session should be removed" "[ -f '$TEST_BASE_DIR/var/data/ssh/sessions/session_1' ]"
}

# Test error handling
function test_error_handling() {
    set_test_group "Error Handling"
    
    # Test with invalid config
    "$CORE_DIR/ssh_manager.sh" --config "nonexistent.conf"
    assertFalse "Invalid config should fail" $?
    
    # Test with read-only sessions directory
    chmod 444 "$TEST_BASE_DIR/var/data/ssh/sessions"
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --new
    assertFalse "Read-only directory should fail" $?
    chmod 755 "$TEST_BASE_DIR/var/data/ssh/sessions"
    
    # Test with missing sessions directory
    rm -rf "$TEST_BASE_DIR/var/data/ssh/sessions"
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --list
    assertFalse "Missing directory should fail" $?
}

# Test session monitoring
function test_session_monitoring() {
    set_test_group "Session Monitoring"
    
    # Setup mock processes
    mkdir -p "$TEST_BASE_DIR/var/data/ssh/sessions"
    echo "$$" > "$TEST_BASE_DIR/var/data/ssh/sessions/active_session"
    
    # Test active session detection
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --check-active
    assertTrue "Active session detection should succeed" $?
    
    # Test inactive session detection
    echo "999999" > "$TEST_BASE_DIR/var/data/ssh/sessions/inactive_session"
    "$CORE_DIR/ssh_manager.sh" --config "$TEST_CONFIG_DIR/manager_config.conf" --cleanup-inactive
    assertTrue "Inactive session cleanup should succeed" $?
    assertFalse "Inactive session should be removed" "[ -f '$TEST_BASE_DIR/var/data/ssh/sessions/inactive_session' ]"
}

# Cleanup function
function cleanup() {
    rm -rf "$TEST_BASE_DIR/var/data/ssh"
    rm -rf "$TEST_BASE_DIR/var/log/ssh"
    rm -rf "$TEST_BASE_DIR/var/tmp/ssh"
}

# Run all tests
setup
test_session_management
test_session_limits
test_error_handling
test_session_monitoring
cleanup

exit $?
