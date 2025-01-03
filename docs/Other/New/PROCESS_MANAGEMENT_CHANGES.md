# Process Management Changes Required

## 1. Lock File System

### Current State
```bash
# No explicit lock file handling in monitor_helper.sh
# Could lead to multiple instances running simultaneously
```

### Required Changes
```bash
# Add to monitor_helper.sh
LOCK_FILE="/var/run/monitor_helper.lock"
PID_FILE="/var/run/monitor_helper.pid"

acquire_lock() {
    # Create lock directory if it doesn't exist
    mkdir -p "$(dirname "$LOCK_FILE")"
    
    # Try to create lock file
    if ( set -o noclobber; echo "$$" > "$LOCK_FILE") 2> /dev/null; then
        # Lock acquired; store PID
        echo $$ > "$PID_FILE"
        trap 'rm -f "$LOCK_FILE" "$PID_FILE"' EXIT
        return 0
    else
        return 1
    fi
}

release_lock() {
    rm -f "$LOCK_FILE" "$PID_FILE"
}

# Modify main() to use locks
main() {
    if ! acquire_lock; then
        handle_error "Another instance is running"
        exit 1
    fi
    # ... rest of main function
}
```

## 2. Process Monitoring

### Current State
```bash
# No process state monitoring
# No automatic recovery
# Manual intervention needed for failures
```

### Required Changes
```bash
# Add to monitor_helper.sh
MONITOR_INTERVAL=60
MAX_RETRIES=3

monitor_process() {
    local process_name="$1"
    local pid="$2"
    local retry_count=0

    while true; do
        if ! ps -p "$pid" > /dev/null; then
            log_message "WARNING" "$process_name (PID: $pid) died"
            
            if [ "$retry_count" -lt "$MAX_RETRIES" ]; then
                retry_count=$((retry_count + 1))
                restart_process "$process_name"
            else
                handle_error "$process_name failed after $MAX_RETRIES retries"
                return 1
            fi
        fi
        sleep "$MONITOR_INTERVAL"
    done
}

restart_process() {
    local process_name="$1"
    log_message "INFO" "Restarting $process_name"
    
    case "$process_name" in
        "system_monitor")
            ./system_monitor.sh &
            ;;
        "reboot_monitor")
            ./reboot_monitor.sh &
            ;;
        *)
            handle_error "Unknown process: $process_name"
            return 1
            ;;
    esac
}
```

## 3. Service Recovery

### Current State
```bash
# Basic error handling exists:
trap 'handle_error "An error occurred in monitor_helper.sh on line $LINENO" $?' ERR

# But no systematic recovery procedures
```

### Required Changes
```bash
# Add to monitor_helper.sh
declare -A PROCESS_STATES
RECOVERY_LOG="/var/log/monitor_recovery.log"

initialize_recovery() {
    mkdir -p "$(dirname "$RECOVERY_LOG")"
    PROCESS_STATES["system_monitor"]="stopped"
    PROCESS_STATES["reboot_monitor"]="stopped"
}

handle_recovery() {
    local process_name="$1"
    local error_type="$2"
    
    log_message "WARNING" "Initiating recovery for $process_name ($error_type)" >> "$RECOVERY_LOG"
    
    case "$error_type" in
        "crash")
            cleanup_crash "$process_name"
            restart_process "$process_name"
            ;;
        "hang")
            force_terminate "$process_name"
            cleanup_hang "$process_name"
            restart_process "$process_name"
            ;;
        "resource")
            cleanup_resources
            restart_process "$process_name"
            ;;
        *)
            handle_error "Unknown error type: $error_type"
            ;;
    esac
}

cleanup_crash() {
    local process_name="$1"
    rm -f "/tmp/${process_name}.tmp"
    # Add specific cleanup tasks
}

cleanup_hang() {
    local process_name="$1"
    pkill -f "$process_name"
    # Add specific cleanup tasks
}

cleanup_resources() {
    # Clean temporary files
    find /tmp -name "monitor_*.tmp" -mtime +1 -delete
    # Rotate logs if needed
    # Free up resources
}
```

## 4. State Persistence

### Current State
```bash
# No persistent state storage
# State lost between restarts
```

### Required Changes
```bash
# Add to monitor_helper.sh
STATE_DIR="/var/lib/monitor"
STATE_FILE="$STATE_DIR/monitor_state.json"

initialize_state() {
    mkdir -p "$STATE_DIR"
    if [ ! -f "$STATE_FILE" ]; then
        echo '{
            "last_run": null,
            "processes": {},
            "monitors": {},
            "errors": []
        }' > "$STATE_FILE"
    fi
}

save_state() {
    local state_type="$1"
    local state_data="$2"
    
    # Create temporary file for atomic write
    local temp_file="${STATE_FILE}.tmp"
    
    # Update specific state section
    jq --arg type "$state_type" --arg data "$state_data" \
       '.[$type] = $data' "$STATE_FILE" > "$temp_file"
    
    # Atomic move
    mv "$temp_file" "$STATE_FILE"
}

load_state() {
    local state_type="$1"
    if [ -f "$STATE_FILE" ]; then
        jq -r ".$state_type" "$STATE_FILE"
    else
        echo "{}"
    fi
}

# Usage in main functions
restore_state() {
    initialize_state
    local last_state=$(load_state "processes")
    
    # Restore process states
    while IFS= read -r line; do
        local process_name=$(echo "$line" | jq -r '.name')
        local process_state=$(echo "$line" | jq -r '.state')
        PROCESS_STATES["$process_name"]="$process_state"
    done < <(echo "$last_state" | jq -c '.[]')
}
```

## Implementation Strategy

1. Phase 1: Lock System
   - Implement basic lock file system
   - Add PID tracking
   - Test concurrent execution prevention

2. Phase 2: Process Monitoring
   - Add process state tracking
   - Implement monitoring loop
   - Add basic recovery

3. Phase 3: Recovery System
   - Implement full recovery procedures
   - Add error type detection
   - Create cleanup routines

4. Phase 4: State Management
   - Add state file handling
   - Implement state persistence
   - Add state recovery

## Testing Requirements

1. Lock System Tests
   - Concurrent execution attempts
   - Lock file cleanup
   - Process termination handling

2. Process Monitor Tests
   - Process death detection
   - Restart functionality
   - Retry limits

3. Recovery Tests
   - Various error scenarios
   - Cleanup procedures
   - Resource management

4. State Tests
   - State persistence
   - State recovery
   - Data integrity

## Security Considerations

1. File Permissions
   - Lock files: 600
   - PID files: 644
   - State files: 600

2. Directory Permissions
   - Run directory: 755
   - State directory: 700
   - Log directory: 755

3. User Permissions
   - Service user creation
   - Minimal required permissions
   - Resource limits
