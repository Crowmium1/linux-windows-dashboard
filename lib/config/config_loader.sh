#!/bin/bash

# Function to detect environment
detect_environment() {
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo "wsl"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to parse YAML (basic implementation)
parse_yaml() {
    local file=$1
    local prefix=$2
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    local fs=$(echo @|tr @ '\034')
    
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $file |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn,$2,$3);
        }
    }'
}

# Function to load environment config
load_environment_config() {
    local env=$(detect_environment)
    local config_dir="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/config"
    local env_config="${config_dir}/environments/${env}.yaml"
    
    if [[ ! -f "$env_config" ]]; then
        echo "Error: Environment config not found: $env_config" >&2
        return 1
    fi
    
    # Load and export environment variables
    eval $(parse_yaml "$env_config")
    
    # Verify essential variables
    local required_vars=("LOG_DIR" "DATA_DIR" "TEMP_DIR" "SSH_CMD" "SSH_KEYGEN")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: Required variable $var not set in config" >&2
            return 1
        fi
    done
    
    # Create required directories
    mkdir -p "${LOG_DIR}" "${DATA_DIR}" "${TEMP_DIR}"
    
    return 0
}

# Function to get config value
get_config() {
    local key=$1
    local default=$2
    
    if [[ -n "${!key}" ]]; then
        echo "${!key}"
    else
        echo "$default"
    fi
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If script is run directly, load config
    load_environment_config
fi
