#!/bin/bash

# Import assertions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assertions.sh"

# Ensure TEST_MODE is set
if [ -z "${TEST_MODE}" ]; then
    echo "Error: TEST_MODE must be set before running tests"
    exit 1
fi

# Environment variables
TEST_DIR="${TEST_DIR:-/tmp/test_env}"
LOG_FILE="${LOG_FILE:-$TEST_DIR/test.log}"
TIMEOUT="${TIMEOUT:-30}"

# Environment detection
is_wsl() {
    grep -qi microsoft /proc/version
}

is_root() {
    [ "$(id -u)" = "0" ]
}

# Path conversion for WSL
wsl_path() {
    local win_path="$1"
    if is_wsl; then
        echo "$win_path" | sed 's|\\|/|g' | sed 's|^C:|/mnt/c|'
    else
        echo "$win_path"
    fi
}

windows_path() {
    local unix_path="$1"
    if is_wsl; then
        echo "$unix_path" | sed 's|^/mnt/c|C:|' | sed 's|/|\\|g'
    else
        echo "$unix_path"
    fi
}

# Generic wait function
wait_for() {
    local check_command="$1"
    local timeout="${2:-$TIMEOUT}"
    local message="${3:-Waiting for condition}"
    local interval="${4:-1}"
    
    local end_time=$(($(date +%s) + timeout))
    
    while [ $(date +%s) -lt $end_time ]; do
        if eval "$check_command"; then
            return 0
        fi
        echo -n "."
        sleep "$interval"
    done
    
    echo "Timeout waiting for: $message"
    return 1
}

# Specialized wait functions
wait_for_file() {
    local file="$1"
    local timeout="${2:-$TIMEOUT}"
    wait_for "[ -f '$file' ]" "$timeout" "file to exist: $file"
}

wait_for_dir() {
    local dir="$1"
    local timeout="${2:-$TIMEOUT}"
    wait_for "[ -d '$dir' ]" "$timeout" "directory to exist: $dir"
}

wait_for_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-$TIMEOUT}"
    wait_for "nc -z '$host' '$port'" "$timeout" "port $port to be open on $host"
}

wait_for_process() {
    local process="$1"
    local timeout="${2:-$TIMEOUT}"
    wait_for "pgrep -f '$process' > /dev/null" "$timeout" "process to start: $process"
}

wait_for_command() {
    local command="$1"
    local timeout="${2:-$TIMEOUT}"
    local message="${3:-command to succeed}"
    wait_for "$command" "$timeout" "$message"
}

# Process management
start_process() {
    local command="$1"
    local pidfile="${2:-}"
    local logfile="${3:-}"
    local background="${4:-true}"
    
    if [ -n "$logfile" ]; then
        if [ "$background" = "true" ]; then
            eval "$command > '$logfile' 2>&1 &"
        else
            eval "$command > '$logfile' 2>&1"
        fi
    else
        if [ "$background" = "true" ]; then
            eval "$command &"
        else
            eval "$command"
        fi
    fi
    
    local pid=$!
    if [ -n "$pidfile" ]; then
        echo $pid > "$pidfile"
    fi
    return 0
}

stop_process() {
    local identifier="$1"  # Can be PID, pidfile, or process name
    local force="${2:-false}"
    local signal="${3:-TERM}"
    
    if [ -f "$identifier" ]; then
        # It's a pidfile
        local pid=$(cat "$identifier")
        kill -$signal $pid 2>/dev/null
        rm -f "$identifier"
    elif [[ "$identifier" =~ ^[0-9]+$ ]]; then
        # It's a PID
        kill -$signal $identifier 2>/dev/null
    else
        # It's a process name
        pkill -$signal -f "$identifier" 2>/dev/null
    fi
    
    if [ "$force" = "true" ] && ps -p $pid >/dev/null 2>&1; then
        sleep 1
        kill -9 $pid 2>/dev/null
    fi
}

# Test environment management
setup_test_env() {
    mkdir -p "$TEST_DIR"
    chmod 755 "$TEST_DIR"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

setup_test_dir() {
    local dir="${1:-$TEST_DIR}"
    rm -rf "$dir"
    mkdir -p "$dir"
    chmod 755 "$dir"
}

cleanup_test_env() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

cleanup_test_dir() {
    local dir="${1:-$TEST_DIR}"
    if [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
}

# Command mocking
mock_command() {
    local command="$1"
    local output="$2"
    local exit_code="${3:-0}"
    
    cat > "$TEST_DIR/$command" << EOF
#!/bin/bash
echo "$output"
exit $exit_code
EOF
    
    chmod +x "$TEST_DIR/$command"
    export PATH="$TEST_DIR:$PATH"
}

# Logging
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

log_debug() { log_message "DEBUG" "$1"; }
log_info() { log_message "INFO" "$1"; }
log_warn() { log_message "WARN" "$1"; }
log_error() { log_message "ERROR" "$1"; }

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CURRENT_GROUP=""

# Test environment variables
TEST_DIR="/tmp/ssh_dashboard_test"
export TEST_MODE=1

# Print status with color
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        return 1
    fi
}

# Set current test group
set_test_group() {
    CURRENT_GROUP="$1"
    echo -e "\n${YELLOW}=== Testing: $CURRENT_GROUP ===${NC}"
}

# Assert path exists and is of correct type
assert_path() {
    local path="$1"
    local type="$2"
    local message="$3"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    case "$type" in
        "file")
            if [ -f "$path" ]; then
                print_status "$message" 0
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                print_status "$message" 1
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
            ;;
        "dir")
            if [ -d "$path" ]; then
                print_status "$message" 0
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                print_status "$message" 1
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
            ;;
    esac
}

# Assert command succeeds
assert_success() {
    local command="$1"
    local message="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$command" > /dev/null 2>&1; then
        print_status "$message" 0
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_status "$message" 1
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Assert command output contains string
assert_output() {
    local command="$1"
    local expected="$2"
    local message="$3"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local output
    output=$(eval "$command" 2>&1)
    
    if [[ "$output" == *"$expected"* ]]; then
        print_status "$message" 0
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_status "$message" 1
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Assert file contains string
assert_file_contains() {
    local file="$1"
    local expected="$2"
    local message="$3"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if grep -q "$expected" "$file" 2>/dev/null; then
        print_status "$message" 0
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_status "$message" 1
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Print test summary
print_test_summary() {
    echo -e "\n${YELLOW}=== Test Summary ===${NC}"
    echo "Total tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}