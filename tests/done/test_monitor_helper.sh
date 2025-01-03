#!/bin/bash

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"
CORE_DIR="${ROOT_DIR}/core"

# Enable test mode
export TEST_MODE="true"

# Mock functions for testing
mock_ssh() {
    case "$*" in
        *"exit"*)
            return 0
            ;;
        *"mkdir -p"*)
            return 0
            ;;
        *"free -h"*)
            echo "              total        used        free      shared  buff/cache   available"
            echo "Mem:        8192000     2097152     4194304      102400     1900544     6094848"
            ;;
        *"df -h"*)
            echo "Filesystem     1K-blocks      Used Available Use% Mounted on"
            echo "/dev/sda1      61411456  12345678  49065778  21% /"
            ;;
        *"uptime"*)
            echo " 12:34:56 up 7 days, 1:23, 2 users, load average: 0.52, 0.58, 0.59"
            ;;
        *"sensors"*)
            echo "Package id 0: +45.0°C"
            ;;
        *"glxinfo"*)
            echo "OpenGL renderer string: Mock GPU"
            ;;
        *"./reboot_monitor.sh"*)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Override ssh for testing
ssh() { mock_ssh "$@"; }

# Override command check for testing
command() {
    case "$2" in
        "ssh")
            return 0
            ;;
        *)
            command "$@"
            ;;
    esac
}

# Source helper script and configuration
source "${CORE_DIR}/monitor_helper.sh"
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

# Test cases
test_validate_ssh_config() {
    echo -e "\n${YELLOW}Testing SSH Config Validation${NC}"
    local failures=0
    
    # Test valid config
    SSH_USER="test"
    SSH_HOST="localhost"
    SSH_PORT="22"
    validate_ssh_config
    assert_success "Valid SSH config test" || ((failures++))
    
    # Test invalid port
    SSH_PORT="invalid"
    validate_ssh_config
    assert_failure "Invalid port test" || ((failures++))
    
    # Test empty host
    SSH_PORT="22"
    SSH_HOST=""
    validate_ssh_config
    assert_failure "Empty host test" || ((failures++))
    
    return $failures
}

test_check_ssh() {
    echo -e "\n${YELLOW}Testing SSH Connection Check${NC}"
    local failures=0
    
    # Test successful connection
    SSH_PORT="22"
    SSH_HOST="localhost"
    SSH_USER="test"
    check_ssh
    assert_success "SSH connection test" || ((failures++))
    
    # Test failed connection
    SSH_PORT="invalid"
    check_ssh
    assert_failure "Invalid port connection test" || ((failures++))
    
    return $failures
}

test_run_remote() {
    echo -e "\n${YELLOW}Testing Remote Command Execution${NC}"
    local failures=0
    
    # Setup valid SSH config
    SSH_PORT="22"
    SSH_HOST="localhost"
    SSH_USER="test"
    
    # Test valid command
    run_remote "echo test"
    assert_success "Valid remote command test" || ((failures++))
    
    # Test empty command
    run_remote ""
    assert_failure "Empty command test" || ((failures++))
    
    return $failures
}

test_system_info() {
    echo -e "\n${YELLOW}Testing System Info Collection${NC}"
    local failures=0
    
    # Setup valid SSH config
    SSH_PORT="22"
    SSH_HOST="localhost"
    SSH_USER="test"
    
    # Test memory info
    run_remote "free -h"
    assert_success "Memory info collection test" || ((failures++))
    
    # Test disk usage
    run_remote "df -h"
    assert_success "Disk usage collection test" || ((failures++))
    
    # Test load average
    run_remote "uptime"
    assert_success "Load average collection test" || ((failures++))
    
    return $failures
}

test_reboot_monitoring() {
    echo -e "\n${YELLOW}Testing Reboot Monitoring${NC}"
    local failures=0
    
    # Setup valid SSH config
    SSH_PORT="22"
    SSH_HOST="localhost"
    SSH_USER="test"
    
    # Test pre-reboot recording
    run_remote "./reboot_monitor.sh pre"
    assert_success "Pre-reboot recording test" || ((failures++))
    
    # Test post-reboot recording
    run_remote "./reboot_monitor.sh post"
    assert_success "Post-reboot recording test" || ((failures++))
    
    return $failures
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}=== Running Monitor Helper Tests ===${NC}"
    local total_failures=0
    
    test_validate_ssh_config
    total_failures=$((total_failures + $?))
    
    test_check_ssh
    total_failures=$((total_failures + $?))
    
    test_run_remote
    total_failures=$((total_failures + $?))
    
    test_system_info
    total_failures=$((total_failures + $?))
    
    test_reboot_monitoring
    total_failures=$((total_failures + $?))
    
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
