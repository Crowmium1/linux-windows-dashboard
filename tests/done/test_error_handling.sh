#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test environment variables
TEST_MODE=1
TEST_DIR="${ROOT_DIR}/tmp/error_test_$(date +%s)"
TEST_CONFIG_DIR="${TEST_DIR}/config"
TEST_LOG_DIR="${TEST_DIR}/logs"
export LOG_FILE="${TEST_LOG_DIR}/error_test.log"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_status="$3"  # 0 for success, 1 for failure
    
    echo -n "Testing $test_name... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    eval "$test_command" > /dev/null 2>&1
    local status=$?
    
    if [ $status -eq $expected_status ]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "Expected status: $expected_status, got: $status"
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
}

# Cleanup test environment
teardown() {
    # Force remove write protection before cleanup
    if [ -d "$TEST_DIR" ]; then
        find "$TEST_DIR" -type d -exec chmod 755 {} \;
        find "$TEST_DIR" -type f -exec chmod 644 {} \;
        rm -rf "$TEST_DIR"
    fi
}

# Test permission denied
test_permission_denied() {
    echo -e "\n${YELLOW}Testing Permission Denied Scenarios${NC}"
    
    if is_wsl; then
        echo -e "${YELLOW}Note: Some permission tests may behave differently in WSL${NC}"
        
        # Test access to a non-existent system file
        run_test "access system file" "cat /etc/nonexistent" 1
        
        # Test write to system directory
        run_test "write to system directory" "touch /etc/test.txt" 1
    else
        # Create read-only directory
        local readonly_dir="$TEST_DIR/readonly"
        mkdir -p "$readonly_dir"
        chmod 500 "$readonly_dir"
        
        # Test write to read-only directory
        run_test "write to read-only directory" "touch $readonly_dir/test.txt" 1
        
        # Test execute without permission
        local test_script="$TEST_DIR/test.sh"
        echo "#!/bin/bash" > "$test_script"
        chmod 644 "$test_script"
        run_test "execute without permission" "$test_script" 1
        
        # Cleanup
        chmod 755 "$readonly_dir"
        rm -rf "$readonly_dir"
    fi
}

# Test disk space issues
test_disk_space() {
    echo -e "\n${YELLOW}Testing Disk Space Handling${NC}"
    
    # Test writing to full directory
    local test_file="$TEST_DIR/large_file.txt"
    
    # In WSL, we'll test disk space check instead of actual disk full
    run_test "check available space" "df -h $TEST_DIR >/dev/null" 0
    
    # Test writing a moderately sized file
    run_test "write test file" "dd if=/dev/zero of=$test_file bs=1M count=1" 0
    
    # Cleanup
    rm -f "$test_file"
}

# Test command timeouts
test_command_timeouts() {
    echo -e "\n${YELLOW}Testing Command Timeouts${NC}"
    
    # Test slow command timeout
    run_test "command timeout" "timeout 1 sleep 2" 124
    
    # Test command interrupt
    run_test "command interrupt" "sleep 1 & pid=\$!; kill \$pid" 0
}

# Test invalid input
test_invalid_input() {
    echo -e "\n${YELLOW}Testing Invalid Input Handling${NC}"
    
    # Test invalid file path
    run_test "invalid file path" "cat /nonexistent/file" 1
    
    # Test invalid command
    run_test "invalid command" "nonexistentcommand" 127
    
    # Test invalid arguments
    run_test "invalid arguments" "ls --invalidflag" 2
}

# Run all tests
run_tests() {
    echo -e "${YELLOW}=== Running Error Handling Tests ===${NC}"
    
    setup
    
    test_permission_denied
    test_disk_space
    test_command_timeouts
    test_invalid_input
    
    teardown
    
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    [ $TESTS_FAILED -eq 0 ]
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
