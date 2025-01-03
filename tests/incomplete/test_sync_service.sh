#!/bin/bash

# Source test utilities
. "$TEST_BASE_DIR/utils/test_helpers.sh"

# Source dependencies
source "$LIB_DIR/utils.sh"

# Initialize test environment
function setup_test_env() {
    set_test_group "Environment Setup"
    
    # Create test directories
    mkdir -p "$TEST_BASE_DIR/var/data/sync/source"
    mkdir -p "$TEST_BASE_DIR/var/data/sync/target"
    
    # Create mock config
    cat > "$TEST_CONFIG_DIR/sync_config.conf" << EOL
LOG_DIR=$TEST_BASE_DIR/var/log
DATA_DIR=$TEST_BASE_DIR/var/data/sync
TEMP_DIR=$TEST_BASE_DIR/var/tmp
SOURCE_DIR=$TEST_BASE_DIR/var/data/sync/source
TARGET_DIR=$TEST_BASE_DIR/var/data/sync/target
SYNC_INTERVAL=60
MAX_RETRIES=3
RETRY_DELAY=5
ALERT_THRESHOLD=90
EOL
    
    # Create source test files
    echo "test file 1" > "$TEST_BASE_DIR/var/data/sync/source/file1.txt"
    echo "test file 2" > "$TEST_BASE_DIR/var/data/sync/source/file2.txt"
    mkdir -p "$TEST_BASE_DIR/var/data/sync/source/subdir"
    echo "test file 3" > "$TEST_BASE_DIR/var/data/sync/source/subdir/file3.txt"
    
    # Verify setup
    assert_path "$TEST_CONFIG_DIR/sync_config.conf" "file" "Config file creation"
    assert_path "$TEST_BASE_DIR/var/data/sync/source/file1.txt" "file" "Source file 1 creation"
    assert_path "$TEST_BASE_DIR/var/data/sync/source/file2.txt" "file" "Source file 2 creation"
    assert_path "$TEST_BASE_DIR/var/data/sync/source/subdir/file3.txt" "file" "Source file 3 creation"
}

# Test sync functionality
function test_sync_functionality() {
    set_test_group "Sync Functionality"
    
    # Test basic sync
    assert_success "TEST_MODE=1 $CORE_DIR/sync_service.sh --config=$TEST_CONFIG_DIR/sync_config.conf" \
        "Basic sync operation"
    
    # Verify synced files
    assert_path "$TEST_BASE_DIR/var/data/sync/target/file1.txt" "file" "Target file 1 sync"
    assert_path "$TEST_BASE_DIR/var/data/sync/target/file2.txt" "file" "Target file 2 sync"
    assert_path "$TEST_BASE_DIR/var/data/sync/target/subdir/file3.txt" "file" "Target file 3 sync"
    
    # Verify file contents
    assert_file_equals "$TEST_BASE_DIR/var/data/sync/source/file1.txt" "$TEST_BASE_DIR/var/data/sync/target/file1.txt" "File 1 content match"
    assert_file_equals "$TEST_BASE_DIR/var/data/sync/source/file2.txt" "$TEST_BASE_DIR/var/data/sync/target/file2.txt" "File 2 content match"
    assert_file_equals "$TEST_BASE_DIR/var/data/sync/source/subdir/file3.txt" "$TEST_BASE_DIR/var/data/sync/target/subdir/file3.txt" "File 3 content match"
}

# Test incremental sync
function test_incremental_sync() {
    set_test_group "Incremental Sync"
    
    # Modify source files
    echo "modified content" > "$TEST_BASE_DIR/var/data/sync/source/file1.txt"
    echo "new file" > "$TEST_BASE_DIR/var/data/sync/source/file4.txt"
    rm "$TEST_BASE_DIR/var/data/sync/source/file2.txt"
    
    # Run incremental sync
    assert_success "TEST_MODE=1 $CORE_DIR/sync_service.sh --config=$TEST_CONFIG_DIR/sync_config.conf" \
        "Incremental sync operation"
    
    # Verify changes
    assert_file_contains "$TEST_BASE_DIR/var/data/sync/target/file1.txt" "modified content" "Modified file sync"
    assert_path "$TEST_BASE_DIR/var/data/sync/target/file4.txt" "file" "New file sync"
    assert_path_not_exists "$TEST_BASE_DIR/var/data/sync/target/file2.txt" "Deleted file sync"
}

# Test error handling
function test_error_handling() {
    set_test_group "Error Handling"
    
    # Test with invalid config
    assert_failure "TEST_MODE=1 $CORE_DIR/sync_service.sh --config=nonexistent.conf" \
        "Invalid config detection"
    
    # Test with read-only target directory
    chmod 444 "$TEST_BASE_DIR/var/data/sync/target"
    assert_failure "TEST_MODE=1 $CORE_DIR/sync_service.sh --config=$TEST_CONFIG_DIR/sync_config.conf" \
        "Read-only target directory handling"
    chmod 755 "$TEST_BASE_DIR/var/data/sync/target"
    
    # Test with missing source directory
    rm -rf "$TEST_BASE_DIR/var/data/sync/source"
    assert_failure "TEST_MODE=1 $CORE_DIR/sync_service.sh --config=$TEST_CONFIG_DIR/sync_config.conf" \
        "Missing source directory handling"
}

# Test sync logging
function test_sync_logging() {
    set_test_group "Sync Logging"
    
    # Run sync with logging
    assert_success "TEST_MODE=1 $CORE_DIR/sync_service.sh --config=$TEST_CONFIG_DIR/sync_config.conf --verbose" \
        "Sync with verbose logging"
    
    # Verify logs
    assert_path "$TEST_BASE_DIR/var/log/sync.log" "file" "Sync log creation"
    assert_file_contains "$TEST_BASE_DIR/var/log/sync.log" "Starting sync operation" "Sync start logged"
    assert_file_contains "$TEST_BASE_DIR/var/log/sync.log" "Sync completed" "Sync completion logged"
}

# Run all tests
echo -e "${YELLOW}=== Running Sync Service Tests ===${NC}"
setup_test_env
test_sync_functionality
test_incremental_sync
test_error_handling
test_sync_logging

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
