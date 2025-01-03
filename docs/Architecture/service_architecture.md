# Service Architecture

## Overview
The system is split into two main components:
1. Interactive SSH Manager (`ssh_manager.sh`)
2. Background Sync Service (`sync_service.sh`)

## SSH Manager Service

### Command Structure
```bash
./ssh_manager.sh <command> [options]

Commands:
  setup     - Initial SSH setup and configuration
  forward   - Manage port forwarding
  sync      - One-time manual sync
  status    - Check SSH connections
  help      - Show this help
```

### Implementation Details
```bash
#!/bin/bash
# ssh_manager.sh

COMMAND=$1
shift # Remove command from args

case "$COMMAND" in
    setup)
        # Setup SSH keys and config
        setup_ssh_keys
        configure_ssh
        ;;
    forward)
        # Setup port forwarding
        setup_port_forwarding "$@"
        ;;
    sync)
        # One-time sync
        perform_manual_sync
        ;;
    status)
        # Check SSH status
        check_ssh_status
        ;;
    *)
        show_help
        ;;
esac
```

## Sync Service

### Service Commands
```bash
./sync_service.sh <command> [options]

Commands:
  start    - Start the sync daemon
  stop     - Stop the sync daemon
  status   - Check sync status
  restart  - Restart the service
```

### Process Management
```bash
#!/bin/bash
# sync_service.sh

PID_FILE="/var/run/sync_service.pid"
LOCK_FILE="/var/lock/sync_service.lock"

start_service() {
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Service already running"
            return 1
        fi
    fi

    # Start the sync process in background
    (
        # Create lock file
        exec {lock_fd}>"$LOCK_FILE"
        flock -n "$lock_fd" || exit 1

        # Start the watcher
        inotifywait -m -r -e modify,create,delete,move "${WATCH_DIR}" |
        while read -r directory events filename; do
            # Process events
            process_changes "$directory" "$events" "$filename"
        done
    ) &

    # Store PID
    echo $! > "$PID_FILE"
}

stop_service() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null
        rm -f "$PID_FILE"
        rm -f "$LOCK_FILE"
    fi
}

check_status() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Service is running (PID: $pid)"
            return 0
        fi
    fi
    echo "Service is not running"
    return 1
}
```

### Integration with Existing Watcher
```bash
process_changes() {
    local directory="$1"
    local events="$2"
    local filename="$3"

    # Acquire lock for sync
    exec {sync_lock_fd}>"$LOCK_FILE.sync"
    if ! flock -n "$sync_lock_fd"; then
        logger "Sync already in progress, queuing changes"
        return
    fi

    # Verify changes
    if verify_changes "$directory/$filename"; then
        # Perform rsync with existing configuration
        rsync -avz --delete \
            --exclude-from="$EXCLUDE_FILE" \
            "$LOCAL_DIR/" "$REMOTE_HOST:$REMOTE_DIR/"
    fi

    # Release lock
    flock -u "$sync_lock_fd"
}

verify_changes() {
    local file="$1"
    
    # Wait for file operations to complete
    sleep 1
    
    # Verify file still exists (for create events)
    # or doesn't exist (for delete events)
    if [[ -e "$file" ]] || [[ "$events" == *"DELETE"* ]]; then
        return 0
    fi
    return 1
}
```

## Detailed Process Management

### 1. Process Hierarchy
```
systemd
└── sync_service.sh (parent)
    └── inotifywait (child)
        └── rsync processes (grandchildren)
```

### 2. Process States
```bash
# Process lifecycle
START → RUNNING → PAUSED/STOPPED → CLEANUP → EXIT

# State management
check_process_state() {
    local pid=$1
    if [ -d "/proc/$pid" ]; then
        state=$(ps -o state= -p "$pid")
        case $state in
            R) echo "Running";;
            S) echo "Sleeping (idle)";;
            D) echo "Disk sleep";;
            Z) echo "Zombie";;
            T) echo "Stopped";;
        esac
    else
        echo "Not running"
    fi
}
```

### 3. Process Control
```bash
# Graceful shutdown
stop_process() {
    local pid=$1
    # Send SIGTERM first
    kill -TERM "$pid" 2>/dev/null
    
    # Wait for graceful shutdown
    for i in {1..30}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    
    # Force kill if still running
    kill -KILL "$pid" 2>/dev/null
}

# Process resurrection
monitor_process() {
    while true; do
        if ! kill -0 "$PID" 2>/dev/null; then
            logger "Process died, restarting..."
            start_service
        fi
        sleep 60
    done
}
```

## Lock System Explained

### 1. Types of Locks

#### Process Lock
```bash
# Main service lock
PID_FILE="/var/run/sync_service.pid"
LOCK_FILE="/var/lock/sync_service.lock"

# Prevents multiple service instances
acquire_process_lock() {
    exec {lock_fd}>"$LOCK_FILE"
    if ! flock -n "$lock_fd"; then
        echo "Another instance is running"
        return 1
    fi
    # Store file descriptor for later use
    echo "$lock_fd" > "$LOCK_FILE.fd"
    return 0
}
```

#### Operation Locks
```bash
# Sync operation lock
SYNC_LOCK="/var/lock/sync_operation.lock"

# Prevents concurrent syncs
acquire_sync_lock() {
    exec {sync_lock_fd}>"$SYNC_LOCK"
    if ! flock -w 10 "$sync_lock_fd"; then
        logger "Failed to acquire sync lock after 10s"
        return 1
    fi
    return 0
}
```

#### Resource Locks
```bash
# File-specific locks
FILE_LOCK_DIR="/var/lock/sync_files"

# Lock specific files during sync
lock_file() {
    local file="$1"
    local lock_file="$FILE_LOCK_DIR/${file//\//_}.lock"
    
    mkdir -p "$FILE_LOCK_DIR"
    exec {file_lock_fd}>"$lock_file"
    
    if ! flock -w 5 "$file_lock_fd"; then
        logger "File $file is locked"
        return 1
    fi
    return 0
}
```

### 2. Lock Hierarchy
```
Process Lock (sync_service.lock)
├── Operation Lock (sync_operation.lock)
│   └── Resource Locks (file-specific locks)
└── Watcher Lock (inotify_watcher.lock)
```

### 3. Lock Management

#### Lock Cleanup
```bash
cleanup_locks() {
    local max_age=3600  # 1 hour
    
    # Clean stale locks
    find /var/lock -name "sync_*.lock" -type f -mmin +60 -delete
    
    # Clean orphaned locks
    for lock in /var/lock/sync_*.lock; do
        if [ -f "$lock" ]; then
            pid=$(fuser "$lock" 2>/dev/null)
            if [ -z "$pid" ]; then
                rm -f "$lock"
            fi
        fi
    done
}
```

#### Lock Monitoring
```bash
monitor_locks() {
    while true; do
        # Check for stuck locks
        for lock in /var/lock/sync_*.lock; do
            if [ -f "$lock" ]; then
                lock_age=$(($(date +%s) - $(stat -c %Y "$lock")))
                if [ $lock_age -gt 3600 ]; then
                    logger "Warning: Stale lock found: $lock"
                    handle_stale_lock "$lock"
                fi
            fi
        done
        sleep 300  # Check every 5 minutes
    done
}
```

### 4. Lock Recovery

#### Deadlock Prevention
```bash
# Lock timeout system
acquire_lock_with_timeout() {
    local lock_file="$1"
    local timeout="$2"
    local start_time=$(date +%s)
    
    while true; do
        if flock -n "$lock_file" ; then
            return 0
        fi
        
        if [ $(($(date +%s) - start_time)) -gt "$timeout" ]; then
            return 1
        fi
        sleep 1
    done
}
```

#### Emergency Recovery
```bash
force_unlock() {
    local lock_file="$1"
    
    # Log the forced unlock
    logger "WARNING: Forcing unlock of $lock_file"
    
    # Kill processes holding the lock
    fuser -k "$lock_file" 2>/dev/null
    
    # Remove the lock file
    rm -f "$lock_file"
    
    # Trigger service recovery
    handle_service_failure
}
```

## Service Integration

### System Service Installation
```bash
install_service() {
    # Create systemd service file
    cat > /etc/systemd/system/sync-service.service << EOF
[Unit]
Description=Dashboard Sync Service
After=network.target

[Service]
Type=simple
ExecStart=/path/to/sync_service.sh start
ExecStop=/path/to/sync_service.sh stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload
}
```

### Automatic Startup
```bash
# Enable service
systemctl enable sync-service

# Start service
systemctl start sync-service
```

## Monitoring and Logging

### Service Logs
```bash
# Log to system journal
logger -t sync-service "Message"

# Read logs
journalctl -u sync-service
```

### Status Information
```bash
check_detailed_status() {
    # Check process
    check_status

    # Check SSH connections
    check_ssh_connections

    # Check sync status
    check_sync_status

    # Show recent logs
    tail -n 50 "$LOG_FILE"
}
```

## Error Handling

### Recovery Procedures
```bash
handle_service_failure() {
    # Log failure
    logger -t sync-service "Service failure detected"

    # Attempt cleanup
    cleanup_stale_locks
    cleanup_stale_processes

    # Restart service
    restart_service
}
```

### Lock Management
```bash
cleanup_stale_locks() {
    # Check lock age
    if [ -f "$LOCK_FILE" ]; then
        if [ $(( $(date +%s) - $(stat -c %Y "$LOCK_FILE") )) -gt 3600 ]; then
            rm -f "$LOCK_FILE"
        fi
    fi
}
