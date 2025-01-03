#!/bin/bash

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Initialize test environment
setup_test_env
TEST_ROOT="$TEST_DIR/env_test"

# Test environment setup
setup() {
    set_test_group "Environment Setup"
    
    # Create test directories
    setup_test_dir "$TEST_ROOT"
    mkdir -p "$TEST_ROOT/ssh"
    mkdir -p "$TEST_ROOT/config"
    mkdir -p "$TEST_ROOT/logs"
    
    # Create mock config
    cat > "$TEST_ROOT/config/env_config.conf" << EOL
SSH_USER=testuser
SSH_HOST=localhost
SSH_PORT=22
LOG_DIR=$TEST_ROOT/logs
MONITOR_INTERVAL=60
RETRY_INTERVAL=30
MAX_RETRIES=3
TEST_MODE=1
WSL_TEST=1
EOL
    
    # Verify setup
    assert_path "$TEST_ROOT/config/env_config.conf" "file" "Config file creation"
    assert_path "$TEST_ROOT/logs" "dir" "Log directory creation"
}

# Test environment validation
test_env_validation() {
    set_test_group "Environment Validation"
    
    # Test with valid config
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/env_config.conf" \
        "Environment setup with valid config"
    
    # Verify environment setup
    assert_path "$TEST_ROOT/logs" "writable" "Log directory is writable"
    assert_file_contains "$TEST_ROOT/config/env_config.conf" "SSH_USER" "Config contains SSH_USER"
    assert_file_contains "$TEST_ROOT/config/env_config.conf" "SSH_HOST" "Config contains SSH_HOST"
}

# Test directory permissions
test_directory_permissions() {
    set_test_group "Directory Permissions"
    
    # Test log directory permissions
    chmod 755 "$TEST_ROOT/logs"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/env_config.conf" \
        "Setup with correct log directory permissions"
    
    # Test with incorrect permissions
    chmod 444 "$TEST_ROOT/logs"
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/env_config.conf" \
        "Setup with incorrect log directory permissions"
    chmod 755 "$TEST_ROOT/logs"
}

# Test config validation
test_config_validation() {
    set_test_group "Config Validation"
    
    # Test with missing required fields
    cat > "$TEST_ROOT/config/invalid_config.conf" << EOL
SSH_USER=testuser
# Missing SSH_HOST
SSH_PORT=22
EOL
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/invalid_config.conf" \
        "Setup with missing required config"
    
    # Test with invalid port
    cat > "$TEST_ROOT/config/invalid_port.conf" << EOL
SSH_USER=testuser
SSH_HOST=localhost
SSH_PORT=invalid
EOL
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/invalid_port.conf" \
        "Setup with invalid port"
}

# Test environment variables
test_env_variables() {
    set_test_group "Environment Variables"
    
    # Test environment variable export
    assert_success "source $TEST_ROOT/config/env_config.conf && [ -n \"$SSH_USER\" ]" \
        "SSH_USER environment variable"
    assert_success "source $TEST_ROOT/config/env_config.conf && [ -n \"$SSH_HOST\" ]" \
        "SSH_HOST environment variable"
    assert_success "source $TEST_ROOT/config/env_config.conf && [ -n \"$SSH_PORT\" ]" \
        "SSH_PORT environment variable"
}

# Test logging setup
test_logging() {
    set_test_group "Logging Setup"
    
    # Test log file creation
    local test_log="$TEST_ROOT/logs/test.log"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/env_config.conf --log=$test_log" \
        "Setup with log file"
    assert_path "$test_log" "file" "Log file creation"
    assert_path "$test_log" "writable" "Log file is writable"
}

# Test SSH config setup
test_ssh_config() {
    set_test_group "SSH Config Setup"
    
    # Test with valid SSH config
    cp "$ROOT_DIR/config/ssh_config" "$TEST_ROOT/config/ssh_config"
    assert_success "REQUIRE_SSH_CONFIG=1 TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/env_config.conf" \
        "Setup with valid SSH config"
    assert_path "$HOME/.ssh/config" "file" "SSH config file exists"
    assert_file_contains "$HOME/.ssh/config" "Host ubuntu-remote" "SSH config contains host definition"
    
    # Test with missing SSH config
    rm -f "$TEST_ROOT/config/ssh_config"
    assert_failure "REQUIRE_SSH_CONFIG=1 TEST_MODE=1 ${ROOT_DIR}/ssh/setup_environment.sh --config=$TEST_ROOT/config/env_config.conf" \
        "Setup with missing SSH config"
}

# Run all tests
setup
test_env_validation
test_directory_permissions
test_config_validation
test_env_variables
test_logging
test_ssh_config

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
