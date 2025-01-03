#!/bin/bash

# Source environment variables and error handler
source "${BASE_DIR}/.envrc"
source "${LIB_DIR}/utils/error_handler.sh"

# Log levels
declare -r LOG_DEBUG=0
declare -r LOG_INFO=1
declare -r LOG_WARN=2
declare -r LOG_ERROR=3
declare -r LOG_FATAL=4

# Log level names
declare -A LOG_LEVEL_NAMES=(
    [${LOG_DEBUG}]="DEBUG"
    [${LOG_INFO}]="INFO"
    [${LOG_WARN}]="WARN"
    [${LOG_ERROR}]="ERROR"
    [${LOG_FATAL}]="FATAL"
)

# Default log level
declare -i CURRENT_LOG_LEVEL=${LOG_INFO}

# Log file path
LOG_FILE="${LOG_DIR}/ssh_dashboard.log"

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}" || {
            echo "Failed to create log directory: ${LOG_DIR}" >&2
            return ${E_PERMISSION_DENIED}
        }
    }

    # Create or truncate log file
    touch "${LOG_FILE}" || {
        echo "Failed to create/access log file: ${LOG_FILE}" >&2
        return ${E_PERMISSION_DENIED}
    }

    # Set appropriate permissions
    chmod 640 "${LOG_FILE}" || {
        echo "Failed to set permissions on log file: ${LOG_FILE}" >&2
        return ${E_PERMISSION_DENIED}
    }

    return ${E_SUCCESS}
}

# Set log level
set_log_level() {
    local level=$1
    
    if [[ ${level} -ge ${LOG_DEBUG} ]] && [[ ${level} -le ${LOG_FATAL} ]]; then
        CURRENT_LOG_LEVEL=${level}
        return ${E_SUCCESS}
    else
        handle_error ${E_INVALID_ARGS} "Invalid log level: ${level}"
        return ${E_INVALID_ARGS}
    fi
}

# Internal logging function
_log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local level_name=${LOG_LEVEL_NAMES[${level}]}
    local source=${BASH_SOURCE[2]:-${BASH_SOURCE[1]}}
    local line=${BASH_LINENO[1]:-${BASH_LINENO[0]}}
    
    # Check if we should log at this level
    if [[ ${level} -ge ${CURRENT_LOG_LEVEL} ]]; then
        echo "[${timestamp}] [${level_name}] [${source}:${line}] ${message}" >> "${LOG_FILE}"
        
        # Also output to stderr for ERROR and FATAL
        if [[ ${level} -ge ${LOG_ERROR} ]]; then
            echo "[${timestamp}] [${level_name}] ${message}" >&2
        fi
    fi
}

# Logging functions for different levels
log_debug() {
    _log ${LOG_DEBUG} "$1"
}

log_info() {
    _log ${LOG_INFO} "$1"
}

log_warn() {
    _log ${LOG_WARN} "$1"
}

log_error() {
    _log ${LOG_ERROR} "$1"
}

log_fatal() {
    _log ${LOG_FATAL} "$1"
    exit ${E_GENERAL}
}

# Log rotation function
rotate_logs() {
    local max_size=${1:-10485760}  # Default: 10MB
    local backup_count=${2:-5}      # Default: Keep 5 backups
    
    # Check if log file exists and exceeds max size
    if [[ -f "${LOG_FILE}" ]] && [[ $(stat -f%z "${LOG_FILE}") -gt ${max_size} ]]; then
        # Rotate existing backup logs
        for (( i=${backup_count}; i>0; i-- )); do
            if [[ -f "${LOG_FILE}.${i}" ]]; then
                if [[ ${i} -eq ${backup_count} ]]; then
                    rm "${LOG_FILE}.${i}"
                else
                    mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i+1))"
                fi
            fi
        done
        
        # Rotate current log
        mv "${LOG_FILE}" "${LOG_FILE}.1"
        touch "${LOG_FILE}"
        chmod 640 "${LOG_FILE}"
    fi
}

# Clean old logs
clean_old_logs() {
    local max_age=${1:-30}  # Default: 30 days
    
    find "${LOG_DIR}" -name "*.log.*" -type f -mtime +${max_age} -delete
}

# Initialize logging on source
init_logging