#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source configurations
source "${ROOT_DIR}/config/main_config.conf"
source "${ROOT_DIR}/config/monitor_config.conf"

# Set test environment
export TEST_MODE=1
export TEST_BASE_DIR="/mnt/c/temp/monitor_test_$(date +%s)"
export TEST_DATA_DIR="$TEST_BASE_DIR/var/data/monitoring"
export TEST_ARCHIVE_DIR="$TEST_BASE_DIR/var/archives"
export TEST_CONFIG_DIR="$TEST_BASE_DIR/var/config"

# Source test utilities
source "${PARENT_DIR}/utils/utils.sh"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Assert functions
assert_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        exit 1
    fi
}

assert_failure() {
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        exit 1
    fi
}

# Setup test environment
setup() {
    echo "Setting up test environment..."
    
    # Create test directories
    mkdir -p "$TEST_DATA_DIR"
    mkdir -p "$TEST_ARCHIVE_DIR"
    mkdir -p "$TEST_CONFIG_DIR"
    
    # Create test configuration
    cat > "$TEST_CONFIG_DIR/monitor_config.conf" << EOL
TEST_MODE=1
COLLECT_CPU=1
COLLECT_MEMORY=1
COLLECT_DISK=1
COLLECT_NETWORK=1
DATA_DIR="$TEST_DATA_DIR"
ARCHIVE_DIR="$TEST_ARCHIVE_DIR"
RETENTION_DAYS=7
EOL
    
    # Export test environment variables
    export TEST_MODE=1
    export TEST_BASE_DIR
    export TEST_DATA_DIR
    export TEST_ARCHIVE_DIR
    export TEST_CONFIG_DIR
}

# Cleanup test environment
teardown() {
    echo "Cleaning up test environment..."
    rm -rf "$TEST_BASE_DIR"
}

# Test data collection
test_data_collection() {
    echo "Testing system data collection..."
    
    # 1. Create test output directory
    local test_output="$TEST_DATA_DIR/test_output"
    mkdir -p "$test_output"
    
    # 2. Run data collection and create archive
    "${PARENT_DIR}/collect_system_info.sh" --test-mode \
        --config="$TEST_CONFIG_DIR/monitor_config.conf" \
        --output-dir="$test_output" \
        --archive
    assert_success "System info collection"
    
    # 3. Verify output files
    [ -f "$test_output/00_summary.txt" ]
    assert_success "Summary file creation"
    
    [ -f "$test_output/01_network_config.txt" ]
    assert_success "Network config file creation"
    
    [ -f "$test_output/02_open_ports.txt" ]
    assert_success "Open ports file creation"
    
    [ -f "$test_output/08_memory_status.txt" ]
    assert_success "Memory status file creation"
    
    [ -f "$test_output/09_disk_usage.txt" ]
    assert_success "Disk usage file creation"
    
    # 4. Verify archive creation
    local archive_name="test_archive.tar.gz"
    [ -f "$test_output/$archive_name" ]
    assert_success "Archive file creation"
    
    # 5. Verify archive integrity
    tar -tzf "$test_output/$archive_name" >/dev/null 2>&1
    assert_success "Archive integrity"
}

# Test data archiving
test_data_archiving() {
    echo "Testing data archiving..."
    
    # 1. Create test output directories with timestamps
    for i in {1..5}; do
        date_str=$(date -d "$i days ago" +%Y%m%d)
        test_dir="$TEST_DATA_DIR/test_output_$date_str"
        mkdir -p "$test_dir"
        echo "Test data $i" > "$test_dir/00_summary.txt"
        echo "Test data $i" > "$test_dir/08_memory_status.txt"
    done
    
    # 2. Test archive creation
    "${PARENT_DIR}/collect_system_info.sh" --test-mode \
        --config="$TEST_CONFIG_DIR/monitor_config.conf" \
        --archive
    assert_success "Archive creation"
    
    # 3. Verify archive exists
    latest_archive=$(ls -t "$TEST_DATA_DIR"/test_output/archive_*.tar.gz 2>/dev/null | head -n1)
    [ -n "$latest_archive" ]
    assert_success "Archive file exists"
    
    # 4. Test archive contents
    tar -tzf "$latest_archive" >/dev/null
    assert_success "Archive integrity"
}

# Test data retention
test_data_retention() {
    echo "Testing data retention..."
    
    # 1. Create old test directories (beyond retention period)
    old_dir="$TEST_DATA_DIR/old_test_output"
    mkdir -p "$old_dir"
    echo "Old test data" > "$old_dir/00_summary.txt"
    
    # 2. Create recent test directories
    recent_dir="$TEST_DATA_DIR/recent_test_output"
    mkdir -p "$recent_dir"
    echo "Recent test data" > "$recent_dir/00_summary.txt"
    
    # Sleep briefly to ensure file timestamps are different
    sleep 1
    
    # 3. Run retention cleanup with retention days = 0 to force immediate cleanup
    "${PARENT_DIR}/collect_system_info.sh" --test-mode \
        --config="$TEST_CONFIG_DIR/monitor_config.conf" \
        --cleanup \
        --retention-days=0
    assert_success "Retention cleanup"
    
    # 4. Verify old directory is removed
    if [ -d "$old_dir" ]; then
        echo "Error: Old directory still exists: $old_dir"
        ls -la "$old_dir"
        return 1
    fi
    assert_success "Old directory removal"
    
    # 5. Verify recent directory is kept
    [ -d "$recent_dir" ]
    assert_success "Recent directory retention"
}

# Test error handling
test_error_handling() {
    echo "Testing error handling..."
    
    # 1. Test invalid config
    "${PARENT_DIR}/collect_system_info.sh" --test-mode \
        --config="/nonexistent/config.conf" \
        --type=cpu
    assert_failure "Invalid config detection"
    
    # 2. Test invalid type
    "${PARENT_DIR}/collect_system_info.sh" --test-mode \
        --config="$TEST_CONFIG_DIR/monitor_config.conf" \
        --type=invalid
    assert_failure "Invalid type detection"
    
    # 3. Test missing arguments
    "${PARENT_DIR}/collect_system_info.sh" --test-mode
    assert_failure "Missing arguments detection"
    
    # 4. Test invalid directory permissions
    chmod 000 "$TEST_DATA_DIR"
    "${PARENT_DIR}/collect_system_info.sh" --test-mode \
        --config="$TEST_CONFIG_DIR/monitor_config.conf" \
        --type=cpu
    assert_failure "Permission error detection"
    chmod 755 "$TEST_DATA_DIR"
}

# Run all tests
run_tests() {
    setup
    
    echo "Running Monitoring tests..."
    test_data_collection
    test_data_archiving
    test_data_retention
    test_error_handling
    
    teardown
    echo -e "${GREEN}All monitoring tests completed successfully${NC}"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
