#!/bin/bash

# Source test utilities
. "$TEST_BASE_DIR/utils/test_helpers.sh"

# Set and export TEST_MODE
export TEST_MODE=1

# Source dependencies
source "$LIB_DIR/utils.sh"

# Required toolkit files
CORE_FILES=(
    "$CORE_DIR/system_monitor.sh"
    "$CORE_DIR/collect_system_info.sh"
    "$CORE_DIR/monitor_helper.sh"
)

UTILS_FILES=(
    "$LIB_DIR/utils.sh"
    "$LIB_DIR/cleanup.sh"
    "$LIB_DIR/keyring_diagnostic.sh"
)

SSH_FILES=(
    "$CORE_DIR/ssh_manager.sh"
    "$CORE_DIR/setup_environment.sh"
    "$CORE_DIR/setup_passwordless_ssh.sh"
)

CONFIG_FILES=(
    "$CONFIG_DIR/main_config.conf"
    "$CONFIG_DIR/ssh_config"
)

# Initialize test environment
function setup_test_env() {
    # Create test directories if they don't exist
    mkdir -p "$TEST_BASE_DIR/var/data/orchestrator"
    mkdir -p "$TEST_BASE_DIR/var/log"
    mkdir -p "$TEST_BASE_DIR/var/tmp"
    
    # Clean test directory
    rm -rf "${TEST_BASE_DIR:?}/var/data/orchestrator/"*
    
    # Copy config files
    cp "$CONFIG_DIR/main_config.conf" "$TEST_CONFIG_DIR/"
    cp "$CONFIG_DIR/ssh_config" "$TEST_CONFIG_DIR/"
    
    # Create test log file
    touch "$TEST_BASE_DIR/var/log/orchestrator/orchestrator_test.log"
    chmod 644 "$TEST_BASE_DIR/var/log/orchestrator/orchestrator_test.log"
}

# Test setup
function setup() {
    set_test_group "Environment Setup"
    
    # Create test config
    cat > "$TEST_CONFIG_DIR/orchestrator_config.conf" << EOL
# Test Configuration
TEST_MODE=1
TOOLKIT_DIR="$TEST_BASE_DIR/var/data/orchestrator/toolkit"
LOG_FILE="$TEST_BASE_DIR/var/log/orchestrator/orchestrator_test.log"
EOL
    
    # Create tools directory
    mkdir -p "$TEST_BASE_DIR/var/data/orchestrator/tools"
    
    # Verify setup
    assert_path "$TEST_CONFIG_DIR/orchestrator_config.conf" "file" "Config file creation"
    assert_path "$TEST_BASE_DIR/var/data/orchestrator/tools" "dir" "Tools directory creation"
    assert_path "$TEST_BASE_DIR/var/log/orchestrator/orchestrator_test.log" "file" "Log file creation"
}

# Test toolkit preparation
function test_toolkit_preparation() {
    set_test_group "Toolkit Preparation"
    
    # Test with valid config
    "$CORE_DIR/orchestrator.sh" --config "$TEST_CONFIG_DIR/main_config.conf"
    assertTrue "Toolkit preparation should succeed" $?
    
    # Verify core files
    for file in "${CORE_FILES[@]}"; do
        assertTrue "Core file $(basename "$file") should exist" "[ -f "$TEST_BASE_DIR/var/data/orchestrator/$(basename "$file")" ]"
    done
}

# Test error handling
function test_error_handling() {
    set_test_group "Error Handling"
    
    # Test with invalid config
    assert_failure "$CORE_DIR/orchestrator.sh --config invalid.conf" "Invalid config detection"
    
    # Test with read-only directory
    chmod 444 "$TEST_BASE_DIR/var/data/orchestrator"
    assert_failure "$CORE_DIR/orchestrator.sh --config $TEST_CONFIG_DIR/main_config.conf" "Read-only directory handling"
    chmod 755 "$TEST_BASE_DIR/var/data/orchestrator"
    
    # Test with missing directory
    rm -rf "$TEST_BASE_DIR/var/data/orchestrator/tools"
    assert_failure "$CORE_DIR/orchestrator.sh --config $TEST_CONFIG_DIR/main_config.conf" "Missing directory handling"
}

# Test toolkit validation
function test_toolkit_validation() {
    set_test_group "Toolkit Validation"
    
    # Test with incomplete toolkit
    rm -f "$TEST_BASE_DIR/var/data/orchestrator/toolkit/"*
    assert_failure "$CORE_DIR/orchestrator.sh --validate --config $TEST_CONFIG_DIR/main_config.conf" "Incomplete toolkit detection"
    
    # Test with complete toolkit
    mkdir -p "$TEST_BASE_DIR/var/data/orchestrator/toolkit"
    for file in "${CORE_FILES[@]}" "${UTILS_FILES[@]}" "${SSH_FILES[@]}" "${CONFIG_FILES[@]}"; do
        cp "$file" "$TEST_BASE_DIR/var/data/orchestrator/toolkit/"
    done
    assert_success "$CORE_DIR/orchestrator.sh --validate --config $TEST_CONFIG_DIR/main_config.conf" "Complete toolkit validation"
}

# Run all tests
echo
setup_test_env
setup
test_toolkit_preparation
test_error_handling
test_toolkit_validation

# Print test summary
print_test_summary
