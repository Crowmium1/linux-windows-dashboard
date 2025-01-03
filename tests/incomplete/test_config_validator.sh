#!/bin/bash

# Source test utilities and configs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test utilities
source "${ROOT_DIR}/utils/test_helpers.sh"
source "${ROOT_DIR}/utils/utils.sh"
source "${ROOT_DIR}/lib/config/validator.sh"

# Set test environment
export TEST_MODE=true
export DEBUG=true

# Override paths for testing
TEST_BASE_DIR="${ROOT_DIR}/tests/var"
TEST_CONFIG_DIR="${TEST_BASE_DIR}/config"
TEST_LOG_DIR="${TEST_BASE_DIR}/log"
TEST_DATA_DIR="${TEST_BASE_DIR}/data"
TEST_TEMP_DIR="${TEST_BASE_DIR}/tmp"

# Initialize test environment
function setup_test_env() {
    set_test_group "Environment Setup"
    
    # Create test directories
    mkdir -p "${TEST_CONFIG_DIR}/environments"
    mkdir -p "${TEST_LOG_DIR}"
    mkdir -p "${TEST_DATA_DIR}"
    mkdir -p "${TEST_TEMP_DIR}"
    
    # Create valid main config
    cat > "${TEST_CONFIG_DIR}/main_config.yaml" << EOL
# Main configuration
MONITOR_INTERVAL: 60
CPU_THRESHOLD: 80
MEMORY_THRESHOLD: 90
DISK_THRESHOLD: 85
SSH_PORT: 22
SSH_KEY_TYPE: 'rsa'
SSH_KEY_BITS: 4096
EOL
    
    # Create valid environment config
    cat > "${TEST_CONFIG_DIR}/environments/test.yaml" << EOL
# Test environment configuration
LOG_DIR: '${TEST_LOG_DIR}'
DATA_DIR: '${TEST_DATA_DIR}'
TEMP_DIR: '${TEST_TEMP_DIR}'
SSH_CMD: '/usr/bin/ssh'
SSH_KEYGEN: '/usr/bin/ssh-keygen'
PATH_SEPARATOR: '/'
EOL
    
    # Verify setup
    assert_path "${TEST_CONFIG_DIR}/main_config.yaml" "file" "Main config creation"
    assert_path "${TEST_CONFIG_DIR}/environments/test.yaml" "file" "Environment config creation"
}

# Test numeric validation
function test_numeric_validation() {
    set_test_group "Numeric Validation"
    
    # Test valid numbers
    assert_true "is_numeric '42'" "Integer validation"
    assert_true "is_numeric '3.14'" "Float validation"
    
    # Test invalid numbers
    assert_false "is_numeric 'abc'" "String rejection"
    assert_false "is_numeric '12.34.56'" "Invalid float rejection"
    assert_false "is_numeric ''" "Empty string rejection"
}

# Test path validation
function test_path_validation() {
    set_test_group "Path Validation"
    
    # Test valid paths
    assert_true "is_absolute_path '/usr/bin'" "Unix path validation"
    assert_true "is_absolute_path 'C:\\Windows'" "Windows path validation"
    
    # Test invalid paths
    assert_false "is_absolute_path 'usr/bin'" "Relative Unix path rejection"
    assert_false "is_absolute_path 'Windows\\System32'" "Relative Windows path rejection"
}

# Test main config validation
function test_main_config_validation() {
    set_test_group "Main Config Validation"
    
    # Test valid config
    assert_success "validate_main_config '${TEST_CONFIG_DIR}/main_config.yaml'" "Valid main config"
    
    # Test missing required field
    sed -i 's/MONITOR_INTERVAL: 60/# MONITOR_INTERVAL: 60/' "${TEST_CONFIG_DIR}/main_config.yaml"
    assert_failure "validate_main_config '${TEST_CONFIG_DIR}/main_config.yaml'" "Missing field detection"
    setup_test_env  # Restore valid config
    
    # Test invalid threshold
    sed -i 's/CPU_THRESHOLD: 80/CPU_THRESHOLD: 150/' "${TEST_CONFIG_DIR}/main_config.yaml"
    assert_failure "validate_main_config '${TEST_CONFIG_DIR}/main_config.yaml'" "Invalid threshold detection"
    setup_test_env  # Restore valid config
    
    # Test invalid SSH key type
    sed -i 's/SSH_KEY_TYPE: .rsa./SSH_KEY_TYPE: .invalid./' "${TEST_CONFIG_DIR}/main_config.yaml"
    assert_failure "validate_main_config '${TEST_CONFIG_DIR}/main_config.yaml'" "Invalid SSH key type detection"
    setup_test_env  # Restore valid config
}

# Test environment config validation
function test_env_config_validation() {
    set_test_group "Environment Config Validation"
    
    # Test valid config
    assert_success "validate_env_config '${TEST_CONFIG_DIR}/environments/test.yaml'" "Valid environment config"
    
    # Test missing required field
    sed -i 's/SSH_CMD: .usr.bin.ssh./# SSH_CMD: .usr.bin.ssh./' "${TEST_CONFIG_DIR}/environments/test.yaml"
    assert_failure "validate_env_config '${TEST_CONFIG_DIR}/environments/test.yaml'" "Missing field detection"
    setup_test_env  # Restore valid config
    
    # Test invalid path separator
    sed -i 's/PATH_SEPARATOR: .\\/.\/PATH_SEPARATOR: .invalid./' "${TEST_CONFIG_DIR}/environments/test.yaml"
    assert_failure "validate_env_config '${TEST_CONFIG_DIR}/environments/test.yaml'" "Invalid path separator detection"
    setup_test_env  # Restore valid config
    
    # Test invalid directory path
    sed -i "s|LOG_DIR: '${TEST_LOG_DIR}'|LOG_DIR: 'relative/path'|" "${TEST_CONFIG_DIR}/environments/test.yaml"
    assert_failure "validate_env_config '${TEST_CONFIG_DIR}/environments/test.yaml'" "Invalid directory path detection"
    setup_test_env  # Restore valid config
}

# Test complete validation
function test_complete_validation() {
    set_test_group "Complete Validation"
    
    # Test all valid configs
    assert_success "validate_all_configs '${TEST_CONFIG_DIR}'" "All valid configs"
    
    # Test with invalid main config
    sed -i 's/SSH_PORT: 22/SSH_PORT: invalid/' "${TEST_CONFIG_DIR}/main_config.yaml"
    assert_failure "validate_all_configs '${TEST_CONFIG_DIR}'" "Invalid main config detection"
    setup_test_env  # Restore valid config
    
    # Test with invalid environment config
    sed -i 's/SSH_KEYGEN: .usr.bin.ssh-keygen./SSH_KEYGEN: relative.path/' "${TEST_CONFIG_DIR}/environments/test.yaml"
    assert_failure "validate_all_configs '${TEST_CONFIG_DIR}'" "Invalid environment config detection"
    setup_test_env  # Restore valid config
}

# Run all tests
echo -e "${YELLOW}=== Running Config Validator Tests ===${NC}"
setup_test_env
test_numeric_validation
test_path_validation
test_main_config_validation
test_env_config_validation
test_complete_validation

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
