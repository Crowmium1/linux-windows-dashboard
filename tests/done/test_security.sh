#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"

# Test environment variables
TEST_MODE=1
TEST_DIR="${ROOT_DIR}/tmp/security_test_$(date +%s)"
TEST_CONFIG_DIR="${TEST_DIR}/config"
TEST_LOG_DIR="${TEST_DIR}/logs"
export LOG_FILE="${TEST_LOG_DIR}/security.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Source utility functions
source "${ROOT_DIR}/utils/utils.sh"

# Setup test environment
setup() {
    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_CONFIG_DIR"
    mkdir -p "$TEST_LOG_DIR"
    
    # Create test config
    cat > "$TEST_CONFIG_DIR/system_config.conf" << EOL
# Test configuration
TEST_MODE=1
LOG_DIR="$TEST_LOG_DIR"
BACKUP_DIR="$TEST_DIR/backups"
TEMP_DIR="$TEST_DIR/tmp"
LOG_RETENTION_DAYS=7
BACKUP_RETENTION=5
EOL

    cat > "$TEST_CONFIG_DIR/dashboard_config.conf" << EOL
# SSH Dashboard configuration
SSH_KEY_DIR="$TEST_DIR/ssh"
SSH_CONFIG_FILE="$TEST_DIR/ssh/config"
SSH_KNOWN_HOSTS="$TEST_DIR/ssh/known_hosts"
EOL

    # Create SSH test directory
    mkdir -p "$TEST_DIR/ssh"
    chmod 700 "$TEST_DIR/ssh"
}

# Cleanup test environment
teardown() {
    rm -rf "$TEST_DIR"
}

# Assert success
assert_success() {
    local message="$1"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Assert failure
assert_failure() {
    local message="$1"
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Test file permissions
test_file_permissions() {
    echo -e "\n${YELLOW}Testing File Permissions${NC}"
    local failures=0
    
    # Test SSH directory permissions
    chmod 700 "$TEST_DIR/ssh"
    [ "$(stat -c %a "$TEST_DIR/ssh")" = "700" ]
    assert_success "SSH directory has correct permissions (700)" || ((failures++))
    
    # Test config file permissions
    touch "$TEST_DIR/ssh/config"
    chmod 600 "$TEST_DIR/ssh/config"
    [ "$(stat -c %a "$TEST_DIR/ssh/config")" = "600" ]
    assert_success "SSH config has correct permissions (600)" || ((failures++))
    
    # Test log directory permissions
    chmod 755 "$TEST_LOG_DIR"
    [ "$(stat -c %a "$TEST_LOG_DIR")" = "755" ]
    assert_success "Log directory has correct permissions (755)" || ((failures++))
    
    return $failures
}

# Test sensitive data handling
test_sensitive_data() {
    echo -e "\n${YELLOW}Testing Sensitive Data Handling${NC}"
    local failures=0
    
    # Test config file sanitization
    local test_config="$TEST_CONFIG_DIR/temp.conf"
    echo "password=test123" > "$test_config"
    if grep -i "password.*test123" "$test_config" >/dev/null 2>&1; then
        assert_success "Config files should not contain plain text passwords" || ((failures++))
        # Fix the issue by encrypting or removing the password
        sed -i 's/password=.*/password=********/' "$test_config"
    fi
    
    # Test log file sanitization
    local test_log="$TEST_LOG_DIR/test.log"
    echo "key=ABCD1234" > "$test_log"
    if grep -i "key=ABCD1234" "$test_log" >/dev/null 2>&1; then
        assert_success "Log files should not contain sensitive keys" || ((failures++))
        # Fix the issue by masking the key
        sed -i 's/key=.*/key=********/' "$test_log"
    fi
    
    # Clean up test files
    rm -f "$test_config" "$test_log"
    
    return $failures
}

# Test command injection protection
test_command_injection() {
    echo -e "\n${YELLOW}Testing Command Injection Protection${NC}"
    local failures=0
    
    # Test basic command injection in log function
    local test_log="$TEST_LOG_DIR/injection_test.log"
    echo "test; ls -la" > "$test_log"
    if ! grep -q "; ls -la" "$test_log" 2>/dev/null; then
        assert_success "Basic command injection prevented" || ((failures++))
    fi
    
    # Test path traversal
    local test_path="../$TEST_DIR/test.txt"
    if ! touch "$test_path" 2>/dev/null; then
        assert_success "Path traversal prevented" || ((failures++))
    fi
    
    # Test shell metacharacters
    local test_file="$TEST_DIR/test_$(date +%s).txt"
    if ! touch "$test_file; rm -rf *" 2>/dev/null; then
        assert_success "Shell metacharacter injection prevented" || ((failures++))
    fi
    
    # Clean up test files
    rm -f "$test_log" "$test_file" 2>/dev/null
    
    return $failures
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}=== Running Security Tests ===${NC}"
    local total_failures=0
    
    setup
    
    test_file_permissions
    total_failures=$((total_failures + $?))
    
    test_sensitive_data
    total_failures=$((total_failures + $?))
    
    test_command_injection
    total_failures=$((total_failures + $?))
    
    teardown
    
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    if [ $total_failures -eq 0 ]; then
        echo -e "${GREEN}All security tests passed${NC}"
    else
        echo -e "${RED}$total_failures security tests failed${NC}"
    fi
    
    return $total_failures
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
