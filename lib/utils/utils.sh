#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running in test mode
is_test_mode() {
    [ "${TEST_MODE:-0}" = "1" ]
}

# Check if running in WSL
is_wsl() {
    if uname -r | grep -qi microsoft; then
        return 0  # true in bash
    else
        return 1  # false in bash
    fi
}

# Function to check if command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        if is_test_mode; then
            echo -e "${YELLOW}Warning: $cmd would be required in non-test mode${NC}"
            return 0
        fi
        
        if is_wsl && [[ " lspci lsusb dmidecode glxinfo vulkaninfo vainfo sensors " =~ " $cmd " ]]; then
            echo -e "${YELLOW}Warning: $cmd not available in WSL. Some hardware info will be limited.${NC}"
        else
            echo -e "${YELLOW}Warning: $cmd is not installed${NC}"
            case "$cmd" in
                "netstat") echo "Consider installing net-tools package" ;;
                "ss") echo "Consider installing iproute2 package" ;;
                "sensors") echo "Consider installing lm-sensors package" ;;
                "glxinfo") echo "Consider installing mesa-utils package" ;;
                "vulkaninfo") echo "Consider installing vulkan-tools package" ;;
                "vainfo") echo "Consider installing vainfo package" ;;
            esac
        fi
        return 1
    fi
    return 0
}

# Function to check directory permissions
check_directory_permissions() {
    local dir="$1"
    
    # Create directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            echo -e "${RED}Error: Failed to create directory $dir${NC}"
            return 1
        }
    fi
    
    # In WSL on Windows filesystem, skip permission checks
    if is_wsl && [[ "$dir" == "/mnt/c/"* ]]; then
        return 0
    fi
    
    # Set proper permissions (only on non-Windows filesystems)
    chmod 755 "$dir" || {
        echo -e "${RED}Error: Failed to set permissions on $dir${NC}"
        return 1
    }
    
    # Verify permissions (only on non-Windows filesystems)
    if [ "$(stat -c %a $dir)" != "755" ]; then
        echo -e "${RED}Error: Directory $dir has incorrect permissions${NC}"
        return 1
    fi
    
    return 0
}

# Function to check disk space
check_disk_space() {
    local required_space=10240  # 10MB in KB
    local available_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt "$required_space" ]; then
        echo -e "${RED}Error: Insufficient disk space. Need at least 10MB${NC}"
        return 1
    fi
    return 0
}

# Function to run command with timeout
run_with_timeout() {
    local cmd="$1"
    local timeout_duration=5  # Reduced from 30 to 5 seconds for faster tests
    
    # Run with timeout and redirect stderr to stdout
    timeout --kill-after=1 $timeout_duration bash -c "$cmd" 2>&1
    local status=$?
    
    # Check if command timed out
    if [ $status -eq 124 ] || [ $status -eq 137 ]; then
        echo "Command timed out: $cmd"
        return 1
    fi
    return $status
}

# Function to sanitize directory path
sanitize_path() {
    local path="$1"
    # Remove any command injection attempts
    path="${path//;/}"
    path="${path//|/}"
    path="${path//>/}"
    path="${path//</}"
    path="${path//\`/}"
    path="${path//\$/}"
    path="${path//\(/}"
    path="${path//\)/}"
    path="${path//&/}"
    # Convert to absolute path
    echo "$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
}

# Function to validate directory path
validate_path() {
    local path="$1"
    # Check for suspicious patterns
    if echo "$path" | grep -q '[;&|><`$(){}]'; then
        echo -e "${RED}Error: Invalid characters in path${NC}"
        return 1
    fi
    # Check if path is within allowed directories
    local allowed_dirs=("/tmp" "/mnt" "$HOME" ".")
    local abs_path="$(cd "$(dirname "$path")" 2>/dev/null && pwd)"
    local valid=0
    for dir in "${allowed_dirs[@]}"; do
        if echo "$abs_path" | grep -q "^$(cd "$dir" 2>/dev/null && pwd)"; then
            valid=1
            break
        fi
    done
    if [ $valid -eq 0 ]; then
        echo -e "${RED}Error: Path not in allowed directories${NC}"
        return 1
    fi
    return 0
}

# Create archive of a directory
create_archive() {
    local source_dir="$1"
    local archive_name="${2:-archive_$(date +%Y%m%d_%H%M%S).tar.gz}"
    
    if [ ! -d "$source_dir" ]; then
        echo -e "${RED}Error: Source directory does not exist: $source_dir${NC}"
        return 1
    fi
    
    # Get absolute paths
    source_dir=$(cd "$source_dir" && pwd)
    archive_dir=$(dirname "$(readlink -f "$archive_name")")
    archive_base=$(basename "$archive_name")
    
    if [ ! -w "$archive_dir" ]; then
        echo -e "${RED}Error: Archive directory is not writable: $archive_dir${NC}"
        return 1
    fi
    
    # Create temporary directory for the archive
    local temp_dir
    temp_dir=$(mktemp -d)
    local temp_archive="$temp_dir/$archive_base"
    
    # Create archive in temporary location
    echo "Creating archive: $archive_base"
    local current_dir=$(pwd)
    cd "$source_dir" || return 1
    if ! tar -czf "$temp_archive" . ; then
        echo -e "${RED}Error: Failed to create archive${NC}"
        cd "$current_dir"
        rm -rf "$temp_dir"
        return 1
    fi
    cd "$current_dir"
    
    # Move archive to final location
    if ! mv "$temp_archive" "$archive_name"; then
        echo -e "${RED}Error: Failed to move archive to final location${NC}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    # Verify archive was created and is not empty
    if [ ! -f "$archive_name" ] || [ ! -s "$archive_name" ]; then
        echo -e "${RED}Error: Archive creation failed or archive is empty${NC}"
        return 1
    fi
    
    # List the created archive
    ls -l "$archive_name"
    return 0
}

# Clean old files based on retention period
cleanup_old_files() {
    local directory="$1"
    local days="$2"
    
    if [ ! -d "$directory" ]; then
        echo -e "${RED}Error: Directory does not exist: $directory${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Cleaning up files older than $days days in $directory${NC}"
    
    # Special case: if days=0, remove all files except those modified in the last minute
    if [ "$days" -eq 0 ]; then
        echo "Immediate cleanup mode: removing all files not modified in the last minute"
        # First list all files to remove
        local files_to_remove=()
        while IFS= read -r -d '' file; do
            files_to_remove+=("$file")
        done < <(find "$directory" -mindepth 1 -not -mmin -1 -print0)
        
        # Then remove them
        for file in "${files_to_remove[@]}"; do
            echo "Removing: $file"
            rm -rf "$file"
        done
        return 0
    fi
    
    # For WSL on Windows filesystem, we need to handle dates differently
    if is_wsl && [[ "$directory" == "/mnt/c/"* ]]; then
        # First collect all files to remove
        local files_to_remove=()
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                # Get file age in days
                local mtime
                mtime=$(stat -c %Y "$file")
                local now
                now=$(date +%s)
                local age_days=$(( (now - mtime) / 86400 ))
                
                if [ "$age_days" -gt "$days" ]; then
                    echo "Removing old file: $file"
                    files_to_remove+=("$file")
                fi
            fi
        done < <(find "$directory" -type f -print0)
        
        # Then remove them
        for file in "${files_to_remove[@]}"; do
            rm -f "$file"
        done
        
        # Now handle directories
        local dirs_to_remove=()
        while IFS= read -r -d '' dir; do
            if [ "$dir" != "$directory" ] && [ -z "$(ls -A "$dir")" ]; then
                echo "Removing empty directory: $dir"
                dirs_to_remove+=("$dir")
            fi
        done < <(find "$directory" -type d -print0)
        
        # Remove empty directories
        for dir in "${dirs_to_remove[@]}"; do
            rm -rf "$dir"
        done
    else
        # For non-Windows filesystem, use standard find commands but still in two phases
        # First collect files
        local files_to_remove=()
        while IFS= read -r -d '' file; do
            files_to_remove+=("$file")
        done < <(find "$directory" -type f -mtime +"$days" -print0)
        
        # Then remove them
        for file in "${files_to_remove[@]}"; do
            echo "Removing old file: $file"
            rm -f "$file"
        done
        
        # Now handle directories
        local dirs_to_remove=()
        while IFS= read -r -d '' dir; do
            if [ -z "$(ls -A "$dir")" ]; then
                echo "Removing empty directory: $dir"
                dirs_to_remove+=("$dir")
            fi
        done < <(find "$directory" -mindepth 1 -type d -print0)
        
        # Remove empty directories
        for dir in "${dirs_to_remove[@]}"; do
            rm -rf "$dir"
        done
    fi
    
    return 0
}
