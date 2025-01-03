#!/bin/bash

# Set test mode and test directories first
export TEST_MODE=1
TEST_DIR="/tmp/system_monitor_test_$(date +%s)"
mkdir -p "$TEST_DIR/logs"
export TEST_LOG_DIR="$TEST_DIR/logs"
export LOG_FILE="$TEST_LOG_DIR/system_monitor.log"

# Source the scripts
source ../core/system_monitor.sh

# Source the environment setup
if [ -f "../utils/utils.sh" ]; then
    source "../utils/utils.sh"
fi

# Mock functions
mock_sensors() {
    echo "Package id 0: +45.0°C"
}

mock_systemctl() {
    echo "active"
}

mock_tee() {
    echo "$1" >> "$LOG_FILE"
}

# Override functions that require root
check_root() {
    return 0  # Always succeed in test mode
}

# Test cases for WSL environment
test_handle_error() {
    local result
    result=$(handle_error "Test error" 2>&1)
    if [[ $result == *"ERROR: Test error"* ]]; then
        echo "✓ handle_error test passed"
    else
        echo "✗ handle_error test failed"
    fi
}

test_check_dependencies() {
    local result
    result=$(check_dependencies 2>&1)
    if [[ $result == *"Test mode: Skipping dependency checks"* ]]; then
        echo "✓ check_dependencies test passed"
    else
        echo "✗ check_dependencies test failed"
    fi
}

test_check_gpu() {
    echo "Testing GPU check in WSL..."
    local result
    result=$(check_gpu 2>&1)
    
    if is_wsl; then
        if [[ $result == *"Limited GPU information in WSL"* ]]; then
            echo "✓ GPU check test passed (WSL handling)"
            return 0
        fi
    elif is_test_mode; then
        if [[ $result == *"Test mode: Simulating GPU check"* ]]; then
            echo "✓ GPU check test passed (test mode)"
            return 0
        fi
    fi
    
    echo "✗ GPU check test failed"
    return 1
}

test_check_services() {
    echo "Testing service checks in WSL..."
    local result
    result=$(check_services 2>&1)
    
    if is_wsl; then
        if [[ $result == *"not available in WSL"* ]]; then
            echo "✓ Service check test passed (WSL handling)"
            return 0
        fi
    elif is_test_mode; then
        if [[ $result == *"active"* ]]; then
            echo "✓ Service check test passed (test mode)"
            return 0
        fi
    fi
    
    echo "✗ Service check test failed"
    return 1
}

test_log() {
    local test_message="Test log message"
    
    # Clear the log file first
    > "$LOG_FILE"
    
    # Test logging
    log "$test_message"
    
    if [[ -f "$LOG_FILE" && $(cat "$LOG_FILE") == *"$test_message"* ]]; then
        echo "✓ log test passed"
        return 0
    fi
    
    echo "✗ log test failed"
    return 1
}

cleanup() {
    # Cleanup test directory
    rm -rf "$TEST_DIR"
}

# Set up trap for cleanup
trap cleanup EXIT

# Run tests
echo "Running system_monitor.sh tests in WSL environment..."
test_handle_error
test_check_dependencies
test_check_gpu
test_check_services
test_log
