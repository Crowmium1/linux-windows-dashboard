#!/bin/bash

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"

# Source utility functions
source "${ROOT_DIR}/utils/utils.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test environment variables
TEST_MODE=1
TEST_DIR="${ROOT_DIR}/tmp/collect_test_$(date +%Y%m%d_%H%M%S)"
TEST_CONFIG_DIR="${TEST_DIR}/config"
TEST_LOG_DIR="${TEST_DIR}/logs"
export LOG_FILE="${TEST_LOG_DIR}/collect_test.log"

# Error handling
set -e  # Exit on error
trap 'cleanup' EXIT
trap 'handle_interrupt' INT TERM

# Cleanup function
cleanup() {
    local exit_code=$?
    if [ -d "$TEST_DIR" ]; then
        find "$TEST_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
        find "$TEST_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
        rm -rf "$TEST_DIR"
    fi
    exit $exit_code
}

# Handle interrupt
handle_interrupt() {
    echo -e "\n${RED}Script interrupted by user${NC}"
    cleanup
    exit 1
}

# Check if running in WSL
is_wsl() {
    if uname -r | grep -qi microsoft; then
        return 0  # true in bash
    else
        return 1  # false in bash
    fi
}

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_status="${3:-0}"  # Default to expecting success
    
    echo -n "Testing $test_name... "
    
    eval "$test_command" > /dev/null 2>&1
    local status=$?
    
    if [ $status -eq $expected_status ]; then
        echo -e "${GREEN}PASSED${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "Expected status: $expected_status, got: $status"
        return 1
    fi
}

# Setup test environment
setup() {
    # Create test directories
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

# Test system info collection
test_system_info() {
    echo -e "\n${YELLOW}Testing System Info Collection${NC}"
    local failures=0
    
    # Test memory info
    run_test "collect memory info" "free -h > '$TEST_LOG_DIR/memory.log'" || ((failures++))
    
    # Test disk usage
    run_test "collect disk usage" "df -h > '$TEST_LOG_DIR/disk.log'" || ((failures++))
    
    # Test system load
    run_test "collect load average" "uptime > '$TEST_LOG_DIR/load.log'" || ((failures++))
    
    # Test process list
    run_test "collect process list" "ps aux > '$TEST_LOG_DIR/processes.log'" || ((failures++))
    
    # Test network info (skip some in WSL)
    if ! is_wsl; then
        run_test "collect network info" "ip addr show > '$TEST_LOG_DIR/network.log'" || ((failures++))
    else
        echo -e "${YELLOW}Note: Skipping some network tests in WSL${NC}"
    fi
    
    return $failures
}

# Test SSH info collection
test_ssh_info() {
    echo -e "\n${YELLOW}Testing SSH Info Collection${NC}"
    local failures=0
    
    # Create test SSH files
    mkdir -p "$TEST_DIR/ssh"
    touch "$TEST_DIR/ssh/config"
    touch "$TEST_DIR/ssh/known_hosts"
    
    # Test SSH config collection
    run_test "collect SSH config" "cp '$TEST_DIR/ssh/config' '$TEST_LOG_DIR/ssh_config.log'" || ((failures++))
    
    # Test SSH known hosts collection
    run_test "collect known hosts" "cp '$TEST_DIR/ssh/known_hosts' '$TEST_LOG_DIR/known_hosts.log'" || ((failures++))
    
    return $failures
}

# Test log handling
test_logging() {
    echo -e "\n${YELLOW}Testing Log Handling${NC}"
    local failures=0
    
    # Test log directory creation
    run_test "create log directory" "mkdir -p '$TEST_LOG_DIR'" || ((failures++))
    
    # Test log file creation
    run_test "create log file" "touch '$LOG_FILE'" || ((failures++))
    
    # Test log file write
    run_test "write to log file" "echo 'Test log entry' >> '$LOG_FILE'" || ((failures++))
    
    return $failures
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}=== Running System Info Collection Tests ===${NC}"
    local total_failures=0
    
    setup
    
    test_system_info
    total_failures=$((total_failures + $?))
    
    test_ssh_info
    total_failures=$((total_failures + $?))
    
    test_logging
    total_failures=$((total_failures + $?))
    
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    if [ $total_failures -eq 0 ]; then
        echo -e "${GREEN}All tests passed${NC}"
    else
        echo -e "${RED}$total_failures tests failed${NC}"
    fi
    
    return $total_failures
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
