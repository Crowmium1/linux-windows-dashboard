#!/bin/bash

# Source environment variables and utilities
source "${BASE_DIR}/.envrc"
source "${LIB_DIR}/utils/error_handler.sh"
source "${LIB_DIR}/utils/logger.sh"
source "${LIB_DIR}/utils/path_manager.sh"

# Source test utilities
source "${TEST_BASE_DIR}/utils/assertions.sh"
source "${TEST_BASE_DIR}/utils/test_helpers.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Start time
START_TIME=$(date +%s)

# Print test header
print_header() {
    local title=$1
    echo -e "\n${YELLOW}=== Running ${title} ===${NC}\n"
}

# Print test result
print_result() {
    local test_name=$1
    local result=$2
    local message=${3:-}
    
    case ${result} in
        "PASS")
            echo -e "${GREEN}✓ ${test_name}${NC}"
            ;;
        "FAIL")
            echo -e "${RED}✗ ${test_name}${NC}"
            if [[ -n "${message}" ]]; then
                echo -e "${RED}  ${message}${NC}"
            fi
            ;;
        "SKIP")
            echo -e "${YELLOW}- ${test_name} (SKIPPED)${NC}"
            if [[ -n "${message}" ]]; then
                echo -e "${YELLOW}  ${message}${NC}"
            fi
            ;;
    esac
}

# Run a single test
run_test() {
    local test_file=$1
    local test_name=$(basename "${test_file}" .sh)
    
    # Create test environment
    setup_test_environment
    
    # Run test
    if source "${test_file}"; then
        ((TESTS_PASSED++))
        print_result "${test_name}" "PASS"
    else
        ((TESTS_FAILED++))
        print_result "${test_name}" "FAIL" "Test failed with exit code $?"
    fi
    
    # Clean up test environment
    cleanup_test_environment
    
    ((TESTS_RUN++))
}

# Run all tests in a directory
run_test_directory() {
    local dir=$1
    local pattern=${2:-"test_*.sh"}
    
    if [[ ! -d "${dir}" ]]; then
        echo -e "${RED}Test directory not found: ${dir}${NC}"
        return ${E_FILE_NOT_FOUND}
    fi
    
    print_header "Tests in $(basename "${dir}")"
    
    # Find and run all test files
    find "${dir}" -type f -name "${pattern}" | while read -r test_file; do
        run_test "${test_file}"
    done
}

# Print test summary
print_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo -e "Duration: ${duration}s"
    echo -e "Tests run: ${TESTS_RUN}"
    echo -e "${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Tests failed: ${TESTS_FAILED}${NC}"
    echo -e "${YELLOW}Tests skipped: ${TESTS_SKIPPED}${NC}"
    
    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Main function
main() {
    local test_dirs=()
    local pattern="test_*.sh"
    local specific_test=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                test_dirs+=("$2")
                shift 2
                ;;
            -p|--pattern)
                pattern="$2"
                shift 2
                ;;
            -t|--test)
                specific_test="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                exit ${E_INVALID_ARGS}
                ;;
        esac
    done
    
    # If no directories specified, run all tests
    if [[ ${#test_dirs[@]} -eq 0 ]]; then
        test_dirs=("${TEST_BASE_DIR}/complete")
    fi
    
    # Run specific test if specified
    if [[ -n "${specific_test}" ]]; then
        if [[ -f "${specific_test}" ]]; then
            run_test "${specific_test}"
        else
            echo -e "${RED}Test file not found: ${specific_test}${NC}"
            exit ${E_FILE_NOT_FOUND}
        fi
    else
        # Run all tests in specified directories
        for dir in "${test_dirs[@]}"; do
            run_test_directory "${dir}" "${pattern}"
        done
    fi
    
    print_summary
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
