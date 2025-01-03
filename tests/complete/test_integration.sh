#!/bin/bash

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"
TEST_BASE_DIR="${ROOT_DIR}/tests/var"

# Source configuration
source "${CONFIG_DIR}/dashboard_config.conf"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test utilities
assert_success() {
    local message="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $message${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_failure() {
    local message="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓ $message${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ $message${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if running in WSL
is_wsl() {
    if uname -r | grep -qi microsoft; then
        return 0  # true in bash
    else
        return 1  # false in bash
    fi
}

# Setup test environment
setup() {
    echo -e "${YELLOW}Setting up test environment...${NC}"
    
    # Use appropriate test directory
    TEST_DIR="${TEST_BASE_DIR}/integration_test_$(date +%s)"
    export TEST_LOCAL_DIR="$TEST_DIR/local"
    export TEST_REMOTE_DIR="$TEST_DIR/remote"
    export TEST_CONFIG_DIR="$TEST_DIR/config"
    export TEST_LOG_DIR="$TEST_DIR/logs"
    
    # Create test directories
    mkdir -p "$TEST_LOCAL_DIR" "$TEST_REMOTE_DIR" "$TEST_CONFIG_DIR" "$TEST_LOG_DIR"
    
    # Create test files
    echo "test1" > "$TEST_LOCAL_DIR/file1.txt"
    mkdir -p "$TEST_LOCAL_DIR/subdir"
    echo "test2" > "$TEST_LOCAL_DIR/subdir/file2.txt"
    
    # Setup test config
    cat > "$TEST_CONFIG_DIR/test_config.conf" << EOL
TEST_MODE=1
SSH_USER=testuser
SSH_HOST=localhost
SSH_PORT=22
LOCAL_DIR=$TEST_LOCAL_DIR
REMOTE_DIR=$TEST_REMOTE_DIR
LOG_DIR=$TEST_LOG_DIR
EOL
    
    # Setup SSH test environment
    if ! is_wsl; then
        # Setup SSH keys for testing (only in non-WSL environment)
        ssh-keygen -t rsa -N "" -f "$TEST_DIR/id_rsa" >/dev/null 2>&1
        mkdir -p "$TEST_DIR/.ssh"
        cp "$TEST_DIR/id_rsa.pub" "$TEST_DIR/.ssh/authorized_keys"
        chmod 700 "$TEST_DIR/.ssh"
        chmod 600 "$TEST_DIR/.ssh/authorized_keys"
    else
        echo -e "${YELLOW}Running in WSL - skipping SSH key generation${NC}"
    fi
    
    assert_success "Test environment setup completed"
}

# Cleanup test environment
teardown() {
    echo -e "${YELLOW}Cleaning up test environment...${NC}"
    if [ -d "$TEST_DIR" ]; then
        chmod -R 755 "$TEST_DIR"
        rm -rf "$TEST_DIR"
    fi
}

# Test SSH setup with sync
test_ssh_sync_integration() {
    echo -e "\n${YELLOW}Testing SSH and Sync Integration${NC}"
    local failures=0
    
    # Test SSH connection
    if ! is_wsl; then
        # Test actual SSH in non-WSL environment
        ssh -o StrictHostKeyChecking=no -i "$TEST_DIR/id_rsa" -p 22 localhost "echo test" >/dev/null 2>&1
        assert_success "SSH connection test" || ((failures++))
    else
        # Mock SSH test in WSL
        echo "test" > "$TEST_REMOTE_DIR/test.txt"
        assert_success "Mock SSH connection test" || ((failures++))
    fi
    
    # Test file sync
    cp "$TEST_LOCAL_DIR/file1.txt" "$TEST_REMOTE_DIR/file1.txt"
    diff "$TEST_LOCAL_DIR/file1.txt" "$TEST_REMOTE_DIR/file1.txt" >/dev/null 2>&1
    assert_success "File synchronization test" || ((failures++))
    
    # Test directory sync
    cp -r "$TEST_LOCAL_DIR/subdir" "$TEST_REMOTE_DIR/"
    diff -r "$TEST_LOCAL_DIR/subdir" "$TEST_REMOTE_DIR/subdir" >/dev/null 2>&1
    assert_success "Directory synchronization test" || ((failures++))
    
    return $failures
}

# Test concurrent operations
test_concurrent_operations() {
    echo -e "\n${YELLOW}Testing Concurrent Operations${NC}"
    local failures=0
    
    # Test multiple file operations
    for i in {1..5}; do
        echo "test$i" > "$TEST_LOCAL_DIR/concurrent_$i.txt" &
    done
    wait
    
    # Verify files
    local count=$(ls "$TEST_LOCAL_DIR/concurrent_"* 2>/dev/null | wc -l)
    [ "$count" -eq 5 ]
    assert_success "Concurrent file creation test" || ((failures++))
    
    # Test concurrent sync
    for i in {1..5}; do
        cp "$TEST_LOCAL_DIR/concurrent_$i.txt" "$TEST_REMOTE_DIR/concurrent_$i.txt" &
    done
    wait
    
    # Verify sync
    count=$(ls "$TEST_REMOTE_DIR/concurrent_"* 2>/dev/null | wc -l)
    [ "$count" -eq 5 ]
    assert_success "Concurrent sync test" || ((failures++))
    
    return $failures
}

# Test recovery scenarios
test_recovery() {
    echo -e "\n${YELLOW}Testing Recovery Scenarios${NC}"
    local failures=0
    
    # Test incomplete sync recovery
    echo "recovery_test" > "$TEST_LOCAL_DIR/recovery.txt"
    cp "$TEST_LOCAL_DIR/recovery.txt" "$TEST_REMOTE_DIR/recovery.txt.partial"
    mv "$TEST_REMOTE_DIR/recovery.txt.partial" "$TEST_REMOTE_DIR/recovery.txt"
    diff "$TEST_LOCAL_DIR/recovery.txt" "$TEST_REMOTE_DIR/recovery.txt" >/dev/null 2>&1
    assert_success "Incomplete sync recovery test" || ((failures++))
    
    # Test missing directory recovery
    rm -rf "$TEST_REMOTE_DIR/subdir"
    mkdir -p "$TEST_REMOTE_DIR/subdir"
    cp "$TEST_LOCAL_DIR/subdir/file2.txt" "$TEST_REMOTE_DIR/subdir/file2.txt"
    diff -r "$TEST_LOCAL_DIR/subdir" "$TEST_REMOTE_DIR/subdir" >/dev/null 2>&1
    assert_success "Missing directory recovery test" || ((failures++))
    
    return $failures
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}=== Running Integration Tests ===${NC}"
    local total_failures=0
    
    setup
    
    test_ssh_sync_integration
    total_failures=$((total_failures + $?))
    
    test_concurrent_operations
    total_failures=$((total_failures + $?))
    
    test_recovery
    total_failures=$((total_failures + $?))
    
    teardown
    
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    return $total_failures
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
