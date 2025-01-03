#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/system_config.conf"

# Check if running in test mode
is_test_mode() {
    [ "${TEST_MODE:-0}" = "1" ]
}

# Function to show cleanup menu
show_cleanup_menu() {
    echo -e "${BLUE}=== Cleanup Options ===${NC}"
    echo "1) Clean old logs"
    echo "2) Clean old backups"
    echo "3) Clean temporary files"
    echo "4) Clean all sync data"
    echo "5) Reset configuration"
    echo "6) Clean everything"
    echo "b) Back to main menu"
}

# Function to clean old logs
clean_logs() {
    echo -e "\n${BLUE}Cleaning old logs...${NC}"
    
    local log_dir="${LOG_DIR:-$SCRIPT_DIR/../logs}"
    if [ ! -d "$log_dir" ]; then
        echo -e "${YELLOW}No logs directory found at $log_dir${NC}"
        return 0
    fi
    
    # Find and remove old log files
    find "$log_dir" -name "*.log" -type f -mtime +${LOG_RETENTION_DAYS} -exec rm {} \;
    
    # Remove empty directories
    find "$log_dir" -type d -empty -delete
    
    echo -e "${GREEN}✓ Old logs cleaned${NC}"
}

# Function to clean old backups
clean_backups() {
    echo -e "\n${BLUE}Cleaning old backups...${NC}"
    
    local backup_dir="${BACKUP_DIR:-$SCRIPT_DIR/../backups}"
    if [ ! -d "$backup_dir" ]; then
        echo -e "${YELLOW}No backups directory found at $backup_dir${NC}"
        return 0
    fi
    
    # Keep only the specified number of recent backups
    cd "$backup_dir" || return
    ls -t backup_* 2>/dev/null | tail -n +$((BACKUP_RETENTION + 1)) | xargs -r rm -rf
    
    echo -e "${GREEN}✓ Old backups cleaned${NC}"
}

# Function to clean temporary files
clean_temp() {
    echo -e "\n${BLUE}Cleaning temporary files...${NC}"
    
    local temp_dir="${TEMP_DIR:-$SCRIPT_DIR/../tmp}"
    if [ ! -d "$temp_dir" ]; then
        echo -e "${YELLOW}No temporary directory found at $temp_dir${NC}"
        return 0
    fi
    
    # Clean temporary directory
    rm -rf "${temp_dir:?}/"*
    
    # Clean other temporary files
    find "$SCRIPT_DIR" -name "*.tmp" -type f -delete
    find "$SCRIPT_DIR" -name "*.swp" -type f -delete
    
    echo -e "${GREEN}✓ Temporary files cleaned${NC}"
}

# Function to clean sync data
clean_sync() {
    echo -e "\n${BLUE}Cleaning sync data...${NC}"
    
    # Stop any running sync processes
    pkill -f "sync_helper.sh"
    
    # Clean sync logs and temporary files
    local sync_dir="${SYNC_DIR:-$SCRIPT_DIR/../sync}"
    if [ ! -d "$sync_dir" ]; then
        echo -e "${YELLOW}No sync directory found at $sync_dir${NC}"
        return 0
    fi
    rm -rf "$sync_dir"/*
    
    echo -e "${GREEN}✓ Sync data cleaned${NC}"
}

# Function to reset configuration
reset_config() {
    echo -e "\n${BLUE}Resetting configuration...${NC}"
    
    # Backup current config
    if [ -f "$SCRIPT_DIR/../config/system_config.conf" ]; then
        cp "$SCRIPT_DIR/../config/system_config.conf" "$SCRIPT_DIR/../config/system_config.conf.bak"
    fi
    
    # Reset to defaults
    cat > "$SCRIPT_DIR/../config/system_config.conf" << EOL
# Default Keyring Manager Configuration
LOG_LEVEL=INFO
MAX_LOG_SIZE=10M
LOG_RETENTION_DAYS=30
DETAILED_LOGGING=true
BACKUP_RETENTION=5
AUTO_BACKUP=true
EOL
    
    echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
    echo -e "${YELLOW}Previous config backed up as system_config.conf.bak${NC}"
}

# Function to clean everything
clean_all() {
    echo -e "\n${YELLOW}Warning: This will clean all data except essential files${NC}"
    read -p "Are you sure? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        clean_logs
        clean_backups
        clean_temp
        clean_sync
        echo -e "${GREEN}✓ All cleanup tasks completed${NC}"
    else
        echo "Cleanup cancelled"
    fi
}

# Main cleanup loop
while true; do
    show_cleanup_menu
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            clean_logs
            ;;
        2)
            clean_backups
            ;;
        3)
            clean_temp
            ;;
        4)
            clean_sync
            ;;
        5)
            reset_config
            ;;
        6)
            clean_all
            ;;
        b|B)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
done
