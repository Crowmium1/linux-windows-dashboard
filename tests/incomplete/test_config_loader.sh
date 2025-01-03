#!/bin/bash

# Source test utilities and configs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test utilities
source "${ROOT_DIR}/utils/test_helpers.sh"
source "${ROOT_DIR}/utils/utils.sh"

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
    
    # Create test configs
    cat > "${TEST_CONFIG_DIR}/main_config.yaml" << EOL
MONITOR_INTERVAL: 60
CPU_THRESHOLD: 80
MEMORY_THRESHOLD: 90
SSH_PORT: 22
EOL
    
    # Create test environment configs
    cat > "${TEST_CONFIG_DIR}/environments/test.yaml" << EOL
LOG_DIR: '${TEST_LOG_DIR}'
DATA_DIR: '${TEST_DATA_DIR}'
TEMP_DIR: '${TEST_TEMP_DIR}'
SSH_CMD: '/usr/bin/ssh'
SSH_KEYGEN: '/usr/bin/ssh-keygen'
USE_POWERSHELL: false
PATH_SEPARATOR: '/'
EOL
    
    # Verify setup
    assert_path "${TEST_CONFIG_DIR}/main_config.yaml" "file" "Main config creation"
    assert_path "${TEST_CONFIG_DIR}/environments/test.yaml" "file" "Environment config creation"
}

# Test environment detection
function test_environment_detection() {
    set_test_group "Environment Detection"
    
    # Test WSL detection
    (
        export WSL_DISTRO_NAME="Ubuntu"
        assert_equals "$(detect_environment)" "wsl" "WSL detection"
    )
    
    # Test Linux detection
    (
        unset WSL_DISTRO_NAME
        export OSTYPE="linux-gnu"
        assert_equals "$(detect_environment)" "linux" "Linux detection"
    )
    
    # Test Windows detection
    (
        unset WSL_DISTRO_NAME
        export OSTYPE="msys"
        assert_equals "$(detect_environment)" "windows" "Windows detection"
    )
}

# Test config loading
function test_config_loading() {
    set_test_group "Config Loading"
    
    # Test valid config
    (
        export TEST_ENV="test"
        assert_success "load_environment_config" "Valid config loading"
        assert_equals "${LOG_DIR}" "${TEST_LOG_DIR}" "LOG_DIR setting"
        assert_equals "${SSH_CMD}" "/usr/bin/ssh" "SSH_CMD setting"
    )
    
    # Test invalid config
    (
        export TEST_ENV="nonexistent"
        assert_failure "load_environment_config" "Invalid config detection"
    )
    
    # Test required variables
    (
        export TEST_ENV="test"
        sed -i 's/LOG_DIR/INVALID_DIR/' "${TEST_CONFIG_DIR}/environments/test.yaml"
        assert_failure "load_environment_config" "Missing required variable detection"
        # Restore config
        setup_test_env
    )
}

# Test config retrieval
function test_config_retrieval() {
    set_test_group "Config Retrieval"
    
    # Load test config
    export TEST_ENV="test"
    load_environment_config
    
    # Test getting existing value
    assert_equals "$(get_config LOG_DIR)" "${TEST_LOG_DIR}" "Get existing config"
    
    # Test getting value with default
    assert_equals "$(get_config NONEXISTENT default)" "default" "Get default value"
    
    # Test getting empty value
    assert_equals "$(get_config EMPTY_VAR)" "" "Get empty value"
}

# Test directory creation
function test_directory_creation() {
    set_test_group "Directory Creation"
    
    # Remove test directories
    rm -rf "${TEST_LOG_DIR}" "${TEST_DATA_DIR}" "${TEST_TEMP_DIR}"
    
    # Load config (should create directories)
    export TEST_ENV="test"
    load_environment_config
    
    # Verify directories
    assert_path "${TEST_LOG_DIR}" "directory" "Log directory creation"
    assert_path "${TEST_DATA_DIR}" "directory" "Data directory creation"
    assert_path "${TEST_TEMP_DIR}" "directory" "Temp directory creation"
}

# Run all tests
echo -e "${YELLOW}=== Running Configuration Tests ===${NC}"
setup_test_env
test_environment_detection
test_config_loading
test_config_retrieval
test_directory_creation

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
