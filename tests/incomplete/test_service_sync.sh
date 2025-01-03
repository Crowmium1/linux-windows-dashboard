#!/bin/bash

# Test script for service_sync.sh

# Source test utilities and configs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test utilities and target script
source "${ROOT_DIR}/utils/test_helpers.sh"
source "${ROOT_DIR}/utils/utils.sh"
source "${ROOT_DIR}/lib/ssh/service_sync.sh"

# Set test environment
export TEST_MODE=true
export DEBUG=true

# Test environment variables
TEST_REMOTE_HOST="test-host"
TEST_REMOTE_USER="test-user"
TEST_SERVICE_NAME="test-service"
TEST_LOCK_FILE="/tmp/test_service_sync.lock"
TEST_STATUS_FILE="/tmp/test_service_sync_status"

# Mock functions
mock_ssh() {
    case "$*" in
        *"systemctl is-active"*)
            echo "${MOCK_REMOTE_STATUS:-active}"
            ;;
        *"cat /etc/systemd/system/test-service.service"*)
            echo "${MOCK_REMOTE_CONFIG:-[Unit]
Description=Test Service}"
            ;;
        *"sudo systemctl start"*)
            MOCK_REMOTE_STATUS="active"
            return 0
            ;;
        *"sudo systemctl stop"*)
            MOCK_REMOTE_STATUS="inactive"
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

mock_systemctl() {
    case "$*" in
        "is-active ${TEST_SERVICE_NAME}")
            echo "${MOCK_LOCAL_STATUS:-active}"
            ;;
        *)
            return 0
            ;;
    esac
}

# Setup test environment
setup_test_env() {
    set_test_group "Environment Setup"
    
    # Override commands with mocks
    ssh() { mock_ssh "$@"; }
    systemctl() { mock_systemctl "$@"; }
    
    # Create test files
    echo "[Unit]
Description=Test Service" > "/tmp/test-service.service"
    
    # Override global variables
    SYNC_LOCK_FILE="${TEST_LOCK_FILE}"
    SYNC_STATUS_FILE="${TEST_STATUS_FILE}"
    SYNC_INTERVAL=1  # Speed up tests
    
    # Reset mock states
    MOCK_LOCAL_STATUS="active"
    MOCK_REMOTE_STATUS="active"
    
    # Verify setup
    assert_true "[[ -f /tmp/test-service.service ]]" "Test service file creation"
}

# Test lock file mechanism
test_sync_lock() {
    set_test_group "Sync Lock"
    
    # Test lock acquisition
    rm -f "${TEST_LOCK_FILE}"
    assert_success "check_sync_lock" "Initial lock acquisition"
    
    # Test lock file creation
    assert_true "[[ -f ${TEST_LOCK_FILE} ]]" "Lock file creation"
    
    # Test lock prevention
    assert_failure "check_sync_lock" "Lock prevention"
    
    # Test stale lock removal
    echo "999999" > "${TEST_LOCK_FILE}"
    assert_success "check_sync_lock" "Stale lock removal"
}

# Test service status sync
test_service_status_sync() {
    set_test_group "Service Status Sync"
    
    # Test matching status
    MOCK_LOCAL_STATUS="active"
    MOCK_REMOTE_STATUS="active"
    assert_success "sync_service_status ${TEST_REMOTE_HOST} ${TEST_REMOTE_USER} ${TEST_SERVICE_NAME}" "Matching status sync"
    
    # Test status mismatch - local active, remote inactive
    MOCK_LOCAL_STATUS="active"
    MOCK_REMOTE_STATUS="inactive"
    assert_success "sync_service_status ${TEST_REMOTE_HOST} ${TEST_REMOTE_USER} ${TEST_SERVICE_NAME}" "Status mismatch handling - start remote"
    assert_equals "${MOCK_REMOTE_STATUS}" "active" "Remote service started"
    
    # Test status mismatch - local inactive, remote active
    MOCK_LOCAL_STATUS="inactive"
    MOCK_REMOTE_STATUS="active"
    assert_success "sync_service_status ${TEST_REMOTE_HOST} ${TEST_REMOTE_USER} ${TEST_SERVICE_NAME}" "Status mismatch handling - stop remote"
    assert_equals "${MOCK_REMOTE_STATUS}" "inactive" "Remote service stopped"
}

# Test service config sync
test_service_config_sync() {
    set_test_group "Service Config Sync"
    
    # Test matching configs
    MOCK_REMOTE_CONFIG="[Unit]
Description=Test Service"
    assert_success "sync_service_config ${TEST_REMOTE_HOST} ${TEST_REMOTE_USER} ${TEST_SERVICE_NAME}" "Matching config sync"
    
    # Test config mismatch
    MOCK_REMOTE_CONFIG="[Unit]
Description=Different Service"
    assert_success "sync_service_config ${TEST_REMOTE_HOST} ${TEST_REMOTE_USER} ${TEST_SERVICE_NAME}" "Config mismatch handling"
}

# Test cleanup
test_cleanup() {
    set_test_group "Cleanup"
    
    # Create lock file
    touch "${TEST_LOCK_FILE}"
    assert_true "[[ -f ${TEST_LOCK_FILE} ]]" "Lock file exists"
    
    # Test cleanup
    cleanup
    assert_false "[[ -f ${TEST_LOCK_FILE} ]]" "Lock file removal"
}

# Test main function argument validation
test_main_args() {
    set_test_group "Main Arguments"
    
    # Test missing arguments
    assert_failure "main" "No arguments"
    assert_failure "main ${TEST_REMOTE_HOST}" "Missing user and service"
    assert_failure "main ${TEST_REMOTE_HOST} ${TEST_REMOTE_USER}" "Missing service"
    
    # Test valid arguments
    # Note: We don't actually run main here as it's an infinite loop
    true
}

# Run all tests
echo -e "${YELLOW}=== Running Service Sync Tests ===${NC}"
setup_test_env
test_sync_lock
test_service_status_sync
test_service_config_sync
test_cleanup
test_main_args

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
