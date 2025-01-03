#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CURRENT_GROUP=""

# Set the current test group for better organization
set_test_group() {
    CURRENT_GROUP="$1"
    echo -e "\n${YELLOW}=== Testing: $CURRENT_GROUP ===${NC}"
}

# Generic assertion function
assert() {
    local condition="$1"
    local message="$2"
    local expect_failure="${3:-false}"
    
    ((TOTAL_TESTS++))
    
    if eval "$condition"; then
        if [ "$expect_failure" = "true" ]; then
            echo -e "${RED}✗ $message (unexpected success)${NC}"
            ((FAILED_TESTS++))
            return 1
        else
            echo -e "${GREEN}✓ $message${NC}"
            ((PASSED_TESTS++))
            return 0
        fi
    else
        if [ "$expect_failure" = "true" ]; then
            echo -e "${GREEN}✓ $message (expected failure)${NC}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}✗ $message${NC}"
            ((FAILED_TESTS++))
            return 1
        fi
    fi
}

# Success/failure assertions
assert_success() {
    local command="$1"
    local message="$2"
    eval "$command"
    assert "[ \$? -eq 0 ]" "$message"
}

assert_failure() {
    local command="$1"
    local message="$2"
    eval "$command"
    assert "[ \$? -ne 0 ]" "$message"
}

# Path assertions
assert_path() {
    local path="$1"
    local type="$2"
    local message="$3"
    
    case "$type" in
        "file")
            assert "[ -f '$path' ]" "${message:-File exists: $path}"
            ;;
        "dir"|"directory")
            assert "[ -d '$path' ]" "${message:-Directory exists: $path}"
            ;;
        "readable")
            assert "[ -r '$path' ]" "${message:-Path is readable: $path}"
            ;;
        "writable")
            assert "[ -w '$path' ]" "${message:-Path is writable: $path}"
            ;;
        "executable")
            assert "[ -x '$path' ]" "${message:-Path is executable: $path}"
            ;;
        *)
            assert "[ -e '$path' ]" "${message:-Path exists: $path}"
            ;;
    esac
}

# File content assertions
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"
    assert "grep -q '$pattern' '$file'" "${message:-File contains pattern: $pattern}"
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local message="$3"
    assert "! grep -q '$pattern' '$file'" "${message:-File does not contain pattern: $pattern}"
}

assert_file_empty() {
    local file="$1"
    local message="$2"
    assert "[ ! -s '$file' ]" "${message:-File is empty: $file}"
}

assert_file_not_empty() {
    local file="$1"
    local message="$2"
    assert "[ -s '$file' ]" "${message:-File is not empty: $file}"
}

# Process assertions
assert_process_running() {
    local process="$1"
    local message="$2"
    assert "pgrep -f '$process' > /dev/null" "${message:-Process is running: $process}"
}

assert_process_not_running() {
    local process="$1"
    local message="$2"
    assert "! pgrep -f '$process' > /dev/null" "${message:-Process is not running: $process}"
}

# Network assertions
assert_port_open() {
    local host="$1"
    local port="$2"
    local message="$3"
    assert "nc -z '$host' '$port'" "${message:-Port $port is open on $host}"
}

assert_host_reachable() {
    local host="$1"
    local message="$2"
    assert "ping -c 1 '$host' > /dev/null 2>&1" "${message:-Host is reachable: $host}"
}

# String assertions
assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="$3"
    assert "[ '$actual' = '$expected' ]" "${message:-Expected '$expected', got '$actual'}"
}

assert_not_equals() {
    local actual="$1"
    local expected="$2"
    local message="$3"
    assert "[[ '$actual' != '$expected' ]]" "${message:-Expected different value than '$expected'}"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    assert "[[ '$haystack' == *'$needle'* ]]" "${message:-String contains substring}"
}

# Print test summary
print_test_summary() {
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "Total tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}