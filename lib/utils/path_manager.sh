#!/bin/bash

# Source environment variables and utilities
source "${BASE_DIR}/.envrc"
source "${LIB_DIR}/utils/error_handler.sh"
source "${LIB_DIR}/utils/logger.sh"

# Load YAML configuration
parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
         -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
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

# Initialize paths from config
init_paths() {
    local config_file="${CONFIG_DIR}/main_config.yaml"
    
    # Check if config file exists
    if [[ ! -f "${config_file}" ]]; then
        log_error "Main config file not found: ${config_file}"
        return ${E_FILE_NOT_FOUND}
    }
    
    # Load YAML config into environment
    eval $(parse_yaml "${config_file}" "CONFIG_")
    
    # Verify required directories exist
    check_required_dirs "${BASE_DIR}" "${CONFIG_DIR}" "${LOG_DIR}" "${TEMP_DIR}" || {
        log_error "Required directories missing"
        return ${E_FILE_NOT_FOUND}
    }
    
    return ${E_SUCCESS}
}

# Get absolute path
get_abs_path() {
    local path=$1
    
    # If path is already absolute, return it
    if [[ "${path}" = /* ]]; then
        echo "${path}"
        return ${E_SUCCESS}
    fi
    
    # Convert relative to absolute path
    echo "${BASE_DIR}/${path}"
    return ${E_SUCCESS}
}

# Validate path
validate_path() {
    local path=$1
    local type=${2:-any}  # any, file, dir
    
    # Get absolute path
    local abs_path=$(get_abs_path "${path}")
    
    # Check if path exists
    if [[ ! -e "${abs_path}" ]]; then
        log_error "Path does not exist: ${abs_path}"
        return ${E_FILE_NOT_FOUND}
    }
    
    # Check path type
    case ${type} in
        file)
            if [[ ! -f "${abs_path}" ]]; then
                log_error "Path is not a file: ${abs_path}"
                return ${E_INVALID_ARGS}
            fi
            ;;
        dir)
            if [[ ! -d "${abs_path}" ]]; then
                log_error "Path is not a directory: ${abs_path}"
                return ${E_INVALID_ARGS}
            fi
            ;;
    esac
    
    return ${E_SUCCESS}
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir=$1
    local perms=${2:-755}
    
    # Get absolute path
    local abs_dir=$(get_abs_path "${dir}")
    
    # Create directory if it doesn't exist
    if [[ ! -d "${abs_dir}" ]]; then
        mkdir -p "${abs_dir}" || {
            log_error "Failed to create directory: ${abs_dir}"
            return ${E_PERMISSION_DENIED}
        }
        
        # Set permissions
        chmod "${perms}" "${abs_dir}" || {
            log_error "Failed to set permissions on directory: ${abs_dir}"
            return ${E_PERMISSION_DENIED}
        }
    fi
    
    return ${E_SUCCESS}
}

# Get config path
get_config_path() {
    local config_name=$1
    local env=${ENV:-production}
    
    # Check environment-specific config first
    local env_config="${CONFIG_DIR}/environments/${env}/${config_name}"
    if [[ -f "${env_config}" ]]; then
        echo "${env_config}"
        return ${E_SUCCESS}
    fi
    
    # Fall back to main config directory
    local main_config="${CONFIG_DIR}/${config_name}"
    if [[ -f "${main_config}" ]]; then
        echo "${main_config}"
        return ${E_SUCCESS}
    fi
    
    log_error "Config file not found: ${config_name}"
    return ${E_FILE_NOT_FOUND}
}

# Initialize paths on source
init_paths