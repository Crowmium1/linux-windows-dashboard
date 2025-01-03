#!/bin/bash

# Security Manager for SSH Dashboard
# Handles security checks, key management, and access control

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load security configuration
SECURITY_CONFIG="${SCRIPT_DIR}/../../config/security/security.yaml"

# Global variables
declare -A KEY_STATUS
declare -A PERMISSION_STATUS
SECURITY_LOCK_FILE="${HA_STATE_DIR}/security.lock"
LAST_CHECK_TIME=0

# Function to load security configuration
load_security_config() {
    if [[ ! -f "${SECURITY_CONFIG}" ]]; then
        log_error "Security configuration not found: ${SECURITY_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${SECURITY_CONFIG}")"
}

# Function to acquire security lock
acquire_security_lock() {
    if [[ -f "${SECURITY_LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${SECURITY_LOCK_FILE}")
        if kill -0 "${lock_pid}" 2>/dev/null; then
            log_warning "Security check already in progress (PID: ${lock_pid})"
            return 1
        fi
        rm -f "${SECURITY_LOCK_FILE}"
    fi
    
    echo $$ > "${SECURITY_LOCK_FILE}"
    return 0
}

# Function to release security lock
release_security_lock() {
    rm -f "${SECURITY_LOCK_FILE}"
}

# Function to check SSH key permissions
check_key_permissions() {
    local key_path=$1
    local expected_perms=${2:-600}
    
    if [[ ! -f "${key_path}" ]]; then
        log_error "SSH key not found: ${key_path}"
        return 1
    fi
    
    local actual_perms
    actual_perms=$(stat -c "%a" "${key_path}")
    
    if [[ "${actual_perms}" != "${expected_perms}" ]]; then
        log_error "Invalid permissions on ${key_path}: ${actual_perms} (expected ${expected_perms})"
        PERMISSION_STATUS["${key_path}"]="invalid"
        return 1
    fi
    
    PERMISSION_STATUS["${key_path}"]="valid"
    return 0
}

# Function to check SSH key age
check_key_age() {
    local key_path=$1
    local max_age=${2:-${SSH_KEY_MAX_AGE}}
    
    local key_age
    key_age=$(($(date +%s) - $(stat -c "%Y" "${key_path}")))
    key_age=$((key_age / 86400)) # Convert to days
    
    if [[ ${key_age} -gt ${max_age} ]]; then
        log_warning "SSH key ${key_path} is ${key_age} days old (max: ${max_age})"
        KEY_STATUS["${key_path}"]="expired"
        return 1
    fi
    
    KEY_STATUS["${key_path}"]="valid"
    return 0
}

# Function to check SSH configuration
check_ssh_config() {
    local host=$1
    local config_path="/etc/ssh/sshd_config"
    
    # Check remote SSH configuration
    local config_check
    config_check=$(ssh ${SSH_OPTIONS} \
        -p "${SSH_PORT}" \
        -i "${SSH_KEY_PATH}" \
        "${SSH_USER}@${host}" \
        "grep -E '^(PermitRootLogin|PasswordAuthentication|Protocol|X11Forwarding)' ${config_path}")
    
    local secure=true
    
    # Check individual settings
    if echo "${config_check}" | grep -q "PermitRootLogin yes"; then
        log_error "Root login is permitted on ${host}"
        secure=false
    fi
    
    if echo "${config_check}" | grep -q "PasswordAuthentication yes"; then
        log_error "Password authentication is enabled on ${host}"
        secure=false
    fi
    
    if echo "${config_check}" | grep -q "Protocol.*1"; then
        log_error "SSHv1 is enabled on ${host}"
        secure=false
    fi
    
    if echo "${config_check}" | grep -q "X11Forwarding yes"; then
        log_warning "X11 forwarding is enabled on ${host}"
    fi
    
    ${secure}
}

# Function to verify host keys
verify_host_keys() {
    local host=$1
    local known_hosts="${HOME}/.ssh/known_hosts"
    
    # Backup known_hosts
    cp "${known_hosts}" "${known_hosts}.bak"
    
    # Get current host key
    local current_key
    current_key=$(ssh-keyscan -t rsa "${host}" 2>/dev/null)
    
    # Check if key exists and matches
    if ! ssh-keygen -F "${host}" >/dev/null 2>&1; then
        log_warning "No existing key for ${host}, adding new key"
        echo "${current_key}" >> "${known_hosts}"
        return 0
    fi
    
    local stored_key
    stored_key=$(ssh-keygen -F "${host}")
    
    if [[ "${current_key}" != "${stored_key}" ]]; then
        log_error "Host key mismatch for ${host}"
        return 1
    fi
    
    return 0
}

# Function to check authentication logs
check_auth_logs() {
    local host=$1
    local max_failures=${2:-${SSH_MAX_AUTH_FAILURES}}
    local time_window=${3:-3600} # Default 1 hour
    
    local auth_failures
    auth_failures=$(ssh ${SSH_OPTIONS} \
        -p "${SSH_PORT}" \
        -i "${SSH_KEY_PATH}" \
        "${SSH_USER}@${host}" \
        "grep 'Failed password' /var/log/auth.log | wc -l")
    
    if [[ ${auth_failures} -gt ${max_failures} ]]; then
        log_error "Excessive authentication failures on ${host}: ${auth_failures} in last hour"
        return 1
    fi
    
    return 0
}

# Function to check firewall rules
check_firewall_rules() {
    local host=$1
    
    # Check if firewall is active
    local firewall_status
    firewall_status=$(ssh ${SSH_OPTIONS} \
        -p "${SSH_PORT}" \
        -i "${SSH_KEY_PATH}" \
        "${SSH_USER}@${host}" \
        "ufw status | grep -q 'Status: active' && echo active || echo inactive")
    
    if [[ "${firewall_status}" != "active" ]]; then
        log_error "Firewall is not active on ${host}"
        return 1
    fi
    
    # Check SSH port rules
    local ssh_rules
    ssh_rules=$(ssh ${SSH_OPTIONS} \
        -p "${SSH_PORT}" \
        -i "${SSH_KEY_PATH}" \
        "${SSH_USER}@${host}" \
        "ufw status | grep ${SSH_PORT}/tcp")
    
    if ! echo "${ssh_rules}" | grep -q "ALLOW"; then
        log_error "No firewall rule allowing SSH on port ${SSH_PORT} for ${host}"
        return 1
    fi
    
    return 0
}

# Function to check security on single host
check_host_security() {
    local host=$1
    local security_failed=false
    
    # Check SSH configuration
    if ! check_ssh_config "${host}"; then
        security_failed=true
    fi
    
    # Verify host keys
    if ! verify_host_keys "${host}"; then
        security_failed=true
    fi
    
    # Check authentication logs
    if ! check_auth_logs "${host}"; then
        security_failed=true
    fi
    
    # Check firewall rules
    if ! check_firewall_rules "${host}"; then
        security_failed=true
    fi
    
    if [[ "${security_failed}" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# Function to check all hosts
check_all_hosts() {
    # Try to acquire security lock
    if ! acquire_security_lock; then
        return 1
    fi
    
    local check_failed=false
    
    # Check SSH key permissions and age
    check_key_permissions "${SSH_KEY_PATH}" || check_failed=true
    check_key_age "${SSH_KEY_PATH}" || check_failed=true
    
    # Check primary host
    if ! check_host_security "${hosts_primary_hostname}"; then
        check_failed=true
    fi
    
    # Check backup hosts
    for backup in "${hosts_backup[@]}"; do
        if ! check_host_security "${backup[hostname]}"; then
            check_failed=true
        fi
    done
    
    LAST_CHECK_TIME=$(date +%s)
    release_security_lock
    
    if [[ "${check_failed}" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# Function to get security report
get_security_report() {
    local report=""
    report+="Security Status Report\n"
    report+="Last check: $(date -d @${LAST_CHECK_TIME} '+%Y-%m-%d %H:%M:%S')\n\n"
    
    # SSH Key Status
    report+="SSH Key Status:\n"
    for key in "${!KEY_STATUS[@]}"; do
        report+="  ${key}: ${KEY_STATUS[${key}]}\n"
        report+="  Permissions: ${PERMISSION_STATUS[${key}]}\n"
    done
    
    # Get current security settings
    report+="\nSecurity Settings:\n"
    report+="  Max Auth Failures: ${SSH_MAX_AUTH_FAILURES}\n"
    report+="  Key Max Age: ${SSH_KEY_MAX_AGE} days\n"
    report+="  Root Login: ${SSH_PERMIT_ROOT_LOGIN}\n"
    
    echo -e "${report}"
}

# Main function
main() {
    # Load configuration
    if ! load_security_config; then
        exit 1
    fi
    
    # Create required directories
    mkdir -p "${HA_LOG_DIR}/security" "${HA_STATE_DIR}"
    
    # Process command line arguments
    case "$1" in
        check)
            if [[ -n "$2" ]]; then
                check_host_security "$2"
            else
                check_all_hosts
            fi
            ;;
        status)
            get_security_report
            ;;
        monitor)
            # Continuous security monitoring
            while true; do
                if check_all_hosts; then
                    log_info "All security checks passed"
                else
                    log_warning "Security issues detected"
                    send_notifications "SECURITY_WARNING" "$(get_security_report)"
                fi
                sleep "${SECURITY_CHECK_INTERVAL}"
            done
            ;;
        *)
            echo "Usage: $0 {check [host]|status|monitor}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
