#!/bin/bash

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Initialize test environment
setup_test_env
TEST_ROOT="$TEST_DIR/sync_test"

# Test environment setup
setup() {
    set_test_group "Environment Setup"
    
    # Create test directories
    setup_test_dir "$TEST_ROOT"
    mkdir -p "$TEST_ROOT/source"
    mkdir -p "$TEST_ROOT/target"
    mkdir -p "$TEST_ROOT/config"
    mkdir -p "$TEST_ROOT/logs"
    
    # Create mock config
    cat > "$TEST_ROOT/config/sync_config.conf" << EOL
SOURCE_DIR=$TEST_ROOT/source
TARGET_DIR=$TEST_ROOT/target
SYNC_INTERVAL=60
RETRY_COUNT=3
RETRY_DELAY=5
LOG_DIR=$TEST_ROOT/logs
EXCLUDE_PATTERNS=".git,.svn,node_modules"
EOL
    
    # Create test files
    echo "test content 1" > "$TEST_ROOT/source/file1.txt"
    echo "test content 2" > "$TEST_ROOT/source/file2.txt"
    mkdir -p "$TEST_ROOT/source/subdir"
    echo "test content 3" > "$TEST_ROOT/source/subdir/file3.txt"
    
    # Create excluded directories
    mkdir -p "$TEST_ROOT/source/.git"
    mkdir -p "$TEST_ROOT/source/node_modules"
    
    # Verify setup
    assert_path "$TEST_ROOT/config/sync_config.conf" "file" "Config file creation"
    assert_path "$TEST_ROOT/source/file1.txt" "file" "Source file 1 creation"
    assert_path "$TEST_ROOT/source/file2.txt" "file" "Source file 2 creation"
    assert_path "$TEST_ROOT/source/subdir/file3.txt" "file" "Source file 3 creation"
}

# Test basic sync functionality
test_basic_sync() {
    set_test_group "Basic Sync"
    
    # Test initial sync
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf" \
        "Initial sync operation"
    
    # Verify synced files
    assert_path "$TEST_ROOT/target/file1.txt" "file" "Target file 1 exists"
    assert_path "$TEST_ROOT/target/file2.txt" "file" "Target file 2 exists"
    assert_path "$TEST_ROOT/target/subdir/file3.txt" "file" "Target file 3 exists"
    
    # Verify file contents
    assert_file_contains "$TEST_ROOT/target/file1.txt" "test content 1" "Target file 1 content"
    assert_file_contains "$TEST_ROOT/target/file2.txt" "test content 2" "Target file 2 content"
    assert_file_contains "$TEST_ROOT/target/subdir/file3.txt" "test content 3" "Target file 3 content"
}

# Test incremental sync
test_incremental_sync() {
    set_test_group "Incremental Sync"
    
    # Create new file
    echo "new content" > "$TEST_ROOT/source/new_file.txt"
    
    # Modify existing file
    echo "modified content" > "$TEST_ROOT/source/file1.txt"
    
    # Delete a file
    rm "$TEST_ROOT/source/file2.txt"
    
    # Run sync
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf" \
        "Incremental sync operation"
    
    # Verify changes
    assert_path "$TEST_ROOT/target/new_file.txt" "file" "New file synced"
    assert_file_contains "$TEST_ROOT/target/file1.txt" "modified content" "Modified file synced"
    assert_path "$TEST_ROOT/target/file2.txt" "file" "true" "Deleted file removed"
}

# Test exclusion patterns
test_exclusions() {
    set_test_group "Exclusion Patterns"
    
    # Create files in excluded directories
    echo "git file" > "$TEST_ROOT/source/.git/config"
    echo "node file" > "$TEST_ROOT/source/node_modules/package.json"
    
    # Run sync
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf" \
        "Sync with exclusions"
    
    # Verify exclusions
    assert_path "$TEST_ROOT/target/.git" "dir" "true" "Git directory excluded"
    assert_path "$TEST_ROOT/target/node_modules" "dir" "true" "Node modules excluded"
}

# Test error handling
test_error_handling() {
    set_test_group "Error Handling"
    
    # Test with invalid config
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=nonexistent.conf" \
        "Invalid config detection"
    
    # Test with read-only target directory
    chmod 444 "$TEST_ROOT/target"
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf" \
        "Read-only target handling"
    chmod 755 "$TEST_ROOT/target"
    
    # Test with missing source directory
    rm -rf "$TEST_ROOT/source"
    assert_failure "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf" \
        "Missing source handling"
}

# Test retry mechanism
test_retry_mechanism() {
    set_test_group "Retry Mechanism"
    
    # Setup mock rsync that fails initially
    local attempt=0
    mock_command "rsync" "if [ \$attempt -lt 2 ]; then attempt=\$((attempt + 1)); exit 1; else exit 0; fi" 0
    
    # Run sync with retries
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf" \
        "Sync with retries"
    
    # Verify retry count
    assert_file_contains "$TEST_ROOT/logs/sync.log" "Retry attempt" "Retry attempts logged"
}

# Test logging
test_logging() {
    set_test_group "Logging"
    
    # Run sync with logging
    local log_file="$TEST_ROOT/logs/sync.log"
    assert_success "TEST_MODE=1 ${ROOT_DIR}/core/sync_service.sh --config=$TEST_ROOT/config/sync_config.conf --log=$log_file" \
        "Sync with logging"
    
    # Verify log contents
    assert_file_not_empty "$log_file" "Log file has content"
    assert_file_contains "$log_file" "Starting sync" "Log contains start message"
    assert_file_contains "$log_file" "Sync completed" "Log contains completion message"
}

# Run all tests
setup
test_basic_sync
test_incremental_sync
test_exclusions
test_error_handling
test_retry_mechanism
test_logging

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
