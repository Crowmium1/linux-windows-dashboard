#!/bin/bash

# Config validator for SSH Dashboard Monitor
# Validates YAML configuration files for proper format and required fields

# Required fields for each config type
MAIN_CONFIG_REQUIRED=(
    "MONITOR_INTERVAL"
    "CPU_THRESHOLD"
    "MEMORY_THRESHOLD"
    "DISK_THRESHOLD"
    "SSH_PORT"
    "SSH_KEY_TYPE"
    "SSH_KEY_BITS"
)

ENV_CONFIG_REQUIRED=(
    "LOG_DIR"
    "DATA_DIR"
    "TEMP_DIR"
    "SSH_CMD"
    "SSH_KEYGEN"
    "PATH_SEPARATOR"
)

# Function to check if value is numeric
is_numeric() {
    local value=$1
    [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" =~ ^[0-9]+\.[0-9]+$ ]]
}

# Function to check if path is absolute
is_absolute_path() {
    local path=$1
    [[ "$path" == /* ]] || [[ "$path" =~ ^[A-Za-z]:[\\/] ]]
}

# Function to validate a single field
validate_field() {
    local file=$1
    local field=$2
    local value
    
    # Extract value using parse_yaml from config_loader.sh
    value=$(parse_yaml "$file" | grep "^${field}=" | cut -d'=' -f2- | tr -d '"')
    
    if [[ -z "$value" ]]; then
        echo "Error: Required field '$field' not found in $file" >&2
        return 1
    fi
    
    # Validate specific fields
    case "$field" in
        *_THRESHOLD)
            if ! is_numeric "$value" || [[ "$value" -lt 0 ]] || [[ "$value" -gt 100 ]]; then
                echo "Error: $field must be a number between 0 and 100" >&2
                return 1
            fi
            ;;
        MONITOR_INTERVAL|SSH_PORT|SSH_KEY_BITS)
            if ! is_numeric "$value" || [[ "$value" -lt 1 ]]; then
                echo "Error: $field must be a positive number" >&2
                return 1
            fi
            ;;
        *_DIR)
            if ! is_absolute_path "$value"; then
                echo "Error: $field must be an absolute path" >&2
                return 1
            fi
            ;;
        SSH_KEY_TYPE)
            if [[ ! "$value" =~ ^(rsa|ed25519|ecdsa)$ ]]; then
                echo "Error: SSH_KEY_TYPE must be one of: rsa, ed25519, ecdsa" >&2
                return 1
            fi
            ;;
        SSH_CMD|SSH_KEYGEN)
            if ! is_absolute_path "$value"; then
                echo "Error: $field must be an absolute path to the command" >&2
                return 1
            fi
            ;;
        PATH_SEPARATOR)
            if [[ ! "$value" =~ ^[/\\]$ ]]; then
                echo "Error: PATH_SEPARATOR must be either '/' or '\\'" >&2
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Function to validate main config
validate_main_config() {
    local config_file=$1
    local errors=0
    
    echo "Validating main config: $config_file"
    
    # Check file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Main config file not found: $config_file" >&2
        return 1
    fi
    
    # Validate each required field
    for field in "${MAIN_CONFIG_REQUIRED[@]}"; do
        if ! validate_field "$config_file" "$field"; then
            ((errors++))
        fi
    done
    
    return "$errors"
}

# Function to validate environment config
validate_env_config() {
    local config_file=$1
    local errors=0
    
    echo "Validating environment config: $config_file"
    
    # Check file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Environment config file not found: $config_file" >&2
        return 1
    fi
    
    # Validate each required field
    for field in "${ENV_CONFIG_REQUIRED[@]}"; do
        if ! validate_field "$config_file" "$field"; then
            ((errors++))
        fi
    done
    
    return "$errors"
}

# Function to validate all configs
validate_all_configs() {
    local config_dir=$1
    local errors=0
    
    # Validate main config
    if ! validate_main_config "${config_dir}/main_config.yaml"; then
        ((errors++))
    fi
    
    # Validate environment configs
    for env_config in "${config_dir}"/environments/*.yaml; do
        if [[ -f "$env_config" ]]; then
            if ! validate_env_config "$env_config"; then
                ((errors++))
            fi
        fi
    done
    
    if [[ "$errors" -eq 0 ]]; then
        echo "All configurations validated successfully"
        return 0
    else
        echo "Found $errors validation errors" >&2
        return 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If script is run directly, validate all configs
    config_dir="${1:-$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")/config}"
    validate_all_configs "$config_dir"
fi