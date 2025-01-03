#!/bin/bash

# =============================================
# CONFIGURATION
# =============================================
# Script directory and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/dashboard_config.conf"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create required directories
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$TEMP_DIR"

# Log file
LOG_FILE="$LOG_DIR/sync_$(date +%Y%m%d_%H%M%S).log"

# =============================================
# SSH CONNECTION
# =============================================
check_connection() {
    echo "Checking network connectivity..." | tee -a "$LOG_FILE"
    local remote_ip=$(grep -A1 "Host ${SSH_HOST}" ~/.ssh/config | grep HostName | awk '{print $2}')
    if [ -z "$remote_ip" ]; then
        echo -e "${RED}Error: Could not find IP address in SSH config${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "Testing connection to ${remote_ip}..." | tee -a "$LOG_FILE"
    if ! ping -c 1 "${remote_ip}" >/dev/null 2>&1; then
        echo -e "${RED}Error: Cannot reach ${remote_ip}${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    echo -e "${GREEN}✓ Network connection successful${NC}" | tee -a "$LOG_FILE"
    return 0
}

setup_ssh() {
    echo "Setting up SSH connection..." | tee -a "$LOG_FILE"
    check_connection || return 1
    
    # Ensure SSH agent is running
    if ! ssh-add -l >/dev/null 2>&1; then
        eval $(ssh-agent)
        ssh-add ~/.ssh/id_ed25519
    fi
    
    # Test SSH connection
    if ! ssh -q "${SSH_HOST}" exit; then
        echo -e "${RED}Error: Cannot connect to remote host${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo -e "${GREEN}✓ SSH connection successful${NC}" | tee -a "$LOG_FILE"
    return 0
}

# =============================================
# PORT FORWARDING
# =============================================
setup_port_forwarding() {
    echo "Setting up port forwarding..." | tee -a "$LOG_FILE"
    
    # Kill existing port forwarding
    pkill -f "ssh.*:${DASHBOARD_PORT}.*:${METRICS_PORT}"
    
    # Start new port forwarding
    ssh -fN -L "${DASHBOARD_PORT}:localhost:${DASHBOARD_PORT}" \
           -L "${METRICS_PORT}:localhost:${METRICS_PORT}" \
           "${SSH_HOST}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Port forwarding established${NC}" | tee -a "$LOG_FILE"
        echo "Dashboard available at: http://localhost:${DASHBOARD_PORT}" | tee -a "$LOG_FILE"
        echo "Metrics available at: http://localhost:${METRICS_PORT}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}✗ Port forwarding failed${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# =============================================
# SYNC FUNCTIONS
# =============================================
parse_args() {
    TEST_MODE=0
    SOURCE_DIR=""
    DEST_DIR=""
    HOST=""
    USER=""
    PORT="22"
    COMMAND="$1"
    shift  # Remove command from args
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-mode)
                TEST_MODE=1
                shift
                ;;
            --source=*)
                SOURCE_DIR="${1#*=}"
                shift
                ;;
            --dest=*)
                DEST_DIR="${1#*=}"
                shift
                ;;
            --host=*)
                HOST="${1#*=}"
                shift
                ;;
            --user=*)
                USER="${1#*=}"
                shift
                ;;
            --port=*)
                PORT="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments based on command
    case "$COMMAND" in
        "stop")
            # Stop only requires host and user
            if [ -z "$HOST" ] || [ -z "$USER" ]; then
                echo "Error: Host and user required for stop command"
                echo "Usage: $0 stop --host=hostname --user=username [--port=22] [--test-mode]"
                exit 1
            fi
            ;;
        "sync")
            # Sync requires all arguments
            if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ] || [ -z "$HOST" ] || [ -z "$USER" ]; then
                echo "Error: Missing required arguments for sync command"
                echo "Usage: $0 sync --source=/path/to/source --dest=/path/to/dest --host=hostname --user=username [--port=22] [--test-mode]"
                exit 1
            fi
            ;;
    esac
}

sync_directories() {
    local source_dir="$1"
    local dest_dir="$2"
    local host="$3"
    local user="$4"
    local port="$5"
    
    if [ "${TEST_MODE:-0}" = "1" ]; then
        echo "Test mode: Simulating sync from $source_dir to $dest_dir"
        # Create destination if it doesn't exist
        mkdir -p "$dest_dir"
        
        # In test mode, just copy files locally
        if [ -d "$source_dir" ] && [ -n "$(ls -A $source_dir 2>/dev/null)" ]; then
            cp -r "$source_dir"/* "$dest_dir"/ || {
                echo "Error: Failed to copy files in test mode"
                return 1
            }
        else
            # Source is empty or doesn't exist, touch a marker file
            touch "$dest_dir/.sync_empty"
        fi
        return 0
    fi
    
    # Real sync using rsync over SSH
    rsync -avz -e "ssh -p $port" "$source_dir"/* "$user@$host:$dest_dir"/ || {
        echo "Error: Failed to sync directories"
        return 1
    }
    return 0
}

sync_dashboard_files() {
    echo "Syncing dashboard files..." | tee -a "$LOG_FILE"
    
    # Create remote directory if it doesn't exist
    if [ "${TEST_MODE:-0}" = "1" ]; then
        mkdir -p "$DEST_DIR"
    else
        ssh -p "$PORT" "$USER@$HOST" "mkdir -p $DEST_DIR"
    fi
    
    # Start sync
    echo "Starting sync..."
    sync_directories "$SOURCE_DIR" "$DEST_DIR" "$HOST" "$USER" "$PORT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Dashboard files synced${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}✗ Sync failed${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

watch_and_sync() {
    echo "Setting up monitoring..." | tee -a "$LOG_FILE"
    setup_ssh || exit 1
    setup_port_forwarding || exit 1
    
    echo "Performing initial sync..." | tee -a "$LOG_FILE"
    sync_dashboard_files
    
    echo -e "${BLUE}Starting file watcher...${NC}" | tee -a "$LOG_FILE"
    echo "Watching for changes in: ${LOCAL_DIR}" | tee -a "$LOG_FILE"
    echo "Press Ctrl+C to stop watching" | tee -a "$LOG_FILE"
    
    while true; do
        inotifywait -e modify,create,delete -r "${LOCAL_DIR}"
        sync_dashboard_files
    done
}

stop_sync() {
    if [ "${TEST_MODE:-0}" = "1" ]; then
        echo "Test mode: Simulating sync stop"
        return 0
    fi
    
    # Find and kill any running rsync processes
    local pids=$(pgrep -f "rsync.*$USER@$HOST")
    if [ -n "$pids" ]; then
        echo "Stopping sync processes: $pids"
        kill $pids
    else
        echo "No sync processes found"
    fi
}

# =============================================
# CLEANUP
# =============================================
cleanup() {
    echo "Cleaning up connections..." | tee -a "$LOG_FILE"
    pkill -f "ssh -fN.*${SSH_HOST}"
    pkill -f "ssh.*:${DASHBOARD_PORT}.*:${METRICS_PORT}"
}

trap cleanup EXIT

# =============================================
# MAIN SCRIPT
# =============================================
main() {
    parse_args "$@"
    
    case "$COMMAND" in
        "stop")
            stop_sync
            ;;
        "sync")
            # Create destination directory if it doesn't exist
            if [ "${TEST_MODE:-0}" = "1" ]; then
                mkdir -p "$DEST_DIR"
            else
                ssh -p "$PORT" "$USER@$HOST" "mkdir -p $DEST_DIR"
            fi
            
            # Start sync
            echo "Starting sync..."
            sync_directories "$SOURCE_DIR" "$DEST_DIR" "$HOST" "$USER" "$PORT"
            
            if [ $? -eq 0 ]; then
                echo "Sync completed successfully"
            else
                echo "Sync failed"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {sync|stop}"
            echo ""
            echo "Commands:"
            echo "  sync  - Sync files from source to destination"
            echo "  stop  - Stop sync processes"
            echo ""
            echo "Options:"
            echo "  --test-mode             Run in test mode"
            echo "  --source=/path/to/src   Source directory (sync only)"
            echo "  --dest=/path/to/dest    Destination directory (sync only)"
            echo "  --host=hostname         Remote hostname"
            echo "  --user=username         Remote username"
            echo "  --port=22              SSH port (default: 22)"
            exit 1
            ;;
    esac
}

main "$@"
