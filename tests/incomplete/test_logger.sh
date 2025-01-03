#!/bin/bash

# Source test utilities
source "${TEST_BASE_DIR}/utils/assertions.sh"
source "${TEST_BASE_DIR}/utils/test_helpers.sh"

# Source component to test
source "${LIB_DIR}/utils/logger.sh"

# Test setup
setup() {
    TEST_LOG_FILE="${TEST_TEMP_DIR}/test.log"
    TEST_LOG_LEVEL="DEBUG"
    export LOG_FILE="${TEST_LOG_FILE}"
    export LOG_LEVEL="${TEST_LOG_LEVEL}"
}

# Test teardown
teardown() {
    rm -f "${TEST_LOG_FILE}"
    unset LOG_FILE LOG_LEVEL
}

# Test log initialization
test_init_logging() {
    init_logging
    assert_equals $? ${E_SUCCESS} "init_logging should succeed"
    assert_file_exists "${TEST_LOG_FILE}" "Log file should be created"
}

# Test log levels
test_log_levels() {
    local message="Test log message"
    local result
    
    # Test debug level
    result=$(log_debug "${message}")
    assert_contains "$(cat "${TEST_LOG_FILE}")" "[DEBUG] ${message}" "Debug message should be logged"
    
    # Test info level
    result=$(log_info "${message}")
    assert_contains "$(cat "${TEST_LOG_FILE}")" "[INFO] ${message}" "Info message should be logged"
    
    # Test warning level
    result=$(log_warning "${message}")
    assert_contains "$(cat "${TEST_LOG_FILE}")" "[WARNING] ${message}" "Warning message should be logged"
    
    # Test error level
    result=$(log_error "${message}")
    assert_contains "$(cat "${TEST_LOG_FILE}")" "[ERROR] ${message}" "Error message should be logged"
}

# Test log rotation
test_log_rotation() {
    # Fill log file
    local i
    for i in {1..1000}; do
        log_info "Test message ${i}"
    done
    
    # Check if rotation occurred
    assert_file_exists "${TEST_LOG_FILE}.1" "Rotated log file should exist"
}

# Test log format
test_log_format() {
    local message="Test log format"
    log_info "${message}"
    
    # Check log format
    local log_line
    log_line=$(tail -n 1 "${TEST_LOG_FILE}")
    
    # Format should be: [TIMESTAMP] [LEVEL] [SCRIPT] MESSAGE
    assert_matches "${log_line}" "\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]" "Log should have timestamp"
    assert_contains "${log_line}" "[INFO]" "Log should have level"
    assert_contains "${log_line}" "${message}" "Log should have message"
}

# Test log filtering
test_log_filtering() {
    # Set log level to INFO
    export LOG_LEVEL="INFO"
    
    # Log messages at different levels
    log_debug "Debug message"
    log_info "Info message"
    log_warning "Warning message"
    log_error "Error message"
    
    # Check filtering
    local log_content
    log_content=$(cat "${TEST_LOG_FILE}")
    assert_not_contains "${log_content}" "[DEBUG] Debug message" "Debug messages should be filtered"
    assert_contains "${log_content}" "[INFO] Info message" "Info messages should be logged"
    assert_contains "${log_content}" "[WARNING] Warning message" "Warning messages should be logged"
    assert_contains "${log_content}" "[ERROR] Error message" "Error messages should be logged"
}

# Test log cleanup
test_log_cleanup() {
    # Create some log files
    touch "${TEST_LOG_FILE}.1"
    touch "${TEST_LOG_FILE}.2"
    touch "${TEST_LOG_FILE}.3"
    
    # Clean old logs
    cleanup_old_logs
    
    # Check cleanup
    assert_file_not_exists "${TEST_LOG_FILE}.3" "Old log files should be removed"
}

# Run all tests
run_tests() {
    setup
    
    test_init_logging
    test_log_levels
    test_log_rotation
    test_log_format
    test_log_filtering
    test_log_cleanup
    
    teardown
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
