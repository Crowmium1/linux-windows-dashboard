#!/bin/bash

# Script to install SSH Dashboard services
# Must be run as root

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/utils/utils.sh"

# Installation paths
INSTALL_DIR="/opt/ssh_dashboard"
SYSTEMD_DIR="/etc/systemd/system"

# Function to install service files
install_services() {
    log_info "Installing SSH Dashboard services..."
    
    # Create installation directory
    mkdir -p "${INSTALL_DIR}"
    
    # Copy project files
    cp -r "${SCRIPT_DIR}/.." "${INSTALL_DIR}"
    
    # Set correct permissions
    chown -R root:root "${INSTALL_DIR}"
    chmod -R 755 "${INSTALL_DIR}"
    
    # Install systemd service files
    cp "${INSTALL_DIR}/lib/ha/ssh-ha.service" "${SYSTEMD_DIR}/"
    cp "${INSTALL_DIR}/lib/monitoring/ssh-monitor.service" "${SYSTEMD_DIR}/"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable services
    systemctl enable ssh-ha.service
    systemctl enable ssh-monitor.service
    
    log_info "Services installed successfully"
}

# Function to verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check service files
    for service in ssh-ha.service ssh-monitor.service; do
        if [[ ! -f "${SYSTEMD_DIR}/${service}" ]]; then
            log_error "Service file not found: ${service}"
            return 1
        fi
    done
    
    # Check service status
    for service in ssh-ha ssh-monitor; do
        if ! systemctl is-enabled "${service}.service" >/dev/null 2>&1; then
            log_error "Service not enabled: ${service}"
            return 1
        fi
    done
    
    # Check installation directory
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        log_error "Installation directory not found"
        return 1
    fi
    
    log_info "Installation verified successfully"
    return 0
}

# Main function
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
    
    # Install services
    if ! install_services; then
        log_error "Failed to install services"
        exit 1
    fi
    
    # Verify installation
    if ! verify_installation; then
        log_error "Installation verification failed"
        exit 1
    fi
    
    log_info "Installation completed successfully"
    
    # Display service status
    echo -e "\nService Status:"
    systemctl status ssh-ha.service
    systemctl status ssh-monitor.service
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
