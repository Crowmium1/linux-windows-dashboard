#!/bin/bash

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Initialize test environment
setup_test_env
TEST_ROOT="$TEST_DIR/logout_test"

# Test environment setup
setup() {
    set_test_group "Environment Setup"
    
    # Create test directories
    setup_test_dir "$TEST_ROOT"
    mkdir -p "$TEST_ROOT/ssh"
    mkdir -p "$TEST_ROOT/config"
    mkdir -p "$TEST_ROOT/sessions"
    
    # Create mock config files
    cat > "$TEST_ROOT/config/system_config.conf" << EOL
SSH_USER=testuser
SSH_HOST=localhost
SSH_PORT=22
SESSION_DIR=$TEST_ROOT/sessions
EOL
    
    # Create mock session files
    touch "$TEST_ROOT/sessions/session_1"
    touch "$TEST_ROOT/sessions/session_2"
    
    # Verify setup
    assert_path "$TEST_ROOT/config/system_config.conf" "file" "Config file creation"
    assert_path "$TEST_ROOT/sessions/session_1" "file" "Session file 1 creation"
    assert_path "$TEST_ROOT/sessions/session_2" "file" "Session file 2 creation"
}

# Test logout functionality
test_logout() {
    set_test_group "Logout Functionality"
    
    # Test with valid config
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/logout.sh --config=$TEST_ROOT/config/system_config.conf" \
        "Logout with valid config"
    
    # Test session cleanup
    assert_path "$TEST_ROOT/sessions/session_1" "file" "Session file 1 exists" "true"
    assert_path "$TEST_ROOT/sessions/session_2" "file" "Session file 2 exists" "true"
    
    # Test with invalid config
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/ssh/logout.sh --config=nonexistent.conf" \
        "Invalid config detection"
    
    # Test with missing session directory
    rm -rf "$TEST_ROOT/sessions"
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/ssh/logout.sh --config=$TEST_ROOT/config/system_config.conf" \
        "Missing session directory handling"
    
    # Test with read-only session directory
    mkdir -p "$TEST_ROOT/sessions"
    chmod 444 "$TEST_ROOT/sessions"
    touch "$TEST_ROOT/sessions/session_3" 2>/dev/null
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/ssh/logout.sh --config=$TEST_ROOT/config/system_config.conf" \
        "Read-only directory handling"
}

# Test error logging
test_error_logging() {
    set_test_group "Error Logging"
    
    # Test error log creation
    local log_file="$TEST_ROOT/logout.log"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/logout.sh --config=nonexistent.conf --log=$log_file" \
        "Error logging with invalid config"
    assert_file_not_empty "$log_file" "Error log contains content"
    assert_file_contains "$log_file" "Error" "Error log contains error message"
}

# Run all tests
echo -e "${YELLOW}=== Running Logout Tests ===${NC}"
setup
test_logout
test_error_logging

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
