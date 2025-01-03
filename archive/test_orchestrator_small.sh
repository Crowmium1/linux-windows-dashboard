#!/bin/bash

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Set and export TEST_MODE
export TEST_MODE=1

# Source test helpers
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Test environment variables
TEST_DIR="$ROOT_DIR/tmp/test"
LOG_DIR="$ROOT_DIR/log/test"
VAR_DIR="$ROOT_DIR/var/test"

# Test specific variables
TOOLKIT_SCRIPT="$ROOT_DIR/core/prepare_ssh_toolkit.sh"
TEST_ROOT="$TEST_DIR/ssh_toolkit_test"
CONFIG_DIR="$ROOT_DIR/config"

# Required toolkit files
CORE_FILES=(
    "$ROOT_DIR/core/system_monitor.sh"
    "$ROOT_DIR/core/collect_system_info.sh"
    "$ROOT_DIR/core/monitor_helper.sh"
)

UTILS_FILES=(
    "$ROOT_DIR/utils/utils.sh"
    "$ROOT_DIR/utils/keyring_diagnostic.sh"
    "$ROOT_DIR/utils/cleanup.sh"
)

CONFIG_FILES=(
    "$ROOT_DIR/config/main_config.conf"
    "$ROOT_DIR/config/ssh_config"
)

# Initialize test environment
setup_test_env() {
    mkdir -p "$TEST_ROOT"
    chmod 755 "$TEST_ROOT"
    
    # Create test log file
    touch "$TEST_ROOT/test.log"
    chmod 644 "$TEST_ROOT/test.log"
}

# Test environment setup
setup() {
    echo "Starting environment setup..."
    set_test_group "Environment Setup"
    
    # Create test config
    echo "Creating test config..."
    cat > "$TEST_ROOT/config.conf" << EOL
# Test Configuration
TEST_MODE=1
TOOLKIT_DIR="$TEST_ROOT/ssh_toolkit"
LOG_FILE="$TEST_ROOT/test.log"
EOL
    
    # Create tools directory
    mkdir -p "$TEST_ROOT/tools"
    
    # Verify setup
    assert_path "$TEST_ROOT/config.conf" "file" "Config file creation"
    assert_path "$TEST_ROOT/tools" "dir" "Tools directory creation"
}

# Test toolkit preparation
test_toolkit_preparation() {
    set_test_group "Toolkit Preparation"
    
    # Test with valid config
    assert_success "$TOOLKIT_SCRIPT --config $TEST_ROOT/config.conf" "Toolkit preparation with valid config"
    
    # Verify core files
    for file in "${CORE_FILES[@]}"; do
        assert_path "$TEST_ROOT/ssh_toolkit/$(basename "$file")" "file" "$(basename "$file") exists"
    done
}

# Test error handling
test_error_handling() {
    set_test_group "Error Handling"
    
    # Test with invalid config
    assert_failure "$TOOLKIT_SCRIPT --config invalid.conf" "Invalid config detection"
    
    # Test with read-only directory
    chmod 444 "$TEST_ROOT"
    assert_failure "$TOOLKIT_SCRIPT --config $TEST_ROOT/config.conf" "Read-only directory handling"
    chmod 755 "$TEST_ROOT"
    
    # Test with missing directory
    rm -rf "$TEST_ROOT/tools"
    assert_failure "$TOOLKIT_SCRIPT --config $TEST_ROOT/config.conf" "Missing directory handling"
}

# Test toolkit validation
test_toolkit_validation() {
    set_test_group "Toolkit Validation"
    
    # Test with incomplete toolkit
    rm -f "$TEST_ROOT/ssh_toolkit/"*
    assert_failure "$TOOLKIT_SCRIPT --validate --config $TEST_ROOT/config.conf" "Incomplete toolkit detection"
    
    # Test with complete toolkit
    mkdir -p "$TEST_ROOT/ssh_toolkit"
    for file in "${CORE_FILES[@]}" "${UTILS_FILES[@]}" "${CONFIG_FILES[@]}"; do
        cp "$file" "$TEST_ROOT/ssh_toolkit/"
    done
    assert_success "$TOOLKIT_SCRIPT --validate --config $TEST_ROOT/config.conf" "Complete toolkit validation"
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
