# Configuration System Changes Required

## 1. Centralized Configuration

### Current State
```bash
# Configuration scattered across files:
# monitor_helper.sh
SSH_USER="lj"
SSH_HOST="192.168.17.193"
SSH_PORT="22"

# system_monitor.sh
LOG_FILE="/var/log/system_monitor.log"
TEST_MODE="0"
```

### Required Changes
```bash
# Create new config/monitor_config.yaml
monitoring:
  ssh:
    user: "lj"
    host: "192.168.17.193"
    port: 22
    timeout: 30
    retries: 3
  
  logging:
    directory: "/var/log"
    level: "INFO"
    rotation: "daily"
    retention: 7
    
  system:
    check_interval: 60
    metrics_retention: 30
    alert_threshold: 80
    
  services:
    - name: "ssh"
      critical: true
    - name: "system_monitor"
      critical: true
    - name: "reboot_monitor"
      critical: false

# Add config loader to lib/config_manager.sh
#!/bin/bash

CONFIG_FILE="/etc/monitor/config.yaml"
CONFIG_CACHE="/tmp/monitor_config.cache"

load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        handle_error "Configuration file not found: $CONFIG_FILE"
        return 1
    }
    
    # Parse YAML and create cache
    parse_yaml "$CONFIG_FILE" > "$CONFIG_CACHE"
    source "$CONFIG_CACHE"
}

parse_yaml() {
    local yaml_file="$1"
    local prefix="$2"
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$|\1$prefix\2=\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$|\1$prefix\2=\3|p" "$yaml_file"
}

validate_config() {
    local required_fields=(
        "monitoring_ssh_user"
        "monitoring_ssh_host"
        "monitoring_ssh_port"
        "monitoring_logging_directory"
    )
    
    for field in "${required_fields[@]}"; do
        if [ -z "${!field}" ]; then
            handle_error "Missing required config: $field"
            return 1
        fi
    done
}
```

## 2. Configuration Validation

### Current State
```bash
# Basic validation in monitor_helper.sh
validate_ssh_config() {
    if [[ -z "$SSH_USER" || -z "$SSH_HOST" || -z "$SSH_PORT" ]]; then
        handle_error "Missing SSH configuration variables"
        return 1
    fi
}
```

### Required Changes
```bash
# Add to lib/config_validator.sh
#!/bin/bash

# Configuration schema
declare -A CONFIG_SCHEMA=(
    ["monitoring.ssh.user"]="string|required"
    ["monitoring.ssh.host"]="ip|required"
    ["monitoring.ssh.port"]="port|required"
    ["monitoring.logging.level"]="enum:INFO,DEBUG,WARNING,ERROR|required"
    ["monitoring.system.check_interval"]="integer:10:3600|required"
)

validate_config_schema() {
    local config_file="$1"
    local errors=()
    
    while IFS='=' read -r key value; do
        if [[ -n "${CONFIG_SCHEMA[$key]}" ]]; then
            local validation="${CONFIG_SCHEMA[$key]}"
            local result=$(validate_field "$key" "$value" "$validation")
            if [ "$result" != "valid" ]; then
                errors+=("$result")
            fi
        fi
    done < <(parse_yaml "$config_file")
    
    if [ ${#errors[@]} -gt 0 ]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    return 0
}

validate_field() {
    local key="$1"
    local value="$2"
    local validation="$3"
    
    IFS='|' read -r type required <<< "$validation"
    
    # Check if required
    if [ "$required" = "required" ] && [ -z "$value" ]; then
        echo "$key is required but empty"
        return 1
    fi
    
    # Validate type
    case "$type" in
        "string")
            # Any string is valid
            ;;
        "ip")
            if ! validate_ip "$value"; then
                echo "$key must be a valid IP address"
                return 1
            fi
            ;;
        "port")
            if ! validate_port "$value"; then
                echo "$key must be a valid port number (1-65535)"
                return 1
            fi
            ;;
        "enum:"*)
            local valid_values=${type#enum:}
            if [[ ! ",$valid_values," =~ ",$value," ]]; then
                echo "$key must be one of: $valid_values"
                return 1
            fi
            ;;
        "integer:"*)
            IFS=':' read -r _ min max <<< "$type"
            if ! validate_integer "$value" "$min" "$max"; then
                echo "$key must be an integer between $min and $max"
                return 1
            fi
            ;;
    esac
    
    echo "valid"
    return 0
}
```

## 3. Environment Detection

### Current State
```bash
# Basic WSL detection in system_monitor.sh
is_wsl() {
    if uname -r | grep -qi microsoft; then
        return 0
    else
        return 1
    fi
}
```

### Required Changes
```bash
# Add to lib/environment_detector.sh
#!/bin/bash

# Environment types
ENV_TYPE_LINUX="linux"
ENV_TYPE_WSL="wsl"
ENV_TYPE_WINDOWS="windows"
ENV_TYPE_UNKNOWN="unknown"

detect_environment() {
    # Detect WSL
    if uname -r | grep -qi microsoft; then
        echo "$ENV_TYPE_WSL"
        return
    fi
    
    # Detect Windows
    if [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]]; then
        echo "$ENV_TYPE_WINDOWS"
        return
    fi
    
    # Detect Linux
    if [[ "$(uname -s)" == "Linux" ]]; then
        echo "$ENV_TYPE_LINUX"
        return
    fi
    
    echo "$ENV_TYPE_UNKNOWN"
}

get_environment_config() {
    local env_type=$(detect_environment)
    local config_dir="/etc/monitor/environments"
    
    case "$env_type" in
        "$ENV_TYPE_WSL")
            echo "$config_dir/wsl.yaml"
            ;;
        "$ENV_TYPE_WINDOWS")
            echo "$config_dir/windows.yaml"
            ;;
        "$ENV_TYPE_LINUX")
            echo "$config_dir/linux.yaml"
            ;;
        *)
            echo "$config_dir/default.yaml"
            ;;
    esac
}

load_environment_config() {
    local env_config=$(get_environment_config)
    if [ -f "$env_config" ]; then
        load_config "$env_config"
    else
        handle_error "Environment config not found: $env_config"
        return 1
    fi
}
```

## 4. Path Handling

### Current State
```bash
# Hardcoded paths across files
MONITOR_DIR="/var/log/system_monitor"
LOG_FILE="/var/log/system_monitor.log"
```

### Required Changes
```bash
# Add to lib/path_manager.sh
#!/bin/bash

# Base directories
declare -A PATHS=(
    ["config_root"]="/etc/monitor"
    ["log_root"]="/var/log/monitor"
    ["run_root"]="/var/run/monitor"
    ["lib_root"]="/var/lib/monitor"
    ["cache_root"]="/var/cache/monitor"
)

initialize_paths() {
    local env_type=$(detect_environment)
    
    # Adjust paths based on environment
    case "$env_type" in
        "$ENV_TYPE_WSL")
            PATHS["config_root"]="/etc/monitor"
            PATHS["log_root"]="/var/log/monitor"
            ;;
        "$ENV_TYPE_WINDOWS")
            PATHS["config_root"]="C:/ProgramData/Monitor/config"
            PATHS["log_root"]="C:/ProgramData/Monitor/logs"
            ;;
    esac
    
    # Create directories if they don't exist
    for dir in "${PATHS[@]}"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            handle_error "Failed to create directory: $dir"
            return 1
        fi
    done
}

get_path() {
    local path_type="$1"
    local sub_path="${2:-}"
    
    if [ -z "${PATHS[$path_type]}" ]; then
        handle_error "Unknown path type: $path_type"
        return 1
    fi
    
    local full_path="${PATHS[$path_type]}"
    if [ -n "$sub_path" ]; then
        full_path="$full_path/$sub_path"
    fi
    
    echo "$full_path"
}

validate_paths() {
    local errors=()
    
    for path_type in "${!PATHS[@]}"; do
        local path="${PATHS[$path_type]}"
        
        # Check if directory exists
        if [ ! -d "$path" ]; then
            errors+=("Directory does not exist: $path")
            continue
        fi
        
        # Check write permissions
        if [ ! -w "$path" ]; then
            errors+=("Cannot write to directory: $path")
        fi
    done
    
    if [ ${#errors[@]} -gt 0 ]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    return 0
}
```

## Implementation Strategy

1. Phase 1: Basic Configuration
   - Create YAML configuration structure
   - Implement basic config loader
   - Add environment detection

2. Phase 2: Validation
   - Implement schema validation
   - Add type checking
   - Create validation tests

3. Phase 3: Environment Support
   - Add environment configs
   - Implement path management
   - Test cross-platform

4. Phase 4: Integration
   - Update existing scripts
   - Add migration support
   - Document changes

## Testing Requirements

1. Configuration Tests
   - YAML parsing
   - Schema validation
   - Required fields
   - Type validation

2. Environment Tests
   - WSL detection
   - Windows detection
   - Linux detection
   - Path handling

3. Integration Tests
   - Config loading
   - Environment switching
   - Path resolution
   - Error handling

## Security Considerations

1. File Permissions
   - Config files: 600
   - Cache files: 600
   - Log files: 644

2. Directory Permissions
   - Config directory: 700
   - Log directory: 755
   - Cache directory: 700

3. Security Checks
   - YAML injection prevention
   - Path traversal protection
   - Environment validation
