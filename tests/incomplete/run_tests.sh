#!/bin/bash

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source utility functions
source "${ROOT_DIR}/utils/utils.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test environment setup
TEST_BASE_DIR="$SCRIPT_DIR"
TEST_LOG_DIR="$TEST_BASE_DIR/var/log"
TEST_TMP_DIR="$TEST_BASE_DIR/var/tmp"
TEST_DATA_DIR="$TEST_BASE_DIR/var/data"
TEST_CONFIG_DIR="$TEST_BASE_DIR/config"

# Test suites (relative to SCRIPT_DIR)
TEST_SUITES=(
    "test_orchestrator.sh"
    "test_ssh_manager.sh"
    "test_system_monitor.sh"
    "test_reboot_monitor.sh"
    "test_monitor_helper.sh"
    "test_sync_service.sh"
    "test_logout.sh"
)

# Run all test suites
run_all_tests() {
    echo -e "${BLUE}Running all test suites...${NC}"
    
    # Create test directories if they don't exist
    mkdir -p "$TEST_LOG_DIR" "$TEST_TMP_DIR" "$TEST_DATA_DIR" "$TEST_CONFIG_DIR"
    
    local failed=0
    for suite in "${TEST_SUITES[@]}"; do
        local suite_path="${SCRIPT_DIR}/${suite}"
        if [ -f "$suite_path" ]; then
            echo -e "\n${BLUE}Running $suite...${NC}"
            if TEST_MODE=1 bash "$suite_path"; then
                echo -e "${GREEN}✓ $suite passed${NC}"
            else
                echo -e "${RED}✗ $suite failed${NC}"
                failed=$((failed + 1))
            fi
        else
            echo -e "${RED}✗ Test suite not found: $suite${NC}"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "\n${GREEN}All test suites passed!${NC}"
        return 0
    else
        echo -e "\n${RED}$failed test suite(s) failed${NC}"
        return 1
    fi
}

# Run specific test suite if provided, otherwise run all
if [ $# -eq 0 ]; then
    run_all_tests
else
    # Create test directories if they don't exist
    mkdir -p "$TEST_LOG_DIR" "$TEST_TMP_DIR" "$TEST_DATA_DIR" "$TEST_CONFIG_DIR"
    
    for suite in "$@"; do
        suite_path="${SCRIPT_DIR}/${suite}"
        if [ -f "$suite_path" ]; then
            echo -e "\n${BLUE}Running $suite...${NC}"
            if TEST_MODE=1 bash "$suite_path"; then
                echo -e "${GREEN}✓ $suite passed${NC}"
            else
                echo -e "${RED}✗ $suite failed${NC}"
                exit 1
            fi
        else
            echo -e "${RED}✗ Test suite not found: $suite${NC}"
            exit 1
        fi
    done
fi
