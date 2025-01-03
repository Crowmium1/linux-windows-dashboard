#!/bin/bash

# Source environment variables
source "${BASE_DIR}/.envrc"

# Error codes
declare -r E_SUCCESS=0
declare -r E_GENERAL=1
declare -r E_INVALID_ARGS=2
declare -r E_FILE_NOT_FOUND=3
declare -r E_PERMISSION_DENIED=4
declare -r E_NETWORK=5
declare -r E_SERVICE=6
declare -r E_CONFIG=7
declare -r E_DATABASE=8

# Error messages
declare -A ERROR_MESSAGES=(
    [${E_SUCCESS}]="Success"
    [${E_GENERAL}]="General error"
    [${E_INVALID_ARGS}]="Invalid arguments"
    [${E_FILE_NOT_FOUND}]="File not found"
    [${E_PERMISSION_DENIED}]="Permission denied"
    [${E_NETWORK}]="Network error"
    [${E_SERVICE}]="Service error"
    [${E_CONFIG}]="Configuration error"
    [${E_DATABASE}]="Database error"
)

# Error handling function
handle_error() {
    local error_code=$1
    local error_message=${2:-${ERROR_MESSAGES[${error_code}]}}
    local error_source=${3:-${BASH_SOURCE[1]}}
    local error_line=${4:-${BASH_LINENO[0]}}

    # Log the error if logger is available
    if type log_error &>/dev/null; then
        log_error "[${error_code}] ${error_message} (${error_source}:${error_line})"
    else
        echo "[ERROR] [${error_code}] ${error_message} (${error_source}:${error_line})" >&2
    fi

    return ${error_code}
}

# Function to check required commands
check_required_commands() {
    local missing_commands=()
    
    for cmd in "$@"; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing_commands+=("${cmd}")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        handle_error ${E_GENERAL} "Missing required commands: ${missing_commands[*]}"
        return ${E_GENERAL}
    fi
    
    return ${E_SUCCESS}
}

# Function to check required files
check_required_files() {
    local missing_files=()
    
    for file in "$@"; do
        if [[ ! -f "${file}" ]]; then
            missing_files+=("${file}")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        handle_error ${E_FILE_NOT_FOUND} "Missing required files: ${missing_files[*]}"
        return ${E_FILE_NOT_FOUND}
    fi
    
    return ${E_SUCCESS}
}

# Function to check required directories
check_required_dirs() {
    local missing_dirs=()
    
    for dir in "$@"; do
        if [[ ! -d "${dir}" ]]; then
            missing_dirs+=("${dir}")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        handle_error ${E_FILE_NOT_FOUND} "Missing required directories: ${missing_dirs[*]}"
        return ${E_FILE_NOT_FOUND}
    fi
    
    return ${E_SUCCESS}
}

# Function to check permissions
check_permissions() {
    local path=$1
    local perms=$2
    
    if [[ ! -e "${path}" ]]; then
        handle_error ${E_FILE_NOT_FOUND} "Path not found: ${path}"
        return ${E_FILE_NOT_FOUND}
    fi
    
    case ${perms} in
        r) if [[ ! -r "${path}" ]]; then
               handle_error ${E_PERMISSION_DENIED} "Read permission denied: ${path}"
               return ${E_PERMISSION_DENIED}
           fi ;;
        w) if [[ ! -w "${path}" ]]; then
               handle_error ${E_PERMISSION_DENIED} "Write permission denied: ${path}"
               return ${E_PERMISSION_DENIED}
           fi ;;
        x) if [[ ! -x "${path}" ]]; then
               handle_error ${E_PERMISSION_DENIED} "Execute permission denied: ${path}"
               return ${E_PERMISSION_DENIED}
           fi ;;
        *) handle_error ${E_INVALID_ARGS} "Invalid permission type: ${perms}"
           return ${E_INVALID_ARGS} ;;
    esac
    
    return ${E_SUCCESS}
}

# Function to handle cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    local cleanup_function=${1:-}
    
    # Run custom cleanup function if provided
    if [[ -n "${cleanup_function}" ]] && type "${cleanup_function}" &>/dev/null; then
        ${cleanup_function}
    fi
    
    # Log exit if not successful
    if [[ ${exit_code} -ne ${E_SUCCESS} ]]; then
        handle_error ${exit_code} "Script exited with error"
    fi
    
    exit ${exit_code}
}

# Set up trap for cleanup
trap_cleanup() {
    local cleanup_function=${1:-}
    trap "cleanup_on_exit ${cleanup_function}" EXIT
}