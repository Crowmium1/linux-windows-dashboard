#!/bin/bash

# Source test utilities
source "${TEST_BASE_DIR}/utils/assertions.sh"
source "${TEST_BASE_DIR}/utils/test_helpers.sh"

# Source component to test
source "${LIB_DIR}/utils/path_manager.sh"

# Test setup
setup() {
    TEST_CONFIG_DIR="${TEST_TEMP_DIR}/config"
    TEST_DATA_DIR="${TEST_TEMP_DIR}/data"
    TEST_LOG_DIR="${TEST_TEMP_DIR}/logs"
    
    mkdir -p "${TEST_CONFIG_DIR}" "${TEST_DATA_DIR}" "${TEST_LOG_DIR}"
    
    export CONFIG_DIR="${TEST_CONFIG_DIR}"
    export DATA_DIR="${TEST_DATA_DIR}"
    export LOG_DIR="${TEST_LOG_DIR}"
}

# Test teardown
teardown() {
    rm -rf "${TEST_CONFIG_DIR}" "${TEST_DATA_DIR}" "${TEST_LOG_DIR}"
    unset CONFIG_DIR DATA_DIR LOG_DIR
}

# Test path initialization
test_init_paths() {
    init_paths
    assert_equals $? ${E_SUCCESS} "init_paths should succeed"
    
    assert_dir_exists "${TEST_CONFIG_DIR}" "Config directory should exist"
    assert_dir_exists "${TEST_DATA_DIR}" "Data directory should exist"
    assert_dir_exists "${TEST_LOG_DIR}" "Log directory should exist"
}

# Test config path resolution
test_get_config_path() {
    local config_file="test.yaml"
    touch "${TEST_CONFIG_DIR}/${config_file}"
    
    local result
    result=$(get_config_path "${config_file}")
    assert_equals "${result}" "${TEST_CONFIG_DIR}/${config_file}" "get_config_path should return correct path"
    
    # Test with subdirectory
    mkdir -p "${TEST_CONFIG_DIR}/subdir"
    touch "${TEST_CONFIG_DIR}/subdir/${config_file}"
    
    result=$(get_config_path "subdir/${config_file}")
    assert_equals "${result}" "${TEST_CONFIG_DIR}/subdir/${config_file}" "get_config_path should handle subdirectories"
}

# Test data path resolution
test_get_data_path() {
    local data_file="test.dat"
    touch "${TEST_DATA_DIR}/${data_file}"
    
    local result
    result=$(get_data_path "${data_file}")
    assert_equals "${result}" "${TEST_DATA_DIR}/${data_file}" "get_data_path should return correct path"
    
    # Test with subdirectory
    mkdir -p "${TEST_DATA_DIR}/subdir"
    touch "${TEST_DATA_DIR}/subdir/${data_file}"
    
    result=$(get_data_path "subdir/${data_file}")
    assert_equals "${result}" "${TEST_DATA_DIR}/subdir/${data_file}" "get_data_path should handle subdirectories"
}

# Test log path resolution
test_get_log_path() {
    local log_file="test.log"
    touch "${TEST_LOG_DIR}/${log_file}"
    
    local result
    result=$(get_log_path "${log_file}")
    assert_equals "${result}" "${TEST_LOG_DIR}/${log_file}" "get_log_path should return correct path"
    
    # Test with subdirectory
    mkdir -p "${TEST_LOG_DIR}/subdir"
    touch "${TEST_LOG_DIR}/subdir/${log_file}"
    
    result=$(get_log_path "subdir/${log_file}")
    assert_equals "${result}" "${TEST_LOG_DIR}/subdir/${log_file}" "get_log_path should handle subdirectories"
}

# Test path validation
test_validate_path() {
    local test_file="${TEST_TEMP_DIR}/test_file"
    touch "${test_file}"
    
    # Test existing file
    validate_path "${test_file}"
    assert_equals $? ${E_SUCCESS} "validate_path should succeed for existing file"
    
    # Test non-existing file
    validate_path "${TEST_TEMP_DIR}/nonexistent"
    assert_equals $? ${E_FILE_NOT_FOUND} "validate_path should fail for non-existing file"
    
    # Test directory
    validate_path "${TEST_TEMP_DIR}"
    assert_equals $? ${E_SUCCESS} "validate_path should succeed for directory"
    
    # Clean up
    rm -f "${test_file}"
}

# Test path normalization
test_normalize_path() {
    local result
    
    # Test absolute path
    result=$(normalize_path "/path/to/file")
    assert_equals "${result}" "/path/to/file" "normalize_path should not modify absolute paths"
    
    # Test relative path
    result=$(normalize_path "./path/to/file")
    assert_equals "${result}" "$(pwd)/path/to/file" "normalize_path should convert relative paths to absolute"
    
    # Test path with parent references
    result=$(normalize_path "/path/to/../file")
    assert_equals "${result}" "/path/file" "normalize_path should resolve parent references"
}

# Test YAML parsing
test_parse_yaml() {
    # Create test YAML file
    local yaml_file="${TEST_TEMP_DIR}/test.yaml"
    cat > "${yaml_file}" << EOF
key1: value1
key2:
  subkey1: value2
  subkey2: value3
EOF
    
    # Test YAML parsing
    local result
    result=$(parse_yaml "${yaml_file}" "config_")
    
    assert_contains "${result}" "config_key1=\"value1\"" "parse_yaml should parse top-level keys"
    assert_contains "${result}" "config_key2_subkey1=\"value2\"" "parse_yaml should parse nested keys"
    assert_contains "${result}" "config_key2_subkey2=\"value3\"" "parse_yaml should parse multiple nested keys"
    
    # Clean up
    rm -f "${yaml_file}"
}

# Run all tests
run_tests() {
    setup
    
    test_init_paths
    test_get_config_path
    test_get_data_path
    test_get_log_path
    test_validate_path
    test_normalize_path
    test_parse_yaml
    
    teardown
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
