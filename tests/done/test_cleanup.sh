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
    
    # Clean test directories
    rm -rf data_collection_test
    rm -rf security_test_dir
    rm -rf sensitive_test_dir
    rm -rf injection_test_dir
    rm -rf cleanup_test_dir
    rm -rf timeout_test_dir
    rm -rf temp_test_dir
    
    # Clean temporary files
    find . -name "*.tmp" -type f -delete
    find . -name "*.swp" -type f -delete
    find . -name "ssh_details_*.tar.gz" -type f -delete
    
    echo -e "${GREEN}✓ Test directories cleaned${NC}"
}

# Test cleanup functionality
test_cleanup() {
    echo -e "\n${YELLOW}Testing Cleanup${NC}"
    
    # Setup test environment
    setup_test_env
    
    # Create test directories and files
    local test_dirs=(
        "data_collection_test"
        "security_test_dir"
        "sensitive_test_dir"
        "injection_test_dir"
        "cleanup_test_dir"
        "timeout_test_dir"
        "temp_test_dir"
    )
    
    # Create test directories
    for dir in "${test_dirs[@]}"; do
        assert_true "mkdir -p $dir" "Create test directory: $dir"
        assert_true "touch $dir/test_file.txt" "Create test file in $dir"
    done
    
    # Create temporary files
    assert_true "touch test1.tmp" "Create .tmp file"
    assert_true "touch test2.swp" "Create .swp file"
    assert_true "touch ssh_details_123.tar.gz" "Create archive file"
    
    # Run cleanup
    clean_test_dirs
    
    # Verify cleanup
    for dir in "${test_dirs[@]}"; do
        assert_false "[ -d '$dir' ]" "Directory should not exist: $dir"
    done
    
    assert_false "find . -name '*.tmp' -type f | grep -q ." "No .tmp files should exist"
    assert_false "find . -name '*.swp' -type f | grep -q ." "No .swp files should exist"
    assert_false "find . -name 'ssh_details_*.tar.gz' -type f | grep -q ." "No archive files should exist"
    
    # Cleanup test environment
    cleanup_test_env
}

# Run tests
echo -e "${YELLOW}=== Running Cleanup Tests ===${NC}"
test_cleanup

# Print test summary and exit
print_test_summary
