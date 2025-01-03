#!/bin/bash

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/assertions.sh"
source "${SCRIPT_DIR}/utils/test_helpers.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to clean test directories
clean_test_dirs() {
    echo -e "\n${YELLOW}Cleaning test directories...${NC}"
    
    # Clean test directories under var
    rm -rf "$TEST_BASE_DIR/var/data/cleanup"
    rm -rf "$TEST_BASE_DIR/var/tmp/cleanup"
    
    # Clean temporary files
    find "$TEST_BASE_DIR/var/tmp" -name "*.tmp" -type f -delete
    find "$TEST_BASE_DIR/var/tmp" -name "*.swp" -type f -delete
    find "$TEST_BASE_DIR/var/data" -name "ssh_details_*.tar.gz" -type f -delete
    
    echo -e "${GREEN}✓ Test directories cleaned${NC}"
}

# Test cleanup functionality
test_cleanup() {
    echo -e "\n${YELLOW}Testing Cleanup${NC}"
    
    # Setup test environment
    setup_test_env
    
    # Create test directories and files
    mkdir -p "$TEST_BASE_DIR/var/data/cleanup/test1"
    mkdir -p "$TEST_BASE_DIR/var/data/cleanup/test2"
    mkdir -p "$TEST_BASE_DIR/var/tmp/cleanup/temp1"
    mkdir -p "$TEST_BASE_DIR/var/tmp/cleanup/temp2"
    
    # Create test files
    touch "$TEST_BASE_DIR/var/data/cleanup/test1/file1.txt"
    touch "$TEST_BASE_DIR/var/data/cleanup/test2/file2.txt"
    touch "$TEST_BASE_DIR/var/tmp/cleanup/temp1/temp1.tmp"
    touch "$TEST_BASE_DIR/var/tmp/cleanup/temp2/temp2.swp"
    
    # Test directory existence before cleanup
    assert_path "$TEST_BASE_DIR/var/data/cleanup/test1" "dir" "Test directory 1 exists"
    assert_path "$TEST_BASE_DIR/var/data/cleanup/test2" "dir" "Test directory 2 exists"
    assert_path "$TEST_BASE_DIR/var/tmp/cleanup/temp1" "dir" "Temp directory 1 exists"
    assert_path "$TEST_BASE_DIR/var/tmp/cleanup/temp2" "dir" "Temp directory 2 exists"
    
    # Run cleanup
    clean_test_dirs
    
    # Test directory removal
    assert_path_not_exists "$TEST_BASE_DIR/var/data/cleanup/test1" "Test directory 1 removed"
    assert_path_not_exists "$TEST_BASE_DIR/var/data/cleanup/test2" "Test directory 2 removed"
    assert_path_not_exists "$TEST_BASE_DIR/var/tmp/cleanup/temp1" "Temp directory 1 removed"
    assert_path_not_exists "$TEST_BASE_DIR/var/tmp/cleanup/temp2" "Temp directory 2 removed"
    
    # Test file removal
    assert_path_not_exists "$TEST_BASE_DIR/var/data/cleanup/test1/file1.txt" "Test file 1 removed"
    assert_path_not_exists "$TEST_BASE_DIR/var/data/cleanup/test2/file2.txt" "Test file 2 removed"
    assert_path_not_exists "$TEST_BASE_DIR/var/tmp/cleanup/temp1/temp1.tmp" "Temp file 1 removed"
    assert_path_not_exists "$TEST_BASE_DIR/var/tmp/cleanup/temp2/temp2.swp" "Temp file 2 removed"
    
    # Cleanup test environment
    cleanup_test_env
}

# Run tests
echo -e "${YELLOW}=== Running Cleanup Tests ===${NC}"
test_cleanup

# Print test summary and exit
print_test_summary
