#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"

# Test mode setup
export TEST_MODE=1
TEST_BASE_DIR="${SCRIPT_DIR}/../var"
TEST_CONFIG_DIR="${TEST_BASE_DIR}/config"
TEST_LOG_DIR="${TEST_BASE_DIR}/log"

# Source required files
source "$ROOT_DIR/utils/utils.sh"
source "$ROOT_DIR/core/system_monitor.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing $test_name... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
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

# Test required commands
test_commands() {
    echo -e "\n${YELLOW}Testing Required Commands${NC}"
    
    # Basic commands (should always be available)
    local commands=()
    
    if ! is_wsl; then
        commands+=("sensors" "lspci" "systemctl")
    fi
    
    commands+=("free" "df" "vmstat" "ps" "hostname")
    
    for cmd in "${commands[@]}"; do
        if is_wsl && [[ " sensors lspci systemctl " =~ " $cmd " ]]; then
            echo -e "${YELLOW}Skipping $cmd test in WSL${NC}"
            continue
        fi
        run_test "command $cmd exists" "command -v $cmd"
    done
}

# Test output directory creation
test_output_dir() {
    echo -e "\n${YELLOW}Testing Output Directory Creation${NC}"
    
    # Test log directory creation
    local output_dir="$TEST_BASE_DIR/var/data/collect_info/output"
    run_test "create output directory" "mkdir -p \"$output_dir\""
    run_test "output directory is writable" "touch \"$output_dir/test.log\""
    
    # Clean up test files
    rm -f "$output_dir/test.log"
}

# Test data collection functions
test_data_collection() {
    echo -e "\n${YELLOW}Testing Data Collection Functions${NC}"
    
    # Setup test data directory
    local data_dir="$TEST_BASE_DIR/var/data/collect_info/data"
    mkdir -p "$data_dir"
    
    # Create test config
    cat > "$TEST_CONFIG_DIR/collect_info.conf" << EOL
LOG_DIR=$TEST_LOG_DIR
DATA_DIR=$data_dir
TEMP_DIR=$TEST_BASE_DIR/var/tmp
COLLECT_INTERVAL=60
MAX_RETRIES=3
RETRY_DELAY=5
EOL
    
    # Memory info
    run_test "collect memory info" "free -h > \"$data_dir/memory.log\""
    
    # Disk usage
    run_test "collect disk usage" "df -h > \"$data_dir/disk.log\""
    
    # System load
    run_test "collect system load" "vmstat 1 1 > \"$data_dir/load.log\""
    
    # Process list
    run_test "collect process list" "ps aux > \"$data_dir/processes.log\""
}

# Test error handling
test_error_handling() {
    echo -e "\n${YELLOW}Testing Error Handling${NC}"
    
    # Test invalid command
    run_test "handle invalid command" "! nonexistent_command"
    
    # Test invalid directory
    run_test "handle invalid directory" "! touch \"/nonexistent/file\""
}

# Run all tests
echo -e "${YELLOW}=== Running System Info Collection Tests ===${NC}"

test_commands
test_output_dir
test_data_collection
test_error_handling

# Print test summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

# Cleanup
rm -rf "$TEST_BASE_DIR/var/data/collect_info"

# Exit with failure if any tests failed
[ $TESTS_FAILED -eq 0 ]
