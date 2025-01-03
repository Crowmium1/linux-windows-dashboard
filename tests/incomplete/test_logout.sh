#!/bin/bash

# Source test utilities and configs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source configurations
source "${ROOT_DIR}/config/main_config.conf"
source "${ROOT_DIR}/config/monitor_config.conf"

# Set test environment
export TEST_MODE=true
export DEBUG=true
export ENV="testing"

# Override paths for testing
TEST_BASE_DIR="${ROOT_DIR}/tests/var"
TEST_CONFIG_DIR="${TEST_BASE_DIR}/config"
TEST_LOG_DIR="${TEST_BASE_DIR}/log"
TEST_DATA_DIR="${TEST_BASE_DIR}/data"
TEST_TEMP_DIR="${TEST_BASE_DIR}/tmp"

# Source test utilities
source "${ROOT_DIR}/utils/test_helpers.sh"
source "${ROOT_DIR}/utils/utils.sh"

# Initialize test environment
function setup_test_env() {
    set_test_group "Environment Setup"
    
    # Create test directories
    mkdir -p "${TEST_DATA_DIR}/logout/sessions"
    mkdir -p "${TEST_LOG_DIR}"
    mkdir -p "${TEST_TEMP_DIR}"
    mkdir -p "${TEST_CONFIG_DIR}"
    
    # Create mock config files
    cat > "${TEST_CONFIG_DIR}/logout_config.conf" << EOL
SSH_USER=${SSH_USER}
SSH_HOST=${SSH_HOST}
SSH_PORT=${SSH_PORT}
LOG_DIR=${TEST_LOG_DIR}
DATA_DIR=${TEST_DATA_DIR}/logout
TEMP_DIR=${TEST_TEMP_DIR}
SESSION_DIR=${TEST_DATA_DIR}/logout/sessions
MAX_RETRIES=${MAX_RETRIES}
RETRY_DELAY=${RETRY_DELAY}
EOL
    
    # Create mock session files
    touch "${TEST_DATA_DIR}/logout/sessions/session_1"
    touch "${TEST_DATA_DIR}/logout/sessions/session_2"
    
    # Verify setup
    assert_path "${TEST_CONFIG_DIR}/logout_config.conf" "file" "Config file creation"
    assert_path "${TEST_DATA_DIR}/logout/sessions/session_1" "file" "Session file 1 creation"
    assert_path "${TEST_DATA_DIR}/logout/sessions/session_2" "file" "Session file 2 creation"
}

# Test logout functionality
function test_logout() {
    set_test_group "Logout Functionality"
    
    # Test with valid config
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/logout.sh --config=${TEST_CONFIG_DIR}/logout_config.conf" \
        "Logout with valid config"
    
    # Test session cleanup
    assert_path "${TEST_DATA_DIR}/logout/sessions/session_1" "file" "Session file 1 exists" "true"
    assert_path "${TEST_DATA_DIR}/logout/sessions/session_2" "file" "Session file 2 exists" "true"
    
    # Test with invalid config
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/core/logout.sh --config=nonexistent.conf" \
        "Invalid config detection"
    
    # Test with missing session directory
    rm -rf "${TEST_DATA_DIR}/logout/sessions"
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/core/logout.sh --config=${TEST_CONFIG_DIR}/logout_config.conf" \
        "Missing session directory handling"
    
    # Test with read-only session directory
    mkdir -p "${TEST_DATA_DIR}/logout/sessions"
    chmod 444 "${TEST_DATA_DIR}/logout/sessions"
    touch "${TEST_DATA_DIR}/logout/sessions/session_3" 2>/dev/null
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/core/logout.sh --config=${TEST_CONFIG_DIR}/logout_config.conf" \
        "Read-only directory handling"
    chmod 755 "${TEST_DATA_DIR}/logout/sessions"
}

# Test error logging
function test_error_logging() {
    set_test_group "Error Logging"
    
    # Test error log creation
    local log_file="${TEST_LOG_DIR}/logout.log"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/logout.sh --config=${TEST_CONFIG_DIR}/logout_config.conf --log=${log_file}" \
        "Error logging with invalid config"
    assert_file_not_empty "${log_file}" "Error log contains content"
    assert_file_contains "${log_file}" "Error" "Error log contains error message"
    
    # Test error logging
    assert_success "log_error 'Test error message'" "Error logging"
    assert_file_contains "${TEST_LOG_DIR}/error.log" "Test error message" "Error log content"
    
    # Test warning logging
    assert_success "log_warning 'Test warning message'" "Warning logging"
    assert_file_contains "${TEST_LOG_DIR}/error.log" "Test warning message" "Warning log content"
}

# Run all tests
echo -e "${YELLOW}=== Running Logout Tests ===${NC}"
setup_test_env
test_logout
test_error_logging

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
