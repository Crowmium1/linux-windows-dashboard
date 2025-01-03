#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/utils/test_helpers.sh"

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

# Test data collection
test_data_collection() {
    echo -e "\n${YELLOW}Testing Data Collection${NC}"
    
    # Setup test environment
    setup_test_env
    
    # Create test directory
    local test_dir="data_collection_test"
    assert_true "mkdir -p $test_dir" "Create test directory"
    
    # Create test files
    assert_true "touch $test_dir/test_file.txt" "Create test file"
    
    # Run the collection script with test directory and capture output
    output=$(TEST_MODE=1 "${ROOT_DIR}/core/collect_system_info.sh" --test-mode --output-dir="$test_dir" --archive)
    echo "$output"
    
    # Debug: Check directory contents
    echo "Checking directory contents:"
    ls -la "$test_dir"
    
    # Look for the archive file
    local output_file
    if wait_for_file "$test_dir"/archive_*.tar.gz; then
        output_file=$(ls "$test_dir"/archive_*.tar.gz 2>/dev/null | head -n 1)
        echo "Found archive: $output_file"
    else
        echo "No archive file found after timeout"
        return 1
    fi
    
    # Test archive creation
    assert_file_exists "$output_file" "Archive file created"
    
    # Create temp directory for extraction
    local temp_dir="$test_dir/extract"
    assert_true "mkdir -p $temp_dir" "Create temp directory"
    
    # Extract files
    assert_true "tar -xzf $output_file -C $temp_dir" "Extract archive"
    
    # Test required files
    echo -e "\n${YELLOW}Testing Required Files${NC}"
    required_files=(
        "test_file.txt"
    )
    
    for file in "${required_files[@]}"; do
        assert_file_exists "$temp_dir/test_file.txt" "File exists: $file"
    done
    
    # Cleanup
    cleanup_test_env
}

# Run tests
echo -e "${YELLOW}=== Running Data Collection Tests ===${NC}"
test_data_collection

# Print test summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo "Tests Run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

exit $TESTS_FAILED
