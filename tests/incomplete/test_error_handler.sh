#!/bin/bash

# Source test utilities
source "${TEST_BASE_DIR}/utils/assertions.sh"
source "${TEST_BASE_DIR}/utils/test_helpers.sh"

# Source component to test
source "${LIB_DIR}/utils/error_handler.sh"

# Test handle_error function
test_handle_error() {
    # Test with valid error code
    local result
    result=$(handle_error ${E_INVALID_ARGS} "Test error message" "test_file.sh" 123)
    assert_equals $? ${E_INVALID_ARGS} "handle_error should return the error code"
    assert_contains "${result}" "Test error message" "Error message should be in output"
    assert_contains "${result}" "test_file.sh:123" "Source location should be in output"
    
    # Test with invalid error code
    result=$(handle_error 999 "Invalid error code")
    assert_equals $? 999 "handle_error should return the provided error code even if invalid"
}

# Test check_required_commands function
test_check_required_commands() {
    # Test with existing command
    check_required_commands "ls"
    assert_equals $? ${E_SUCCESS} "check_required_commands should succeed for existing command"
    
    # Test with non-existing command
    check_required_commands "nonexistentcommand123"
    assert_equals $? ${E_GENERAL} "check_required_commands should fail for non-existing command"
    
    # Test with multiple commands
    check_required_commands "ls" "cd" "pwd"
    assert_equals $? ${E_SUCCESS} "check_required_commands should succeed for multiple existing commands"
}

# Test check_required_files function
test_check_required_files() {
    # Create test file
    local test_file="${TEST_TEMP_DIR}/test_file"
    touch "${test_file}"
    
    # Test with existing file
    check_required_files "${test_file}"
    assert_equals $? ${E_SUCCESS} "check_required_files should succeed for existing file"
    
    # Test with non-existing file
    check_required_files "${TEST_TEMP_DIR}/nonexistent_file"
    assert_equals $? ${E_FILE_NOT_FOUND} "check_required_files should fail for non-existing file"
    
    # Test with multiple files
    touch "${TEST_TEMP_DIR}/test_file2"
    check_required_files "${test_file}" "${TEST_TEMP_DIR}/test_file2"
    assert_equals $? ${E_SUCCESS} "check_required_files should succeed for multiple existing files"
    
    # Clean up
    rm -f "${test_file}" "${TEST_TEMP_DIR}/test_file2"
}

# Test check_required_dirs function
test_check_required_dirs() {
    # Create test directory
    local test_dir="${TEST_TEMP_DIR}/test_dir"
    mkdir -p "${test_dir}"
    
    # Test with existing directory
    check_required_dirs "${test_dir}"
    assert_equals $? ${E_SUCCESS} "check_required_dirs should succeed for existing directory"
    
    # Test with non-existing directory
    check_required_dirs "${TEST_TEMP_DIR}/nonexistent_dir"
    assert_equals $? ${E_FILE_NOT_FOUND} "check_required_dirs should fail for non-existing directory"
    
    # Test with multiple directories
    mkdir -p "${TEST_TEMP_DIR}/test_dir2"
    check_required_dirs "${test_dir}" "${TEST_TEMP_DIR}/test_dir2"
    assert_equals $? ${E_SUCCESS} "check_required_dirs should succeed for multiple existing directories"
    
    # Clean up
    rm -rf "${test_dir}" "${TEST_TEMP_DIR}/test_dir2"
}

# Test check_permissions function
test_check_permissions() {
    # Create test file with specific permissions
    local test_file="${TEST_TEMP_DIR}/test_perms"
    touch "${test_file}"
    chmod 600 "${test_file}"
    
    # Test read permission
    check_permissions "${test_file}" "r"
    assert_equals $? ${E_SUCCESS} "check_permissions should succeed for readable file"
    
    # Test write permission
    check_permissions "${test_file}" "w"
    assert_equals $? ${E_SUCCESS} "check_permissions should succeed for writable file"
    
    # Test execute permission
    check_permissions "${test_file}" "x"
    assert_equals $? ${E_PERMISSION_DENIED} "check_permissions should fail for non-executable file"
    
    # Test invalid permission type
    check_permissions "${test_file}" "z"
    assert_equals $? ${E_INVALID_ARGS} "check_permissions should fail for invalid permission type"
    
    # Clean up
    rm -f "${test_file}"
}

# Test cleanup_on_exit function
test_cleanup_on_exit() {
    # Create test cleanup function
    test_cleanup() {
        echo "Cleanup executed"
    }
    
    # Test cleanup execution
    local result
    result=$(cleanup_on_exit "test_cleanup")
    assert_contains "${result}" "Cleanup executed" "Cleanup function should be executed"
}

# Run all tests
run_tests() {
    test_handle_error
    test_check_required_commands
    test_check_required_files
    test_check_required_dirs
    test_check_permissions
    test_cleanup_on_exit
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
