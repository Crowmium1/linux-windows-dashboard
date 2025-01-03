#!/bin/bash

# Test suite for core/reboot_monitor.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils/test_helpers.sh"

# Initialize test environment
setup_test_env

# Test environment validation
set_test_group "Environment Validation"

# Test with valid environment
assert_success "validate_environment" "Environment validation with valid setup"
assert_file_exists "$LOG_FILE" "Log file creation"

# Test with invalid directory
MONITOR_DIR="/nonexistent/dir" assert_failure "validate_environment" "Environment validation with invalid directory"

# Test with read-only directory
setup_test_dir "$TEST_DIR/readonly"
chmod 444 "$TEST_DIR/readonly"
MONITOR_DIR="$TEST_DIR/readonly" assert_failure "validate_environment" "Environment validation with read-only directory"
chmod 755 "$TEST_DIR/readonly"

# Test state collection
set_test_group "State Collection"

# Test basic state collection
test_state="$TEST_DIR/test_state.txt"
assert_success "collect_state '$test_state'" "Basic state collection"
assert_file_exists "$test_state" "State file creation"
assert_file_not_empty "$test_state" "State file should have content"

# Verify required sections
required_sections=(
    "System State at"
    "Memory Usage"
    "Disk Usage"
    "System Load"
    "Process Count"
    "Network Connections"
    "Recent Kernel Messages"
)

for section in "${required_sections[@]}"; do
    assert_file_contains "$test_state" "$section" "Contains section: $section"
done

# Test error cases
assert_failure "collect_state ''" "Empty filename handling"
assert_failure "collect_state '/nonexistent/dir/state.txt'" "Invalid directory handling"

# Test state comparison
set_test_group "State Comparison"

# Test without state files
assert_failure "compare_states" "Comparison without state files"

# Create test states
assert_success "collect_state '$MONITOR_DIR/pre_reboot_state.txt'" "Pre-reboot state collection"
sleep 1  # Ensure some time difference
assert_success "collect_state '$MONITOR_DIR/post_reboot_state.txt'" "Post-reboot state collection"

# Test comparison
assert_success "compare_states" "State comparison"
assert_file_exists "$MONITOR_DIR/state_comparison.txt" "Comparison file creation"
assert_file_contains "$MONITOR_DIR/state_comparison.txt" "State Comparison at" "Contains comparison header"

# Test script argument handling
set_test_group "Command Line Arguments"

# Test invalid action
assert_failure "$ROOT_DIR/core/reboot_monitor.sh invalid_action" "Invalid action handling"

# Test missing arguments
assert_failure "$ROOT_DIR/core/reboot_monitor.sh" "Missing arguments handling"

# Test pre-reboot collection
assert_success "$ROOT_DIR/core/reboot_monitor.sh pre" "Pre-reboot collection"
assert_file_exists "$MONITOR_DIR/pre_reboot_state.txt" "Pre-reboot state file creation"

# Test post-reboot collection and comparison
assert_success "$ROOT_DIR/core/reboot_monitor.sh post" "Post-reboot collection and comparison"
assert_file_exists "$MONITOR_DIR/post_reboot_state.txt" "Post-reboot state file creation"
assert_file_exists "$MONITOR_DIR/state_comparison.txt" "Post-reboot comparison file creation"

# Test error logging
set_test_group "Error Handling"

error_msg="Test error message"
assert_success "handle_error '$error_msg'" "Error handler execution"
assert_file_contains "$LOG_FILE" "$error_msg" "Error message logging"

# Cleanup
cleanup_test_env

# Print test summary
print_test_summary
